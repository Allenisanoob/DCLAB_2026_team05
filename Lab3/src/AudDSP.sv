
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
    input         [19:0] i_stop_addr,
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
    //localparam S_GET_4 = 6;
    localparam S_SEND  = 6;
    localparam S_STOP  = 7;
    
    reg        [2:0]  state_r, state_w;
    reg        [3:0]  counter_r, counter_w;
    reg               is_pause_r, is_pause_w;
    reg        [2:0]  speed_r, speed_w;
    reg               is_fast_r, is_fast_w;
    reg               slow_mode_r, slow_mode_w;
    reg        [19:0] addr_r, addr_w;
    reg signed [15:0] data_old_r, data_old_w;
    reg signed [15:0] data_new_r, data_new_w;
    reg signed [15:0] o_dac_data_r, o_dac_data_w;
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
                if (temp_addr > i_stop_addr) addr_w = 0;
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
                    else            state_w = S_GET_3;
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
            /*S_GET_4: begin
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
            end*/
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

/*
module AudDSP (
    input i_rst_n,
    input i_clk,
    input i_start, // start signal, sent by the controller, not a button press
    input i_pause, // pause signal, press to pause, press again to resume
    input [2:0] i_speed,
    input i_stop,
    input i_fast,
    input i_slow_mode,
    input i_daclrck,               // prepare data when low
    input signed [15:0] i_sram_data,
    input [19:0] i_stop_addr, // the last address to read from SRAM
    output signed [15:0] o_dac_data,
    output o_en,                   // enable signal for AudPlayer, !i_daclrck
    output o_is_pause,
    output [19:0] o_sram_addr
);
    // TODO: DSP operations including speed adjustments

    localparam S_IDLE       = 0;
    localparam S_PAUSE      = 1;
    localparam S_GETDATA    = 2;
    localparam S_SENDDATA   = 3;
    localparam S_STOP       = 4;
    

    reg [2:0] state_r, state_w;
    reg [3:0] slow_counter_r, slow_counter_w; // counter for S_SLOW0 and S_SLOW1
    reg [1:0] get_data_counter_r, get_data_counter_w; // counter for getting data from SRAM, when 0 set addr_w, when 1 set addr_r, when 2 get data

    // save input state
    reg is_pause_r, is_pause_w; // pause signal
    reg [2:0] speed_r, speed_w;
    reg is_slow_r, is_slow_w;
    reg slow_mode_r, slow_mode_w;

    reg [19:0] addr_r, addr_w;
    reg signed [15:0] i_data_curr_r, i_data_curr_w;
    reg signed [15:0] i_data_next_r, i_data_next_w; // next data for interpolation

    reg [15:0] o_data_r, o_data_w;

    assign o_dac_data = o_data_r;
    assign o_en = !i_daclrck;
    assign o_sram_addr = addr_r;
    assign o_is_pause = is_pause_r;

    // state machine
    always @(*) begin
        state_w = state_r;
        case(state_r)
            S_IDLE: begin
                if (i_stop) state_w = S_STOP;
                else if (i_start)    state_w = S_PAUSE;
                else            state_w = S_IDLE;
            end
            S_PAUSE: begin
                if (i_stop) state_w = S_STOP;
                else if (!is_pause_r)    state_w = S_GETDATA;
                else                state_w = S_PAUSE;
            end
            S_GETDATA: begin
                if (i_stop) state_w = S_STOP;
                else if (is_pause_r) state_w = S_PAUSE;
                else begin
                    if (!i_daclrck) state_w = S_SENDDATA;   // o_en = 1
                    else            state_w = S_GETDATA;    // o_en = 0
                end
            end
            S_SENDDATA: begin
                if (i_stop) state_w = S_STOP;
                else if (is_pause_r) state_w = S_PAUSE;
                else begin
                    if (!i_daclrck) state_w = S_SENDDATA;   // o_en = 1
                    else            state_w = S_GETDATA;    // o_en = 0
                end
            end
            S_STOP: begin
                state_w = S_IDLE;
            end
        endcase
    end

    // slow counter logic
    always @(*) begin
        slow_counter_w = slow_counter_r;
        case(state_r)
            S_IDLE:     slow_counter_w = 0;
            S_PAUSE:    slow_counter_w = 0;
            S_SENDDATA: begin
                if(is_slow_r && !is_pause_r && i_daclrck) begin
                    if(slow_counter_r == speed_r)   slow_counter_w = 0;
                    else                            slow_counter_w = slow_counter_r + 1;
                end
            end
        endcase
    end

    // get data counter logic
    always @(*) begin
        get_data_counter_w = get_data_counter_r;
        case(state_r)
            S_IDLE:     get_data_counter_w = 0;
            S_PAUSE:    get_data_counter_w = 0;
            S_GETDATA:  if(get_data_counter_r < 3)  get_data_counter_w = get_data_counter_r + 1;
            S_SENDDATA: get_data_counter_w = 0;
        endcase
    end

    // pause logic
    always @(*) begin
        is_pause_w = is_pause_r;
        case(state_r)
            S_IDLE:     is_pause_w = 1;
            S_PAUSE:    if(i_pause) is_pause_w = 0;
            S_GETDATA:  if(i_pause) is_pause_w = 1;
            S_SENDDATA: if(i_pause) is_pause_w = 1;
        endcase
    end

    // play config logic
    always @(*) begin
        speed_w = speed_r;
        is_slow_w = is_slow_r;
        slow_mode_w = slow_mode_r;
        case(state_r)
            S_IDLE: begin
                speed_w = 0;
                is_slow_w = 0;
                slow_mode_w = 0;
            end
            S_PAUSE: begin
                speed_w = i_speed;
                is_slow_w = !i_fast;
                slow_mode_w = i_slow_mode;
            end
            S_GETDATA: begin
                // not able to change configs when getting data
                speed_w = speed_r;
                is_slow_w = is_slow_r;
                slow_mode_w = slow_mode_r;
            end
            S_SENDDATA: begin
                speed_w = i_speed;
                is_slow_w = !i_fast;
                slow_mode_w = i_slow_mode;
            end
        endcase
    end

    // address logic
    // ask for i_data_next
    // add one more bit to prevent overflow
    // if it is larger than i_sram_stop_addr, reset to 0
    reg [20:0] temp_addr;
    always @(*) begin
        addr_w = addr_r;
        temp_addr = addr_r;
        case(state_r)
            S_IDLE: temp_addr = 0;
            S_GETDATA: begin
                if(get_data_counter_r == 0) begin
                    if(is_slow_r) begin
                        // slow mode
                        if(slow_counter_r == 0) temp_addr = addr_r + 1;
                    end
                    else begin
                        // fast mode
                        temp_addr = addr_r + speed_r + 1;
                    end
                end
            end
            S_STOP: temp_addr = 0;
        endcase
        if(temp_addr > i_stop_addr)    addr_w = 0;
        else                                addr_w = temp_addr;
    end

    // i_data logic
    always @(*) begin
        i_data_curr_w = i_data_curr_r;
        i_data_next_w = i_data_next_r;
        case(state_r)
            S_IDLE: i_data_next_w = 0;
            S_PAUSE: i_data_next_w = i_sram_data;
            S_GETDATA: begin
                if(get_data_counter_r == 2) begin
                    if(is_slow_r) begin
                        // slow mode
                        if(slow_counter_r == 0) begin
                            i_data_curr_w = i_data_next_r;
                            i_data_next_w = i_sram_data;
                        end
                    end
                    else begin
                        // fast mode
                        i_data_curr_w = i_data_next_r;
                        i_data_next_w = i_sram_data;
                    end
                end
            end
        endcase
    end

    // o_data logic
    reg signed [16:0] diff; // add one more bit to prevent overflow
    reg signed [20:0] diff_times_slow_counter;
    reg signed [20:0] diff_times_slow_counter_div_speed;
    always @(*) begin
        o_data_w = o_data_r;
        diff = 0;
        diff_times_slow_counter = 0;
        diff_times_slow_counter_div_speed = 0;
        case(state_r)
            S_IDLE: o_data_w = 0;
            S_GETDATA: begin
                if(get_data_counter_r == 3) begin
                    if(is_slow_r) begin
                        // slow mode
                        if(slow_mode_r) begin
                            // linear interpolation
                            diff = $signed(i_data_next_r) - $signed(i_data_curr_r);
                            diff_times_slow_counter = $signed(diff) * $signed({1'b0, slow_counter_r});
                            diff_times_slow_counter_div_speed = $signed($signed(diff_times_slow_counter) / $signed({1'b0, speed_r + 1}));
                            o_data_w = $signed($signed(i_data_curr_r) + $signed(diff_times_slow_counter_div_speed));
                        end
                        else begin
                            // constant interpolation
                            o_data_w = i_data_curr_r;
                        end
                    end
                    else begin
                        // fast mode
                        o_data_w = i_data_curr_r;
                    end
                end
            end
        endcase
    end

    always_ff @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            state_r <= S_IDLE;
            slow_counter_r <= 0;
            get_data_counter_r <= 0;
            is_pause_r <= 1;
            speed_r <= 0;
            is_slow_r <= 0;
            slow_mode_r <= 0;
            addr_r <= 0;
            i_data_curr_r <= 0;
            i_data_next_r <= 0;
            o_data_r <= 0;
        end
        else begin
            state_r <= state_w;
            slow_counter_r <= slow_counter_w;
            get_data_counter_r <= get_data_counter_w;
            is_pause_r <= is_pause_w;
            speed_r <= i_speed;
            is_slow_r <= !i_fast;
            slow_mode_r <= i_slow_mode;
            addr_r <= addr_w;
            i_data_curr_r <= i_data_curr_w;
            i_data_next_r <= i_data_next_w;
            o_data_r <= o_data_w;
        end
    end
endmodule
*/