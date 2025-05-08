module sdram_ctrl(
    input clk_100MHz,
    input rst_n,
    // SDRAM Interface
    output reg [12:0] sdram_addr,
    output reg [1:0] sdram_ba,
    output reg sdram_cas_n,
    output reg sdram_cke,
    output reg sdram_cs_n,
    inout [15:0] sdram_dq,
    output reg sdram_ras_n,
    output reg sdram_we_n,
    // Control Interface
    input [23:0] addr,
    input rd_req,
    output reg [15:0] rd_data,
    output reg rd_ready
);

parameter tRP   = 3'd2;   // 20ns
parameter tRCD  = 3'd2;   // 20ns
parameter tCAS  = 3'd3;   // CL=3 cycles

localparam INIT=0, IDLE=1, ACTIVE=2, READ=3, PRECHARGE=4, MODE_REG=5, REFRESH=6;
reg [3:0] state;
reg [3:0] init_counter;

reg [15:0] sdram_dq_out;
reg sdram_dq_oe;
assign sdram_dq = sdram_dq_oe ? sdram_dq_out : 16'bz;

// Refresh logic

localparam REFRESH_INTERVAL = 780; // 7.8us at 100MHz
reg [9:0] refresh_counter; // Enough bits for 780
reg refresh_req;

always @(posedge clk_100MHz or negedge rst_n) begin
    if(!rst_n) begin
        refresh_counter <= 0;
        refresh_req <= 0;
    end else begin
        if (refresh_counter >= REFRESH_INTERVAL) begin
            refresh_counter <= 0;
            refresh_req <= 1;
        end else begin
            refresh_counter <= refresh_counter + 1;
            refresh_req <= 0;
        end
    end
end

always @(posedge clk_100MHz or negedge rst_n) begin
    if(!rst_n) begin
        state <= INIT;
        {sdram_cs_n, sdram_ras_n, sdram_cas_n, sdram_we_n} <= 4'b1111;
        sdram_cke <= 1'b1;
        init_counter <= 0;
        rd_ready <= 0;
    end else begin
        rd_ready <= 0;
        case(state)
            INIT: begin
                if(init_counter < 200)
                    init_counter <= init_counter + 1;
                else
                    state <= PRECHARGE;
            end
            PRECHARGE: begin
                {sdram_cs_n, sdram_ras_n, sdram_cas_n, sdram_we_n} <= 4'b0010;
                sdram_addr[10] <= 1'b1;
                state <= MODE_REG;
            end
            MODE_REG: begin
                {sdram_cs_n, sdram_ras_n, sdram_cas_n, sdram_we_n} <= 4'b0000;
                sdram_addr <= {3'b000, 1'b0, 2'b00, 3'b011, 1'b0, 3'b000};
                state <= IDLE;
            end
            IDLE: begin
                {sdram_cs_n, sdram_ras_n, sdram_cas_n, sdram_we_n} <= 4'b1111;
                if(refresh_req) begin
                    state <= REFRESH;
                end else if(rd_req) begin
                    sdram_ba <= addr[23:22];
                    sdram_addr <= addr[21:9];
                    state <= ACTIVE;
                end
            end
            ACTIVE: begin
                {sdram_cs_n, sdram_ras_n, sdram_cas_n, sdram_we_n} <= 4'b0011;
                if(init_counter < tRCD)
                    init_counter <= init_counter + 1;
                else begin
                    init_counter <= 0;
                    sdram_addr <= {3'b0, addr[8:0]};
                    state <= READ;
                end
            end
            READ: begin
                {sdram_cs_n, sdram_ras_n, sdram_cas_n, sdram_we_n} <= 4'b0101;
                if(init_counter < tCAS)
                    init_counter <= init_counter + 1;
                else begin
                    rd_data <= sdram_dq;
                    rd_ready <= 1'b1;
                    state <= PRECHARGE;
                end
            end
            REFRESH: begin
                // Issue AUTO REFRESH command: CS=0, RAS=0, CAS=0, WE=1
                {sdram_cs_n, sdram_ras_n, sdram_cas_n, sdram_we_n} <= 4'b0001;
                // Wait one cycle for refresh, then return to IDLE
                state <= IDLE;
            end
        endcase
    end
end

endmodule

