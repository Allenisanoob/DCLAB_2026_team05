`timescale 1ns / 1ps

module tanh_div_v_pwl (
    input  wire               i_clk,   // Clock
    input  wire               i_rst,   // Active-high reset
    input  wire signed [31:0] v_in,    // Q11.21 格式輸入
    input  wire               i_en,    // Input Enable
    output reg  signed [31:0] o_g,     // Output: Signed Q11.21
    output reg                o_en     // Output Enable
);

    // =========================================================================
    // Stage 1: 輸入處理、位址擷取與 LZD (領先零偵測)
    // =========================================================================
    wire [31:0] abs_v = (v_in[31]) ? (~v_in + 1) : v_in;
    
    // Region 判斷：當 |v| >= 8.0 (8.0 是 32'h0100_0000)，也就是 Bit 31~24 不為零
    wire is_reg2_s1 = (|abs_v[31:24]); 

    // --- Region 1 (PWL) 位址與小數 ---
    // |v| 的整數部分有 3 bits (23:21)，最高小數 5 bits (20:16)
    // 合成 8 bits 作為 256-entry ROM 的位址
    wire [7:0]  addr_r1_s1 = abs_v[23:16];
    
    // 剩餘的 16 bits 小數作為 Δx (Q0.16 格式的比例，0 ~ 0.9999)
    wire [15:0] frac_s1    = abs_v[15:0];

    // --- Region 2 (1/v) LZD 與尾數 ---
    reg [4:0] msb_idx_s1;
    reg [7:0] addr_r2_s1;

    always @(*) begin
        if      (abs_v[31]) msb_idx_s1 = 5'd31; 
        else if (abs_v[30]) msb_idx_s1 = 5'd30;
        else if (abs_v[29]) msb_idx_s1 = 5'd29;
        else if (abs_v[28]) msb_idx_s1 = 5'd28;
        else if (abs_v[27]) msb_idx_s1 = 5'd27;
        else if (abs_v[26]) msb_idx_s1 = 5'd26;
        else if (abs_v[25]) msb_idx_s1 = 5'd25;
        else                msb_idx_s1 = 5'd24; 
    end

    always @(*) begin
        case(msb_idx_s1)
            5'd31: addr_r2_s1 = abs_v[30:23];
            5'd30: addr_r2_s1 = abs_v[29:22];
            5'd29: addr_r2_s1 = abs_v[28:21];
            5'd28: addr_r2_s1 = abs_v[27:20];
            5'd27: addr_r2_s1 = abs_v[26:19];
            5'd26: addr_r2_s1 = abs_v[25:18];
            5'd25: addr_r2_s1 = abs_v[24:17];
            5'd24: addr_r2_s1 = abs_v[23:16];
            default: addr_r2_s1 = 8'h00;
        endcase
    end

    // =========================================================================
    // Stage 2: ROM 讀取與訊號流水線 (Pipeline)
    // =========================================================================
    // ROM 宣告
    reg [31:0] rom_r1_base [0:255]; // Region 1 基準值 (Q11.21)
    reg [15:0] rom_r1_diff [0:255]; // Region 1 差值   (Q11.21 的絕對誤差)
    reg [15:0] rom_r2_man  [0:255]; // Region 2 尾數倒數 (Q1.15)

    initial begin
        $readmemh("rom_r1_base.hex", rom_r1_base);
        $readmemh("rom_r1_diff.hex", rom_r1_diff);
        $readmemh("rom_r2_man.hex",  rom_r2_man);
    end

    // Pipeline Registers
    reg [31:0] r1_base_s2;
    reg [15:0] r1_diff_s2;
    reg [15:0] r2_man_s2;
    
    reg [15:0] frac_s2;
    reg [4:0]  msb_idx_s2;
    reg        is_reg2_s2;
    reg        en_s2;

    always @(posedge i_clk or negedge i_rst) begin
        if (!i_rst) begin
            r1_base_s2 <= 32'sd0;
            r1_diff_s2 <= 16'd0;
            r2_man_s2  <= 16'd0;
            frac_s2    <= 16'd0;
            msb_idx_s2 <= 5'd0;
            is_reg2_s2 <= 1'b0;
            en_s2      <= 1'b0;
        end else begin
            en_s2 <= i_en;

            if (i_en) begin
                // ROM 讀取
                r1_base_s2 <= rom_r1_base[addr_r1_s1];
                r1_diff_s2 <= rom_r1_diff[addr_r1_s1];
                r2_man_s2  <= rom_r2_man[addr_r2_s1];

                // 延遲訊號
                frac_s2    <= frac_s1;
                msb_idx_s2 <= msb_idx_s1;
                is_reg2_s2 <= is_reg2_s1;
            end
        end
    end

    // =========================================================================
    // Stage 3: 計算與最終 MUX 輸出 (DSP 與 Shifter)
    // =========================================================================
    // --- Region 1: PWL 計算 ---
    // 乘法器: 16-bit(Diff) * 16-bit(Frac) = 32-bit
    // 技巧：除以 2^16 (也就是向右 shift 16 bits) 即為真實修正量
    wire [31:0] pwl_mult       = r1_diff_s2 * frac_s2; 
    wire [31:0] pwl_correction = {16'b0, pwl_mult[31:16]}; 
    wire [31:0] result_r1      = r1_base_s2 - pwl_correction;

    // --- Region 2: 動態位移計算 ---
    wire [31:0] r2_base_val = {16'b0, r2_man_s2};
    reg  [31:0] result_r2;

    always @(*) begin
        case(msb_idx_s2)
            5'd31: result_r2 = r2_base_val >> 4;
            5'd30: result_r2 = r2_base_val >> 3;
            5'd29: result_r2 = r2_base_val >> 2;
            5'd28: result_r2 = r2_base_val >> 1;
            5'd27: result_r2 = r2_base_val;       // 基準: 不位移
            5'd26: result_r2 = r2_base_val << 1;
            5'd25: result_r2 = r2_base_val << 2;
            5'd24: result_r2 = r2_base_val << 3;
            default: result_r2 = 32'h0;
        endcase
    end

    // --- 最終輸出暫存器 ---
    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            o_g  <= 32'sd0;
            o_en <= 1'b0;
        end else begin
            o_en <= en_s2;

            if (en_s2) begin
                if (is_reg2_s2)
                    o_g <= $signed(result_r2);
                else
                    o_g <= $signed(result_r1);
            end else begin
                o_g <= 32'sd0;
            end
        end
    end

endmodule