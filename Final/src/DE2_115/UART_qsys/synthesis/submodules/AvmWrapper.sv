// =============================================================================
// AvmWrapper.sv  (RX-only 重構版)
// -----------------------------------------------------------------------------
// 職責：
//   作為 Avalon-MM Master，對下控制 Qsys 裡的 RS232 (UART) IP。
//   連續輪詢 UART STATUS，每次讀 1 個 byte (avm_readdata[7:0])，
//   在內部以 shift register 累積滿 32 bytes (256 bits) 後，
//   把整包資料從 o_command[255:0] 輸出，並把 o_valid 拉高「1 個 clock cycle」。
//
// 對外介面 (Conduit 形式，直接拉到頂層 DE2_115.sv 再接 Param_Manager)：
//   o_command[255:0] : 累積滿的一整包 256-bit 命令
//   o_valid          : 1-cycle pulse，告知 o_command 這拍有效 (接收端無 ready)
//
// 位元拼裝順序：
//   第一個收到的 byte 放在最高位 [255:248]，最後一個收到的放在 [7:0]。
//   作法：每收到一個 byte 就把暫存器左移 8 位，新 byte 放進 [7:0]。
//   收滿 32 個後，最先進來的那個 byte 自然被推到最高位，符合需求。
//
// 注意 (reset 極性)：
//   本模組沿用 lab2 / Qsys 慣例，採 active-high reset (avm_rst)。
//   Param_Manager.sv 採 active-low reset (i_rst, negedge)。
//   在頂層連接時，Param_Manager 的 i_rst 必須接 ~avm_rst (反相)！
// =============================================================================
module AvmWrapper (
    // ---- Avalon-MM master interface (連到 Qsys 生成的 RS232 IP) ----
    input         avm_rst,          // active-high reset
    input         avm_clk,
    output  [4:0] avm_address,
    output        avm_read,
    input  [31:0] avm_readdata,
    output        avm_write,        // 本模組不寫，恆為 0 (保留 port 以符合 Avalon master)
    output [31:0] avm_writedata,    // 同上，恆為 0
    input         avm_waitrequest,

    // ---- Conduit interface to upper layer (Param_Manager via DE2_115.sv) ----
    output logic [255:0] o_command, // 累積滿的 256-bit 命令
    output logic         o_valid    // 1-cycle valid pulse
);

// -----------------------------------------------------------------------------
// MMIO 暫存器位址與狀態位元
//   依規格：RX_BASE = 0, TX_BASE = 4, STATUS_BASE = 8 (byte address)
//   STATUS_BASE 的 bit[7] 為 rrdy (RX ready，可讀)
// -----------------------------------------------------------------------------
localparam [4:0] RX_BASE     = 5'd0;
localparam [4:0] TX_BASE     = 5'd4;   // 本模組不使用，僅保留定義
localparam [4:0] STATUS_BASE = 5'd8;
localparam       RX_OK_BIT   = 7;      // rrdy

// 一整包要收的 byte 數 (256 bits / 8 = 32 bytes)
localparam       TOTAL_BYTES = 32;

// -----------------------------------------------------------------------------
// 精簡 FSM
//   S_POLL : 讀 STATUS，檢查 rrdy。rrdy=0 -> 繼續輪詢；rrdy=1 -> 去讀 RX
//   S_READ : 讀 RX_BASE 取得 1 個 byte，shift 進暫存器、更新計數
//            - 若這是第 32 個 byte -> 整包收齊，發 valid pulse，計數歸零回 S_POLL
//            - 否則 -> 回 S_POLL 繼續輪詢下一個 byte
// -----------------------------------------------------------------------------
localparam S_POLL = 1'd0;
localparam S_READ = 1'd1;

logic        state_r, state_w;

// bus 訊號暫存 (registered，避免組合迴路)
logic [4:0]  avm_address_r, avm_address_w;
logic        avm_read_r, avm_read_w;

// 資料累積暫存
logic [255:0] command_r, command_w;     // shift register
logic [5:0]   byte_cnt_r, byte_cnt_w;    // 0..32，需可表示 32 故 6 bits
logic         valid_r, valid_w;          // 對外 valid pulse (registered)

// -----------------------------------------------------------------------------
// 輸出 assign
// -----------------------------------------------------------------------------
assign avm_address   = avm_address_r;
assign avm_read      = avm_read_r;
assign avm_write     = 1'b0;             // 純 RX，永不寫
assign avm_writedata = 32'b0;

assign o_command = command_r;
assign o_valid   = valid_r;

// -----------------------------------------------------------------------------
// 組合邏輯：next-state / next-value
// -----------------------------------------------------------------------------
always_comb begin
    // 預設保持現值
    state_w       = state_r;
    avm_address_w = avm_address_r;
    avm_read_w    = avm_read_r;
    command_w     = command_r;
    byte_cnt_w    = byte_cnt_r;
    valid_w       = 1'b0;        // valid 預設為 0，只有收滿那拍才拉高 -> 自動成為 1-cycle pulse

    case (state_r)
        // ---------------------------------------------------------------------
        // 輪詢 STATUS：avm_waitrequest=High 時整個分支不動作，狀態機自然卡住等待
        // ---------------------------------------------------------------------
        S_POLL: begin
            avm_address_w = STATUS_BASE;
            avm_read_w    = 1'b1;        // 持續對 STATUS 發 read
            if (!avm_waitrequest) begin
                if (avm_readdata[RX_OK_BIT]) begin
                    // rrdy=1：下一拍改去讀 RX_BASE
                    avm_address_w = RX_BASE;
                    avm_read_w    = 1'b1;
                    state_w       = S_READ;
                end
                // rrdy=0：維持 S_POLL，下一拍再查一次 STATUS
            end
        end

        // ---------------------------------------------------------------------
        // 讀 RX：取得 1 個 byte，左移 8 位塞入 [7:0]，更新計數
        // ---------------------------------------------------------------------
        S_READ: begin
            avm_address_w = RX_BASE;
            avm_read_w    = 1'b1;
            if (!avm_waitrequest) begin
                // shift in：先到的 byte 會被往高位推，最後到的留在 [7:0]
                command_w  = {command_r[247:0], avm_readdata[7:0]};
                byte_cnt_w = byte_cnt_r + 6'd1;

                if (byte_cnt_r + 6'd1 == TOTAL_BYTES) begin
                    // 第 32 個 byte 收齊：這拍把整包鎖進 command_r，下一拍發 valid pulse
                    valid_w    = 1'b1;          // 在時序段對齊 command_r 更新後輸出
                    byte_cnt_w = 6'd0;          // 歸零，準備收下一包
                end

                // 不論是否收滿，都回 S_POLL 繼續輪詢
                avm_address_w = STATUS_BASE;
                avm_read_w    = 1'b1;
                state_w       = S_POLL;
            end
            // avm_waitrequest=High：維持 S_READ，read 持續拉著，等 slave 完成
        end

        default: begin
            state_w       = S_POLL;
            avm_address_w = STATUS_BASE;
            avm_read_w    = 1'b1;
        end
    endcase
end

// -----------------------------------------------------------------------------
// 時序邏輯 (active-high reset)
// -----------------------------------------------------------------------------
always_ff @(posedge avm_clk or posedge avm_rst) begin
    if (avm_rst) begin
        state_r       <= S_POLL;
        avm_address_r <= STATUS_BASE;
        avm_read_r    <= 1'b1;       // reset 後立刻開始輪詢 STATUS
        command_r     <= 256'b0;
        byte_cnt_r    <= 6'd0;
        valid_r       <= 1'b0;
    end else begin
        state_r       <= state_w;
        avm_address_r <= avm_address_w;
        avm_read_r    <= avm_read_w;
        command_r     <= command_w;
        byte_cnt_r    <= byte_cnt_w;
        valid_r       <= valid_w;    // valid_w 只在收滿那拍為 1 -> valid_r 為單拍 pulse
    end
end

endmodule
