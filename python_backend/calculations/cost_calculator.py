"""
SOURCE: Commercial costing, coatings, margins, GST, and billing factor computations.
Extracted directly from calculate_project() in verified JavaScript source.
"""
import math
from typing import Dict, List, Any, Tuple
from python_backend.models.project import WEIGHTS_PER_FT, COATING_RATES
from python_backend.models.calculation_result import PipeCutBin, PackedSection

def compute_section_packing_and_cost(
    master: Dict[str, List[Dict[str, Any]]],
    scrap_map: Dict[str, List[float]],
    allowed_pipes: List[int],
    w_type: str,
    coat: str,
    rates: Dict[str, float]
) -> Tuple[Dict[str, PackedSection], float, float, float, float]:
    """
    SOURCE: calculate_project() section packing loop:
    for(let sec in master){ ... }

    Returns tuple:
    (packed_data, total_weight, total_alu_cost, total_coat_cost, finish_extra_amt)
    """
    from python_backend.calculations.cutting_optimizer import pack_bfd

    packed: Dict[str, PackedSection] = {}
    total_wt = 0.0
    total_alu = 0.0
    total_coat = 0.0
    finish_extra_amt = 0.0

    if not allowed_pipes:
        allowed_pipes = [12, 15, 16]

    for sec in master:
        scrap_for_sec = list(scrap_map.get(sec, []))
        needed = list(master[sec])

        def get_len(x: Any) -> float:
            return float(x.get("len", 0)) if isinstance(x, dict) else float(x)

        needed.sort(key=get_len, reverse=True)
        scrap_for_sec.sort(reverse=True)

        remaining = []
        scrap_used = 0
        scrap_copy = list(scrap_for_sec)

        for need in needed:
            need_len = get_len(need)
            found_idx = -1
            for idx, s in enumerate(scrap_copy):
                if s >= need_len:
                    found_idx = idx
                    break
            if found_idx != -1:
                scrap_copy.pop(found_idx)
                scrap_used += 1
            else:
                remaining.append(need)

        wt_key = sec.replace(" ", "_").replace("_Center_Open", "")
        wt_dict = WEIGHTS_PER_FT.get(wt_key, {})
        wt_pf = wt_dict.get(w_type, wt_dict.get("Medium", 0.0))

        coat_dict = COATING_RATES.get(wt_key, {})
        c_rate = coat_dict.get(coat, 0.0) if coat != "Mill Finish" else 0.0

        alu_rt = float(rates.get("alu_rate", 480.0))
        if wt_key == "Partition_DP_Pipe":
            alu_rt = float(rates.get("part_dp_rate", 460.0))
        elif wt_key == "Partition_Door_Pipe":
            alu_rt = float(rates.get("part_door_rate", 460.0))
        elif wt_key == "Partition_Clip":
            alu_rt = 0.0
            wt_pf = 0.0

        bins = pack_bfd(remaining, allowed_pipes, 0.15)
        best: List[PipeCutBin] = []

        for b in bins:
            sz = int(math.ceil(b["size"] / 12.0))
            best.append(
                PipeCutBin(
                    size_ft=sz,
                    cuts=b["cuts"],
                    waste=float(b["rem"]),
                    weight=sz * wt_pf
                )
            )

        packed[sec] = PackedSection(
            pipes=best,
            scrapUsed=scrap_used,
            totalNeeded=len(needed)
        )

        for p in best:
            total_wt += p.weight
            total_alu += p.weight * alu_rt
            if wt_key == "Partition_Clip":
                total_alu += (p.size_ft / 12.0) * float(rates.get("part_clip_rate", 130.0))
            if "Partition" in sec:
                finish_extra_amt += p.size_ft * c_rate
            else:
                total_coat += p.size_ft * c_rate

    return packed, total_wt, total_alu, total_coat, finish_extra_amt


def compute_final_totals(
    base_cost: float,
    profit: float,
    transport: float,
    extra: float,
    use_gst: bool,
    total_sqft: float,
    billing_sqft: float,
    billing_mode: str,
    min_billing: bool
) -> Tuple[float, float, float, float, float, float, float, float]:
    """
    SOURCE: calculate_project() commercial aggregation and billing factor logic:
    let profit_amt = base_cost*(profit/100);
    let sub = base_cost+profit_amt+transport+extra;
    let gst = useGST?sub*0.18:0;
    let grand = sub+gst;
    let billingFactor = (actualTotal>0 && billingTotal>0) ? (billingTotal/actualTotal) : 1;
    let billingSub = sub * billingFactor;
    let billingGst = useGST ? billingSub*0.18 : 0;
    let billingGrand = billingSub + billingGst;
    if(billingMode==='actual' && !minBilling){ ... }

    Returns tuple:
    (profit_amt, sub_total, gst_amount, grand_total,
     billing_sub_total, billing_gst, billing_grand_total, final_billing_sqft)
    """
    profit_amt = base_cost * (profit / 100.0)
    sub = base_cost + profit_amt + transport + extra
    gst = sub * 0.18 if use_gst else 0.0
    grand = sub + gst

    actual_total = total_sqft
    billing_total = billing_sqft

    billing_factor = (billing_total / actual_total) if (actual_total > 0 and billing_total > 0) else 1.0
    billing_sub = sub * billing_factor
    billing_gst = billing_sub * 0.18 if use_gst else 0.0
    billing_grand = billing_sub + billing_gst

    if billing_mode == "actual" and not min_billing:
        billing_total = actual_total
        billing_grand = grand
        billing_sub = sub
        billing_gst = gst

    return (
        profit_amt,
        sub,
        gst,
        grand,
        billing_sub,
        billing_gst,
        billing_grand,
        billing_total
    )
