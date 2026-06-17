module DE2_115 (
	input CLOCK_50,
	input CLOCK2_50,
	input CLOCK3_50,
	input ENETCLK_25,
	input SMA_CLKIN,
	output SMA_CLKOUT,
	output [8:0] LEDG,
	output [17:0] LEDR,
	input [3:0] KEY,
	input [17:0] SW,
	output [6:0] HEX0,
	output [6:0] HEX1,
	output [6:0] HEX2,
	output [6:0] HEX3,
	output [6:0] HEX4,
	output [6:0] HEX5,
	output [6:0] HEX6,
	output [6:0] HEX7,
	output LCD_BLON,
	inout [7:0] LCD_DATA,
	output LCD_EN,
	output LCD_ON,
	output LCD_RS,
	output LCD_RW,
	output UART_CTS,
	input UART_RTS,
	input UART_RXD,
	output UART_TXD,
	inout PS2_CLK,
	inout PS2_DAT,
	inout PS2_CLK2,
	inout PS2_DAT2,
	output SD_CLK,
	inout SD_CMD,
	inout [3:0] SD_DAT,
	input SD_WP_N,
	output [7:0] VGA_B,
	output VGA_BLANK_N,
	output VGA_CLK,
	output [7:0] VGA_G,
	output VGA_HS,
	output [7:0] VGA_R,
	output VGA_SYNC_N,
	output VGA_VS,
	input AUD_ADCDAT,
	inout AUD_ADCLRCK,
	inout AUD_BCLK,
	output AUD_DACDAT,
	inout AUD_DACLRCK,
	output AUD_XCK,
	output EEP_I2C_SCLK,
	inout EEP_I2C_SDAT,
	output I2C_SCLK,
	inout I2C_SDAT,
	output ENET0_GTX_CLK,
	input ENET0_INT_N,
	output ENET0_MDC,
	input ENET0_MDIO,
	output ENET0_RST_N,
	input ENET0_RX_CLK,
	input ENET0_RX_COL,
	input ENET0_RX_CRS,
	input [3:0] ENET0_RX_DATA,
	input ENET0_RX_DV,
	input ENET0_RX_ER,
	input ENET0_TX_CLK,
	output [3:0] ENET0_TX_DATA,
	output ENET0_TX_EN,
	output ENET0_TX_ER,
	input ENET0_LINK100,
	output ENET1_GTX_CLK,
	input ENET1_INT_N,
	output ENET1_MDC,
	input ENET1_MDIO,
	output ENET1_RST_N,
	input ENET1_RX_CLK,
	input ENET1_RX_COL,
	input ENET1_RX_CRS,
	input [3:0] ENET1_RX_DATA,
	input ENET1_RX_DV,
	input ENET1_RX_ER,
	input ENET1_TX_CLK,
	output [3:0] ENET1_TX_DATA,
	output ENET1_TX_EN,
	output ENET1_TX_ER,
	input ENET1_LINK100,
	input TD_CLK27,
	input [7:0] TD_DATA,
	input TD_HS,
	output TD_RESET_N,
	input TD_VS,
	inout [15:0] OTG_DATA,
	output [1:0] OTG_ADDR,
	output OTG_CS_N,
	output OTG_WR_N,
	output OTG_RD_N,
	input OTG_INT,
	output OTG_RST_N,
	input IRDA_RXD,
	output [12:0] DRAM_ADDR,
	output [1:0] DRAM_BA,
	output DRAM_CAS_N,
	output DRAM_CKE,
	output DRAM_CLK,
	output DRAM_CS_N,
	inout [31:0] DRAM_DQ,
	output [3:0] DRAM_DQM,
	output DRAM_RAS_N,
	output DRAM_WE_N,
	output [19:0] SRAM_ADDR,
	output SRAM_CE_N,
	inout [15:0] SRAM_DQ,
	output SRAM_LB_N,
	output SRAM_OE_N,
	output SRAM_UB_N,
	output SRAM_WE_N,
	output [22:0] FL_ADDR,
	output FL_CE_N,
	inout [7:0] FL_DQ,
	output FL_OE_N,
	output FL_RST_N,
	input FL_RY,
	output FL_WE_N,
	output FL_WP_N,
	inout [35:0] GPIO,
	input HSMC_CLKIN_P1,
	input HSMC_CLKIN_P2,
	input HSMC_CLKIN0,
	output HSMC_CLKOUT_P1,
	output HSMC_CLKOUT_P2,
	output HSMC_CLKOUT0,
	inout [3:0] HSMC_D,
	input [16:0] HSMC_RX_D_P,
	output [16:0] HSMC_TX_D_P,
	inout [6:0] EX_IO
);

// =========================================================================
// 1. 虛擬 48kHz 採樣脈衝產生器 (每 1042 拍 50MHz 產生一個點)
// =========================================================================
reg [10:0] clk_div_cnt;
wire       fake_audio_pulse;

always @(posedge CLOCK_50 or negedge KEY[0]) begin
    if (!KEY[0]) begin
        clk_div_cnt <= 11'd0;
    end else begin
        if (clk_div_cnt == 11'd1041)
            clk_div_cnt <= 11'd0;
        else
            clk_div_cnt <= clk_div_cnt + 1'b1;
    end
end
// 產生一個維持 1 個主時脈週期的脈衝，模擬音訊採樣完成
assign fake_audio_pulse = (clk_div_cnt == 11'd1041);

// =========================================================================
// 2. 4096 點大胃王計數器 (完全對齊 Avalon-ST 官方時序手冊)
// =========================================================================
reg [11:0] test_sample_cnt;
wire       fft_sink_ready;

always @(posedge CLOCK_50 or negedge KEY[0]) begin
    if (!KEY[0]) begin
        test_sample_cnt <= 12'd0;
    end else begin
        // 當假的音訊脈衝來了，且 FFT 零件說它可以收資料時，計數器前進
        if (fake_audio_pulse && fft_sink_ready) begin
            test_sample_cnt <= test_sample_cnt + 1'b1; // 數到 4095 會自動歸零
        end
    end
end

// 根據手冊要求，用計數器拉出同步的有效、起點與終點訊號
wire fft_sink_valid = fake_audio_pulse;
wire fft_sink_sop   = (test_sample_cnt == 12'd0);
wire fft_sink_eop   = (test_sample_cnt == 12'd4095);

// 產生我們自訂的獨立測試資料：直接把計數器轉成 16-bit 訊號餵進去 (遞增波/鋸齒波)
wire [15:0] fake_audio_data = {4'd0, test_sample_cnt}; // 可以自己寫別的東西進去試試看，像是正弦波、方波、三角波等等，或是直接讀 SRAM 的資料也行

// =========================================================================
// 3. 正式對接你的 fft_0518 零件
// =========================================================================
wire        fft_src_valid;
wire        fft_src_sop;
wire        fft_src_eop;
wire [15:0] fft_src_real;
wire [15:0] fft_src_imag;
wire [5:0]  fft_src_exp;

fft_0518 u_fft_test (
    .clk          (CLOCK_50),          // 系統 50MHz 主要時脈
    .reset_n      (KEY[0]),            // 板子上的 KEY0 鈕當作重置
    
    // 輸入端 (Sink)：焊上我們自製的虛擬時序與資料
    .sink_valid   (fft_sink_valid),    // 虛擬 48kHz 脈衝
    .sink_ready   (fft_sink_ready),    // 接收 IP 的 ready 反饋
    .sink_error   (2'b00),             // 無錯誤，固定給 0
    .sink_sop     (fft_sink_sop),      // 計數器第 0 點
    .sink_eop     (fft_sink_eop),      // 計數器第 4095 點
    .sink_real    (fake_audio_data),   // 餵入我們的 16-bit 數位測資
    .sink_imag    (16'd0),             // 虛部沒有資料，固定填 0
    .inverse      (1'b0),              // 固定給 0 = Forward（時域轉頻域）
    
    // 輸出端 (Source)：算好的頻譜會從這裡吐出來
    .source_valid (fft_src_valid),     // 頻譜有效訊號
    .source_ready (1'b1),              // 告訴 FFT 我們永遠張開雙手收結果
    .source_error (),                  // 懸空不用管
    .source_sop   (fft_src_sop),       // 頻譜起點 (0Hz)
    .source_eop   (fft_src_eop),       // 頻譜終點
    .source_real  (fft_src_real),      // 算出來的頻譜實部
    .source_imag  (fft_src_imag),      // 算出來的頻譜虛部
    .source_exp   (fft_src_exp)        // BFP 共用指數
);

// =========================================================================
// 4. 外接板子硬體確認 (讓你用肉眼快速驗證)
// =========================================================================
assign LEDG[0] = fft_src_valid;        // 如果 FFT 成功開工，綠燈會亮起或極高速閃爍
assign LEDR[11:0] = test_sample_cnt;   // 紅燈會隨輸入計數器跳動（代表有在餵食資料）

endmodule
