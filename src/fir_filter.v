`default_nettype none

// Full-rate, two-stage 11-sample moving-sum FIR (no decimation).
// mixer_sample must be the full product of two signed 8-bit operands:
// -16256 through +16384. Other 16-bit inputs can overflow the sums.
// Tie sample_en high for one sample per clock at the nominal 1 MHz.
// Each >>> 4 rounds toward negative infinity; no division by 11 is used.
// fir_sum is raw signed output, with nominal DC scale 121/256.
// Accepted edge 0 updates stage 1 while stage 2 consumes its reset sum.
// After accepted edge n+1, fir_sum equals mathematical FIR sample n.
// Thus the 10-sample filter group delay has one extra pipeline interval.
module fir_filter (
    input  wire               clk,
    input  wire               rst_n,
    input  wire               sample_en,
    input  wire signed [15:0] mixer_sample,
    output wire signed [13:0] fir_sum
);
    wire signed [11:0] stage1_input;
    wire signed [14:0] stage1_sum;
    wire signed [10:0] stage2_input;

    // Explicitly discard four fractional bits (equivalent to signed >>> 4).
    // Assignment to signed wires preserves negative two's-complement values.
    assign stage1_input = mixer_sample[15:4];
    assign stage2_input = stage1_sum[14:4];

    wire _unused = &{mixer_sample[3:0], stage1_sum[3:0], 1'b0};

    fir_filter_sum11 #(.INPUT_WIDTH(12), .SUM_WIDTH(15)) u_stage1 (
        .clk(clk), .rst_n(rst_n), .sample_en(sample_en),
        .sample_in(stage1_input), .sum_out(stage1_sum)
    );

    fir_filter_sum11 #(.INPUT_WIDTH(11), .SUM_WIDTH(14)) u_stage2 (
        .clk(clk), .rst_n(rst_n), .sample_en(sample_en),
        .sample_in(stage2_input), .sum_out(fir_sum)
    );
endmodule

// SUM_WIDTH must cover eleven samples over the caller's supported range.
// The two instances use 253 history bits and 29 accumulator bits total.
module fir_filter_sum11 #(
    parameter INPUT_WIDTH = 12,
    parameter SUM_WIDTH = 15
) (
    input  wire                          clk,
    input  wire                          rst_n,
    input  wire                          sample_en,
    input  wire signed [INPUT_WIDTH-1:0] sample_in,
    output reg  signed [SUM_WIDTH-1:0]   sum_out
);
    reg signed [INPUT_WIDTH-1:0] history [0:10];
    wire signed [SUM_WIDTH-1:0] entering_sample;
    wire signed [SUM_WIDTH-1:0] leaving_sample;
    wire signed [SUM_WIDTH-1:0] sum_without_oldest;
    integer i;

    assign entering_sample = {{(SUM_WIDTH-INPUT_WIDTH){sample_in[INPUT_WIDTH-1]}}, sample_in};
    assign leaving_sample = {{(SUM_WIDTH-INPUT_WIDTH){history[10][INPUT_WIDTH-1]}}, history[10]};
    // Subtract first: the intermediate is the sum of ten retained entries.
    assign sum_without_oldest = sum_out - leaving_sample;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum_out <= {SUM_WIDTH{1'b0}};
            for (i = 0; i < 11; i = i + 1)
                history[i] <= {INPUT_WIDTH{1'b0}};
        end else if (sample_en) begin
            sum_out <= sum_without_oldest + entering_sample;
            history[0] <= sample_in;
            for (i = 1; i < 11; i = i + 1)
                history[i] <= history[i-1];
        end
    end
endmodule

`default_nettype wire
