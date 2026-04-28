module AudDSP (
    input                i_rst_n,
    input                i_clk,
    input                i_start,
    input                i_pause,
    input                i_stop,
    input         [2:0]  i_speed,
    input                i_fast,      // 0 -> 慢速    1 -> 快速
    input                i_slow_mode, // 0 -> 0次內插 1 -> 1次內插
    input                i_daclrck,
    input  signed [15:0] i_sram_data,
    output signed [15:0] o_dac_data,
    output        [19:0] o_sram_addr,
    output               o_is_pause
);

    localparam S_IDLE  = 0;
    localparam S_PAUSE = 1;
    localparam S_GET_0 = 2;
    localparam S_GET_1 = 3;
    localparam S_GET_2 = 4;
    localparam S_GET_3 = 5;
    localparam S_GET_4 = 6;
    localparam S_SEND  = 7;
    localparam S_STOP  = 8;
    
    reg        [3:0]  state_r, state_w;
    reg        [3:0]  counter_r, counter_w;
    reg               is_pause_r, is_pause_w;
    reg        [2:0]  speed_r, speed_w;
    reg               is_fast_r, is_fast_w;
    reg               slow_mode_r, slow_mode_w;
    reg        [19:0] addr_r, addr_w;
    reg signed [15:0] data_old_r, data_old_w;
    reg signed [15:0] data_new_r, data_new_w;
    reg        [15:0] o_dac_data_r, o_dac_data_w;
    reg        [20:0] temp_addr;
    reg signed [16:0] diff;
    reg signed [20:0] temp1, temp2;

    assign o_dac_data  = o_dac_data_r;
    assign o_sram_addr = addr_r;
    assign o_is_pause  = is_pause_r;

    always_comb begin
        state_w      = state_r;
        counter_w    = counter_r;
        is_pause_w   = is_pause_r;
        speed_w      = speed_r;
        is_fast_w    = is_fast_r;
        slow_mode_w  = slow_mode_r;
        addr_w       = addr_r;
        temp_addr    = addr_r;
        data_old_w   = data_old_r;
        data_new_w   = data_new_r;
        o_dac_data_w = o_dac_data_r;
        diff         = 0;
        temp1        = 0;
        temp2        = 0;
        case (state_r)
            S_IDLE: begin
                if (i_start) state_w = S_PAUSE;
                counter_w    = 0;
                is_pause_w   = 1;
                speed_w      = 0;
                is_fast_w    = 0;
                slow_mode_w  = 0;
                temp_addr    = 0;
                data_new_w   = 0;
                o_dac_data_w = 0;
            end
            S_PAUSE: begin
                if(i_stop) state_w = S_STOP;
                else if (!is_pause_r) state_w = S_GET_0;
                counter_w   = 0;
                if (i_pause) is_pause_w = 0;
                speed_w     = i_speed;
                is_fast_w   = i_fast;
                slow_mode_w = i_slow_mode;
                data_new_w  = i_sram_data;
            end
            S_GET_0: begin
                if (i_stop) begin
                    state_w = S_STOP;     
                end
                else if (is_pause_r) begin
                        state_w = S_PAUSE;    
                end
                if (is_pause_r) state_w = S_PAUSE;
                else begin
                    if (!i_daclrck) state_w = S_SEND;
                    else            state_w = S_GET_1;
                end
                if (i_pause) is_pause_w = 1;
                speed_w     = speed_r;
                is_fast_w   = is_fast_r;
                slow_mode_w = slow_mode_r;
                if (is_fast_r) begin
                    temp_addr = addr_r + speed_r + 1;
                end else begin
                    if(counter_r == 0) temp_addr = addr_r + 1;
                end
                if (temp_addr > 20'd1048575) addr_w = 0;
                else                         addr_w = temp_addr;
            end
            S_GET_1: begin
                if (i_stop) begin
                    state_w = S_STOP;     
                end
                else if (is_pause_r) begin
                        state_w = S_PAUSE;    
                end
                else begin
                    if (!i_daclrck) state_w = S_SEND;
                    else            state_w = S_GET_2;
                end
                if (i_pause) is_pause_w = 1;
                speed_w     = speed_r;
                is_fast_w   = is_fast_r;
                slow_mode_w = slow_mode_r;
            end
            S_GET_2: begin
                if (i_stop) begin
                    state_w = S_STOP;     
                end
                else if (is_pause_r) begin
                        state_w = S_PAUSE;    
                end
                else begin
                    if (!i_daclrck) state_w = S_SEND;
                    else            state_w = S_GET_3;
                end
                if (i_pause) is_pause_w = 1;
                speed_w     = speed_r;
                is_fast_w   = is_fast_r;
                slow_mode_w = slow_mode_r;
                if (is_fast_r) begin
                    data_old_w = data_new_r;
                    data_new_w = i_sram_data;
                end else begin
                    if (counter_r == 0) begin
                        data_old_w = data_new_r;
                        data_new_w = i_sram_data;
                    end
                end
            end
            S_GET_3: begin
                if (i_stop) begin
                    state_w = S_STOP;     
                end
                else if (is_pause_r) begin
                        state_w = S_PAUSE;    
                end
                else begin
                    if (!i_daclrck) state_w = S_SEND;
                    else            state_w = S_GET_4;
                end
                if (i_pause) is_pause_w = 1;
                speed_w     = speed_r;
                is_fast_w   = is_fast_r;
                slow_mode_w = slow_mode_r;
                if (is_fast_r) begin
                    o_dac_data_w = data_old_r;
                end else begin
                    if (slow_mode_r) begin
                        diff         = $signed(data_new_r) - $signed(data_old_r);
                        temp1        = $signed(diff) * $signed({1'b0, counter_r});
                        temp2        = $signed($signed(temp1) / $signed({1'b0, speed_r + 1}));
                        o_dac_data_w = $signed($signed(data_old_r) + $signed(temp2));
                    end
                    else begin
                        o_dac_data_w = data_old_r;
                    end
                end
            end
            S_GET_4: begin
                if (i_stop) begin
                    state_w = S_STOP;     
                end
                else if (is_pause_r) begin
                        state_w = S_PAUSE;    
                end
                else begin
                    if (!i_daclrck) state_w = S_SEND;
                    else            state_w = S_GET_4;
                end
                if (i_pause) is_pause_w = 1;
                speed_w     = speed_r;
                is_fast_w   = is_fast_r;
                slow_mode_w = slow_mode_r;
            end
            S_SEND: begin
                if (is_pause_r) state_w = S_PAUSE;
                else begin
                    if (!i_daclrck) state_w = S_SEND;
                    else            state_w = S_GET_0;
                end
                if (!is_fast_r && state_w == S_GET_0) begin
                    if (counter_r == speed_r) counter_w = 0;
                    else                      counter_w = counter_r + 1;
                end
                if (i_pause) is_pause_w = 1;
                speed_w     = i_speed;
                is_fast_w   = i_fast;
                slow_mode_w = i_slow_mode;
            end
            S_STOP: begin
                addr_w = 20'd0;    
                state_w = S_IDLE;  
            end
            default: state_w = S_IDLE;
        endcase
    end

    always_ff @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            state_r      <= S_IDLE;
            counter_r    <= 0;
            is_pause_r   <= 1;
            speed_r      <= 0;
            is_fast_r    <= 0;
            slow_mode_r  <= 0;
            addr_r       <= 0;
            data_old_r   <= 0;
            data_new_r   <= 0;
            o_dac_data_r <= 0;
        end
        else begin
            state_r      <= state_w;
            counter_r    <= counter_w;
            is_pause_r   <= is_pause_w;
            speed_r      <= speed_w;
            is_fast_r    <= is_fast_w;
            slow_mode_r  <= slow_mode_w;
            addr_r       <= addr_w;
            data_old_r   <= data_old_w;
            data_new_r   <= data_new_w;
            o_dac_data_r <= o_dac_data_w;
        end
    end
endmodule