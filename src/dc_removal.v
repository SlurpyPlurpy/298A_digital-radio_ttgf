`default_nettype none

module dc_removal (
    input  wire               clk,
    input  wire               rst_n,
    input  wire               sample_en,
    input  wire signed [13:0] sample_in,   // 14-bit signed FIR filter output
    output wire signed [13:0] audio_out    // signed audio output after DC is removed
);

    // 14 integer/sign bits plus 9 fractional bits. The tracking factor
    // remains 1/512; reducing fractional precision does not change the gain.
    reg signed [22:0] avg_reg;
  
    // Scale the incoming 14-bit sample to match the 9-bit fractional fixed-point scale (multiply by 512)
    wire signed [22:0] scaled_sample = {sample_in, 9'b0};
    
    // error = difference between current scaled sample and current average
    wire signed [22:0] error = scaled_sample - avg_reg;
    
    // Update average
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset the average to a constant zero for hardware synthesis.
            avg_reg <= 23'sd0;
        end else if (sample_en) begin
            avg_reg <= avg_reg + (error >>> 9); // shift right by 9 bits (1/512) towards the sample
        end
    end

    // subtract the tracked average from the scaled sample to get AC audio, then shift back down by 9
    wire signed [22:0] dc_removed = scaled_sample - avg_reg;
    assign audio_out = dc_removed[22:9]; // Extract whole-number signed audio bits

    // The fractional output bits are intentionally discarded.
    wire _unused = &{dc_removed[8:0], 1'b0};

endmodule

`default_nettype wire
