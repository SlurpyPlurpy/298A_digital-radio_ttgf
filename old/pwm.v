// pwm.v
// Counter-based PWM audio output
//
// At 50 MHz, PWM_BITS=10 gives a carrier of about 48.8 kHz. Increasing
// PWM_BITS improves duty resolution but lowers carrier frequency.
// Confirm this trade-off against the intended analog output filter and
// the actual Tiny Tapeout output-pin constraints.
//
// TODO: Confirm the signed-audio scaling/offset and whether AUDIO_WIDTH
// should equal PWM_BITS. This template assumes matching widths.

module pwm #(
    parameter AUDIO_WIDTH = 10,
    parameter PWM_BITS    = 10
) (
    input  wire                          clk,
    input  wire                          rst_n,
    input  wire signed [AUDIO_WIDTH-1:0] audio_in,
    input  wire                          sample_valid,
    output reg                           pwm_out
);

    reg [PWM_BITS-1:0] carrier;
    reg [PWM_BITS-1:0] duty;

    // For equal widths, reinterpret signed two's-complement audio as an
    // unsigned duty value by flipping the sign bit. This maps the signed
    // range into an unsigned range without a wide adder.
    wire [PWM_BITS-1:0] duty_from_audio;
    assign duty_from_audio = audio_in[AUDIO_WIDTH-1] ?
        {1'b0, audio_in[AUDIO_WIDTH-2:0]} :
        {1'b1, audio_in[AUDIO_WIDTH-2:0]};

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            carrier <= {PWM_BITS{1'b0}};
            duty    <= {PWM_BITS{1'b0}};
            pwm_out <= 1'b0;
        end else begin
            carrier <= carrier + 1'b1;

            if (sample_valid)
                duty <= duty_from_audio;

            pwm_out <= (carrier < duty);
        end
    end

endmodule
