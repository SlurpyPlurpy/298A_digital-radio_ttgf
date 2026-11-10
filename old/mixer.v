// mixer.v
// Real-valued 1-bit RF x signed NCO mixer.
//
// Assumption: rf_in is encoded as bipolar data:
//   rf_in == 1 -> +1
//   rf_in == 0 -> -1
// Under that assumption, mixing is selecting the NCO sample or its negation;
// no general multiplier is needed.
//
// The output is one bit wider than the NCO input so negating the most-negative
// SAMPLE_WIDTH-bit value cannot overflow. This is a small correctness cost.

module mixer #(
    parameter SAMPLE_WIDTH = 8
) (
    input  wire                           rf_in,
    input  wire signed [SAMPLE_WIDTH-1:0]  osc_in,
    output wire signed [SAMPLE_WIDTH:0]    mixed_out
);

    wire signed [SAMPLE_WIDTH:0] osc_extended;
    assign osc_extended = {osc_in[SAMPLE_WIDTH-1], osc_in};

    assign mixed_out = rf_in ? osc_extended : -osc_extended;

endmodule
