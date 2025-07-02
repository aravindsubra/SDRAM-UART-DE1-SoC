module top(
    input CLOCK_50,
    input [3:0] KEY,
    output [12:0] DRAM_ADDR,
    output [1:0] DRAM_BA,
    output DRAM_CAS_N,
    output DRAM_CKE,
    output DRAM_CS_N,
    inout [15:0] DRAM_DQ,
    output DRAM_RAS_N,
    output DRAM_WE_N,
    input FPGA_UART_RX,
    output FPGA_UART_TX
);

// UART RX
wire [7:0] uart_rx_data;
wire uart_rx_valid;

// UART TX
wire [7:0] uart_tx_data;
wire uart_tx_send;
wire uart_tx_busy;

// SDRAM
reg [23:0] sdram_addr;
reg sdram_rd_req, sdram_wr_req;
reg [15:0] sdram_wr_data;
wire [15:0] sdram_rd_data;
wire sdram_rd_ready, sdram_wr_ready;

// Simple command FSM (expand as needed)
always @(*) begin
    sdram_addr = {16'h0000, uart_rx_data};
    sdram_rd_req = uart_rx_valid; // Example: trigger read on each UART RX
    sdram_wr_req = 1'b0;          // Connect to your write logic if needed
    sdram_wr_data = 16'hFFFF;     // Example: always write all 1's
end

sdram_ctrl controller(
    .clk(CLOCK_50),
    .rst_n(KEY[0]),
    .sdram_addr(DRAM_ADDR),
    .sdram_ba(DRAM_BA),
    .sdram_cas_n(DRAM_CAS_N),
    .sdram_cke(DRAM_CKE),
    .sdram_cs_n(DRAM_CS_N),
    .sdram_dq(DRAM_DQ),
    .sdram_ras_n(DRAM_RAS_N),
    .sdram_we_n(DRAM_WE_N),
    .addr(sdram_addr),
    .rd_req(sdram_rd_req),
    .wr_req(sdram_wr_req),
    .wr_data(sdram_wr_data),
    .rd_data(sdram_rd_data),
    .rd_ready(sdram_rd_ready),
    .wr_ready(sdram_wr_ready)
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
    .busy(uart_tx_busy)
);

endmodule
