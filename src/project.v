/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

// Signed 8-bit IF samples at 1 MHz; the input carrier is phase-aligned
// with the fixed 455 kHz NCO. Mixer -> FIR -> DC removal -> limiter -> PWM.
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
    wire signed [15:0] mixer_sample; // Full signed 8x8 multiplier product.
    wire signed [13:0] fir_sum;      // Raw FIR result for audio scaling/PWM.
    wire signed [7:0] sine_reference; // 8-bit local oscillator output of reference wave
    wire signed [13:0] dc_removed_audio;
    wire signed [9:0] limited_audio;
    wire signed [7:0] if_sample = $signed(ui_in);
    wire              pwm_out;

    // Fixed-frequency reference, independent of the ADC sample bus.
    nco_sine_gen u_nco (
        .clk(clk),
        .rst_n(rst_n),
        .sine_reference(sine_reference)
    );
    

    // Mixer
    
    assign mixer_sample = if_sample * sine_reference;

    // FIR filter

    fir_filter u_fir (
        .clk(clk),
        .rst_n(rst_n),
        .sample_en(1'b1),
        .mixer_sample(mixer_sample),
        .fir_sum(fir_sum)
    );

    // DC removal

    dc_removal u_dc_rem (
        .clk(clk),
        .rst_n(rst_n),
        .sample_en(1'b1),
        .sample_in(fir_sum),
        .audio_out(dc_removed_audio)
    );

    // Scaling and Limiting

    scaling_limiter u_limiter (
        .audio_in(dc_removed_audio),
        .audio_out(limited_audio)
    );

    //PWM

    pwm_modulator_1mhz u_pwm (
        .clk(clk),
        .rst_n(rst_n),
        .audio_in(limited_audio),
        .pwm_out(pwm_out)
    );
    

    
    // PWM is always available; no hardware debug selector is required.
    assign uo_out = {7'b0, pwm_out};

    assign uio_out = 8'b0;
    assign uio_oe  = 8'b0;  

    wire _unused = &{ena, uio_in, 1'b0};
endmodule

`default_nettype wire
