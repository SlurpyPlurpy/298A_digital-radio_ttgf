/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_angela_ethan_digitalradio (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

    // Integration baseline: one 50 MHz clock, asynchronous active-low reset.
    // ui_in[0] must already be logic-level RF. No analog conversion or
    // input synchronizer is implemented here.
    localparam NCO_WIDTH = 8;
    localparam MIX_WIDTH = NCO_WIDTH + 1;
    localparam CIC_WIDTH = MIX_WIDTH + 30;
    localparam AUDIO_WIDTH = 10;

    wire signed [NCO_WIDTH-1:0] osc_sample;
    wire osc_valid;
    wire signed [MIX_WIDTH-1:0] mixed_sample;
    wire signed [CIC_WIDTH-1:0] baseband_sample;
    wire baseband_valid;
    wire signed [AUDIO_WIDTH-1:0] audio_sample;
    wire audio_pwm;

    nco #(.PHASE_WIDTH(16), .SAMPLE_WIDTH(NCO_WIDTH)) u_nco (
        .clk(clk), .rst_n(rst_n), .freq_ctrl(ui_in[7:1]),
        .sample(osc_sample), .sample_valid(osc_valid)
    );

    mixer #(.SAMPLE_WIDTH(NCO_WIDTH)) u_mixer (
        .rf_in(ui_in[0]), .osc_in(osc_sample), .mixed_out(mixed_sample)
    );

    cic #(
        .INPUT_WIDTH(MIX_WIDTH), .STAGES(3),
        .DECIMATION(1024), .OUTPUT_WIDTH(CIC_WIDTH)
    ) u_cic (
        .clk(clk), .rst_n(rst_n), .data_in(mixed_sample),
        .data_valid(osc_valid), .data_out(baseband_sample),
        .sample_valid(baseband_valid)
    );

    // PROVISIONAL baseband monitor, not a complete AM demodulator.
    // CIC DC gain is 1024^3 = 2^30. Taking the signed top ten bits
    // divides by 2^29, normalizing that gain and applying a gain of two.
    // This truncates with no rounding, DC removal, or AGC.
    // TODO: Insert the selected AM demodulation/DC-removal stage here.
    assign audio_sample = baseband_sample[CIC_WIDTH-1:CIC_WIDTH-AUDIO_WIDTH];

    pwm #(.AUDIO_WIDTH(AUDIO_WIDTH), .PWM_BITS(AUDIO_WIDTH)) u_pwm (
        .clk(clk), .rst_n(rst_n), .audio_in(audio_sample),
        .sample_valid(baseband_valid), .pwm_out(audio_pwm)
    );

    // Pinout matches info.yaml. Debug is the NCO sample sign bit.
    assign uo_out = {6'b0, osc_sample[NCO_WIDTH-1], audio_pwm};
    assign uio_out = 8'b0;
    assign uio_oe = 8'b0;

    // Unused interface inputs and intentionally discarded audio precision.
    wire _unused = &{ena, uio_in, baseband_sample[CIC_WIDTH-AUDIO_WIDTH-1:0], 1'b0};

endmodule

`default_nettype wire
