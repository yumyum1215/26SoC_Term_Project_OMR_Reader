module servo_pwm (
    input wire clk,
    input wire resetn,
    input wire [11:0] pulse_us,
    output reg pwm
);
    // The PS FCLK is 50 MHz. Sample commands once per 20 ms frame.
    localparam [19:0] FRAME_LAST = 20'd999999;
    reg [19:0] frame_count;
    reg [16:0] pulse_ticks;
    wire [16:0] requested_ticks = pulse_us * 17'd50;

    always @(posedge clk) begin
        if (!resetn) begin
            frame_count <= FRAME_LAST;
            pulse_ticks <= 0;
            pwm <= 0;
        end else if (frame_count == FRAME_LAST) begin
            frame_count <= 0;
            if (pulse_us >= 12'd1000 && pulse_us <= 12'd2000) begin
                pulse_ticks <= requested_ticks;
                pwm <= 1;
            end else begin
                pulse_ticks <= 0;
                pwm <= 0;
            end
        end else begin
            frame_count <= frame_count + 1'b1;
            if (frame_count == {3'b000, pulse_ticks} - 20'd1)
                pwm <= 0;
        end
    end
endmodule
