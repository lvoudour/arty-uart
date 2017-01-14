
if {[file exists work]} {
    vdel -all
}
vlib work
vmap work work

vcom -work work ../src/hdl/fifo_srl.vhd
vcom -work work ../src/hdl/uart_tx.vhd
vcom -work work ../src/hdl/uart_rx.vhd
vcom -work work ../src/hdl/uart.vhd
vcom -work work ./tb_uart.vhd

vsim tb_uart

# Uncomment if running in gui
# add wave *
run 100us


