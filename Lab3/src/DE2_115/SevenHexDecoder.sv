module SevenHexDecoder (
	input        [3:0] i_hex,
	input              i_dot_en,
	output logic [7:0] o_seven
);

/* The layout of seven segment display, 1: dark
 *    00
 *   5  1
 *    66
 *   4  2
 *    33 .7
 */
parameter D0 = 7'b1000000;
parameter D1 = 7'b1111001;
parameter D2 = 7'b0100100;
parameter D3 = 7'b0110000;
parameter D4 = 7'b0011001;
parameter D5 = 7'b0010010;
parameter D6 = 7'b0000010;
parameter D7 = 7'b1111000;
parameter D8 = 7'b0000000;
parameter D9 = 7'b0010000;
always_comb begin
	case(i_hex)
		4'h0: o_seven[6:0] = D0;
        4'h1: o_seven[6:0] = D1;
        4'h2: o_seven[6:0] = D2;
        4'h3: o_seven[6:0] = D3;
		4'h4: o_seven[6:0] = D4;
        4'h5: o_seven[6:0] = D5;
        4'h6: o_seven[6:0] = D6;
        4'h7: o_seven[6:0] = D7;
        4'h8: o_seven[6:0] = D8;
        4'h9: o_seven[6:0] = D9;
        default: o_seven[6:0] = 7'b1111111; // 其他數值不顯示
        endcase
		o_seven[7] = (i_dot_en) ? 1'b0 : 1'b1;
end

endmodule
