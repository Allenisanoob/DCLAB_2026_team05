// =============================================================================
// Packet.sv
// -----------------------------------------------------------------------------
// 封包語意層。夾在 AvmWrapper (純 byte 流) 與各功能模組之間。
//
//   AvmWrapper  <-- byte 流 -->  Packet.sv  <-- 解析後語意 -->  功能模組
//
// 接收 (PC -> FPGA)，三條獨立 valid + 資料線：
//   * Parameter packet [0xA5 mid pid hi lo xor]  -> o_param_command / o_param_valid  (-> Param_Manager)
//   * Chain     packet [0x5A s1 s2 s3 s4 xor]    -> o_chain_*       / o_chain_valid   (-> Stager)
//   * Preview   packet [0xC1 mid xor]            -> o_preview_id    / o_preview_valid (-> Find_4_in_36)
//
// 回傳 (FPGA -> PC)，三個 request/done 介面：
//   * Note   packet [0xB1 note freq_hi freq_lo xor]
//   * Chord  packet [0xB2 root quality xor]
//   * STFT   packet [0xB3 N mag_0..mag_35 xor]   (N 固定 36)
//
// XOR checksum = 前面所有 byte 互斥或。接收端驗證通過才拉 valid；
// 回傳端由 Packet.sv 自動算好附在最後一個 byte。
// =============================================================================
module Packet #(
    parameter STFT_N = 36   // STFT 回傳固定 36 bands (E2..Ds5)
) (
    input  i_clk,
    input  i_rst,   // active high (對齊 AvmWrapper 的 avm_rst)

    // ---- byte 流介面 (連到 AvmWrapper) ----
    // RX: 從 AvmWrapper 收 byte
    input  [7:0] i_rx_data,
    input        i_rx_valid,
    output       o_rx_ready,
    // TX: 丟 byte 給 AvmWrapper 送出
    output [7:0] o_tx_data,
    output       o_tx_valid,
    input        i_tx_ready,

    // ============ 接收側輸出 (PC -> FPGA) ============
    // A1 Parameter -> Param_Manager
    // 做法 B 打包格式:
    //   o_param_command[ 7:0 ] = module_id
    //   o_param_command[15:8 ] = param_id
    //   o_param_command[31:16] = value (0~1000)
    //   其餘 bit = 0
    output [255:0] o_param_command,
    output         o_param_valid,

    // A2 Chain -> Stager  (0x00 = bypass/None)
    output [7:0] o_chain_s1,
    output [7:0] o_chain_s2,
    output [7:0] o_chain_s3,
    output [7:0] o_chain_s4,
    output       o_chain_valid,

    // A3 Preview -> Find_4_in_36  (0x00 = 全部停止)
    output [7:0] o_preview_id,
    output       o_preview_valid,

    // ============ 回傳側輸入 (FPGA -> PC) ============
    // B1 Note  (上層拉 valid 要求送出，Packet 送完拉 done 一拍)
    input  [7:0]  i_note_id,
    input  [15:0] i_note_freq,
    input         i_note_valid,
    output        o_note_done,

    // B2 Chord
    input  [7:0]  i_chord_root,
    input  [7:0]  i_chord_quality,
    input         i_chord_valid,
    output        o_chord_done,

    // B3 STFT  (i_stft_mag 為平坦陣列，上層已壓成每個 band 0~255)
    //   band 0 = i_stft_mag[7:0], band 1 = i_stft_mag[15:8], ...
    input  [STFT_N*8-1:0] i_stft_mag,
    input                 i_stft_valid,
    output                o_stft_done
);

// =============================================================================
// 封包 header / 長度常數
// =============================================================================
localparam H_PARAM   = 8'hA5;
localparam H_CHAIN   = 8'h5A;
localparam H_PREVIEW = 8'hC1;
localparam H_NOTE    = 8'hB1;
localparam H_CHORD   = 8'hB2;
localparam H_STFT    = 8'hB3;

localparam LEN_PARAM   = 6;  // A5 mid pid hi lo xor
localparam LEN_CHAIN   = 6;  // 5A s1 s2 s3 s4 xor
localparam LEN_PREVIEW = 3;  // C1 mid xor

// =============================================================================
// ============================  接收 (RX) 路徑  ===============================
// =============================================================================
// parser FSM：先看 header 決定要收幾個 byte，收齊後驗 XOR，正確才打 valid。
// 收到的 byte 暫存在 rx_buf。
localparam RX_IDLE   = 3'd0;  // 等 header
localparam RX_PARAM  = 3'd1;  // 收 param 剩餘 byte
localparam RX_CHAIN  = 3'd2;  // 收 chain 剩餘 byte
localparam RX_PREVIEW= 3'd3;  // 收 preview 剩餘 byte

logic [2:0] rx_state_r, rx_state_w;
logic [7:0] rx_buf_r [0:5];
logic [7:0] rx_buf_w [0:5];
logic [2:0] rx_cnt_r, rx_cnt_w;   // 已收 byte 數
logic [2:0] rx_need_r, rx_need_w; // 此封包總長度

// 解析輸出暫存
logic [255:0] param_cmd_r, param_cmd_w;
logic         param_valid_r, param_valid_w;
logic [7:0]   chain_s1_r, chain_s2_r, chain_s3_r, chain_s4_r;
logic [7:0]   chain_s1_w, chain_s2_w, chain_s3_w, chain_s4_w;
logic         chain_valid_r, chain_valid_w;
logic [7:0]   preview_id_r, preview_id_w;
logic         preview_valid_r, preview_valid_w;

// RX ready：parser 是 registered、每拍最多消費一個 byte，任何狀態都能立即吸收
// 下一個 byte，故恆為 1。
//
// 注意：這裡「不」因為 TX 忙碌而關閉 RX。RX 與 TX 在 AvmWrapper 內部已用 S_IDLE
// 仲裁分隔，AvmWrapper 一次只做一個方向。若這裡在送 TX 時把 rx_ready 壓低，而
// AvmWrapper 剛好已半途讀進一個 RX byte 卡在 deliver 等 ready，會造成
// 「RX 等 ready / ready 等 TX 送完 / TX 等 AvmWrapper 回 IDLE」三方死鎖。
// 故恆為 1，讓已讀進的 byte 永遠能被交付，AvmWrapper 才能回 IDLE 服務 TX。
assign o_rx_ready = 1'b1;

assign o_param_command = param_cmd_r;
assign o_param_valid   = param_valid_r;
assign o_chain_s1      = chain_s1_r;
assign o_chain_s2      = chain_s2_r;
assign o_chain_s3      = chain_s3_r;
assign o_chain_s4      = chain_s4_r;
assign o_chain_valid   = chain_valid_r;
assign o_preview_id    = preview_id_r;
assign o_preview_valid = preview_valid_r;

// XOR 計算 helper：對 rx_buf_w 的前 (need-1) 個 byte 取 XOR
function automatic [7:0] xor_check(input [2:0] need);
    integer k;
    logic [7:0] acc;
    begin
        acc = 8'h00;
        for (k = 0; k < 5; k = k + 1) begin
            if (k < (need - 1)) acc = acc ^ rx_buf_w[k];
        end
        xor_check = acc;
    end
endfunction

integer i;
always_comb begin
    // 預設保持
    rx_state_w = rx_state_r;
    rx_cnt_w   = rx_cnt_r;
    rx_need_w  = rx_need_r;
    for (i = 0; i < 6; i = i + 1) rx_buf_w[i] = rx_buf_r[i];

    param_cmd_w     = param_cmd_r;
    param_valid_w   = 1'b0;          // valid 預設只打一拍
    chain_s1_w      = chain_s1_r;
    chain_s2_w      = chain_s2_r;
    chain_s3_w      = chain_s3_r;
    chain_s4_w      = chain_s4_r;
    chain_valid_w   = 1'b0;
    preview_id_w    = preview_id_r;
    preview_valid_w = 1'b0;

    case (rx_state_r)
        // ---------------------------------------------------------------
        RX_IDLE: begin
            rx_cnt_w = 3'd0;
            if (i_rx_valid && o_rx_ready) begin
                rx_buf_w[0] = i_rx_data;
                rx_cnt_w    = 3'd1;
                case (i_rx_data)
                    H_PARAM:   begin rx_need_w = LEN_PARAM[2:0];   rx_state_w = RX_PARAM;   end
                    H_CHAIN:   begin rx_need_w = LEN_CHAIN[2:0];   rx_state_w = RX_CHAIN;   end
                    H_PREVIEW: begin rx_need_w = LEN_PREVIEW[2:0]; rx_state_w = RX_PREVIEW; end
                    default:   begin rx_cnt_w = 3'd0; rx_state_w = RX_IDLE; end // 不認得的 header 丟棄
                endcase
            end
        end

        // ---------------------------------------------------------------
        // 三種封包收 byte 的流程相同：存進 buf、湊滿就驗 XOR
        RX_PARAM, RX_CHAIN, RX_PREVIEW: begin
            if (i_rx_valid && o_rx_ready) begin
                rx_buf_w[rx_cnt_r] = i_rx_data;
                rx_cnt_w = rx_cnt_r + 3'd1;

                if ((rx_cnt_r + 3'd1) == rx_need_r) begin
                    // 收齊，驗 XOR（最後一個 byte 是 checksum）
                    if (xor_check(rx_need_r) == i_rx_data) begin
                        case (rx_state_r)
                            RX_PARAM: begin
                                // 做法 B 打包
                                param_cmd_w = 256'd0;
                                param_cmd_w[7:0]   = rx_buf_w[1];                       // module_id
                                param_cmd_w[15:8]  = rx_buf_w[2];                       // param_id
                                param_cmd_w[31:16] = {rx_buf_w[3], rx_buf_w[4]};        // value hi:lo
                                param_valid_w = 1'b1;
                            end
                            RX_CHAIN: begin
                                chain_s1_w = rx_buf_w[1];
                                chain_s2_w = rx_buf_w[2];
                                chain_s3_w = rx_buf_w[3];
                                chain_s4_w = rx_buf_w[4];
                                chain_valid_w = 1'b1;
                            end
                            RX_PREVIEW: begin
                                preview_id_w = rx_buf_w[1];
                                preview_valid_w = 1'b1;
                            end
                            default: ;
                        endcase
                    end
                    // 不論 XOR 對錯，回 IDLE 等下一包（錯就直接丟）
                    rx_state_w = RX_IDLE;
                    rx_cnt_w   = 3'd0;
                end
            end
        end

        default: rx_state_w = RX_IDLE;
    endcase
end

// =============================================================================
// ============================  回傳 (TX) 路徑  ===============================
// =============================================================================
// 三種回傳共用 AvmWrapper 的 tx。用一個 FSM 逐 byte 送，附帶 running XOR。
// 仲裁：note > chord > stft（固定優先序，簡單且足夠）。
//
// 流程：閒置時若有 *_valid，鎖存資料、決定封包長度，逐 byte 經 tx 送出，
//       送完最後一個 byte 後拉對應的 *_done 一拍。
localparam TX_IDLE = 2'd0;
localparam TX_SEND = 2'd1;
localparam TX_DONE = 2'd2;

localparam SEL_NONE  = 2'd0;
localparam SEL_NOTE  = 2'd1;
localparam SEL_CHORD = 2'd2;
localparam SEL_STFT  = 2'd3;

// 最大封包長度：STFT = 2 + 36 + 1 = 39 bytes
localparam TX_MAX = 2 + STFT_N + 1;

logic [1:0] tx_state_r, tx_state_w;
logic [1:0] tx_sel_r, tx_sel_w;             // 正在送哪一種
logic [7:0] tx_len_r, tx_len_w;             // 此封包總長度
logic [7:0] tx_idx_r, tx_idx_w;             // 目前送到第幾個 byte
logic [7:0] tx_xor_r, tx_xor_w;             // running XOR

// 鎖存待送資料
logic [7:0]  note_id_r,   note_id_w;
logic [15:0] note_freq_r, note_freq_w;
logic [7:0]  chord_root_r, chord_root_w;
logic [7:0]  chord_qual_r, chord_qual_w;
logic [STFT_N*8-1:0] stft_mag_r, stft_mag_w;

logic [7:0] tx_data_r, tx_data_w;
logic       tx_valid_r, tx_valid_w;

logic note_done_r, note_done_w;
logic chord_done_r, chord_done_w;
logic stft_done_r, stft_done_w;

assign o_tx_data  = tx_data_r;
assign o_tx_valid = tx_valid_r;
assign o_note_done  = note_done_r;
assign o_chord_done = chord_done_r;
assign o_stft_done  = stft_done_r;

// 依目前 sel 與 idx，算出「這個位置該送哪個 byte」(不含 checksum)
// idx 從 0 起算。checksum 在 idx == len-1 時送出。
function automatic [7:0] tx_byte_at(input [1:0] sel, input [7:0] idx);
    logic [7:0] b;
    integer band;
    begin
        b = 8'h00;
        case (sel)
            SEL_NOTE: begin
                case (idx)
                    8'd0: b = H_NOTE;
                    8'd1: b = note_id_r;
                    8'd2: b = note_freq_r[15:8];
                    8'd3: b = note_freq_r[7:0];
                    default: b = 8'h00;
                endcase
            end
            SEL_CHORD: begin
                case (idx)
                    8'd0: b = H_CHORD;
                    8'd1: b = chord_root_r;
                    8'd2: b = chord_qual_r;
                    default: b = 8'h00;
                endcase
            end
            SEL_STFT: begin
                if (idx == 8'd0)      b = H_STFT;
                else if (idx == 8'd1) b = STFT_N[7:0];
                else begin
                    band = idx - 2;                       // 0 .. STFT_N-1
                    b = stft_mag_r[band*8 +: 8];
                end
            end
            default: b = 8'h00;
        endcase
        tx_byte_at = b;
    end
endfunction

always_comb begin
    tx_state_w  = tx_state_r;
    tx_sel_w    = tx_sel_r;
    tx_len_w    = tx_len_r;
    tx_idx_w    = tx_idx_r;
    tx_xor_w    = tx_xor_r;
    note_id_w   = note_id_r;
    note_freq_w = note_freq_r;
    chord_root_w= chord_root_r;
    chord_qual_w= chord_qual_r;
    stft_mag_w  = stft_mag_r;
    tx_data_w   = tx_data_r;
    tx_valid_w  = tx_valid_r;
    note_done_w = 1'b0;     // done 只打一拍
    chord_done_w= 1'b0;
    stft_done_w = 1'b0;

    case (tx_state_r)
        // ---------------------------------------------------------------
        TX_IDLE: begin
            tx_valid_w = 1'b0;
            tx_idx_w   = 8'd0;
            tx_xor_w   = 8'h00;
            // 固定優先序仲裁
            if (i_note_valid) begin
                tx_sel_w    = SEL_NOTE;
                tx_len_w    = 8'd5;             // B1 + 3 + xor
                note_id_w   = i_note_id;
                note_freq_w = i_note_freq;
                tx_state_w  = TX_SEND;
            end else if (i_chord_valid) begin
                tx_sel_w     = SEL_CHORD;
                tx_len_w     = 8'd4;            // B2 + 2 + xor
                chord_root_w = i_chord_root;
                chord_qual_w = i_chord_quality;
                tx_state_w   = TX_SEND;
            end else if (i_stft_valid) begin
                tx_sel_w   = SEL_STFT;
                tx_len_w   = TX_MAX[7:0];       // B3 + N + N*mag + xor
                stft_mag_w = i_stft_mag;
                tx_state_w = TX_SEND;
            end
        end

        // ---------------------------------------------------------------
        // 標準 ready/valid：先擺好 data 並舉 valid，等 AvmWrapper 的
        // o_tx_ready (=i_tx_ready) 與我們的 valid 同拍成立即完成該 byte 交握。
        TX_SEND: begin
            if (!tx_valid_r) begin
                // 尚未舉 valid：擺上 data，下一拍舉 valid 等 ready
                if (tx_idx_r == (tx_len_r - 8'd1)) begin
                    tx_data_w = tx_xor_r;       // 最後一個 byte = checksum
                end else begin
                    tx_data_w = tx_byte_at(tx_sel_r, tx_idx_r);
                end
                tx_valid_w = 1'b1;
            end else if (tx_valid_r && i_tx_ready) begin
                // 握手成立：AvmWrapper 已收下這個 byte
                tx_valid_w = 1'b0;
                // 累計 XOR（checksum byte 本身不計入）
                if (tx_idx_r != (tx_len_r - 8'd1)) begin
                    tx_xor_w = tx_xor_r ^ tx_data_r;
                end
                // 前進到下一個 byte，或結束
                if (tx_idx_r == (tx_len_r - 8'd1)) begin
                    tx_state_w = TX_DONE;
                end else begin
                    tx_idx_w = tx_idx_r + 8'd1;
                end
            end
            // else: 已舉 valid 但 ready 尚未到，維持等待 (tx_valid_w 預設保持)
        end

        // ---------------------------------------------------------------
        TX_DONE: begin
            // 拉對應 done 一拍
            case (tx_sel_r)
                SEL_NOTE:  note_done_w  = 1'b1;
                SEL_CHORD: chord_done_w = 1'b1;
                SEL_STFT:  stft_done_w  = 1'b1;
                default: ;
            endcase
            tx_sel_w   = SEL_NONE;
            tx_state_w = TX_IDLE;
        end

        default: tx_state_w = TX_IDLE;
    endcase
end

// =============================================================================
// 時序邏輯
// =============================================================================
integer j;
always_ff @(posedge i_clk or posedge i_rst) begin
    if (i_rst) begin
        // RX
        rx_state_r <= RX_IDLE;
        rx_cnt_r   <= 3'd0;
        rx_need_r  <= 3'd0;
        for (j = 0; j < 6; j = j + 1) rx_buf_r[j] <= 8'h00;
        param_cmd_r     <= 256'd0;
        param_valid_r   <= 1'b0;
        chain_s1_r      <= 8'h00;
        chain_s2_r      <= 8'h00;
        chain_s3_r      <= 8'h00;
        chain_s4_r      <= 8'h00;
        chain_valid_r   <= 1'b0;
        preview_id_r    <= 8'h00;
        preview_valid_r <= 1'b0;
        // TX
        tx_state_r <= TX_IDLE;
        tx_sel_r   <= SEL_NONE;
        tx_len_r   <= 8'd0;
        tx_idx_r   <= 8'd0;
        tx_xor_r   <= 8'h00;
        note_id_r   <= 8'h00;
        note_freq_r <= 16'h0000;
        chord_root_r<= 8'h00;
        chord_qual_r<= 8'h00;
        stft_mag_r  <= '0;
        tx_data_r   <= 8'h00;
        tx_valid_r  <= 1'b0;
        note_done_r <= 1'b0;
        chord_done_r<= 1'b0;
        stft_done_r <= 1'b0;
    end else begin
        // RX
        rx_state_r <= rx_state_w;
        rx_cnt_r   <= rx_cnt_w;
        rx_need_r  <= rx_need_w;
        for (j = 0; j < 6; j = j + 1) rx_buf_r[j] <= rx_buf_w[j];
        param_cmd_r     <= param_cmd_w;
        param_valid_r   <= param_valid_w;
        chain_s1_r      <= chain_s1_w;
        chain_s2_r      <= chain_s2_w;
        chain_s3_r      <= chain_s3_w;
        chain_s4_r      <= chain_s4_w;
        chain_valid_r   <= chain_valid_w;
        preview_id_r    <= preview_id_w;
        preview_valid_r <= preview_valid_w;
        // TX
        tx_state_r <= tx_state_w;
        tx_sel_r   <= tx_sel_w;
        tx_len_r   <= tx_len_w;
        tx_idx_r   <= tx_idx_w;
        tx_xor_r   <= tx_xor_w;
        note_id_r   <= note_id_w;
        note_freq_r <= note_freq_w;
        chord_root_r<= chord_root_w;
        chord_qual_r<= chord_qual_w;
        stft_mag_r  <= stft_mag_w;
        tx_data_r   <= tx_data_w;
        tx_valid_r  <= tx_valid_w;
        note_done_r <= note_done_w;
        chord_done_r<= chord_done_w;
        stft_done_r <= stft_done_w;
    end
end

endmodule
