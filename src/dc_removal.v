`default_nettype none

module dc_removal (
    input  wire               clk,
    input  wire               rst_n,
    input  wire               sample_en,
    input  wire signed [13:0] sample_in,   // 14-bit signed FIR filter output
  output wire signed [13:0] audio_out    // signed audio output after DC is removed
);

    reg signed [24:0] avg_reg;
  
    // Scale the incoming 14-bit sample to match the 11-bit fractional fixed-point scale (multiply by 2048)
    wire signed [24:0] scaled_sample = {sample_in, 11'b0};
    
    // error = difference between current scaled sample and current average
    wire signed [24:0] error = scaled_sample - avg_reg;
    
    // Update average
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Startup policy: Initialize average to the first incoming sample scaled up
            avg_reg <= {sample_in, 11'b0};
        end else if (sample_en) begin
            avg_reg <= avg_reg + (error >>> 9); // shift right by 9 bits (1/512) towards the sampel
        end
    end

    // subtract the tracked average from the scaled sample to get AC audio, then shift back down by 11
    wire signed [24:0] dc_removed = scaled_sample - avg_reg;
    assign audio_out = dc_removed[24:11]; // Extract whole-number signed audio bits

endmodule

`default_nettype wire
