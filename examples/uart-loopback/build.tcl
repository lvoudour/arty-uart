# set output directories
set REPORTS_DIR ./reports
set BITSTREAM_DIR ./bit

if {![file isdirectory $REPORTS_DIR]} {
    file mkdir $REPORTS_DIR
}

if {![file isdirectory $BITSTREAM_DIR]} {
    file mkdir $BITSTREAM_DIR
}

# set source directory
set HDL_PATH ../../src/hdl

# set top module
set TOP_MODULE uart_loopback

# Source files
read_vhdl -library work $HDL_PATH/fifo_srl.vhd
read_vhdl -library work $HDL_PATH/uart_tx.vhd
read_vhdl -library work $HDL_PATH/uart_rx.vhd
read_vhdl -library work $HDL_PATH/uart.vhd
read_vhdl -library work uart_loopback.vhd
read_xdc uart_loopback.xdc

# Synthesis
synth_design -top $TOP_MODULE -part xc7a35ticsg324-1L
write_checkpoint -force $REPORTS_DIR/post_synth.dcp
report_timing_summary -file $REPORTS_DIR/post_synth_timing_summary.rpt
report_utilization -file $REPORTS_DIR/post_synth_util.rpt -verbose

# Optimize & place
opt_design
place_design
write_checkpoint -force $REPORTS_DIR/post_place.dcp
report_clock_utilization -file $REPORTS_DIR/clock_util.rpt
report_utilization -file $REPORTS_DIR/post_place_util.rpt -verbose
report_timing_summary -file $REPORTS_DIR/post_place_timing_summary.rpt

# Route
route_design
write_checkpoint -force $REPORTS_DIR/post_route.dcp
report_route_status -file $REPORTS_DIR/post_route_status.rpt
report_timing_summary -file $REPORTS_DIR/post_route_timing_summary.rpt
report_power -file $REPORTS_DIR/post_route_power.rpt
report_drc -file $REPORTS_DIR/post_imp_drc.rpt

write_bitstream -force $BITSTREAM_DIR/$TOP_MODULE.bit
