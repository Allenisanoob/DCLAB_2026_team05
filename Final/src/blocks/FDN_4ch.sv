module FDN_4ch #(
    parameter integer delay_sample_0 = 1423,
    parameter integer delay_sample_1 = 1787,
    parameter integer delay_sample_2 = 2131,
    parameter integer delay_sample_3 = 2531,
    parameter signed [7:0] gain = 8'sd64 // Q1.7
)(
    input clk,
    input rst,
    input in_valid,
    input signed [15:0] in,
    output reg out_valid,
    output reg signed [15:0] out
);

logic signed [15:0] ch0_buffer [0:delay_sample_0 - 1];
logic signed [15:0] ch1_buffer [0:delay_sample_1 - 1];
logic signed [15:0] ch2_buffer [0:delay_sample_2 - 1];
logic signed [15:0] ch3_buffer [0:delay_sample_3 - 1];
logic [$clog2(delay_sample_0) - 1:0] ptr_0;
logic [$clog2(delay_sample_1) - 1:0] ptr_1;
logic [$clog2(delay_sample_2) - 1:0] ptr_2;
logic [$clog2(delay_sample_3) - 1:0] ptr_3;
logic is_loop_0;
logic is_loop_1;
logic is_loop_2;
logic is_loop_3;
logic signed [15:0] ch0_read; // ch0_read = ch0_buffer[ptr_0]
logic signed [15:0] ch1_read; // ch1_read = ch1_buffer[ptr_1]
logic signed [15:0] ch2_read; // ch2_read = ch2_buffer[ptr_2]
logic signed [15:0] ch3_read; // ch3_read = ch3_buffer[ptr_3]
logic signed [15:0] ch0_delay; // ch0_delay = is_loop_0 ? ch0_read : 16'sd0
logic signed [15:0] ch1_delay; // ch1_delay = is_loop_1 ? ch1_read : 16'sd0
logic signed [15:0] ch2_delay; // ch2_delay = is_loop_2 ? ch2_read : 16'sd0
logic signed [15:0] ch3_delay; // ch3_delay = is_loop_3 ? ch3_read : 16'sd0
logic signed [17:0] ch0_temp_0; // ch0_temp_0 = gain * ch0_delay // Q16.8
logic signed [17:0] ch1_temp_0; // ch1_temp_0 = gain * ch1_delay // Q16.8
logic signed [17:0] ch2_temp_0; // ch2_temp_0 = gain * ch2_delay // Q16.8
logic signed [17:0] ch3_temp_0; // ch3_temp_0 = gain * ch3_delay // Q16.8
logic signed [25:0] ch0_temp_1; // ch0_temp_1 = ch0_temp_0 + ch1_temp_0 + ch2_temp_0 + ch3_temp_0 // Q17.9
logic signed [25:0] ch1_temp_1; // ch1_temp_1 = ch0_temp_0 - ch1_temp_0 + ch2_temp_0 - ch3_temp_0 // Q17.9
logic signed [25:0] ch2_temp_1; // ch2_temp_1 = ch0_temp_0 + ch1_temp_0 - ch2_temp_0 - ch3_temp_0 // Q17.9
logic signed [25:0] ch3_temp_1; // ch3_temp_1 = ch0_temp_0 - ch1_temp_0 - ch2_temp_0 + ch3_temp_0 // Q17.9
logic signed [17:0] ch0_temp_2; // ch0_temp_2 = (ch0_temp_1 + 26'sd256) >>> 9 // Q17.0
logic signed [17:0] ch1_temp_2; // ch1_temp_2 = (ch1_temp_1 + 26'sd256) >>> 9 // Q17.0
logic signed [17:0] ch2_temp_2; // ch2_temp_2 = (ch2_temp_1 + 26'sd256) >>> 9 // Q17.0
logic signed [17:0] ch3_temp_2; // ch3_temp_2 = (ch3_temp_1 + 26'sd256) >>> 9 // Q17.0
logic signed [18:0] ch0_curr_temp; // ch0_curr_temp = in_0 + ch0_temp_2 // Q18.0
logic signed [18:0] ch1_curr_temp; // ch1_curr_temp = in_1 + ch1_temp_2 // Q18.0
logic signed [18:0] ch2_curr_temp; // ch2_curr_temp = in_2 + ch2_temp_2 // Q18.0
logic signed [18:0] ch3_curr_temp; // ch3_curr_temp = in_3 + ch3_temp_2 // Q18.0
logic signed [15:0] ch0_curr; // ch0_curr = saturate(ch0_curr_temp) // Q16.0
logic signed [15:0] ch1_curr; // ch1_curr = saturate(ch1_curr_temp) // Q16.0
logic signed [15:0] ch2_curr; // ch2_curr = saturate(ch2_curr_temp) // Q16.0
logic signed [15:0] ch3_curr; // ch3_curr = saturate(ch3_curr_temp) // Q16.0
logic signed [15:0] out_temp; // out_temp = ch0_temp_0 >>> 2 // Q16.0

assign ch0_delay = is_loop_0 ? ch0_read : 16'sd0;
assign ch1_delay = is_loop_1 ? ch1_read : 16'sd0;
assign ch2_delay = is_loop_2 ? ch2_read : 16'sd0;
assign ch3_delay = is_loop_3 ? ch3_read : 16'sd0;
assign ch0_temp_0 = ch0_delay + ch1_delay + ch2_delay + ch3_delay;
assign ch1_temp_0 = ch0_delay - ch1_delay + ch2_delay - ch3_delay;
assign ch2_temp_0 = ch0_delay + ch1_delay - ch2_delay - ch3_delay;
assign ch3_temp_0 = ch0_delay - ch1_delay - ch2_delay + ch3_delay;
assign ch0_temp_1 = gain * ch0_temp_0;
assign ch1_temp_1 = gain * ch1_temp_0;
assign ch2_temp_1 = gain * ch2_temp_0;
assign ch3_temp_1 = gain * ch3_temp_0;
assign ch0_temp_2 = (ch0_temp_1 + 26'sd128) >>> 8;
assign ch1_temp_2 = (ch1_temp_1 + 26'sd128) >>> 8;
assign ch2_temp_2 = (ch2_temp_1 + 26'sd128) >>> 8;
assign ch3_temp_2 = (ch3_temp_1 + 26'sd128) >>> 8;
assign ch0_curr_temp = in + ch0_temp_2;
assign ch1_curr_temp = in + ch1_temp_2;
assign ch2_curr_temp = in + ch2_temp_2;
assign ch3_curr_temp = in + ch3_temp_2;
assign ch0_curr = (ch0_curr_temp > 19'sd32767) ? 19'sd32767 :
                  (ch0_curr_temp < -19'sd32768) ? -19'sd32768 :
                  ch0_curr_temp[15:0];
assign ch1_curr = (ch1_curr_temp > 19'sd32767) ? 19'sd32767 :
                  (ch1_curr_temp < -19'sd32768) ? -19'sd32768 :
                  ch1_curr_temp[15:0];
assign ch2_curr = (ch2_curr_temp > 19'sd32767) ? 19'sd32767 :
                  (ch2_curr_temp < -19'sd32768) ? -19'sd32768 :
                  ch2_curr_temp[15:0];
assign ch3_curr = (ch3_curr_temp > 19'sd32767) ? 19'sd32767 :
                  (ch3_curr_temp < -19'sd32768) ? -19'sd32768 :
                  ch3_curr_temp[15:0];                  
assign out_temp = ch0_temp_0 >>> 2;
always_ff @(posedge clk or negedge rst) begin
    if (!rst) begin
        ptr_0 <= 0;
        ptr_1 <= 0;
        ptr_2 <= 0;
        ptr_3 <= 0;
        is_loop_0 <= 0;
        is_loop_1 <= 0;
        is_loop_2 <= 0;
        is_loop_3 <= 0;
    end else if (in_valid) begin
        if (ptr_0 == delay_sample_0 - 1) begin
            ptr_0 <= 0;
            is_loop_0 <= 1;
        end else begin
            ptr_0 <= ptr_0 + 1;
        end
        if (ptr_1 == delay_sample_1 - 1) begin
            ptr_1 <= 0;
            is_loop_1 <= 1;
        end else begin
            ptr_1 <= ptr_1 + 1;
        end
        if (ptr_2 == delay_sample_2 - 1) begin
            ptr_2 <= 0;
            is_loop_2 <= 1;
        end else begin
            ptr_2 <= ptr_2 + 1;
        end
        if (ptr_3 == delay_sample_3 - 1) begin
            ptr_3 <= 0;
            is_loop_3 <= 1;
        end else begin
            ptr_3 <= ptr_3 + 1;
        end
        ch0_buffer[ptr_0] <= ch0_curr;
        ch1_buffer[ptr_1] <= ch1_curr;
        ch2_buffer[ptr_2] <= ch2_curr;
        ch3_buffer[ptr_3] <= ch3_curr;
        out_valid <= 1'b1;
        out <= out_temp;
    end else if (out_valid) begin
        out_valid <= 0;
        ch0_read <= ch0_buffer[ptr_0];
        ch1_read <= ch1_buffer[ptr_1];
        ch2_read <= ch2_buffer[ptr_2];
        ch3_read <= ch3_buffer[ptr_3];
    end
end

endmodule