module AudDSP (
    input                i_rst_n,
    input                i_clk,
    input                i_start,
    input                i_pause,
    input                i_stop,
    input                i_daclrck,
    input  signed [15:0] i_sram_data,
    input         [19:0] i_stop_addr,
    output signed [15:0] o_dac_data,
    output        [19:0] o_sram_addr,
    output               o_is_pause
);

    localparam IDLE  = 0;
    localparam PAUSE = 1;
    localparam LEFT  = 2;
    localparam RIGHT = 3;
    localparam STOP  = 4;
    
    logic        [2:0]  state_r, state_w;
    logic               is_pause_r, is_pause_w;
    logic               is_stop_r, is_stop_w;
    logic        [19:0] addr_L_r, addr_L_w;
    logic        [19:0] addr_R_r, addr_R_w;
    logic signed [15:0] data_r, data_w;
    logic signed [15:0] o_dac_data_r, o_dac_data_w;
    logic        [1:0]  get_cnt_r, get_cnt_w;
    logic               daclrck_prev_r;

    assign o_dac_data  = o_dac_data_r;
    assign o_sram_addr = (state_r == LEFT && get_cnt_r > 0) ? addr_R_r : (state_r == RIGHT && get_cnt_r > 0) ? addr_L_r : 20'd0;
    assign o_is_pause  = is_pause_r;

    always_comb begin
        state_w      = state_r;
        is_pause_w   = is_pause_r;
        addr_L_w     = addr_L_r;
        addr_R_w     = addr_R_r;
        data_w       = data_r;
        o_dac_data_w = o_dac_data_r;
        get_cnt_w    = get_cnt_r;
        case (state_r)
            IDLE: begin
                if (i_start) state_w = PAUSE;
                is_pause_w   = 1;
                is_stop_w    = 0;
                addr_L_w     = 0;
                addr_R_w     = 0;
                data_w       = 0;
                o_dac_data_w = 0;
                get_cnt_w    = 0;
            end
            PAUSE: begin
                if (is_stop_r) state_w = STOP;
                else if (!is_pause_r && !i_daclrck && daclrck_prev_r) state_w = LEFT;
                else if (!is_pause_r && i_daclrck && !daclrck_prev_r) state_w = RIGHT;
                if (i_pause) is_pause_w = 0;
                if (i_stop) is_stop_w = 1;
                data_w    = i_sram_data;
                get_cnt_w = 0;
            end
            LEFT: begin
                if (is_stop_r) state_w = STOP;
                else if (is_pause_r) state_w = PAUSE;
                else if (i_daclrck) state_w = RIGHT;
                if (i_pause) is_pause_w = 1;
                if (i_stop) is_stop_w = 1;
                if (state_w == RIGHT) get_cnt_w = 0;
                else if (state_w == LEFT && get_cnt_r < 3)  get_cnt_w = get_cnt_r + 1;
                if (get_cnt_r == 0) begin
                    addr_R_w = (addr_R_r + 1 >= 20'd524288 + i_stop_addr) ? 20'd524288 : (addr_R_r + 1);
                end else if (get_cnt_r == 2) begin
                    data_w = i_sram_data;
                end else if (get_cnt_r == 3) begin
                    o_dac_data_w = data_r;
                end
            end
            RIGHT: begin
                if (is_stop_r) state_w = STOP;
                else if (is_pause_r) state_w = PAUSE;
                else if (!i_daclrck) state_w = LEFT;
                if (i_pause) is_pause_w = 1;
                if (i_stop) is_stop_w = 1;
                if (state_w == LEFT) get_cnt_w = 0;
                else if (state_w == RIGHT && get_cnt_r < 3)  get_cnt_w = get_cnt_r + 1;
                if (get_cnt_r == 0) begin
                    addr_L_w = (addr_L_r + 1 >= i_stop_addr) ? 20'd0 : (addr_L_r + 1);
                end else if (get_cnt_r == 2) begin
                    data_w = i_sram_data;
                end else if (get_cnt_r == 3) begin
                    o_dac_data_w = data_r;
                end
            end
            STOP: begin
                state_w   = IDLE;
                is_stop_w = 1;
                addr_L_w  = 0;
                addr_R_w  = 20'd524288;
            end
            default: state_w = IDLE;
        endcase
    end

    always_ff @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            state_r        <= IDLE;
            is_pause_r     <= 1;
            is_stop_r      <= 0;
            addr_L_r       <= 0;
            addr_R_r       <= 20'd524288;
            data_r         <= 0;
            o_dac_data_r   <= 0;
            get_cnt_r      <= 0;
            daclrck_prev_r <= i_daclrck;
        end
        else begin
            state_r        <= state_w;
            is_pause_r     <= is_pause_w;
            is_stop_r      <= is_stop_w;
            addr_L_r       <= addr_L_w;
            addr_R_r       <= addr_R_w;
            data_r         <= data_w;
            o_dac_data_r   <= o_dac_data_w;
            get_cnt_r      <= get_cnt_w;
            daclrck_prev_r <= i_daclrck;
        end
    end
endmodule