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

set platform [lindex $quartus(args) 0]
set board_variant [lindex $quartus(args) 1]

# get pr_base.id
set pr_base_id_file [open "pr_base.id" r]
set pr_base_id [string trim [read $pr_base_id_file]]
close $pr_base_id_file

# get current quartus version
regexp {Version (.*) Build (\d*)} $quartus(version) -> version_num build_num
append version_num "_" $build_num
append version_num "_" $pr_base_id

# set temporary dir to be removed
set tmp_dir $::env(AOCL_TMP_DIR)/$platform/$board_variant/$version_num
post_message "Deleting $tmp_dir..."
file delete -force -- $tmp_dir
post_message "Deleting $tmp_dir completed successfully"

source "$::env(INTELFPGAOCLSDKROOT)/ip/board/bsp/bak_flow.tcl"
