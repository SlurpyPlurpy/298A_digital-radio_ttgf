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
    wire signed [7:0] sine_reference; // 8-bit local oscillator output of reference wave
    wire signed [13:0] dc_removed_audio;
    wire signed [9:0] limited_audio;
    wire signed [7:0] if_sample = $signed(ui_in);
    wire              pwm_out;


    // NCO
    wire [23:0] tuning_word = 24'd7633633;  // no longer having an input to select the channel since we are assuming a clean 455kHz incoming signal
                                            // tuning word = 455000 * 2^24 / 1000000 = 7633633 approx
    nco_sine_gen u_nco (
        .clk(clk),
        .rst_n(rst_n),
        .tuning_word(tuning_word),
        .sine_reference(sine_reference)
    );
    
    // BEGIN TEMPORARY INPUT ADAPTER
    // TODO: Remove this assignment when the multiplier drives mixer_sample.
    // Feed the final multiplier from ui_in (IF) and uio_in (local reference).
    // For now supply q=floor(product/16), range -1016..+1024:
    // ui_in=q[7:0], uio_in[3:0]=q[11:8]. Restore four discarded low bits
    // as zeros; the FIR's initial >>> 4 recovers q exactly.
    // assign mixer_sample = {uio_in[3:0], ui_in, 4'b0000};
    // END TEMPORARY INPUT ADAPTER

    // Mixer
    
    assign mixer_sample = $signed(if_sample) * $signed(sine_reference) ;

    // FIR filter

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
    // END TEMPORARY OUTPUT ADAPTER

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
    

    
    wire [7:0] fir_high_byte = { {2{fir_sum[13]}}, fir_sum[13:8] };

    // Decode hardware modes directly; X detection belongs in the testbench.
    assign uo_out = (uio_in[7:4] == 4'h2) ? sine_reference :
                    (uio_in[7:4] == 4'h3) ? (uio_in[0] ? mixer_sample[15:8] : mixer_sample[7:0]) :
                    (uio_in[7:4] == 4'h4) ? (uio_in[4] ? fir_high_byte : fir_sum[7:0]) :
                    (uio_in[7:4] == 4'h5) ? dc_removed_audio[7:0] :
                    (uio_in[7:4] == 4'h6) ? limited_audio[7:0] :
                    (uio_in[7:4] == 4'h8) ? {7'b0, pwm_out} : 
                    8'h00;

    assign uio_out = 8'b0;
    assign uio_oe  = 8'b0;  

    wire _unused = &{ena, uio_in[3:1], uio_in[7:5], 1'b0};
endmodule

`default_nettype wire
