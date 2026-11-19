`default_nettype none

module nco_sine_gen (
    input  wire               clk,
    input  wire               rst_n,
    output reg signed [7:0]   sine_reference
);

    // round(455000 * 2^24 / 1000000): 454999.983 Hz at a 1 MHz clock.
    localparam [23:0] PHASE_STEP = 24'd7633633;
    reg [23:0] phase_acc;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            phase_acc <= 24'd0;
        end else begin
            phase_acc <= phase_acc + PHASE_STEP;
        end
    end

    // Keep all 64 phase positions; store only the first quarter-wave.
    wire [5:0] lut_addr = phase_acc[23:18];

    // Quadrants 1 and 3 reflect the index: 16, 15, ..., 1.
    // Five bits retain index 16 at both waveform peaks (addresses 16/48).
    wire [4:0] quarter_addr = lut_addr[4]
        ? (5'd16 - {1'b0, lut_addr[3:0]})
        : {1'b0, lut_addr[3:0]};
    reg [6:0] quarter_magnitude;

    always @(*) begin
        case (quarter_addr)
            5'd0: quarter_magnitude = 7'd0;
            5'd1: quarter_magnitude = 7'd12;
            5'd2: quarter_magnitude = 7'd25;
            5'd3: quarter_magnitude = 7'd37;
            5'd4: quarter_magnitude = 7'd49;
            5'd5: quarter_magnitude = 7'd60;
            5'd6: quarter_magnitude = 7'd71;
            5'd7: quarter_magnitude = 7'd81;
            5'd8: quarter_magnitude = 7'd90;
            5'd9: quarter_magnitude = 7'd98;
            5'd10: quarter_magnitude = 7'd103;
            5'd11: quarter_magnitude = 7'd109;
            5'd12: quarter_magnitude = 7'd113;
            5'd13: quarter_magnitude = 7'd117;
            5'd14: quarter_magnitude = 7'd120;
            5'd15: quarter_magnitude = 7'd123;
            5'd16: quarter_magnitude = 7'd124;
            default: quarter_magnitude = 7'd0;
        endcase
    end

    // Extend to signed eight bits before negation. The second half-cycle
    // uses the same magnitudes with opposite sign, including zero at 32.
    wire signed [7:0] positive_sample = $signed({1'b0, quarter_magnitude});
    wire signed [7:0] sine_wave_rom = lut_addr[5]
        ? -positive_sample : positive_sample;

    always @(*) begin
        sine_reference = sine_wave_rom;
    end

endmodule

`default_nettype wire
