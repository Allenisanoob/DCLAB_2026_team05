module STFT (
    input clk,
    input rst,
    input in_valid,
    input signed [15:0] in,
    output reg out_valid,
    output reg [31:0] amp_sq_E2,
    output reg [31:0] amp_sq_F2,
    output reg [31:0] amp_sq_Fs2,
    output reg [31:0] amp_sq_G2,
    output reg [31:0] amp_sq_Gs2,
    output reg [31:0] amp_sq_A2,
    output reg [31:0] amp_sq_As2,
    output reg [31:0] amp_sq_B2,
    output reg [31:0] amp_sq_C3,
    output reg [31:0] amp_sq_Cs3,
    output reg [31:0] amp_sq_D3,
    output reg [31:0] amp_sq_Ds3,
    output reg [31:0] amp_sq_E3,
    output reg [31:0] amp_sq_F3,
    output reg [31:0] amp_sq_Fs3,
    output reg [31:0] amp_sq_G3,
    output reg [31:0] amp_sq_Gs3,
    output reg [31:0] amp_sq_A3,
    output reg [31:0] amp_sq_As3,
    output reg [31:0] amp_sq_B3,
    output reg [31:0] amp_sq_C4,
    output reg [31:0] amp_sq_Cs4,
    output reg [31:0] amp_sq_D4,
    output reg [31:0] amp_sq_Ds4,
    output reg [31:0] amp_sq_E4,
    output reg [31:0] amp_sq_F4,
    output reg [31:0] amp_sq_Fs4,
    output reg [31:0] amp_sq_G4,
    output reg [31:0] amp_sq_Gs4,
    output reg [31:0] amp_sq_A4,
    output reg [31:0] amp_sq_As4,
    output reg [31:0] amp_sq_B4,
    output reg [31:0] amp_sq_C5,
    output reg [31:0] amp_sq_Cs5,
    output reg [31:0] amp_sq_D5,
    output reg [31:0] amp_sq_Ds5
);

logic [5:0] state;
logic [1:0] cnt;

logic signed [47:0] response_real_E2, response_image_E2; // Q33.15
logic signed [47:0] response_real_F2, response_image_F2; // Q33.15
logic signed [47:0] response_real_Fs2, response_image_Fs2; // Q33.15
logic signed [47:0] response_real_G2, response_image_G2; // Q33.15
logic signed [47:0] response_real_Gs2, response_image_Gs2; // Q33.15
logic signed [47:0] response_real_A2, response_image_A2; // Q33.15
logic signed [47:0] response_real_As2, response_image_As2; // Q33.15
logic signed [47:0] response_real_B2, response_image_B2; // Q33.15
logic signed [47:0] response_real_C3, response_image_C3; // Q33.15
logic signed [47:0] response_real_Cs3, response_image_Cs3; // Q33.15
logic signed [47:0] response_real_D3, response_image_D3; // Q33.15
logic signed [47:0] response_real_Ds3, response_image_Ds3; // Q33.15
logic signed [47:0] response_real_E3, response_image_E3; // Q33.15
logic signed [47:0] response_real_F3, response_image_F3; // Q33.15
logic signed [47:0] response_real_Fs3, response_image_Fs3; // Q33.15
logic signed [47:0] response_real_G3, response_image_G3; // Q33.15
logic signed [47:0] response_real_Gs3, response_image_Gs3; // Q33.15
logic signed [47:0] response_real_A3, response_image_A3; // Q33.15
logic signed [47:0] response_real_As3, response_image_As3; // Q33.15
logic signed [47:0] response_real_B3, response_image_B3; // Q33.15
logic signed [47:0] response_real_C4, response_image_C4; // Q33.15
logic signed [47:0] response_real_Cs4, response_image_Cs4; // Q33.15
logic signed [47:0] response_real_D4, response_image_D4; // Q33.15
logic signed [47:0] response_real_Ds4, response_image_Ds4; // Q33.15
logic signed [47:0] response_real_E4, response_image_E4; // Q33.15
logic signed [47:0] response_real_F4, response_image_F4; // Q33.15
logic signed [47:0] response_real_Fs4, response_image_Fs4; // Q33.15
logic signed [47:0] response_real_G4, response_image_G4; // Q33.15
logic signed [47:0] response_real_Gs4, response_image_Gs4; // Q33.15
logic signed [47:0] response_real_A4, response_image_A4; // Q33.15
logic signed [47:0] response_real_As4, response_image_As4; // Q33.15
logic signed [47:0] response_real_B4, response_image_B4; // Q33.15
logic signed [47:0] response_real_C5, response_image_C5; // Q33.15
logic signed [47:0] response_real_Cs5, response_image_Cs5; // Q33.15
logic signed [47:0] response_real_D5, response_image_D5; // Q33.15
logic signed [47:0] response_real_Ds5, response_image_Ds5; // Q33.15

logic signed [15:0] data_buffer [0:38399]; // Q16.0
logic [15:0] ptr;
logic is_loop;
logic read_data_valid;
logic signed [15:0] temp_0; // temp_0 = data_buffer[ptr]
logic signed [15:0] delay_data; // delay_data = is_loop ? temp_0 : 16'sd0;

assign delay_data = is_loop ? temp_0 : 16'sd0;

logic signed [15:0] new_cos_E2;
logic signed [15:0] new_cos_F2;
logic signed [15:0] new_cos_Fs2;
logic signed [15:0] new_cos_G2;
logic signed [15:0] new_cos_Gs2;
logic signed [15:0] new_cos_A2;
logic signed [15:0] new_cos_As2;
logic signed [15:0] new_cos_B2;
logic signed [15:0] new_cos_C3;
logic signed [15:0] new_cos_Cs3;
logic signed [15:0] new_cos_D3;
logic signed [15:0] new_cos_Ds3;
logic signed [15:0] new_cos_E3;
logic signed [15:0] new_cos_F3;
logic signed [15:0] new_cos_Fs3;
logic signed [15:0] new_cos_G3;
logic signed [15:0] new_cos_Gs3;
logic signed [15:0] new_cos_A3;
logic signed [15:0] new_cos_As3;
logic signed [15:0] new_cos_B3;
logic signed [15:0] new_cos_C4;
logic signed [15:0] new_cos_Cs4;
logic signed [15:0] new_cos_D4;
logic signed [15:0] new_cos_Ds4;
logic signed [15:0] new_cos_E4;
logic signed [15:0] new_cos_F4;
logic signed [15:0] new_cos_Fs4;
logic signed [15:0] new_cos_G4;
logic signed [15:0] new_cos_Gs4;
logic signed [15:0] new_cos_A4;
logic signed [15:0] new_cos_As4;
logic signed [15:0] new_cos_B4;
logic signed [15:0] new_cos_C5;
logic signed [15:0] new_cos_Cs5;
logic signed [15:0] new_cos_D5;
logic signed [15:0] new_cos_Ds5;

logic signed [15:0] new_sin_E2;
logic signed [15:0] new_sin_F2;
logic signed [15:0] new_sin_Fs2;
logic signed [15:0] new_sin_G2;
logic signed [15:0] new_sin_Gs2;
logic signed [15:0] new_sin_A2;
logic signed [15:0] new_sin_As2;
logic signed [15:0] new_sin_B2;
logic signed [15:0] new_sin_C3;
logic signed [15:0] new_sin_Cs3;
logic signed [15:0] new_sin_D3;
logic signed [15:0] new_sin_Ds3;
logic signed [15:0] new_sin_E3;
logic signed [15:0] new_sin_F3;
logic signed [15:0] new_sin_Fs3;
logic signed [15:0] new_sin_G3;
logic signed [15:0] new_sin_Gs3;
logic signed [15:0] new_sin_A3;
logic signed [15:0] new_sin_As3;
logic signed [15:0] new_sin_B3;
logic signed [15:0] new_sin_C4;
logic signed [15:0] new_sin_Cs4;
logic signed [15:0] new_sin_D4;
logic signed [15:0] new_sin_Ds4;
logic signed [15:0] new_sin_E4;
logic signed [15:0] new_sin_F4;
logic signed [15:0] new_sin_Fs4;
logic signed [15:0] new_sin_G4;
logic signed [15:0] new_sin_Gs4;
logic signed [15:0] new_sin_A4;
logic signed [15:0] new_sin_As4;
logic signed [15:0] new_sin_B4;
logic signed [15:0] new_sin_C5;
logic signed [15:0] new_sin_Cs5;
logic signed [15:0] new_sin_D5;
logic signed [15:0] new_sin_Ds5;

logic signed [15:0] old_cos_E2;
logic signed [15:0] old_cos_F2;
logic signed [15:0] old_cos_Fs2;
logic signed [15:0] old_cos_G2;
logic signed [15:0] old_cos_Gs2;
logic signed [15:0] old_cos_A2;
logic signed [15:0] old_cos_As2;
logic signed [15:0] old_cos_B2;
logic signed [15:0] old_cos_C3;
logic signed [15:0] old_cos_Cs3;
logic signed [15:0] old_cos_D3;
logic signed [15:0] old_cos_Ds3;
logic signed [15:0] old_cos_E3;
logic signed [15:0] old_cos_F3;
logic signed [15:0] old_cos_Fs3;
logic signed [15:0] old_cos_G3;
logic signed [15:0] old_cos_Gs3;
logic signed [15:0] old_cos_A3;
logic signed [15:0] old_cos_As3;
logic signed [15:0] old_cos_B3;
logic signed [15:0] old_cos_C4;
logic signed [15:0] old_cos_Cs4;
logic signed [15:0] old_cos_D4;
logic signed [15:0] old_cos_Ds4;
logic signed [15:0] old_cos_E4;
logic signed [15:0] old_cos_F4;
logic signed [15:0] old_cos_Fs4;
logic signed [15:0] old_cos_G4;
logic signed [15:0] old_cos_Gs4;
logic signed [15:0] old_cos_A4;
logic signed [15:0] old_cos_As4;
logic signed [15:0] old_cos_B4;
logic signed [15:0] old_cos_C5;
logic signed [15:0] old_cos_Cs5;
logic signed [15:0] old_cos_D5;
logic signed [15:0] old_cos_Ds5;

logic signed [15:0] old_sin_E2;
logic signed [15:0] old_sin_F2;
logic signed [15:0] old_sin_Fs2;
logic signed [15:0] old_sin_G2;
logic signed [15:0] old_sin_Gs2;
logic signed [15:0] old_sin_A2;
logic signed [15:0] old_sin_As2;
logic signed [15:0] old_sin_B2;
logic signed [15:0] old_sin_C3;
logic signed [15:0] old_sin_Cs3;
logic signed [15:0] old_sin_D3;
logic signed [15:0] old_sin_Ds3;
logic signed [15:0] old_sin_E3;
logic signed [15:0] old_sin_F3;
logic signed [15:0] old_sin_Fs3;
logic signed [15:0] old_sin_G3;
logic signed [15:0] old_sin_Gs3;
logic signed [15:0] old_sin_A3;
logic signed [15:0] old_sin_As3;
logic signed [15:0] old_sin_B3;
logic signed [15:0] old_sin_C4;
logic signed [15:0] old_sin_Cs4;
logic signed [15:0] old_sin_D4;
logic signed [15:0] old_sin_Ds4;
logic signed [15:0] old_sin_E4;
logic signed [15:0] old_sin_F4;
logic signed [15:0] old_sin_Fs4;
logic signed [15:0] old_sin_G4;
logic signed [15:0] old_sin_Gs4;
logic signed [15:0] old_sin_A4;
logic signed [15:0] old_sin_As4;
logic signed [15:0] old_sin_B4;
logic signed [15:0] old_sin_C5;
logic signed [15:0] old_sin_Cs5;
logic signed [15:0] old_sin_D5;
logic signed [15:0] old_sin_Ds5;

STFT_LUT stft_lut(
    .clk(clk),
    .rst(rst),
    .in_valid(out_valid),

    .new_cos_E2(new_cos_E2),
    .new_cos_F2(new_cos_F2),
    .new_cos_Fs2(new_cos_Fs2),
    .new_cos_G2(new_cos_G2),
    .new_cos_Gs2(new_cos_Gs2),
    .new_cos_A2(new_cos_A2),
    .new_cos_As2(new_cos_As2),
    .new_cos_B2(new_cos_B2),
    .new_cos_C3(new_cos_C3),
    .new_cos_Cs3(new_cos_Cs3),
    .new_cos_D3(new_cos_D3),
    .new_cos_Ds3(new_cos_Ds3),
    .new_cos_E3(new_cos_E3),
    .new_cos_F3(new_cos_F3),
    .new_cos_Fs3(new_cos_Fs3),
    .new_cos_G3(new_cos_G3),
    .new_cos_Gs3(new_cos_Gs3),
    .new_cos_A3(new_cos_A3),
    .new_cos_As3(new_cos_As3),
    .new_cos_B3(new_cos_B3),
    .new_cos_C4(new_cos_C4),
    .new_cos_Cs4(new_cos_Cs4),
    .new_cos_D4(new_cos_D4),
    .new_cos_Ds4(new_cos_Ds4),
    .new_cos_E4(new_cos_E4),
    .new_cos_F4(new_cos_F4),
    .new_cos_Fs4(new_cos_Fs4),
    .new_cos_G4(new_cos_G4),
    .new_cos_Gs4(new_cos_Gs4),
    .new_cos_A4(new_cos_A4),
    .new_cos_As4(new_cos_As4),
    .new_cos_B4(new_cos_B4),
    .new_cos_C5(new_cos_C5),
    .new_cos_Cs5(new_cos_Cs5),
    .new_cos_D5(new_cos_D5),
    .new_cos_Ds5(new_cos_Ds5),

    .new_sin_E2(new_sin_E2),
    .new_sin_F2(new_sin_F2),
    .new_sin_Fs2(new_sin_Fs2),
    .new_sin_G2(new_sin_G2),
    .new_sin_Gs2(new_sin_Gs2),
    .new_sin_A2(new_sin_A2),
    .new_sin_As2(new_sin_As2),
    .new_sin_B2(new_sin_B2),
    .new_sin_C3(new_sin_C3),
    .new_sin_Cs3(new_sin_Cs3),
    .new_sin_D3(new_sin_D3),
    .new_sin_Ds3(new_sin_Ds3),
    .new_sin_E3(new_sin_E3),
    .new_sin_F3(new_sin_F3),
    .new_sin_Fs3(new_sin_Fs3),
    .new_sin_G3(new_sin_G3),
    .new_sin_Gs3(new_sin_Gs3),
    .new_sin_A3(new_sin_A3),
    .new_sin_As3(new_sin_As3),
    .new_sin_B3(new_sin_B3),
    .new_sin_C4(new_sin_C4),
    .new_sin_Cs4(new_sin_Cs4),
    .new_sin_D4(new_sin_D4),
    .new_sin_Ds4(new_sin_Ds4),
    .new_sin_E4(new_sin_E4),
    .new_sin_F4(new_sin_F4),
    .new_sin_Fs4(new_sin_Fs4),
    .new_sin_G4(new_sin_G4),
    .new_sin_Gs4(new_sin_Gs4),
    .new_sin_A4(new_sin_A4),
    .new_sin_As4(new_sin_As4),
    .new_sin_B4(new_sin_B4),
    .new_sin_C5(new_sin_C5),
    .new_sin_Cs5(new_sin_Cs5),
    .new_sin_D5(new_sin_D5),
    .new_sin_Ds5(new_sin_Ds5),
    
    .old_cos_E2(old_cos_E2),
    .old_cos_F2(old_cos_F2),
    .old_cos_Fs2(old_cos_Fs2),
    .old_cos_G2(old_cos_G2),
    .old_cos_Gs2(old_cos_Gs2),
    .old_cos_A2(old_cos_A2),
    .old_cos_As2(old_cos_As2),
    .old_cos_B2(old_cos_B2),
    .old_cos_C3(old_cos_C3),
    .old_cos_Cs3(old_cos_Cs3),
    .old_cos_D3(old_cos_D3),
    .old_cos_Ds3(old_cos_Ds3),
    .old_cos_E3(old_cos_E3),
    .old_cos_F3(old_cos_F3),
    .old_cos_Fs3(old_cos_Fs3),
    .old_cos_G3(old_cos_G3),
    .old_cos_Gs3(old_cos_Gs3),
    .old_cos_A3(old_cos_A3),
    .old_cos_As3(old_cos_As3),
    .old_cos_B3(old_cos_B3),
    .old_cos_C4(old_cos_C4),
    .old_cos_Cs4(old_cos_Cs4),
    .old_cos_D4(old_cos_D4),
    .old_cos_Ds4(old_cos_Ds4),
    .old_cos_E4(old_cos_E4),
    .old_cos_F4(old_cos_F4),
    .old_cos_Fs4(old_cos_Fs4),
    .old_cos_G4(old_cos_G4),
    .old_cos_Gs4(old_cos_Gs4),
    .old_cos_A4(old_cos_A4),
    .old_cos_As4(old_cos_As4),
    .old_cos_B4(old_cos_B4),
    .old_cos_C5(old_cos_C5),
    .old_cos_Cs5(old_cos_Cs5),
    .old_cos_D5(old_cos_D5),
    .old_cos_Ds5(old_cos_Ds5),

    .old_sin_E2(old_sin_E2),
    .old_sin_F2(old_sin_F2),
    .old_sin_Fs2(old_sin_Fs2),
    .old_sin_G2(old_sin_G2),
    .old_sin_Gs2(old_sin_Gs2),
    .old_sin_A2(old_sin_A2),
    .old_sin_As2(old_sin_As2),
    .old_sin_B2(old_sin_B2),
    .old_sin_C3(old_sin_C3),
    .old_sin_Cs3(old_sin_Cs3),
    .old_sin_D3(old_sin_D3),
    .old_sin_Ds3(old_sin_Ds3),
    .old_sin_E3(old_sin_E3),
    .old_sin_F3(old_sin_F3),
    .old_sin_Fs3(old_sin_Fs3),
    .old_sin_G3(old_sin_G3),
    .old_sin_Gs3(old_sin_Gs3),
    .old_sin_A3(old_sin_A3),
    .old_sin_As3(old_sin_As3),
    .old_sin_B3(old_sin_B3),
    .old_sin_C4(old_sin_C4),
    .old_sin_Cs4(old_sin_Cs4),
    .old_sin_D4(old_sin_D4),
    .old_sin_Ds4(old_sin_Ds4),
    .old_sin_E4(old_sin_E4),
    .old_sin_F4(old_sin_F4),
    .old_sin_Fs4(old_sin_Fs4),
    .old_sin_G4(old_sin_G4),
    .old_sin_Gs4(old_sin_Gs4),
    .old_sin_A4(old_sin_A4),
    .old_sin_As4(old_sin_As4),
    .old_sin_B4(old_sin_B4),
    .old_sin_C5(old_sin_C5),
    .old_sin_Cs5(old_sin_Cs5),
    .old_sin_D5(old_sin_D5),
    .old_sin_Ds5(old_sin_Ds5)
);

logic signed [47:0] response_real, response_image; // Q33.15
logic signed [47:0] leak_response_real, leak_response_image; // Q33.15
logic signed [31:0] temp_new_real, temp_new_image, temp_old_real, temp_old_image; // Q17.15

assign leak_response_real = response_real - (response_real >>> 12);
assign leak_response_image = response_image - (response_image >>> 12);

logic signed [15:0] truncated_real, truncated_image;

assign truncated_real  = leak_response_real[47:32];
assign truncated_image = leak_response_image[47:32];

logic signed [31:0] amp_sq_real, amp_sq_image;

assign amp_sq_real  = truncated_real * truncated_real;
assign amp_sq_image = truncated_image * truncated_image;

logic signed [32:0] amp_sq;

assign amp_sq = amp_sq_real + amp_sq_image;

always_ff @(posedge clk or negedge rst) begin
    if (!rst) begin
        ptr <= 0;
        is_loop <= 0;
        state <= 0;
        cnt <= 0;
        read_data_valid <= 0;
        out_valid <= 0;

        response_real <= 48'sd0;
        response_image <= 48'sd0;
        temp_new_real <= 32'sd0;
        temp_new_image <= 32'sd0;
        temp_old_real <= 32'sd0;
        temp_old_image <= 32'sd0;

        response_real_E2 <= 48'sd0;
        response_image_E2 <= 48'sd0;
        response_real_F2 <= 48'sd0;
        response_image_F2 <= 48'sd0;
        response_real_Fs2 <= 48'sd0;
        response_image_Fs2 <= 48'sd0;
        response_real_G2 <= 48'sd0;
        response_image_G2 <= 48'sd0;
        response_real_Gs2 <= 48'sd0;
        response_image_Gs2 <= 48'sd0;
        response_real_A2 <= 48'sd0;
        response_image_A2 <= 48'sd0;
        response_real_As2 <= 48'sd0;
        response_image_As2 <= 48'sd0;
        response_real_B2 <= 48'sd0;
        response_image_B2 <= 48'sd0;
        response_real_C3 <= 48'sd0;
        response_image_C3 <= 48'sd0;
        response_real_Cs3 <= 48'sd0;
        response_image_Cs3 <= 48'sd0;
        response_real_D3 <= 48'sd0;
        response_image_D3 <= 48'sd0;
        response_real_Ds3 <= 48'sd0;
        response_image_Ds3 <= 48'sd0;
        response_real_E3 <= 48'sd0;
        response_image_E3 <= 48'sd0;
        response_real_F3 <= 48'sd0;
        response_image_F3 <= 48'sd0;
        response_real_Fs3 <= 48'sd0;
        response_image_Fs3 <= 48'sd0;
        response_real_G3 <= 48'sd0;
        response_image_G3 <= 48'sd0;
        response_real_Gs3 <= 48'sd0;
        response_image_Gs3 <= 48'sd0;
        response_real_A3 <= 48'sd0;
        response_image_A3 <= 48'sd0;
        response_real_As3 <= 48'sd0;
        response_image_As3 <= 48'sd0;
        response_real_B3 <= 48'sd0;
        response_image_B3 <= 48'sd0;
        response_real_C4 <= 48'sd0;
        response_image_C4 <= 48'sd0;
        response_real_Cs4 <= 48'sd0;
        response_image_Cs4 <= 48'sd0;
        response_real_D4 <= 48'sd0;
        response_image_D4 <= 48'sd0;
        response_real_Ds4 <= 48'sd0;
        response_image_Ds4 <= 48'sd0;
        response_real_E4 <= 48'sd0;
        response_image_E4 <= 48'sd0;
        response_real_F4 <= 48'sd0;
        response_image_F4 <= 48'sd0;
        response_real_Fs4 <= 48'sd0;
        response_image_Fs4 <= 48'sd0;
        response_real_G4 <= 48'sd0;
        response_image_G4 <= 48'sd0;
        response_real_Gs4 <= 48'sd0;
        response_image_Gs4 <= 48'sd0;
        response_real_A4 <= 48'sd0;
        response_image_A4 <= 48'sd0;
        response_real_As4 <= 48'sd0;
        response_image_As4 <= 48'sd0;
        response_real_B4 <= 48'sd0;
        response_image_B4 <= 48'sd0;
        response_real_C5 <= 48'sd0;
        response_image_C5 <= 48'sd0;
        response_real_Cs5 <= 48'sd0;
        response_image_Cs5 <= 48'sd0;
        response_real_D5 <= 48'sd0;
        response_image_D5 <= 48'sd0;
        response_real_Ds5 <= 48'sd0;
        response_image_Ds5 <= 48'sd0;
    end else begin
        case (state)
            6'd0: begin
                if (in_valid) begin
                    state <= state + 1;
                    cnt <= 0;
                    if (ptr == 38399) begin
                        ptr <= 0;
                        is_loop <= 1;
                    end else begin
                        ptr <= ptr + 1;
                    end
                    data_buffer[ptr] <= in;
                end else if (read_data_valid) begin
                    read_data_valid <= 0;
                    temp_0 <= data_buffer[ptr];
                    out_valid <= 1;
                end else if (out_valid) begin
                    out_valid <= 0;
                end
                response_real <= 48'sd0;
                response_image <= 48'sd0;
                temp_new_real <= 32'sd0;
                temp_new_image <= 32'sd0;
                temp_old_real <= 32'sd0;
                temp_old_image <= 32'sd0;               
            end
            6'd1: begin
                if (cnt == 0) begin
                    temp_new_real <= in * new_cos_E2;
                    temp_new_image <= in * new_sin_E2;
                    temp_old_real <= delay_data * old_cos_E2;
                    temp_old_image <= delay_data * old_sin_E2;
                    cnt <= 1;
                end else if (cnt == 1) begin
                    response_real <= response_real_E2 + temp_new_real - temp_old_real;
                    response_image <= response_image_E2 + temp_new_image - temp_old_image;
                    cnt <= 2;
                end else if (cnt == 2) begin
                    response_real_E2 <= leak_response_real;
                    response_image_E2 <= leak_response_image;
                    amp_sq_E2 <= amp_sq;
                    state <= state + 1;
                    cnt <= 0;
                end
            end
            6'd2: begin
                if (cnt == 0) begin
                    temp_new_real <= in * new_cos_F2;
                    temp_new_image <= in * new_sin_F2;
                    temp_old_real <= delay_data * old_cos_F2;
                    temp_old_image <= delay_data * old_sin_F2;
                    cnt <= 1;
                end else if (cnt == 1) begin
                    response_real <= response_real_F2 + temp_new_real - temp_old_real;
                    response_image <= response_image_F2 + temp_new_image - temp_old_image;
                    cnt <= 2;
                end else if (cnt == 2) begin
                    response_real_F2 <= leak_response_real;
                    response_image_F2 <= leak_response_image;
                    amp_sq_F2 <= amp_sq;
                    state <= state + 1;
                    cnt <= 0;
                end
            end
            6'd3: begin
                if (cnt == 0) begin
                    temp_new_real <= in * new_cos_Fs2;
                    temp_new_image <= in * new_sin_Fs2;
                    temp_old_real <= delay_data * old_cos_Fs2;
                    temp_old_image <= delay_data * old_sin_Fs2;
                    cnt <= 1;
                end else if (cnt == 1) begin
                    response_real <= response_real_Fs2 + temp_new_real - temp_old_real;
                    response_image <= response_image_Fs2 + temp_new_image - temp_old_image;
                    cnt <= 2;
                end else if (cnt == 2) begin
                    response_real_Fs2 <= leak_response_real;
                    response_image_Fs2 <= leak_response_image;
                    amp_sq_Fs2 <= amp_sq;
                    state <= state + 1;
                    cnt <= 0;
                end
            end
            6'd4: begin
                if (cnt == 0) begin
                    temp_new_real <= in * new_cos_G2;
                    temp_new_image <= in * new_sin_G2;
                    temp_old_real <= delay_data * old_cos_G2;
                    temp_old_image <= delay_data * old_sin_G2;
                    cnt <= 1;
                end else if (cnt == 1) begin
                    response_real <= response_real_G2 + temp_new_real - temp_old_real;
                    response_image <= response_image_G2 + temp_new_image - temp_old_image;
                    cnt <= 2;
                end else if (cnt == 2) begin
                    response_real_G2 <= leak_response_real;
                    response_image_G2 <= leak_response_image;
                    amp_sq_G2 <= amp_sq;
                    state <= state + 1;
                    cnt <= 0;
                end
            end
            6'd5: begin
                if (cnt == 0) begin
                    temp_new_real <= in * new_cos_Gs2;
                    temp_new_image <= in * new_sin_Gs2;
                    temp_old_real <= delay_data * old_cos_Gs2;
                    temp_old_image <= delay_data * old_sin_Gs2;
                    cnt <= 1;
                end else if (cnt == 1) begin
                    response_real <= response_real_Gs2 + temp_new_real - temp_old_real;
                    response_image <= response_image_Gs2 + temp_new_image - temp_old_image;
                    cnt <= 2;
                end else if (cnt == 2) begin
                    response_real_Gs2 <= leak_response_real;
                    response_image_Gs2 <= leak_response_image;
                    amp_sq_Gs2 <= amp_sq;
                    state <= state + 1;
                    cnt <= 0;
                end
            end
            6'd6: begin
                if (cnt == 0) begin
                    temp_new_real <= in * new_cos_A2;
                    temp_new_image <= in * new_sin_A2;
                    temp_old_real <= delay_data * old_cos_A2;
                    temp_old_image <= delay_data * old_sin_A2;
                    cnt <= 1;
                end else if (cnt == 1) begin
                    response_real <= response_real_A2 + temp_new_real - temp_old_real;
                    response_image <= response_image_A2 + temp_new_image - temp_old_image;
                    cnt <= 2;
                end else if (cnt == 2) begin
                    response_real_A2 <= leak_response_real;
                    response_image_A2 <= leak_response_image;
                    amp_sq_A2 <= amp_sq;
                    state <= state + 1;
                    cnt <= 0;
                end
            end
            6'd7: begin
                if (cnt == 0) begin
                    temp_new_real <= in * new_cos_As2;
                    temp_new_image <= in * new_sin_As2;
                    temp_old_real <= delay_data * old_cos_As2;
                    temp_old_image <= delay_data * old_sin_As2;
                    cnt <= 1;
                end else if (cnt == 1) begin
                    response_real <= response_real_As2 + temp_new_real - temp_old_real;
                    response_image <= response_image_As2 + temp_new_image - temp_old_image;
                    cnt <= 2;
                end else if (cnt == 2) begin
                    response_real_As2 <= leak_response_real;
                    response_image_As2 <= leak_response_image;
                    amp_sq_As2 <= amp_sq;
                    state <= state + 1;
                    cnt <= 0;
                end
            end
            6'd8: begin
                if (cnt == 0) begin
                    temp_new_real <= in * new_cos_B2;
                    temp_new_image <= in * new_sin_B2;
                    temp_old_real <= delay_data * old_cos_B2;
                    temp_old_image <= delay_data * old_sin_B2;
                    cnt <= 1;
                end else if (cnt == 1) begin
                    response_real <= response_real_B2 + temp_new_real - temp_old_real;
                    response_image <= response_image_B2 + temp_new_image - temp_old_image;
                    cnt <= 2;
                end else if (cnt == 2) begin
                    response_real_B2 <= leak_response_real;
                    response_image_B2 <= leak_response_image;
                    amp_sq_B2 <= amp_sq;
                    state <= state + 1;
                    cnt <= 0;
                end
            end
            6'd9: begin
                if (cnt == 0) begin
                    temp_new_real <= in * new_cos_C3;
                    temp_new_image <= in * new_sin_C3;
                    temp_old_real <= delay_data * old_cos_C3;
                    temp_old_image <= delay_data * old_sin_C3;
                    cnt <= 1;
                end else if (cnt == 1) begin
                    response_real <= response_real_C3 + temp_new_real - temp_old_real;
                    response_image <= response_image_C3 + temp_new_image - temp_old_image;
                    cnt <= 2;
                end else if (cnt == 2) begin
                    response_real_C3 <= leak_response_real;
                    response_image_C3 <= leak_response_image;
                    amp_sq_C3 <= amp_sq;
                    state <= state + 1;
                    cnt <= 0;
                end
            end
            6'd10: begin
                if (cnt == 0) begin
                    temp_new_real <= in * new_cos_Cs3;
                    temp_new_image <= in * new_sin_Cs3;
                    temp_old_real <= delay_data * old_cos_Cs3;
                    temp_old_image <= delay_data * old_sin_Cs3;
                    cnt <= 1;
                end else if (cnt == 1) begin
                    response_real <= response_real_Cs3 + temp_new_real - temp_old_real;
                    response_image <= response_image_Cs3 + temp_new_image - temp_old_image;
                    cnt <= 2;
                end else if (cnt == 2) begin
                    response_real_Cs3 <= leak_response_real;
                    response_image_Cs3 <= leak_response_image;
                    amp_sq_Cs3 <= amp_sq;
                    state <= state + 1;
                    cnt <= 0;
                end
            end
            6'd11: begin
                if (cnt == 0) begin
                    temp_new_real <= in * new_cos_D3;
                    temp_new_image <= in * new_sin_D3;
                    temp_old_real <= delay_data * old_cos_D3;
                    temp_old_image <= delay_data * old_sin_D3;
                    cnt <= 1;
                end else if (cnt == 1) begin
                    response_real <= response_real_D3 + temp_new_real - temp_old_real;
                    response_image <= response_image_D3 + temp_new_image - temp_old_image;
                    cnt <= 2;
                end else if (cnt == 2) begin
                    response_real_D3 <= leak_response_real;
                    response_image_D3 <= leak_response_image;
                    amp_sq_D3 <= amp_sq;
                    state <= state + 1;
                    cnt <= 0;
                end
            end
            6'd12: begin
                if (cnt == 0) begin
                    temp_new_real <= in * new_cos_Ds3;
                    temp_new_image <= in * new_sin_Ds3;
                    temp_old_real <= delay_data * old_cos_Ds3;
                    temp_old_image <= delay_data * old_sin_Ds3;
                    cnt <= 1;
                end else if (cnt == 1) begin
                    response_real <= response_real_Ds3 + temp_new_real - temp_old_real;
                    response_image <= response_image_Ds3 + temp_new_image - temp_old_image;
                    cnt <= 2;
                end else if (cnt == 2) begin
                    response_real_Ds3 <= leak_response_real;
                    response_image_Ds3 <= leak_response_image;
                    amp_sq_Ds3 <= amp_sq;
                    state <= state + 1;
                    cnt <= 0;
                end
            end
            6'd13: begin
                if (cnt == 0) begin
                    temp_new_real <= in * new_cos_E3;
                    temp_new_image <= in * new_sin_E3;
                    temp_old_real <= delay_data * old_cos_E3;
                    temp_old_image <= delay_data * old_sin_E3;
                    cnt <= 1;
                end else if (cnt == 1) begin
                    response_real <= response_real_E3 + temp_new_real - temp_old_real;
                    response_image <= response_image_E3 + temp_new_image - temp_old_image;
                    cnt <= 2;
                end else if (cnt == 2) begin
                    response_real_E3 <= leak_response_real;
                    response_image_E3 <= leak_response_image;
                    amp_sq_E3 <= amp_sq;
                    state <= state + 1;
                    cnt <= 0;
                end
            end
            6'd14: begin
                if (cnt == 0) begin
                    temp_new_real <= in * new_cos_F3;
                    temp_new_image <= in * new_sin_F3;
                    temp_old_real <= delay_data * old_cos_F3;
                    temp_old_image <= delay_data * old_sin_F3;
                    cnt <= 1;
                end else if (cnt == 1) begin
                    response_real <= response_real_F3 + temp_new_real - temp_old_real;
                    response_image <= response_image_F3 + temp_new_image - temp_old_image;
                    cnt <= 2;
                end else if (cnt == 2) begin
                    response_real_F3 <= leak_response_real;
                    response_image_F3 <= leak_response_image;
                    amp_sq_F3 <= amp_sq;
                    state <= state + 1;
                    cnt <= 0;
                end
            end
            6'd15: begin
                if (cnt == 0) begin
                    temp_new_real <= in * new_cos_Fs3;
                    temp_new_image <= in * new_sin_Fs3;
                    temp_old_real <= delay_data * old_cos_Fs3;
                    temp_old_image <= delay_data * old_sin_Fs3;
                    cnt <= 1;
                end else if (cnt == 1) begin
                    response_real <= response_real_Fs3 + temp_new_real - temp_old_real;
                    response_image <= response_image_Fs3 + temp_new_image - temp_old_image;
                    cnt <= 2;
                end else if (cnt == 2) begin
                    response_real_Fs3 <= leak_response_real;
                    response_image_Fs3 <= leak_response_image;
                    amp_sq_Fs3 <= amp_sq;
                    state <= state + 1;
                    cnt <= 0;
                end
            end
            6'd16: begin
                if (cnt == 0) begin
                    temp_new_real <= in * new_cos_G3;
                    temp_new_image <= in * new_sin_G3;
                    temp_old_real <= delay_data * old_cos_G3;
                    temp_old_image <= delay_data * old_sin_G3;
                    cnt <= 1;
                end else if (cnt == 1) begin
                    response_real <= response_real_G3 + temp_new_real - temp_old_real;
                    response_image <= response_image_G3 + temp_new_image - temp_old_image;
                    cnt <= 2;
                end else if (cnt == 2) begin
                    response_real_G3 <= leak_response_real;
                    response_image_G3 <= leak_response_image;
                    amp_sq_G3 <= amp_sq;
                    state <= state + 1;
                    cnt <= 0;
                end
            end
            6'd17: begin
                if (cnt == 0) begin
                    temp_new_real <= in * new_cos_Gs3;
                    temp_new_image <= in * new_sin_Gs3;
                    temp_old_real <= delay_data * old_cos_Gs3;
                    temp_old_image <= delay_data * old_sin_Gs3;
                    cnt <= 1;
                end else if (cnt == 1) begin
                    response_real <= response_real_Gs3 + temp_new_real - temp_old_real;
                    response_image <= response_image_Gs3 + temp_new_image - temp_old_image;
                    cnt <= 2;
                end else if (cnt == 2) begin
                    response_real_Gs3 <= leak_response_real;
                    response_image_Gs3 <= leak_response_image;
                    amp_sq_Gs3 <= amp_sq;
                    state <= state + 1;
                    cnt <= 0;
                end
            end
            6'd18: begin
                if (cnt == 0) begin
                    temp_new_real <= in * new_cos_A3;
                    temp_new_image <= in * new_sin_A3;
                    temp_old_real <= delay_data * old_cos_A3;
                    temp_old_image <= delay_data * old_sin_A3;
                    cnt <= 1;
                end else if (cnt == 1) begin
                    response_real <= response_real_A3 + temp_new_real - temp_old_real;
                    response_image <= response_image_A3 + temp_new_image - temp_old_image;
                    cnt <= 2;
                end else if (cnt == 2) begin
                    response_real_A3 <= leak_response_real;
                    response_image_A3 <= leak_response_image;
                    amp_sq_A3 <= amp_sq;
                    state <= state + 1;
                    cnt <= 0;
                end
            end
            6'd19: begin
                if (cnt == 0) begin
                    temp_new_real <= in * new_cos_As3;
                    temp_new_image <= in * new_sin_As3;
                    temp_old_real <= delay_data * old_cos_As3;
                    temp_old_image <= delay_data * old_sin_As3;
                    cnt <= 1;
                end else if (cnt == 1) begin
                    response_real <= response_real_As3 + temp_new_real - temp_old_real;
                    response_image <= response_image_As3 + temp_new_image - temp_old_image;
                    cnt <= 2;
                end else if (cnt == 2) begin
                    response_real_As3 <= leak_response_real;
                    response_image_As3 <= leak_response_image;
                    amp_sq_As3 <= amp_sq;
                    state <= state + 1;
                    cnt <= 0;
                end
            end
            6'd20: begin
                if (cnt == 0) begin
                    temp_new_real <= in * new_cos_B3;
                    temp_new_image <= in * new_sin_B3;
                    temp_old_real <= delay_data * old_cos_B3;
                    temp_old_image <= delay_data * old_sin_B3;
                    cnt <= 1;
                end else if (cnt == 1) begin
                    response_real <= response_real_B3 + temp_new_real - temp_old_real;
                    response_image <= response_image_B3 + temp_new_image - temp_old_image;
                    cnt <= 2;
                end else if (cnt == 2) begin
                    response_real_B3 <= leak_response_real;
                    response_image_B3 <= leak_response_image;
                    amp_sq_B3 <= amp_sq;
                    state <= state + 1;
                    cnt <= 0;
                end
            end
            6'd21: begin
                if (cnt == 0) begin
                    temp_new_real <= in * new_cos_C4;
                    temp_new_image <= in * new_sin_C4;
                    temp_old_real <= delay_data * old_cos_C4;
                    temp_old_image <= delay_data * old_sin_C4;
                    cnt <= 1;
                end else if (cnt == 1) begin
                    response_real <= response_real_C4 + temp_new_real - temp_old_real;
                    response_image <= response_image_C4 + temp_new_image - temp_old_image;
                    cnt <= 2;
                end else if (cnt == 2) begin
                    response_real_C4 <= leak_response_real;
                    response_image_C4 <= leak_response_image;
                    amp_sq_C4 <= amp_sq;
                    state <= state + 1;
                    cnt <= 0;
                end
            end
            6'd22: begin
                if (cnt == 0) begin
                    temp_new_real <= in * new_cos_Cs4;
                    temp_new_image <= in * new_sin_Cs4;
                    temp_old_real <= delay_data * old_cos_Cs4;
                    temp_old_image <= delay_data * old_sin_Cs4;
                    cnt <= 1;
                end else if (cnt == 1) begin
                    response_real <= response_real_Cs4 + temp_new_real - temp_old_real;
                    response_image <= response_image_Cs4 + temp_new_image - temp_old_image;
                    cnt <= 2;
                end else if (cnt == 2) begin
                    response_real_Cs4 <= leak_response_real;
                    response_image_Cs4 <= leak_response_image;
                    amp_sq_Cs4 <= amp_sq;
                    state <= state + 1;
                    cnt <= 0;
                end
            end
            6'd23: begin
                if (cnt == 0) begin
                    temp_new_real <= in * new_cos_D4;
                    temp_new_image <= in * new_sin_D4;
                    temp_old_real <= delay_data * old_cos_D4;
                    temp_old_image <= delay_data * old_sin_D4;
                    cnt <= 1;
                end else if (cnt == 1) begin
                    response_real <= response_real_D4 + temp_new_real - temp_old_real;
                    response_image <= response_image_D4 + temp_new_image - temp_old_image;
                    cnt <= 2;
                end else if (cnt == 2) begin
                    response_real_D4 <= leak_response_real;
                    response_image_D4 <= leak_response_image;
                    amp_sq_D4 <= amp_sq;
                    state <= state + 1;
                    cnt <= 0;
                end
            end
            6'd24: begin
                if (cnt == 0) begin
                    temp_new_real <= in * new_cos_Ds4;
                    temp_new_image <= in * new_sin_Ds4;
                    temp_old_real <= delay_data * old_cos_Ds4;
                    temp_old_image <= delay_data * old_sin_Ds4;
                    cnt <= 1;
                end else if (cnt == 1) begin
                    response_real <= response_real_Ds4 + temp_new_real - temp_old_real;
                    response_image <= response_image_Ds4 + temp_new_image - temp_old_image;
                    cnt <= 2;
                end else if (cnt == 2) begin
                    response_real_Ds4 <= leak_response_real;
                    response_image_Ds4 <= leak_response_image;
                    amp_sq_Ds4 <= amp_sq;
                    state <= state + 1;
                    cnt <= 0;
                end
            end
            6'd25: begin
                if (cnt == 0) begin
                    temp_new_real <= in * new_cos_E4;
                    temp_new_image <= in * new_sin_E4;
                    temp_old_real <= delay_data * old_cos_E4;
                    temp_old_image <= delay_data * old_sin_E4;
                    cnt <= 1;
                end else if (cnt == 1) begin
                    response_real <= response_real_E4 + temp_new_real - temp_old_real;
                    response_image <= response_image_E4 + temp_new_image - temp_old_image;
                    cnt <= 2;
                end else if (cnt == 2) begin
                    response_real_E4 <= leak_response_real;
                    response_image_E4 <= leak_response_image;
                    amp_sq_E4 <= amp_sq;
                    state <= state + 1;
                    cnt <= 0;
                end
            end
            6'd26: begin
                if (cnt == 0) begin
                    temp_new_real <= in * new_cos_F4;
                    temp_new_image <= in * new_sin_F4;
                    temp_old_real <= delay_data * old_cos_F4;
                    temp_old_image <= delay_data * old_sin_F4;
                    cnt <= 1;
                end else if (cnt == 1) begin
                    response_real <= response_real_F4 + temp_new_real - temp_old_real;
                    response_image <= response_image_F4 + temp_new_image - temp_old_image;
                    cnt <= 2;
                end else if (cnt == 2) begin
                    response_real_F4 <= leak_response_real;
                    response_image_F4 <= leak_response_image;
                    amp_sq_F4 <= amp_sq;
                    state <= state + 1;
                    cnt <= 0;
                end
            end
            6'd27: begin
                if (cnt == 0) begin
                    temp_new_real <= in * new_cos_Fs4;
                    temp_new_image <= in * new_sin_Fs4;
                    temp_old_real <= delay_data * old_cos_Fs4;
                    temp_old_image <= delay_data * old_sin_Fs4;
                    cnt <= 1;
                end else if (cnt == 1) begin
                    response_real <= response_real_Fs4 + temp_new_real - temp_old_real;
                    response_image <= response_image_Fs4 + temp_new_image - temp_old_image;
                    cnt <= 2;
                end else if (cnt == 2) begin
                    response_real_Fs4 <= leak_response_real;
                    response_image_Fs4 <= leak_response_image;
                    amp_sq_Fs4 <= amp_sq;
                    state <= state + 1;
                    cnt <= 0;
                end
            end
            6'd28: begin
                if (cnt == 0) begin
                    temp_new_real <= in * new_cos_G4;
                    temp_new_image <= in * new_sin_G4;
                    temp_old_real <= delay_data * old_cos_G4;
                    temp_old_image <= delay_data * old_sin_G4;
                    cnt <= 1;
                end else if (cnt == 1) begin
                    response_real <= response_real_G4 + temp_new_real - temp_old_real;
                    response_image <= response_image_G4 + temp_new_image - temp_old_image;
                    cnt <= 2;
                end else if (cnt == 2) begin
                    response_real_G4 <= leak_response_real;
                    response_image_G4 <= leak_response_image;
                    amp_sq_G4 <= amp_sq;
                    state <= state + 1;
                    cnt <= 0;
                end
            end
            6'd29: begin
                if (cnt == 0) begin
                    temp_new_real <= in * new_cos_Gs4;
                    temp_new_image <= in * new_sin_Gs4;
                    temp_old_real <= delay_data * old_cos_Gs4;
                    temp_old_image <= delay_data * old_sin_Gs4;
                    cnt <= 1;
                end else if (cnt == 1) begin
                    response_real <= response_real_Gs4 + temp_new_real - temp_old_real;
                    response_image <= response_image_Gs4 + temp_new_image - temp_old_image;
                    cnt <= 2;
                end else if (cnt == 2) begin
                    response_real_Gs4 <= leak_response_real;
                    response_image_Gs4 <= leak_response_image;
                    amp_sq_Gs4 <= amp_sq;
                    state <= state + 1;
                    cnt <= 0;
                end
            end
            6'd30: begin
                if (cnt == 0) begin
                    temp_new_real <= in * new_cos_A4;
                    temp_new_image <= in * new_sin_A4;
                    temp_old_real <= delay_data * old_cos_A4;
                    temp_old_image <= delay_data * old_sin_A4;
                    cnt <= 1;
                end else if (cnt == 1) begin
                    response_real <= response_real_A4 + temp_new_real - temp_old_real;
                    response_image <= response_image_A4 + temp_new_image - temp_old_image;
                    cnt <= 2;
                end else if (cnt == 2) begin
                    response_real_A4 <= leak_response_real;
                    response_image_A4 <= leak_response_image;
                    amp_sq_A4 <= amp_sq;
                    state <= state + 1;
                    cnt <= 0;
                end
            end
            6'd31: begin
                if (cnt == 0) begin
                    temp_new_real <= in * new_cos_As4;
                    temp_new_image <= in * new_sin_As4;
                    temp_old_real <= delay_data * old_cos_As4;
                    temp_old_image <= delay_data * old_sin_As4;
                    cnt <= 1;
                end else if (cnt == 1) begin
                    response_real <= response_real_As4 + temp_new_real - temp_old_real;
                    response_image <= response_image_As4 + temp_new_image - temp_old_image;
                    cnt <= 2;
                end else if (cnt == 2) begin
                    response_real_As4 <= leak_response_real;
                    response_image_As4 <= leak_response_image;
                    amp_sq_As4 <= amp_sq;
                    state <= state + 1;
                    cnt <= 0;
                end
            end
            6'd32: begin
                if (cnt == 0) begin
                    temp_new_real <= in * new_cos_B4;
                    temp_new_image <= in * new_sin_B4;
                    temp_old_real <= delay_data * old_cos_B4;
                    temp_old_image <= delay_data * old_sin_B4;
                    cnt <= 1;
                end else if (cnt == 1) begin
                    response_real <= response_real_B4 + temp_new_real - temp_old_real;
                    response_image <= response_image_B4 + temp_new_image - temp_old_image;
                    cnt <= 2;
                end else if (cnt == 2) begin
                    response_real_B4 <= leak_response_real;
                    response_image_B4 <= leak_response_image;
                    amp_sq_B4 <= amp_sq;
                    state <= state + 1;
                    cnt <= 0;
                end
            end
            6'd33: begin
                if (cnt == 0) begin
                    temp_new_real <= in * new_cos_C5;
                    temp_new_image <= in * new_sin_C5;
                    temp_old_real <= delay_data * old_cos_C5;
                    temp_old_image <= delay_data * old_sin_C5;
                    cnt <= 1;
                end else if (cnt == 1) begin
                    response_real <= response_real_C5 + temp_new_real - temp_old_real;
                    response_image <= response_image_C5 + temp_new_image - temp_old_image;
                    cnt <= 2;
                end else if (cnt == 2) begin
                    response_real_C5 <= leak_response_real;
                    response_image_C5 <= leak_response_image;
                    amp_sq_C5 <= amp_sq;
                    state <= state + 1;
                    cnt <= 0;
                end
            end
            6'd34: begin
                if (cnt == 0) begin
                    temp_new_real <= in * new_cos_Cs5;
                    temp_new_image <= in * new_sin_Cs5;
                    temp_old_real <= delay_data * old_cos_Cs5;
                    temp_old_image <= delay_data * old_sin_Cs5;
                    cnt <= 1;
                end else if (cnt == 1) begin
                    response_real <= response_real_Cs5 + temp_new_real - temp_old_real;
                    response_image <= response_image_Cs5 + temp_new_image - temp_old_image;
                    cnt <= 2;
                end else if (cnt == 2) begin
                    response_real_Cs5 <= leak_response_real;
                    response_image_Cs5 <= leak_response_image;
                    amp_sq_Cs5 <= amp_sq;
                    state <= state + 1;
                    cnt <= 0;
                end
            end
            6'd35: begin
                if (cnt == 0) begin
                    temp_new_real <= in * new_cos_D5;
                    temp_new_image <= in * new_sin_D5;
                    temp_old_real <= delay_data * old_cos_D5;
                    temp_old_image <= delay_data * old_sin_D5;
                    cnt <= 1;
                end else if (cnt == 1) begin
                    response_real <= response_real_D5 + temp_new_real - temp_old_real;
                    response_image <= response_image_D5 + temp_new_image - temp_old_image;
                    cnt <= 2;
                end else if (cnt == 2) begin
                    response_real_D5 <= leak_response_real;
                    response_image_D5 <= leak_response_image;
                    amp_sq_D5 <= amp_sq;
                    state <= state + 1;
                    cnt <= 0;
                end
            end
            6'd36: begin
                if (cnt == 0) begin
                    temp_new_real <= in * new_cos_Ds5;
                    temp_new_image <= in * new_sin_Ds5;
                    temp_old_real <= delay_data * old_cos_Ds5;
                    temp_old_image <= delay_data * old_sin_Ds5;
                    cnt <= 1;
                end else if (cnt == 1) begin
                    response_real <= response_real_Ds5 + temp_new_real - temp_old_real;
                    response_image <= response_image_Ds5 + temp_new_image - temp_old_image;
                    cnt <= 2;
                end else if (cnt == 2) begin
                    response_real_Ds5 <= leak_response_real;
                    response_image_Ds5 <= leak_response_image;
                    amp_sq_Ds5 <= amp_sq;
                    state <= 0;
                    cnt <= 0;
                    read_data_valid <= 1;
                end
            end
        endcase
    end
end

endmodule