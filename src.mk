
XDC_SRC_REL  += \
              $(BUILD_DIR)/uart_loopback.xdc

VHDL_SRC_REL += \
              $(SRC_DIR)/fifo_srl.vhd \
              $(SRC_DIR)/uart_tx.vhd \
              $(SRC_DIR)/uart_rx.vhd \
              $(SRC_DIR)/uart.vhd

TB_SRC_REL   += \
              $(VHDL_SRC_REL) \
              $(SIM_DIR)/tb_uart.vhd

BUILD_SRC_REL += \
              $(VHDL_SRC_REL) \
              $(BUILD_DIR)/uart_loopback.vhd