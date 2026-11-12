`default_nettype none

module pwm_modulator_1mhz (
    input  wire               clk,
    input  wire               rst_n,
    input  wire signed [9:0]  audio_in,    // 10-bit signed audio input (-512 to +511)
    output reg                pwm_out      // 1-bit PWM audio output pin
);

    // 5-bit free-running ramp counter (0 to 31) -> 31.25 kHz carrier at 1 MHz clock
    reg [4:0] pwm_counter;
    
    // Double-buffered duty registers (scaled down to 5 bits: 0 to 31)
    reg [4:0] active_duty;
    reg [4:0] pending_duty;

  // Map signed 10-bit audio (-512 to +511) to an unsigned 5-bit duty value (0 to 31) by dividing by 2^5 and shift to a non negative number (+16)
    wire [4:0] mapped_duty = audio_in[9:5] + 5'sd16;

    // Capture incoming audio into the pending duty register continuously
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pending_duty <= 5'd16; // Default to the midpoint (16 out of 32) on reset
        end else begin
            pending_duty <= mapped_duty;  // stores the calculated value at every clock cycle to temp
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pwm_counter <= 5'd0;
            active_duty <= 5'd16;
        end else begin
          if (pwm_counter == 5'd31) begin    // counts from 0 to 31 repeatedly 
                pwm_counter <= 5'd0;         
                active_duty <= pending_duty; // Transfer pending duty after a full cycle is complete -> values updates at 31.25 kHz which is now within the audiable rate
            end else begin
                pwm_counter <= pwm_counter + 5'd1;        
            end
        end
    end

    // Comparator: Drive high while counter is less than active duty cycle -> pin high for number of ticks corresponding to the active_duty value
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pwm_out <= 1'b0;
        end else begin
            pwm_out <= (pwm_counter < active_duty) ? 1'b1 : 1'b0;
        end
    end

    // PWM intentionally uses only the upper five audio bits.
    wire _unused = &{audio_in[4:0], 1'b0};

endmodule

`default_nettype wire
