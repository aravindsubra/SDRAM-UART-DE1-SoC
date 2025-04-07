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
    // UART Interface
    input FPGA_UART_RX,
    output FPGA_UART_TX
);

wire [7:0] uart_rx_data;
wire uart_rx_valid;
wire [15:0] sdram_data;
wire sdram_rd_valid;
reg [23:0] sdram_addr;
reg [15:0] sdram_wr_data;
reg rd_req, wr_req;

uart_rx u_rx(
    .clk(CLOCK_50),
    .rst_n(KEY[0]),
    .rx(FPGA_UART_RX),
    .data(uart_rx_data),
    .data_valid(uart_rx_valid)
);

sdram_ctrl sdram(
    .clk_100MHz(CLOCK_50),
    .rst_n(KEY[0]),
    .sdram_addr(DRAM_ADDR),
    .sdram_ba(DRAM_BA),
    .sdram_cas_n(DRAM_CAS_N),
    .sdram_cke(DRAM_CKE),
    .sdram_cs_n(DRAM_CS_N),
    .sdram_dq(DRAM_DQ),
    .sdram_dqm(),
    .sdram_ras_n(DRAM_RAS_N),
    .sdram_we_n(DRAM_WE_N),
    .addr(sdram_addr),
    .rd_req(rd_req),
    .wr_req(wr_req),
    .wr_data(sdram_wr_data),
    .rd_data(sdram_data),
    .rd_valid(sdram_rd_valid),
    .wr_ready()
);

uart_tx u_tx(
    .clk(CLOCK_50),
    .rst_n(KEY[0]),
    .data({sdram_data[7:0], sdram_data[15:8]}), // Send both bytes
    .send(sdram_rd_valid),
    .tx(FPGA_UART_TX),
    .busy()
);

// Command Processor
reg [2:0] cmd_state;
always @(posedge CLOCK_50 or negedge KEY[0]) begin
    if (!KEY[0]) begin
        cmd_state <= 0;
        sdram_addr <= 0;
        sdram_wr_data <= 0;
        rd_req <= 0;
        wr_req <= 0;
    end else begin
        case(cmd_state)
            0: begin
                rd_req <= 0;
                wr_req <= 0;
                if (uart_rx_valid) begin
                    case(uart_rx_data)
                        8'h52: cmd_state <= 1; // 'R'
                        8'h57: cmd_state <= 4; // 'W'
                    endcase
                end
            end
            
            1: begin // Read address byte 2
                sdram_addr[23:16] <= uart_rx_data;
                cmd_state <= 2;
            end
            
            2: begin // Read address byte 1
                sdram_addr[15:8] <= uart_rx_data;
                cmd_state <= 3;
            end
            
            3: begin // Read address byte 0
                sdram_addr[7:0] <= uart_rx_data;
                rd_req <= 1'b1;
                cmd_state <= 0;
            end
            
            4: begin // Write address byte 2
                sdram_addr[23:16] <= uart_rx_data;
                cmd_state <= 5;
            end
            
            5: begin // Write address byte 1
                sdram_addr[15:8] <= uart_rx_data;
                cmd_state <= 6;
            end
            
            6: begin // Write address byte 0
                sdram_addr[7:0] <= uart_rx_data;
                cmd_state <= 7;
            end
            
            7: begin // Write data byte 1
                sdram_wr_data[15:8] <= uart_rx_data;
                cmd_state <= 8;
            end
            
            8: begin // Write data byte 0
                sdram_wr_data[7:0] <= uart_rx_data;
                wr_req <= 1'b1;
                cmd_state <= 0;
            end
        endcase
    end
end

endmodule
