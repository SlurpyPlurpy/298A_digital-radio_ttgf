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

    reg [7:0] pwm_counter;
    reg       pwm_out_reg;


    // Reference sine wave lookup table
    reg [5:0] lut_addr;
    // increments table address pointer at every clock edge
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lut_addr <= 6'd0;                                // reset back to zero on rst_n
        end else begin
            lut_adr <= lut_addr + 6'd1;                      // step to the next entry on clock edge
        end 
    end

    always @(*) begin
        case (lut_addr)
            6'd0:  sine_wave = 8'sd0;      // 0 degrees phase point
            6'd1:  sine_wave = 8'sd25;     
            6'd2:  sine_wave = 8'sd50;
            6'd3:  sine_wave = 8'sd74;
            6'd4:  sine_wave = 8'sd95;
            6'd5:  sine_wave = 8'sd112;
            6'd6:  sine_wave = 8'sd124;
            6'd7:  sine_wave = 8'sd127;    // Positive peak amplitude (~90 degrees)
            6'd8:  sine_wave = 8'sd124;
            6'd9:  sine_wave = 8'sd112;
            6'd10: sine_wave = 8'sd95;
            6'd11: sine_wave = 8'sd74;
            6'd12: sine_wave = 8'sd50;
            6'd13: sine_wave = 8'sd25;
            6'd14: sine_wave = 8'sd0;      // Zero crossing point (~180 degrees)
            6'd15: sine_wave = -8'sd25;    
            6'd16: sine_wave = -8'sd50;
            6'd17: sine_wave = -8'sd74;
            6'd18: sine_wave = -8'sd95;
            6'd19: sine_wave = -8'sd112;
            6'd20: sine_wave = -8'sd124;
            6'd21: sine_wave = -8'sd127;   // Negative peak amplitude (~270 degrees)
            6'd22: sine_wave = -8'sd124;
            6'd23: sine_wave = -8'sd112;
            6'd24: sine_wave = -8'sd95;
            6'd25: sine_wave = -8'sd74;
            6'd26: sine_wave = -8'sd50;
            6'd27: sine_wave = -8'sd25;
            default: sine_wave = 8'sd0;    // Fallback safe value for any unlisted table addresses
        endcase
    end

    reg signed [7:0] sine_wave;
    assign sine_reference = sign+wave;
    
    // BEGIN TEMPORARY INPUT ADAPTER
    // TODO: Remove this assignment when the multiplier drives mixer_sample.
    // Feed the final multiplier from ui_in (IF) and uio_in (local reference).
    // For now supply q=floor(product/16), range -1016..+1024:
    // ui_in=q[7:0], uio_in[3:0]=q[11:8]. Restore four discarded low bits
    // as zeros; the FIR's initial >>> 4 recovers q exactly.
    // assign mixer_sample = {uio_in[3:0], ui_in, 4'b0000};
    // END TEMPORARY INPUT ADAPTER

    // Mixer
    
    assign mixer_sample = $signed({1'b0, ui_in}) * sine_reference;

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
    assign uo_out = uio_in[4] ? {{2{fir_sum[13]}}, fir_sum[13:8]}
                                : fir_sum[7:0];
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

    sacling_limiter u_limiter (
        .audio_in(dc_removed_audio),
        .audio_out(limited_audio)
    );

    //PWM

    pwm_modulator_1mhz u_pwm (
        .clk(clk),
        .rst_n(rst_n),
        audio_in(limited_audio),
        .pwm_out(uo_out[0])
    );
    
 
    assign uo_out[7:1] = 7'b0;
    assign uio_out = 8'b0;
    assign uio_oe = 8'b0;  // All bidirectional pins operate as inputs.

    // TODO: Remove uio_in[7:5] here once the multiplier uses all reference bits.
    wire _unused = &{ena, uio_in, 1'b0};
endmodule

`default_nettype wire
