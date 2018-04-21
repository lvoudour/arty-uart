if { $argc != 4 } {
    puts "ERROR: build.tcl requires 4 arguments. Please try again."
    exit -1
}

# set output directories
set REPORTS_DIR ./reports
set BITSTREAM_DIR ./bit

if {![file isdirectory $REPORTS_DIR]} {
    file mkdir $REPORTS_DIR
}

if {![file isdirectory $BITSTREAM_DIR]} {
    file mkdir $BITSTREAM_DIR
}

set TOP_MODULE [lindex $argv 2]
set PART [lindex $argv 3]

foreach src [lindex $argv 0] {
  read_vhdl -vhdl2008 -library work $src
}

foreach src [lindex $argv 1] {
  read_xdc $src
}

# Synthesis
synth_design -top $TOP_MODULE -part $PART
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
