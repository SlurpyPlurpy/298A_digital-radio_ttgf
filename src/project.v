/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

// Temporary FIR-only wrapper for area estimation and pin-level testing.
// Supply q = floor(mixer_product / 16), a signed 12-bit value, on:
//   ui_in[7:0]  = q[7:0]   (original mixer product bits [11:4])
//   uio_in[3:0] = q[11:8]  (original mixer product bits [15:12])
// Supported q range: -1016 through +1024, including both mixer endpoints.
// The omitted product bits [3:0] are discarded by the FIR anyway.
// uio_in[4] selects the output byte: 0 = bits [7:0], 1 = bits [13:8]
// sign-extended to eight bits. Read both pages between sample edges;
// there is no output snapshot register. uio_in[7:5] are unused.
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
    wire signed [15:0] mixer_sample;
    wire signed [13:0] fir_sum;

    // Restore the bit positions expected by the unchanged FIR interface.
    // Its initial >>> 4 recovers q exactly, including negative values.
    assign mixer_sample = {uio_in[3:0], ui_in, 4'b0000};

    fir_filter u_fir (
        .clk(clk),
        .rst_n(rst_n),
        .sample_en(1'b1),
        .mixer_sample(mixer_sample),
        .fir_sum(fir_sum)
    );

    // Both pages are externally observable so all FIR output bits are used.
    assign uo_out = uio_in[4] ? {{2{fir_sum[13]}}, fir_sum[13:8]}
                                : fir_sum[7:0];
    assign uio_out = 8'b0;
    assign uio_oe = 8'b0;  // All bidirectional pins operate as inputs.

    wire _unused = &{ena, uio_in[7:5], 1'b0};
endmodule

`default_nettype wire
