#!/usr/bin/env python3
import math

def sat16(v: int) -> int:
    return max(-32768, min(32767, v))

def q15_from_float(y: float) -> int:
    # Ideal symmetric round-to-nearest and saturate to signed Q1.15.
    if y >= 0:
        v = math.floor(y * 32768.0 + 0.5)
    else:
        v = math.ceil(y * 32768.0 - 0.5)
    return sat16(int(v))

def overdrive_golden(i_data: int, i_gain: int) -> int:
    # i_data: signed Q1.15 integer [-32768, 32767]
    # i_gain: unsigned Q2.6 integer [0, 255]
    if not -32768 <= i_data <= 32767:
        raise ValueError('i_data out of signed 16-bit range')
    if not 0 <= i_gain <= 255:
        raise ValueError('i_gain out of unsigned 8-bit range')
    if i_gain <= 4:
        return i_data
    x = i_data / 32768.0
    g = i_gain / 64.0
    y = math.tanh(g * x) / math.tanh(g)
    return q15_from_float(y)

def main():
    cases = []
    for g in [0, 1, 4]:
        for x in [-32768, -30000, -16384, -1, 0, 1, 16384, 30000, 32767]:
            cases.append((x, g))
    for g in [5, 8, 16, 32, 64, 128, 192, 255]:
        for x in [-32768, -16384, -1024, 0, 1024, 32767]:
            cases.append((x, g))

    print('# idx i_data_dec i_gain_dec expected_o_data_dec i_data_hex i_gain_hex expected_hex')
    for idx, (x, g) in enumerate(cases):
        exp = overdrive_golden(x, g)
        print(f'{idx:02d} {x:7d} {g:3d} {exp:7d} 0x{(x & 0xffff):04X} 0x{g:02X} 0x{(exp & 0xffff):04X}')

if __name__ == '__main__':
    main()
