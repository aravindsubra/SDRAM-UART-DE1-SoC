// Top-level module declaration
module top(
    // 50 MHz clock input (common FPGA clock)
    input CLOCK_50,
    // Active-low reset (KEY[0]) and other buttons
    input [3:0] KEY,
    
    // SDRAM Interface (DRAM Chip Control Signals)
    output [12:0] DRAM_ADDR,  // 13-bit address bus
    output [1:0] DRAM_BA,     // Bank address
    output DRAM_CAS_N,        // Column Address Strobe (active low)
    output DRAM_CKE,          // Clock Enable
    output DRAM_CS_N,         // Chip Select (active low)
    inout [15:0] DRAM_DQ,     // Bidirectional data bus
    output DRAM_RAS_N,        // Row Address Strobe (active low)
    output DRAM_WE_N,         // Write Enable (active low)
    
    // UART Interface
    input FPGA_UART_RX,       // UART Receive line
    output FPGA_UART_TX       // UART Transmit line
);

// UART Receive Signals
wire [7:0] uart_rx_data;     // Received byte from UART
wire uart_rx_valid;          // High when data is valid

// UART Transmit Signals
reg [7:0] uart_tx_data;      // Data to transmit
reg uart_tx_send;            // Pulse to start transmission

// Instantiate SDRAM Controller
sdram_ctrl controller(
    .clk_100MHz(CLOCK_50),   // Potential issue: Using 50MHz clock as 100MHz
    .rst_n(KEY[0]),          // Active-low reset from KEY[0]
    // SDRAM Physical Interface
    .sdram_addr(DRAM_ADDR),
    .sdram_ba(DRAM_BA),
    .sdram_cas_n(DRAM_CAS_N),
    .sdram_cke(DRAM_CKE),
    .sdram_cs_n(DRAM_CS_N),
    .sdram_dq(DRAM_DQ),
    .sdram_ras_n(DRAM_RAS_N),
    .sdram_we_n(DRAM_WE_N),
    // Memory Interface
    .addr({16'h0000, uart_rx_data}),  // Combines static upper bits with UART input
    .rd_req(uart_rx_valid),  // Read request triggered by UART receive
    .rd_data(),              // Unused read data (potential issue)
    .rd_ready()              // Unused ready signal
);

// UART Receiver Instance
uart_rx rx(
    .clk(CLOCK_50),
    .rst_n(KEY[0]),
    .rx(FPGA_UART_RX),
    .data(uart_rx_data),
    .data_valid(uart_rx_valid)
);

// UART Transmitter Instance
uart_tx tx(
    .clk(CLOCK_50),
    .rst_n(KEY[0]),
    .data(uart_tx_data),
    .send(uart_tx_send),
    .tx(FPGA_UART_TX),
    .busy()                  // Unused busy signal
);

endmodule
