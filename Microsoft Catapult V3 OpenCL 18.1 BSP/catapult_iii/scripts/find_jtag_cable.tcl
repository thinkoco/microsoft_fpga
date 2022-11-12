load_package insystem_source_probe

if {$argc > 0} {post_message "Running find_jtag_cable.tcl to find CADE value: $argv" }

set cable 1

# check to exit when there is no cable attached
if {[catch {get_hardware_names} err ]} {
  post_message "No JTAG cable found!! check cable connection..."
  exit 1
}

foreach usb [get_hardware_names] {
  
  foreach device_name [get_device_names -hardware_name $usb] {
    
    post_message "Looking in Cable ($usb) Device ($device_name)"
    # Skip device if no sources and probes exit
    if {[catch {get_insystem_source_probe_instance_info -hardware_name $usb -device_name $device_name} err ]} {
      post_message "Doesn't contain sources and probes. Skipping..."
      continue
    } 
   
    # Sources and probes exit, hence look for "CADE" 
    #post_message "Looking for CADE in sources and probes"
    foreach instance [get_insystem_source_probe_instance_info -hardware_name $usb -device_name $device_name] {
      
      set probe_name [lindex $instance 3]
      set probe_index [lindex $instance 0]
      
      if {[string match $probe_name "CADE"]} {
        post_message "Found CADE in Probe Index:$probe_index. Probing for CADEID..."
        start_insystem_source_probe -device_name $device_name -hardware_name $usb
        set val [read_probe_data -instance_index $probe_index -value_in_hex ]
        post_message "Expected CADEID=$argv, Probe return CADEID=$val"
    
        if {[string match $val "$argv"]} {
          post_message "CADEID value matched. Found Cable!!!"
          post_message "Matched Cable:$cable Device Name:$device_name"
          exit 0
        } else {
          post_message "CADEID didn't match. Continue looking..."
        }
        end_insystem_source_probe
      }
    }
  }
  
  #increment cable index while going through usb
  incr cable
}

exit 1
