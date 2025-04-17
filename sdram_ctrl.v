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

// Timing Parameters (MT48LC16M16A2 @100MHz)
parameter tRP   = 3'd2;  // 20ns
parameter tRCD  = 3'd2;  // 20ns
parameter tCAS  = 3'd3;  // CL=3 cycles
parameter tRFC  = 3'd7;  // 70ns

// State Machine (Expanded with refresh states)
localparam INIT=0, IDLE=1, ACTIVE=2, READ=3, WRITE=4, 
           PRECHARGE=5, MODE_REG=6, REFRESH1=7, REFRESH2=8;
reg [3:0] state;  // Increased to 4-bit width

// Counters
reg [3:0] init_counter;
reg [15:0] refresh_counter;

// Tri-state buffer
reg [15:0] sdram_dq_out;
reg sdram_dq_oe;
assign sdram_dq = sdram_dq_oe ? sdram_dq_out : 16'bz;

// Initialization Sequence (Fixed)
always @(posedge clk_100MHz or negedge rst_n) begin
    if(!rst_n) begin
        state <= INIT;
        {sdram_cs_n, sdram_ras_n, sdram_cas_n, sdram_we_n} <= 4'b1111;
        sdram_cke <= 1'b1;
        init_counter <= 0;
        refresh_counter <= 0;
    end else begin
        case(state)
            INIT: begin
                if(init_counter < 200) // Wait 200us
                    init_counter <= init_counter + 1;
                else
                    state <= PRECHARGE;
            end
            
            PRECHARGE: begin
                {sdram_cs_n, sdram_ras_n, sdram_cas_n, sdram_we_n} <= 4'b0010;
                sdram_addr[10] <= 1'b1; // Precharge all banks
                state <= REFRESH1;
            end
            
            REFRESH1: begin
                {sdram_cs_n, sdram_ras_n, sdram_cas_n, sdram_we_n} <= 4'b0001;
                state <= REFRESH2;
            end
            
            REFRESH2: begin
                {sdram_cs_n, sdram_ras_n, sdram_cas_n, sdram_we_n} <= 4'b0001;
                state <= MODE_REG;
            end
            
            MODE_REG: begin
                {sdram_cs_n, sdram_ras_n, sdram_cas_n, sdram_we_n} <= 4'b0000;
                sdram_addr <= {3'b000, 1'b0, 2'b00, 3'b011, 1'b0, 3'b000}; // CL=3, BL=8
                state <= IDLE;
            end
            
            IDLE: begin
                {sdram_cs_n, sdram_ras_n, sdram_cas_n, sdram_we_n} <= 4'b1111;
                if(rd_req) begin
                    sdram_ba <= addr[23:22];     // Bank
                    sdram_addr <= addr[21:9];    // Row
                    state <= ACTIVE;
                end
            end
            
            ACTIVE: begin
                {sdram_cs_n, sdram_ras_n, sdram_cas_n, sdram_we_n} <= 4'b0011;
                if(init_counter < tRCD)
                    init_counter <= init_counter + 1;
                else begin
                    init_counter <= 0;
                    sdram_addr <= {3'b0, addr[8:0]}; // Column
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
            
            PRECHARGE: begin
                {sdram_cs_n, sdram_ras_n, sdram_cas_n, sdram_we_n} <= 4'b0010;
                state <= IDLE;
            end
        endcase
    end
end

endmodule
