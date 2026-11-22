`default_nettype none

module scaling_limiter (
    input  wire signed [13:0] audio_in,
    output reg  signed [9:0]  audio_out   // Clamped 10-bit signed range (-512 to +511)
);

    // The 6/4 FIR halves the nominal output versus 5/4. Divide by two
    // instead of four to preserve nominal end-to-end gain; rounding differs.
    wire signed [13:0] scaled_audio = audio_in >>> 1;

    always @(*) begin
      // limit to prevent distortion from any overflow wraparound (cut off any larger audios to be within the max range)
        if (scaled_audio > 14'sd511) begin
            audio_out = 10'sd511;           // set to maximum positive limit
        end else if (scaled_audio < -14'sd512) begin
            audio_out = -10'sd512;          // set to maximum negative limit
        end else begin
          audio_out = scaled_audio[9:0];  // if it is within range, pass through
        end
    end

endmodule

`default_nettype wire
