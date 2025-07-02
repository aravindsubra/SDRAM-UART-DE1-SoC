module uart_rx(
    input clk,              // 50MHz system clock
    input rst_n,            // Active-low reset
    input rx,               // UART RX line
    output reg [7:0] data,  // Received data
    output reg data_valid   // Data valid pulse
);

parameter CLK_FREQ = 50_000_000;
parameter BAUD_RATE = 115200;
localparam BAUD_TICK = CLK_FREQ / BAUD_RATE;  // 434

reg [15:0] baud_counter;
reg [3:0] bit_index;
reg rx_busy;
reg [9:0] rx_shift;
reg rx_sync1, rx_sync2;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        data_valid <= 0;
        rx_busy <= 0;
        baud_counter <= 0;
        bit_index <= 0;
        rx_shift <= 0;
        rx_sync1 <= 1;
        rx_sync2 <= 1;
    end else begin
        data_valid <= 0;
        rx_sync1 <= rx;
        rx_sync2 <= rx_sync1;
        if (!rx_busy) begin
            if (!rx_sync2) begin // Start bit detected
                rx_busy <= 1;
                baud_counter <= BAUD_TICK/2;
                bit_index <= 0;
            end
        end else begin
            if (baud_counter == BAUD_TICK-1) begin
                baud_counter <= 0;
                bit_index <= bit_index + 1;
                rx_shift <= {rx_sync2, rx_shift[9:1]};
                if (bit_index == 9) begin // Stop bit
                    rx_busy <= 0;
                    if (rx_shift[0] == 0 && rx_sync2 == 1) begin // Valid start/stop
                        data <= rx_shift[8:1];
                        data_valid <= 1;
                    end
                end
            end else begin
                baud_counter <= baud_counter + 1;
            end
        end
    end
end
endmodule
