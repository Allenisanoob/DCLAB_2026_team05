import math

def f(v):
    if v == 0.0:
        return 1.0
    return math.tanh(v) / v

def generate_roms():
    Q11_21 = 2**21
    Q1_15  = 2**15

    # ==========================================
    # 產生 Region 1 的 PWL LUT (Base & Diff)
    # 範圍 [0, 8.0)，共 256 個 entries
    # 每個 entry 跨距 = 8.0 / 256 = 0.03125 (即 2^-5)
    # ==========================================
    with open("rom_r1_base.hex", "w") as fb, open("rom_r1_diff.hex", "w") as fd:
        for i in range(256):
            v_curr = i * (2**-5)
            v_next = (i + 1) * (2**-5)
            
            y_curr = f(v_curr)
            y_next = f(v_next)
            
            # Base_Val: 轉換為 Q11.21 的十六進位
            base_val_q21 = int(round(y_curr * Q11_21))
            fb.write(f"{base_val_q21:08X}\n")
            
            # Diff: 理論上 y_curr 必定 >= y_next (因為函數嚴格遞減)
            diff_val = y_curr - y_next
            
            # 將差值也轉成 Q11.21 的尺度
            diff_val_q21 = int(round(diff_val * Q11_21))
            
            # 確保 Diff 能夠塞入 16-bit (最大值大約 22400，絕對不會溢位)
            assert diff_val_q21 < 65536, f"Diff exceeded 16-bit at index {i}"
            fd.write(f"{diff_val_q21:04X}\n")

    # ==========================================
    # 產生 Region 2 的尾數 LUT (Mantissa)
    # ==========================================
    with open("rom_r2_man.hex", "w") as fm:
        for i in range(256):
            # 8 bits 尾數，範圍 1.000... 到 1.99609375
            m = i / 256.0
            v = 1.0 + m
            
            # 計算倒數
            y = 1.0 / v
            
            # 轉換為 Unsigned Q1.15 的十六進位
            val_q1_15 = int(round(y * Q1_15))
            fm.write(f"{val_q1_15:04X}\n")

if __name__ == "__main__":
    generate_roms()
    print("3 個 ROM hex files 成功產生！")