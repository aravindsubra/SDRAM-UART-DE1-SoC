module uart_tx(
    input rst_n,            // Active-low reset
    input clk,              // System clock (50MHz)
    input [7:0] data,       // Parallel data input
    input send,             // Transmission trigger (should be pulsed)
    output reg tx,          // Serial output line
    output reg busy         // Transmission status indicator
);

// Timing parameters
parameter CLK_FREQ = 50_000_000;  // 50MHz system clock
parameter BAUD_RATE = 115200;     // Target baud rate
localparam BAUD_TICK = CLK_FREQ/(BAUD_RATE*16);  // Incorrect baud divisor

// Internal registers
reg [15:0] baud_counter;   // Clock cycle counter for baud timing
reg [3:0] bit_index;       // Bit position counter (0-9)
reg [9:0] tx_shift;        // Shift register: [stop|data|start]

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        // Reset initialization
        tx <= 1'b1;         // Maintain idle state (high)
        busy <= 0;          // Not transmitting
        baud_counter <= 0;
        bit_index <= 0;
    end else begin
        if (busy) begin
            if (baud_counter == BAUD_TICK-1) begin
                baud_counter <= 0;
                if (bit_index == 9) begin
                    busy <= 0;          // Transmission complete
                    tx <= 1'b1;         // Return to idle state
                end else begin
                    tx <= tx_shift[bit_index];  // Output current bit
                    bit_index <= bit_index + 1; // Next bit position
                end
            end else begin
                baud_counter <= baud_counter + 1;  // Count clock cycles
            end
        end else if (send) begin
            // Start new transmission
            tx_shift <= {1'b1, data, 1'b0};  // Format: [Stop|Data|Start]
            busy <= 1;          // Mark as transmitting
            bit_index <= 0;     // Start with start bit
            baud_counter <= 0;  // Reset timing counter
        end
    end
end
endmodule
