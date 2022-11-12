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


# recursive glob
proc glob_r {{dir .}} {
  set res {}
  foreach i [lsort [glob -nocomplain -dir $dir *]] {
    if {[file type $i] eq {directory}} {
      eval lappend res [glob_r $i]
    } else {
      lappend res $i
    }
  }
  set res
}

proc create_qar_list {bak_list dir} {
  # get a list of files to add to the archive
  set list_in [glob_r $dir]
  set list_handle [open $bak_list a+]
  foreach line $list_in {
    # no sdc files
    if {[string match "*sdc" $line]} { continue }
    puts $list_handle $line
  }
  close $list_handle
}
