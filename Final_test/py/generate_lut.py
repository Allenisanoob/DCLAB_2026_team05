import numpy as np

def generate_base_delta_lut(filename="lut_base_delta.hex"):
    num_entries = 128
    frac_bits_g = 15
    v_max = 16.0 
    
    # 每個 Index 代表的 v 的跨度 (16.0 / 128 = 0.125)
    step_size = v_max / num_entries
    
    with open(filename, 'w') as f:
        for i in range(num_entries):
            # 1. 取得這一步與下一步的 v 值
            v0 = i * step_size
            v1 = (i + 1) * step_size
            
            # 2. 計算數學真實值 h(v) = tanh(v) / v
            # 保護除以零的情形
            y0 = 1.0 if v0 < 1e-6 else (np.tanh(v0) / v0)
            y1 = 1.0 if v1 < 1e-6 else (np.tanh(v1) / v1)
            
            # 3. 轉成 Q1.15 定點數
            base_q15 = int(round(y0 * (2**frac_bits_g)))
            y1_q15   = int(round(y1 * (2**frac_bits_g)))
            
            # 確保不會溢位超過 32767
            base_q15 = min(32767, max(0, base_q15))
            y1_q15   = min(32767, max(0, y1_q15))
            
            # 4. 計算 Delta (差值)
            # 因為 tanh(v)/v 是一個遞減函數，這裡算出來的 Delta 必然是負數或 0
            delta_q15 = y1_q15 - base_q15
            
            # 5. 格式轉換與打包 (合成 32-bit hex)
            # 將負數轉為 16-bit 2's complement 的表示法
            base_hex = base_q15 & 0xFFFF
            delta_hex = delta_q15 & 0xFFFF
            
            # 將 Base 放在高 16 bit，Delta 放在低 16 bit 寫入檔案
            f.write(f"{base_hex:04X}{delta_hex:04X}\n")

    print(f"✅ 成功生成 128 筆 Base+Delta 資料至 {filename}")

if __name__ == "__main__":
    generate_base_delta_lut()