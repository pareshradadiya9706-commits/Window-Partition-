"""
SOURCE: Deductions, cut allocations, glass sqft, and sheet pieces for Partition series.
Extracted directly from calculate_project() in verified JavaScript source.
"""
import math
import random
from typing import Dict, List, Any, Tuple
from python_backend.models.window import PartitionItem
from python_backend.models.partition import PartitionDrawData

def calculate_partition_cuts(
    item: PartitionItem,
    index: int,
    rates: Dict[str, float],
    master: Dict[str, List[Dict[str, Any]]],
    last_partitions: List[PartitionDrawData],
    global_pieces: List[Dict[str, Any]]
) -> Tuple[float, float, float, float, float]:
    """
    SOURCE: calculate_project() partition branch: if(sr=="Partition")

    Returns tuple:
    (pane_w, top_h, total_glass_sqft_delta, total_part_hardware_delta, total_labor_cost_delta)
    """
    w = float(item.w)
    h = float(item.h)
    qty = int(item.qty)
    dw = float(item.dw or 0.0)
    dh = float(item.dh or 0.0)
    bh = float(item.bh or 0.0) if item.midDes == "standard" else 0.0

    min_pane_w = float(item.paneWSize.split("-")[0])
    max_pane_w = float(item.paneWSize.split("-")[1])
    pt = 1.5
    cols = 1
    pane_w = 0.0
    found = False

    for c in range(1, 21):
        temp = (w - dw - ((c + 2) * pt)) / float(c)
        if temp > 0 and min_pane_w <= temp <= max_pane_w:
            cols = c
            pane_w = temp
            found = True
            break

    if not found:
        cols = max(1, math.ceil((w - dw - (4 * pt)) / max_pane_w)) or 1
    pane_w = (w - dw - ((cols + 2) * pt)) / float(cols)
    if pane_w < 0:
        pane_w = 0.0

    top_h = (h - dh) - (2 * pt)
    if top_h < 0:
        top_h = 0.0

    glass_h = (dh - bh - 2 * pt) if item.midDes == "standard" else (dh - 2 * pt)
    if glass_h < 0:
        glass_h = 0.0

    last_partitions.append(
        PartitionDrawData(
            w=w,
            h=h,
            dw=dw,
            dh=dh,
            bh=bh,
            cols=cols,
            paneW=pane_w,
            glassH=glass_h,
            topH=top_h,
            topMat=item.topMat,
            midDes=item.midDes
        )
    )

    def add_c(sec: str, length: float, cnt: int, win_no: int) -> None:
        if length > 0 and cnt > 0:
            if sec not in master:
                master[sec] = []
            for _ in range(cnt):
                master[sec].append({"len": length, "win": win_no})

    # Extrusion Cuts (DP Pipe)
    add_c("Partition DP Pipe", h, 2 * qty, index + 1)
    add_c("Partition DP Pipe", w - 3.0, 1 * qty, index + 1)
    add_c("Partition DP Pipe", h - 1.5, 1 * qty, index + 1)
    add_c("Partition DP Pipe", w - dw - 4.5, 1 * qty, index + 1)

    if cols > 1:
        add_c("Partition DP Pipe", h - 3.0, (cols - 1) * qty, index + 1)
    if dw > 0:
        add_c("Partition DP Pipe", dw, 1 * qty, index + 1)

    if item.midDes == "standard":
        add_c("Partition DP Pipe", pane_w, cols * 2 * qty, index + 1)
    else:
        add_c("Partition DP Pipe", pane_w, cols * qty, index + 1)

    # Door Pipe & Hardware
    total_part_hardware = 0.0
    if dw > 0 and dh > 0:
        add_c("Partition Door Pipe", dh, 2 * qty, index + 1)
        add_c("Partition Door Pipe", dw, 3 * qty, index + 1)
        part_hw_rate = float(rates.get("part_hw_rate", 850.0))
        total_part_hardware += part_hw_rate * qty

    # Partition Clip
    add_c("Partition Clip", pane_w, cols * 2 * qty, index + 1)
    add_c("Partition Clip", top_h, cols * 2 * qty, index + 1)
    if dw > 0:
        add_c("Partition Clip", dw, 2 * qty, index + 1)
        add_c("Partition Clip", top_h, 2 * qty, index + 1)

    if item.midDes == "standard":
        add_c("Partition Clip", pane_w, cols * 4 * qty, index + 1)
        add_c("Partition Clip", glass_h, cols * 2 * qty, index + 1)
        add_c("Partition Clip", bh, cols * 2 * qty, index + 1)
    else:
        add_c("Partition Clip", pane_w, cols * 2 * qty, index + 1)
        add_c("Partition Clip", glass_h, cols * 2 * qty, index + 1)

    if dw > 0 and dh > 0:
        add_c("Partition Clip", dh, 2 * qty, index + 1)
        add_c("Partition Clip", dw, 1 * qty, index + 1)

    # Glass & Sheet Piece Calculations
    total_glass_sqft = 0.0
    p_top = (pane_w * top_h * cols) / 144.0
    if dw > 0:
        p_top += (dw * top_h) / 144.0
    p_mid = (pane_w * glass_h * cols) / 144.0

    d_inner_w = max(0.0, dw - 4.0)
    d_inner_glass_h = max(0.0, glass_h - 4.0)
    d_inner_sheet_h = max(0.0, (bh or 36.0) - 4.0)

    if item.topMat == "glass":
        total_glass_sqft += p_top * qty
    else:
        for k in range(qty):
            for c in range(cols):
                global_pieces.append({"w": pane_w, "h": top_h, "id": f"P{index}_Top_{c}_{k}_{random.random()}"})
            if dw > 0:
                global_pieces.append({"w": dw, "h": top_h, "id": f"P{index}_TopD_{k}_{random.random()}"})

    if item.midDes in ["standard", "full_glass"]:
        total_glass_sqft += p_mid * qty
    elif item.midDes == "full_sheet":
        for k in range(qty):
            for c in range(cols):
                global_pieces.append({"w": pane_w, "h": glass_h, "id": f"P{index}_Mid_{c}_{k}_{random.random()}"})

    if item.midDes == "standard":
        for k in range(qty):
            for c in range(cols):
                global_pieces.append({"w": pane_w, "h": bh, "id": f"P{index}_Bot_{c}_{k}_{random.random()}"})

    if dw > 0 and dh > 0:
        total_glass_sqft += ((d_inner_w * d_inner_glass_h) / 144.0) * qty
        if d_inner_sheet_h > 0:
            for k in range(qty):
                global_pieces.append({"w": d_inner_w, "h": d_inner_sheet_h, "id": f"P{index}_DoorS_{k}_{random.random()}"})

    sqft = (w * h) / 144.0 * qty
    s18_labor_rate = float(rates.get("s18_labor", 40.0))
    total_labor_cost = sqft * s18_labor_rate

    return pane_w, top_h, total_glass_sqft, total_part_hardware, total_labor_cost
