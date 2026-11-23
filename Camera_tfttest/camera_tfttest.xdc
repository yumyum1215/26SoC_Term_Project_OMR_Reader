set_property IOSTANDARD "LVCMOS33" [get_ports "clk"]
set_property PACKAGE_PIN "M19" [get_ports "clk"]

set_property IOSTANDARD "LVCMOS33" [get_ports "resetn"]
set_property PACKAGE_PIN "Y18" [get_ports "resetn"]

set_property IOSTANDARD "LVCMOS33" [get_ports "TFTLCD_TCLK"]
set_property PACKAGE_PIN "L17" [get_ports "TFTLCD_TCLK"]

set_property IOSTANDARD "LVCMOS33" [get_ports "TFTLCD_Hsync"]
set_property PACKAGE_PIN "N17" [get_ports "TFTLCD_Hsync"]

set_property IOSTANDARD "LVCMOS33" [get_ports "TFTLCD_Vsync"]
set_property PACKAGE_PIN "M17" [get_ports "TFTLCD_Vsync"]

set_property IOSTANDARD "LVCMOS33" [get_ports "TFTLCD_DE_out"]
set_property PACKAGE_PIN "U22" [get_ports "TFTLCD_DE_out"]

set_property IOSTANDARD "LVCMOS33" [get_ports "TFTLCD_D[*]"]
set_property PACKAGE_PIN "T22" [get_ports "TFTLCD_D[15]"]
set_property PACKAGE_PIN "U21" [get_ports "TFTLCD_D[14]"]
set_property PACKAGE_PIN "T21" [get_ports "TFTLCD_D[13]"]
set_property PACKAGE_PIN "K20" [get_ports "TFTLCD_D[12]"]
set_property PACKAGE_PIN "K19" [get_ports "TFTLCD_D[11]"]
set_property PACKAGE_PIN "L22" [get_ports "TFTLCD_D[10]"]
set_property PACKAGE_PIN "L21" [get_ports "TFTLCD_D[9]"]
set_property PACKAGE_PIN "K21" [get_ports "TFTLCD_D[8]"]
set_property PACKAGE_PIN "J20" [get_ports "TFTLCD_D[7]"]
set_property PACKAGE_PIN "J22" [get_ports "TFTLCD_D[6]"]
set_property PACKAGE_PIN "J21" [get_ports "TFTLCD_D[5]"]
set_property PACKAGE_PIN "K18" [get_ports "TFTLCD_D[4]"]
set_property PACKAGE_PIN "J18" [get_ports "TFTLCD_D[3]"]
set_property PACKAGE_PIN "M16" [get_ports "TFTLCD_D[2]"]
set_property PACKAGE_PIN "M15" [get_ports "TFTLCD_D[1]"]
set_property PACKAGE_PIN "N18" [get_ports "TFTLCD_D[0]"]

set_property IOSTANDARD "LVCMOS33" [get_ports "TFTLCD_Tpower"]
set_property PACKAGE_PIN "W22" [get_ports "TFTLCD_Tpower"]

set_property IOSTANDARD "LVCMOS33" [get_ports "camera_PWDN"]
set_property PACKAGE_PIN "V5" [get_ports "camera_PWDN"]

set_property IOSTANDARD "LVCMOS33" [get_ports "camera_RESETn"]
set_property PACKAGE_PIN "V4" [get_ports "camera_RESETn"]

set_property IOSTANDARD "LVCMOS33" [get_ports "camera_SCL"]
set_property PACKAGE_PIN "F16" [get_ports "camera_SCL"]

set_property IOSTANDARD "LVCMOS33" [get_ports "camera_SDA"]
set_property PACKAGE_PIN "E16" [get_ports "camera_SDA"]

set_property IOSTANDARD "LVCMOS33" [get_ports "camera_HSYNC"]
set_property PACKAGE_PIN "W17" [get_ports "camera_HSYNC"]

set_property IOSTANDARD "LVCMOS33" [get_ports "camera_VSYNC"]
set_property PACKAGE_PIN "W18" [get_ports "camera_VSYNC"]

set_property IOSTANDARD "LVCMOS33" [get_ports "camera_PCLK"]
set_property PACKAGE_PIN "W16" [get_ports "camera_PCLK"]

set_property IOSTANDARD "LVCMOS33" [get_ports "camera_MCLK"]
set_property PACKAGE_PIN "Y16" [get_ports "camera_MCLK"]

set_property IOSTANDARD "LVCMOS33" [get_ports "camera_data[*]"]
set_property PACKAGE_PIN "U15" [get_ports "camera_data[0]"]
set_property PACKAGE_PIN "U16" [get_ports "camera_data[1]"]
set_property PACKAGE_PIN "U17" [get_ports "camera_data[2]"]
set_property PACKAGE_PIN "V17" [get_ports "camera_data[3]"]
set_property PACKAGE_PIN "AA17" [get_ports "camera_data[4]"]
set_property PACKAGE_PIN "AB17" [get_ports "camera_data[5]"]
set_property PACKAGE_PIN "AA16" [get_ports "camera_data[6]"]
set_property PACKAGE_PIN "AB16" [get_ports "camera_data[7]"]


# M19 board oscillator and independent camera pixel clock.
create_clock -name board_clk -period 40.000 [get_ports clk]
create_clock -name camera_pclk -period 20.000 [get_ports camera_PCLK]
create_generated_clock -name sensor_xclk -source [get_pins clock_manager/CLKOUT0] -divide_by 2 [get_ports camera_MCLK]
create_generated_clock -name sccb_clk -source [get_pins clock_manager/CLKOUT0] -divide_by 100 [get_pins video/i2c_clk_reg/Q]
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks board_clk] -group [get_clocks camera_pclk]
