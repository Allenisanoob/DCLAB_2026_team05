// =============================================================================
// AvmWrapper.sv
// -----------------------------------------------------------------------------
// 這個模組只負責 Avalon-MM (RS232 IP) 的 memory-mapped I/O。
// 它把「先查 STATUS、等 rrdy/trdy、再讀 RX / 寫 TX」的輪詢邏輯整個包在內部，
// 對上層 (Packet.sv) 只暴露乾淨的 byte-stream ready/valid 介面。
//
//   收 byte (AvmWrapper -> Packet):  o_rx_data / o_rx_valid / i_rx_ready
//   送 byte (Packet -> AvmWrapper):  i_tx_data / i_tx_valid / o_tx_ready
//
// 介面語意 (標準 ready/valid，當 valid && ready 同拍成立即完成交握)：
//   RX: AvmWrapper 讀到一個 byte 後，o_rx_valid=1 且 o_rx_data 穩定，維持到
//       上層 i_rx_ready=1 為止。該拍兩者皆 1 即視為上層收下。
//   TX: 上層 i_tx_valid=1 表示有一個 byte 要送；o_tx_ready=1 表示 AvmWrapper
//       現在可以收下這個 byte 去寫 UART。該拍兩者皆 1 即視為 AvmWrapper 收下，
//       之後 AvmWrapper 自行完成「查 trdy -> 寫 TX」，期間 o_tx_ready=0。
//
// 設計重點 (相對 lab2 Rsa256Wrapper 的修正)：
//   1. 任何 polling 狀態在條件不成立時都會「回到 S_IDLE 重新仲裁」，不會把自己
//      鎖死在某個 polling state，因此 TX 不會被 RX polling 餓死，可連續收發。
//   2. o_tx_ready 是真正的 ready (「可收」)，不是 done pulse。
//   3. RX deliver 不佔用 bus，且 TX 永遠能在下一次 S_IDLE 搶到優先權，不死鎖。
//
// MMIO 機制 (port、RX/TX/STATUS_BASE、avm_*_r/w、StartRead/StartWrite、
// !avm_waitrequest 才動作) 沿用自 lab2 的 Rsa256Wrapper.sv。
// =============================================================================
module AvmWrapper (
    // ---- Avalon-MM master interface (連到 Qsys 生成的 RS232 IP) ----
    input         avm_rst,
    input         avm_clk,
    output  [4:0] avm_address,
    output        avm_read,
    input  [31:0] avm_readdata,
    output        avm_write,
    output [31:0] avm_writedata,
    input         avm_waitrequest,

    // ---- byte-stream interface to upper layer (Packet.sv) ----
    // RX: 收到一個 byte 交給上層
    output [7:0]  o_rx_data,
    output        o_rx_valid,
    input         i_rx_ready,
    // TX: 上層丟一個 byte 給我送出去
    input  [7:0]  i_tx_data,
    input         i_tx_valid,
    output        o_tx_ready
);

// -----------------------------------------------------------------------------
// MMIO 暫存器位址與狀態位元 (沿用 Rsa256Wrapper.sv)
// -----------------------------------------------------------------------------
localparam RX_BASE     = 0*4;
localparam TX_BASE     = 1*4;
localparam STATUS_BASE = 2*4;
localparam TX_OK_BIT   = 6;   // trdy
localparam RX_OK_BIT   = 7;   // rrdy

// -----------------------------------------------------------------------------
// 內部輪詢 FSM
//   S_IDLE        : 仲裁點。TX 優先：i_tx_valid 時收下 byte 去送；否則去輪詢 RX
//   S_RX_STATUS   : 讀 STATUS，檢查 rrdy；rrdy=0 -> 回 S_IDLE 重新仲裁
//   S_RX_DATA     : rrdy=1，讀 RX_BASE 取得 byte
//   S_RX_DELIVER  : 把 byte 用 valid/ready 交給上層 (不佔 bus)
//   S_TX_STATUS   : 讀 STATUS，檢查 trdy；trdy=0 -> 繼續查 (TX 已承諾收下，需送完)
//   S_TX_DATA     : trdy=1，寫 TX_BASE 送出 byte
// -----------------------------------------------------------------------------
localparam S_IDLE       = 3'd0;
localparam S_RX_STATUS  = 3'd1;
localparam S_RX_DATA    = 3'd2;
localparam S_RX_DELIVER = 3'd3;
localparam S_TX_STATUS  = 3'd4;
localparam S_TX_DATA    = 3'd5;

logic [2:0] state_r, state_w;

// bus 訊號暫存
logic [4:0]  avm_address_r, avm_address_w;
logic        avm_read_r, avm_read_w, avm_write_r, avm_write_w;
logic [31:0] avm_writedata_r, avm_writedata_w;

// byte-stream 暫存
logic [7:0] rx_data_r, rx_data_w;   // 收進來的 byte
logic       rx_valid_r, rx_valid_w; // 對上層的 valid (registered)
logic [7:0] tx_data_r, tx_data_w;   // 抓住上層要送的 byte

// -----------------------------------------------------------------------------
// 輸出 assign
// -----------------------------------------------------------------------------
assign avm_address   = avm_address_r;
assign avm_read      = avm_read_r;
assign avm_write     = avm_write_r;
assign avm_writedata = avm_writedata_r;

assign o_rx_data  = rx_data_r;
assign o_rx_valid = rx_valid_r;

// o_tx_ready: 真正的 ready。只有在 S_IDLE、且沒有 RX byte 正等著交付時，
// AvmWrapper 才可以收下一個新的 TX byte。組合輸出，與 i_tx_valid 同拍握手。
assign o_tx_ready = (state_r == S_IDLE) && !rx_valid_r;

// -----------------------------------------------------------------------------
// bus transaction helper
// -----------------------------------------------------------------------------
task StartRead;
    input [4:0] addr;
    begin
        avm_read_w    = 1'b1;
        avm_write_w   = 1'b0;
        avm_address_w = addr;
    end
endtask
task StartWrite;
    input [4:0] addr;
    begin
        avm_read_w    = 1'b0;
        avm_write_w   = 1'b1;
        avm_address_w = addr;
    end
endtask
task BusIdle;   // 不發起任何 bus 動作
    begin
        avm_read_w  = 1'b0;
        avm_write_w = 1'b0;
    end
endtask

// -----------------------------------------------------------------------------
// 組合邏輯
// -----------------------------------------------------------------------------
always_comb begin
    // 預設保持
    state_w         = state_r;
    avm_address_w   = avm_address_r;
    avm_read_w      = avm_read_r;
    avm_write_w     = avm_write_r;
    avm_writedata_w = avm_writedata_r;
    rx_data_w       = rx_data_r;
    rx_valid_w      = rx_valid_r;     // valid 預設維持 (registered handshake)
    tx_data_w       = tx_data_r;

    case (state_r)
        // ---------------------------------------------------------------------
        // 仲裁點：TX 優先 (i_tx_valid && o_tx_ready 同拍握手)，否則去輪詢 RX。
        // o_tx_ready 在此狀態 = !rx_valid_r，故 rx 尚有 byte 未交付時不收 TX。
        // ---------------------------------------------------------------------
        S_IDLE: begin
            if (i_tx_valid && !rx_valid_r) begin
                // 同拍收下上層的 byte
                tx_data_w = i_tx_data;
                StartRead(STATUS_BASE);     // 先去查 trdy
                state_w = S_TX_STATUS;
            end else if (i_rx_ready && !rx_valid_r) begin
                // 上層允許收、且手上沒有未交付的 byte -> 去輪詢 RX
                StartRead(STATUS_BASE);     // 先去查 rrdy
                state_w = S_RX_STATUS;
            end else begin
                BusIdle();                  // 沒事，待在 IDLE
            end
        end

        // ---------------------------------------------------------------------
        // RX：查 STATUS -> 等 rrdy。rrdy=0 立刻回 S_IDLE 重新仲裁 (修問題一)
        // ---------------------------------------------------------------------
        S_RX_STATUS: begin
            if (!avm_waitrequest) begin
                if (avm_readdata[RX_OK_BIT]) begin
                    StartRead(RX_BASE);     // rrdy=1，下個 cycle 真正讀 byte
                    state_w = S_RX_DATA;
                end else begin
                    BusIdle();              // 沒資料 -> 回仲裁，讓 TX 有機會
                    state_w = S_IDLE;
                end
            end
        end

        S_RX_DATA: begin
            if (!avm_waitrequest) begin
                rx_data_w  = avm_readdata[7:0];
                rx_valid_w = 1'b1;          // 舉起 valid，交給上層
                BusIdle();
                state_w = S_RX_DELIVER;
            end
        end

        // ---------------------------------------------------------------------
        // RX deliver：不佔 bus。維持 valid 直到上層 i_rx_ready 收下。
        // 收下後回 S_IDLE，TX 可在下一拍立即被服務 (不死鎖)。
        // ---------------------------------------------------------------------
        S_RX_DELIVER: begin
            BusIdle();
            if (i_rx_ready) begin           // valid 已為 1，這拍 ready=1 即握手成立
                rx_valid_w = 1'b0;
                state_w = S_IDLE;
            end
        end

        // ---------------------------------------------------------------------
        // TX：已在 S_IDLE 承諾收下 byte，這裡負責送完。
        // trdy=0 時繼續查 STATUS (不放棄，因為 byte 已收下，必須送出去)。
        // ---------------------------------------------------------------------
        S_TX_STATUS: begin
            if (!avm_waitrequest) begin
                if (avm_readdata[TX_OK_BIT]) begin
                    avm_writedata_w = {24'b0, tx_data_r};
                    StartWrite(TX_BASE);    // trdy=1，下個 cycle 寫 byte
                    state_w = S_TX_DATA;
                end else begin
                    StartRead(STATUS_BASE); // 還沒好，繼續輪詢 trdy
                end
            end
        end

        S_TX_DATA: begin
            if (!avm_waitrequest) begin
                // 寫入完成。直接回 S_IDLE。
                // (上層在 S_IDLE 握手那拍就已知道 byte 被收下，不需要 done pulse)
                BusIdle();
                state_w = S_IDLE;
            end
        end

        default: begin
            BusIdle();
            state_w = S_IDLE;
        end
    endcase
end

// -----------------------------------------------------------------------------
// 時序邏輯 (沿用 Rsa256Wrapper.sv 的 reset 初始化風格；active-high reset)
// -----------------------------------------------------------------------------
always_ff @(posedge avm_clk or posedge avm_rst) begin
    if (avm_rst) begin
        state_r         <= S_IDLE;
        avm_address_r   <= STATUS_BASE;
        avm_read_r      <= 1'b0;
        avm_write_r     <= 1'b0;
        avm_writedata_r <= 32'b0;
        rx_data_r       <= 8'b0;
        rx_valid_r      <= 1'b0;
        tx_data_r       <= 8'b0;
    end else begin
        state_r         <= state_w;
        avm_address_r   <= avm_address_w;
        avm_read_r      <= avm_read_w;
        avm_write_r     <= avm_write_w;
        avm_writedata_r <= avm_writedata_w;
        rx_data_r       <= rx_data_w;
        rx_valid_r      <= rx_valid_w;
        tx_data_r       <= tx_data_w;
    end
end

endmodule
