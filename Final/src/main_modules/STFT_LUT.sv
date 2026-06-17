module STFT_LUT (
    input  clk,
    input  rst,
    input  in_valid,

    output reg signed [15:0] new_cos_E2,
    output reg signed [15:0] new_cos_F2,
    output reg signed [15:0] new_cos_Fs2,
    output reg signed [15:0] new_cos_G2,
    output reg signed [15:0] new_cos_Gs2,
    output reg signed [15:0] new_cos_A2,
    output reg signed [15:0] new_cos_As2,
    output reg signed [15:0] new_cos_B2,
    output reg signed [15:0] new_cos_C3,
    output reg signed [15:0] new_cos_Cs3,
    output reg signed [15:0] new_cos_D3,
    output reg signed [15:0] new_cos_Ds3,
    output reg signed [15:0] new_cos_E3,
    output reg signed [15:0] new_cos_F3,
    output reg signed [15:0] new_cos_Fs3,
    output reg signed [15:0] new_cos_G3,
    output reg signed [15:0] new_cos_Gs3,
    output reg signed [15:0] new_cos_A3,
    output reg signed [15:0] new_cos_As3,
    output reg signed [15:0] new_cos_B3,
    output reg signed [15:0] new_cos_C4,
    output reg signed [15:0] new_cos_Cs4,
    output reg signed [15:0] new_cos_D4,
    output reg signed [15:0] new_cos_Ds4,
    output reg signed [15:0] new_cos_E4,
    output reg signed [15:0] new_cos_F4,
    output reg signed [15:0] new_cos_Fs4,
    output reg signed [15:0] new_cos_G4,
    output reg signed [15:0] new_cos_Gs4,
    output reg signed [15:0] new_cos_A4,
    output reg signed [15:0] new_cos_As4,
    output reg signed [15:0] new_cos_B4,
    output reg signed [15:0] new_cos_C5,
    output reg signed [15:0] new_cos_Cs5,
    output reg signed [15:0] new_cos_D5,
    output reg signed [15:0] new_cos_Ds5,

    output reg signed [15:0] new_sin_E2,
    output reg signed [15:0] new_sin_F2,
    output reg signed [15:0] new_sin_Fs2,
    output reg signed [15:0] new_sin_G2,
    output reg signed [15:0] new_sin_Gs2,
    output reg signed [15:0] new_sin_A2,
    output reg signed [15:0] new_sin_As2,
    output reg signed [15:0] new_sin_B2,
    output reg signed [15:0] new_sin_C3,
    output reg signed [15:0] new_sin_Cs3,
    output reg signed [15:0] new_sin_D3,
    output reg signed [15:0] new_sin_Ds3,
    output reg signed [15:0] new_sin_E3,
    output reg signed [15:0] new_sin_F3,
    output reg signed [15:0] new_sin_Fs3,
    output reg signed [15:0] new_sin_G3,
    output reg signed [15:0] new_sin_Gs3,
    output reg signed [15:0] new_sin_A3,
    output reg signed [15:0] new_sin_As3,
    output reg signed [15:0] new_sin_B3,
    output reg signed [15:0] new_sin_C4,
    output reg signed [15:0] new_sin_Cs4,
    output reg signed [15:0] new_sin_D4,
    output reg signed [15:0] new_sin_Ds4,
    output reg signed [15:0] new_sin_E4,
    output reg signed [15:0] new_sin_F4,
    output reg signed [15:0] new_sin_Fs4,
    output reg signed [15:0] new_sin_G4,
    output reg signed [15:0] new_sin_Gs4,
    output reg signed [15:0] new_sin_A4,
    output reg signed [15:0] new_sin_As4,
    output reg signed [15:0] new_sin_B4,
    output reg signed [15:0] new_sin_C5,
    output reg signed [15:0] new_sin_Cs5,
    output reg signed [15:0] new_sin_D5,
    output reg signed [15:0] new_sin_Ds5,

    output reg signed [15:0] old_cos_E2,
    output reg signed [15:0] old_cos_F2,
    output reg signed [15:0] old_cos_Fs2,
    output reg signed [15:0] old_cos_G2,
    output reg signed [15:0] old_cos_Gs2,
    output reg signed [15:0] old_cos_A2,
    output reg signed [15:0] old_cos_As2,
    output reg signed [15:0] old_cos_B2,
    output reg signed [15:0] old_cos_C3,
    output reg signed [15:0] old_cos_Cs3,
    output reg signed [15:0] old_cos_D3,
    output reg signed [15:0] old_cos_Ds3,
    output reg signed [15:0] old_cos_E3,
    output reg signed [15:0] old_cos_F3,
    output reg signed [15:0] old_cos_Fs3,
    output reg signed [15:0] old_cos_G3,
    output reg signed [15:0] old_cos_Gs3,
    output reg signed [15:0] old_cos_A3,
    output reg signed [15:0] old_cos_As3,
    output reg signed [15:0] old_cos_B3,
    output reg signed [15:0] old_cos_C4,
    output reg signed [15:0] old_cos_Cs4,
    output reg signed [15:0] old_cos_D4,
    output reg signed [15:0] old_cos_Ds4,
    output reg signed [15:0] old_cos_E4,
    output reg signed [15:0] old_cos_F4,
    output reg signed [15:0] old_cos_Fs4,
    output reg signed [15:0] old_cos_G4,
    output reg signed [15:0] old_cos_Gs4,
    output reg signed [15:0] old_cos_A4,
    output reg signed [15:0] old_cos_As4,
    output reg signed [15:0] old_cos_B4,
    output reg signed [15:0] old_cos_C5,
    output reg signed [15:0] old_cos_Cs5,
    output reg signed [15:0] old_cos_D5,
    output reg signed [15:0] old_cos_Ds5,

    output reg signed [15:0] old_sin_E2,
    output reg signed [15:0] old_sin_F2,
    output reg signed [15:0] old_sin_Fs2,
    output reg signed [15:0] old_sin_G2,
    output reg signed [15:0] old_sin_Gs2,
    output reg signed [15:0] old_sin_A2,
    output reg signed [15:0] old_sin_As2,
    output reg signed [15:0] old_sin_B2,
    output reg signed [15:0] old_sin_C3,
    output reg signed [15:0] old_sin_Cs3,
    output reg signed [15:0] old_sin_D3,
    output reg signed [15:0] old_sin_Ds3,
    output reg signed [15:0] old_sin_E3,
    output reg signed [15:0] old_sin_F3,
    output reg signed [15:0] old_sin_Fs3,
    output reg signed [15:0] old_sin_G3,
    output reg signed [15:0] old_sin_Gs3,
    output reg signed [15:0] old_sin_A3,
    output reg signed [15:0] old_sin_As3,
    output reg signed [15:0] old_sin_B3,
    output reg signed [15:0] old_sin_C4,
    output reg signed [15:0] old_sin_Cs4,
    output reg signed [15:0] old_sin_D4,
    output reg signed [15:0] old_sin_Ds4,
    output reg signed [15:0] old_sin_E4,
    output reg signed [15:0] old_sin_F4,
    output reg signed [15:0] old_sin_Fs4,
    output reg signed [15:0] old_sin_G4,
    output reg signed [15:0] old_sin_Gs4,
    output reg signed [15:0] old_sin_A4,
    output reg signed [15:0] old_sin_As4,
    output reg signed [15:0] old_sin_B4,
    output reg signed [15:0] old_sin_C5,
    output reg signed [15:0] old_sin_Cs5,
    output reg signed [15:0] old_sin_D5,
    output reg signed [15:0] old_sin_Ds5
);

logic [5:0] state;

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

localparam [21:0] L_f_discrete_E2  = 22'h1ECEE5;
localparam [21:0] L_f_discrete_F2  = 22'h1D87C4;
localparam [21:0] L_f_discrete_Fs2 = 22'h1FFB6E;
localparam [21:0] L_f_discrete_G2  = 22'h2662A9;
localparam [21:0] L_f_discrete_Gs2 = 22'h30F99C;
localparam [21:0] L_f_discrete_A2  = 22'h0;
localparam [21:0] L_f_discrete_As2 = 22'h13B95A;
localparam [21:0] L_f_discrete_B2  = 22'h2C6D33;
localparam [21:0] L_f_discrete_C3  = 22'hA6754;
localparam [21:0] L_f_discrete_Cs3 = 22'h2DF806;
localparam [21:0] L_f_discrete_D3  = 22'h17745B;
localparam [21:0] L_f_discrete_Ds3 = 22'h73673;
localparam [21:0] L_f_discrete_E3  = 22'h3D9DCA;
localparam [21:0] L_f_discrete_F3  = 22'h3B0F89;
localparam [21:0] L_f_discrete_Fs3 = 22'h3FF6DD;
localparam [21:0] L_f_discrete_G3  = 22'hCC553;
localparam [21:0] L_f_discrete_Gs3 = 22'h21F337;
localparam [21:0] L_f_discrete_A3  = 22'h0;
localparam [21:0] L_f_discrete_As3 = 22'h2772B5;
localparam [21:0] L_f_discrete_B3  = 22'h18DA67;
localparam [21:0] L_f_discrete_C4  = 22'h14CEA7;
localparam [21:0] L_f_discrete_Cs4 = 22'h1BF00C;
localparam [21:0] L_f_discrete_D4  = 22'h2EE8B6;
localparam [21:0] L_f_discrete_Ds4 = 22'hE6CE6;
localparam [21:0] L_f_discrete_E4  = 22'h3B3B94;
localparam [21:0] L_f_discrete_F4  = 22'h361F12;
localparam [21:0] L_f_discrete_Fs4 = 22'h3FEDB9;
localparam [21:0] L_f_discrete_G4  = 22'h198AA5;
localparam [21:0] L_f_discrete_Gs4 = 22'h3E66F;
localparam [21:0] L_f_discrete_A4  = 22'h0;
localparam [21:0] L_f_discrete_As4 = 22'hEE56A;
localparam [21:0] L_f_discrete_B4  = 22'h31B4CD;
localparam [21:0] L_f_discrete_C5  = 22'h299D4E;
localparam [21:0] L_f_discrete_Cs5 = 22'h37E017;
localparam [21:0] L_f_discrete_D5  = 22'h1DD16C;
localparam [21:0] L_f_discrete_Ds5 = 22'h1CD9CD;

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

logic [15:0] new_rad_cos, new_rad_sin, old_rad_cos, old_rad_sin;
logic signed [15:0] result_cos_0, result_cos_1, result_cos_2, result_cos_3;

always_comb begin
    case (state)
        6'd1: begin
            new_rad_cos = new_rad_cos_E2[21:6] + new_rad_cos_E2[5];
            new_rad_sin = new_rad_sin_E2[21:6] + new_rad_sin_E2[5];
            old_rad_cos = old_rad_cos_E2[21:6] + old_rad_cos_E2[5];
            old_rad_sin = old_rad_sin_E2[21:6] + old_rad_sin_E2[5];
        end
        6'd2: begin
            new_rad_cos = new_rad_cos_F2[21:6] + new_rad_cos_F2[5];
            new_rad_sin = new_rad_sin_F2[21:6] + new_rad_sin_F2[5];
            old_rad_cos = old_rad_cos_F2[21:6] + old_rad_cos_F2[5];
            old_rad_sin = old_rad_sin_F2[21:6] + old_rad_sin_F2[5];
        end
        6'd3: begin
            new_rad_cos = new_rad_cos_Fs2[21:6] + new_rad_cos_Fs2[5];
            new_rad_sin = new_rad_sin_Fs2[21:6] + new_rad_sin_Fs2[5];
            old_rad_cos = old_rad_cos_Fs2[21:6] + old_rad_cos_Fs2[5];
            old_rad_sin = old_rad_sin_Fs2[21:6] + old_rad_sin_Fs2[5];
        end
        6'd4: begin
            new_rad_cos = new_rad_cos_G2[21:6] + new_rad_cos_G2[5];
            new_rad_sin = new_rad_sin_G2[21:6] + new_rad_sin_G2[5];
            old_rad_cos = old_rad_cos_G2[21:6] + old_rad_cos_G2[5];
            old_rad_sin = old_rad_sin_G2[21:6] + old_rad_sin_G2[5];
        end
        6'd5: begin
            new_rad_cos = new_rad_cos_Gs2[21:6] + new_rad_cos_Gs2[5];
            new_rad_sin = new_rad_sin_Gs2[21:6] + new_rad_sin_Gs2[5];
            old_rad_cos = old_rad_cos_Gs2[21:6] + old_rad_cos_Gs2[5];
            old_rad_sin = old_rad_sin_Gs2[21:6] + old_rad_sin_Gs2[5];
        end
        6'd6: begin
            new_rad_cos = new_rad_cos_A2[21:6] + new_rad_cos_A2[5];
            new_rad_sin = new_rad_sin_A2[21:6] + new_rad_sin_A2[5];
            old_rad_cos = old_rad_cos_A2[21:6] + old_rad_cos_A2[5];
            old_rad_sin = old_rad_sin_A2[21:6] + old_rad_sin_A2[5];
        end
        6'd7: begin
            new_rad_cos = new_rad_cos_As2[21:6] + new_rad_cos_As2[5];
            new_rad_sin = new_rad_sin_As2[21:6] + new_rad_sin_As2[5];
            old_rad_cos = old_rad_cos_As2[21:6] + old_rad_cos_As2[5];
            old_rad_sin = old_rad_sin_As2[21:6] + old_rad_sin_As2[5];
        end
        6'd8: begin
            new_rad_cos = new_rad_cos_B2[21:6] + new_rad_cos_B2[5];
            new_rad_sin = new_rad_sin_B2[21:6] + new_rad_sin_B2[5];
            old_rad_cos = old_rad_cos_B2[21:6] + old_rad_cos_B2[5];
            old_rad_sin = old_rad_sin_B2[21:6] + old_rad_sin_B2[5];
        end
        6'd9: begin
            new_rad_cos = new_rad_cos_C3[21:6] + new_rad_cos_C3[5];
            new_rad_sin = new_rad_sin_C3[21:6] + new_rad_sin_C3[5];
            old_rad_cos = old_rad_cos_C3[21:6] + old_rad_cos_C3[5];
            old_rad_sin = old_rad_sin_C3[21:6] + old_rad_sin_C3[5];
        end
        6'd10: begin
            new_rad_cos = new_rad_cos_Cs3[21:6] + new_rad_cos_Cs3[5];
            new_rad_sin = new_rad_sin_Cs3[21:6] + new_rad_sin_Cs3[5];
            old_rad_cos = old_rad_cos_Cs3[21:6] + old_rad_cos_Cs3[5];
            old_rad_sin = old_rad_sin_Cs3[21:6] + old_rad_sin_Cs3[5];
        end
        6'd11: begin
            new_rad_cos = new_rad_cos_D3[21:6] + new_rad_cos_D3[5];
            new_rad_sin = new_rad_sin_D3[21:6] + new_rad_sin_D3[5];
            old_rad_cos = old_rad_cos_D3[21:6] + old_rad_cos_D3[5];
            old_rad_sin = old_rad_sin_D3[21:6] + old_rad_sin_D3[5];
        end
        6'd12: begin
            new_rad_cos = new_rad_cos_Ds3[21:6] + new_rad_cos_Ds3[5];
            new_rad_sin = new_rad_sin_Ds3[21:6] + new_rad_sin_Ds3[5];
            old_rad_cos = old_rad_cos_Ds3[21:6] + old_rad_cos_Ds3[5];
            old_rad_sin = old_rad_sin_Ds3[21:6] + old_rad_sin_Ds3[5];
        end
        6'd13: begin
            new_rad_cos = new_rad_cos_E3[21:6] + new_rad_cos_E3[5];
            new_rad_sin = new_rad_sin_E3[21:6] + new_rad_sin_E3[5];
            old_rad_cos = old_rad_cos_E3[21:6] + old_rad_cos_E3[5];
            old_rad_sin = old_rad_sin_E3[21:6] + old_rad_sin_E3[5];
        end
        6'd14: begin
            new_rad_cos = new_rad_cos_F3[21:6] + new_rad_cos_F3[5];
            new_rad_sin = new_rad_sin_F3[21:6] + new_rad_sin_F3[5];
            old_rad_cos = old_rad_cos_F3[21:6] + old_rad_cos_F3[5];
            old_rad_sin = old_rad_sin_F3[21:6] + old_rad_sin_F3[5];
        end
        6'd15: begin
            new_rad_cos = new_rad_cos_Fs3[21:6] + new_rad_cos_Fs3[5];
            new_rad_sin = new_rad_sin_Fs3[21:6] + new_rad_sin_Fs3[5];
            old_rad_cos = old_rad_cos_Fs3[21:6] + old_rad_cos_Fs3[5];
            old_rad_sin = old_rad_sin_Fs3[21:6] + old_rad_sin_Fs3[5];
        end
        6'd16: begin
            new_rad_cos = new_rad_cos_G3[21:6] + new_rad_cos_G3[5];
            new_rad_sin = new_rad_sin_G3[21:6] + new_rad_sin_G3[5];
            old_rad_cos = old_rad_cos_G3[21:6] + old_rad_cos_G3[5];
            old_rad_sin = old_rad_sin_G3[21:6] + old_rad_sin_G3[5];
        end
        6'd17: begin
            new_rad_cos = new_rad_cos_Gs3[21:6] + new_rad_cos_Gs3[5];
            new_rad_sin = new_rad_sin_Gs3[21:6] + new_rad_sin_Gs3[5];
            old_rad_cos = old_rad_cos_Gs3[21:6] + old_rad_cos_Gs3[5];
            old_rad_sin = old_rad_sin_Gs3[21:6] + old_rad_sin_Gs3[5];
        end
        6'd18: begin
            new_rad_cos = new_rad_cos_A3[21:6] + new_rad_cos_A3[5];
            new_rad_sin = new_rad_sin_A3[21:6] + new_rad_sin_A3[5];
            old_rad_cos = old_rad_cos_A3[21:6] + old_rad_cos_A3[5];
            old_rad_sin = old_rad_sin_A3[21:6] + old_rad_sin_A3[5];
        end
        6'd19: begin
            new_rad_cos = new_rad_cos_As3[21:6] + new_rad_cos_As3[5];
            new_rad_sin = new_rad_sin_As3[21:6] + new_rad_sin_As3[5];
            old_rad_cos = old_rad_cos_As3[21:6] + old_rad_cos_As3[5];
            old_rad_sin = old_rad_sin_As3[21:6] + old_rad_sin_As3[5];
        end
        6'd20: begin
            new_rad_cos = new_rad_cos_B3[21:6] + new_rad_cos_B3[5];
            new_rad_sin = new_rad_sin_B3[21:6] + new_rad_sin_B3[5];
            old_rad_cos = old_rad_cos_B3[21:6] + old_rad_cos_B3[5];
            old_rad_sin = old_rad_sin_B3[21:6] + old_rad_sin_B3[5];
        end
        6'd21: begin
            new_rad_cos = new_rad_cos_C4[21:6] + new_rad_cos_C4[5];
            new_rad_sin = new_rad_sin_C4[21:6] + new_rad_sin_C4[5];
            old_rad_cos = old_rad_cos_C4[21:6] + old_rad_cos_C4[5];
            old_rad_sin = old_rad_sin_C4[21:6] + old_rad_sin_C4[5];
        end
        6'd22: begin
            new_rad_cos = new_rad_cos_Cs4[21:6] + new_rad_cos_Cs4[5];
            new_rad_sin = new_rad_sin_Cs4[21:6] + new_rad_sin_Cs4[5];
            old_rad_cos = old_rad_cos_Cs4[21:6] + old_rad_cos_Cs4[5];
            old_rad_sin = old_rad_sin_Cs4[21:6] + old_rad_sin_Cs4[5];
        end
        6'd23: begin
            new_rad_cos = new_rad_cos_D4[21:6] + new_rad_cos_D4[5];
            new_rad_sin = new_rad_sin_D4[21:6] + new_rad_sin_D4[5];
            old_rad_cos = old_rad_cos_D4[21:6] + old_rad_cos_D4[5];
            old_rad_sin = old_rad_sin_D4[21:6] + old_rad_sin_D4[5];
        end
        6'd24: begin
            new_rad_cos = new_rad_cos_Ds4[21:6] + new_rad_cos_Ds4[5];
            new_rad_sin = new_rad_sin_Ds4[21:6] + new_rad_sin_Ds4[5];
            old_rad_cos = old_rad_cos_Ds4[21:6] + old_rad_cos_Ds4[5];
            old_rad_sin = old_rad_sin_Ds4[21:6] + old_rad_sin_Ds4[5];
        end
        6'd25: begin
            new_rad_cos = new_rad_cos_E4[21:6] + new_rad_cos_E4[5];
            new_rad_sin = new_rad_sin_E4[21:6] + new_rad_sin_E4[5];
            old_rad_cos = old_rad_cos_E4[21:6] + old_rad_cos_E4[5];
            old_rad_sin = old_rad_sin_E4[21:6] + old_rad_sin_E4[5];
        end
        6'd26: begin
            new_rad_cos = new_rad_cos_F4[21:6] + new_rad_cos_F4[5];
            new_rad_sin = new_rad_sin_F4[21:6] + new_rad_sin_F4[5];
            old_rad_cos = old_rad_cos_F4[21:6] + old_rad_cos_F4[5];
            old_rad_sin = old_rad_sin_F4[21:6] + old_rad_sin_F4[5];
        end
        6'd27: begin
            new_rad_cos = new_rad_cos_Fs4[21:6] + new_rad_cos_Fs4[5];
            new_rad_sin = new_rad_sin_Fs4[21:6] + new_rad_sin_Fs4[5];
            old_rad_cos = old_rad_cos_Fs4[21:6] + old_rad_cos_Fs4[5];
            old_rad_sin = old_rad_sin_Fs4[21:6] + old_rad_sin_Fs4[5];
        end
        6'd28: begin
            new_rad_cos = new_rad_cos_G4[21:6] + new_rad_cos_G4[5];
            new_rad_sin = new_rad_sin_G4[21:6] + new_rad_sin_G4[5];
            old_rad_cos = old_rad_cos_G4[21:6] + old_rad_cos_G4[5];
            old_rad_sin = old_rad_sin_G4[21:6] + old_rad_sin_G4[5];
        end
        6'd29: begin
            new_rad_cos = new_rad_cos_Gs4[21:6] + new_rad_cos_Gs4[5];
            new_rad_sin = new_rad_sin_Gs4[21:6] + new_rad_sin_Gs4[5];
            old_rad_cos = old_rad_cos_Gs4[21:6] + old_rad_cos_Gs4[5];
            old_rad_sin = old_rad_sin_Gs4[21:6] + old_rad_sin_Gs4[5];
        end
        6'd30: begin
            new_rad_cos = new_rad_cos_A4[21:6] + new_rad_cos_A4[5];
            new_rad_sin = new_rad_sin_A4[21:6] + new_rad_sin_A4[5];
            old_rad_cos = old_rad_cos_A4[21:6] + old_rad_cos_A4[5];
            old_rad_sin = old_rad_sin_A4[21:6] + old_rad_sin_A4[5];
        end
        6'd31: begin
            new_rad_cos = new_rad_cos_As4[21:6] + new_rad_cos_As4[5];
            new_rad_sin = new_rad_sin_As4[21:6] + new_rad_sin_As4[5];
            old_rad_cos = old_rad_cos_As4[21:6] + old_rad_cos_As4[5];
            old_rad_sin = old_rad_sin_As4[21:6] + old_rad_sin_As4[5];
        end
        6'd32: begin
            new_rad_cos = new_rad_cos_B4[21:6] + new_rad_cos_B4[5];
            new_rad_sin = new_rad_sin_B4[21:6] + new_rad_sin_B4[5];
            old_rad_cos = old_rad_cos_B4[21:6] + old_rad_cos_B4[5];
            old_rad_sin = old_rad_sin_B4[21:6] + old_rad_sin_B4[5];
        end
        6'd33: begin
            new_rad_cos = new_rad_cos_C5[21:6] + new_rad_cos_C5[5];
            new_rad_sin = new_rad_sin_C5[21:6] + new_rad_sin_C5[5];
            old_rad_cos = old_rad_cos_C5[21:6] + old_rad_cos_C5[5];
            old_rad_sin = old_rad_sin_C5[21:6] + old_rad_sin_C5[5];
        end
        6'd34: begin
            new_rad_cos = new_rad_cos_Cs5[21:6] + new_rad_cos_Cs5[5];
            new_rad_sin = new_rad_sin_Cs5[21:6] + new_rad_sin_Cs5[5];
            old_rad_cos = old_rad_cos_Cs5[21:6] + old_rad_cos_Cs5[5];
            old_rad_sin = old_rad_sin_Cs5[21:6] + old_rad_sin_Cs5[5];
        end
        6'd35: begin
            new_rad_cos = new_rad_cos_D5[21:6] + new_rad_cos_D5[5];
            new_rad_sin = new_rad_sin_D5[21:6] + new_rad_sin_D5[5];
            old_rad_cos = old_rad_cos_D5[21:6] + old_rad_cos_D5[5];
            old_rad_sin = old_rad_sin_D5[21:6] + old_rad_sin_D5[5];
        end
        6'd36: begin
            new_rad_cos = new_rad_cos_Ds5[21:6] + new_rad_cos_Ds5[5];
            new_rad_sin = new_rad_sin_Ds5[21:6] + new_rad_sin_Ds5[5];
            old_rad_cos = old_rad_cos_Ds5[21:6] + old_rad_cos_Ds5[5];
            old_rad_sin = old_rad_sin_Ds5[21:6] + old_rad_sin_Ds5[5];
        end
        default: begin
            new_rad_cos = 16'd0;
            new_rad_sin = 16'd0;
            old_rad_cos = 16'd0;
            old_rad_sin = 16'd0;
        end
    endcase
end

cosine cos_0 (.f(new_rad_cos), .cos_2pif(result_cos_0));
cosine cos_1 (.f(new_rad_sin), .cos_2pif(result_cos_1));
cosine cos_2 (.f(old_rad_cos), .cos_2pif(result_cos_2));
cosine cos_3 (.f(old_rad_sin), .cos_2pif(result_cos_3));

always_ff @(posedge clk or negedge rst) begin
    if (!rst) begin
        state <= 6'd0;
        new_rad_cos_E2  <= 22'd0;
        new_rad_cos_F2  <= 22'd0;
        new_rad_cos_Fs2 <= 22'd0;
        new_rad_cos_G2  <= 22'd0;
        new_rad_cos_Gs2 <= 22'd0;
        new_rad_cos_A2  <= 22'd0;
        new_rad_cos_As2 <= 22'd0;
        new_rad_cos_B2  <= 22'd0;
        new_rad_cos_C3  <= 22'd0;
        new_rad_cos_Cs3 <= 22'd0;
        new_rad_cos_D3  <= 22'd0;
        new_rad_cos_Ds3 <= 22'd0;
        new_rad_cos_E3  <= 22'd0;
        new_rad_cos_F3  <= 22'd0;
        new_rad_cos_Fs3 <= 22'd0;
        new_rad_cos_G3  <= 22'd0;
        new_rad_cos_Gs3 <= 22'd0;
        new_rad_cos_A3  <= 22'd0;
        new_rad_cos_As3 <= 22'd0;
        new_rad_cos_B3  <= 22'd0;
        new_rad_cos_C4  <= 22'd0;
        new_rad_cos_Cs4 <= 22'd0;
        new_rad_cos_D4  <= 22'd0;
        new_rad_cos_Ds4 <= 22'd0;
        new_rad_cos_E4  <= 22'd0;
        new_rad_cos_F4  <= 22'd0;
        new_rad_cos_Fs4 <= 22'd0;
        new_rad_cos_G4  <= 22'd0;
        new_rad_cos_Gs4 <= 22'd0;
        new_rad_cos_A4  <= 22'd0;
        new_rad_cos_As4 <= 22'd0;
        new_rad_cos_B4  <= 22'd0;
        new_rad_cos_C5  <= 22'd0;
        new_rad_cos_Cs5 <= 22'd0;
        new_rad_cos_D5  <= 22'd0;
        new_rad_cos_Ds5 <= 22'd0;
    end else begin
        case (state)
            6'd0: begin
                if (in_valid) begin
                    new_rad_cos_E2  <= new_rad_cos_E2  - f_discrete_E2 ;
                    new_rad_cos_F2  <= new_rad_cos_F2  - f_discrete_F2 ;
                    new_rad_cos_Fs2 <= new_rad_cos_Fs2 - f_discrete_Fs2;
                    new_rad_cos_G2  <= new_rad_cos_G2  - f_discrete_G2 ;
                    new_rad_cos_Gs2 <= new_rad_cos_Gs2 - f_discrete_Gs2;
                    new_rad_cos_A2  <= new_rad_cos_A2  - f_discrete_A2 ;
                    new_rad_cos_As2 <= new_rad_cos_As2 - f_discrete_As2;
                    new_rad_cos_B2  <= new_rad_cos_B2  - f_discrete_B2 ;
                    new_rad_cos_C3  <= new_rad_cos_C3  - f_discrete_C3 ;
                    new_rad_cos_Cs3 <= new_rad_cos_Cs3 - f_discrete_Cs3;
                    new_rad_cos_D3  <= new_rad_cos_D3  - f_discrete_D3 ;
                    new_rad_cos_Ds3 <= new_rad_cos_Ds3 - f_discrete_Ds3;
                    new_rad_cos_E3  <= new_rad_cos_E3  - f_discrete_E3 ;
                    new_rad_cos_F3  <= new_rad_cos_F3  - f_discrete_F3 ;
                    new_rad_cos_Fs3 <= new_rad_cos_Fs3 - f_discrete_Fs3;
                    new_rad_cos_G3  <= new_rad_cos_G3  - f_discrete_G3 ;
                    new_rad_cos_Gs3 <= new_rad_cos_Gs3 - f_discrete_Gs3;
                    new_rad_cos_A3  <= new_rad_cos_A3  - f_discrete_A3 ;
                    new_rad_cos_As3 <= new_rad_cos_As3 - f_discrete_As3;
                    new_rad_cos_B3  <= new_rad_cos_B3  - f_discrete_B3 ;
                    new_rad_cos_C4  <= new_rad_cos_C4  - f_discrete_C4 ;
                    new_rad_cos_Cs4 <= new_rad_cos_Cs4 - f_discrete_Cs4;
                    new_rad_cos_D4  <= new_rad_cos_D4  - f_discrete_D4 ;
                    new_rad_cos_Ds4 <= new_rad_cos_Ds4 - f_discrete_Ds4;
                    new_rad_cos_E4  <= new_rad_cos_E4  - f_discrete_E4 ;
                    new_rad_cos_F4  <= new_rad_cos_F4  - f_discrete_F4 ;
                    new_rad_cos_Fs4 <= new_rad_cos_Fs4 - f_discrete_Fs4;
                    new_rad_cos_G4  <= new_rad_cos_G4  - f_discrete_G4 ;
                    new_rad_cos_Gs4 <= new_rad_cos_Gs4 - f_discrete_Gs4;
                    new_rad_cos_A4  <= new_rad_cos_A4  - f_discrete_A4 ;
                    new_rad_cos_As4 <= new_rad_cos_As4 - f_discrete_As4;
                    new_rad_cos_B4  <= new_rad_cos_B4  - f_discrete_B4 ;
                    new_rad_cos_C5  <= new_rad_cos_C5  - f_discrete_C5 ;
                    new_rad_cos_Cs5 <= new_rad_cos_Cs5 - f_discrete_Cs5;
                    new_rad_cos_D5  <= new_rad_cos_D5  - f_discrete_D5 ;
                    new_rad_cos_Ds5 <= new_rad_cos_Ds5 - f_discrete_Ds5;
                    state <= state + 1;
                end
            end
            6'd1: begin
                new_cos_E2 <= result_cos_0;
                new_sin_E2 <= result_cos_1;
                old_cos_E2 <= result_cos_2;
                old_sin_E2 <= result_cos_3;
                state <= state + 1;
            end
            6'd2: begin
                new_cos_F2 <= result_cos_0;
                new_sin_F2 <= result_cos_1;
                old_cos_F2 <= result_cos_2;
                old_sin_F2 <= result_cos_3;
                state <= state + 1;
            end
            6'd3: begin
                new_cos_Fs2 <= result_cos_0;
                new_sin_Fs2 <= result_cos_1;
                old_cos_Fs2 <= result_cos_2;
                old_sin_Fs2 <= result_cos_3;
                state <= state + 1;
            end
            6'd4: begin
                new_cos_G2 <= result_cos_0;
                new_sin_G2 <= result_cos_1;
                old_cos_G2 <= result_cos_2;
                old_sin_G2 <= result_cos_3;
                state <= state + 1;
            end
            6'd5: begin
                new_cos_Gs2 <= result_cos_0;
                new_sin_Gs2 <= result_cos_1;
                old_cos_Gs2 <= result_cos_2;
                old_sin_Gs2 <= result_cos_3;
                state <= state + 1;
            end
            6'd6: begin
                new_cos_A2 <= result_cos_0;
                new_sin_A2 <= result_cos_1;
                old_cos_A2 <= result_cos_2;
                old_sin_A2 <= result_cos_3;
                state <= state + 1;
            end
            6'd7: begin
                new_cos_As2 <= result_cos_0;
                new_sin_As2 <= result_cos_1;
                old_cos_As2 <= result_cos_2;
                old_sin_As2 <= result_cos_3;
                state <= state + 1;
            end
            6'd8: begin
                new_cos_B2 <= result_cos_0;
                new_sin_B2 <= result_cos_1;
                old_cos_B2 <= result_cos_2;
                old_sin_B2 <= result_cos_3;
                state <= state + 1;
            end
            6'd9: begin
                new_cos_C3 <= result_cos_0;
                new_sin_C3 <= result_cos_1;
                old_cos_C3 <= result_cos_2;
                old_sin_C3 <= result_cos_3;
                state <= state + 1;
            end
            6'd10: begin
                new_cos_Cs3 <= result_cos_0;
                new_sin_Cs3 <= result_cos_1;
                old_cos_Cs3 <= result_cos_2;
                old_sin_Cs3 <= result_cos_3;
                state <= state + 1;
            end
            6'd11: begin
                new_cos_D3 <= result_cos_0;
                new_sin_D3 <= result_cos_1;
                old_cos_D3 <= result_cos_2;
                old_sin_D3 <= result_cos_3;
                state <= state + 1;
            end
            6'd12: begin
                new_cos_Ds3 <= result_cos_0;
                new_sin_Ds3 <= result_cos_1;
                old_cos_Ds3 <= result_cos_2;
                old_sin_Ds3 <= result_cos_3;
                state <= state + 1;
            end
            6'd13: begin
                new_cos_E3 <= result_cos_0;
                new_sin_E3 <= result_cos_1;
                old_cos_E3 <= result_cos_2;
                old_sin_E3 <= result_cos_3;
                state <= state + 1;
            end
            6'd14: begin
                new_cos_F3 <= result_cos_0;
                new_sin_F3 <= result_cos_1;
                old_cos_F3 <= result_cos_2;
                old_sin_F3 <= result_cos_3;
                state <= state + 1;
            end
            6'd15: begin
                new_cos_Fs3 <= result_cos_0;
                new_sin_Fs3 <= result_cos_1;
                old_cos_Fs3 <= result_cos_2;
                old_sin_Fs3 <= result_cos_3;
                state <= state + 1;
            end
            6'd16: begin
                new_cos_G3 <= result_cos_0;
                new_sin_G3 <= result_cos_1;
                old_cos_G3 <= result_cos_2;
                old_sin_G3 <= result_cos_3;
                state <= state + 1;
            end
            6'd17: begin
                new_cos_Gs3 <= result_cos_0;
                new_sin_Gs3 <= result_cos_1;
                old_cos_Gs3 <= result_cos_2;
                old_sin_Gs3 <= result_cos_3;
                state <= state + 1;
            end
            6'd18: begin
                new_cos_A3 <= result_cos_0;
                new_sin_A3 <= result_cos_1;
                old_cos_A3 <= result_cos_2;
                old_sin_A3 <= result_cos_3;
                state <= state + 1;
            end
            6'd19: begin
                new_cos_As3 <= result_cos_0;
                new_sin_As3 <= result_cos_1;
                old_cos_As3 <= result_cos_2;
                old_sin_As3 <= result_cos_3;
                state <= state + 1;
            end
            6'd20: begin
                new_cos_B3 <= result_cos_0;
                new_sin_B3 <= result_cos_1;
                old_cos_B3 <= result_cos_2;
                old_sin_B3 <= result_cos_3;
                state <= state + 1;
            end
            6'd21: begin
                new_cos_C4 <= result_cos_0;
                new_sin_C4 <= result_cos_1;
                old_cos_C4 <= result_cos_2;
                old_sin_C4 <= result_cos_3;
                state <= state + 1;
            end
            6'd22: begin
                new_cos_Cs4 <= result_cos_0;
                new_sin_Cs4 <= result_cos_1;
                old_cos_Cs4 <= result_cos_2;
                old_sin_Cs4 <= result_cos_3;
                state <= state + 1;
            end
            6'd23: begin
                new_cos_D4 <= result_cos_0;
                new_sin_D4 <= result_cos_1;
                old_cos_D4 <= result_cos_2;
                old_sin_D4 <= result_cos_3;
                state <= state + 1;
            end
            6'd24: begin
                new_cos_Ds4 <= result_cos_0;
                new_sin_Ds4 <= result_cos_1;
                old_cos_Ds4 <= result_cos_2;
                old_sin_Ds4 <= result_cos_3;
                state <= state + 1;
            end
            6'd25: begin
                new_cos_E4 <= result_cos_0;
                new_sin_E4 <= result_cos_1;
                old_cos_E4 <= result_cos_2;
                old_sin_E4 <= result_cos_3;
                state <= state + 1;
            end
            6'd26: begin
                new_cos_F4 <= result_cos_0;
                new_sin_F4 <= result_cos_1;
                old_cos_F4 <= result_cos_2;
                old_sin_F4 <= result_cos_3;
                state <= state + 1;
            end
            6'd27: begin
                new_cos_Fs4 <= result_cos_0;
                new_sin_Fs4 <= result_cos_1;
                old_cos_Fs4 <= result_cos_2;
                old_sin_Fs4 <= result_cos_3;
                state <= state + 1;
            end
            6'd28: begin
                new_cos_G4 <= result_cos_0;
                new_sin_G4 <= result_cos_1;
                old_cos_G4 <= result_cos_2;
                old_sin_G4 <= result_cos_3;
                state <= state + 1;
            end
            6'd29: begin
                new_cos_Gs4 <= result_cos_0;
                new_sin_Gs4 <= result_cos_1;
                old_cos_Gs4 <= result_cos_2;
                old_sin_Gs4 <= result_cos_3;
                state <= state + 1;
            end
            6'd30: begin
                new_cos_A4 <= result_cos_0;
                new_sin_A4 <= result_cos_1;
                old_cos_A4 <= result_cos_2;
                old_sin_A4 <= result_cos_3;
                state <= state + 1;
            end
            6'd31: begin
                new_cos_As4 <= result_cos_0;
                new_sin_As4 <= result_cos_1;
                old_cos_As4 <= result_cos_2;
                old_sin_As4 <= result_cos_3;
                state <= state + 1;
            end
            6'd32: begin
                new_cos_B4 <= result_cos_0;
                new_sin_B4 <= result_cos_1;
                old_cos_B4 <= result_cos_2;
                old_sin_B4 <= result_cos_3;
                state <= state + 1;
            end
            6'd33: begin
                new_cos_C5 <= result_cos_0;
                new_sin_C5 <= result_cos_1;
                old_cos_C5 <= result_cos_2;
                old_sin_C5 <= result_cos_3;
                state <= state + 1;
            end
            6'd34: begin
                new_cos_Cs5 <= result_cos_0;
                new_sin_Cs5 <= result_cos_1;
                old_cos_Cs5 <= result_cos_2;
                old_sin_Cs5 <= result_cos_3;
                state <= state + 1;
            end
            6'd35: begin
                new_cos_D5 <= result_cos_0;
                new_sin_D5 <= result_cos_1;
                old_cos_D5 <= result_cos_2;
                old_sin_D5 <= result_cos_3;
                state <= state + 1;
            end
            6'd36: begin
                new_cos_Ds5 <= result_cos_0;
                new_sin_Ds5 <= result_cos_1;
                old_cos_Ds5 <= result_cos_2;
                old_sin_Ds5 <= result_cos_3;
                state <= 0;
            end
        endcase
    end
end

endmodule