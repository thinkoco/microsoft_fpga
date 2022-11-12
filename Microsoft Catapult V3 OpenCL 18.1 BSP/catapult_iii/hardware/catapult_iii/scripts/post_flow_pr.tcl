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

post_message "Running post_flow_pr.tcl script"

post_message "Checking for OpenCL SDK installation, environment should have INTELFPGAOCLSDKROOT defined"
if {[catch {set sdk_root $::env(INTELFPGAOCLSDKROOT)} result]} {
  post_message -type error "OpenCL SDK installation not found.  Make sure INTELFPGAOCLSDKROOT is correctly set"
  exit 2
} else {
  post_message "INTELFPGAOCLSDKROOT=$::env(INTELFPGAOCLSDKROOT)"
}

# Load OpenCL BSP utility functions
source "$sdk_root/ip/board/bsp/opencl_bsp_util.tcl"
source "scripts/qar_ip_files.tcl"

set project_name  [::opencl_bsp::get_project_name $quartus(args)]
set revision_name [::opencl_bsp::get_revision_name $quartus(args) $project_name]
set fast_compile  [::aocl_fast_compile::is_fast_compile]
set logic_limit 75.0
set update_mif 1


##############################################################################
##############################       MAIN        #############################
##############################################################################

post_message "Project name: $project_name"
post_message "Revision name: $revision_name"

if {$revision_name eq "base"} {
  post_message "Compiling base revision -> exporting the base revision compile database to QDB archive base.qdb!"
  qexec "quartus_cdb $project_name -c $revision_name --export_design --snapshot final --file $revision_name.qdb"
}

# Update onchip memory with mif created during preflow
if {$update_mif & !$fast_compile & $revision_name eq "top"} {
    qexec "quartus_cdb top -c base --update_mif" 
    qexec "quartus_cdb top -c top --update_mif"
}

# Run PR checks script
if {!$fast_compile} {
  source "$sdk_root/ip/board/bsp/pr_checks_a10.tcl"
}

# Run adjust PLL script 
source "$sdk_root/ip/board/bsp/adjust_plls.tcl"

# Export SDC constraints in base revision compile only
post_message "Exporting SDC constraints"
if {$revision_name eq "base"} {
  post_message "Compiling base revision -> exporting SDC constraints to base.sdc!"
  qexec "quartus_sta top -c base --report_script=scripts/base_write_sdc.tcl" 
} else {
  post_message "Compiling top or flat revision -> nothing to be done here!"
}

# Export static partition IP in base revision compile only
post_message "Exporting static partition IP"
if {$revision_name eq "base"} {
  post_message "Compiling base revision -> pack base revision compile outputs into base.qar!"
  qar_ip_files
} else {
  post_message "Compiling top or flat revision -> nothing to be done here!"
}

# Create fpga.bin
post_message "Running create_fpga_bin_pr.tcl script"
if {$revision_name eq "base"} {
  post_message "Compiling base revision -> adding only base.sof to fpga.bin!"
  qexec "quartus_cdb -t scripts/create_fpga_bin_pr.tcl base.sof"

} elseif {$revision_name eq "top"} {
  # top.kernel.rbf is named after the partition name of the PR region set during the base compile
  post_message "Compiling top revision -> adding top.sof, top.kernel.rbf, pr_base.id and quartus_version.id to fpga.bin!"
  qexec "quartus_cdb -t scripts/create_fpga_bin_pr.tcl top.sof top.kernel.rbf pr_base.id quartus_version.id"

} elseif {$revision_name eq "flat"} {
  post_message "Compiling flat revision -> adding only flat.sof to fpga.bin!"
  qexec "quartus_cdb -t scripts/create_fpga_bin_pr.tcl flat.sof"
}

# Check board utilization is below 75% threshold on fast compile, because
# certain large designs may be dangerous to run on HW
if {$fast_compile} {
  ::aocl_fast_compile::check_logic_utilization $logic_limit
}

