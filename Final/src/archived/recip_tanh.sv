//if (i_gain <= 8'd4) begin
//    o_data = i_data;  No information for i_gain <= 8'd4 in this LUT
`timescale 1ns/1ps
module recip_tanh (
    input  logic [7:0]  i_gain,            // Q2.6 unsigned
    output logic [15:0] o_recip_tanh_val     // Q7.9 unsigned
);

    logic [6:0] lut_idx;
    logic       frac_bit;

    logic        [15:0] base_val;          // Q7.9 unsigned
    logic signed [15:0] slope_val;         // Q7.9 integer delta for one input-code step
    logic signed [17:0] interp_val;

    assign lut_idx  = i_gain[7:1];
    assign frac_bit = i_gain[0];

    always_comb begin
        unique case (lut_idx)
            7'd2: base_val = 16'd8203;
            7'd3: base_val = 16'd5477;
            7'd4: base_val = 16'd4117;
            7'd5: base_val = 16'd3303;
            7'd6: base_val = 16'd2763;
            7'd7: base_val = 16'd2378;
            7'd8: base_val = 16'd2090;
            7'd9: base_val = 16'd1868;
            7'd10: base_val = 16'd1691;
            7'd11: base_val = 16'd1548;
            7'd12: base_val = 16'd1429;
            7'd13: base_val = 16'd1329;
            7'd14: base_val = 16'd1244;
            7'd15: base_val = 16'd1171;
            7'd16: base_val = 16'd1108;
            7'd17: base_val = 16'd1053;
            7'd18: base_val = 16'd1004;
            7'd19: base_val = 16'd961;
            7'd20: base_val = 16'd923;
            7'd21: base_val = 16'd889;
            7'd22: base_val = 16'd859;
            7'd23: base_val = 16'd831;
            7'd24: base_val = 16'd806;
            7'd25: base_val = 16'd784;
            7'd26: base_val = 16'd763;
            7'd27: base_val = 16'd744;
            7'd28: base_val = 16'd727;
            7'd29: base_val = 16'd712;
            7'd30: base_val = 16'd697;
            7'd31: base_val = 16'd684;
            7'd32: base_val = 16'd672;
            7'd33: base_val = 16'd661;
            7'd34: base_val = 16'd651;
            7'd35: base_val = 16'd641;
            7'd36: base_val = 16'd633;
            7'd37: base_val = 16'd625;
            7'd38: base_val = 16'd617;
            7'd39: base_val = 16'd610;
            7'd40: base_val = 16'd604;
            7'd41: base_val = 16'd598;
            7'd42: base_val = 16'd592;
            7'd43: base_val = 16'd587;
            7'd44: base_val = 16'd582;
            7'd45: base_val = 16'd577;
            7'd46: base_val = 16'd573;
            7'd47: base_val = 16'd569;
            7'd48: base_val = 16'd566;
            7'd49: base_val = 16'd562;
            7'd50: base_val = 16'd559;
            7'd51: base_val = 16'd556;
            7'd52: base_val = 16'd553;
            7'd53: base_val = 16'd551;
            7'd54: base_val = 16'd548;
            7'd55: base_val = 16'd546;
            7'd56: base_val = 16'd544;
            7'd57: base_val = 16'd542;
            7'd58: base_val = 16'd540;
            7'd59: base_val = 16'd538;
            7'd60: base_val = 16'd537;
            7'd61: base_val = 16'd535;
            7'd62: base_val = 16'd534;
            7'd63: base_val = 16'd532;
            7'd64: base_val = 16'd531;
            7'd65: base_val = 16'd530;
            7'd66: base_val = 16'd529;
            7'd67: base_val = 16'd528;
            7'd68: base_val = 16'd527;
            7'd69: base_val = 16'd526;
            7'd70: base_val = 16'd525;
            7'd71: base_val = 16'd524;
            7'd72: base_val = 16'd524;
            7'd73: base_val = 16'd523;
            7'd74: base_val = 16'd522;
            7'd75: base_val = 16'd522;
            7'd76: base_val = 16'd521;
            7'd77: base_val = 16'd520;
            7'd78: base_val = 16'd520;
            7'd79: base_val = 16'd519;
            7'd80: base_val = 16'd519;
            7'd81: base_val = 16'd519;
            7'd82: base_val = 16'd518;
            7'd83: base_val = 16'd518;
            7'd84: base_val = 16'd517;
            7'd85: base_val = 16'd517;
            7'd86: base_val = 16'd517;
            7'd87: base_val = 16'd516;
            7'd88: base_val = 16'd516;
            7'd89: base_val = 16'd516;
            7'd90: base_val = 16'd516;
            7'd91: base_val = 16'd515;
            7'd92: base_val = 16'd515;
            7'd93: base_val = 16'd515;
            7'd94: base_val = 16'd515;
            7'd95: base_val = 16'd515;
            7'd96: base_val = 16'd515;
            7'd97: base_val = 16'd514;
            7'd98: base_val = 16'd514;
            7'd99: base_val = 16'd514;
            7'd100: base_val = 16'd514;
            7'd101: base_val = 16'd514;
            7'd102: base_val = 16'd514;
            7'd103: base_val = 16'd514;
            7'd104: base_val = 16'd514;
            7'd105: base_val = 16'd513;
            7'd106: base_val = 16'd513;
            7'd107: base_val = 16'd513;
            7'd108: base_val = 16'd513;
            7'd109: base_val = 16'd513;
            7'd110: base_val = 16'd513;
            7'd111: base_val = 16'd513;
            7'd112: base_val = 16'd513;
            7'd113: base_val = 16'd513;
            7'd114: base_val = 16'd513;
            7'd115: base_val = 16'd513;
            7'd116: base_val = 16'd513;
            7'd117: base_val = 16'd513;
            7'd118: base_val = 16'd513;
            7'd119: base_val = 16'd513;
            7'd120: base_val = 16'd513;
            7'd121: base_val = 16'd513;
            7'd122: base_val = 16'd513;
            7'd123: base_val = 16'd512;
            7'd124: base_val = 16'd512;
            7'd125: base_val = 16'd512;
            7'd126: base_val = 16'd512;
            7'd127: base_val = 16'd512;
            default: base_val = 16'd0;
        endcase
    end

    always_comb begin
        unique case (lut_idx)
            7'd2: slope_val = -16'sd1636;
            7'd3: slope_val = -16'sd777;
            7'd4: slope_val = -16'sd452;
            7'd5: slope_val = -16'sd295;
            7'd6: slope_val = -16'sd208;
            7'd7: slope_val = -16'sd154;
            7'd8: slope_val = -16'sd117;
            7'd9: slope_val = -16'sd93;
            7'd10: slope_val = -16'sd75;
            7'd11: slope_val = -16'sd62;
            7'd12: slope_val = -16'sd52;
            7'd13: slope_val = -16'sd44;
            7'd14: slope_val = -16'sd38;
            7'd15: slope_val = -16'sd33;
            7'd16: slope_val = -16'sd29;
            7'd17: slope_val = -16'sd25;
            7'd18: slope_val = -16'sd22;
            7'd19: slope_val = -16'sd19;
            7'd20: slope_val = -16'sd17;
            7'd21: slope_val = -16'sd16;
            7'd22: slope_val = -16'sd15;
            7'd23: slope_val = -16'sd13;
            7'd24: slope_val = -16'sd11;
            7'd25: slope_val = -16'sd11;
            7'd26: slope_val = -16'sd9;
            7'd27: slope_val = -16'sd8;
            7'd28: slope_val = -16'sd8;
            7'd29: slope_val = -16'sd8;
            7'd30: slope_val = -16'sd6;
            7'd31: slope_val = -16'sd6;
            7'd32: slope_val = -16'sd5;
            7'd33: slope_val = -16'sd5;
            7'd34: slope_val = -16'sd5;
            7'd35: slope_val = -16'sd4;
            7'd36: slope_val = -16'sd4;
            7'd37: slope_val = -16'sd4;
            7'd38: slope_val = -16'sd4;
            7'd39: slope_val = -16'sd3;
            7'd40: slope_val = -16'sd3;
            7'd41: slope_val = -16'sd3;
            7'd42: slope_val = -16'sd3;
            7'd43: slope_val = -16'sd3;
            7'd44: slope_val = -16'sd2;
            7'd45: slope_val = -16'sd2;
            7'd46: slope_val = -16'sd2;
            7'd47: slope_val = -16'sd2;
            7'd48: slope_val = -16'sd2;
            7'd49: slope_val = -16'sd1;
            7'd50: slope_val = -16'sd1;
            7'd51: slope_val = -16'sd1;
            7'd52: slope_val = -16'sd1;
            7'd53: slope_val = -16'sd2;
            7'd54: slope_val = -16'sd1;
            7'd55: slope_val = -16'sd1;
            7'd56: slope_val = -16'sd1;
            7'd57: slope_val = -16'sd1;
            7'd58: slope_val = -16'sd1;
            7'd59: slope_val = -16'sd1;
            7'd60: slope_val = -16'sd1;
            7'd61: slope_val = -16'sd1;
            7'd62: slope_val = -16'sd1;
            7'd63: slope_val = 16'sd0;
            7'd64: slope_val = 16'sd0;
            7'd65: slope_val = -16'sd1;
            7'd66: slope_val = -16'sd1;
            7'd67: slope_val = -16'sd1;
            7'd68: slope_val = -16'sd1;
            7'd69: slope_val = -16'sd1;
            7'd70: slope_val = 16'sd0;
            7'd71: slope_val = 16'sd0;
            7'd72: slope_val = -16'sd1;
            7'd73: slope_val = -16'sd1;
            7'd74: slope_val = 16'sd0;
            7'd75: slope_val = -16'sd1;
            7'd76: slope_val = 16'sd0;
            7'd77: slope_val = 16'sd0;
            7'd78: slope_val = 16'sd0;
            7'd79: slope_val = 16'sd0;
            7'd80: slope_val = 16'sd0;
            7'd81: slope_val = -16'sd1;
            7'd82: slope_val = 16'sd0;
            7'd83: slope_val = 16'sd0;
            7'd84: slope_val = 16'sd0;
            7'd85: slope_val = 16'sd0;
            7'd86: slope_val = 16'sd0;
            7'd87: slope_val = 16'sd0;
            7'd88: slope_val = 16'sd0;
            7'd89: slope_val = 16'sd0;
            7'd90: slope_val = 16'sd0;
            7'd91: slope_val = 16'sd0;
            7'd92: slope_val = 16'sd0;
            7'd93: slope_val = 16'sd0;
            7'd94: slope_val = 16'sd0;
            7'd95: slope_val = 16'sd0;
            7'd96: slope_val = -16'sd1;
            7'd97: slope_val = 16'sd0;
            7'd98: slope_val = 16'sd0;
            7'd99: slope_val = 16'sd0;
            7'd100: slope_val = 16'sd0;
            7'd101: slope_val = 16'sd0;
            7'd102: slope_val = 16'sd0;
            7'd103: slope_val = 16'sd0;
            7'd104: slope_val = -16'sd1;
            7'd105: slope_val = 16'sd0;
            7'd106: slope_val = 16'sd0;
            7'd107: slope_val = 16'sd0;
            7'd108: slope_val = 16'sd0;
            7'd109: slope_val = 16'sd0;
            7'd110: slope_val = 16'sd0;
            7'd111: slope_val = 16'sd0;
            7'd112: slope_val = 16'sd0;
            7'd113: slope_val = 16'sd0;
            7'd114: slope_val = 16'sd0;
            7'd115: slope_val = 16'sd0;
            7'd116: slope_val = 16'sd0;
            7'd117: slope_val = 16'sd0;
            7'd118: slope_val = 16'sd0;
            7'd119: slope_val = 16'sd0;
            7'd120: slope_val = 16'sd0;
            7'd121: slope_val = 16'sd0;
            7'd122: slope_val = -16'sd1;
            7'd123: slope_val = 16'sd0;
            7'd124: slope_val = 16'sd0;
            7'd125: slope_val = 16'sd0;
            7'd126: slope_val = 16'sd0;
            7'd127: slope_val = 16'sd0;
            default: slope_val = 16'sd0;
        endcase
    end

    always_comb begin
        interp_val      = 18'sd0;
        o_recip_tanh_val = 16'd0;

        if (i_gain <= 8'd4) begin
            // Dummy output. The caller should bypass for this gain range.
            o_recip_tanh_val = 16'd0;
        end else begin
            interp_val = $signed({1'b0, base_val})
                       + (frac_bit ? $signed(slope_val) : 18'sd0);

            if (interp_val < 18'sd0) begin
                o_recip_tanh_val = 16'd0;
            end else if (interp_val > 18'sd65535) begin
                o_recip_tanh_val = 16'hFFFF;
            end else begin
                o_recip_tanh_val = interp_val[15:0];
            end
        end
    end

endmodule
// recip_tanh_lut_128_pruned.sv
// Standalone pruned 1/tanh(gain) LUT.
// Input : i_gain is unsigned Q2.6, gain = i_gain / 64.
// Output: o_recip_tanh_val is unsigned Q7.9, value ~= 1/tanh(gain).
//
// Assumption:
//   The caller bypasses the effect when i_gain <= 8'd4, so this LUT returns
//   dummy 0 for i_gain <= 8'd4. Valid numerical output starts at i_gain = 5.
//
// Mapping:
//   lut_idx  = i_gain[7:1]
//   frac_bit = i_gain[0]
//   base[k]  = round((1/tanh((2*k)/64)) * 512)
//   slope[k] = value(2*k+1) - value(2*k), exact one-code delta in Q7.9 LSB.
//
// Important:
//   lut_idx = 2 is kept because i_gain = 5 maps to lut_idx = 2, frac_bit = 1.