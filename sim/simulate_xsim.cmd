@echo off

:: Change to point to your Vivado installation directory
set XILINX_VIVADO=C:\Xilinx\Vivado\2016.3

:: Put Xilinx tools in the path
set OLD_PATH=%PATH%
set PATH=%XILINX_VIVADO%\bin;%XILINX_VIVADO%\lib\win64.o;%PATH%

call xvhdl -work work ../src/hdl/fifo_srl.vhd
call xvhdl -work work ../src/hdl/uart_tx.vhd
call xvhdl -work work ../src/hdl/uart_rx.vhd
call xvhdl -work work ../src/hdl/uart.vhd
call xvhdl -work work ./tb_uart.vhd

call xelab -debug typical -s top tb_uart

:: Uncomment this line to run simulation in gui
:: call xsim -gui -t simulate_xsim.tcl top
call xsim -t simulate_xsim.tcl top

:: reset path
set PATH=%OLD_PATH%
set XILINX_VIVADO=