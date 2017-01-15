@echo off
:: Change to point to your Vivado installation directory
set XILINX_VIVADO=C:\Xilinx\Vivado\2016.3

:: Put Xilinx tools in the path
set OLD_PATH=%PATH%
set PATH=%XILINX_VIVADO%\bin;%XILINX_VIVADO%\lib\win64.o;%PATH%

if not exist log mkdir log
call vivado -log log/vivado.log -journal log/vivado.jou -mode batch -source build.tcl

set PATH=%OLD_PATH%
set XILINX_VIVADO=