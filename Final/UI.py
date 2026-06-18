#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Guitar FX Studio  —  PyQt5 vintage effects-pedal & tone-analysis UI  (v2)
=========================================================================

執行:
    pip install PyQt5 pyserial
    python guitar_fx_ui_v2.py

v2 變更:
  - 純黑底、vintage 質感、全英文 UI
  - 不分頁,10 個模組(含 Volume)排成 2 列 x 5 個,Volume 較小
  - 拉絲金屬旋鈕:輕微滾花 + 黑點指示 + 外圈 0~100 刻度 + 下方白色七段顯示器
  - FX Panel 為「獨立試聽」:每顆模組有 PLAY/STOP,同時只有一顆出聲
      * 選中(PLAY)的模組才解鎖,可調旋鈕/滑桿;其餘鎖住
      * Volume 為全域音量,永遠可調、無 play/stop
      * 切換試聽時送一個 preview 封包給 FPGA(0xC1,格式待定案,集中在 send_preview)
  - Stager:4 段插槽,選中的模組同樣可用旋鈕/滑桿調參數
  - Tone & Chord:被動接收 FPGA 回傳結果

== Mac -> FPGA ==
  參數 (6B):   [0xA5][module_id][param_id][value_hi][value_lo][xor]
  效果鏈 (6B): [0x5A][s1][s2][s3][s4][xor]
  試聽 (3B):   [0xC1][module_id][xor]      (module_id=0 表示全部停止;格式待定案)
== FPGA -> Mac (big-endian, xor=前面所有 byte XOR) ==
  音高 (5B):   [0xB1][note 0~11][freq_hi][freq_lo][xor]
  和弦 (4B):   [0xB2][root 0~11][quality][xor]
  STFT (變長): [0xB3][N][mag_0..mag_(N-1)][xor]   每個 mag 0~255
"""

import sys
import math
import threading
import time


# 優先用 PyQt5;若環境只有 PyQt6 也能跑
try:
    from PyQt5 import QtCore, QtGui, QtWidgets
    from PyQt5.QtCore import Qt, QPointF, QRectF, pyqtSignal
    QT = 5
except ImportError:
    from PyQt6 import QtCore, QtGui, QtWidgets
    from PyQt6.QtCore import Qt, QPointF, QRectF, pyqtSignal
    QT = 6
    # PyQt6 把列舉放進巢狀類別,這裡攤平回 PyQt5 風格,讓其餘程式不必改
    for _grp in ("AlignmentFlag", "FocusPolicy", "CursorShape", "KeyboardModifier",
                 "ScrollBarPolicy"):
        _g = getattr(Qt, _grp, None)
        if _g is not None:
            for _name in dir(_g):
                if not _name.startswith("_"):
                    setattr(Qt, _name, getattr(_g, _name))
    for _cls, _grp in ((QtGui.QPainter, None), (Qt, "PenStyle"), (Qt, "BrushStyle")):
        _g = getattr(Qt, _grp, None) if _grp else None
        if _g is not None:
            for _name in dir(_g):
                if not _name.startswith("_"):
                    setattr(Qt, _name, getattr(_g, _name))
    # QPainter.RenderHint(Antialiasing 等)
    _rh = getattr(QtGui.QPainter, "RenderHint", None)
    if _rh is not None:
        for _name in dir(_rh):
            if not _name.startswith("_"):
                setattr(QtGui.QPainter, _name, getattr(_rh, _name))
    # QPalette.ColorRole(ToolTipBase 等)
    _cr = getattr(QtGui.QPalette, "ColorRole", None)
    if _cr is not None:
        for _name in dir(_cr):
            if not _name.startswith("_"):
                setattr(QtGui.QPalette, _name, getattr(_cr, _name))
    # QLineCap(RoundCap 等)
    _pc = getattr(Qt, "PenCapStyle", None)
    if _pc is not None:
        for _name in dir(_pc):
            if not _name.startswith("_"):
                setattr(Qt, _name, getattr(_pc, _name))


def _no_vscroll(scroll_area):
    """設定捲動條政策:水平需要時出現、垂直關閉。相容 PyQt5/6 列舉路徑。"""
    pol = Qt.ScrollBarPolicy if hasattr(Qt, "ScrollBarPolicy") else Qt
    scroll_area.setHorizontalScrollBarPolicy(pol.ScrollBarAsNeeded)
    scroll_area.setVerticalScrollBarPolicy(pol.ScrollBarAlwaysOff)


def _app_exec(app):
    """PyQt5 是 exec_(),PyQt6 是 exec()。"""
    return app.exec_() if hasattr(app, "exec_") else app.exec()


try:
    import serial
    import serial.tools.list_ports
    HAVE_SERIAL = True
except Exception:
    HAVE_SERIAL = False


# =============================================================================
#  模組 / 參數定義
# =============================================================================
# control: "knob" | "slider"
# 5 參數模組(NoiseGate, Flanger)用倒ㄇ:3 滑桿 + 中間 2 旋鈕
MODULES = {
    "Overdrive": {"id": 0x01,
        "params": [
            ("i_gain", "Gain", "knob", 0.5, 1023),
            ("L", "Level", "slider", 0.5, 65535)
        ],
        "current_values": [0.5, 0.5],
    },
    "Fuzz": {"id": 0x02,
        "params": [
            ("i_gain", "Gain", "knob", 0.6, 1023),
            ("L", "Level", "slider", 0.5, 65535)
        ],
        "current_values": [0.6, 0.5],
    },
    "Distortion": {"id": 0x03,
        "params": [
            ("i_gain", "Gain", "knob", 0.6, 1023),
            ("L", "Level", "slider", 0.5, 65535)
        ],
        "current_values": [0.6, 0.5],
    },
    "Reverb": {"id": 0x04,
        "params": [
            ("wet_rate", "Wet", "slider", 0.4, 255),
            ("ap_gain", "Width", "knob", 0.5, 255)
        ],
        "current_values": [0.4, 0.5],
    },
    "NoiseGate": {"id": 0x05, "five": True,
        "params": [
            ("ng_rise_rate", "Rise", "slider", 0.4, 255),
            ("ng_decay_rate", "Decay", "slider", 0.4, 255),
            ("ng_hold", "Hold", "slider", 0.4, 65535),
            ("ng_threshold_low", "Th.Lo", "slider", 0.3, 32767),
            ("ng_threshold_high", "Th.Hi", "slider", 0.7, 32767)
        ],
        "current_values": [0.4, 0.4, 0.4, 0.3, 0.7],
    },
    "Delay": {"id": 0x06,
        "params": [
            ("delay_time", "Time", "knob", 0.4, 65535),
            ("delay_feedback", "F.back", "slider", 0.3, 255),
            ("delay_mix", "Mix", "slider", 0.5, 255)
        ],
        "current_values": [0.4, 0.3, 0.5],
    },
    "Flanger": {"id": 0x07, "five": True,
        "params": [
            ("inc", "Speed", "knob", 0.5, 127),
            ("delay_base", "Depth", "knob", 0.4, 1023),
            ("delay_amp", "Range", "knob", 0.4, 1023),
            ("gain", "F.back", "knob", 0.5, 255),
            ("wet_rate", "Mix", "knob", 0.5, 255)
        ],
        "current_values": [0.5, 0.4, 0.4, 0.5, 0.5],
    },
    "Chorus": {"id": 0x08,
        "params": [
            ("in", "Speed", "knob", 0.5, 127),
            ("delay_base", "Depth", "knob", 0.4, 4095),
            ("delay_amp", "Range", "knob", 0.4, 4095),
            ("wet_rate", "Mix", "slider", 0.5, 255)
        ],
        "current_values": [0.5, 0.4, 0.4, 0.5],
    },
    "Auto_Wah": {"id": 0x09,
        "params": [
            ("in", "Speed", "knob", 0.5, 127),
            ("delay_base", "Depth", "knob", 0.4, 4095),
            ("delay_amp", "Range", "knob", 0.4, 4095),
            ("wet_rate", "Mix", "slider", 0.5, 255)
        ],
        "current_values": [0.5, 0.4, 0.4, 0.5],
    },
    "Volume": {"id": 0x0B,
        "params": [
            ("i_gain", "Master", "knob", 0.7, 127)
        ],
        "current_values": [0.7],
    },
}

# FX Panel 2x5 排列順序(Volume 放最後、做小)
PANEL_ORDER = ["Reverb", "Delay", "Flanger", "Overdrive", "Chorus",
               "Fuzz", "Distortion", "NoiseGate", "Auto_Wah", "Volume"]

PARAM_ID = {}
for _m, _d in MODULES.items():
    for _i, _p in enumerate(_d["params"]):
        PARAM_ID[(_m, _p[0])] = _i


# =============================================================================
#  色票  —  純黑 vintage
# =============================================================================
class C:
    bg          = QtGui.QColor(10, 10, 10)
    panel_face  = QtGui.QColor(22, 22, 22)
    panel_face2 = QtGui.QColor(14, 14, 14)
    panel_edge  = QtGui.QColor(150, 130, 95)     # 暗金邊框(vintage)
    ink         = QtGui.QColor(232, 226, 212)
    ink_dim     = QtGui.QColor(232, 226, 212, 130)
    brass       = QtGui.QColor(190, 158, 96)
    seven_on    = QtGui.QColor(245, 245, 245)
    seven_off   = QtGui.QColor(38, 38, 38)
    led_on      = QtGui.QColor(120, 230, 140)
    led_off     = QtGui.QColor(45, 45, 45)


# =============================================================================
#  拉絲金屬旋鈕  —  滾輪控制,要先點一下「拿起」;選中模組才 enabled
#  外圈 0~100 刻度 + 黑點指示 + 下方七段顯示器
# =============================================================================
SEG_MAP = {
    '0': "abcdef", '1': "bc", '2': "abged", '3': "abgcd", '4': "fgbc",
    '5': "afgcd", '6': "afgcde", '7': "abc", '8': "abcdefg", '9': "abcdfg",
    ' ': "", '-': "g",
}

class Knob(QtWidgets.QWidget):
    valueChanged = pyqtSignal(float)

    # size 預設組: (widget_w, widget_h, knob_r, tick_r, seven_w, seven_h, font)
    SIZES = {
        "tiny":   (84, 104, 21, 31, 6, 10, 5),
        "small":  (104, 128, 26, 39, 7, 13, 6),
        "normal": (128, 156, 33, 49, 9, 15, 7),
        "large":  (160, 196, 43, 63, 12, 20, 8),
    }

    def __init__(self, label="", value=0.5, size="normal", parent=None):
        super().__init__(parent)
        self._value = value
        self._label = label
        self._armed = False
        self._size = size
        w, h, *_ = self.SIZES[size]
        self.setFixedSize(w, h)
        self.setFocusPolicy(Qt.ClickFocus)
        self.setToolTip("Click to grab, then scroll to adjust")

    def value(self):
        return self._value

    def setValue(self, v):
        v = max(0.0, min(1.0, v))
        if abs(v - self._value) > 1e-6:
            self._value = v
            self.update()
            self.valueChanged.emit(v)

    def mousePressEvent(self, e):
        if not self.isEnabled():
            return
        self._armed = not self._armed
        self.setFocus()
        self.update()

    def focusOutEvent(self, e):
        self._armed = False
        self.update()
        super().focusOutEvent(e)

    def wheelEvent(self, e):
        if not self.isEnabled() or not self._armed:
            e.ignore()
            return
        step = 0.02 if (e.modifiers() & Qt.ShiftModifier) else 0.05
        self.setValue(self._value + (e.angleDelta().y() / 120.0) * step)
        e.accept()

    def paintEvent(self, e):
        p = QtGui.QPainter(self)
        p.setRenderHint(QtGui.QPainter.Antialiasing)
        W = self.width()
        ww, hh, knob_r, tick_r, sv_w, sv_h, fsz = self.SIZES[self._size]
        cx = W / 2
        cy = tick_r + 8           # 上方留刻度數字空間
        START, SWEEP = 225.0, -270.0
        dim = not self.isEnabled()

        # ---- 外圈刻度 (0~100) ----
        total_minor = 50
        p.setFont(QtGui.QFont("Helvetica", fsz))
        for i in range(total_minor + 1):
            frac = i / total_minor
            ang = math.radians(START + SWEEP * frac)
            is_major = (i % 5 == 0)
            r_out = tick_r
            r_in = tick_r - (knob_r * 0.23 if is_major else knob_r * 0.13)
            x1 = cx + math.cos(ang) * r_in
            y1 = cy - math.sin(ang) * r_in
            x2 = cx + math.cos(ang) * r_out
            y2 = cy - math.sin(ang) * r_out
            if dim:
                col = QtGui.QColor(90, 90, 90) if is_major else QtGui.QColor(50, 50, 50)
            else:
                col = QtGui.QColor(225, 225, 225) if is_major else QtGui.QColor(110, 110, 110)
            p.setPen(QtGui.QPen(col, 1.4 if is_major else 0.7))
            p.drawLine(QPointF(x1, y1), QPointF(x2, y2))
            if is_major:
                val = int(round(frac * 100))
                tx = cx + math.cos(ang) * (tick_r + 7)
                ty = cy - math.sin(ang) * (tick_r + 7)
                p.setPen(QtGui.QColor(170, 170, 170) if not dim else QtGui.QColor(80, 80, 80))
                p.drawText(QRectF(tx - 10, ty - 6, 20, 12), Qt.AlignCenter, str(val))

        # ---- 旋鈕外圈陰影底座 ----
        for i in range(8, 0, -1):
            rr = knob_r + i
            a = 8 + (8 - i) * 8
            p.setBrush(QtGui.QColor(0, 0, 0, a))
            p.setPen(Qt.NoPen)
            p.drawEllipse(QPointF(cx, cy), rr, rr)
        p.setBrush(QtGui.QColor(16, 16, 16))
        p.drawEllipse(QPointF(cx, cy), knob_r + 4, knob_r + 4)

        # ---- 拉絲金屬盤面(角度反光,平滑) ----
        steps = 360
        for s in range(steps):
            ang = s * (360 / steps)
            shine = (math.cos(math.radians(ang - 70)) ** 2) * 0.6 + \
                    (math.cos(math.radians(ang - 250)) ** 2) * 0.4
            g = int(70 + shine * 160)
            g = max(55, min(240, g))
            if dim:
                g = int(40 + (g - 55) * 0.35)
            rad = math.radians(ang)
            x2 = cx + math.cos(rad) * knob_r
            y2 = cy - math.sin(rad) * knob_r
            p.setPen(QtGui.QPen(QtGui.QColor(g, g, g), 1.6))
            p.drawLine(QPointF(cx, cy), QPointF(x2, y2))
        grad = QtGui.QRadialGradient(cx, cy, knob_r)
        grad.setColorAt(0.0, QtGui.QColor(0, 0, 0, 0))
        grad.setColorAt(0.75, QtGui.QColor(0, 0, 0, 0))
        grad.setColorAt(1.0, QtGui.QColor(0, 0, 0, 90))
        p.setBrush(grad)
        p.setPen(Qt.NoPen)
        p.drawEllipse(QPointF(cx, cy), knob_r, knob_r)

        # ---- 輕微滾花邊 ----
        knurl_n = 72
        for i in range(knurl_n):
            ang = math.radians(i * (360 / knurl_n))
            r1 = knob_r - 2.5
            x1 = cx + math.cos(ang) * r1
            y1 = cy - math.sin(ang) * r1
            x2 = cx + math.cos(ang) * knob_r
            y2 = cy - math.sin(ang) * knob_r
            shade = QtGui.QColor(30, 30, 30, 130) if i % 2 == 0 else QtGui.QColor(150, 150, 150, 70)
            p.setPen(QtGui.QPen(shade, 0.8))
            p.drawLine(QPointF(x1, y1), QPointF(x2, y2))

        p.setPen(QtGui.QPen(QtGui.QColor(210, 210, 210, 90), 1))
        p.setBrush(Qt.NoBrush)
        p.drawEllipse(QPointF(cx, cy), knob_r, knob_r)

        if self._armed:
            p.setPen(QtGui.QPen(C.brass, 2))
            p.drawEllipse(QPointF(cx, cy), knob_r + 6, knob_r + 6)

        # ---- 黑色指示點 ----
        ind = math.radians(START + SWEEP * self._value)
        dr = knob_r * 0.62
        dx = cx + math.cos(ind) * dr
        dy = cy - math.sin(ind) * dr
        dot = max(2.2, knob_r * 0.1)
        p.setBrush(QtGui.QColor(12, 12, 12))
        p.setPen(QtGui.QPen(QtGui.QColor(60, 60, 60, 150), 1))
        p.drawEllipse(QPointF(dx, dy), dot, dot)

        # ---- 標籤 ----
        p.setPen(C.ink_dim if dim else C.ink)
        p.setFont(QtGui.QFont("Helvetica", max(7, fsz + 2)))
        p.drawText(QRectF(0, cy + knob_r + 5, W, 13), Qt.AlignHCenter, self._label)

        # ---- 七段顯示器 ----
        self._draw_seven(p, f"{int(round(self._value*100)):3d}", cx,
                         cy + knob_r + 28, dim, sv_w, sv_h)

    def _draw_seven(self, p, text, cx, top, dim, w, h):
        gap, th = max(2, w * 0.45), max(1.5, w * 0.22)
        total = len(text) * w + (len(text) - 1) * gap
        x0 = cx - total / 2
        on = C.seven_on if not dim else QtGui.QColor(110, 110, 110)
        off = C.seven_off
        for ch in text:
            segs = SEG_MAP.get(ch, "")
            x, y = x0, top
            def seg(name, x1, y1, x2, y2):
                p.setPen(QtGui.QPen(on if name in segs else off, th))
                p.drawLine(QPointF(x1, y1), QPointF(x2, y2))
            seg('a', x+th, y, x+w-th, y)
            seg('b', x+w, y+th, x+w, y+h/2-th)
            seg('c', x+w, y+h/2+th, x+w, y+h-th)
            seg('d', x+th, y+h, x+w-th, y+h)
            seg('e', x, y+h/2+th, x, y+h-th)
            seg('f', x, y+th, x, y+h/2-th)
            seg('g', x+th, y+h/2, x+w-th, y+h/2)
            x0 += w + gap


# =============================================================================
#  直立滑桿(vintage:深槽 + 暗金填充 + 金屬把手)
# =============================================================================
class VSlider(QtWidgets.QWidget):
    valueChanged = pyqtSignal(float)

    def __init__(self, label="", value=0.5, horizontal=False, size="normal", parent=None):
        super().__init__(parent)
        self._value = value
        self._label = label
        self._horizontal = horizontal
        self._size = size
        self._drag = False
        if horizontal:
            self.setFixedSize(150, 46)
        else:
            h = {"small": 112, "normal": 136, "bigger": 160, "large": 256}[size]
            w = {"small": 30, "normal": 35, "bigger": 40, "large": 40}[size]
            self.setFixedSize(w, h)

    def value(self):
        return self._value

    def setValue(self, v):
        v = max(0.0, min(1.0, v))
        if abs(v - self._value) > 1e-6:
            self._value = v
            self.update()
            self.valueChanged.emit(v)

    def _track(self):
        if self._horizontal:
            return QRectF(12, self.height()/2 - 3, self.width() - 24, 6)
        return QRectF(self.width()/2 - 3, 6, 6, self.height() - 38)

    def _to_val(self, pos):
        t = self._track()
        if self._horizontal:
            return max(0.0, min(1.0, (pos.x() - t.left()) / t.width()))
        return max(0.0, min(1.0, 1.0 - (pos.y() - t.top()) / t.height()))

    def mousePressEvent(self, e):
        if not self.isEnabled():
            return
        self._drag = True
        self.setValue(self._to_val(e.pos()))

    def mouseMoveEvent(self, e):
        if self._drag and self.isEnabled():
            self.setValue(self._to_val(e.pos()))

    def mouseReleaseEvent(self, e):
        self._drag = False

    def paintEvent(self, e):
        p = QtGui.QPainter(self)
        p.setRenderHint(QtGui.QPainter.Antialiasing)
        t = self._track()
        dim = not self.isEnabled()

        p.setPen(Qt.NoPen)
        p.setBrush(QtGui.QColor(6, 6, 6))
        p.drawRoundedRect(t, 3, 3)

        if self._horizontal:
            fill = QRectF(t.left(), t.top(), t.width() * self._value, t.height())
        else:
            fh = t.height() * self._value
            fill = QRectF(t.left(), t.bottom() - fh, t.width(), fh)
        p.setBrush(C.brass if not dim else QtGui.QColor(80, 70, 50))
        p.drawRoundedRect(fill, 3, 3)

        if self._horizontal:
            hx, hy = t.left() + t.width() * self._value, t.center().y()
        else:
            hx, hy = t.center().x(), t.bottom() - t.height() * self._value
        hg = QtGui.QRadialGradient(hx - 3, hy - 3, 12)
        if dim:
            hg.setColorAt(0, QtGui.QColor(120, 120, 120))
            hg.setColorAt(1, QtGui.QColor(70, 70, 70))
        else:
            hg.setColorAt(0, QtGui.QColor(235, 235, 235))
            hg.setColorAt(1, QtGui.QColor(150, 150, 150))
        p.setBrush(hg)
        p.setPen(QtGui.QPen(QtGui.QColor(10, 10, 10), 1))
        p.drawEllipse(QPointF(hx, hy), 7, 7)

        p.setPen(C.ink_dim if dim else C.ink_dim)
        p.setFont(QtGui.QFont("Helvetica", 10))
        if self._horizontal:
            p.drawText(QRectF(0, 2, self.width(), 24), Qt.AlignHCenter,
                       f"{self._label} {int(self._value*100)}")
        else:
            p.drawText(QRectF(0, self.height() - 26, self.width(), 12),
                       Qt.AlignHCenter, f"{int(self._value*100)}")
            p.drawText(QRectF(0, self.height() - 12, self.width(), 12),
                       Qt.AlignHCenter, self._label)


# =============================================================================
#  模組面板(2x5 用)
# =============================================================================
class ModulePanel(QtWidgets.QFrame):
    paramChanged = pyqtSignal(str, str, float)
    previewToggled = pyqtSignal(str, bool)   # module, playing

    PANEL_W = 272
    PANEL_H = 500

    def __init__(self, name, spec, parent=None):
        super().__init__(parent)
        self.name = name
        self.spec = spec
        self.controls = {}
        self.setFixedSize(self.PANEL_W, self.PANEL_H)   # 統一大小
        self._build()
        self.set_selected(False)   # 預設鎖住

    def _build(self):
        outer = QtWidgets.QVBoxLayout(self)
        outer.setContentsMargins(12, 10, 12, 12)
        outer.setSpacing(6)

        head = QtWidgets.QHBoxLayout()
        title = QtWidgets.QLabel(self.name.replace("_", " ").upper())
        tf = title.font(); tf.setPointSize(11); tf.setBold(True); title.setFont(tf)
        title.setStyleSheet("color:#E8E2D4; letter-spacing:2px;")
        head.addWidget(title)
        head.addStretch(1)
        self.led = QtWidgets.QLabel()
        self.led.setFixedSize(14, 14)
        self._style_led(False)
        head.addWidget(self.led)
        outer.addLayout(head)

        body = QtWidgets.QWidget()
        params = self.spec["params"]
        if self.name == "NoiseGate":
            self._build_NG(body)
        elif self.name == "Flanger":
            self._build_FL(body)
        elif self._is_knob_slider_pair(params):
            self._build_centered_knob(body)   # 單旋鈕+單滑桿:大旋鈕置中
        elif len(self.spec["params"]) == 2:
            self._build_two_param(body)
        elif len(self.spec["params"]) == 4:
            self._build_four_param(body)
        else:
            self._build_normal(body)
        outer.addWidget(body, 1)

        self.play_btn = QtWidgets.QPushButton("PLAY")
        self.play_btn.setCheckable(True)
        self.play_btn.setCursor(Qt.PointingHandCursor)
        self.play_btn.setStyleSheet(self._play_css())
        self.play_btn.toggled.connect(self._on_play)
        outer.addWidget(self.play_btn)

    @staticmethod
    def _is_knob_slider_pair(params):
        if len(params) != 2:
            return False
        types = sorted(p[2] for p in params)
        return types == ["knob", "slider"]

    def _make(self, key, label, ctype, default, size="normal"):
        w = (Knob(label, default, size=size) if ctype == "knob"
             else VSlider(label, default, size=size))
        w.valueChanged.connect(lambda v, k=key: self.paramChanged.emit(self.name, k, v))
        self.controls[key] = w
        return w

    def _build_normal(self, host):
        lay = QtWidgets.QVBoxLayout(host)
        lay.setContentsMargins(0, 0, 0, 0); lay.setSpacing(4)
        lay.addStretch(1)
        row = QtWidgets.QHBoxLayout()
        n = len(self.spec["params"])
        row.setSpacing(10 if n <= 2 else 6)
        row.addStretch(1)
        for pr in self.spec["params"]:
            # 控制少(≤2)全部放大;控制多(3~4)旋鈕 large、滑桿 normal 才不擠
            if n <= 2:
                sz = "large"
            else:
                sz = "large"
            row.addWidget(self._make(pr[0], pr[1], pr[2], pr[3], size=sz), 0, Qt.AlignBottom | Qt.AlignHCenter)
        row.addStretch(1)
        lay.addLayout(row)
        lay.addStretch(1)
        
    def _build_two_param(self, host):
        # Explicitly create a Vertical Layout for 2-parameter pedals
        v_layout = QtWidgets.QVBoxLayout(host)
        v_layout.setSpacing(10)
        v_layout.addStretch(5) # Pushes the knobs towards the center
        
        # Loop through the two parameters (e.g., Gain and Level)
        for pr in self.spec["params"]:
            # Manually unpack to avoid the previous argument collision bug
            p_id, p_title, p_type, p_default, p_range = pr
            
            # Create the widget and add it to the vertical column
            widget = self._make(p_id, p_title, p_type, default=p_default, size="normal")
            v_layout.addWidget(widget, 0, Qt.AlignHCenter)
            
        v_layout.addStretch(1)
        
    def _build_four_param(self, host):
        lay = QtWidgets.QVBoxLayout(host)
        lay.setContentsMargins(0, 0, 0, 0); lay.setSpacing(4)
        lay.addStretch(1)
        row1 = QtWidgets.QHBoxLayout()
        n = len(self.spec["params"])
        row1.setSpacing(10 if n <= 2 else 6)
        row1.addStretch(1)
        for pr in self.spec["params"][0:2]:
            sz = "normal"
            row1.addWidget(self._make(pr[0], pr[1], pr[2], pr[3], size=sz), 0, Qt.AlignBottom | Qt.AlignHCenter)
        row1.addStretch(1)
        lay.addLayout(row1)
        lay.addStretch(1)
        
        row2 = QtWidgets.QHBoxLayout()
        n = len(self.spec["params"])
        row2.setSpacing(10 if n <= 2 else 6)
        row2.addStretch(1)
        for pr in self.spec["params"][2:4]:
            sz = "normal" if pr[2] == "knob" else "bigger"
            row2.addWidget(self._make(pr[0], pr[1], pr[2], pr[3], size=sz), 0, Qt.AlignBottom | Qt.AlignHCenter)
            row2.addStretch(35)
        lay.addLayout(row2)
        lay.addStretch(1)
        
    def _build_NG(self, host):
        lay = QtWidgets.QVBoxLayout(host)
        lay.setContentsMargins(0, 0, 0, 0); lay.setSpacing(4)
        lay.addStretch(1)
        row1 = QtWidgets.QHBoxLayout()
        n = len(self.spec["params"])
        row1.setSpacing(10 if n <= 2 else 6)
        row1.addStretch(1)
        for pr in self.spec["params"][0:5]:
            sz = "large"
            row1.addWidget(self._make(pr[0], pr[1], pr[2], pr[3], size=sz), 0, Qt.AlignBottom | Qt.AlignHCenter)
        row1.addStretch(1)
        lay.addLayout(row1)
        lay.addStretch(1)
        
        
    def _build_FL(self, host):
        lay = QtWidgets.QVBoxLayout(host)
        lay.setContentsMargins(0, 0, 0, 0); lay.setSpacing(4)
        lay.addStretch(1)
        row1 = QtWidgets.QHBoxLayout()
        n = len(self.spec["params"])
        row1.setSpacing(10 if n <= 2 else 6)
        row1.addStretch(1)
        for pr in self.spec["params"][0:2]:
            sz = "normal"
            row1.addWidget(self._make(pr[0], pr[1], pr[2], pr[3], size=sz), 0, Qt.AlignBottom | Qt.AlignHCenter)
        row1.addStretch(1)
        lay.addLayout(row1)
        lay.addStretch(1)
        
        row2 = QtWidgets.QHBoxLayout()
        n = len(self.spec["params"])
        row2.setSpacing(10 if n <= 2 else 6)
        row2.addStretch(35)
        
        pr = self.spec["params"][2]
        sz = "normal" if pr[2] == "knob" else "bigger"
        row2.addWidget(self._make(pr[0], pr[1], pr[2], pr[3], size=sz), 0, Qt.AlignHCenter)
        row2.addStretch(35)
        
        lay.addLayout(row2)
        lay.addStretch(1)
        
        row3 = QtWidgets.QHBoxLayout()
        n = len(self.spec["params"])
        row3.setSpacing(10 if n <= 2 else 6)
        row3.addStretch(1)
        for pr in self.spec["params"][3:5]:
            sz = "normal" if pr[2] == "knob" else "bigger"
            row3.addWidget(self._make(pr[0], pr[1], pr[2], pr[3], size=sz), 0, Qt.AlignBottom | Qt.AlignHCenter)
            row3.addStretch(35)
        lay.addLayout(row3)
        lay.addStretch(1)

    def _build_centered_knob(self, host):
        """單旋鈕 + 單滑桿:旋鈕放中間且放大,滑桿放旁邊。"""
        params = self.spec["params"]
        knob_pr = next(p for p in params if p[2] == "knob")
        slider_pr = next(p for p in params if p[2] == "slider")
        lay = QtWidgets.QVBoxLayout(host)
        lay.setContentsMargins(0, 0, 0, 0)
        lay.addStretch(1)
        row = QtWidgets.QHBoxLayout()
        row.setSpacing(10)
        row.addStretch(1)
        
        # row.addWidget(self._make(*slider_pr, size="large"), 0, Qt.AlignBottom | Qt.AlignHCenter)
        
        # Unpack the 4 tuple items manually
        p_id, p_title, p_type, p_default, p_scale = slider_pr

        # Pass them explicitly to avoid positional collisions
        # *Note: Check your _make() definition to ensure the 4th parameter is actually named 'default' (or adjust as needed)
        widget = self._make(p_id, p_title, p_type, default=p_default, size="large")

        row.addWidget(widget, 0, Qt.AlignBottom | Qt.AlignHCenter)
        
        # row.addWidget(self._make(*knob_pr, size="large"), 0, Qt.AlignVCenter | Qt.AlignHCenter)
        
        # Unpack the 4 tuple items manually
        k_id, k_title, k_type, k_default, k_scale = knob_pr

        # Pass them explicitly to avoid positional collisions
        # *Note: Just like before, ensure 'default' matches your _make() parameter name
        widget = self._make(k_id, k_title, k_type, default=k_default, size="large")

        row.addWidget(widget, 0, Qt.AlignVCenter | Qt.AlignHCenter)

        row.addStretch(1)
        lay.addLayout(row)
        lay.addStretch(1)

    def _build_five(self, host):
        p = self.spec["params"]
        grid = QtWidgets.QGridLayout(host)
        grid.setContentsMargins(0, 0, 0, 0)
        grid.setHorizontalSpacing(6); grid.setVerticalSpacing(8)
        # 倒ㄇ:左右柱用 small 滑桿拉開、頂用 normal 滑桿、中欄兩旋鈕 normal
        left  = self._make(p[0][0], p[0][1], p[0][2], p[0][3], size="small")
        knob1 = self._make(p[1][0], p[1][1], p[1][2], p[1][3], size="normal")
        knob2 = self._make(p[2][0], p[2][1], p[2][2], p[2][3], size="normal")
        top   = self._make(p[3][0], p[3][1], p[3][2], p[3][3], size="normal")
        right = self._make(p[4][0], p[4][1], p[4][2], p[4][3], size="small")
        grid.addWidget(top,   0, 0, 1, 3, Qt.AlignHCenter)
        grid.addWidget(left,  1, 0, 2, 1, Qt.AlignBottom | Qt.AlignHCenter)
        grid.addWidget(knob1, 1, 1, Qt.AlignHCenter)
        grid.addWidget(knob2, 2, 1, Qt.AlignHCenter)
        grid.addWidget(right, 1, 2, 2, 1, Qt.AlignBottom | Qt.AlignHCenter)
        grid.setRowStretch(0, 1)
        grid.setRowStretch(2, 1)
        grid.setColumnStretch(0, 1)
        grid.setColumnStretch(2, 1)

    def _style_led(self, on):
        c = C.led_on if on else C.led_off
        self.led.setStyleSheet(
            f"background:{c.name()}; border-radius:7px; border:2px solid #0a0a0a;")

    def _play_css(self):
        return (
            "QPushButton{background:#1a1a1a; color:#BE9E60; border:1px solid #6e5e3c;"
            "border-radius:6px; padding:6px; font-weight:bold; letter-spacing:2px;}"
            "QPushButton:checked{background:#BE9E60; color:#0a0a0a;}"
            "QPushButton:hover{border-color:#BE9E60;}"
        )

    def _on_play(self, on):
        self.play_btn.setText("STOP" if on else "PLAY")
        self._style_led(on)
        self.previewToggled.emit(self.name, on)

    def set_playing_silently(self, on):
        self.play_btn.blockSignals(True)
        self.play_btn.setChecked(on)
        self.play_btn.setText("STOP" if on else "PLAY")
        self._style_led(on)
        self.play_btn.blockSignals(False)
        self.set_selected(on)

    def set_selected(self, sel):
        for w in self.controls.values():
            w.setEnabled(sel)
        self.setProperty("selected", sel)
        self.style().unpolish(self); self.style().polish(self)
        self.update()

    def paintEvent(self, e):
        p = QtGui.QPainter(self)
        p.setRenderHint(QtGui.QPainter.Antialiasing)
        r = self.rect().adjusted(2, 2, -2, -2)
        path = QtGui.QPainterPath()
        path.addRoundedRect(QRectF(r), 12, 12)
        face = QtGui.QLinearGradient(r.topLeft(), r.bottomRight())
        face.setColorAt(0, C.panel_face)
        face.setColorAt(1, C.panel_face2)
        p.fillPath(path, face)
        sel = bool(self.property("selected"))
        edge = C.brass if sel else C.panel_edge
        p.setPen(QtGui.QPen(edge, 2 if sel else 1.4))
        p.setBrush(Qt.NoBrush)
        p.drawPath(path)
        p.setBrush(QtGui.QColor(70, 64, 50)); p.setPen(Qt.NoPen)
        for sx, sy in [(r.left()+9, r.top()+9), (r.right()-9, r.top()+9),
                       (r.left()+9, r.bottom()-9), (r.right()-9, r.bottom()-9)]:
            p.drawEllipse(QPointF(sx, sy), 2.5, 2.5)
        super().paintEvent(e)


# =============================================================================
#  UART
# =============================================================================
class UartManager(QtCore.QObject):
    log = pyqtSignal(str)
    noteReceived     = pyqtSignal(int, int)
    chordReceived    = pyqtSignal(int, int)
    spectrumReceived = pyqtSignal(object)

    def __init__(self):
        super().__init__()
        self.ser = None
        self._reader = None
        self._stop = False

    def list_ports(self):
        if not HAVE_SERIAL:
            return []
        return [p.device for p in serial.tools.list_ports.comports()]

    def connect(self, port, baud):
        if not HAVE_SERIAL:
            self.log.emit("pyserial not installed - simulation (log only)")
            return False
        try:
            self.ser = serial.Serial(port, int(baud), timeout=0.1)
            self.log.emit(f"Connected {port} @ {baud}")
            self._stop = False
            self._reader = threading.Thread(target=self._read_loop, daemon=True)
            self._reader.start()
            return True
        except Exception as ex:
            self.log.emit(f"Connect failed: {ex}")
            self.ser = None
            return False

    def disconnect(self):
        self._stop = True
        if self._reader:
            self._reader.join(timeout=0.5); self._reader = None
        if self.ser:
            self.ser.close(); self.ser = None
            self.log.emit("Disconnected")

    def _write(self, pkt, tag):
        hexs = " ".join(f"{b:02X}" for b in pkt)
        if self.ser:
            try:
                self.ser.write(pkt)
            except Exception as ex:
                self.log.emit(f"TX fail: {ex}")
        self.log.emit(f"TX {tag}  {hexs}")

    # def send_param(self, module, key, value):
    #     mid = MODULES[module]["id"]; pid = PARAM_ID[(module, key)]
    #     val = int(round(max(0.0, min(1.0, value)) * 1000))
    #     hi, lo = (val >> 8) & 0xFF, val & 0xFF
    #     chk = 0xA5 ^ mid ^ pid ^ hi ^ lo
        
    #     self._write(bytes([0xA5, mid, pid, hi, lo, chk & 0xFF]),
    #                 f"[{module}.{key}={val}]")
        
    def send_module_state(self, module_name, dummy):
        # if not self.ser or not self.ser.is_open:
        #     return
            
        module = MODULES.get(module_name)
        if not module:
            return

        packet = bytearray(32)
        packet[0] = module["id"] & 0xFF  # [255:248] Address
        
        # Grab the current float values (0.0 to 1.0)
        params = module["params"]
        current_floats = module["current_values"]
        
        # You MUST scale these floats to your Verilog integers here!
        # Example: scaled_ints = [int(f * 65535) for f in current_floats]
        scaled_ints = self._scale_parameters(module_name, current_floats) 

        # Pack into 16-bit chunks starting from the end [15:0], [31:16], etc.
        for i, val in enumerate(scaled_ints):
            idx_hi = 30 - (i * 2)
            idx_lo = 31 - (i * 2)
            packet[idx_hi] = (val >> 8) & 0xFF
            packet[idx_lo] = val & 0xFF

        self._write(packet, module_name)
        
    def send_stager(self, stages):
        # if not self.ser or not self.ser.is_open:
        #     return
        
        ids = [MODULES[s]["id"] if s and s in MODULES else 0 for s in stages]
            
        packet = bytearray(32)
        packet[0] = 10  # ADDR_ST is 10 [255:248]
        
        # Map the 4 slots to [31:0]
        packet[28] = ids[0] & 0xFF  # [31:24]
        packet[29] = ids[1] & 0xFF  # [23:16]
        packet[30] = ids[2] & 0xFF  # [15:8]
        packet[31] = ids[3] & 0xFF  # [7:0]
        
        self._write(packet, "staging")


    # def send_chain(self, stages):
    #     ids = [MODULES[s]["id"] if s and s in MODULES else 0 for s in stages]
    #     chk = 0x5A
    #     for i in ids:
    #         chk ^= i
    #     self._write(bytes([0x5A] + ids + [chk & 0xFF]), f"CHAIN {stages}")

    def send_preview(self, module_name):
        """試聽哪顆。module_or_none=None 表示全部停止。
        封包格式 [0xC1][module_id][xor] 為暫定,待 FPGA 端定案後改這裡即可。"""
        # mid = MODULES[module_or_none]["id"] if module_or_none else 0x00
        # chk = 0xC1 ^ mid
        # self._write(bytes([0xC1, mid, chk & 0xFF]),
        #             f"PREVIEW {module_or_none or 'STOP'}")
        
        if module_name == None:
            combo = [None, None, None, None]
            self.send_stager(combo)
            return
        else:
            module = MODULES.get(module_name)
            if not module:
                print("preview failed")
                print(module_name)
                return
            combo = [module_name, None, None, None]
            self.send_stager(combo)
            self.send_module_state(module_name, 0)


    # 接收
    def _read_loop(self):
        buf = bytearray()
        while not self._stop and self.ser:
            try:
                chunk = self.ser.read(64)
            except Exception:
                break
            if chunk:
                buf.extend(chunk)
                self._parse(buf)

    def _parse(self, buf):
        while buf:
            h = buf[0]
            if h == 0xB1:
                if len(buf) < 5: return
                pkt = buf[:5]
                if self._xor(pkt):
                    self.noteReceived.emit(pkt[1], (pkt[2] << 8) | pkt[3])
                del buf[:5]
            elif h == 0xB2:
                if len(buf) < 4: return
                pkt = buf[:4]
                if self._xor(pkt):
                    self.chordReceived.emit(pkt[1], pkt[2])
                del buf[:4]
            elif h == 0xB3:
                if len(buf) < 2: return
                n = buf[1]; total = 2 + n + 1
                if len(buf) < total: return
                pkt = buf[:total]
                if self._xor(pkt):
                    self.spectrumReceived.emit([b / 255.0 for b in pkt[2:2+n]])
                del buf[:total]
            else:
                del buf[0]
                
    def _scale_parameters(self, module_name, current_floats):
        module = MODULES[module_name]
        params = module["params"]
        ranges = [p[4] for p in params]
        return [int(f * r) for f, r in zip(current_floats, ranges)]
        

    @staticmethod
    def _xor(pkt):
        c = 0
        for b in pkt[:-1]:
            c ^= b
        return (c & 0xFF) == pkt[-1]


# =============================================================================
#  FX Panel 頁  —  兩頁 W 排列,獨立試聽,右下角音量 + 頁數鈕
# =============================================================================
# 每頁的 W 折線:0=上、1=下 的垂直偏移比例(再錯開更明顯)
PAGE1 = ["Reverb", "Delay", "Flanger", "Overdrive", "Chorus"]
PAGE2 = ["Fuzz", "Distortion", "NoiseGate", "Auto_Wah"]
W_PATTERN_5 = [0.0, 1.0, 0.0, 1.0, 0.0]      # 高低高低高
W_PATTERN_4 = [0.0, 1.0, 0.0, 1.0]           # 高低高低
W_OFFSET = 72                                # 錯開幅度(模組變高,適度即可)

class FxPanelPage(QtWidgets.QWidget):
    def __init__(self, uart, parent=None):
        super().__init__(parent)
        self.uart = uart
        self.panels = {}
        self._current = None
        self._page = 0
        self._build()

    def _build(self):
        root = QtWidgets.QVBoxLayout(self)
        root.setContentsMargins(24, 18, 24, 14)
        root.setSpacing(8)

        title = QtWidgets.QLabel("FX  PANEL")
        f = title.font(); f.setPointSize(16); f.setBold(True); title.setFont(f)
        title.setStyleSheet("color:#BE9E60; letter-spacing:6px;")
        title.setAlignment(Qt.AlignHCenter)
        root.addWidget(title)
        hint = QtWidgets.QLabel("Press PLAY on a module to audition it. "
                                "Only one plays at a time; its controls unlock while playing.")
        hint.setStyleSheet("color:#8a8270;")
        hint.setAlignment(Qt.AlignHCenter)
        root.addWidget(hint)

        # 兩頁 W 排列疊在 stack,外層套水平捲動保險(視窗縮窄也不擠爆)
        self.stack = QtWidgets.QStackedWidget()
        self.stack.addWidget(self._wrap_scroll(self._make_w_page(PAGE1, W_PATTERN_5)))
        self.stack.addWidget(self._wrap_scroll(self._make_w_page(PAGE2, W_PATTERN_4)))
        root.addWidget(self.stack, 1)

        # 底列:UART 連線(左) + 音量(中) + 頁數鈕(右)
        bottom = QtWidgets.QHBoxLayout()
        bottom.setSpacing(14)
        bottom.addWidget(self._uart_box(), 1)
        bottom.addWidget(self._volume_box())
        bottom.addWidget(self._page_button(), 0, Qt.AlignBottom)
        root.addLayout(bottom)

    def _wrap_scroll(self, w):
        sc = QtWidgets.QScrollArea()
        sc.setWidget(w)
        sc.setWidgetResizable(True)
        _no_vscroll(sc)
        sc.setStyleSheet("QScrollArea{background:transparent;border:none;}")
        return sc

    def _make_w_page(self, names, pattern):
        page = QtWidgets.QWidget()
        outer = QtWidgets.QVBoxLayout(page)
        outer.setContentsMargins(0, 0, 0, 0)
        outer.addStretch(1)                       # 垂直置中
        lay = QtWidgets.QHBoxLayout()
        lay.setContentsMargins(10, 0, 10, 0)
        lay.setSpacing(16)
        lay.addStretch(1)
        for name, off in zip(names, pattern):
            pnl = ModulePanel(name, MODULES[name])
            pnl.paramChanged.connect(self.on_param_changed)
            pnl.previewToggled.connect(self._on_preview)
            self.panels[name] = pnl
            # 用上下 spacer 做 W 偏移
            col = QtWidgets.QVBoxLayout()
            col.setContentsMargins(0, 0, 0, 0); col.setSpacing(0)
            top = QtWidgets.QWidget(); top.setFixedHeight(int(off * W_OFFSET))
            bot = QtWidgets.QWidget(); bot.setFixedHeight(int((1 - off) * W_OFFSET))
            col.addWidget(top)
            col.addWidget(pnl)
            col.addWidget(bot)
            wrap = QtWidgets.QWidget(); wrap.setLayout(col)
            lay.addWidget(wrap, 0, Qt.AlignTop)
        lay.addStretch(1)
        outer.addLayout(lay)
        outer.addStretch(1)
        return page

    def _on_preview(self, module, playing):
        if playing:
            if self._current and self._current != module:
                self.panels[self._current].set_playing_silently(False)
            self._current = module
            self.panels[module].set_selected(True)
            self.uart.send_preview(module)
        else:
            if self._current == module:
                self._current = None
            self.panels[module].set_selected(False)
            self.uart.send_preview(None)

    def _volume_box(self):
        box = QtWidgets.QFrame()
        box.setFixedSize(120, 140)
        box.setStyleSheet("QFrame{background:#141414;border:1px solid #BE9E60;"
                          "border-radius:10px;}")
        lay = QtWidgets.QVBoxLayout(box)
        lay.setContentsMargins(8, 6, 8, 6)
        cap = QtWidgets.QLabel("VOLUME")
        cap.setStyleSheet("color:#BE9E60; font-weight:bold; letter-spacing:1px;")
        cap.setAlignment(Qt.AlignCenter)
        lay.addWidget(cap)
        lay.addSpacing(5)
        # 全域音量滑桿,永遠可調;兩頁共用同一顆
        self.vol = Knob("Master", MODULES["Volume"]["params"][0][3], size="tiny")
        self.vol.valueChanged.connect(lambda v: self.on_param_changed("Volume", "i_gain", v))
        lay.addWidget(self.vol, 0, Qt.AlignHCenter)
        lay.addStretch(1)
        return box

    def _page_button(self):
        self.page_btn = QtWidgets.QPushButton("1")
        self.page_btn.setFixedSize(54, 54)
        self.page_btn.setCursor(Qt.PointingHandCursor)
        self.page_btn.setToolTip("Switch page")
        self.page_btn.setStyleSheet(
            "QPushButton{background:#BE9E60;color:#0a0a0a;font-weight:bold;"
            "font-size:22px;border-radius:27px;}"
            "QPushButton:hover{background:#d4b574;}")
        self.page_btn.clicked.connect(self._flip_page)
        return self.page_btn

    def _flip_page(self):
        self._page = 1 - self._page
        self.stack.setCurrentIndex(self._page)
        self.page_btn.setText("2" if self._page == 0 else "1")  # 顯示「下一頁」的號碼

    def _uart_box(self):
        box = QtWidgets.QFrame()
        box.setFixedHeight(140)
        box.setStyleSheet(
            "QFrame{background:#141414; border:1px solid #6e5e3c; border-radius:10px;}"
            "QLabel{color:#BE9E60;} QComboBox{background:#1f1f1f; color:#E8E2D4;"
            "border:1px solid #6e5e3c; border-radius:6px; padding:4px;}"
            "QComboBox QAbstractItemView{background:#1f1f1f; color:#E8E2D4;"
            "selection-background-color:#BE9E60; selection-color:#0a0a0a;}")
        lay = QtWidgets.QVBoxLayout(box)
        lay.setContentsMargins(14, 10, 14, 10)
        row1 = QtWidgets.QHBoxLayout()
        row1.addWidget(QtWidgets.QLabel("Port"))
        self.port_combo = QtWidgets.QComboBox()
        ports = self.uart.list_ports()
        self.port_combo.addItems(ports if ports else ["(no port / sim)"])
        row1.addWidget(self.port_combo, 1)
        row1.addWidget(QtWidgets.QLabel("Baud"))
        self.baud_combo = QtWidgets.QComboBox()
        self.baud_combo.addItems(["9600", "19200", "38400", "57600", "115200"])
        self.baud_combo.setCurrentText("115200")
        row1.addWidget(self.baud_combo)
        self.connect_btn = QtWidgets.QPushButton("Connect")
        self.connect_btn.setStyleSheet(
            "QPushButton{background:#BE9E60;color:#0a0a0a;font-weight:bold;"
            "border-radius:6px;padding:6px 16px;}")
        self.connect_btn.clicked.connect(self._toggle_connect)
        row1.addWidget(self.connect_btn)
        lay.addLayout(row1)

        self.log_view = QtWidgets.QPlainTextEdit()
        self.log_view.setReadOnly(True)
        self.log_view.setMaximumBlockCount(200)
        self.log_view.setStyleSheet(
            "QPlainTextEdit{background:#0a0a0a;color:#7fb080;border:none;"
            "font-family:monospace;font-size:10px;}")
        self.uart.log.connect(self.log_view.appendPlainText)
        lay.addWidget(self.log_view, 1)
        return box

    def _toggle_connect(self):
        if self.uart.ser:
            self.uart.disconnect()
            self.connect_btn.setText("Connect")
        else:
            ok = self.uart.connect(self.port_combo.currentText(),
                                   self.baud_combo.currentText())
            self.connect_btn.setText("Disconnect" if ok else "Connect")
            
    def on_param_changed(self, module_name, param_name, new_value):
        """
        Updates the tracked state of a module and sends the full 32-byte payload.
        """
        # Look up the index using your existing PARAM_ID dictionary
        param_index = PARAM_ID.get((module_name, param_name))
        
        if param_index is not None:
            # Update the specific float value in our tracking list
            MODULES[module_name]["current_values"][param_index] = new_value
            
            # Send the entire updated state to the FPGA
            self.uart.send_module_state(module_name, 0)
        else:
            print(f"Warning: Parameter {param_name} not found in {module_name}")


# =============================================================================
#  Stager 頁  —  4 段插槽 + 被選模組可調參數
# =============================================================================
class StagerPage(QtWidgets.QWidget):
    def __init__(self, uart, parent=None):
        super().__init__(parent)
        self.uart = uart
        self.combos = []
        self.slot_hosts = []     # 每段放參數控制的容器
        self.fx_names = ["None"] + [m for m in MODULES if m != "Volume"]
        self._build()

    def _build(self):
        root = QtWidgets.QVBoxLayout(self)
        root.setContentsMargins(28, 22, 28, 18)

        title = QtWidgets.QLabel("STAGE  CHAIN")
        f = title.font(); f.setPointSize(20); f.setBold(True); title.setFont(f)
        title.setStyleSheet("color:#BE9E60; letter-spacing:6px;")
        title.setAlignment(Qt.AlignHCenter)
        root.addWidget(title)
        sub = QtWidgets.QLabel("Four fixed hardware stages. Pick an effect per stage "
                               "(None to skip), then adjust its controls.")
        sub.setStyleSheet("color:#8a8270; font-size:14px;")
        sub.setAlignment(Qt.AlignHCenter)
        root.addWidget(sub)
        root.addSpacing(16)

        row = QtWidgets.QHBoxLayout()
        row.setSpacing(8)
        for i in range(4):
            slot = QtWidgets.QFrame()
            slot.setStyleSheet("QFrame{background:#141414; border:1px solid #6e5e3c;"
                               "border-radius:12px;}")
            sl = QtWidgets.QVBoxLayout(slot)
            sl.setContentsMargins(16, 16, 16, 16)
            cap = QtWidgets.QLabel(f"STAGE {i+1}")
            cap.setStyleSheet("color:#BE9E60; font-weight:bold; letter-spacing:2px;")
            cap.setAlignment(Qt.AlignCenter)
            sl.addWidget(cap)

            combo = QtWidgets.QComboBox()
            combo.addItems(self.fx_names)
            combo.setStyleSheet(
                "QComboBox{background:#1f1f1f;color:#E8E2D4;padding:8px;"
                "border:1px solid #BE9E60;border-radius:8px;}"
                "QComboBox QAbstractItemView{background:#1f1f1f;color:#E8E2D4;"
                "selection-background-color:#BE9E60;selection-color:#0a0a0a;}")
            combo.currentTextChanged.connect(lambda t, idx=i: self._on_slot_change(idx, t))
            self.combos.append(combo)
            sl.addWidget(combo)

            host = QtWidgets.QWidget()
            host_lay = QtWidgets.QVBoxLayout(host)
            host_lay.setContentsMargins(0, 12, 0, 0)
            host_lay.setAlignment(Qt.AlignTop)
            self.slot_hosts.append(host_lay)
            sl.addWidget(host)
            sl.addStretch(1)

            # 4 段用比例伸縮,完整塞滿畫面寬度、不需橫向捲動
            row.addWidget(slot, 1)
            if i < 3:
                arrow = QtWidgets.QLabel("→")
                arrow.setStyleSheet("color:#E8E2D4; font-size:24px;")
                arrow.setAlignment(Qt.AlignCenter)
                arrow.setFixedWidth(36)
                row.addWidget(arrow, 0, Qt.AlignVCenter)
        # 直接用 QHBoxLayout 呈現(移除外層 QScrollArea,徹底解決橫桿遮擋)
        root.addLayout(row)
        root.addStretch(1)

        send = QtWidgets.QPushButton("Apply chain to hardware")
        send.setCursor(Qt.PointingHandCursor)
        send.setStyleSheet(
            "QPushButton{background:#BE9E60;color:#0a0a0a;font-weight:bold;"
            "padding:10px 20px;border-radius:8px;letter-spacing:2px;}"
            "QPushButton:hover{background:#d4b574;}")
        send.clicked.connect(lambda: self.uart.send_stager(self.current_chain()))
        root.addWidget(send, 0, Qt.AlignHCenter)

    def current_chain(self):
        return [c.currentText() if c.currentText() != "None" else None
                for c in self.combos]

    def _on_slot_change(self, idx, name):
        host = self.slot_hosts[idx]
        while host.count():
            item = host.takeAt(0)
            w = item.widget()
            if w:
                w.deleteLater()
        if name == "None":
            return
        spec = MODULES[name]
        cont = QtWidgets.QWidget()
        if spec.get("five"):
            inner = QtWidgets.QGridLayout(cont)
            inner.setHorizontalSpacing(6); inner.setVerticalSpacing(10)
            p = spec["params"]
            mk = lambda pr, sz: self._mk(name, pr, sz)
            # 倒ㄇ:左右 small、頂 normal、中欄兩旋鈕 large(Stager 框較寬,放得下)
            left, k1, k2, top, right = (mk(p[0], "small"), mk(p[1], "large"),
                                        mk(p[2], "large"), mk(p[3], "normal"),
                                        mk(p[4], "small"))
            inner.addWidget(top, 0, 0, 1, 3, Qt.AlignHCenter)
            inner.addWidget(left, 1, 0, 2, 1, Qt.AlignBottom | Qt.AlignHCenter)
            inner.addWidget(k1, 1, 1, Qt.AlignHCenter)
            inner.addWidget(k2, 2, 1, Qt.AlignHCenter)
            inner.addWidget(right, 1, 2, 2, 1, Qt.AlignBottom | Qt.AlignHCenter)
            inner.setColumnStretch(0, 1)
            inner.setColumnStretch(2, 1)
        else:
            inner = QtWidgets.QHBoxLayout(cont)
            n = len(spec["params"])
            inner.setSpacing(10 if n <= 2 else 6)
            inner.addStretch(1)
            for pr in spec["params"]:
                if n <= 2:
                    sz = "large"
                else:
                    sz = "large" if pr[2] == "knob" else "normal"
                inner.addWidget(self._mk(name, pr, sz), 0, Qt.AlignBottom | Qt.AlignHCenter)
            inner.addStretch(1)
        host.addWidget(cont)

    def _mk(self, module, pr, size="normal"):
        key, label, ctype, default, scale = pr
        w = (Knob(label, default, size=size) if ctype == "knob"
             else VSlider(label, default, size=size))
        w.valueChanged.connect(lambda v: self.on_param_changed(module, key, v))
        return w
    
    def on_param_changed(self, module_name, param_name, new_value):
        """
        Updates the tracked state of a module and sends the full 32-byte payload.
        """
        # Look up the index using your existing PARAM_ID dictionary
        param_index = PARAM_ID.get((module_name, param_name))
        
        if param_index is not None:
            # Update the specific float value in our tracking list
            MODULES[module_name]["current_values"][param_index] = new_value
            
            # Send the entire updated state to the FPGA
            self.uart.send_module_state(module_name, 0)
        else:
            print(f"Warning: Parameter {param_name} not found in {module_name}")


# =============================================================================
#  Tone & Chord 頁(被動接收)
# =============================================================================
NOTE_NAMES = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
QUALITY = {0: "maj", 1: "min", 2: "dim", 3: "aug", 4: "7"}

class SpectrumWidget(QtWidgets.QWidget):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.mags = []
        self.setMinimumHeight(180)

    def set_mags(self, m):
        self.mags = m; self.update()

    def paintEvent(self, e):
        p = QtGui.QPainter(self)
        p.setRenderHint(QtGui.QPainter.Antialiasing)
        p.fillRect(self.rect(), QtGui.QColor(8, 8, 8))
        n = len(self.mags)
        if not n:
            p.setPen(QtGui.QColor(80, 80, 80))
            p.drawText(self.rect(), Qt.AlignCenter, "waiting for spectrum data…")
            return
        w, h = self.width(), self.height()
        bw = w / n
        for i, m in enumerate(self.mags):
            bh = max(2, m * (h - 10))
            grad = QtGui.QLinearGradient(0, h, 0, h - bh)
            grad.setColorAt(0, QtGui.QColor(190, 158, 96))
            grad.setColorAt(1, QtGui.QColor(120, 230, 140))
            p.fillRect(QRectF(i * bw + 1, h - bh, bw - 2, bh), grad)


class ToneChordPage(QtWidgets.QWidget):
    def __init__(self, uart, parent=None):
        super().__init__(parent)
        self.uart = uart
        self._build()
        uart.noteReceived.connect(self._on_note)
        uart.chordReceived.connect(self._on_chord)
        uart.spectrumReceived.connect(self._on_spectrum)

    def _build(self):
        root = QtWidgets.QVBoxLayout(self)
        root.setContentsMargins(28, 22, 28, 18)
        title = QtWidgets.QLabel("TONE  &  CHORD")
        f = title.font(); f.setPointSize(16); f.setBold(True); title.setFont(f)
        title.setStyleSheet("color:#BE9E60; letter-spacing:6px;")
        title.setAlignment(Qt.AlignHCenter)
        root.addWidget(title)
        sub = QtWidgets.QLabel("Live results received from the FPGA "
                               "(connect UART on the FX Panel first).")
        sub.setStyleSheet("color:#8a8270;")
        sub.setAlignment(Qt.AlignHCenter)
        root.addWidget(sub)

        self.status = QtWidgets.QLabel("● waiting for data…")
        self.status.setStyleSheet("color:#BE9E60;")
        root.addWidget(self.status)

        lab = QtWidgets.QLabel("STFT SPECTRUM")
        lab.setStyleSheet("color:#BE9E60; font-weight:bold; letter-spacing:2px;")
        root.addWidget(lab)
        self.spectrum = SpectrumWidget()
        root.addWidget(self.spectrum)

        row = QtWidgets.QHBoxLayout()
        self.note = self._readout("NOTE", "—")
        self.chord = self._readout("CHORD", "—")
        self.freq = self._readout("FREQUENCY", "—")
        for d in (self.note, self.chord, self.freq):
            row.addWidget(d["box"])
        root.addLayout(row)
        root.addStretch(1)

    def _readout(self, cap, val):
        box = QtWidgets.QFrame()
        box.setStyleSheet("QFrame{background:#141414;border:1px solid #6e5e3c;"
                          "border-radius:12px;}")
        lay = QtWidgets.QVBoxLayout(box)
        c = QtWidgets.QLabel(cap); c.setStyleSheet("color:#BE9E60; letter-spacing:2px;")
        c.setAlignment(Qt.AlignCenter)
        v = QtWidgets.QLabel(val); vf = v.font(); vf.setPointSize(26); vf.setBold(True)
        v.setFont(vf); v.setStyleSheet("color:#E8E2D4;"); v.setAlignment(Qt.AlignCenter)
        lay.addWidget(c); lay.addWidget(v)
        return {"box": box, "value": v}

    def _seen(self):
        self.status.setText("● receiving")
        self.status.setStyleSheet("color:#78e68c;")

    def _on_note(self, nid, freq):
        self._seen()
        if 0 <= nid < 12:
            self.note["value"].setText(NOTE_NAMES[nid])
        self.freq["value"].setText(f"{freq} Hz")

    def _on_chord(self, root, q):
        self._seen()
        if 0 <= root < 12:
            self.chord["value"].setText(f"{NOTE_NAMES[root]} {QUALITY.get(q,'?')}")

    def _on_spectrum(self, mags):
        self._seen()
        self.spectrum.set_mags(mags)


# =============================================================================
#  左側抽屜 Menu
# =============================================================================
class SideMenu(QtWidgets.QFrame):
    selected = pyqtSignal(int)
    EXPANDED, COLLAPSED = 200, 56

    def __init__(self, parent=None):
        super().__init__(parent)
        self._expanded = False
        self.setFixedWidth(self.COLLAPSED)
        self.setStyleSheet("QFrame{background:#0d0d0d; border-right:1px solid #6e5e3c;}")
        self._build()

    def _build(self):
        lay = QtWidgets.QVBoxLayout(self)
        lay.setContentsMargins(6, 14, 6, 14); lay.setSpacing(8)
        self.toggle = QtWidgets.QToolButton()
        self.toggle.setText("≡")
        self.toggle.setStyleSheet("QToolButton{color:#BE9E60;font-size:22px;border:none;}")
        self.toggle.setCursor(Qt.PointingHandCursor)
        self.toggle.clicked.connect(self._toggle)
        lay.addWidget(self.toggle, 0, Qt.AlignLeft)
        lay.addSpacing(16)

        self.items = []
        for i, (icon, name) in enumerate([("▦", "FX Panel"), ("⮂", "Stager"),
                                          ("♪", "Tone & Chord")]):
            b = QtWidgets.QToolButton()
            b.setCheckable(True); b.setCursor(Qt.PointingHandCursor)
            b.setStyleSheet(
                "QToolButton{color:#E8E2D4;background:transparent;border:none;"
                "padding:10px 6px;text-align:left;font-size:14px;border-radius:8px;}"
                "QToolButton:hover{background:rgba(190,158,96,0.18);}"
                "QToolButton:checked{background:#BE9E60;color:#0a0a0a;font-weight:bold;}")
            b.clicked.connect(lambda _, idx=i: self._pick(idx))
            self.items.append((b, icon, name))
            lay.addWidget(b)
        lay.addStretch(1)
        self.items[0][0].setChecked(True)
        self._refresh()

    def _refresh(self):
        for b, icon, name in self.items:
            b.setText(f"{icon}  {name}" if self._expanded else icon)

    def _pick(self, idx):
        for j, (b, _, _) in enumerate(self.items):
            b.setChecked(j == idx)
        self.selected.emit(idx)

    def _toggle(self):
        self._expanded = not self._expanded
        self.setFixedWidth(self.EXPANDED if self._expanded else self.COLLAPSED)
        self._refresh()


# =============================================================================
#  主視窗
# =============================================================================
class MainWindow(QtWidgets.QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Guitar FX Studio")
        self.resize(1560, 940)
        self.uart = UartManager()

        central = QtWidgets.QWidget()
        central.setStyleSheet("background:#0a0a0a;")
        self.setCentralWidget(central)
        root = QtWidgets.QHBoxLayout(central)
        root.setContentsMargins(0, 0, 0, 0); root.setSpacing(0)

        self.menu = SideMenu()
        self.menu.selected.connect(lambda i: self.pages.setCurrentIndex(i))
        root.addWidget(self.menu)

        self.pages = QtWidgets.QStackedWidget()
        self.pages.addWidget(FxPanelPage(self.uart))
        self.pages.addWidget(StagerPage(self.uart))
        self.pages.addWidget(ToneChordPage(self.uart))
        root.addWidget(self.pages, 1)

    def closeEvent(self, e):
        self.uart.disconnect()
        super().closeEvent(e)


def main():
    app = QtWidgets.QApplication(sys.argv)
    app.setStyle("Fusion")
    pal = app.palette()
    pal.setColor(QtGui.QPalette.ToolTipBase, QtGui.QColor(20, 20, 20))
    pal.setColor(QtGui.QPalette.ToolTipText, C.ink)
    app.setPalette(pal)
    MainWindow().show()
    sys.exit(_app_exec(app))


if __name__ == "__main__":
    main()
