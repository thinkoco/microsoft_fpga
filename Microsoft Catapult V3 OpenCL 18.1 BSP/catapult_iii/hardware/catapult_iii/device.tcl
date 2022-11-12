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

# This file contains .qsf settings that are unique to this particular device

#############################################################
# Device
#############################################################
set_global_assignment -name FAMILY "Arria 10"
#set_global_assignment -name DEVICE 10AX115N3F40E2SG
set_global_assignment -name DEVICE 10AXF40AA
set_global_assignment -name MIN_CORE_JUNCTION_TEMP 0
set_global_assignment -name MAX_CORE_JUNCTION_TEMP 100
set_global_assignment -name DEVICE_FILTER_PACKAGE FBGA
set_global_assignment -name DEVICE_FILTER_PIN_COUNT 1932
set_global_assignment -name ERROR_CHECK_FREQUENCY_DIVISOR 256
set_global_assignment -name STRATIX_DEVICE_IO_STANDARD "1.8 V"
set_global_assignment -name RESERVE_ALL_UNUSED_PINS_WEAK_PULLUP "AS INPUT TRI-STATED"
set_global_assignment -name RESERVE_DATA0_AFTER_CONFIGURATION "USE AS REGULAR IO"

set_global_assignment -name VCCP_USER_VOLTAGE 0.9V
set_global_assignment -name NOMINAL_CORE_SUPPLY_VOLTAGE 0.9V
set_global_assignment -name VCCERAM_USER_VOLTAGE 0.9V

# Preserve unused Tx and Rx channels from degradation
set_global_assignment -name PRESERVE_UNUSED_XCVR_CHANNEL ON
