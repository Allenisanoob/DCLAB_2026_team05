#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
fx_tester.py
==========================================================================
取代圖形 UI 的命令列測試工具，用來測試 AvmWrapper + UART_qsys 這條
"UART -> RS232 IP -> AvmWrapper -> Param_Manager" 的參數下載路徑。

--------------------------------------------------------------------------
UART 通訊設定 (來源: Qsys UART (RS-232 Serial Port) IP, Lab2_qsys_tuto1 p.8)
    Baud rate : 115200 bps   (Fixed baud rate, baud error 0.01)
    Parity    : NONE
    Data bits : 8
    Stop bits : 1
    -> 即標準 115200 8N1
    -> 未勾 "Include end-of-packet"：無封包邊界，AvmWrapper 靠數滿 32 bytes
       判定一包結束，故每次務必一次送完整 32 bytes，中間不可插入其他位元組。
    pyserial 預設即為 8N1，無需額外設定 bytesize/parity/stopbits。
--------------------------------------------------------------------------

設計依據 (直接對應你的 RTL)：
  AvmWrapper.S_READ:
      command_r = {command_r[247:0], avm_readdata[7:0]}
    -> 連收 32 bytes (256-bit) 後在第 32 個 byte 那拍發出 1-cycle o_valid。
    -> 先到的 byte 被推到高位，所以：
         command[255:248] = 第 1 個送出的 byte = 位址 / opcode
         command[7:0]     = 第 32 個送出的 byte
       因此整包用 "big-endian" 送出即可與硬體對齊：
         payload = value_256bit.to_bytes(32, 'big')

  Param_Manager.case(i_command[255:248]) 解碼各效果器參數位元欄位
  (見下方 SPECS，欄位定義逐 bit 對齊 RTL)。

模式：
  send     真的透過 serial port 把封包送到 FPGA
  dump     只印出封包十六進位，不需硬體 (驗證打包是否正確)
  selfcheck 內建單元測試，重建 AvmWrapper 的 shift 行為，
            驗證打包/解碼的往返一致性 (不需硬體、不需 pyserial)
  loopback 把 TX 接 RX 短路時，送出後讀回比對 (需硬體或 USB-UART loopback)
  monitor  持續讀 serial 把收到的 bytes 印出 (debug 用)

範例：
  # 不需硬體，先驗證打包正確
  python fx_tester.py selfcheck
  python fx_tester.py dump --fx od --gain 700 --level 40000

  # 列出某效果器有哪些參數
  python fx_tester.py params --fx ng

  # 真的送 (請改成你的 port 與 baudrate)
  python fx_tester.py send --port COM5 --baud 115200 --fx od --gain 700 --level 40000

  # 批次：從 script 檔一行一行送 (見 demo_script.txt)
  python fx_tester.py script --port COM5 --baud 115200 --file demo_script.txt

  # TX/RX 短路自我測試
  python fx_tester.py loopback --port COM5 --baud 115200 --fx vl --volume 100
==========================================================================
"""

import argparse
import sys
import time

# pyserial 為選用，只有 send/loopback/monitor 才需要
try:
    import serial  # type: ignore
    HAVE_SERIAL = True
except Exception:
    HAVE_SERIAL = False


# ==========================================================================
# 命令規格表
#   opcode      = Param_Manager 的 ADDR_xxx (command[255:248])
#   fields      = 參數定義，每個 = (名稱, 低位 bit, 寬度 bit)
#                 (對應 i_command[hi:lo]，這裡用 lo + width 表示)
#   全部欄位都填進一個 256-bit 整數的對應位元，再 big-endian 送出。
# ==========================================================================
# field: (arg_name, lsb_bit, width)
SPECS = {
    "od": {  # Overdrive   ADDR_OD = 1
        "opcode": 1,
        "name": "Overdrive",
        "fields": [
            ("gain",  0, 10),   # i_command[9:0]
            ("level", 16, 16),  # i_command[31:16]
        ],
    },
    "fz": {  # Fuzz        ADDR_FZ = 2
        "opcode": 2,
        "name": "Fuzz",
        "fields": [
            ("gain",  0, 10),
            ("level", 16, 16),
        ],
    },
    "dt": {  # Distortion  ADDR_DT = 3
        "opcode": 3,
        "name": "Distortion",
        "fields": [
            ("gain",  0, 10),
            ("level", 16, 16),
        ],
    },
    "rv": {  # Reverb      ADDR_RV = 4
        "opcode": 4,
        "name": "Reverb",
        "fields": [
            ("w_rate",  0, 8),   # i_command[7:0]
            ("ap_gain", 16, 8),  # i_command[23:16]
        ],
    },
    "ng": {  # Noise Gate  ADDR_NG = 5
        "opcode": 5,
        "name": "Noise Gate",
        "fields": [
            ("rise_rate",  0, 8),   # i_command[7:0]
            ("decay_rate", 16, 8),  # i_command[23:16]
            ("hold",       32, 16), # i_command[47:32]
            ("thres_lo",   48, 15), # i_command[62:48]
            ("thres_hi",   64, 15), # i_command[78:64]
        ],
    },
    "de": {  # Delay       ADDR_DE = 6
        "opcode": 6,
        "name": "Delay Effect",
        "fields": [
            ("time",     0, 16),   # i_command[15:0]
            ("feedback", 16, 8),   # i_command[23:16]
            ("mix",      32, 8),   # i_command[39:32]
        ],
    },
    "fg": {  # Flanger     ADDR_FG = 7
        "opcode": 7,
        "name": "Flanger",
        "fields": [
            ("inc",  0, 7),    # i_command[6:0]
            ("base", 16, 10),  # i_command[25:16]
            ("amp",  32, 10),  # i_command[41:32]
            ("gain", 48, 8),   # i_command[55:48]
            ("rate", 64, 8),   # i_command[71:64]
        ],
    },
    "ch": {  # Chorus      ADDR_CH = 8
        "opcode": 8,
        "name": "Chorus",
        "fields": [
            ("inc",  0, 7),    # i_command[6:0]
            ("base", 16, 12),  # i_command[27:16]
            ("amp",  32, 12),  # i_command[43:32]
            ("rate", 48, 8),   # i_command[55:48]
        ],
    },
    "aw": {  # Auto-Wah    ADDR_AW = 9
        "opcode": 9,
        "name": "Auto-Wah",
        "fields": [
            ("inc",  0, 7),
            ("base", 16, 12),
            ("amp",  32, 12),
            ("rate", 48, 8),
        ],
    },
    "st": {  # Stager      ADDR_ST = 10
        "opcode": 10,
        "name": "Stager",
        "fields": [
            ("staging", 0, 32),  # i_command[31:0]
        ],
    },
    "vl": {  # Volume      ADDR_VL = 11
        "opcode": 11,
        "name": "Volume",
        "fields": [
            ("volume", 0, 7),  # i_command[6:0]
        ],
    },
}

TOTAL_BYTES = 32  # 256 bits


# ==========================================================================
# 打包 / 解包
# ==========================================================================
def build_command(fx: str, values: dict) -> int:
    """依 SPECS 把參數塞進 256-bit 整數，並把 opcode 放到 [255:248]。"""
    if fx not in SPECS:
        raise ValueError(f"unknown fx '{fx}'. valid: {', '.join(SPECS)}")
    spec = SPECS[fx]
    cmd = 0

    for name, lsb, width in spec["fields"]:
        v = int(values.get(name, 0))
        maxv = (1 << width) - 1
        if v < 0 or v > maxv:
            raise ValueError(
                f"[{fx}] field '{name}' = {v} out of range 0..{maxv} ({width}-bit)"
            )
        cmd |= (v & maxv) << lsb

    # opcode 放最高 byte: command[255:248]
    cmd |= (spec["opcode"] & 0xFF) << 248
    return cmd


def command_to_bytes(cmd_int: int) -> bytes:
    """big-endian -> 第一個 byte 即 opcode，符合 AvmWrapper 的左移收法。"""
    return cmd_int.to_bytes(TOTAL_BYTES, byteorder="big")


def simulate_avmwrapper_shift(payload: bytes) -> int:
    """
    純軟體重建 AvmWrapper 的行為：
        command_r = {command_r[247:0], byte}
    對每個收到的 byte 做左移 8 bits 再 OR 進低 8 位。
    送進 32 個 byte 後，回傳最終 256-bit command_r。
    用來驗證 "我們送的 bytes" 經硬體後會還原成 "我們想要的 cmd_int"。
    """
    MASK = (1 << 256) - 1
    reg = 0
    for b in payload:
        reg = ((reg << 8) | (b & 0xFF)) & MASK
    return reg


def decode_command(cmd_int: int):
    """從 256-bit 整數還原 opcode 與各欄位 (模擬 Param_Manager 解碼)。"""
    opcode = (cmd_int >> 248) & 0xFF
    fx = None
    for k, spec in SPECS.items():
        if spec["opcode"] == opcode:
            fx = k
            break
    if fx is None:
        return opcode, None, {}
    vals = {}
    for name, lsb, width in SPECS[fx]["fields"]:
        mask = (1 << width) - 1
        vals[name] = (cmd_int >> lsb) & mask
    return opcode, fx, vals


# ==========================================================================
# 友善列印
# ==========================================================================
def hexdump(payload: bytes) -> str:
    rows = []
    for i in range(0, len(payload), 8):
        chunk = payload[i:i + 8]
        rows.append(f"  [{i:2d}] " + " ".join(f"{b:02X}" for b in chunk))
    return "\n".join(rows)


def describe(fx: str, cmd_int: int) -> str:
    payload = command_to_bytes(cmd_int)
    op, dfx, vals = decode_command(cmd_int)
    lines = []
    lines.append(f"  fx        : {fx} ({SPECS[fx]['name']})")
    lines.append(f"  opcode    : {op} (command[255:248])")
    lines.append(f"  256-bit   : 0x{cmd_int:064X}")
    lines.append(f"  bytes (TX order, opcode first):")
    lines.append(hexdump(payload))
    lines.append(f"  decoded back :")
    for name, lsb, width in SPECS[fx]["fields"]:
        lines.append(f"      {name:<10} = {vals.get(name)}  (bits[{lsb+width-1}:{lsb}])")
    return "\n".join(lines)


# ==========================================================================
# Serial helpers
# ==========================================================================
def open_serial(port: str, baud: int, timeout: float = 1.0):
    if not HAVE_SERIAL:
        sys.exit("錯誤: 需要 pyserial。請先 `pip install pyserial`。")
    return serial.Serial(port=port, baudrate=baud, timeout=timeout)


def send_payload(ser, payload: bytes, inter_byte_delay: float = 0.0):
    """把 32 bytes 送出。inter_byte_delay 可在硬體 RX 較慢時逐 byte 拉開。"""
    if inter_byte_delay > 0:
        for b in payload:
            ser.write(bytes([b]))
            ser.flush()
            time.sleep(inter_byte_delay)
    else:
        ser.write(payload)
        ser.flush()


# ==========================================================================
# 各 sub-command
# ==========================================================================
def collect_field_values(fx: str, args) -> dict:
    """從 argparse 結果蒐集該 fx 需要的欄位值。"""
    vals = {}
    for name, _lsb, _w in SPECS[fx]["fields"]:
        v = getattr(args, name, None)
        if v is not None:
            vals[name] = v
    return vals


def cmd_params(args):
    fx = args.fx
    if fx not in SPECS:
        sys.exit(f"unknown fx '{fx}'. valid: {', '.join(SPECS)}")
    spec = SPECS[fx]
    print(f"{fx} ({spec['name']}), opcode = {spec['opcode']}")
    print("  欄位          範圍              對應 bits")
    for name, lsb, width in spec["fields"]:
        maxv = (1 << width) - 1
        print(f"  --{name:<11} 0..{maxv:<12} command[{lsb+width-1}:{lsb}]")


def cmd_dump(args):
    fx = args.fx
    vals = collect_field_values(fx, args)
    cmd = build_command(fx, vals)
    print(describe(fx, cmd))


def cmd_selfcheck(args):
    """重建 AvmWrapper 收 byte 行為 + Param_Manager 解碼，驗證往返一致。"""
    print("== self-check：打包 -> 模擬 AvmWrapper shift -> 解碼 ==\n")
    n_pass = 0
    n_fail = 0

    # 為每個 fx 造一組有代表性的測試值 (邊界 + 中間值)
    test_vectors = {
        "od": {"gain": 700, "level": 40000},
        "fz": {"gain": 1023, "level": 65535},      # 全滿
        "dt": {"gain": 0, "level": 0},             # 全零
        "rv": {"w_rate": 200, "ap_gain": 99},
        "ng": {"rise_rate": 10, "decay_rate": 2, "hold": 24000,
               "thres_lo": 512, "thres_hi": 1024},
        "de": {"time": 12000, "feedback": 64, "mix": 32},
        "fg": {"inc": 2, "base": 512, "amp": 128, "gain": 64, "rate": 64},
        "ch": {"inc": 5, "base": 4095, "amp": 4095, "rate": 200},
        "aw": {"inc": 1, "base": 1, "amp": 1, "rate": 1},
        "st": {"staging": 0xDEADBEEF},
        "vl": {"volume": 100},
    }

    for fx, vals in test_vectors.items():
        cmd = build_command(fx, vals)
        payload = command_to_bytes(cmd)

        # 1) 長度必須是 32 bytes
        len_ok = (len(payload) == TOTAL_BYTES)

        # 2) 模擬硬體 shift register，結果應等於原 cmd
        reg = simulate_avmwrapper_shift(payload)
        shift_ok = (reg == cmd)

        # 3) 第一個送出的 byte 必須是 opcode
        op_ok = (payload[0] == SPECS[fx]["opcode"])

        # 4) 解碼回來欄位值一致
        _op, dfx, dvals = decode_command(reg)
        decode_ok = (dfx == fx) and all(
            dvals.get(k) == v for k, v in vals.items()
        )

        ok = len_ok and shift_ok and op_ok and decode_ok
        status = "PASS" if ok else "FAIL"
        if ok:
            n_pass += 1
        else:
            n_fail += 1
        print(f"[{status}] {fx:<3} ({SPECS[fx]['name']})")
        if not ok:
            print(f"        len_ok={len_ok} shift_ok={shift_ok} "
                  f"op_ok={op_ok} decode_ok={decode_ok}")
            print(f"        cmd = 0x{cmd:064X}")
            print(f"        reg = 0x{reg:064X}")
            print(f"        decoded = {dvals}")

    print(f"\n結果: {n_pass} passed, {n_fail} failed")
    sys.exit(0 if n_fail == 0 else 1)


def cmd_send(args):
    fx = args.fx
    vals = collect_field_values(fx, args)
    cmd = build_command(fx, vals)
    payload = command_to_bytes(cmd)

    print(describe(fx, cmd))
    print(f"\n-> 送往 {args.port} @ {args.baud} baud "
          f"(inter-byte delay = {args.byte_delay}s)")

    ser = open_serial(args.port, args.baud, timeout=args.timeout)
    try:
        send_payload(ser, payload, inter_byte_delay=args.byte_delay)
        print("送出完成。")
    finally:
        ser.close()


def cmd_loopback(args):
    """TX 短接 RX 時用：送出後讀回 32 bytes 比對。"""
    fx = args.fx
    vals = collect_field_values(fx, args)
    cmd = build_command(fx, vals)
    payload = command_to_bytes(cmd)

    print(describe(fx, cmd))
    ser = open_serial(args.port, args.baud, timeout=args.timeout)
    try:
        ser.reset_input_buffer()
        send_payload(ser, payload, inter_byte_delay=args.byte_delay)
        got = ser.read(TOTAL_BYTES)
        print(f"\n讀回 {len(got)} bytes:")
        print(hexdump(got))
        if got == payload:
            print("\nloopback PASS：收發一致。")
        else:
            print("\nloopback FAIL：收發不一致。")
            sys.exit(1)
    finally:
        ser.close()


def cmd_monitor(args):
    ser = open_serial(args.port, args.baud, timeout=0.2)
    print(f"monitor {args.port} @ {args.baud}，Ctrl-C 結束。")
    try:
        while True:
            data = ser.read(64)
            if data:
                print(" ".join(f"{b:02X}" for b in data))
    except KeyboardInterrupt:
        print("\n停止。")
    finally:
        ser.close()


def cmd_script(args):
    """
    從檔案讀入多行命令依序送出。
    每行格式 (以空白分隔)：
        <fx> key=val key=val ...
    例如：
        od gain=700 level=40000
        vl volume=100
        # 井號開頭為註解，空行略過
    """
    with open(args.file, "r", encoding="utf-8") as f:
        lines = f.readlines()

    ser = None
    if not args.dry_run:
        ser = open_serial(args.port, args.baud, timeout=args.timeout)

    try:
        for ln, raw in enumerate(lines, 1):
            line = raw.strip()
            if not line or line.startswith("#"):
                continue
            parts = line.split()
            fx = parts[0]
            if fx not in SPECS:
                print(f"  第 {ln} 行: 略過未知 fx '{fx}'")
                continue
            vals = {}
            for kv in parts[1:]:
                if "=" not in kv:
                    print(f"  第 {ln} 行: 略過格式錯誤 '{kv}'")
                    continue
                k, v = kv.split("=", 1)
                vals[k] = int(v, 0)  # 支援 0x 十六進位
            cmd = build_command(fx, vals)
            payload = command_to_bytes(cmd)
            op, _dfx, dvals = decode_command(cmd)
            print(f"  第 {ln} 行: {fx} opcode={op} -> {dvals}")
            if ser is not None:
                send_payload(ser, payload, inter_byte_delay=args.byte_delay)
                time.sleep(args.gap)
        print("script 完成。")
    finally:
        if ser is not None:
            ser.close()


# ==========================================================================
# argparse 組裝
# ==========================================================================
def add_fx_field_args(p):
    """把所有 fx 可能用到的欄位都加成 optional int argument。"""
    seen = set()
    for spec in SPECS.values():
        for name, _lsb, _w in spec["fields"]:
            if name not in seen:
                p.add_argument(f"--{name}", type=lambda x: int(x, 0), default=None)
                seen.add(name)


def build_parser():
    ap = argparse.ArgumentParser(
        description="AvmWrapper / UART_qsys 參數下載測試器 (取代 UI)"
    )
    sub = ap.add_subparsers(dest="mode", required=True)

    # selfcheck
    sp = sub.add_parser("selfcheck", help="不需硬體，驗證打包/解碼往返一致")
    sp.set_defaults(func=cmd_selfcheck)

    # params
    sp = sub.add_parser("params", help="列出某效果器有哪些參數")
    sp.add_argument("--fx", required=True, choices=list(SPECS))
    sp.set_defaults(func=cmd_params)

    # dump
    sp = sub.add_parser("dump", help="只印封包，不需硬體")
    sp.add_argument("--fx", required=True, choices=list(SPECS))
    add_fx_field_args(sp)
    sp.set_defaults(func=cmd_dump)

    # send
    sp = sub.add_parser("send", help="透過 serial 送出封包")
    sp.add_argument("--fx", required=True, choices=list(SPECS))
    sp.add_argument("--port", required=True)
    sp.add_argument("--baud", type=int, default=115200)
    sp.add_argument("--timeout", type=float, default=1.0)
    sp.add_argument("--byte-delay", dest="byte_delay", type=float, default=0.0,
                    help="逐 byte 間隔秒數 (RX 慢時可設 0.001)")
    add_fx_field_args(sp)
    sp.set_defaults(func=cmd_send)

    # loopback
    sp = sub.add_parser("loopback", help="TX 短接 RX 自我測試")
    sp.add_argument("--fx", required=True, choices=list(SPECS))
    sp.add_argument("--port", required=True)
    sp.add_argument("--baud", type=int, default=115200)
    sp.add_argument("--timeout", type=float, default=1.0)
    sp.add_argument("--byte-delay", dest="byte_delay", type=float, default=0.0)
    add_fx_field_args(sp)
    sp.set_defaults(func=cmd_loopback)

    # monitor
    sp = sub.add_parser("monitor", help="持續讀 serial 印出 bytes")
    sp.add_argument("--port", required=True)
    sp.add_argument("--baud", type=int, default=115200)
    sp.set_defaults(func=cmd_monitor)

    # script
    sp = sub.add_parser("script", help="從檔案批次送出多行命令")
    sp.add_argument("--file", required=True)
    sp.add_argument("--port", default=None)
    sp.add_argument("--baud", type=int, default=115200)
    sp.add_argument("--timeout", type=float, default=1.0)
    sp.add_argument("--byte-delay", dest="byte_delay", type=float, default=0.0)
    sp.add_argument("--gap", type=float, default=0.05,
                    help="每行之間的間隔秒數")
    sp.add_argument("--dry-run", action="store_true",
                    help="只印不送 (不需硬體)")
    sp.set_defaults(func=cmd_script)

    return ap


def main():
    ap = build_parser()
    args = ap.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
