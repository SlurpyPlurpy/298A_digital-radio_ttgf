// 50 MHz NCO: switch code 0..127 selects 530..1800 kHz.
// Rounded tuning-word table; square-wave output with no sine lookup table.
// Full-scale +/- amplitude preserves the existing mixer/CIC/PWM scaling.
// Supported parameters: PHASE_WIDTH 8..32, SAMPLE_WIDTH 2..16.
module nco #(parameter PHASE_WIDTH=16, parameter SAMPLE_WIDTH=8) (
input wire clk, input wire rst_n, input wire [6:0] freq_ctrl,
output reg signed [SAMPLE_WIDTH-1:0] sample, output reg sample_valid);
reg [PHASE_WIDTH-1:0] phase;
reg [PHASE_WIDTH-1:0] phase_increment;
wire [PHASE_WIDTH-1:0] next_phase = phase + phase_increment;
localparam signed [SAMPLE_WIDTH-1:0] AMPLITUDE = {1'b0, {(SAMPLE_WIDTH-1){1'b1}}};
// Constants are evaluated at elaboration; no runtime divider.
always @* begin
case (freq_ctrl)
7'd0: phase_increment = ((64'd530000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd1: phase_increment = ((64'd540000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd2: phase_increment = ((64'd550000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd3: phase_increment = ((64'd560000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd4: phase_increment = ((64'd570000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd5: phase_increment = ((64'd580000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd6: phase_increment = ((64'd590000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd7: phase_increment = ((64'd600000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd8: phase_increment = ((64'd610000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd9: phase_increment = ((64'd620000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd10: phase_increment = ((64'd630000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd11: phase_increment = ((64'd640000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd12: phase_increment = ((64'd650000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd13: phase_increment = ((64'd660000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd14: phase_increment = ((64'd670000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd15: phase_increment = ((64'd680000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd16: phase_increment = ((64'd690000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd17: phase_increment = ((64'd700000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd18: phase_increment = ((64'd710000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd19: phase_increment = ((64'd720000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd20: phase_increment = ((64'd730000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd21: phase_increment = ((64'd740000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd22: phase_increment = ((64'd750000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd23: phase_increment = ((64'd760000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd24: phase_increment = ((64'd770000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd25: phase_increment = ((64'd780000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd26: phase_increment = ((64'd790000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd27: phase_increment = ((64'd800000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd28: phase_increment = ((64'd810000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd29: phase_increment = ((64'd820000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd30: phase_increment = ((64'd830000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd31: phase_increment = ((64'd840000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd32: phase_increment = ((64'd850000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd33: phase_increment = ((64'd860000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd34: phase_increment = ((64'd870000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd35: phase_increment = ((64'd880000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd36: phase_increment = ((64'd890000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd37: phase_increment = ((64'd900000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd38: phase_increment = ((64'd910000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd39: phase_increment = ((64'd920000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd40: phase_increment = ((64'd930000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd41: phase_increment = ((64'd940000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd42: phase_increment = ((64'd950000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd43: phase_increment = ((64'd960000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd44: phase_increment = ((64'd970000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd45: phase_increment = ((64'd980000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd46: phase_increment = ((64'd990000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd47: phase_increment = ((64'd1000000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd48: phase_increment = ((64'd1010000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd49: phase_increment = ((64'd1020000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd50: phase_increment = ((64'd1030000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd51: phase_increment = ((64'd1040000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd52: phase_increment = ((64'd1050000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd53: phase_increment = ((64'd1060000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd54: phase_increment = ((64'd1070000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd55: phase_increment = ((64'd1080000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd56: phase_increment = ((64'd1090000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd57: phase_increment = ((64'd1100000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd58: phase_increment = ((64'd1110000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd59: phase_increment = ((64'd1120000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd60: phase_increment = ((64'd1130000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd61: phase_increment = ((64'd1140000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd62: phase_increment = ((64'd1150000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd63: phase_increment = ((64'd1160000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd64: phase_increment = ((64'd1170000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd65: phase_increment = ((64'd1180000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd66: phase_increment = ((64'd1190000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd67: phase_increment = ((64'd1200000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd68: phase_increment = ((64'd1210000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd69: phase_increment = ((64'd1220000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd70: phase_increment = ((64'd1230000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd71: phase_increment = ((64'd1240000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd72: phase_increment = ((64'd1250000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd73: phase_increment = ((64'd1260000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd74: phase_increment = ((64'd1270000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd75: phase_increment = ((64'd1280000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd76: phase_increment = ((64'd1290000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd77: phase_increment = ((64'd1300000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd78: phase_increment = ((64'd1310000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd79: phase_increment = ((64'd1320000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd80: phase_increment = ((64'd1330000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd81: phase_increment = ((64'd1340000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd82: phase_increment = ((64'd1350000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd83: phase_increment = ((64'd1360000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd84: phase_increment = ((64'd1370000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd85: phase_increment = ((64'd1380000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd86: phase_increment = ((64'd1390000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd87: phase_increment = ((64'd1400000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd88: phase_increment = ((64'd1410000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd89: phase_increment = ((64'd1420000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd90: phase_increment = ((64'd1430000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd91: phase_increment = ((64'd1440000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd92: phase_increment = ((64'd1450000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd93: phase_increment = ((64'd1460000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd94: phase_increment = ((64'd1470000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd95: phase_increment = ((64'd1480000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd96: phase_increment = ((64'd1490000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd97: phase_increment = ((64'd1500000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd98: phase_increment = ((64'd1510000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd99: phase_increment = ((64'd1520000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd100: phase_increment = ((64'd1530000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd101: phase_increment = ((64'd1540000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd102: phase_increment = ((64'd1550000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd103: phase_increment = ((64'd1560000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd104: phase_increment = ((64'd1570000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd105: phase_increment = ((64'd1580000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd106: phase_increment = ((64'd1590000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd107: phase_increment = ((64'd1600000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd108: phase_increment = ((64'd1610000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd109: phase_increment = ((64'd1620000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd110: phase_increment = ((64'd1630000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd111: phase_increment = ((64'd1640000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd112: phase_increment = ((64'd1650000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd113: phase_increment = ((64'd1660000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd114: phase_increment = ((64'd1670000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd115: phase_increment = ((64'd1680000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd116: phase_increment = ((64'd1690000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd117: phase_increment = ((64'd1700000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd118: phase_increment = ((64'd1710000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd119: phase_increment = ((64'd1720000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd120: phase_increment = ((64'd1730000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd121: phase_increment = ((64'd1740000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd122: phase_increment = ((64'd1750000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd123: phase_increment = ((64'd1760000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd124: phase_increment = ((64'd1770000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd125: phase_increment = ((64'd1780000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd126: phase_increment = ((64'd1790000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
7'd127: phase_increment = ((64'd1800000 << PHASE_WIDTH) + 64'd25000000) / 64'd50000000;
default: phase_increment = 0;
endcase
end
always @(posedge clk or negedge rst_n) begin
if (!rst_n) begin phase <= 0; sample <= 0; sample_valid <= 0; end
else begin phase <= next_phase; sample <= next_phase[PHASE_WIDTH-1] ? -AMPLITUDE : AMPLITUDE; sample_valid <= 1; end
end
endmodule
