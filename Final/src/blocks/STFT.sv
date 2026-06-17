module STFT (
    input clk,
    input rst,
    input in_valid,
    input signed [15:0] in,
    output out_valid,
    output [] amp_sq_E2,
    output [] amp_sq_F2,
    output [] amp_sq_Fs2,
    output [] amp_sq_G2,
    output [] amp_sq_Gs2,
    output [] amp_sq_A2,
    output [] amp_sq_As2,
    output [] amp_sq_B2,
    output [] amp_sq_C3,
    output [] amp_sq_Cs3,
    output [] amp_sq_D3,
    output [] amp_sq_Ds3,
    output [] amp_sq_E3,
    output [] amp_sq_F3,
    output [] amp_sq_Fs3,
    output [] amp_sq_G3,
    output [] amp_sq_Gs3,
    output [] amp_sq_A3,
    output [] amp_sq_As3,
    output [] amp_sq_B3,
    output [] amp_sq_C4,
    output [] amp_sq_Cs4,
    output [] amp_sq_D4,
    output [] amp_sq_Ds4,
    output [] amp_sq_E4,
    output [] amp_sq_F4,
    output [] amp_sq_Fs4,
    output [] amp_sq_G4,
    output [] amp_sq_Gs4,
    output [] amp_sq_A4,
    output [] amp_sq_As4,
    output [] amp_sq_B4,
    output [] amp_sq_C5,
    output [] amp_sq_Cs5,
    output [] amp_sq_D5,
    output [] amp_sq_Ds5
);

endmodule

module STFT_LUT (
    input  clk,
    input  rst,
    input  in_valid,
    output out_valid,

    output signed [15:0] new_cos_E2,
    output signed [15:0] new_cos_F2,
    output signed [15:0] new_cos_Fs2,
    output signed [15:0] new_cos_G2,
    output signed [15:0] new_cos_Gs2,
    output signed [15:0] new_cos_A2,
    output signed [15:0] new_cos_As2,
    output signed [15:0] new_cos_B2,
    output signed [15:0] new_cos_C3,
    output signed [15:0] new_cos_Cs3,
    output signed [15:0] new_cos_D3,
    output signed [15:0] new_cos_Ds3,
    output signed [15:0] new_cos_E3,
    output signed [15:0] new_cos_F3,
    output signed [15:0] new_cos_Fs3,
    output signed [15:0] new_cos_G3,
    output signed [15:0] new_cos_Gs3,
    output signed [15:0] new_cos_A3,
    output signed [15:0] new_cos_As3,
    output signed [15:0] new_cos_B3,
    output signed [15:0] new_cos_C4,
    output signed [15:0] new_cos_Cs4,
    output signed [15:0] new_cos_D4,
    output signed [15:0] new_cos_Ds4,
    output signed [15:0] new_cos_E4,
    output signed [15:0] new_cos_F4,
    output signed [15:0] new_cos_Fs4,
    output signed [15:0] new_cos_G4,
    output signed [15:0] new_cos_Gs4,
    output signed [15:0] new_cos_A4,
    output signed [15:0] new_cos_As4,
    output signed [15:0] new_cos_B4,
    output signed [15:0] new_cos_C5,
    output signed [15:0] new_cos_Cs5,
    output signed [15:0] new_cos_D5,
    output signed [15:0] new_cos_Ds5,

    output signed [15:0] new_sin_E2,
    output signed [15:0] new_sin_F2,
    output signed [15:0] new_sin_Fs2,
    output signed [15:0] new_sin_G2,
    output signed [15:0] new_sin_Gs2,
    output signed [15:0] new_sin_A2,
    output signed [15:0] new_sin_As2,
    output signed [15:0] new_sin_B2,
    output signed [15:0] new_sin_C3,
    output signed [15:0] new_sin_Cs3,
    output signed [15:0] new_sin_D3,
    output signed [15:0] new_sin_Ds3,
    output signed [15:0] new_sin_E3,
    output signed [15:0] new_sin_F3,
    output signed [15:0] new_sin_Fs3,
    output signed [15:0] new_sin_G3,
    output signed [15:0] new_sin_Gs3,
    output signed [15:0] new_sin_A3,
    output signed [15:0] new_sin_As3,
    output signed [15:0] new_sin_B3,
    output signed [15:0] new_sin_C4,
    output signed [15:0] new_sin_Cs4,
    output signed [15:0] new_sin_D4,
    output signed [15:0] new_sin_Ds4,
    output signed [15:0] new_sin_E4,
    output signed [15:0] new_sin_F4,
    output signed [15:0] new_sin_Fs4,
    output signed [15:0] new_sin_G4,
    output signed [15:0] new_sin_Gs4,
    output signed [15:0] new_sin_A4,
    output signed [15:0] new_sin_As4,
    output signed [15:0] new_sin_B4,
    output signed [15:0] new_sin_C5,
    output signed [15:0] new_sin_Cs5,
    output signed [15:0] new_sin_D5,
    output signed [15:0] new_sin_Ds5,

    output signed [15:0] old_cos_E2,
    output signed [15:0] old_cos_F2,
    output signed [15:0] old_cos_Fs2,
    output signed [15:0] old_cos_G2,
    output signed [15:0] old_cos_Gs2,
    output signed [15:0] old_cos_A2,
    output signed [15:0] old_cos_As2,
    output signed [15:0] old_cos_B2,
    output signed [15:0] old_cos_C3,
    output signed [15:0] old_cos_Cs3,
    output signed [15:0] old_cos_D3,
    output signed [15:0] old_cos_Ds3,
    output signed [15:0] old_cos_E3,
    output signed [15:0] old_cos_F3,
    output signed [15:0] old_cos_Fs3,
    output signed [15:0] old_cos_G3,
    output signed [15:0] old_cos_Gs3,
    output signed [15:0] old_cos_A3,
    output signed [15:0] old_cos_As3,
    output signed [15:0] old_cos_B3,
    output signed [15:0] old_cos_C4,
    output signed [15:0] old_cos_Cs4,
    output signed [15:0] old_cos_D4,
    output signed [15:0] old_cos_Ds4,
    output signed [15:0] old_cos_E4,
    output signed [15:0] old_cos_F4,
    output signed [15:0] old_cos_Fs4,
    output signed [15:0] old_cos_G4,
    output signed [15:0] old_cos_Gs4,
    output signed [15:0] old_cos_A4,
    output signed [15:0] old_cos_As4,
    output signed [15:0] old_cos_B4,
    output signed [15:0] old_cos_C5,
    output signed [15:0] old_cos_Cs5,
    output signed [15:0] old_cos_D5,
    output signed [15:0] old_cos_Ds5,

    output signed [15:0] old_sin_E2,
    output signed [15:0] old_sin_F2,
    output signed [15:0] old_sin_Fs2,
    output signed [15:0] old_sin_G2,
    output signed [15:0] old_sin_Gs2,
    output signed [15:0] old_sin_A2,
    output signed [15:0] old_sin_As2,
    output signed [15:0] old_sin_B2,
    output signed [15:0] old_sin_C3,
    output signed [15:0] old_sin_Cs3,
    output signed [15:0] old_sin_D3,
    output signed [15:0] old_sin_Ds3,
    output signed [15:0] old_sin_E3,
    output signed [15:0] old_sin_F3,
    output signed [15:0] old_sin_Fs3,
    output signed [15:0] old_sin_G3,
    output signed [15:0] old_sin_Gs3,
    output signed [15:0] old_sin_A3,
    output signed [15:0] old_sin_As3,
    output signed [15:0] old_sin_B3,
    output signed [15:0] old_sin_C4,
    output signed [15:0] old_sin_Cs4,
    output signed [15:0] old_sin_D4,
    output signed [15:0] old_sin_Ds4,
    output signed [15:0] old_sin_E4,
    output signed [15:0] old_sin_F4,
    output signed [15:0] old_sin_Fs4,
    output signed [15:0] old_sin_G4,
    output signed [15:0] old_sin_Gs4,
    output signed [15:0] old_sin_A4,
    output signed [15:0] old_sin_As4,
    output signed [15:0] old_sin_B4,
    output signed [15:0] old_sin_C5,
    output signed [15:0] old_sin_Cs5,
    output signed [15:0] old_sin_D5,
    output signed [15:0] old_sin_Ds5
);

localparam [15:0] f_discrete_E2  = 16'h1C21;
localparam [15:0] f_discrete_F2  = 16'h1DCD;
localparam [15:0] f_discrete_Fs2 = 16'h1F93;
localparam [15:0] f_discrete_G2  = 16'h2173;
localparam [15:0] f_discrete_Gs2 = 16'h2370;
localparam [15:0] f_discrete_A2  = 16'h258C;
localparam [15:0] f_discrete_As2 = 16'h27C8;
localparam [15:0] f_discrete_B2  = 16'h2A25;
localparam [15:0] f_discrete_C3  = 16'h2CA7;
localparam [15:0] f_discrete_Cs3 = 16'h2F4E;
localparam [15:0] f_discrete_D3  = 16'h321E;
localparam [15:0] f_discrete_Ds3 = 16'h3519;
localparam [15:0] f_discrete_E3  = 16'h3842;
localparam [15:0] f_discrete_F3  = 16'h3B9A;
localparam [15:0] f_discrete_Fs3 = 16'h3F25;
localparam [15:0] f_discrete_G3  = 16'h42E7;
localparam [15:0] f_discrete_Gs3 = 16'h46E1;
localparam [15:0] f_discrete_A3  = 16'h4B18;
localparam [15:0] f_discrete_As3 = 16'h4F8F;
localparam [15:0] f_discrete_B3  = 16'h544A;
localparam [15:0] f_discrete_C4  = 16'h594D;
localparam [15:0] f_discrete_Cs4 = 16'h5E9D;
localparam [15:0] f_discrete_D4  = 16'h643D;
localparam [15:0] f_discrete_Ds4 = 16'h6A33;
localparam [15:0] f_discrete_E4  = 16'h7083;
localparam [15:0] f_discrete_F4  = 16'h7734;
localparam [15:0] f_discrete_Fs4 = 16'h7E4B;
localparam [15:0] f_discrete_G4  = 16'h85CD;
localparam [15:0] f_discrete_Gs4 = 16'h8DC2;
localparam [15:0] f_discrete_A4  = 16'h9630;
localparam [15:0] f_discrete_As4 = 16'h9F1E;
localparam [15:0] f_discrete_B4  = 16'hA894;
localparam [15:0] f_discrete_C5  = 16'hB29A;
localparam [15:0] f_discrete_Cs5 = 16'hBD39;
localparam [15:0] f_discrete_D5  = 16'hC87A;
localparam [15:0] f_discrete_Ds5 = 16'hD465;

localparam [21:0] L_f_discrete_E2  = 22'h1ECEE;
localparam [21:0] L_f_discrete_F2  = 22'h5D87C;
localparam [21:0] L_f_discrete_Fs2 = 22'h9FFB7;
localparam [21:0] L_f_discrete_G2  = 22'hE662B;
localparam [21:0] L_f_discrete_Gs2 = 22'h130F9A;
localparam [21:0] L_f_discrete_A2  = 22'h180000;
localparam [21:0] L_f_discrete_As2 = 22'h1D3B96;
localparam [21:0] L_f_discrete_B2  = 22'h22C6D3;
localparam [21:0] L_f_discrete_C3  = 22'h28A675;
localparam [21:0] L_f_discrete_Cs3 = 22'h2EDF80;
localparam [21:0] L_f_discrete_D3  = 22'h357746;
localparam [21:0] L_f_discrete_Ds3 = 22'h3C7367;
localparam [21:0] L_f_discrete_E3  = 22'h3D9DD;
localparam [21:0] L_f_discrete_F3  = 22'hBB0F9;
localparam [21:0] L_f_discrete_Fs3 = 22'h13FF6E;
localparam [21:0] L_f_discrete_G3  = 22'h1CCC55;
localparam [21:0] L_f_discrete_Gs3 = 22'h261F33;
localparam [21:0] L_f_discrete_A3  = 22'h300000;
localparam [21:0] L_f_discrete_As3 = 22'h3A772B;
localparam [21:0] L_f_discrete_B3  = 22'h58DA6;
localparam [21:0] L_f_discrete_C4  = 22'h114CEA;
localparam [21:0] L_f_discrete_Cs4 = 22'h1DBF01;
localparam [21:0] L_f_discrete_D4  = 22'h2AEE8B;
localparam [21:0] L_f_discrete_Ds4 = 22'h38E6CE;
localparam [21:0] L_f_discrete_E4  = 22'h7B3B9;
localparam [21:0] L_f_discrete_F4  = 22'h1761F1;
localparam [21:0] L_f_discrete_Fs4 = 22'h27FEDC;
localparam [21:0] L_f_discrete_G4  = 22'h3998AA;
localparam [21:0] L_f_discrete_Gs4 = 22'hC3E67;
localparam [21:0] L_f_discrete_A4  = 22'h200000;
localparam [21:0] L_f_discrete_As4 = 22'h34EE57;
localparam [21:0] L_f_discrete_B4  = 22'hB1B4D;
localparam [21:0] L_f_discrete_C5  = 22'h2299D5;
localparam [21:0] L_f_discrete_Cs5 = 22'h3B7E01;
localparam [21:0] L_f_discrete_D5  = 22'h15DD17;
localparam [21:0] L_f_discrete_Ds5 = 22'h31CD9D;

logic [21:0] new_rad_cos_E2 ;
logic [21:0] new_rad_cos_F2 ;
logic [21:0] new_rad_cos_Fs2;
logic [21:0] new_rad_cos_G2 ;
logic [21:0] new_rad_cos_Gs2;
logic [21:0] new_rad_cos_A2 ;
logic [21:0] new_rad_cos_As2;
logic [21:0] new_rad_cos_B2 ;
logic [21:0] new_rad_cos_C3 ;
logic [21:0] new_rad_cos_Cs3;
logic [21:0] new_rad_cos_D3 ;
logic [21:0] new_rad_cos_Ds3;
logic [21:0] new_rad_cos_E3 ;
logic [21:0] new_rad_cos_F3 ;
logic [21:0] new_rad_cos_Fs3;
logic [21:0] new_rad_cos_G3 ;
logic [21:0] new_rad_cos_Gs3;
logic [21:0] new_rad_cos_A3 ;
logic [21:0] new_rad_cos_As3;
logic [21:0] new_rad_cos_B3 ;
logic [21:0] new_rad_cos_C4 ;
logic [21:0] new_rad_cos_Cs4;
logic [21:0] new_rad_cos_D4 ;
logic [21:0] new_rad_cos_Ds4;
logic [21:0] new_rad_cos_E4 ;
logic [21:0] new_rad_cos_F4 ;
logic [21:0] new_rad_cos_Fs4;
logic [21:0] new_rad_cos_G4 ;
logic [21:0] new_rad_cos_Gs4;
logic [21:0] new_rad_cos_A4 ;
logic [21:0] new_rad_cos_As4;
logic [21:0] new_rad_cos_B4 ;
logic [21:0] new_rad_cos_C5 ;
logic [21:0] new_rad_cos_Cs5;
logic [21:0] new_rad_cos_D5 ;
logic [21:0] new_rad_cos_Ds5;

logic [21:0] new_rad_sin_E2 ;
logic [21:0] new_rad_sin_F2 ;
logic [21:0] new_rad_sin_Fs2;
logic [21:0] new_rad_sin_G2 ;
logic [21:0] new_rad_sin_Gs2;
logic [21:0] new_rad_sin_A2 ;
logic [21:0] new_rad_sin_As2;
logic [21:0] new_rad_sin_B2 ;
logic [21:0] new_rad_sin_C3 ;
logic [21:0] new_rad_sin_Cs3;
logic [21:0] new_rad_sin_D3 ;
logic [21:0] new_rad_sin_Ds3;
logic [21:0] new_rad_sin_E3 ;
logic [21:0] new_rad_sin_F3 ;
logic [21:0] new_rad_sin_Fs3;
logic [21:0] new_rad_sin_G3 ;
logic [21:0] new_rad_sin_Gs3;
logic [21:0] new_rad_sin_A3 ;
logic [21:0] new_rad_sin_As3;
logic [21:0] new_rad_sin_B3 ;
logic [21:0] new_rad_sin_C4 ;
logic [21:0] new_rad_sin_Cs4;
logic [21:0] new_rad_sin_D4 ;
logic [21:0] new_rad_sin_Ds4;
logic [21:0] new_rad_sin_E4 ;
logic [21:0] new_rad_sin_F4 ;
logic [21:0] new_rad_sin_Fs4;
logic [21:0] new_rad_sin_G4 ;
logic [21:0] new_rad_sin_Gs4;
logic [21:0] new_rad_sin_A4 ;
logic [21:0] new_rad_sin_As4;
logic [21:0] new_rad_sin_B4 ;
logic [21:0] new_rad_sin_C5 ;
logic [21:0] new_rad_sin_Cs5;
logic [21:0] new_rad_sin_D5 ;
logic [21:0] new_rad_sin_Ds5;

assign new_rad_sin_E2  = new_rad_cos_E2  - 22'h100000;
assign new_rad_sin_F2  = new_rad_cos_F2  - 22'h100000;
assign new_rad_sin_Fs2 = new_rad_cos_Fs2 - 22'h100000;
assign new_rad_sin_G2  = new_rad_cos_G2  - 22'h100000;
assign new_rad_sin_Gs2 = new_rad_cos_Gs2 - 22'h100000;
assign new_rad_sin_A2  = new_rad_cos_A2  - 22'h100000;
assign new_rad_sin_As2 = new_rad_cos_As2 - 22'h100000;
assign new_rad_sin_B2  = new_rad_cos_B2  - 22'h100000;
assign new_rad_sin_C3  = new_rad_cos_C3  - 22'h100000;
assign new_rad_sin_Cs3 = new_rad_cos_Cs3 - 22'h100000;
assign new_rad_sin_D3  = new_rad_cos_D3  - 22'h100000;
assign new_rad_sin_Ds3 = new_rad_cos_Ds3 - 22'h100000;
assign new_rad_sin_E3  = new_rad_cos_E3  - 22'h100000;
assign new_rad_sin_F3  = new_rad_cos_F3  - 22'h100000;
assign new_rad_sin_Fs3 = new_rad_cos_Fs3 - 22'h100000;
assign new_rad_sin_G3  = new_rad_cos_G3  - 22'h100000;
assign new_rad_sin_Gs3 = new_rad_cos_Gs3 - 22'h100000;
assign new_rad_sin_A3  = new_rad_cos_A3  - 22'h100000;
assign new_rad_sin_As3 = new_rad_cos_As3 - 22'h100000;
assign new_rad_sin_B3  = new_rad_cos_B3  - 22'h100000;
assign new_rad_sin_C4  = new_rad_cos_C4  - 22'h100000;
assign new_rad_sin_Cs4 = new_rad_cos_Cs4 - 22'h100000;
assign new_rad_sin_D4  = new_rad_cos_D4  - 22'h100000;
assign new_rad_sin_Ds4 = new_rad_cos_Ds4 - 22'h100000;
assign new_rad_sin_E4  = new_rad_cos_E4  - 22'h100000;
assign new_rad_sin_F4  = new_rad_cos_F4  - 22'h100000;
assign new_rad_sin_Fs4 = new_rad_cos_Fs4 - 22'h100000;
assign new_rad_sin_G4  = new_rad_cos_G4  - 22'h100000;
assign new_rad_sin_Gs4 = new_rad_cos_Gs4 - 22'h100000;
assign new_rad_sin_A4  = new_rad_cos_A4  - 22'h100000;
assign new_rad_sin_As4 = new_rad_cos_As4 - 22'h100000;
assign new_rad_sin_B4  = new_rad_cos_B4  - 22'h100000;
assign new_rad_sin_C5  = new_rad_cos_C5  - 22'h100000;
assign new_rad_sin_Cs5 = new_rad_cos_Cs5 - 22'h100000;
assign new_rad_sin_D5  = new_rad_cos_D5  - 22'h100000;
assign new_rad_sin_Ds5 = new_rad_cos_Ds5 - 22'h100000;

logic [21:0] old_rad_cos_E2 ;
logic [21:0] old_rad_cos_F2 ;
logic [21:0] old_rad_cos_Fs2;
logic [21:0] old_rad_cos_G2 ;
logic [21:0] old_rad_cos_Gs2;
logic [21:0] old_rad_cos_A2 ;
logic [21:0] old_rad_cos_As2;
logic [21:0] old_rad_cos_B2 ;
logic [21:0] old_rad_cos_C3 ;
logic [21:0] old_rad_cos_Cs3;
logic [21:0] old_rad_cos_D3 ;
logic [21:0] old_rad_cos_Ds3;
logic [21:0] old_rad_cos_E3 ;
logic [21:0] old_rad_cos_F3 ;
logic [21:0] old_rad_cos_Fs3;
logic [21:0] old_rad_cos_G3 ;
logic [21:0] old_rad_cos_Gs3;
logic [21:0] old_rad_cos_A3 ;
logic [21:0] old_rad_cos_As3;
logic [21:0] old_rad_cos_B3 ;
logic [21:0] old_rad_cos_C4 ;
logic [21:0] old_rad_cos_Cs4;
logic [21:0] old_rad_cos_D4 ;
logic [21:0] old_rad_cos_Ds4;
logic [21:0] old_rad_cos_E4 ;
logic [21:0] old_rad_cos_F4 ;
logic [21:0] old_rad_cos_Fs4;
logic [21:0] old_rad_cos_G4 ;
logic [21:0] old_rad_cos_Gs4;
logic [21:0] old_rad_cos_A4 ;
logic [21:0] old_rad_cos_As4;
logic [21:0] old_rad_cos_B4 ;
logic [21:0] old_rad_cos_C5 ;
logic [21:0] old_rad_cos_Cs5;
logic [21:0] old_rad_cos_D5 ;
logic [21:0] old_rad_cos_Ds5;

assign old_rad_cos_E2  = new_rad_cos_E2  + L_f_discrete_E2 ;
assign old_rad_cos_F2  = new_rad_cos_F2  + L_f_discrete_F2 ;
assign old_rad_cos_Fs2 = new_rad_cos_Fs2 + L_f_discrete_Fs2;
assign old_rad_cos_G2  = new_rad_cos_G2  + L_f_discrete_G2 ;
assign old_rad_cos_Gs2 = new_rad_cos_Gs2 + L_f_discrete_Gs2;
assign old_rad_cos_A2  = new_rad_cos_A2  + L_f_discrete_A2 ;
assign old_rad_cos_As2 = new_rad_cos_As2 + L_f_discrete_As2;
assign old_rad_cos_B2  = new_rad_cos_B2  + L_f_discrete_B2 ;
assign old_rad_cos_C3  = new_rad_cos_C3  + L_f_discrete_C3 ;
assign old_rad_cos_Cs3 = new_rad_cos_Cs3 + L_f_discrete_Cs3;
assign old_rad_cos_D3  = new_rad_cos_D3  + L_f_discrete_D3 ;
assign old_rad_cos_Ds3 = new_rad_cos_Ds3 + L_f_discrete_Ds3;
assign old_rad_cos_E3  = new_rad_cos_E3  + L_f_discrete_E3 ;
assign old_rad_cos_F3  = new_rad_cos_F3  + L_f_discrete_F3 ;
assign old_rad_cos_Fs3 = new_rad_cos_Fs3 + L_f_discrete_Fs3;
assign old_rad_cos_G3  = new_rad_cos_G3  + L_f_discrete_G3 ;
assign old_rad_cos_Gs3 = new_rad_cos_Gs3 + L_f_discrete_Gs3;
assign old_rad_cos_A3  = new_rad_cos_A3  + L_f_discrete_A3 ;
assign old_rad_cos_As3 = new_rad_cos_As3 + L_f_discrete_As3;
assign old_rad_cos_B3  = new_rad_cos_B3  + L_f_discrete_B3 ;
assign old_rad_cos_C4  = new_rad_cos_C4  + L_f_discrete_C4 ;
assign old_rad_cos_Cs4 = new_rad_cos_Cs4 + L_f_discrete_Cs4;
assign old_rad_cos_D4  = new_rad_cos_D4  + L_f_discrete_D4 ;
assign old_rad_cos_Ds4 = new_rad_cos_Ds4 + L_f_discrete_Ds4;
assign old_rad_cos_E4  = new_rad_cos_E4  + L_f_discrete_E4 ;
assign old_rad_cos_F4  = new_rad_cos_F4  + L_f_discrete_F4 ;
assign old_rad_cos_Fs4 = new_rad_cos_Fs4 + L_f_discrete_Fs4;
assign old_rad_cos_G4  = new_rad_cos_G4  + L_f_discrete_G4 ;
assign old_rad_cos_Gs4 = new_rad_cos_Gs4 + L_f_discrete_Gs4;
assign old_rad_cos_A4  = new_rad_cos_A4  + L_f_discrete_A4 ;
assign old_rad_cos_As4 = new_rad_cos_As4 + L_f_discrete_As4;
assign old_rad_cos_B4  = new_rad_cos_B4  + L_f_discrete_B4 ;
assign old_rad_cos_C5  = new_rad_cos_C5  + L_f_discrete_C5 ;
assign old_rad_cos_Cs5 = new_rad_cos_Cs5 + L_f_discrete_Cs5;
assign old_rad_cos_D5  = new_rad_cos_D5  + L_f_discrete_D5 ;
assign old_rad_cos_Ds5 = new_rad_cos_Ds5 + L_f_discrete_Ds5;

logic [21:0] old_rad_sin_E2 ;
logic [21:0] old_rad_sin_F2 ;
logic [21:0] old_rad_sin_Fs2;
logic [21:0] old_rad_sin_G2 ;
logic [21:0] old_rad_sin_Gs2;
logic [21:0] old_rad_sin_A2 ;
logic [21:0] old_rad_sin_As2;
logic [21:0] old_rad_sin_B2 ;
logic [21:0] old_rad_sin_C3 ;
logic [21:0] old_rad_sin_Cs3;
logic [21:0] old_rad_sin_D3 ;
logic [21:0] old_rad_sin_Ds3;
logic [21:0] old_rad_sin_E3 ;
logic [21:0] old_rad_sin_F3 ;
logic [21:0] old_rad_sin_Fs3;
logic [21:0] old_rad_sin_G3 ;
logic [21:0] old_rad_sin_Gs3;
logic [21:0] old_rad_sin_A3 ;
logic [21:0] old_rad_sin_As3;
logic [21:0] old_rad_sin_B3 ;
logic [21:0] old_rad_sin_C4 ;
logic [21:0] old_rad_sin_Cs4;
logic [21:0] old_rad_sin_D4 ;
logic [21:0] old_rad_sin_Ds4;
logic [21:0] old_rad_sin_E4 ;
logic [21:0] old_rad_sin_F4 ;
logic [21:0] old_rad_sin_Fs4;
logic [21:0] old_rad_sin_G4 ;
logic [21:0] old_rad_sin_Gs4;
logic [21:0] old_rad_sin_A4 ;
logic [21:0] old_rad_sin_As4;
logic [21:0] old_rad_sin_B4 ;
logic [21:0] old_rad_sin_C5 ;
logic [21:0] old_rad_sin_Cs5;
logic [21:0] old_rad_sin_D5 ;
logic [21:0] old_rad_sin_Ds5;

assign old_rad_sin_E2  = old_rad_cos_E2  - 22'h100000;
assign old_rad_sin_F2  = old_rad_cos_F2  - 22'h100000;
assign old_rad_sin_Fs2 = old_rad_cos_Fs2 - 22'h100000;
assign old_rad_sin_G2  = old_rad_cos_G2  - 22'h100000;
assign old_rad_sin_Gs2 = old_rad_cos_Gs2 - 22'h100000;
assign old_rad_sin_A2  = old_rad_cos_A2  - 22'h100000;
assign old_rad_sin_As2 = old_rad_cos_As2 - 22'h100000;
assign old_rad_sin_B2  = old_rad_cos_B2  - 22'h100000;
assign old_rad_sin_C3  = old_rad_cos_C3  - 22'h100000;
assign old_rad_sin_Cs3 = old_rad_cos_Cs3 - 22'h100000;
assign old_rad_sin_D3  = old_rad_cos_D3  - 22'h100000;
assign old_rad_sin_Ds3 = old_rad_cos_Ds3 - 22'h100000;
assign old_rad_sin_E3  = old_rad_cos_E3  - 22'h100000;
assign old_rad_sin_F3  = old_rad_cos_F3  - 22'h100000;
assign old_rad_sin_Fs3 = old_rad_cos_Fs3 - 22'h100000;
assign old_rad_sin_G3  = old_rad_cos_G3  - 22'h100000;
assign old_rad_sin_Gs3 = old_rad_cos_Gs3 - 22'h100000;
assign old_rad_sin_A3  = old_rad_cos_A3  - 22'h100000;
assign old_rad_sin_As3 = old_rad_cos_As3 - 22'h100000;
assign old_rad_sin_B3  = old_rad_cos_B3  - 22'h100000;
assign old_rad_sin_C4  = old_rad_cos_C4  - 22'h100000;
assign old_rad_sin_Cs4 = old_rad_cos_Cs4 - 22'h100000;
assign old_rad_sin_D4  = old_rad_cos_D4  - 22'h100000;
assign old_rad_sin_Ds4 = old_rad_cos_Ds4 - 22'h100000;
assign old_rad_sin_E4  = old_rad_cos_E4  - 22'h100000;
assign old_rad_sin_F4  = old_rad_cos_F4  - 22'h100000;
assign old_rad_sin_Fs4 = old_rad_cos_Fs4 - 22'h100000;
assign old_rad_sin_G4  = old_rad_cos_G4  - 22'h100000;
assign old_rad_sin_Gs4 = old_rad_cos_Gs4 - 22'h100000;
assign old_rad_sin_A4  = old_rad_cos_A4  - 22'h100000;
assign old_rad_sin_As4 = old_rad_cos_As4 - 22'h100000;
assign old_rad_sin_B4  = old_rad_cos_B4  - 22'h100000;
assign old_rad_sin_C5  = old_rad_cos_C5  - 22'h100000;
assign old_rad_sin_Cs5 = old_rad_cos_Cs5 - 22'h100000;
assign old_rad_sin_D5  = old_rad_cos_D5  - 22'h100000;
assign old_rad_sin_Ds5 = old_rad_cos_Ds5 - 22'h100000;

endmodule