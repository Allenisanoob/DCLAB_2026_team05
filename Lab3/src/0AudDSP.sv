module AudDSP(
    input         i_rst_n,
    input         i_clk,        
    input         i_start,
    input         i_pause,
    input         i_stop,
    input  [3:0]  i_speed,      
    input         i_fast,
    input         i_slow_0,     // 0次內插
    input         i_slow_1,     // 1次內插
    input         i_daclrck,    
    input  [15:0] i_sram_data,  
    output [15:0] o_dac_data,
    output [19:0] o_sram_addr
);

localparam S_IDLE  = 2'd0;
localparam S_PLAY  = 2'd1;
localparam S_PAUSE = 2'd2;

logic [1:0]  state_r, state_w;
logic [19:0] addr_r, addr_w;
logic [2:0]  counter_r, counter_w;
logic        daclrck_pre_r;

// 1 週期延遲
logic        data_ready_r; // Wait one cycle for SRAM data to be ready

// addr 為 data_old_r, addr+1 為 data_new_r
logic signed [15:0] data_old_r, data_old_w;
logic signed [15:0] data_new_r, data_new_w;

wire daclrck_edge = (i_daclrck != daclrck_pre_r); 


// data_old + (data_new - data_old) * counter / speed 
wire signed [15:0] diff = data_new_r - data_old_r;

wire signed [31:0] interp_val = $signed({1'b0, counter_r}) * diff / $signed({1'b0, i_speed});

assign o_sram_addr = addr_r;
assign o_dac_data  = (i_slow_1) ? (data_old_r + interp_val[15:0]) : data_old_r;


always_comb begin
    state_w    = state_r;
    addr_w     = addr_r;
    counter_w  = counter_r;
    data_old_w = data_old_r;
    data_new_w = data_new_r;

    case (state_r)
        S_IDLE: begin
            addr_w     = 20'd0;
            counter_w  = 3'd0;
            data_old_w = 16'd0;
            data_new_w = 16'd0;
            if (i_start) state_w = S_PLAY;
        end

        S_PLAY: begin
            if (i_stop)       state_w = S_IDLE;
            else if (i_pause) state_w = S_PAUSE;
            else if (daclrck_edge) begin
                if (i_fast) begin
                    addr_w = addr_r + {17'd0, i_speed};
                    counter_w = 3'd0;
					data_old_w = data_new_r;
                end 
                else if (i_slow_0 || i_slow_1) begin
                    if (counter_r >= (i_speed - 3'd1)) begin
                        addr_w    = addr_r + 20'd1;
                        counter_w = 3'd0;
						// addr +1 資料傳入 data_old_w
                        data_old_w = data_new_r; 
                    end else begin
                        counter_w = counter_r + 3'd1;
                    end
                end 
                else begin 
                    addr_w = addr_r + 20'd1;
                    counter_w = 3'd0;
                    data_old_w = data_new_r;
                end
            end
        end

        S_PAUSE: begin
            if (i_start) state_w = S_PLAY;
            if (i_stop)  state_w = S_IDLE;
        end
        default: state_w = S_IDLE;
    endcase

    if (addr_w >= 20'd1048575) addr_w = 20'd0;
end


always_ff @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        state_r       <= S_IDLE;
        addr_r        <= 20'd0;
        counter_r     <= 3'd0;
        data_old_r    <= 16'd0;
        data_new_r    <= 16'd0;
        data_ready_r  <= 1'b0;
        daclrck_pre_r <= 1'b0;
    end else begin
        state_r       <= state_w;
        addr_r        <= addr_w;
        counter_r     <= counter_w;
        data_old_r    <= data_old_w;
        daclrck_pre_r <= i_daclrck;

        if (state_r == S_PLAY && daclrck_edge) begin
            data_ready_r <= 1'b1;
        end 
        // wait one cycle
        else if (data_ready_r) begin
            data_new_r   <= $signed(i_sram_data); 
            data_ready_r <= 1'b0;
        end
    end
end

endmodule