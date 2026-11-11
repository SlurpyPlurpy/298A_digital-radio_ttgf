/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

// Radio backend integration: multiplier -> mixer_sample -> FIR -> fir_sum
// -> audio scaling/PWM -> uo_out[0].
// TEMPORARY pin adapters below keep the FIR observable for area estimation.
module tt_um_angela_ethan_digitalradio (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);
    // Permanent internal connection points; keep these when integrating.
    wire signed [15:0] mixer_sample; // Full signed 8x8 multiplier product.
    wire signed [13:0] fir_sum;      // Raw FIR result for audio scaling/PWM.

    // BEGIN TEMPORARY INPUT ADAPTER
    // TODO: Remove this assignment when the multiplier drives mixer_sample.
    // Feed the final multiplier from ui_in (IF) and uio_in (local reference).
    // For now supply q=floor(product/16), range -1016..+1024:
    // ui_in=q[7:0], uio_in[3:0]=q[11:8]. Restore four discarded low bits
    // as zeros; the FIR's initial >>> 4 recovers q exactly.
    assign mixer_sample = {uio_in[3:0], ui_in, 4'b0000};
    // END TEMPORARY INPUT ADAPTER

    fir_filter u_fir (
        .clk(clk),
        .rst_n(rst_n),
        .sample_en(1'b1),
        .mixer_sample(mixer_sample),
        .fir_sum(fir_sum)
    );

    // BEGIN TEMPORARY OUTPUT ADAPTER
    // TODO: Remove this assignment when fir_sum feeds audio scaling/PWM.
    // Connect that module's PWM output to uo_out[0], zero unused output pins,
    // and update the project-level test. No FIR instance changes are needed.
    // For now uio_in[4] selects low byte (0) or sign-extended high byte (1).
    // Read both pages between sample edges; there is no snapshot register.
    // Keeping both pages observable prevents removal of unused FIR bits.
    assign uo_out = uio_in[4] ? {{2{fir_sum[13]}}, fir_sum[13:8]}
                                : fir_sum[7:0];
    // END TEMPORARY OUTPUT ADAPTER
    assign uio_out = 8'b0;
    assign uio_oe = 8'b0;  // All bidirectional pins operate as inputs.

    // TODO: Remove uio_in[7:5] here once the multiplier uses all reference bits.
    wire _unused = &{ena, uio_in[7:5], 1'b0};
endmodule

`default_nettype wire
