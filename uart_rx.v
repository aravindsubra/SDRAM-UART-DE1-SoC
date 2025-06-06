module uart_rx(
    input clk,              // System clock (50MHz)
    input rst_n,            // Active-low reset
    input rx,               // Serial input line
    output reg [7:0] data,  // Received data
    output reg data_valid   // Data valid pulse
);

parameter CLK_FREQ = 50_000_000;  // System clock frequency
parameter BAUD_RATE = 115200;     // Target baud rate
localparam BAUD_TICK = CLK_FREQ/(BAUD_RATE*16);  // Oversampling counter (27)

// Internal registers
reg [15:0] baud_counter;   // Baud rate counter
reg [3:0] bit_index;       // Bit position counter
reg rx_busy;               // Reception in progress flag
reg rx_sync;               // Single-stage synchronizer (insufficient)

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        // Reset initialization
        data_valid <= 0;
        rx_busy <= 0;
        baud_counter <= 0;
        bit_index <= 0;
        rx_sync <= 1;      // Assume idle state
    end else begin
        data_valid <= 0;   // Single-cycle pulse
        rx_sync <= rx;     // Single-stage synchronization (issue #1)
        
        if (rx_busy) begin
            if (baud_counter == BAUD_TICK-1) begin
                baud_counter <= 0;
                if (bit_index == 8) begin  // After 8 data bits
                    rx_busy <= 0;
                    data_valid <= 1;       // Missing stop bit check
                end else begin
                    data[bit_index] <= rx_sync;  // Single sample (issue #2)
                    bit_index <= bit_index + 1;
                end
            end else begin
                baud_counter <= baud_counter + 1;
            end
        end else if (!rx_sync) begin  // Start bit detection
            rx_busy <= 1;
            bit_index <= 0;
            baud_counter <= BAUD_TICK/2;  // Middle of start bit
        end
    end
end
endmodule
