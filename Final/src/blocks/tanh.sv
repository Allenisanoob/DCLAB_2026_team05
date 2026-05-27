// `timescale 1ns/1ps

module tanh (
    input  logic signed [15:0] i_data,   // 原始音訊 Q1.15 signed
    input  logic        [7:0]  i_gain,   // 放大倍率 Q2.6 unsigned
    output logic signed [15:0] o_data    // tanh 結果 Q1.15 signed
);

    // i_data: Q1.15
    // i_gain: Q2.6
    // product: Q3.21
    logic signed [24:0] mult_q3_21;
    logic        [24:0] abs_mult;

    // 128-sample LUT over 0 ~ 4, spacing = 1/32 = 2^16 in Q3.21.
    // lut_idx selects the left endpoint:
    //   idx = floor(abs(x) / (1/32))
    // frac_q0_16 is the normalized distance inside this interval:
    //   frac = abs(x) - idx * (1/32), represented as Q0.16.
    logic        [6:0]  lut_idx;
    logic        [15:0] frac_q0_16;

    logic signed [15:0] lut_base;      // tanh(idx/32), Q1.15
    logic signed [15:0] slope_delta;   // LUT[idx+1] - LUT[idx], Q1.15 per interval
    logic signed [31:0] interp_prod;
    logic signed [16:0] tanh_interp;
    logic signed [15:0] tanh_pos;

    always_comb begin
        mult_q3_21 = $signed(i_data) * $signed({1'b0, i_gain});

        if (mult_q3_21 < 0)
            abs_mult = -mult_q3_21;
        else
            abs_mult = mult_q3_21;

        // Clamp x >= 4.0 to tanh(4.0) ~= 32746 in Q1.15.
        if (abs_mult >= 25'd8388608) begin
            lut_idx     = 7'd127;
            frac_q0_16 = 16'd0;
        end
        else begin
            lut_idx     = abs_mult[22:16];
            frac_q0_16 = abs_mult[15:0];
        end

        case (lut_idx)
            7'd0  : lut_base = 16'sd0;
            7'd1  : lut_base = 16'sd1024;
            7'd2  : lut_base = 16'sd2045;
            7'd3  : lut_base = 16'sd3063;
            7'd4  : lut_base = 16'sd4075;
            7'd5  : lut_base = 16'sd5079;
            7'd6  : lut_base = 16'sd6073;
            7'd7  : lut_base = 16'sd7056;
            7'd8  : lut_base = 16'sd8025;
            7'd9  : lut_base = 16'sd8980;
            7'd10 : lut_base = 16'sd9919;
            7'd11 : lut_base = 16'sd10840;
            7'd12 : lut_base = 16'sd11743;
            7'd13 : lut_base = 16'sd12625;
            7'd14 : lut_base = 16'sd13486;
            7'd15 : lut_base = 16'sd14326;
            7'd16 : lut_base = 16'sd15143;
            7'd17 : lut_base = 16'sd15936;
            7'd18 : lut_base = 16'sd16706;
            7'd19 : lut_base = 16'sd17452;
            7'd20 : lut_base = 16'sd18173;
            7'd21 : lut_base = 16'sd18870;
            7'd22 : lut_base = 16'sd19542;
            7'd23 : lut_base = 16'sd20189;
            7'd24 : lut_base = 16'sd20813;
            7'd25 : lut_base = 16'sd21411;
            7'd26 : lut_base = 16'sd21986;
            7'd27 : lut_base = 16'sd22538;
            7'd28 : lut_base = 16'sd23066;
            7'd29 : lut_base = 16'sd23571;
            7'd30 : lut_base = 16'sd24054;
            7'd31 : lut_base = 16'sd24516;
            7'd32 : lut_base = 16'sd24956;
            7'd33 : lut_base = 16'sd25376;
            7'd34 : lut_base = 16'sd25776;
            7'd35 : lut_base = 16'sd26157;
            7'd36 : lut_base = 16'sd26519;
            7'd37 : lut_base = 16'sd26864;
            7'd38 : lut_base = 16'sd27191;
            7'd39 : lut_base = 16'sd27502;
            7'd40 : lut_base = 16'sd27797;
            7'd41 : lut_base = 16'sd28076;
            7'd42 : lut_base = 16'sd28341;
            7'd43 : lut_base = 16'sd28592;
            7'd44 : lut_base = 16'sd28830;
            7'd45 : lut_base = 16'sd29055;
            7'd46 : lut_base = 16'sd29268;
            7'd47 : lut_base = 16'sd29470;
            7'd48 : lut_base = 16'sd29660;
            7'd49 : lut_base = 16'sd29840;
            7'd50 : lut_base = 16'sd30010;
            7'd51 : lut_base = 16'sd30170;
            7'd52 : lut_base = 16'sd30322;
            7'd53 : lut_base = 16'sd30465;
            7'd54 : lut_base = 16'sd30600;
            7'd55 : lut_base = 16'sd30727;
            7'd56 : lut_base = 16'sd30847;
            7'd57 : lut_base = 16'sd30960;
            7'd58 : lut_base = 16'sd31067;
            7'd59 : lut_base = 16'sd31167;
            7'd60 : lut_base = 16'sd31262;
            7'd61 : lut_base = 16'sd31351;
            7'd62 : lut_base = 16'sd31435;
            7'd63 : lut_base = 16'sd31515;
            7'd64 : lut_base = 16'sd31589;
            7'd65 : lut_base = 16'sd31659;
            7'd66 : lut_base = 16'sd31726;
            7'd67 : lut_base = 16'sd31788;
            7'd68 : lut_base = 16'sd31846;
            7'd69 : lut_base = 16'sd31901;
            7'd70 : lut_base = 16'sd31953;
            7'd71 : lut_base = 16'sd32002;
            7'd72 : lut_base = 16'sd32048;
            7'd73 : lut_base = 16'sd32091;
            7'd74 : lut_base = 16'sd32132;
            7'd75 : lut_base = 16'sd32170;
            7'd76 : lut_base = 16'sd32206;
            7'd77 : lut_base = 16'sd32240;
            7'd78 : lut_base = 16'sd32271;
            7'd79 : lut_base = 16'sd32301;
            7'd80 : lut_base = 16'sd32329;
            7'd81 : lut_base = 16'sd32356;
            7'd82 : lut_base = 16'sd32381;
            7'd83 : lut_base = 16'sd32404;
            7'd84 : lut_base = 16'sd32426;
            7'd85 : lut_base = 16'sd32447;
            7'd86 : lut_base = 16'sd32466;
            7'd87 : lut_base = 16'sd32484;
            7'd88 : lut_base = 16'sd32501;
            7'd89 : lut_base = 16'sd32517;
            7'd90 : lut_base = 16'sd32532;
            7'd91 : lut_base = 16'sd32547;
            7'd92 : lut_base = 16'sd32560;
            7'd93 : lut_base = 16'sd32573;
            7'd94 : lut_base = 16'sd32584;
            7'd95 : lut_base = 16'sd32596;
            7'd96 : lut_base = 16'sd32606;
            7'd97 : lut_base = 16'sd32616;
            7'd98 : lut_base = 16'sd32625;
            7'd99 : lut_base = 16'sd32634;
            7'd100: lut_base = 16'sd32642;
            7'd101: lut_base = 16'sd32649;
            7'd102: lut_base = 16'sd32657;
            7'd103: lut_base = 16'sd32663;
            7'd104: lut_base = 16'sd32670;
            7'd105: lut_base = 16'sd32676;
            7'd106: lut_base = 16'sd32681;
            7'd107: lut_base = 16'sd32686;
            7'd108: lut_base = 16'sd32691;
            7'd109: lut_base = 16'sd32696;
            7'd110: lut_base = 16'sd32700;
            7'd111: lut_base = 16'sd32704;
            7'd112: lut_base = 16'sd32708;
            7'd113: lut_base = 16'sd32712;
            7'd114: lut_base = 16'sd32715;
            7'd115: lut_base = 16'sd32718;
            7'd116: lut_base = 16'sd32721;
            7'd117: lut_base = 16'sd32724;
            7'd118: lut_base = 16'sd32727;
            7'd119: lut_base = 16'sd32729;
            7'd120: lut_base = 16'sd32732;
            7'd121: lut_base = 16'sd32734;
            7'd122: lut_base = 16'sd32736;
            7'd123: lut_base = 16'sd32738;
            7'd124: lut_base = 16'sd32740;
            7'd125: lut_base = 16'sd32741;
            7'd126: lut_base = 16'sd32743;
            7'd127: lut_base = 16'sd32745;
            default: lut_base = 16'sd0;
        endcase

        case (lut_idx)
            7'd0  : slope_delta = 16'sd1024;
            7'd1  : slope_delta = 16'sd1021;
            7'd2  : slope_delta = 16'sd1018;
            7'd3  : slope_delta = 16'sd1012;
            7'd4  : slope_delta = 16'sd1004;
            7'd5  : slope_delta = 16'sd994;
            7'd6  : slope_delta = 16'sd983;
            7'd7  : slope_delta = 16'sd969;
            7'd8  : slope_delta = 16'sd955;
            7'd9  : slope_delta = 16'sd939;
            7'd10 : slope_delta = 16'sd921;
            7'd11 : slope_delta = 16'sd903;
            7'd12 : slope_delta = 16'sd882;
            7'd13 : slope_delta = 16'sd861;
            7'd14 : slope_delta = 16'sd840;
            7'd15 : slope_delta = 16'sd817;
            7'd16 : slope_delta = 16'sd793;
            7'd17 : slope_delta = 16'sd770;
            7'd18 : slope_delta = 16'sd746;
            7'd19 : slope_delta = 16'sd721;
            7'd20 : slope_delta = 16'sd697;
            7'd21 : slope_delta = 16'sd672;
            7'd22 : slope_delta = 16'sd647;
            7'd23 : slope_delta = 16'sd624;
            7'd24 : slope_delta = 16'sd598;
            7'd25 : slope_delta = 16'sd575;
            7'd26 : slope_delta = 16'sd552;
            7'd27 : slope_delta = 16'sd528;
            7'd28 : slope_delta = 16'sd505;
            7'd29 : slope_delta = 16'sd483;
            7'd30 : slope_delta = 16'sd462;
            7'd31 : slope_delta = 16'sd440;
            7'd32 : slope_delta = 16'sd420;
            7'd33 : slope_delta = 16'sd400;
            7'd34 : slope_delta = 16'sd381;
            7'd35 : slope_delta = 16'sd362;
            7'd36 : slope_delta = 16'sd345;
            7'd37 : slope_delta = 16'sd327;
            7'd38 : slope_delta = 16'sd311;
            7'd39 : slope_delta = 16'sd295;
            7'd40 : slope_delta = 16'sd279;
            7'd41 : slope_delta = 16'sd265;
            7'd42 : slope_delta = 16'sd251;
            7'd43 : slope_delta = 16'sd238;
            7'd44 : slope_delta = 16'sd225;
            7'd45 : slope_delta = 16'sd213;
            7'd46 : slope_delta = 16'sd202;
            7'd47 : slope_delta = 16'sd190;
            7'd48 : slope_delta = 16'sd180;
            7'd49 : slope_delta = 16'sd170;
            7'd50 : slope_delta = 16'sd160;
            7'd51 : slope_delta = 16'sd152;
            7'd52 : slope_delta = 16'sd143;
            7'd53 : slope_delta = 16'sd135;
            7'd54 : slope_delta = 16'sd127;
            7'd55 : slope_delta = 16'sd120;
            7'd56 : slope_delta = 16'sd113;
            7'd57 : slope_delta = 16'sd107;
            7'd58 : slope_delta = 16'sd100;
            7'd59 : slope_delta = 16'sd95;
            7'd60 : slope_delta = 16'sd89;
            7'd61 : slope_delta = 16'sd84;
            7'd62 : slope_delta = 16'sd80;
            7'd63 : slope_delta = 16'sd74;
            7'd64 : slope_delta = 16'sd70;
            7'd65 : slope_delta = 16'sd67;
            7'd66 : slope_delta = 16'sd62;
            7'd67 : slope_delta = 16'sd58;
            7'd68 : slope_delta = 16'sd55;
            7'd69 : slope_delta = 16'sd52;
            7'd70 : slope_delta = 16'sd49;
            7'd71 : slope_delta = 16'sd46;
            7'd72 : slope_delta = 16'sd43;
            7'd73 : slope_delta = 16'sd41;
            7'd74 : slope_delta = 16'sd38;
            7'd75 : slope_delta = 16'sd36;
            7'd76 : slope_delta = 16'sd34;
            7'd77 : slope_delta = 16'sd31;
            7'd78 : slope_delta = 16'sd30;
            7'd79 : slope_delta = 16'sd28;
            7'd80 : slope_delta = 16'sd27;
            7'd81 : slope_delta = 16'sd25;
            7'd82 : slope_delta = 16'sd23;
            7'd83 : slope_delta = 16'sd22;
            7'd84 : slope_delta = 16'sd21;
            7'd85 : slope_delta = 16'sd19;
            7'd86 : slope_delta = 16'sd18;
            7'd87 : slope_delta = 16'sd17;
            7'd88 : slope_delta = 16'sd16;
            7'd89 : slope_delta = 16'sd15;
            7'd90 : slope_delta = 16'sd15;
            7'd91 : slope_delta = 16'sd13;
            7'd92 : slope_delta = 16'sd13;
            7'd93 : slope_delta = 16'sd11;
            7'd94 : slope_delta = 16'sd12;
            7'd95 : slope_delta = 16'sd10;
            7'd96 : slope_delta = 16'sd10;
            7'd97 : slope_delta = 16'sd9;
            7'd98 : slope_delta = 16'sd9;
            7'd99 : slope_delta = 16'sd8;
            7'd100: slope_delta = 16'sd7;
            7'd101: slope_delta = 16'sd8;
            7'd102: slope_delta = 16'sd6;
            7'd103: slope_delta = 16'sd7;
            7'd104: slope_delta = 16'sd6;
            7'd105: slope_delta = 16'sd5;
            7'd106: slope_delta = 16'sd5;
            7'd107: slope_delta = 16'sd5;
            7'd108: slope_delta = 16'sd5;
            7'd109: slope_delta = 16'sd4;
            7'd110: slope_delta = 16'sd4;
            7'd111: slope_delta = 16'sd4;
            7'd112: slope_delta = 16'sd4;
            7'd113: slope_delta = 16'sd3;
            7'd114: slope_delta = 16'sd3;
            7'd115: slope_delta = 16'sd3;
            7'd116: slope_delta = 16'sd3;
            7'd117: slope_delta = 16'sd3;
            7'd118: slope_delta = 16'sd2;
            7'd119: slope_delta = 16'sd3;
            7'd120: slope_delta = 16'sd2;
            7'd121: slope_delta = 16'sd2;
            7'd122: slope_delta = 16'sd2;
            7'd123: slope_delta = 16'sd2;
            7'd124: slope_delta = 16'sd1;
            7'd125: slope_delta = 16'sd2;
            7'd126: slope_delta = 16'sd2;
            7'd127: slope_delta = 16'sd1;
            default: slope_delta = 16'sd0;
        endcase
        // Linear interpolation:
        // If x is between LUT[k] and LUT[k+1],
        // y = LUT[k] + frac * (LUT[k+1] - LUT[k])
        // frac_q0_16 is Q0.16, so shift right by 16 after multiply.
        interp_prod  = $signed({1'b0, frac_q0_16}) * slope_delta;
        tanh_interp  = $signed({1'b0, lut_base}) + (interp_prod >>> 16);

        // For x >= 4.0, directly saturate close to tanh(4.0).
        if (abs_mult >= 25'd8388608)
            tanh_pos = 16'sd32746;
        else
            tanh_pos = tanh_interp[15:0];

        if (mult_q3_21 < 0)
            o_data = -tanh_pos;
        else
            o_data = tanh_pos;
    end

endmodule
