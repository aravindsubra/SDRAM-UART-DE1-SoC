module sdram_ctrl(
    input clk,             // 50MHz clock
    input rst_n,
    output reg [12:0] sdram_addr,
    output reg [1:0] sdram_ba,
    output reg sdram_cas_n,
    output reg sdram_cke,
    output reg sdram_cs_n,
    inout [15:0] sdram_dq,
    output reg sdram_ras_n,
    output reg sdram_we_n,
    input [23:0] addr,
    input rd_req,
    input wr_req,
    input [15:0] wr_data,
    output reg [15:0] rd_data,
    output reg rd_ready,
    output reg wr_ready
);

// Timing for 167MHz (6ns per cycle): tRP=3, tRCD=3, tCAS=3, tMRD=2
parameter tINIT  = 33_333; // 200us / 6ns = ~33,333 cycles @167MHz
parameter tRP    = 3;      // 18ns
parameter tRCD   = 3;      // 18ns
parameter tCAS   = 3;      // 18ns
parameter tMRD   = 2;      // 12ns

// Refresh interval per row is 62.5 microseconds
parameter REFRESH_INTERVAL_PER_ROW = 16'd6250;

localparam INIT=0, PRECHARGE=1, MODE_REG=2, IDLE=3, ACT=4, WRITE=5, READ=6, DONE=7;

reg [3:0] state;
reg [15:0] timer;
reg [15:0] dq_out;
reg dq_oe;

assign sdram_dq = dq_oe ? dq_out : 16'bz;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= INIT;
        {sdram_cs_n, sdram_ras_n, sdram_cas_n, sdram_we_n} <= 4'b1111;
        sdram_cke <= 1'b1;
        timer <= 0;
        dq_oe <= 0;
        rd_ready <= 0;
        wr_ready <= 0;
    end else begin
        rd_ready <= 0;
        wr_ready <= 0;
        case(state)
            INIT: begin
                if (timer < tINIT) timer <= timer + 1;
                else begin timer <= 0; state <= PRECHARGE; end
            end
            PRECHARGE: begin
                {sdram_cs_n, sdram_ras_n, sdram_cas_n, sdram_we_n} <= 4'b0010;
                sdram_addr[10] <= 1'b1;
                timer <= 0;
                state <= MODE_REG;
            end
            MODE_REG: begin
                if (timer < tMRD) timer <= timer + 1;
                else begin
                    {sdram_cs_n, sdram_ras_n, sdram_cas_n, sdram_we_n} <= 4'b0000;
                    sdram_addr <= 13'b000_0_00_011_0_000; // CL=3, Burst=1
                    timer <= 0;
                    state <= IDLE;
                end
            end
            IDLE: begin
                dq_oe <= 0;
                if (wr_req) begin
                    sdram_ba <= addr[23:22];
                    sdram_addr <= addr[21:9];
                    timer <= 0;
                    state <= ACT;
                end else if (rd_req) begin
                    sdram_ba <= addr[23:22];
                    sdram_addr <= addr[21:9];
                    timer <= 0;
                    state <= ACT;
                end
            end
            ACT: begin
                {sdram_cs_n, sdram_ras_n, sdram_cas_n, sdram_we_n} <= 4'b0011;
                if (timer < tRCD) timer <= timer + 1;
                else begin
                    timer <= 0;
                    if (wr_req) state <= WRITE;
                    else state <= READ;
                end
            end
            WRITE: begin
                {sdram_cs_n, sdram_ras_n, sdram_cas_n, sdram_we_n} <= 4'b0100;
                sdram_addr <= {3'b0, addr[8:0]};
                dq_out <= wr_data;
                dq_oe <= 1;
                wr_ready <= 1;
                timer <= 0;
                state <= DONE;
            end
            READ: begin
                {sdram_cs_n, sdram_ras_n, sdram_cas_n, sdram_we_n} <= 4'b0101;
                sdram_addr <= {3'b0, addr[8:0]};
                dq_oe <= 0;
                if (timer < tCAS) timer <= timer + 1;
                else begin
                    rd_data <= sdram_dq;
                    rd_ready <= 1;
                    timer <= 0;
                    state <= DONE;
                end
            end
            DONE: begin
                dq_oe <= 0;
                state <= IDLE;
            end
        endcase
    end
end

endmodule
