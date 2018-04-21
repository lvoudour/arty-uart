# onerror {quit -f}

if {[file exists work]} {
    vdel -all
}
vlib work
vmap work work

set TOP_MODULE $2

foreach src $1 {
  vcom -work work $src
}

vsim -L unisim tb_$TOP_MODULE


add log -r *
add wave *

run 100us
