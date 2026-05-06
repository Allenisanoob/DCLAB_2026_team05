module buffer(
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
    logic [5:0]  fifo_cnt;
    logic [15:0] out_data;
    logic        is_read_l, is_read_r;

    assign o_data = out_data;

    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            buf_ptr_w <= 0;
            buf_ptr_r_l <= 0;
            buf_ptr_r_r <= 0;
            fifo_cnt <= 0;
            out_data <= 0;
            is_read_l <= 0;
            is_read_r <= 0;
        end else begin
            if (i_D2B_valid && !fifo_cnt[5] && !fifo_cnt[0]) begin
                buf_data_l[buf_ptr_w] <= i_buf_data_l;
                buf_data_r[buf_ptr_w] <= i_buf_data_r;
                buf_ptr_w <= buf_ptr_w + 1;
                fifo_cnt <= fifo_cnt + 2;
            end else if (i_B2P_request_l && fifo_cnt > 0 && !is_read_l) begin
                out_data <= buf_data_l[buf_ptr_r_l];
                buf_ptr_r_l <= buf_ptr_r_l + 1;
                fifo_cnt <= fifo_cnt - 1;
                is_read_l <= 1;
            end else if (i_B2P_request_r && fifo_cnt > 0 && !is_read_r) begin
                out_data <= buf_data_r[buf_ptr_r_r];
                buf_ptr_r_r <= buf_ptr_r_r + 1;
                fifo_cnt <= fifo_cnt - 1;
                is_read_r <= 1;
            end
            if (!i_B2P_request_l) is_read_l <= 0;
            if (!i_B2P_request_r) is_read_r <= 0;
        end
    end
endmodule