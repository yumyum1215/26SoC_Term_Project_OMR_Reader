
`timescale 1 ns / 1 ps

module textlcd_v1_0_S00_AXI #
(
    parameter integer C_S_AXI_DATA_WIDTH = 32,
    parameter integer C_S_AXI_ADDR_WIDTH = 5
)
(
    // Text LCD user ports
    input  wire       resetn,
    input  wire       lcdclk,
    output wire       lcd_rs,
    output wire       lcd_rw,
    output wire       lcd_en,
    output wire [7:0] lcd_data,

    // AXI4-Lite ports
    input  wire S_AXI_ACLK,
    input  wire S_AXI_ARESETN,
    input  wire [C_S_AXI_ADDR_WIDTH-1:0] S_AXI_AWADDR,
    input  wire [2:0] S_AXI_AWPROT,
    input  wire S_AXI_AWVALID,
    output wire S_AXI_AWREADY,
    input  wire [C_S_AXI_DATA_WIDTH-1:0] S_AXI_WDATA,
    input  wire [(C_S_AXI_DATA_WIDTH/8)-1:0] S_AXI_WSTRB,
    input  wire S_AXI_WVALID,
    output wire S_AXI_WREADY,
    output wire [1:0] S_AXI_BRESP,
    output wire S_AXI_BVALID,
    input  wire S_AXI_BREADY,
    input  wire [C_S_AXI_ADDR_WIDTH-1:0] S_AXI_ARADDR,
    input  wire [2:0] S_AXI_ARPROT,
    input  wire S_AXI_ARVALID,
    output wire S_AXI_ARREADY,
    output wire [C_S_AXI_DATA_WIDTH-1:0] S_AXI_RDATA,
    output wire [1:0] S_AXI_RRESP,
    output wire S_AXI_RVALID,
    input  wire S_AXI_RREADY
);

    // AXI4-Lite internal signals
    reg [C_S_AXI_ADDR_WIDTH-1:0] axi_awaddr;
    reg axi_awready;
    reg axi_wready;
    reg [1:0] axi_bresp;
    reg axi_bvalid;
    reg [C_S_AXI_ADDR_WIDTH-1:0] axi_araddr;
    reg axi_arready;
    reg [C_S_AXI_DATA_WIDTH-1:0] axi_rdata;
    reg [1:0] axi_rresp;
    reg axi_rvalid;

    localparam integer ADDR_LSB = (C_S_AXI_DATA_WIDTH/32) + 1;
    localparam integer OPT_MEM_ADDR_BITS = 2;

    // Eight 32-bit LCD character registers
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg0;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg1;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg2;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg3;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg4;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg5;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg6;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg7;

    wire slv_reg_rden;
    wire slv_reg_wren;
    reg [C_S_AXI_DATA_WIDTH-1:0] reg_data_out;
    integer byte_index;
    reg aw_en;

    assign S_AXI_AWREADY = axi_awready;
    assign S_AXI_WREADY  = axi_wready;
    assign S_AXI_BRESP   = axi_bresp;
    assign S_AXI_BVALID  = axi_bvalid;
    assign S_AXI_ARREADY = axi_arready;
    assign S_AXI_RDATA   = axi_rdata;
    assign S_AXI_RRESP   = axi_rresp;
    assign S_AXI_RVALID  = axi_rvalid;

    // AXI write address ready
    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            axi_awready <= 1'b0;
            aw_en <= 1'b1;
        end else begin
            if (!axi_awready && S_AXI_AWVALID &&
                S_AXI_WVALID && aw_en) begin
                axi_awready <= 1'b1;
                aw_en <= 1'b0;
            end else if (S_AXI_BREADY && axi_bvalid) begin
                aw_en <= 1'b1;
                axi_awready <= 1'b0;
            end else begin
                axi_awready <= 1'b0;
            end
        end
    end

    // AXI write address latch
    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN)
            axi_awaddr <= 0;
        else if (!axi_awready && S_AXI_AWVALID &&
                 S_AXI_WVALID && aw_en)
            axi_awaddr <= S_AXI_AWADDR;
    end

    // AXI write data ready
    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN)
            axi_wready <= 1'b0;
        else if (!axi_wready && S_AXI_WVALID &&
                 S_AXI_AWVALID && aw_en)
            axi_wready <= 1'b1;
        else
            axi_wready <= 1'b0;
    end

    // AXI register write enable
    assign slv_reg_wren =
        axi_wready && S_AXI_WVALID &&
        axi_awready && S_AXI_AWVALID;

    // AXI slave registers
    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            slv_reg0 <= 0;
            slv_reg1 <= 0;
            slv_reg2 <= 0;
            slv_reg3 <= 0;
            slv_reg4 <= 0;
            slv_reg5 <= 0;
            slv_reg6 <= 0;
            slv_reg7 <= 0;
        end else if (slv_reg_wren) begin
            case (axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB])
                3'h0: for (byte_index=0; byte_index<4; byte_index=byte_index+1)
                    if (S_AXI_WSTRB[byte_index])
                        slv_reg0[byte_index*8 +: 8] <= S_AXI_WDATA[byte_index*8 +: 8];
                3'h1: for (byte_index=0; byte_index<4; byte_index=byte_index+1)
                    if (S_AXI_WSTRB[byte_index])
                        slv_reg1[byte_index*8 +: 8] <= S_AXI_WDATA[byte_index*8 +: 8];
                3'h2: for (byte_index=0; byte_index<4; byte_index=byte_index+1)
                    if (S_AXI_WSTRB[byte_index])
                        slv_reg2[byte_index*8 +: 8] <= S_AXI_WDATA[byte_index*8 +: 8];
                3'h3: for (byte_index=0; byte_index<4; byte_index=byte_index+1)
                    if (S_AXI_WSTRB[byte_index])
                        slv_reg3[byte_index*8 +: 8] <= S_AXI_WDATA[byte_index*8 +: 8];
                3'h4: for (byte_index=0; byte_index<4; byte_index=byte_index+1)
                    if (S_AXI_WSTRB[byte_index])
                        slv_reg4[byte_index*8 +: 8] <= S_AXI_WDATA[byte_index*8 +: 8];
                3'h5: for (byte_index=0; byte_index<4; byte_index=byte_index+1)
                    if (S_AXI_WSTRB[byte_index])
                        slv_reg5[byte_index*8 +: 8] <= S_AXI_WDATA[byte_index*8 +: 8];
                3'h6: for (byte_index=0; byte_index<4; byte_index=byte_index+1)
                    if (S_AXI_WSTRB[byte_index])
                        slv_reg6[byte_index*8 +: 8] <= S_AXI_WDATA[byte_index*8 +: 8];
                3'h7: for (byte_index=0; byte_index<4; byte_index=byte_index+1)
                    if (S_AXI_WSTRB[byte_index])
                        slv_reg7[byte_index*8 +: 8] <= S_AXI_WDATA[byte_index*8 +: 8];
                default: begin end
            endcase
        end
    end

    // AXI write response
    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            axi_bvalid <= 0;
            axi_bresp <= 0;
        end else begin
            if (axi_awready && S_AXI_AWVALID &&
                !axi_bvalid && axi_wready && S_AXI_WVALID) begin
                axi_bvalid <= 1'b1;
                axi_bresp <= 2'b00;
            end else if (S_AXI_BREADY && axi_bvalid)
                axi_bvalid <= 1'b0;
        end
    end

    // AXI read address
    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            axi_arready <= 1'b0;
            axi_araddr <= 0;
        end else if (!axi_arready && S_AXI_ARVALID) begin
            axi_arready <= 1'b1;
            axi_araddr <= S_AXI_ARADDR;
        end else begin
            axi_arready <= 1'b0;
        end
    end

    // AXI read response
    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            axi_rvalid <= 0;
            axi_rresp <= 0;
        end else if (axi_arready && S_AXI_ARVALID && !axi_rvalid) begin
            axi_rvalid <= 1'b1;
            axi_rresp <= 2'b00;
        end else if (axi_rvalid && S_AXI_RREADY) begin
            axi_rvalid <= 1'b0;
        end
    end

    assign slv_reg_rden =
        axi_arready & S_AXI_ARVALID & ~axi_rvalid;

    // Register read multiplexer
    always @(*) begin
        case (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB])
            3'h0: reg_data_out = slv_reg0;
            3'h1: reg_data_out = slv_reg1;
            3'h2: reg_data_out = slv_reg2;
            3'h3: reg_data_out = slv_reg3;
            3'h4: reg_data_out = slv_reg4;
            3'h5: reg_data_out = slv_reg5;
            3'h6: reg_data_out = slv_reg6;
            3'h7: reg_data_out = slv_reg7;
            default: reg_data_out = 0;
        endcase
    end

    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN)
            axi_rdata <= 0;
        else if (slv_reg_rden)
            axi_rdata <= reg_data_out;
    end

    // Text LCD controller
    textlcd textlcd_inst (
        .resetn   (resetn),
        .lcdclk   (lcdclk),
        .reg_a    (slv_reg0),
        .reg_b    (slv_reg1),
        .reg_c    (slv_reg2),
        .reg_d    (slv_reg3),
        .reg_e    (slv_reg4),
        .reg_f    (slv_reg5),
        .reg_g    (slv_reg6),
        .reg_h    (slv_reg7),
        .lcd_rs   (lcd_rs),
        .lcd_rw   (lcd_rw),
        .lcd_en   (lcd_en),
        .lcd_data (lcd_data)
    );

endmodule
