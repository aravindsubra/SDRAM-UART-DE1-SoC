module sdram_ctrl(
    input clk_100MHz,        // Main clock (assumed 100MHz)
    input rst_n,             // Active-low reset
    // SDRAM Physical Interface
    output reg [12:0] sdram_addr,  // 13-bit address bus
    output reg [1:0] sdram_ba,     // Bank address
    output reg sdram_cas_n,        // Column Address Strobe
    output reg sdram_cke,          // Clock Enable (always on)
    output reg sdram_cs_n,         // Chip Select
    inout [15:0] sdram_dq,         // Bidirectional data bus
    output reg sdram_ras_n,        // Row Address Strobe
    output reg sdram_we_n,         // Write Enable
    // Control Interface
    input [23:0] addr,       // 24-bit memory address
    input rd_req,            // Read request
    output reg [15:0] rd_data, // Read data output
    output reg rd_ready      // Read completion signal
);

// Timing Parameters (in clock cycles)
parameter tRP   = 3'd2;   // Precharge to Active delay (20ns @100MHz)
parameter tRCD  = 3'd2;   // Row to Column delay (20ns)
parameter tCAS  = 3'd3;   // CAS Latency (CL=3)

// Controller States
localparam INIT=0, IDLE=1, ACTIVE=2, READ=3, PRECHARGE=4, MODE_REG=5, REFRESH=6;
reg [3:0] state;           // Current state
reg [3:0] init_counter;    // General-purpose counter (4-bit)

// Data Bus Control
reg [15:0] sdram_dq_out;   // Data output buffer
reg sdram_dq_oe;           // Output enable
assign sdram_dq = sdram_dq_oe ? sdram_dq_out : 16'bz;  // Tri-state buffer

// Refresh Management
localparam REFRESH_INTERVAL = 1560;  // Refresh 3.9 microsecond per row period @100mhz
reg [9:0] refresh_counter;          // Refresh interval counter
reg refresh_req;                    // Refresh request flag

// Refresh Counter Logic
always @(posedge clk_100MHz or negedge rst_n) begin
    if(!rst_n) begin
        refresh_counter <= 0;
        refresh_req <= 0;
    end else begin
        if (refresh_counter >= REFRESH_INTERVAL) begin
            refresh_counter <= 0;
            refresh_req <= 1;  // Single-cycle pulse
        end else begin
            refresh_counter <= refresh_counter + 1;
            refresh_req <= 0;
        end
    end
end

// Main State Machine
always @(posedge clk_100MHz or negedge rst_n) begin
    if(!rst_n) begin
        // Reset initialization
        state <= INIT;
        {sdram_cs_n, sdram_ras_n, sdram_cas_n, sdram_we_n} <= 4'b1111; // NOP
        sdram_cke <= 1'b1;       // Keep clock enabled
        init_counter <= 0;
        rd_ready <= 0;
    end else begin
        rd_ready <= 0;  // Default value
        case(state)
            INIT: begin  // Initialization phase
                // Wait 200 cycles (insufficient for actual 200μs initialization)
                if(init_counter < 200) init_counter <= init_counter + 1;
                else state <= PRECHARGE;
            end
            
            PRECHARGE: begin  // Precharge all banks
                // Command: 0010 (CS#, RAS#, CAS#, WE#)
                {sdram_cs_n, sdram_ras_n, sdram_cas_n, sdram_we_n} <= 4'b0010;
                sdram_addr[10] <= 1'b1;  // Precharge all banks
                state <= MODE_REG;  // Missing tRP delay!
            end
            
            MODE_REG: begin  // Load mode register
                // Command: 0000 (Mode Register Set)
                {sdram_cs_n, sdram_ras_n, sdram_cas_n, sdram_we_n} <= 4'b0000;
                // Burst=1, CL=3, Seq Burst
                sdram_addr <= {3'b000, 1'b0, 2'b00, 3'b011, 1'b0, 3'b000};
                state <= IDLE;  // Missing mode register delay!
            end
            
            IDLE: begin  // Main idle state
                {sdram_cs_n, sdram_ras_n, sdram_cas_n, sdram_we_n} <= 4'b1111; // NOP
                if(refresh_req) state <= REFRESH;
                else if(rd_req) begin
                    sdram_ba <= addr[23:22];     // Bank address
                    sdram_addr <= addr[21:9];    // Row address
                    state <= ACTIVE;
                end
            end
            
            ACTIVE: begin  // Row activation
                // Command: 0011 (Active)
                {sdram_cs_n, sdram_ras_n, sdram_cas_n, sdram_we_n} <= 4'b0011;
                if(init_counter < tRCD) init_counter <= init_counter + 1;
                else begin
                    init_counter <= 0;
                    sdram_addr <= {3'b0, addr[8:0]};  // Column address
                    state <= READ;
                end
            end
            
            READ: begin  // Read with auto-precharge
                // Command: 0101 (Read)
                {sdram_cs_n, sdram_ras_n, sdram_cas_n, sdram_we_n} <= 4'b0101;
                if(init_counter < tCAS) init_counter <= init_counter + 1;
                else begin
                    rd_data <= sdram_dq;  // Capture data
                    rd_ready <= 1'b1;     // Signal completion
                    state <= PRECHARGE;   // Auto-precharge
                end
            end
            
            REFRESH: begin  // Auto-refresh
                // Command: 0001 (Auto Refresh)
                {sdram_cs_n, sdram_ras_n, sdram_cas_n, sdram_we_n} <= 4'b0001;
                state <= IDLE;  // Missing tRFC delay!
            end
        endcase
    end
end

endmodule


