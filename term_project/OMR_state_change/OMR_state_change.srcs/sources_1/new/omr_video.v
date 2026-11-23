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
    // Graph registers share the existing AXI GPIO command, select view 5.
    wire graph_view = command[26:24] == 3'd5;
    reg [19:0] graph_student;
    reg [15:0] graph_scale;
    reg [15:0] graph_score [0:7];
    reg [7:0] graph_height [0:7];
    wire [2:0] graph_write_slot = command[23:21];
    always @(posedge clk) begin
        if (resetn && graph_view && command[27]) begin
            case (command[29:28])
                0: graph_student <= command[19:0];
                1: graph_scale <= command[15:0];
                2: graph_score[graph_write_slot] <= command[15:0];
                3: graph_height[graph_write_slot] <= command[7:0];
            endcase
        end
    end

    function digit_pixel;
        input [19:0] digits;
        input [5:0] px;
        input [3:0] py;
        reg [14:0] shape;
        reg [3:0] number;
        begin
            number = digits[19 - 4 * px[5:3] -: 4];
            case (number)
                0: shape = 15'b111_101_101_101_111;
                1: shape = 15'b010_110_010_010_111;
                2: shape = 15'b111_001_111_100_111;
                3: shape = 15'b111_001_111_001_111;
                4: shape = 15'b101_101_111_001_001;
                5: shape = 15'b111_100_111_001_111;
                6: shape = 15'b111_100_111_101_111;
                7: shape = 15'b111_001_010_010_010;
                8: shape = 15'b111_101_111_101_111;
                9: shape = 15'b111_101_111_001_111;
                15: shape = 15'b000_000_111_000_000;
                default: shape = 0;
            endcase
            digit_pixel = px < 40 && px[2:1] < 3 && py < 10 &&
                          shape[14 - (3 * py[3:1] + px[2:1])];
        end
    endfunction

    // Six centered 48x20 bitmaps in display order: Korean, Math, English, History, Social Studies, Science.
    function [47:0] subject_row;
        input [2:0] slot;
        input [4:0] row;
        begin
            case ({slot, row})
                8'd2: subject_row = 48'h000000001800;
                8'd3: subject_row = 48'h000ff81e1800;
                8'd4: subject_row = 48'h000018331800;
                8'd5: subject_row = 48'h000018311800;
                8'd6: subject_row = 48'h000018619800;
                8'd7: subject_row = 48'h00001861f800;
                8'd8: subject_row = 48'h003ffe619800;
                8'd9: subject_row = 48'h000180619800;
                8'd10: subject_row = 48'h000180311800;
                8'd11: subject_row = 48'h000ff8331800;
                8'd12: subject_row = 48'h0000181e1800;
                8'd13: subject_row = 48'h000018001800;
                8'd14: subject_row = 48'h000018001800;
                8'd15: subject_row = 48'h000018001800;
                8'd34: subject_row = 48'h0000000c3000;
                8'd35: subject_row = 48'h0001c00c3000;
                8'd36: subject_row = 48'h0001c07ff000;
                8'd37: subject_row = 48'h0001c0003000;
                8'd38: subject_row = 48'h0007701f3000;
                8'd39: subject_row = 48'h001c1c31be00;
                8'd40: subject_row = 48'h00000031b000;
                8'd41: subject_row = 48'h00000031b000;
                8'd42: subject_row = 48'h003ffe1f3000;
                8'd43: subject_row = 48'h0001c0000000;
                8'd44: subject_row = 48'h0001c01ff000;
                8'd45: subject_row = 48'h0001c0003000;
                8'd46: subject_row = 48'h0001c0003000;
                8'd47: subject_row = 48'h0001c0003000;
                8'd66: subject_row = 48'h00000c001800;
                8'd67: subject_row = 48'h000f8c1e1800;
                8'd68: subject_row = 48'h0019fc331800;
                8'd69: subject_row = 48'h0010cc311800;
                8'd70: subject_row = 48'h0030cc619800;
                8'd71: subject_row = 48'h0010fc61f800;
                8'd72: subject_row = 48'h00198c619800;
                8'd73: subject_row = 48'h000f0c619800;
                8'd74: subject_row = 48'h000000311800;
                8'd75: subject_row = 48'h0001f8331800;
                8'd76: subject_row = 48'h00060c1e1800;
                8'd77: subject_row = 48'h00060c001800;
                8'd78: subject_row = 48'h00060c001800;
                8'd79: subject_row = 48'h0001f8001800;
                8'd98: subject_row = 48'h000618000000;
                8'd99: subject_row = 48'h0006181ff000;
                8'd100: subject_row = 48'h003ff8003000;
                8'd101: subject_row = 48'h000018003000;
                8'd102: subject_row = 48'h000f98003000;
                8'd103: subject_row = 48'h0018df003000;
                8'd104: subject_row = 48'h0018d87ffc00;
                8'd105: subject_row = 48'h0018d8030000;
                8'd106: subject_row = 48'h000f98030000;
                8'd107: subject_row = 48'h0000181ff000;
                8'd108: subject_row = 48'h000c00003000;
                8'd109: subject_row = 48'h000c00003000;
                8'd110: subject_row = 48'h000c00003000;
                8'd111: subject_row = 48'h000ffc003000;
                8'd130: subject_row = 48'h000018061800;
                8'd131: subject_row = 48'h000618061800;
                8'd132: subject_row = 48'h0006187fd800;
                8'd133: subject_row = 48'h000618001800;
                8'd134: subject_row = 48'h0006181f1800;
                8'd135: subject_row = 48'h000618319800;
                8'd136: subject_row = 48'h00071f319800;
                8'd137: subject_row = 48'h000d18319800;
                8'd138: subject_row = 48'h0009981f9800;
                8'd139: subject_row = 48'h0010d80e1800;
                8'd140: subject_row = 48'h003058061800;
                8'd141: subject_row = 48'h0000187ff800;
                8'd142: subject_row = 48'h000018001800;
                8'd143: subject_row = 48'h000018001800;
                8'd162: subject_row = 48'h00000c0c3000;
                8'd163: subject_row = 48'h001fcc0c3000;
                8'd164: subject_row = 48'h0000cc7ff000;
                8'd165: subject_row = 48'h0000cc003000;
                8'd166: subject_row = 48'h0000cc1f3000;
                8'd167: subject_row = 48'h000ecc31be00;
                8'd168: subject_row = 48'h000ecf31b000;
                8'd169: subject_row = 48'h000ecc31b000;
                8'd170: subject_row = 48'h000e0c1f3000;
                8'd171: subject_row = 48'h000e0c000000;
                8'd172: subject_row = 48'h007ffc1ff000;
                8'd173: subject_row = 48'h00000c003000;
                8'd174: subject_row = 48'h00000c003000;
                8'd175: subject_row = 48'h00000c003000;
                default: subject_row = 48'd0;
            endcase
        end
    endfunction

    wire graph_slot_active = x >= 58 && x < 502;
    wire [9:0] graph_x = x - 10'd58;
    wire [2:0] graph_slot = graph_x / 10'd74;
    wire [6:0] slot_x = graph_x % 10'd74;
    wire score_occurred = graph_score[graph_slot] != 16'hffff;
    wire score_column = graph_slot_active && score_occurred &&
                        slot_x >= 18 && slot_x < 56 &&
                        y >= 9'd226 - {1'b0, graph_height[graph_slot]} && y <= 226;
    wire [47:0] subject_pixels = subject_row(graph_slot, y - 9'd230);
    wire subject_label = graph_slot_active && slot_x >= 13 && slot_x < 61 &&
                         y >= 230 && y < 250 && subject_pixels[7'd60 - slot_x];
    wire score_label = graph_slot_active && slot_x >= 22 && slot_x < 54 &&
                       y >= 252 && y < 262 &&
                       digit_pixel({graph_score[graph_slot], 4'd0}, slot_x - 7'd22, y - 9'd252);
    wire student_label = x >= 261 && x < 301 && y >= 34 && y < 44 &&
                         digit_pixel(graph_student, x - 10'd261, y - 9'd34);
    wire scale_label = x >= 48 && x < 80 && y >= 61 && y < 71 &&
                       digit_pixel({graph_scale, 4'd0}, x - 10'd48, y - 9'd61);
    wire graph_grid = graph_slot_active && (y == 226 || y == 152 || y == 78);
    reg [15:0] column_color;
    always @* begin
        case (graph_slot)
            0: column_color = 16'h5edf;
            1: column_color = 16'h3eeb;
            2: column_color = 16'hf5ab;
            3: column_color = 16'he4fd;
            4: column_color = 16'h4df7;
            default: column_color = 16'hfcad;
        endcase
    end
    wire [15:0] graph_pixel = student_label || scale_label || subject_label || score_label ?
                              16'hffff : score_column ? column_color :
                              graph_grid ? 16'h4aac : 16'h08a4;
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
                            graph_view ? graph_pixel :
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



