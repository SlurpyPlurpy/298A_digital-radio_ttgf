// nco.v
//
// Interface assumptions:
// - 50 MHz input clock
// - 16-bit phase accumulator
// - 7-bit frequency control supplied by ui_in[7:1]
// - 8-bit signed sine sample for the mixer
//
// TODO: Implement phase-to-amplitude conversion. A compact quarter-wave LUT
// with symmetry is one option. Map freq_ctrl to a phase increment based on the
// desired tuning range and the actual clock frequency.

module nco #(
    parameter PHASE_WIDTH = 16,
    parameter SAMPLE_WIDTH = 8
) (
    input  wire                         clk,
    input  wire                         rst_n,
    input  wire [6:0]                   freq_ctrl,
    output reg  signed [SAMPLE_WIDTH-1:0] sample,
    output reg                          sample_valid
);

    reg [PHASE_WIDTH-1:0] phase;
    reg [PHASE_WIDTH-1:0] phase_increment;

    // Placeholder frequency mapping.
    // TODO: Replace this with a documented mapping from 7-bit control values
    // to the desired 535 kHz - 1800 kHz tuning range.
    always @* begin
        phase_increment = {{(PHASE_WIDTH-7){1'b0}}, freq_ctrl};
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            phase        <= {PHASE_WIDTH{1'b0}};
            sample       <= {SAMPLE_WIDTH{1'b0}};
            sample_valid <= 1'b0;
        end else begin
            phase        <= phase + phase_increment;

            // Placeholder output; replace with sine lookup/approximation
            // driven by the appropriate bits of the updated phase.
            sample       <= {SAMPLE_WIDTH{1'b0}};
            sample_valid <= 1'b1;
        end
    end

endmodule
