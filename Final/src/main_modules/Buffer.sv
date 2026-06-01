module Buffer(
    input         i_clk,
    input         i_rst,
    input  [15:0] i_buf_data_l,
    input  [15:0] i_buf_data_r,
    input         i_D2B_valid,
    input         i_B2P_request_l,
    input         i_B2P_request_r,
    output [15:0] o_data
);
    logic [15:0] buf_data_l [0:15];
    logic [15:0] buf_data_r [0:15];
    logic [3:0]  buf_ptr_w, buf_ptr_r_l, buf_ptr_r_r;
    logic [4:0]  fifo_cnt_l, fifo_cnt_r;
    logic [15:0] out_data;
    logic        is_read_l, is_read_r;
    
    logic write_en, read_l_en, read_r_en;

    assign o_data = out_data;
    
    assign write_en  = i_D2B_valid && (fifo_cnt_l < 16) && (fifo_cnt_r < 16);
    assign read_l_en = i_B2P_request_l && (fifo_cnt_l > 0) && !is_read_l;
    assign read_r_en = i_B2P_request_r && (fifo_cnt_r > 0) && !is_read_r;

    always_ff @(posedge i_clk or negedge i_rst) begin
        if (!i_rst) begin
            buf_ptr_w   <= 0;
            buf_ptr_r_l <= 0;
            buf_ptr_r_r <= 0;
            fifo_cnt_l  <= 0;
            fifo_cnt_r  <= 0;
            out_data    <= 0;
            is_read_l   <= 0;
            is_read_r   <= 0;
        end else begin
            if (!i_B2P_request_l) is_read_l <= 0;
            if (!i_B2P_request_r) is_read_r <= 0;

            if (write_en) begin
                buf_data_l[buf_ptr_w] <= i_buf_data_l;
                buf_data_r[buf_ptr_w] <= i_buf_data_r;
                buf_ptr_w             <= buf_ptr_w + 1;
            end
            
            if (read_l_en) begin
                out_data    <= buf_data_l[buf_ptr_r_l];
                buf_ptr_r_l <= buf_ptr_r_l + 1;
                is_read_l   <= 1;
            end else if (read_r_en) begin
                out_data    <= buf_data_r[buf_ptr_r_r];
                buf_ptr_r_r <= buf_ptr_r_r + 1;
                is_read_r   <= 1;
            end
            
            fifo_cnt_l <= fifo_cnt_l + write_en - read_l_en;
            fifo_cnt_r <= fifo_cnt_r + write_en - read_r_en;
        end
    end
endmodule