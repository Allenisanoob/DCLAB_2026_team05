module tanh (
    input  logic signed [15:0] i_data,   // 原始音訊 Q1.15 (Signed)
    input  logic        [7:0]  i_gain,   // 放大倍率 Q2.6 (Unsigned)
    output logic signed [15:0] o_data    // 未正規化的 tanh 結果 Q1.15 (Signed)
);

    logic signed [23:0] z_full;
    logic               z_sign;
    logic signed [23:0] z_trans;
    logic        [22:0] z_abs;
    logic        [5:0]  seg_z;
    logic        [15:0] frac_z;
    
    logic        [15:0] base_LUT;
    logic        [15:0] slope_LUT;
    logic        [31:0] diff;
    logic        [32:0] y_abs_full;
    logic        [15:0] y_abs;

    always_comb begin
        // 1. 乘法運算: 有號數 * 無號數
        z_full = i_data * $signed({1'b0, i_gain});

        // 2. 提取符號與絕對值
        z_sign  = z_full[23];
        z_trans = z_sign ? -z_full : z_full;
        z_abs   = z_trans[22:0]; 

        // 3. 定義分段索引與比例
        seg_z  = z_abs[21:16];
        frac_z = z_abs[15:0];

        // 4 & 5. 查表計算 y = base + (slope * frac)
        if (z_abs >= 24'h400000) begin
            base_LUT  = 16'd31589;
            slope_LUT = 16'h0000;
        end else begin
            case (seg_z)
                6'd 0 : begin base_LUT = 16'd    0; slope_LUT = 16'd 1023; end 
                6'd 1 : begin base_LUT = 16'd 1023; slope_LUT = 16'd 1022; end 
                6'd 2 : begin base_LUT = 16'd 2045; slope_LUT = 16'd 1017; end 
                6'd 3 : begin base_LUT = 16'd 3062; slope_LUT = 16'd 1012; end 
                6'd 4 : begin base_LUT = 16'd 4074; slope_LUT = 16'd 1004; end 
                6'd 5 : begin base_LUT = 16'd 5078; slope_LUT = 16'd  994; end 
                6'd 6 : begin base_LUT = 16'd 6072; slope_LUT = 16'd  983; end 
                6'd 7 : begin base_LUT = 16'd 7055; slope_LUT = 16'd  970; end 
                6'd 8 : begin base_LUT = 16'd 8025; slope_LUT = 16'd  955; end 
                6'd 9 : begin base_LUT = 16'd 8980; slope_LUT = 16'd  938; end 
                6'd10 : begin base_LUT = 16'd 9918; slope_LUT = 16'd  922; end 
                6'd11 : begin base_LUT = 16'd10840; slope_LUT = 16'd  902; end 
                6'd12 : begin base_LUT = 16'd11742; slope_LUT = 16'd  882; end 
                6'd13 : begin base_LUT = 16'd12624; slope_LUT = 16'd  861; end 
                6'd14 : begin base_LUT = 16'd13485; slope_LUT = 16'd  840; end 
                6'd15 : begin base_LUT = 16'd14325; slope_LUT = 16'd  817; end 
                6'd16 : begin base_LUT = 16'd15142; slope_LUT = 16'd  793; end 
                6'd17 : begin base_LUT = 16'd15935; slope_LUT = 16'd  770; end 
                6'd18 : begin base_LUT = 16'd16705; slope_LUT = 16'd  746; end 
                6'd19 : begin base_LUT = 16'd17451; slope_LUT = 16'd  721; end 
                6'd20 : begin base_LUT = 16'd18172; slope_LUT = 16'd  697; end 
                6'd21 : begin base_LUT = 16'd18869; slope_LUT = 16'd  672; end 
                6'd22 : begin base_LUT = 16'd19541; slope_LUT = 16'd  647; end 
                6'd23 : begin base_LUT = 16'd20188; slope_LUT = 16'd  623; end 
                6'd24 : begin base_LUT = 16'd20811; slope_LUT = 16'd  599; end 
                6'd25 : begin base_LUT = 16'd21410; slope_LUT = 16'd  575; end 
                6'd26 : begin base_LUT = 16'd21985; slope_LUT = 16'd  551; end 
                6'd27 : begin base_LUT = 16'd22536; slope_LUT = 16'd  528; end 
                6'd28 : begin base_LUT = 16'd23064; slope_LUT = 16'd  506; end 
                6'd29 : begin base_LUT = 16'd23570; slope_LUT = 16'd  483; end 
                6'd30 : begin base_LUT = 16'd24053; slope_LUT = 16'd  461; end 
                6'd31 : begin base_LUT = 16'd24514; slope_LUT = 16'd  441; end 
                6'd32 : begin base_LUT = 16'd24955; slope_LUT = 16'd  420; end 
                6'd33 : begin base_LUT = 16'd25375; slope_LUT = 16'd  400; end 
                6'd34 : begin base_LUT = 16'd25775; slope_LUT = 16'd  381; end 
                6'd35 : begin base_LUT = 16'd26156; slope_LUT = 16'd  362; end 
                6'd36 : begin base_LUT = 16'd26518; slope_LUT = 16'd  344; end 
                6'd37 : begin base_LUT = 16'd26862; slope_LUT = 16'd  328; end 
                6'd38 : begin base_LUT = 16'd27190; slope_LUT = 16'd  310; end 
                6'd39 : begin base_LUT = 16'd27500; slope_LUT = 16'd  295; end 
                6'd40 : begin base_LUT = 16'd27795; slope_LUT = 16'd  280; end 
                6'd41 : begin base_LUT = 16'd28075; slope_LUT = 16'd  265; end 
                6'd42 : begin base_LUT = 16'd28340; slope_LUT = 16'd  251; end 
                6'd43 : begin base_LUT = 16'd28591; slope_LUT = 16'd  238; end 
                6'd44 : begin base_LUT = 16'd28829; slope_LUT = 16'd  225; end 
                6'd45 : begin base_LUT = 16'd29054; slope_LUT = 16'd  213; end 
                6'd46 : begin base_LUT = 16'd29267; slope_LUT = 16'd  201; end 
                6'd47 : begin base_LUT = 16'd29468; slope_LUT = 16'd  190; end 
                6'd48 : begin base_LUT = 16'd29658; slope_LUT = 16'd  180; end 
                6'd49 : begin base_LUT = 16'd29838; slope_LUT = 16'd  170; end 
                6'd50 : begin base_LUT = 16'd30008; slope_LUT = 16'd  161; end 
                6'd51 : begin base_LUT = 16'd30169; slope_LUT = 16'd  151; end 
                6'd52 : begin base_LUT = 16'd30320; slope_LUT = 16'd  143; end 
                6'd53 : begin base_LUT = 16'd30463; slope_LUT = 16'd  135; end 
                6'd54 : begin base_LUT = 16'd30598; slope_LUT = 16'd  128; end 
                6'd55 : begin base_LUT = 16'd30726; slope_LUT = 16'd  120; end 
                6'd56 : begin base_LUT = 16'd30846; slope_LUT = 16'd  113; end 
                6'd57 : begin base_LUT = 16'd30959; slope_LUT = 16'd  106; end 
                6'd58 : begin base_LUT = 16'd31065; slope_LUT = 16'd  101; end 
                6'd59 : begin base_LUT = 16'd31166; slope_LUT = 16'd   95; end 
                6'd60 : begin base_LUT = 16'd31261; slope_LUT = 16'd   89; end 
                6'd61 : begin base_LUT = 16'd31350; slope_LUT = 16'd   84; end 
                6'd62 : begin base_LUT = 16'd31434; slope_LUT = 16'd   79; end 
                6'd63 : begin base_LUT = 16'd31513; slope_LUT = 16'd   75; end 
                default: begin base_LUT = 16'd31589; slope_LUT = 16'h0000; end
            endcase
        end

        // 計算插值與四捨五入
        diff = slope_LUT * frac_z;
        y_abs_full = {1'b0, base_LUT, 16'b0} + {1'b0, diff};
        y_abs = y_abs_full[31:16] + y_abs_full[15];
        
        // 6. 恢復符號位 (輸出)
        o_data = z_sign ? -y_abs : y_abs;
    end
endmodule