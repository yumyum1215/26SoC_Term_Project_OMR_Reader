//Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2019.1 (win64) Build 2552052 Fri May 24 14:49:42 MDT 2019
//Date        : Mon Nov 23 13:17:59 2026
//Host        : IT23 running 64-bit major release  (build 9200)
//Command     : generate_target system_wrapper.bd
//Design      : system_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module system_wrapper
   (DDR_addr,
    DDR_ba,
    DDR_cas_n,
    DDR_ck_n,
    DDR_ck_p,
    DDR_cke,
    DDR_cs_n,
    DDR_dm,
    DDR_dq,
    DDR_dqs_n,
    DDR_dqs_p,
    DDR_odt,
    DDR_ras_n,
    DDR_reset_n,
    DDR_we_n,
    FIXED_IO_ddr_vrn,
    FIXED_IO_ddr_vrp,
    FIXED_IO_mio,
    FIXED_IO_ps_clk,
    FIXED_IO_ps_porb,
    FIXED_IO_ps_srstb,
    TFTLCD_D,
    TFTLCD_DE_out,
    TFTLCD_Hsync,
    TFTLCD_TCLK,
    TFTLCD_Tpower,
    TFTLCD_Vsync,
    buttons_4bits_tri_i,
    camera_HSYNC,
    camera_MCLK,
    camera_PCLK,
    camera_PWDN,
    camera_RESETn,
    camera_SCL,
    camera_SDA,
    camera_VSYNC,
    camera_data,
    lcd_data,
    lcd_en,
    lcd_rs,
    lcd_rw,
    segcom,
    segdata,
    servo_pwm_o);
  inout [14:0]DDR_addr;
  inout [2:0]DDR_ba;
  inout DDR_cas_n;
  inout DDR_ck_n;
  inout DDR_ck_p;
  inout DDR_cke;
  inout DDR_cs_n;
  inout [3:0]DDR_dm;
  inout [31:0]DDR_dq;
  inout [3:0]DDR_dqs_n;
  inout [3:0]DDR_dqs_p;
  inout DDR_odt;
  inout DDR_ras_n;
  inout DDR_reset_n;
  inout DDR_we_n;
  inout FIXED_IO_ddr_vrn;
  inout FIXED_IO_ddr_vrp;
  inout [53:0]FIXED_IO_mio;
  inout FIXED_IO_ps_clk;
  inout FIXED_IO_ps_porb;
  inout FIXED_IO_ps_srstb;
  output [15:0]TFTLCD_D;
  output TFTLCD_DE_out;
  output TFTLCD_Hsync;
  output TFTLCD_TCLK;
  output TFTLCD_Tpower;
  output TFTLCD_Vsync;
  input [3:0]buttons_4bits_tri_i;
  input camera_HSYNC;
  output camera_MCLK;
  input camera_PCLK;
  output camera_PWDN;
  output camera_RESETn;
  inout camera_SCL;
  inout camera_SDA;
  input camera_VSYNC;
  input [7:0]camera_data;
  output [7:0]lcd_data;
  output lcd_en;
  output lcd_rs;
  output lcd_rw;
  output [7:0]segcom;
  output [7:0]segdata;
  output servo_pwm_o;

  wire [14:0]DDR_addr;
  wire [2:0]DDR_ba;
  wire DDR_cas_n;
  wire DDR_ck_n;
  wire DDR_ck_p;
  wire DDR_cke;
  wire DDR_cs_n;
  wire [3:0]DDR_dm;
  wire [31:0]DDR_dq;
  wire [3:0]DDR_dqs_n;
  wire [3:0]DDR_dqs_p;
  wire DDR_odt;
  wire DDR_ras_n;
  wire DDR_reset_n;
  wire DDR_we_n;
  wire FIXED_IO_ddr_vrn;
  wire FIXED_IO_ddr_vrp;
  wire [53:0]FIXED_IO_mio;
  wire FIXED_IO_ps_clk;
  wire FIXED_IO_ps_porb;
  wire FIXED_IO_ps_srstb;
  wire [15:0]TFTLCD_D;
  wire TFTLCD_DE_out;
  wire TFTLCD_Hsync;
  wire TFTLCD_TCLK;
  wire TFTLCD_Tpower;
  wire TFTLCD_Vsync;
  wire [3:0]buttons_4bits_tri_i;
  wire camera_HSYNC;
  wire camera_MCLK;
  wire camera_PCLK;
  wire camera_PWDN;
  wire camera_RESETn;
  wire camera_SCL;
  wire camera_SDA;
  wire camera_VSYNC;
  wire [7:0]camera_data;
  wire [7:0]lcd_data;
  wire lcd_en;
  wire lcd_rs;
  wire lcd_rw;
  wire [7:0]segcom;
  wire [7:0]segdata;
  wire servo_pwm_o;

  system system_i
       (.DDR_addr(DDR_addr),
        .DDR_ba(DDR_ba),
        .DDR_cas_n(DDR_cas_n),
        .DDR_ck_n(DDR_ck_n),
        .DDR_ck_p(DDR_ck_p),
        .DDR_cke(DDR_cke),
        .DDR_cs_n(DDR_cs_n),
        .DDR_dm(DDR_dm),
        .DDR_dq(DDR_dq),
        .DDR_dqs_n(DDR_dqs_n),
        .DDR_dqs_p(DDR_dqs_p),
        .DDR_odt(DDR_odt),
        .DDR_ras_n(DDR_ras_n),
        .DDR_reset_n(DDR_reset_n),
        .DDR_we_n(DDR_we_n),
        .FIXED_IO_ddr_vrn(FIXED_IO_ddr_vrn),
        .FIXED_IO_ddr_vrp(FIXED_IO_ddr_vrp),
        .FIXED_IO_mio(FIXED_IO_mio),
        .FIXED_IO_ps_clk(FIXED_IO_ps_clk),
        .FIXED_IO_ps_porb(FIXED_IO_ps_porb),
        .FIXED_IO_ps_srstb(FIXED_IO_ps_srstb),
        .TFTLCD_D(TFTLCD_D),
        .TFTLCD_DE_out(TFTLCD_DE_out),
        .TFTLCD_Hsync(TFTLCD_Hsync),
        .TFTLCD_TCLK(TFTLCD_TCLK),
        .TFTLCD_Tpower(TFTLCD_Tpower),
        .TFTLCD_Vsync(TFTLCD_Vsync),
        .buttons_4bits_tri_i(buttons_4bits_tri_i),
        .camera_HSYNC(camera_HSYNC),
        .camera_MCLK(camera_MCLK),
        .camera_PCLK(camera_PCLK),
        .camera_PWDN(camera_PWDN),
        .camera_RESETn(camera_RESETn),
        .camera_SCL(camera_SCL),
        .camera_SDA(camera_SDA),
        .camera_VSYNC(camera_VSYNC),
        .camera_data(camera_data),
        .lcd_data(lcd_data),
        .lcd_en(lcd_en),
        .lcd_rs(lcd_rs),
        .lcd_rw(lcd_rw),
        .segcom(segcom),
        .segdata(segdata),
        .servo_pwm_o(servo_pwm_o));
endmodule
