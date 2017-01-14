:: Modelsim executable (vsim) must be in windows PATH. Otherwise use full path to vsim
@echo off

:: Uncomment to run simulation in gui
:: vsim -gui -do "simulate_mti.tcl"
vsim < "simulate_mti.tcl"