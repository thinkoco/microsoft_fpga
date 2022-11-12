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
# Create Clock
#**************************************************************
create_clock -period 100MHz [get_ports config_clk]
create_clock -period 266.667MHz [get_ports pll_ref_clk]
create_clock -period 100MHz [get_ports pcie_refclk]
create_clock -period 100MHz [get_ports kernel_pll_refclk]
create_clock -name {altera_reserved_tck} -period 50.000 -waveform { 0.000 25.000 } [get_ports {altera_reserved_tck}] 

#**************************************************************
# Set Clock Latency
#**************************************************************

#**************************************************************
# Set Input Delay
#**************************************************************

#**************************************************************
# Set Output Delay
#**************************************************************

#**************************************************************
# Set Multicycle Path
#**************************************************************

#**************************************************************
# Set Maximum Delay
#**************************************************************

#**************************************************************
# Set Minimum Delay
#**************************************************************

#**************************************************************
# Set Input Transition
#**************************************************************

#**************************************************************
# Set Load
#**************************************************************

#**************************************************************
# Set False Paths
#**************************************************************
set_false_path -from [get_ports perstl0_n] -to *
