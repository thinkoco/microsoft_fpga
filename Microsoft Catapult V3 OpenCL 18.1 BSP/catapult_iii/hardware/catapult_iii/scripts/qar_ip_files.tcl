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

source "$::env(INTELFPGAOCLSDKROOT)/ip/board/bsp/helpers.tcl"

proc qar_ip_files {{base_qar "base.qar"}} {
  set list_qar "tmp_qar_list"
  set list_handle [open $list_qar w]
  close $list_handle
  # create the list
  create_qar_list $list_qar ddr4
  create_qar_list $list_qar mem
  create_qar_list $list_qar board
  create_qar_list $list_qar ip/mem
  create_qar_list $list_qar ip/ddr4
  create_qar_list $list_qar ip/board/

  # add individual files
  set list_handle [open $list_qar a+]
  set list_in "base.qdb base.sdc pr_base.id"
  foreach line $list_in {
    puts $list_handle $line
  }
  close $list_handle
  qexec "quartus_sh --archive -input $list_qar -output $base_qar"
}

proc unqar_ip_files {{base_qar "base.qar"} {result_dir "."}} {
  # remove the extension from the file name, store result in $sentinel_file
  regexp {(.*)\.} $base_qar -> sentinel_file

  # form <qar_name>.qarlog, which is produced when a qar is unarchived
  append sentinel_file ".qarlog"

  # only perform unqaring if .qarlog is not present
  if { ![file exists $sentinel_file] } {
    qexec "quartus_sh --restore -output $result_dir $base_qar"
  }
}
