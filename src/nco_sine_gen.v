`default_nettype none

module nco_sine_gen (
    input  wire               clk,
    input  wire               rst_n,
    input  wire [7:0]         tuning_word,  // Controls the frequency step size
    output reg signed [7:0]   sine_reference
);

    // 8-bit Phase Accumulator
    reg [7:0] phase_acc;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            phase_acc <= 8'd0;
        end else begin
            phase_acc <= phase_acc + tuning_word;
        end
    end

    // Use the top 6 bits of the accumulator as the 64-entry ROM address (0 to 63)
    wire [5:0] lut_addr = phase_acc[7:2];

    reg signed [7:0] sine_wave_rom;
    
  // Complete 64-entry Sine ROM (for now, can update if needed and there is space)
    always @(*) begin
        case (lut_addr)
            6'd0:  sine_wave_rom = 8'sd0;
            6'd1:  sine_wave_rom = 8'sd12;
            6'd2:  sine_wave_rom = 8'sd25;
            6'd3:  sine_wave_rom = 8'sd37;
            6'd4:  sine_wave_rom = 8'sd49;
            6'd5:  sine_wave_rom = 8'sd60;
            6'd6:  sine_wave_rom = 8'sd71;
            6'd7:  sine_wave_rom = 8'sd81;
            6'd8:  sine_wave_rom = 8'sd90;
            6'd9:  sine_wave_rom = 8'sd98;
            6'd10: sine_wave_rom = 8'sd103;
            6'd11: sine_wave_rom = 8'sd109;
            6'd12: sine_wave_rom = 8'sd113;
            6'd13: sine_wave_rom = 8'sd117;
            6'd14: sine_wave_rom = 8'sd120;
            6'd15: sine_wave_rom = 8'sd123;
            6'd16: sine_wave_rom = 8'sd124; 
            6'd17: sine_wave_rom = 8'sd123;
            6'd18: sine_wave_rom = 8'sd120;
            6'd19: sine_wave_rom = 8'sd117;
            6'd20: sine_wave_rom = 8'sd113;
            6'd21: sine_wave_rom = 8'sd109;
            6'd22: sine_wave_rom = 8'sd103;
            6'd23: sine_wave_rom = 8'sd98;
            6'd24: sine_wave_rom = 8'sd90;
            6'd25: sine_wave_rom = 8'sd81;
            6'd26: sine_wave_rom = 8'sd71;
            6'd27: sine_wave_rom = 8'sd60;
            6'd28: sine_wave_rom = 8'sd49;
            6'd29: sine_wave_rom = 8'sd37;
            6'd30: sine_wave_rom = 8'sd25;
            6'd31: sine_wave_rom = 8'sd12;
            6'd32: sine_wave_rom = 8'sd0;   
            6'd33: sine_wave_rom = -8'sd12;
            6'd34: sine_wave_rom = -8'sd25;
            6'd35: sine_wave_rom = -8'sd37;
            6'd36: sine_wave_rom = -8'sd49;
            6'd37: sine_wave_rom = -8'sd60;
            6'd38: sine_wave_rom = -8'sd71;
            6'd39: sine_wave_rom = -8'sd81;
            6'd40: sine_wave_rom = -8'sd90;
            6'd41: sine_wave_rom = -8'sd98;
            6'd42: sine_wave_rom = -8'sd103;
            6'd43: sine_wave_rom = -8'sd109;
            6'd44: sine_wave_rom = -8'sd113;
            6'd45: sine_wave_rom = -8'sd117;
            6'd46: sine_wave_rom = -8'sd120;
            6'd47: sine_wave_rom = -8'sd123;
            6'd48: sine_wave_rom = -8'sd124; 
            6'd49: sine_wave_rom = -8'sd123;
            6'd50: sine_wave_rom = -8'sd120;
            6'd51: sine_wave_rom = -8'sd117;
            6'd52: sine_wave_rom = -8'sd113;
            6'd53: sine_wave_rom = -8'sd109;
            6'd54: sine_wave_rom = -8'sd103;
            6'd55: sine_wave_rom = -8'sd98;
            6'd56: sine_wave_rom = -8'sd90;
            6'd57: sine_wave_rom = -8'sd81;
            6'd58: sine_wave_rom = -8'sd71;
            6'd59: sine_wave_rom = -8'sd60;
            6'd60: sine_wave_rom = -8'sd49;
            6'd61: sine_wave_rom = -8'sd37;
            6'd62: sine_wave_rom = -8'sd25;
            6'd63: sine_wave_rom = -8'sd12;
            default: sine_wave_rom = 8'sd0;
        endcase
    end

    reg signed [7:0] sine_wave_rom;
    always @(*) begin
        sine_reference = sine_wave_rom;
    end

endmodule

`default_nettype wire
