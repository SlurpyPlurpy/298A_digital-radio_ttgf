`default_nettype none

// Full-rate, two-stage 11-sample moving-sum FIR (no decimation).
// mixer_sample must be the product of a signed 8-bit ADC sample and
// the current NCO reference (-124 to +124): -15872 through +15872.
// This bound lets stage 1 store (mixer_sample >>> 5) in 10 signed bits.
// Arbitrary signed 8x8 products are not supported (e.g. +16384).
// Tie sample_en high for one sample per clock at the nominal 1 MHz.
// Stage 1 shifts by 5 and stage 2 by 4; both round toward negative infinity.
// No division by 11 is used.
// fir_sum is raw signed output, with nominal DC scale 121/512.
// Accepted edge 0 captures the shifted mixer sample in an input register.
// Stage 1 consumes it on edge 1; stage 2 consumes that sum on edge 2.
// After accepted edge n+2, fir_sum equals mathematical FIR sample n.
// Thus the 10-sample filter group delay has two extra pipeline intervals.
module fir_filter (
    input  wire               clk,
    input  wire               rst_n,
    input  wire               sample_en,
    input  wire signed [15:0] mixer_sample,
    output wire signed [13:0] fir_sum
);
    reg  signed [9:0] stage1_input;
    wire signed [13:0] stage1_sum;
    wire signed [9:0] stage2_input;
    wire signed [12:0] stage2_sum;

    // Both histories shift on the same accepted edges, including the initial
    // pipeline zeros. Their validity therefore uses one shared fill counter.
    reg [3:0] fill_count;
    wire history_full = (fill_count == 4'd11);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            fill_count <= 4'd0;
        else if (sample_en && !history_full)
            // The 12th accepted sample is the first to subtract old history.
            fill_count <= fill_count + 4'd1;
    end

    // Discard five low bits before stage 1 and four before stage 2.
    // Assignment to signed wires preserves negative two's-complement values.
    // Bit 15 duplicates bit 14 throughout the supported mixer range.
    // Break the lookup/multiplier-to-accumulator path after truncation.
    // Reset inserts one zero sample; pauses hold the entire FIR pipeline.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            stage1_input <= 10'sd0;
        else if (sample_en)
            stage1_input <= mixer_sample[14:5];
    end
    assign stage2_input = stage1_sum[13:4];
    // Preserve the 14-bit interface by sign-extending the 13-bit sum.
    assign fir_sum = {stage2_sum[12], stage2_sum};

    wire _unused = &{mixer_sample[15], mixer_sample[4:0], stage1_sum[3:0], 1'b0};

    fir_filter_sum11 #(.INPUT_WIDTH(10), .SUM_WIDTH(14)) u_stage1 (
        .clk(clk), .rst_n(rst_n), .sample_en(sample_en),
        .history_full(history_full), .sample_in(stage1_input), .sum_out(stage1_sum)
    );

    fir_filter_sum11 #(.INPUT_WIDTH(10), .SUM_WIDTH(13)) u_stage2 (
        .clk(clk), .rst_n(rst_n), .sample_en(sample_en),
        .history_full(history_full), .sample_in(stage2_input), .sum_out(stage2_sum)
    );
endmodule

// SUM_WIDTH must cover eleven samples over the caller's supported range.
// The two instances use 220 history bits and 27 accumulator bits total.
// The wrapper adds a 10-bit input pipeline register and shared 4-bit fill counter.
// history_full must stay low until eleven samples have been accepted after reset.
module fir_filter_sum11 #(
    parameter INPUT_WIDTH = 12,
    parameter SUM_WIDTH = 15
) (
    input  wire                          clk,
    input  wire                          rst_n,
    input  wire                          sample_en,
    input  wire                          history_full,
    input  wire signed [INPUT_WIDTH-1:0] sample_in,
    output reg  signed [SUM_WIDTH-1:0]   sum_out
);
    // History needs no reset: mask its outgoing sample until all entries
    // have been overwritten by samples accepted since the latest reset.
    reg signed [INPUT_WIDTH-1:0] history [0:10];
    wire signed [SUM_WIDTH-1:0] entering_sample;
    wire signed [SUM_WIDTH-1:0] leaving_sample;
    wire signed [SUM_WIDTH-1:0] sum_without_oldest;
    integer i;

    assign entering_sample = {{(SUM_WIDTH-INPUT_WIDTH){sample_in[INPUT_WIDTH-1]}}, sample_in};
    assign leaving_sample = history_full
        ? {{(SUM_WIDTH-INPUT_WIDTH){history[10][INPUT_WIDTH-1]}}, history[10]}
        : {SUM_WIDTH{1'b0}};
    // Subtract first: the intermediate is the sum of ten retained entries.
    assign sum_without_oldest = sum_out - leaving_sample;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum_out <= {SUM_WIDTH{1'b0}};
        end else if (sample_en) begin
            sum_out <= sum_without_oldest + entering_sample;
        end
    end

    // Plain flip-flops: shifting during reset is harmless because history_full
    // remains low. Only samples accepted after reset make history valid.
    always @(posedge clk) begin
        if (sample_en) begin
            history[0] <= sample_in;
            for (i = 1; i < 11; i = i + 1)
                history[i] <= history[i-1];
        end
    end
endmodule

`default_nettype wire
