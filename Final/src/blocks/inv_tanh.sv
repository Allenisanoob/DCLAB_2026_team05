module inv_tanh (
    input  logic [7:0]  i_gain,          // 放大倍率 Q2.6
    output logic [15:0] o_inv_tanh_val   // 1/tanh(gain) 的值 Q7.9
);

    logic [5:0] gain_idx;

    always_comb begin
        gain_idx = i_gain[7:2];
        case (gain_idx)
            6'd 0: o_inv_tanh_val = 16'd16389; 6'd 1: o_inv_tanh_val = 16'd5477;
            6'd 2: o_inv_tanh_val = 16'd3303;  6'd 3: o_inv_tanh_val = 16'd2378;
            6'd 4: o_inv_tanh_val = 16'd1868;  6'd 5: o_inv_tanh_val = 16'd1548;
            6'd 6: o_inv_tanh_val = 16'd1329;  6'd 7: o_inv_tanh_val = 16'd1171;
            6'd 8: o_inv_tanh_val = 16'd1053;  6'd 9: o_inv_tanh_val = 16'd961;
            6'd10: o_inv_tanh_val = 16'd889;   6'd11: o_inv_tanh_val = 16'd831;
            6'd12: o_inv_tanh_val = 16'd784;   6'd13: o_inv_tanh_val = 16'd744;
            6'd14: o_inv_tanh_val = 16'd712;   6'd15: o_inv_tanh_val = 16'd684;
            6'd16: o_inv_tanh_val = 16'd661;   6'd17: o_inv_tanh_val = 16'd641;
            6'd18: o_inv_tanh_val = 16'd625;   6'd19: o_inv_tanh_val = 16'd610;
            6'd20: o_inv_tanh_val = 16'd598;   6'd21: o_inv_tanh_val = 16'd587;
            6'd22: o_inv_tanh_val = 16'd577;   6'd23: o_inv_tanh_val = 16'd569;
            6'd24: o_inv_tanh_val = 16'd562;   6'd25: o_inv_tanh_val = 16'd556;
            6'd26: o_inv_tanh_val = 16'd551;   6'd27: o_inv_tanh_val = 16'd546;
            6'd28: o_inv_tanh_val = 16'd542;   6'd29: o_inv_tanh_val = 16'd538;
            6'd30: o_inv_tanh_val = 16'd535;   6'd31: o_inv_tanh_val = 16'd532;
            6'd32: o_inv_tanh_val = 16'd530;   6'd33: o_inv_tanh_val = 16'd528;
            6'd34: o_inv_tanh_val = 16'd526;   6'd35: o_inv_tanh_val = 16'd524;
            6'd36: o_inv_tanh_val = 16'd523;   6'd37: o_inv_tanh_val = 16'd522;
            6'd38: o_inv_tanh_val = 16'd520;   6'd39: o_inv_tanh_val = 16'd519;
            6'd40: o_inv_tanh_val = 16'd519;   6'd41: o_inv_tanh_val = 16'd518;
            6'd42: o_inv_tanh_val = 16'd517;   6'd43: o_inv_tanh_val = 16'd516;
            6'd44: o_inv_tanh_val = 16'd516;   6'd45: o_inv_tanh_val = 16'd515;
            6'd46: o_inv_tanh_val = 16'd515;   6'd47: o_inv_tanh_val = 16'd515;
            6'd48: o_inv_tanh_val = 16'd514;   6'd49: o_inv_tanh_val = 16'd514;
            6'd50: o_inv_tanh_val = 16'd514;   6'd51: o_inv_tanh_val = 16'd514;
            6'd52: o_inv_tanh_val = 16'd513;   6'd53: o_inv_tanh_val = 16'd513;
            6'd54: o_inv_tanh_val = 16'd513;   6'd55: o_inv_tanh_val = 16'd513;
            6'd56: o_inv_tanh_val = 16'd513;   6'd57: o_inv_tanh_val = 16'd513;
            6'd58: o_inv_tanh_val = 16'd513;   6'd59: o_inv_tanh_val = 16'd513;
            6'd60: o_inv_tanh_val = 16'd513;   6'd61: o_inv_tanh_val = 16'd512;
            6'd62: o_inv_tanh_val = 16'd512;   6'd63: o_inv_tanh_val = 16'd512;
            default: o_inv_tanh_val = 16'd512;
        endcase
    end
endmodule