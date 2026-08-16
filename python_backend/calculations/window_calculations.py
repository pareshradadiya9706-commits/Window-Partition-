"""
SOURCE: Deductions and cut allocations for 18x40, 60mm, Domal, R40, Louver, and Repairing.
Extracted directly from calculate_project() in verified JavaScript source.
"""
from typing import Dict, List, Any, Tuple
from python_backend.models.window import WindowItem

def calculate_window_cuts(
    item: WindowItem,
    index: int,
    rates: Dict[str, float],
    master: Dict[str, List[Dict[str, Any]]]
) -> Tuple[float, float, int, float, float, float, float, float, float]:
    """
    SOURCE: calculate_project() window series branching logic:
    - 18x40 & 60mm series deduction block
    - Domal series deduction block
    - R40 series deduction block
    - Louver series deduction block
    - Repairing series deduction block

    Returns tuple:
    (g_w, g_h, g_qty, total_glass_sqft_delta, total_jali_cost_delta, total_louver_cost_delta,
     total_glass_cost_delta, total_labor_cost_delta, total_hard_cost_delta)
    """
    sr = item.series
    tr = item.track if item.track else "-"
    w = float(item.w) if isinstance(item.w, (int, float)) else 0.0
    h = float(item.h) if isinstance(item.h, (int, float)) else 0.0
    qty = int(item.qty)
    jali = bool(item.jali)

    def add_c(sec: str, length: float, cnt: int, win_no: int) -> None:
        if length > 0 and cnt > 0:
            if sec not in master:
                master[sec] = []
            for _ in range(cnt):
                master[sec].append({"len": length, "win": win_no})

    if sr == "Repairing":
        # SOURCE: if(sr=="Repairing")
        q = qty
        glass_cost = float(item.glass or 0.0) * q
        hw_cost = float(item.hw or 0.0) * q
        labor_cost = float(item.labor or 0.0) * q
        return (0.0, 0.0, 0, 0.0, 0.0, 0.0, glass_cost, labor_cost, hw_cost)

    sqft = (w * h) / 144.0 * qty
    base = "2Track"
    if "3Track" in tr:
        base = "3Track"
    elif "4Track" in tr:
        base = "4Track"
    elif "Fix" in tr or "Open" in tr or "Blade" in tr:
        base = tr

    is_c = "Center Open" in tr
    tr_f = base
    if jali:
        if base == "2Track":
            tr_f = "3Track"
        elif base == "3Track":
            tr_f = "4Track"

    g_w, g_h, g_qty = 0.0, 0.0, 0
    total_jali_cost = 0.0
    total_louver_cost = 0.0
    total_glass_cost = 0.0
    total_labor_cost = 0.0
    total_hard_cost = 0.0

    if sr == "Louver":
        # SOURCE: if(sr=="Louver")
        blades = max(1, round((h - 1.0) / 3.5))
        g_w = w - 1.5
        g_h = 4.0
        g_qty = blades * qty
        louver_rate = float(rates.get("louver_rate", 130.0))
        total_louver_cost += blades * qty * louver_rate
        add_c("Louver Frame", w, 2 * qty, index + 1)
        add_c("Louver Frame", h, 2 * qty, index + 1)

    elif sr == "R40":
        # SOURCE: else if(sr=="R40")
        g_w = w
        g_h = h
        g_qty = qty
        if tr == "Fix":
            add_c("R40 Frame", w, 2 * qty, index + 1)
            add_c("R40 Frame", h, 2 * qty, index + 1)
            add_c("R40 Clip", w, 2 * qty, index + 1)
            add_c("R40 Clip", h, 2 * qty, index + 1)
        elif tr == "Single Open":
            add_c("R40 Frame", w, 2 * qty, index + 1)
            add_c("R40 Frame", h, 2 * qty, index + 1)
            add_c("R40 Shutter", w, 2 * qty, index + 1)
            add_c("R40 Shutter", h, 2 * qty, index + 1)
        elif tr == "Double Open":
            add_c("R40 Frame", w, 2 * qty, index + 1)
            add_c("R40 Frame", h, 2 * qty, index + 1)
            add_c("R40 Shutter", w, 2 * qty, index + 1)
            add_c("R40 Shutter", h, 4 * qty, index + 1)
            add_c("R40 Mulleon", h, 1 * qty, index + 1)

        if jali:
            add_c("R40 Shutter", w, 2 * qty, index + 1)
            add_c("R40 Shutter", h, 2 * qty, index + 1)
            jali_rate = float(rates.get("jali_rate", 0.0))
            total_jali_cost += (w * h) / 144.0 * qty * jali_rate

    elif sr == "Domal":
        # SOURCE: else if(sr=="Domal")
        hnd = h - 2.75
        intc = h - 2.75
        if is_c:
            if base == "2Track":
                hor = (w + 3.5) / 4.0
                hor_q = 8
                hnd_q = 8
                int_q = 4
            elif base == "3Track":
                hor = (w + 6.5) / 6.0
                hor_q = 12
                hnd_q = 12
                int_q = 8
            else:
                hor = (w + 12.0) / 8.0
                hor_q = 16
                hnd_q = 16
                int_q = 12
        else:
            if base == "2Track":
                hor = (w + 0.5) / 2.0
                hor_q = 4
                hnd_q = 4
                int_q = 2
            elif base == "3Track":
                hor = (w + 2.25) / 3.0
                hor_q = 6
                hnd_q = 6
                int_q = 4
            else:
                hor = (w + 4.5) / 4.0
                hor_q = 8
                hnd_q = 8
                int_q = 6

        jh = 4 if (jali and is_c) else (2 if jali else 0)
        jv_h = 2 if (jali and is_c) else (1 if jali else 0)
        jv_i = 2 if (jali and is_c) else (1 if jali else 0)

        g_w = hor - 4.125
        g_h = hnd - 4.125
        mult = 4 if base == "2Track" else (6 if base == "3Track" else 8)
        if not is_c:
            mult //= 2
        g_qty = mult * qty

        add_c(f"Domal {tr_f} Frame", w, 2 * qty, index + 1)
        add_c(f"Domal {tr_f} Frame", h, 2 * qty, index + 1)
        add_c("Domal Handle", hor, (hor_q + jh) * qty, index + 1)
        add_c("Domal Handle", hnd, (hnd_q + jv_h) * qty, index + 1)
        add_c("Domal Interlock", intc, (int_q + jv_i) * qty, index + 1)

        if jali:
            jali_rate = float(rates.get("jali_rate", 0.0))
            total_jali_cost += (hor * hnd) / 144.0 * qty * jali_rate * (2 if is_c else 1)

    elif sr in ["18x40", "60mm"]:
        # SOURCE: else if(["18x40","60mm"].includes(sr))
        hnd = h - 1.5
        intc = h - 1.5
        ghv = (h - 4.0) if sr == "18x40" else (h - 5.5)

        if is_c:
            if base == "2Track":
                hor = (w - 6.5) / 4.0 if sr == "18x40" else (w + 3.0) / 4.0
                hor_q = 8
                hnd_q = 4
                int_q = 4
            elif base == "3Track":
                hor = (w - 8.0) / 6.0 if sr == "18x40" else (w + 5.5) / 6.0
                hor_q = 12
                hnd_q = 4
                int_q = 8
            else:
                hor = (w - 11.5) / 8.0 if sr == "18x40" else (w + 9.0) / 8.0
                hor_q = 16
                hnd_q = 4
                int_q = 12
        else:
            if base == "2Track":
                hor = (w - 6.5) / 2.0 if sr == "18x40" else (w + 0.5) / 2.0
                hor_q = 4
                hnd_q = 2
                int_q = 2
            elif base == "3Track":
                hor = (w - 8.0) / 3.0 if sr == "18x40" else (w + 2.5) / 3.0
                hor_q = 6
                hnd_q = 2
                int_q = 4
            else:
                hor = (w - 11.5) / 4.0 if sr == "18x40" else (w + 4.5) / 4.0
                hor_q = 8
                hnd_q = 2
                int_q = 6

        jbp = 4 if (jali and is_c) else (2 if jali else 0)
        jv_h = 2 if (jali and is_c) else (1 if jali else 0)
        jv_i = 2 if (jali and is_c) else (1 if jali else 0)

        g_w = (hor + 0.65) if sr == "18x40" else (hor - 4.125)
        g_h = ghv
        mult = 4 if base == "2Track" else (6 if base == "3Track" else 8)
        if not is_c:
            mult //= 2
        g_qty = mult * qty

        add_c(f"{sr} {tr_f} Bottom", w, 1 * qty, index + 1)
        add_c(f"{sr} {tr_f} Top", w, 1 * qty, index + 1)
        add_c(f"{sr} {tr_f} Top", h, 2 * qty, index + 1)
        add_c(f"{sr} BearingPatti", hor, (hor_q + jbp) * qty, index + 1)
        add_c(f"{sr} Handle", hnd, (hnd_q + jv_h) * qty, index + 1)
        add_c(f"{sr} Interlock", intc, (int_q + jv_i) * qty, index + 1)

        if jali:
            jali_rate = float(rates.get("jali_rate", 0.0))
            total_jali_cost += (hor * hnd) / 144.0 * qty * jali_rate * (2 if is_c else 1)

    # Cost calculation for glass/labor/hardware
    if sr not in ["Louver", "Repairing"]:
        pref = "s18" if sr == "18x40" else ("s60" if sr == "60mm" else ("domal" if sr == "Domal" else "r40"))
        total_glass_cost += sqft * float(rates.get(f"{pref}_glass", 0.0))
        total_labor_cost += sqft * float(rates.get(f"{pref}_labor", 0.0))
        total_hard_cost += sqft * float(rates.get(f"{pref}_hardw", 0.0))

    total_glass_sqft = 0.0
    if sr != "Louver" and g_qty > 0:
        total_glass_sqft = (g_w * g_h) / 144.0 * g_qty

    return (
        g_w, g_h, g_qty, total_glass_sqft, total_jali_cost, total_louver_cost,
        total_glass_cost, total_labor_cost, total_hard_cost
    )
