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



#**************************************************************
# Create Generated Clock
#**************************************************************
derive_pll_clocks

#**************************************************************
# Set Clock Uncertainty
#**************************************************************
derive_clock_uncertainty

# Add clock uncertainty between the 1x and 2x clocks to avoid hold time violations.
# These settings should only be applied when running the fitter.
if {[string equal $::TimeQuestInfo(nameofexecutable) "quartus_fit"]} {
  set_clock_uncertainty -add -setup -from [get_clocks *kernel_pll*outclk0] -to [get_clocks *kernel_pll*outclk1] 0.01
  set_clock_uncertainty -add -hold  -from [get_clocks *kernel_pll*outclk0] -to [get_clocks *kernel_pll*outclk1] 0.01
  set_clock_uncertainty -add -setup -from [get_clocks *kernel_pll*outclk1] -to [get_clocks *kernel_pll*outclk0] 0.01
  set_clock_uncertainty -add -hold  -from [get_clocks *kernel_pll*outclk1] -to [get_clocks *kernel_pll*outclk0] 0.01
}

#**************************************************************
# Set Clock Groups
#**************************************************************
set_clock_groups -asynchronous \
-group { \
   config_clk \
} -group { \
   a10_internal_oscillator_clock0 \
} -group { \
   altera_ts_clk \
} -group { \
   pll_ref_clk \
} -group { \
   kernel_pll_refclk \
} -group [get_clocks {
   pcie_refclk \
   board_inst|pcie|* \
}] -group [get_clocks { \
   board_inst|kernel_clk_gen|kernel_clk_gen|kernel_pll|* \
}] -group [get_clocks { \
   acl_hmcc_wrapper_inst|* \
}] -group { \
   altera_reserved_tck \
} -group [get_clocks { \
    mem0_dqs[0]_IN \
    mem0_dqs[1]_IN \
    mem0_dqs[2]_IN \
    mem0_dqs[3]_IN \
    mem0_dqs[4]_IN \
    mem0_dqs[5]_IN \
    mem0_dqs[6]_IN \
    mem0_dqs[7]_IN \
	mem1_dqs[0]_IN \
    mem1_dqs[1]_IN \
    mem1_dqs[2]_IN \
    mem1_dqs[3]_IN \
    mem1_dqs[4]_IN \
    mem1_dqs[5]_IN \
    mem1_dqs[6]_IN \
    mem1_dqs[7]_IN \
    board_inst|mem|* \
}]

#**************************************************************
# Set False Path
#**************************************************************

#cut paths to led pins
set_false_path -from * -to leds[*]

# Cut path to pcie npor - this signal is asynchronous
set_false_path -from board_inst|por_reset_counter|por_reset_counter|sw_reset_n_out -to *

# Cut path to DDR4 reset - this signal is asynchronous
set_false_path -from board_inst|mem|ddr4_calibrate|sw_reset_n_out -to *

# Cut path to freeze signal - this signal is asynchronous
set_false_path -from board_inst|alt_pr|alt_pr|alt_pr_cb_host|alt_pr_cb_controller_v2|freeze_reg -to *

# Make the kernel reset multicycle
set_multicycle_path -to * -setup 4 -from {board_inst|kernel_interface|kernel_interface|reset_controller_sw|alt_rst_sync_uq1|altera_reset_synchronizer_int_chain_out}
set_multicycle_path -to * -hold 3 -from {board_inst|kernel_interface|kernel_interface|reset_controller_sw|alt_rst_sync_uq1|altera_reset_synchronizer_int_chain_out}
set_multicycle_path -to * -setup 4 -from {freeze_wrapper_inst|kernel_system_clock_reset_reset_reset_n}
set_multicycle_path -to * -hold 3 -from {freeze_wrapper_inst|kernel_system_clock_reset_reset_reset_n}

# Cut path to twoXclock_consumer (this instance is only there to keep 
# kernel interface consistent and prevents kernel_clk2x to be swept away by synthesis)
set_false_path -from * -to freeze_wrapper_inst|pr_region_inst|*|twoXclock_consumer_NO_SHIFT_REG

# Relax Kernel constraints - only do this during base revision compiles
if {! [string equal $::TimeQuestInfo(nameofexecutable) "quartus_map"]} {
# Case 196028 can't call get_current_revision in parallel map

if { [get_current_revision] eq "base" } {

  post_message -type critical_warning "Compiling with slowed OpenCL Kernel clock.  This is to help achieve timing closure for board bringup."

  if {! [string equal $::TimeQuestInfo(nameofexecutable) "quartus_sta"]} {
    set kernel_keepers [get_keepers freeze_wrapper_inst\|pr_region_inst\|*] 
    set_max_delay 5 -from $kernel_keepers -to $kernel_keepers
  }
}

}
