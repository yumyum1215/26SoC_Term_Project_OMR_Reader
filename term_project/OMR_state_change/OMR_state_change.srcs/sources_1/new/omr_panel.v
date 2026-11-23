module omr_panel (
    input wire clk, resetn,
    input wire [3:0] raw_buttons,
    input wire [31:0] digits,
    output reg [3:0] debounced = 4'hf,
    output wire [7:0] segcom,
    output reg [7:0] segdata
);
    (* ASYNC_REG = "TRUE" *) reg [3:0] sync_1 = 4'hf, sync_2 = 4'hf;
    reg [18:0] stable_count [0:3];
    reg [15:0] scan = 0;
    reg [2:0] position = 0;
    integer i;
    always @(posedge clk) begin
        sync_1 <= raw_buttons;
        sync_2 <= sync_1;
        if (!resetn) begin
            scan <= 0;
            position <= 0;
            debounced <= 4'hf;
            for (i = 0; i < 4; i = i + 1)
                stable_count[i] <= 0;
        end else begin
            scan <= scan + 1'b1;
            if (scan == 16'hffff)
                position <= position + 1'b1;
            for (i = 0; i < 4; i = i + 1) begin
                if (sync_2[i] == debounced[i])
                    stable_count[i] <= 0;
                else if (stable_count[i] == 19'd499999) begin
                    debounced[i] <= sync_2[i];
                    stable_count[i] <= 0;
                end else
                    stable_count[i] <= stable_count[i] + 1'b1;
            end
        end
    end

    assign segcom = scan < 100 ? 8'hff : ~(8'b10000000 >> position);
    always @* begin
        case (digits[31 - position * 4 -: 4])
            0: segdata = 8'h3f;
            1: segdata = 8'h06;
            2: segdata = 8'h5b;
            3: segdata = 8'h4f;
            4: segdata = 8'h66;
            5: segdata = 8'h6d;
            6: segdata = 8'h7d;
            7: segdata = 8'h07;
            8: segdata = 8'h7f;
            9: segdata = 8'h6f;
            default: segdata = 8'h00;
        endcase
    end
endmodule
