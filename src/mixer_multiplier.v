`default_nettype none

// Exact signed 8x8 multiplication with one internal register boundary.
// Accepts a new operand pair every clock. After each rising edge, product
// corresponds to the pair sampled at that edge, after combinational settling.
// The existing FIR input register captures the combined result next clock.
module mixer_multiplier (
    input  wire               clk,
    input  wire               rst_n,
    input  wire signed [7:0]  sample_a,
    input  wire signed [7:0]  sample_b,
    output wire signed [15:0] product
);
    // In two's complement, b = signed(b[7:4])*16 + unsigned(b[3:0]).
    // A leading zero makes the low nibble a nonnegative signed operand.
    wire signed [4:0] b_low = {1'b0, sample_b[3:0]};
    wire signed [3:0] b_high = sample_b[7:4];
    reg signed [11:0] low_product;
    reg signed [11:0] high_product;

    // Both products fit 12 signed bits:
    // low: -1920..1905; high: -1016..1024, including -128 * -8.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            low_product <= 12'sd0;
            high_product <= 12'sd0;
        end else begin
            low_product <= sample_a * b_low;
            high_product <= sample_a * b_high;
        end
    end

    // Stage 2: combine registered partial products without truncation.
    // Keep the low-bit carries; the FIR applies its existing five-bit shift.
    wire signed [15:0] low_extended = {{4{low_product[11]}}, low_product};
    wire signed [15:0] high_shifted = {high_product, 4'b0};
    assign product = low_extended + high_shifted;
endmodule

`default_nettype wire
