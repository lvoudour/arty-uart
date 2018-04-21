if { $argc != 1 } {
    puts "ERROR: program.tcl requires 1 argument. Please try again."
    exit -1
}

# set output directories
set BITSTREAM_DIR ./bit
set TOP_MODULE [lindex $argv 0]

open_hw
connect_hw_server

# current_hw_target [get_hw_targets */xilinx_tcf/Digilent/*]
# set_property PARAM.FREQUENCY 15000000 [get_hw_targets */xilinx_tcf/Digilent/*]
open_hw_target

set HW_DEVICE [lindex [get_hw_devices] 0]
current_hw_device $HW_DEVICE
refresh_hw_device -update_hw_probes false $HW_DEVICE

set_property PROGRAM.FILE "$BITSTREAM_DIR/$TOP_MODULE.bit" $HW_DEVICE
program_hw_devices $HW_DEVICE