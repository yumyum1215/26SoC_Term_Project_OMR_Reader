module omr_video (
    input wire clk, resetn,
    input wire [31:0] command, panel_digits,
    output wire [31:0] status,
    input wire camera_PCLK, camera_HSYNC, camera_VSYNC,
    input wire [7:0] camera_data,
    inout wire camera_SCL, camera_SDA,
    output reg camera_MCLK = 0,
    output wire camera_RESETn, camera_PWDN,
    output wire TFTLCD_TCLK, TFTLCD_DE_out, TFTLCD_Tpower,
    output reg TFTLCD_Hsync, TFTLCD_Vsync,
    output reg [15:0] TFTLCD_D
);
    localparam VIDEO_PIXELS = 480 * 272;
    reg [7:0] i2c_div = 0;
    reg i2c_clk = 0;
    always @(posedge clk) begin
        camera_MCLK <= ~camera_MCLK;
        if (i2c_div == 49) begin
            i2c_div <= 0;
            i2c_clk <= ~i2c_clk;
        end else
            i2c_div <= i2c_div + 1'b1;
    end

    wire scl_in, sda_in, scl_release, sda_release;
    wire camera_initialized, camera_init_nack;
    IOBUF camera_scl_pad (.I(1'b0), .T(scl_release), .IO(camera_SCL), .O(scl_in));
    IOBUF camera_sda_pad (.I(1'b0), .T(sda_release), .IO(camera_SDA), .O(sda_in));

    camera_i2c init_camera (
        .clk(i2c_clk), .SW_1(1'b1), .camera_RESETn(camera_RESETn),
        .camera_PWDN(camera_PWDN), .scl_in(scl_in), .sda_in(sda_in),
        .scl_release(scl_release), .sda_release(sda_release),
        .init_done(camera_initialized), .init_nack(camera_init_nack)
    );

    (* ASYNC_REG = "TRUE" *) reg [1:0] camera_reset = 0;
    (* ASYNC_REG = "TRUE" *) reg [1:0] freeze_sync = 0;
    (* ASYNC_REG = "TRUE" *) reg [1:0] frozen_sync = 0;
    (* ASYNC_REG = "TRUE" *) reg [1:0] valid_sync = 0;
    (* ASYNC_REG = "TRUE" *) reg [1:0] align_required = 0;
    (* ASYNC_REG = "TRUE" *) reg [1:0] aligned_sync = 0;
    (* ASYNC_REG = "TRUE" *) reg [1:0] init_nack_sync = 0;
    reg frozen = 0, frame_valid = 0, frame_aligned = 0;
    reg [9:0] outside_light = 0;
    reg [6:0] left_paper = 0, right_paper = 0;
    reg [8:0] broad_rows = 0;
    reg have_frame_start = 0, frame_complete = 0;
    reg [16:0] write_addr = 0;
    reg [9:0] byte_index = 0;
    reg [8:0] row = 0;
    reg [7:0] high_byte;
    reg href_previous = 0;
    wire [8:0] column = byte_index[9:1];
    wire light_pixel = high_byte[7:3] >= 5'd17 &&
                       {high_byte[2:0], camera_data[7:5]} >= 6'd38 &&
                       camera_data[4:0] >= 5'd19;
    wire aligned = outside_light < 10'd160 && broad_rows >= 9'd120;
    (* ram_style = "block" *) reg [15:0] frame [0:VIDEO_PIXELS-1];

    always @(posedge camera_PCLK) begin
        camera_reset <= {camera_reset[0], resetn && camera_initialized};
        freeze_sync <= {freeze_sync[0], command[31]};
        align_required <= {align_required[0], command[29]};
        if (!camera_reset[1]) begin
            frozen <= 0;
            frame_valid <= 0;
            frame_aligned <= 0;
            have_frame_start <= 0;
        end else if (camera_VSYNC) begin
            if (frame_complete) begin
                frame_valid <= 1;
                frame_aligned <= aligned;
                frozen <= freeze_sync[1] && (frozen || !align_required[1] || aligned);
            end else if (!freeze_sync[1])
                frozen <= 0;

            have_frame_start <= 1;
            write_addr <= 0;
            frame_complete <= 0;
            outside_light <= 0;
            left_paper <= 0;
            right_paper <= 0;
            broad_rows <= 0;
            row <= 0;
            byte_index <= 0;
            href_previous <= 0;
        end else begin
            href_previous <= camera_HSYNC;
            if (!camera_HSYNC) begin
                byte_index <= 0;
                if (href_previous && row < 272) begin
                    if (left_paper >= 20 && right_paper >= 20)
                        broad_rows <= broad_rows + 1'b1;
                    left_paper <= 0;
                    right_paper <= 0;
                    row <= row + 1'b1;
                end
            end else if (have_frame_start && row < 272 && byte_index < 960) begin
                byte_index <= byte_index + 1'b1;
                if (!byte_index[0])
                    high_byte <= camera_data;
                else if (write_addr < VIDEO_PIXELS) begin
                    write_addr <= write_addr + 1'b1;
                    if (light_pixel) begin
                        if (column < 24 || column > 455 || row < 16 || row > 255) begin
                            if (outside_light != 10'd1023)
                                outside_light <= outside_light + 1'b1;
                        end else begin
                            if (column >= 64 && column < 112)
                                left_paper <= left_paper + 1'b1;
                            if (column >= 368 && column < 416)
                                right_paper <= right_paper + 1'b1;
                        end
                    end
                    if (write_addr == VIDEO_PIXELS - 1)
                        frame_complete <= 1;
                end
            end
        end
    end

    always @(posedge camera_PCLK) begin
        if (camera_reset[1] && !camera_VSYNC && camera_HSYNC &&
            have_frame_start && row < 272 && byte_index < 960 &&
            byte_index[0] && !frozen && write_addr < VIDEO_PIXELS)
            frame[write_addr] <= {high_byte, camera_data};
    end

    reg [2:0] phase = 0;
    reg [9:0] x = 0;
    reg [8:0] y = 0;
    reg [16:0] display_addr = 0;
    wire active = x >= 42 && x < 522 && y >= 12 && y < 284;
    wire guide = ((x == 66 || x == 497) && y >= 28 && y <= 267) ||
                 ((y == 28 || y == 267) && x >= 66 && x <= 497);
    wire [16:0] read_addr = phase == 0 ? display_addr : command[16:0];
    wire result_view = command[26:24] != 0;
    wire [2:0] glyph = (x - 10'd74) / 10'd48;
    wire [9:0] glyph_x = (x - 10'd74) % 10'd48;
    wire [3:0] digit = panel_digits[31 - glyph * 4 -: 4];
    reg [6:0] segments;
    always @* begin
        case (digit)
            0: segments = 7'h3f;
            1: segments = 7'h06;
            2: segments = 7'h5b;
            3: segments = 7'h4f;
            4: segments = 7'h66;
            5: segments = 7'h6d;
            6: segments = 7'h7d;
            7: segments = 7'h07;
            8: segments = 7'h7f;
            9: segments = 7'h6f;
            default: segments = 0;
        endcase
    end
    wire bar = glyph_x >= 8 && glyph_x < 28;
    wire paint = x >= 74 && x < 458 && (
        (segments[0] && bar && y >= 110 && y < 114) ||
        (segments[1] && glyph_x >= 28 && glyph_x < 32 && y >= 114 && y < 138) ||
        (segments[2] && glyph_x >= 28 && glyph_x < 32 && y >= 142 && y < 166) ||
        (segments[3] && bar && y >= 166 && y < 170) ||
        (segments[4] && glyph_x >= 4 && glyph_x < 8 && y >= 142 && y < 166) ||
        (segments[5] && glyph_x >= 4 && glyph_x < 8 && y >= 114 && y < 138) ||
        (segments[6] && bar && y >= 138 && y < 142));
    wire [15:0] banner_color = command[26:24] == 1 ? 16'h07e0 :
                               command[26:24] == 2 ? 16'h07ff :
                               command[26:24] == 3 ? 16'hffe0 : 16'hf800;
    reg [15:0] read_data, cpu_pixel;
    reg read_ack = 0;

    always @(posedge clk)
        read_data <= frame[read_addr];

    always @(posedge clk) begin
        frozen_sync <= {frozen_sync[0], frozen};
        valid_sync <= {valid_sync[0], frame_valid};
        aligned_sync <= {aligned_sync[0], frame_aligned};
        init_nack_sync <= {init_nack_sync[0], camera_init_nack};
        if (!resetn) begin
            phase <= 0;
            x <= 0;
            y <= 0;
            display_addr <= 0;
            read_ack <= 0;
            TFTLCD_D <= 0;
            TFTLCD_Hsync <= 0;
            TFTLCD_Vsync <= 0;
        end else begin
            phase <= phase == 4 ? 0 : phase + 1'b1;
            if (phase == 1) begin
                TFTLCD_Hsync <= x >= 40 && x < 522;
                TFTLCD_Vsync <= y >= 10 && y < 284;
                TFTLCD_D <= !active ? 16'd0 :
                            result_view ? (y < 24 || paint ? banner_color : 16'h0024) :
                            guide ? (aligned_sync[1] ? 16'h07e0 : 16'hf800) :
                            valid_sync[1] ? {read_data[4:0], read_data[10:5], read_data[15:11]} : 16'h001f;
            end
            if (phase == 4) begin
                if (command[30] != read_ack) begin
                    cpu_pixel <= frozen_sync[1] ? read_data : 16'd0;
                    read_ack <= command[30];
                end
                x <= x == 522 ? 0 : x + 1'b1;
                if (x == 522)
                    y <= y == 284 ? 0 : y + 1'b1;
                if (x == 522 && y == 284)
                    display_addr <= 0;
                else if (active)
                    display_addr <= display_addr + 1'b1;
            end
        end
    end

    assign TFTLCD_TCLK = phase == 3 || phase == 4;
    assign TFTLCD_DE_out = 1'b1;
    assign TFTLCD_Tpower = 1'b1;
    assign status = {11'd0, init_nack_sync[1], aligned_sync[1], read_ack, valid_sync[1], frozen_sync[1], cpu_pixel};
endmodule



