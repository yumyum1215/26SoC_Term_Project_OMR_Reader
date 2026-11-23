module camera_tfttest #(
    parameter SHOW_COLOR_BARS = 0
) (
    input wire clk, resetn,
    input wire camera_PCLK, camera_HSYNC, camera_VSYNC,
    input wire [7:0] camera_data,
    inout wire camera_SCL, camera_SDA,
    output wire camera_MCLK, camera_RESETn, camera_PWDN,
    output wire TFTLCD_TCLK, TFTLCD_DE_out, TFTLCD_Tpower,
    output wire TFTLCD_Hsync, TFTLCD_Vsync,
    output wire [15:0] TFTLCD_D
);
    wire fb, fb_global, clk50_raw, clk50, locked;
    // M19 receives 25 MHz. The video logic uses 50 MHz for a 12.5 MHz TFT clock.
    MMCME2_BASE #(
        .CLKIN1_PERIOD(40.0), .DIVCLK_DIVIDE(1),
        .CLKFBOUT_MULT_F(40.0), .CLKOUT0_DIVIDE_F(20.0)
    ) clock_manager (
        .CLKIN1(clk), .CLKFBIN(fb_global), .CLKFBOUT(fb),
        .CLKOUT0(clk50_raw), .LOCKED(locked), .PWRDWN(1'b0), .RST(1'b0)
    );
    BUFG feedback_buffer (.I(fb), .O(fb_global));
    BUFG video_clock_buffer (.I(clk50_raw), .O(clk50));

    camera_tfttest_core #(.SHOW_COLOR_BARS(SHOW_COLOR_BARS)) video (
        .clk(clk50), .resetn(resetn && locked),
        .camera_PCLK(camera_PCLK), .camera_HSYNC(camera_HSYNC),
        .camera_VSYNC(camera_VSYNC), .camera_data(camera_data),
        .camera_SCL(camera_SCL), .camera_SDA(camera_SDA),
        .camera_MCLK(camera_MCLK), .camera_RESETn(camera_RESETn), .camera_PWDN(camera_PWDN),
        .TFTLCD_TCLK(TFTLCD_TCLK), .TFTLCD_DE_out(TFTLCD_DE_out),
        .TFTLCD_Tpower(TFTLCD_Tpower), .TFTLCD_Hsync(TFTLCD_Hsync),
        .TFTLCD_Vsync(TFTLCD_Vsync), .TFTLCD_D(TFTLCD_D)
    );
endmodule

module camera_tfttest_core #(
    parameter SHOW_COLOR_BARS = 0
) (
    input wire clk, resetn,
    input wire camera_PCLK, camera_HSYNC, camera_VSYNC,
    input wire [7:0] camera_data,
    inout wire camera_SCL, camera_SDA,
    output reg camera_MCLK = 0,
    output wire camera_RESETn, camera_PWDN,
    output reg TFTLCD_TCLK = 0,
    output wire TFTLCD_DE_out, TFTLCD_Tpower,
    output reg TFTLCD_Hsync = 0, TFTLCD_Vsync = 0,
    output reg [15:0] TFTLCD_D = 0
);
    localparam WIDTH = 480;
    localparam HEIGHT = 272;
    localparam PIXELS = WIDTH * HEIGHT;
    localparam LEFT = 80;
    localparam TOP = 104;

    localparam H_SYNC = 41;
    localparam H_START = H_SYNC + 2;
    localparam H_END = H_START + WIDTH;
    localparam H_TOTAL = H_END + 2;
    localparam V_SYNC = 10;
    localparam V_START = V_SYNC + 2;
    localparam V_END = V_START + HEIGHT;
    localparam V_TOTAL = V_END + 2;

    reg [5:0] i2c_div = 0;
    reg i2c_clk = 0;
    always @(posedge clk) begin
        camera_MCLK <= ~camera_MCLK;
        if (i2c_div == 49) begin
            i2c_div <= 0;
            i2c_clk <= ~i2c_clk;
        end else
            i2c_div <= i2c_div + 1'b1;
    end

    camera_i2c init_camera (
        .clk(i2c_clk), .SW_1(1'b1),
        .camera_RESETn(camera_RESETn), .camera_PWDN(camera_PWDN),
        .camera_SCL(camera_SCL), .camera_SDA(camera_SDA)
    );

    (* ASYNC_REG = "TRUE" *) reg [1:0] capture_resetn = 0;
    (* ASYNC_REG = "TRUE" *) reg [1:0] display_resetn = 0;
    always @(posedge camera_PCLK)
        capture_resetn <= {capture_resetn[0], resetn};

    always @(posedge clk or negedge resetn)
        if (!resetn) display_resetn <= 0;
        else display_resetn <= {display_resetn[0], 1'b1};

    // OV5640 DVP sends the high byte first while HREF is asserted.
    reg in_frame = 0, low_byte = 0, frame_valid = 0;
    reg [7:0] high_byte = 0;
    reg [16:0] write_addr = 0;
    reg [9:0] sensor_x = 0;
    reg [8:0] sensor_y = 0;
    reg previous_href = 0;
    wire capture = capture_resetn[1] && in_frame &&
                   !camera_VSYNC && camera_HSYNC && write_addr < PIXELS;
    // The lab ROM configures 640x480. Keep the center 480x272.
    wire visible = sensor_x >= LEFT && sensor_x < LEFT + WIDTH &&
                   sensor_y >= TOP && sensor_y < TOP + HEIGHT;
    (* ram_style = "block" *) reg [15:0] frame [0:PIXELS-1];

    always @(posedge camera_PCLK) begin
        previous_href <= camera_HSYNC;
        if (!capture_resetn[1]) begin
            sensor_x <= 0;
            sensor_y <= 0;
            in_frame <= 0;
            low_byte <= 0;
            write_addr <= 0;
            frame_valid <= 0;
        end else if (camera_VSYNC) begin
            sensor_x <= 0;
            sensor_y <= 0;
            previous_href <= 0;
            in_frame <= 1;
            low_byte <= 0;
            write_addr <= 0;
            if (write_addr == PIXELS)
                frame_valid <= 1;
        end else if (!camera_HSYNC) begin
            low_byte <= 0;
            sensor_x <= 0;
            if (previous_href)
                sensor_y <= sensor_y + 1'b1;
        end else if (capture) begin
            low_byte <= ~low_byte;
            if (!low_byte)
                high_byte <= camera_data;
            else begin
                sensor_x <= sensor_x + 1'b1;
                if (visible)
                    write_addr <= write_addr + 1'b1;
            end
        end
    end

    always @(posedge camera_PCLK)
        if (capture && low_byte && visible)
            frame[write_addr] <= {high_byte, camera_data};

    // TFT timing matches the 480x272 lab window. Set data before TCLK rises.
    (* ASYNC_REG = "TRUE" *) reg [1:0] valid_sync = 0;
    reg [1:0] phase = 0;
    reg [9:0] x = 0;
    reg [8:0] y = 0;
    reg [16:0] read_addr = 0;
    reg [15:0] pixel;
    wire active = x >= H_START && x < H_END && y >= V_START && y < V_END;
    wire last_pixel = x == H_TOTAL - 1 && y == V_TOTAL - 1;

    always @(posedge clk)
        if (phase == 0)
            pixel <= frame[read_addr];

    always @(posedge clk) begin
        if (!display_resetn[1]) begin
            valid_sync <= 0;
            phase <= 0;
            x <= 0;
            y <= 0;
            read_addr <= 0;
            TFTLCD_TCLK <= 0;
            TFTLCD_Hsync <= 0;
            TFTLCD_Vsync <= 0;
            TFTLCD_D <= 0;
        end else begin
            valid_sync <= {valid_sync[0], frame_valid};
            phase <= phase + 1'b1;
            TFTLCD_TCLK <= phase[1];
            if (phase == 1) begin
                TFTLCD_Hsync <= x >= H_SYNC;
                TFTLCD_Vsync <= y >= V_SYNC;
                if (!active)
                    TFTLCD_D <= 16'h0000;
                else if (SHOW_COLOR_BARS)
                    TFTLCD_D <= x < H_START + 160 ? 16'hf800 : x < H_START + 320 ? 16'h07e0 : 16'h001f;
                else
                    // Match the lab's camera-to-TFT red/blue wiring order.
                    TFTLCD_D <= valid_sync[1] ? {pixel[4:0], pixel[10:5], pixel[15:11]} : 16'h001f;
            end
            if (phase == 3) begin
                x <= x == H_TOTAL - 1 ? 0 : x + 1'b1;
                if (x == H_TOTAL - 1)
                    y <= y == V_TOTAL - 1 ? 0 : y + 1'b1;
                if (last_pixel)
                    read_addr <= 0;
                else if (active && read_addr < PIXELS - 1)
                    read_addr <= read_addr + 1'b1;
            end
        end
    end

    assign TFTLCD_DE_out = 1'b1;
    assign TFTLCD_Tpower = 1'b1;
endmodule
