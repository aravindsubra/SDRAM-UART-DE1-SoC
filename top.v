module top(
    input CLOCK_50,
    input [3:0] KEY,
    // SDRAM Interface
    output [12:0] DRAM_ADDR,
    output [1:0] DRAM_BA,
    output DRAM_CAS_N,
    output DRAM_CKE,
    output DRAM_CS_N,
    inout [15:0] DRAM_DQ,
    output DRAM_RAS_N,
    output DRAM_WE_N,
    // UART
    input FPGA_UART_RX,
    output FPGA_UART_TX
);

wire [7:0] uart_rx_data;
wire uart_rx_valid;
reg [7:0] uart_tx_data;
reg uart_tx_send;

sdram_ctrl controller(
    .clk_100MHz(CLOCK_50),
    .rst_n(KEY[0]),
    .sdram_addr(DRAM_ADDR),
    .sdram_ba(DRAM_BA),
    .sdram_cas_n(DRAM_CAS_N),
    .sdram_cke(DRAM_CKE),
    .sdram_cs_n(DRAM_CS_N),
    .sdram_dq(DRAM_DQ),
    .sdram_ras_n(DRAM_RAS_N),
    .sdram_we_n(DRAM_WE_N),
    .addr({16'h0000, uart_rx_data}),
    .rd_req(uart_rx_valid),
    .rd_data(),
    .rd_ready()
);

uart_rx rx(
    .clk(CLOCK_50),
    .rst_n(KEY[0]),
    .rx(FPGA_UART_RX),
    .data(uart_rx_data),
    .data_valid(uart_rx_valid)
);

uart_tx tx(
    .clk(CLOCK_50),
    .rst_n(KEY[0]),
    .data(uart_tx_data),
    .send(uart_tx_send),
    .tx(FPGA_UART_TX),
    .busy()
);

endmodule

