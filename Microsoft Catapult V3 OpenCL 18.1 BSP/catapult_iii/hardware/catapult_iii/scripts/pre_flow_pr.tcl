# (C) 1992-2019 Intel Corporation.                            
# Intel, the Intel logo, Intel, MegaCore, NIOS II, Quartus and TalkBack words    
# and logos are trademarks of Intel Corporation or its subsidiaries in the U.S.  
# and/or other countries. Other marks and brands may be claimed as the property  
# of others. See Trademarks on intel.com for full list of Intel trademarks or    
# the Trademarks & Brands Names Database (if Intel) or See www.Intel.com/legal (if Altera) 
# Your use of Intel Corporation's design tools, logic functions and other        
# software and tools, and its AMPP partner logic functions, and any output       
# files any of the foregoing (including device programming or simulation         
# files), and any associated documentation or information are expressly subject  
# to the terms and conditions of the Altera Program License Subscription         
# Agreement, Intel MegaCore Function License Agreement, or other applicable      
# license agreement, including, without limitation, that your use is for the     
# sole purpose of programming logic devices manufactured by Intel and sold by    
# Intel or its authorized distributors.  Please refer to the applicable          
# agreement for further details.                                                 

post_message "Running pre-flow script"

# Make sure OpenCL SDK installation exists
post_message "Checking for OpenCL SDK installation, environment should have INTELFPGAOCLSDKROOT defined"
if {[catch {set sdk_root $::env(INTELFPGAOCLSDKROOT)} result]} {
  post_message -type error "OpenCL SDK installation not found.  Make sure INTELFPGAOCLSDKROOT is correctly set"
  post_message -type error "Terminating pre-flow script"
  exit 2
} else {
  post_message "INTELFPGAOCLSDKROOT=$::env(INTELFPGAOCLSDKROOT)"
}

# Load OpenCL BSP utility functions
source "$sdk_root/ip/board/bsp/opencl_bsp_util.tcl"
source "$sdk_root/ip/board/incremental/aocl_incremental.tcl"
source "scripts/qar_ip_files.tcl"

set project_name top
set revision_name UNKNOWN

# Get revision name (from quartus(args) variable)
if { [llength $quartus(args)] > 0 } {
  set revision_name [lindex $quartus(args) 0]
} else {
  set revision_name top
}

set fast_compile  [::aocl_fast_compile::is_fast_compile]
set incremental_compile [::aocl_incremental::is_incremental_compile]
set device_name   [::opencl_bsp::get_device_name $project_name $revision_name]


##############################################################################
##############################       MAIN        #############################
##############################################################################

post_message "Project name: $project_name"
post_message "Revision name: $revision_name"
post_message "Device part name: $device_name"

# For A10 18.0 BSP the Qsys-less flow added the pr_region hierarchy level 
set top_path {freeze_wrapper_inst|pr_region_inst|kernel_system_inst}
::opencl_bsp::pre_flow_init $project_name $revision_name $top_path

# Check if fast compile is on during base revision
if {$revision_name eq "base" && $fast_compile} {
  post_message -type error "Using fast compile for base compile is forbidden since it is likely to yield low performing BSPs"
  post_message -type error "Terminating pre-flow script"
  exit 2
}

if {$revision_name ne "top" && $incremental_compile} {
  post_message -type error "Incremental compile is only supported on the default \"top\" flow"
  post_message -type error "Terminating pre-flow script"
  exit 3
}

# Create quartus_version.id and acds_version_rom.mif
# The acds_version_rom.mif is used during post-flow to update contents of onchip memory in BSP
# The onchip memory stores Quartus version the sof was compiled with, so that designs compiled 
# with different version of Quartus are not PR'ed.
# MMD determines the version of Quartus the new sof was compiled with using quartus_version.id in fpga.bin
qexec "quartus_cdb -t scripts/create_acds_ver_hex.tcl $revision_name"

# Create and embed unique base revision compile ID into static region (board.qsys).
# The generated hash is written to board.qsys with qsys-script.
# board.qsys, mem.qsys and ddr4.qsys are only added to "opencl_bsp_ip.qsf" file
# for "flat" and "base" revision compiles.
# These files are not required in "top" revision compiles which import the post-fit netlist from a previous "base"
# revision compile.
if {$revision_name eq "base" || $revision_name eq "flat"} {
  post_message "Compiling $revision_name revision: creating and embedding unique revision compile ID!"

  # Get MD5 Hash value
  set base_id [::opencl_bsp::create_base_id]

  # Wirte MD5 hash to pr_base.id
  set pr_base_id_filename "pr_base.id"
  set pr_base_id_file [open $pr_base_id_filename w]
  puts $pr_base_id_file $base_id
  close $pr_base_id_file

  # Update pr_base_id in board.qsys to include MD5 hash
  qexec "qsys-script --quartus-project=$project_name --rev=opencl_bsp_ip --system-file=board.qsys --cmd=\"package require -exact qsys 16.1;set_validation_property AUTOMATIC_VALIDATION false;load_component pr_base_id;set_component_parameter_value \"VERSION_ID\" \"$base_id\";save_component;save_system board.qsys\""
}

# Generate and archive if static region is being compiled
# Otherwise unqar previously packed qar
if {$revision_name eq "base" || $revision_name eq "flat"} {
  post_message "Compiling $revision_name revision: generating and archiving board.qsys"
  post_message "    qsys-generate -syn --family=\"Arria 10\" --part=$device_name board.qsys"
  qexec "qsys-generate -syn --family=\"Arria 10\" --part=$device_name board.qsys"
  post_message "    qsys-archive --quartus-project=$project_name --rev=opencl_bsp_ip --add-to-project board.qsys"
  qexec "qsys-archive --quartus-project=$project_name --rev=opencl_bsp_ip --add-to-project board.qsys"

} elseif {[string match $revision_name "top"]} {
  post_message "Compiling top revision: unpacking base revision compile outputs from base.qar"
  unqar_ip_files
}

# Generate the Pipeline brdige IP in kernel_mem
post_message "Updating kernel_mem pipeline bridges"
post_message "    qsys-generate --upgrade-ip-cores kernel_mem.qsys"
qexec "qsys-generate --upgrade-ip-cores kernel_mem.qsys"
post_message "    qsys-generate --synthesis kernel_mem.qsys"
qexec "qsys-generate --synthesis kernel_mem.qsys"
