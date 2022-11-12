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

# Update acds_version_rom.mif with version of this compile. Then create Intel
# hex form of the same file.

# Constants
set num_expected_args 1
set max_onchip_ram_bytes 64

set prog create_acds_version_hex
set mif_file "acds_version_rom.mif"

# Need to know if current compile revision is base to put magic value in ROM
# Magic value is "Base"
if { $argc != $num_expected_args } {
  post_message "$prog: Need one argument: Compile revision"
  exit 2
}

set revision_name [lindex $quartus(args) 0]

# Get Quartus release and build version
set acds_version [exec quartus_sh --version]
regexp {Version ([0-9\.]+).* Build ([0-9]+)} $acds_version full_acds_version acds_version_rom_txt build_num

append acds_version_rom_txt " " $build_num

# If revision is base, replace Quartus version with "Base"
if {[string match $revision_name "base"]} {
  post_message "Compiling base revision -> creating mif with magic value"
  set acds_version_rom_txt "Base"
}

set version_bytes [string length $acds_version_rom_txt]
set version_words [expr (($version_bytes - 1)/4) + 1]

# Create quartus_version.id file to go into fpga.bin
set quartus_ver_file "quartus_version.id"
set quartus_ver [open $quartus_ver_file w]
puts -nonewline $quartus_ver $acds_version_rom_txt

# Create MIF for the onchip_mem component
set mif [open $mif_file w]
set ram_depth [expr int ($max_onchip_ram_bytes / 4 ) ]
puts $mif "DEPTH=$ram_depth;"
puts $mif "WIDTH=32;"
puts $mif "ADDRESS_RADIX=DEC;"
puts $mif "DATA_RADIX=HEX;"
puts $mif "CONTENT BEGIN"
set addr 0

for {set i 0} {$i < [expr $version_words] } {incr i} {
  # 8 hex chars define the 4B word
  set start [expr 4 * $i]
  set read_bytes [expr $i * 4]
  set remaining_bytes [expr $version_bytes - $read_bytes]
  if [expr $remaining_bytes > 4] {
    set end [expr (4 * $i) + 3]
    set next_read 4
  } else {
    set end [expr (4 * $i) + $remaining_bytes - 1]
    set next_read $remaining_bytes
  }
  set acds_ver_four_bytes [string range $acds_version_rom_txt $start $end]
 
  for {set j 0} {$j < $next_read} {incr j} {
    set acds_ver_char [string range $acds_ver_four_bytes [expr $next_read - $j - 1] [expr $next_read - $j - 1]]
    if {$j == 0} {
      set acds_ver_ascii [format %2.2X [scan $acds_ver_char %c]]
    } else {
      append acds_ver_ascii [format %2.2X [scan $acds_ver_char %c]]
    }
  }
  
  puts $mif "$addr : $acds_ver_ascii;"
  incr addr
}

# Zero out rest of mif
puts $mif "\[$addr\.\.[expr $ram_depth - 1 ]\] : 0 ;"

puts $mif "END;"
close $mif
close $quartus_ver 

# Create hex file from the mif file
catch {exec mif2hex $mif_file acds_version_rom.hex} res
