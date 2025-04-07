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
    output reg [1:0] sdram_dqm,
    output reg sdram_ras_n,
    output reg sdram_we_n,
    // Control Interface
    input [23:0] addr,
    input rd_req,
    input wr_req,
    input [15:0] wr_data,
    output reg [15:0] rd_data,
    output reg rd_valid,  // Changed from rd_ready
    output reg wr_ready
);

parameter tRP = 2, tRCD = 2, tCAS = 2;
localparam INIT=0, IDLE=1, ACTIVE=2, READ=3, WRITE=4, PRECHARGE=5;

reg [3:0] state;
reg [3:0] init_cnt;
reg [15:0] data_out;
reg [1:0] cas_counter;

// Correct address decomposition
wire [1:0]  bank_addr = addr[23:22];
wire [12:0] row_addr  = addr[21:9];
wire [9:0]  col_addr  = {1'b0, addr[8:0]};

always @(posedge clk_100MHz or negedge rst_n) begin
    if (!rst_n) begin
        state <= INIT;
        init_cnt <= 0;
        {sdram_cs_n, sdram_ras_n, sdram_cas_n, sdram_we_n} <= 4'b1111;
        sdram_cke <= 1'b1;
        sdram_dqm <= 2'b00;
        cas_counter <= 0;
    end else begin
        case(state)
            INIT: begin
                if (init_cnt < 8) init_cnt <= init_cnt + 1;
                case(init_cnt)
                    0: {sdram_cs_n, sdram_ras_n, sdram_cas_n, sdram_we_n} <= 4'b0111; // Precharge
                    2: {sdram_cs_n, sdram_ras_n, sdram_cas_n, sdram_we_n} <= 4'b0011; // Refresh
                    4: {sdram_cs_n, sdram_ras_n, sdram_cas_n, sdram_we_n} <= 4'b0011; // Refresh
                    6: {sdram_cs_n, sdram_ras_n, sdram_cas_n, sdram_we_n} <= 4'b0000; // Mode register
                    8: state <= IDLE;
                endcase
            end
            
            IDLE: begin
                rd_valid <= 0;
                if (wr_req) begin
                    sdram_addr <= row_addr;
                    sdram_ba <= bank_addr;
                    {sdram_cs_n, sdram_ras_n, sdram_cas_n, sdram_we_n} <= 4'b0011; // ACTIVE
                    state <= ACTIVE;
                end else if (rd_req) begin
                    sdram_addr <= row_addr;
                    sdram_ba <= bank_addr;
                    {sdram_cs_n, sdram_ras_n, sdram_cas_n, sdram_we_n} <= 4'b0011; // ACTIVE
                    state <= ACTIVE;
                end
            end
            
            ACTIVE: begin
                if (wr_req) begin
                    sdram_addr <= {1'b1, col_addr[8:0]}; // Auto precharge
                    {sdram_cs_n, sdram_ras_n, sdram_cas_n, sdram_we_n} <= 4'b0100; // WRITE
                    data_out <= wr_data;
                    state <= WRITE;
                end else begin
                    sdram_addr <= {3'b000, col_addr};
                    {sdram_cs_n, sdram_ras_n, sdram_cas_n, sdram_we_n} <= 4'b0101; // READ
                    cas_counter <= 0;
                    state <= READ;
                end
            end
            
            READ: begin
                if(cas_counter == tCAS) begin
                    rd_data <= sdram_dq;
                    rd_valid <= 1'b1;  // Single-cycle pulse
                    {sdram_cs_n, sdram_ras_n, sdram_cas_n, sdram_we_n} <= 4'b0111; // PRECHARGE
                    state <= PRECHARGE;
                end else begin
                    cas_counter <= cas_counter + 1;
                end
            end
            
            WRITE: begin
                wr_ready <= 1'b1;
                {sdram_cs_n, sdram_ras_n, sdram_cas_n, sdram_we_n} <= 4'b0111; // PRECHARGE
                state <= PRECHARGE;
            end
            
            PRECHARGE: begin
                wr_ready <= 0;
                state <= IDLE;
            end
        endcase
    end
end

assign sdram_dq = (state == WRITE) ? data_out : 16'bz;

endmodule
