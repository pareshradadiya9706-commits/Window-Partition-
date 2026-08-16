"""
SOURCE: 1D Best-Fit-Decreasing stock packing (pack_bfd), 2D sheet nesting (MaxRectsPacker),
and architectural inch-fraction formatter (formatDora).
Direct 1-to-1 parity with verified JavaScript source functions.
"""
import math
from typing import List, Dict, Any, Optional

def format_dora(v: Optional[float]) -> str:
    """
    SOURCE: function formatDora(v) in JavaScript source.
    Converts decimal inch values to 16th fractional inches string representation.
    """
    if v is None or v <= 0.001:
        return "-"
    sign = "-" if v < 0 else ""
    v = abs(v)
    whole = math.floor(v)
    frac = v - whole
    denom = 16
    num = round(frac * denom)
    if num == denom:
        whole += 1
        num = 0

    def gcd(a: int, b: int) -> int:
        return b if b == 0 else gcd(b, a % b)

    frac_str = ""
    if num > 0:
        g = math.gcd(num, denom)
        n = num // g
        d = denom // g
        while d > 1 and n % 2 == 0 and d % 2 == 0:
            n //= 2
            d //= 2
        if whole == 0:
            frac_str = f"{n}/{d}"
        else:
            frac_str = f"{whole} {n}/{d}"
    else:
        frac_str = f"{whole}"

    return sign + frac_str + '"'


def pack_bfd(lengths: List[Any], allowed: List[int], kerf: float = 0.15) -> List[Dict[str, Any]]:
    """
    SOURCE: function pack_bfd(lengths, allowed, kerf=0.15) in JavaScript source.
    1D Best-Fit-Decreasing (BFD) linear stock bar allocation algorithm.
    """
    # Sort cut lengths descending
    def get_len(item: Any) -> float:
        if isinstance(item, dict):
            return float(item.get("len", 0))
        if hasattr(item, "len"):
            return float(getattr(item, "len", 0))
        return float(item)

    sorted_lengths = sorted(lengths, key=get_len, reverse=True)
    bins: List[Dict[str, Any]] = []

    for cut in sorted_lengths:
        clen = get_len(cut)
        best: Optional[Dict[str, Any]] = None
        best_w = float("inf")

        for b in bins:
            need = clen + (kerf if len(b["cuts"]) > 0 else 0.0)
            if need <= b["rem"] and (b["rem"] - need) < best_w:
                best = b
                best_w = b["rem"] - need

        if best is not None:
            need = clen + (kerf if len(best["cuts"]) > 0 else 0.0)
            best["cuts"].append(cut)
            best["rem"] -= need
        else:
            valid = [p for p in allowed if p * 12 >= clen]
            size = min(valid) * 12 if len(valid) > 0 else max(allowed) * 12
            bins.append({
                "size": size,
                "rem": size - clen,
                "cuts": [cut]
            })

    return bins


class MaxRectsPacker:
    """
    SOURCE: class MaxRectsPacker in JavaScript source.
    2D Maximal Rectangles bin packing algorithm for sheet panels.
    """
    def __init__(self, w: float, h: float, kerf: float = 0.12, allow_rot: bool = True):
        self.bin_w = float(w)
        self.bin_h = float(h)
        self.kerf = float(kerf)
        self.allow_rot = allow_rot
        self.free: List[Dict[str, float]] = [{"x": 0.0, "y": 0.0, "w": self.bin_w, "h": self.bin_h}]
        self.used: List[Dict[str, Any]] = []

    def fit(self, blocks: List[Dict[str, Any]]) -> None:
        for b in blocks:
            best = self.find_best(b)
            if not best:
                continue
            self.place(b, best)

    def find_best(self, block: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        best = {"score": float("inf"), "idx": -1, "rot": False, "x": 0.0, "y": 0.0}
        bw, bh = float(block["w"]), float(block["h"])

        for i, fr in enumerate(self.free):
            if bw <= fr["w"] and bh <= fr["h"]:
                s = min(fr["w"] - bw, fr["h"] - bh) * 1000.0 + max(fr["w"] - bw, fr["h"] - bh)
                if s < best["score"]:
                    best = {"score": s, "idx": i, "rot": False, "x": fr["x"], "y": fr["y"]}
            if self.allow_rot and bh <= fr["w"] and bw <= fr["h"]:
                r = min(fr["w"] - bh, fr["h"] - bw) * 1000.0 + max(fr["w"] - bh, fr["h"] - bw)
                if r < best["score"]:
                    best = {"score": r, "idx": i, "rot": True, "x": fr["x"], "y": fr["y"]}

        return None if best["idx"] == -1 else best

    def place(self, block: Dict[str, Any], best: Dict[str, Any]) -> None:
        if best["rot"]:
            t = block["w"]
            block["w"] = block["h"]
            block["h"] = t
            block["rotated"] = True
        else:
            block["rotated"] = False

        block["fit"] = {"x": best["x"], "y": best["y"], "w": block["w"], "h": block["h"]}
        k = self.kerf
        pw, ph = block["w"] + k, block["h"] + k
        placed = {"x": best["x"], "y": best["y"], "w": pw, "h": ph}
        self.used.append(block)

        new_free: List[Dict[str, float]] = []
        for fr in self.free:
            if (fr["x"] >= placed["x"] + placed["w"] or
                fr["x"] + fr["w"] <= placed["x"] or
                fr["y"] >= placed["y"] + placed["h"] or
                fr["y"] + fr["h"] <= placed["y"]):
                new_free.append(fr)
                continue
            if placed["x"] > fr["x"]:
                new_free.append({"x": fr["x"], "y": fr["y"], "w": placed["x"] - fr["x"], "h": fr["h"]})
            if placed["x"] + placed["w"] < fr["x"] + fr["w"]:
                new_free.append({"x": placed["x"] + placed["w"], "y": fr["y"], "w": fr["x"] + fr["w"] - (placed["x"] + placed["w"]), "h": fr["h"]})
            if placed["y"] > fr["y"]:
                new_free.append({"x": fr["x"], "y": fr["y"], "w": fr["w"], "h": placed["y"] - fr["y"]})
            if placed["y"] + placed["h"] < fr["y"] + fr["h"]:
                new_free.append({"x": fr["x"], "y": placed["y"] + placed["h"], "w": fr["w"], "h": fr["y"] + fr["h"] - (placed["y"] + placed["h"])})

        f = [r for r in new_free if r["w"] > 0.5 and r["h"] > 0.5]
        for i in range(len(f) - 1, -1, -1):
            for j in range(len(f) - 1, -1, -1):
                if (i != j and i < len(f) and j < len(f) and
                    f[i] and f[j] and
                    f[i]["x"] >= f[j]["x"] and
                    f[i]["y"] >= f[j]["y"] and
                    f[i]["x"] + f[i]["w"] <= f[j]["x"] + f[j]["w"] and
                    f[i]["y"] + f[i]["h"] <= f[j]["y"] + f[j]["h"]):
                    f.pop(i)
                    break

        self.free = f
