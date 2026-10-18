// cic.v
// CIC decimator: 3 integrator stages, rate change R=1024,
// followed by 3 comb stages with differential delay M=1.
//
// With INPUT_WIDTH=9 (the widened mixer output), STAGES=3,
// DECIMATION=1024, M=1, a common full-precision width estimate is
// 9 + 3*log2(1024) = 39 bits.
//
// This is intentionally conservative, not yet area-optimized or verified.
// Once it passes reference-model tests, evaluate stage-specific widths and
// carefully justified truncation/pruning against audio-quality requirements.

module cic #(
    parameter INPUT_WIDTH  = 9,
    parameter STAGES       = 3,
    parameter DECIMATION   = 1024,
    parameter OUTPUT_WIDTH = INPUT_WIDTH + 30
) (
    input  wire                           clk,
    input  wire                           rst_n,
    input  wire signed [INPUT_WIDTH-1:0]  data_in,
    input  wire                           data_valid,
    output reg  signed [OUTPUT_WIDTH-1:0] data_out,
    output reg                            sample_valid
);

    localparam COUNT_WIDTH = (DECIMATION <= 2) ? 1 : $clog2(DECIMATION);

    reg signed [OUTPUT_WIDTH-1:0] integrator [0:STAGES-1];
    reg signed [OUTPUT_WIDTH-1:0] comb_delay [0:STAGES-1];
    reg [COUNT_WIDTH-1:0] decim_count;

    wire signed [OUTPUT_WIDTH-1:0] integrator_input;
    wire signed [OUTPUT_WIDTH-1:0] comb_stage [0:STAGES];

    integer i;
    genvar k;

    // Sign-extend the input into the internal accumulator width.
    assign integrator_input =
        {{(OUTPUT_WIDTH-INPUT_WIDTH){data_in[INPUT_WIDTH-1]}}, data_in};

    // Combinational cascade of comb differences. Each delay stores the
    // previous value entering that comb stage.
    assign comb_stage[0] = integrator[STAGES-1];

    generate
        for (k = 0; k < STAGES; k = k + 1) begin : gen_comb
            assign comb_stage[k+1] = comb_stage[k] - comb_delay[k];
        end
    endgenerate

    // Integrator chain: one update per valid input sample.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < STAGES; i = i + 1)
                integrator[i] <= {OUTPUT_WIDTH{1'b0}};
            decim_count <= {COUNT_WIDTH{1'b0}};
        end else if (data_valid) begin
            integrator[0] <= integrator[0] + integrator_input;
            for (i = 1; i < STAGES; i = i + 1)
                integrator[i] <= integrator[i] + integrator[i-1];

            if (decim_count == DECIMATION-1)
                decim_count <= {COUNT_WIDTH{1'b0}};
            else
                decim_count <= decim_count + 1'b1;
        end
    end

    // Update comb delays only when a decimated sample is available.
    // data_out is registered at that same event.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < STAGES; i = i + 1)
                comb_delay[i] <= {OUTPUT_WIDTH{1'b0}};
            data_out     <= {OUTPUT_WIDTH{1'b0}};
            sample_valid <= 1'b0;
        end else begin
            sample_valid <= 1'b0;
            if (data_valid && decim_count == DECIMATION-1) begin
                for (i = 0; i < STAGES; i = i + 1)
                    comb_delay[i] <= comb_stage[i];
                data_out     <= comb_stage[STAGES];
                sample_valid <= 1'b1;
            end
        end
    end

endmodule
