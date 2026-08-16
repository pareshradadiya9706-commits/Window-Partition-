"""
SOURCE: Main calculation engine function calculate_project().
Direct 1-to-1 parity with verified JavaScript source function calculate_project().
"""
import math
from typing import List, Dict, Any, Optional, Union

from python_backend.models.window import WindowItem, PartitionItem, ExtraItem, ScrapItem
from python_backend.models.partition import PartitionDrawData, SheetUsed
from python_backend.models.project import DEFAULT_RATES
from python_backend.models.calculation_result import (
    CalculationResult, CutSummaryRow, GlassDetail, BillingDetail
)
from python_backend.calculations.window_calculations import calculate_window_cuts
from python_backend.calculations.partition_calculations import calculate_partition_cuts
from python_backend.calculations.cutting_optimizer import MaxRectsPacker
from python_backend.calculations.cost_calculator import (
    compute_section_packing_and_cost, compute_final_totals
)

def calculate_project(
    cart: List[Union[WindowItem, PartitionItem, Dict[str, Any]]],
    allowed: Optional[List[int]] = None,
    rates: Optional[Dict[str, float]] = None,
    coat: str = "Powder",
    w_type: str = "Medium",
    profit: float = 0.0,
    transport: float = 0.0,
    extra: float = 0.0,
    use_gst: bool = True,
    billing_mode: str = "actual",
    min_billing: bool = False,
    scrap: Optional[List[Union[ScrapItem, Dict[str, Any]]]] = None,
    extra_items: Optional[List[Union[ExtraItem, Dict[str, Any]]]] = None
) -> CalculationResult:
    """
    SOURCE: function calculate_project(cart, allowed, rates, coat, w_type, profit=0, transport=0, extra=0, useGST=true, billingMode='actual', minBilling=false)
    in verified JavaScript source.
    """
    if allowed is None:
        allowed = [12, 15, 16]
    if rates is None:
        rates = dict(DEFAULT_RATES)
    else:
        # Merge with defaults to ensure all keys present
        merged_rates = dict(DEFAULT_RATES)
        merged_rates.update(rates)
        rates = merged_rates

    if scrap is None:
        scrap = []
    if extra_items is None:
        extra_items = []

    master: Dict[str, List[Dict[str, Any]]] = {}
    total_sqft = 0.0
    total_glass_sqft = 0.0
    total_jali = 0.0
    total_louver = 0.0
    glass_details: List[GlassDetail] = []
    cut_sum: List[CutSummaryRow] = []
    total_glass_cost = 0.0
    total_labor = 0.0
    total_hard = 0.0
    total_qty = 0
    total_part_sheet_cost = 0.0
    total_part_hardware = 0.0
    total_extra_cost = 0.0

    billing_details: List[BillingDetail] = []
    total_billing_sqft = 0.0
    min_applied = False

    # Scrap map construction
    scrap_map: Dict[str, List[float]] = {}
    for s in scrap:
        if isinstance(s, dict):
            s_series = s.get("series", "")
            s_part = s.get("part", "")
            s_len = float(s.get("len", s.get("length", 0.0)))
            s_qty = int(s.get("qty", 1))
        else:
            s_series = s.series
            s_part = s.part
            s_len = float(s.length)
            s_qty = int(s.qty)

        key = f"{s_series} {s_part}"
        if key not in scrap_map:
            scrap_map[key] = []
        for _ in range(s_qty):
            scrap_map[key].append(s_len)

    last_draw_partitions: List[PartitionDrawData] = []
    last_draw_sheets: List[SheetUsed] = []
    global_pieces_obj: List[Dict[str, Any]] = []

    for i, raw_item in enumerate(cart):
        if isinstance(raw_item, dict):
            sr = raw_item.get("series", "")
            if sr == "Partition":
                item: Union[WindowItem, PartitionItem] = PartitionItem(**raw_item)
            else:
                item = WindowItem(**raw_item)
        else:
            item = raw_item

        sr = item.series
        if sr == "Repairing":
            # SOURCE: if(sr=="Repairing")
            q = int(item.qty)
            total_qty += q
            g_cost = float(item.glass or 0.0) * q
            h_cost = float(item.hw or 0.0) * q
            l_cost = float(item.labor or 0.0) * q
            total_glass_cost += g_cost
            total_hard += h_cost
            total_labor += l_cost
            cut_sum.append(
                CutSummaryRow(
                    no=i + 1,
                    series="Repairing",
                    track=item.desc or "",
                    w="-",
                    h="-",
                    qty=q,
                    glass=float(item.glass or 0.0),
                    hw=float(item.hw or 0.0),
                    labor=float(item.labor or 0.0)
                )
            )
            continue

        w = float(item.w)
        h = float(item.h)
        qty = int(item.qty)
        tr = item.track if item.track else "-"
        jali = bool(item.jali)

        sqft = (w * h) / 144.0 * qty
        total_sqft += sqft
        total_qty += qty

        # Billing area calculation with +3 inch rule and min 11 sqft
        bw = w
        bh = h
        if billing_mode == "plus3":
            bw = math.ceil(w / 3.0) * 3.0
            bh = math.ceil(h / 3.0) * 3.0

        billing_sqft_per_piece = (bw * bh) / 144.0
        min_applied_for_this = False
        if min_billing and billing_sqft_per_piece < 11.0:
            billing_sqft_per_piece = 11.0
            min_applied_for_this = True

        total_billing_sqft += billing_sqft_per_piece * qty
        if min_applied_for_this:
            min_applied = True

        billing_details.append(
            BillingDetail(
                no=i + 1,
                w=w,
                h=h,
                bw=bw,
                bh=bh,
                actualSqftPerPiece=(w * h) / 144.0,
                billingSqftPerPiece=billing_sqft_per_piece,
                qty=qty,
                minApplied=min_applied_for_this
            )
        )

        if sr == "Partition":
            # SOURCE: if(sr=="Partition")
            assert isinstance(item, PartitionItem)
            pane_w, top_h, p_glass_sqft, p_hw, p_labor = calculate_partition_cuts(
                item=item,
                index=i,
                rates=rates,
                master=master,
                last_partitions=last_draw_partitions,
                global_pieces=global_pieces_obj
            )
            total_glass_sqft += p_glass_sqft
            total_part_hardware += p_hw
            total_labor += p_labor
            cut_sum.append(
                CutSummaryRow(
                    no=i + 1,
                    series="Partition",
                    track=tr,
                    w=w,
                    h=h,
                    qty=qty,
                    gw=pane_w,
                    gh=top_h
                )
            )
        else:
            # SOURCE: Standard window series
            assert isinstance(item, WindowItem)
            (
                g_w, g_h, g_qty, w_glass_sqft, w_jali_cost, w_louver_cost,
                w_glass_cost, w_labor_cost, w_hard_cost
            ) = calculate_window_cuts(
                item=item,
                index=i,
                rates=rates,
                master=master
            )
            total_glass_sqft += w_glass_sqft
            total_jali += w_jali_cost
            total_louver += w_louver_cost
            total_glass_cost += w_glass_cost
            total_labor += w_labor_cost
            total_hard += w_hard_cost

            if sr != "Louver" and g_qty > 0:
                glass_details.append(
                    GlassDetail(
                        no=i + 1,
                        w=g_w,
                        h=g_h,
                        qty=g_qty,
                        sqft=w_glass_sqft
                    )
                )

            cut_sum.append(
                CutSummaryRow(
                    no=i + 1,
                    series=sr,
                    track=tr,
                    w=w,
                    h=h,
                    qty=qty,
                    gw=g_w,
                    gh=g_h,
                    gq=g_qty,
                    jali=jali
                )
            )

    # Extra Items Sum
    for ex in extra_items:
        if isinstance(ex, dict):
            ex_rate = float(ex.get("rate", 0.0))
            ex_qty = float(ex.get("qty", 1.0))
        else:
            ex_rate = float(ex.rate)
            ex_qty = float(ex.qty)
        total_extra_cost += ex_rate * ex_qty

    # Extrusion Optimization & Weights
    packed, total_wt, total_alu, total_coat, finish_extra_amt = compute_section_packing_and_cost(
        master=master,
        scrap_map=scrap_map,
        allowed_pipes=allowed,
        w_type=w_type,
        coat=coat,
        rates=rates
    )

    # 2D Sheet Packing Optimization
    if len(global_pieces_obj) > 0:
        sheet_sizes = [{"w": 48.0, "h": 96.0}, {"w": 72.0, "h": 96.0}, {"w": 72.0, "h": 108.0}]
        unplaced = list(global_pieces_obj)
        sheets_used: List[SheetUsed] = []
        safety = 0

        while len(unplaced) > 0 and safety < 20:
            safety += 1
            best_size = None
            best_pack = None
            best_util = -1.0

            for size in sheet_sizes:
                packer = MaxRectsPacker(size["w"], size["h"], 0.12, True)
                trial = sorted(
                    [dict(o) for o in unplaced],
                    key=lambda b: float(b["w"]) * float(b["h"]),
                    reverse=True
                )
                packer.fit(trial)
                if len(packer.used) == 0:
                    continue
                util = sum(float(p["w"]) * float(p["h"]) for p in packer.used) / (size["w"] * size["h"])
                if util > best_util:
                    best_util = util
                    best_size = size
                    best_pack = packer

            if not best_pack or not best_size:
                break

            sheets_used.append(
                SheetUsed(
                    size=best_size,
                    pieces=best_pack.used
                )
            )
            placed_ids = {p["id"] for p in best_pack.used}
            unplaced = [p for p in unplaced if p["id"] not in placed_ids]

        sheet_sqft = sum((sh.size["w"] * sh.size["h"]) / 144.0 for sh in sheets_used)
        total_part_sheet_cost = sheet_sqft * float(rates.get("part_sheet_rate", 55.0))

    # Base Cost Aggregation
    base_cost = (
        total_alu
        + total_glass_cost
        + total_coat
        + total_labor
        + total_hard
        + total_jali
        + total_louver
        + total_part_sheet_cost
        + total_part_hardware
        + finish_extra_amt
        + total_extra_cost
    )

    (
        profit_amt, sub_total, gst_amount, grand_total,
        billing_sub_total, billing_gst, billing_grand_total, final_billing_sqft
    ) = compute_final_totals(
        base_cost=base_cost,
        profit=profit,
        transport=transport,
        extra=extra,
        use_gst=use_gst,
        total_sqft=total_sqft,
        billing_sqft=total_billing_sqft,
        billing_mode=billing_mode,
        min_billing=min_billing
    )

    return CalculationResult(
        total_sqft=total_sqft,
        total_weight=total_wt,
        total_alu_cost=total_alu,
        total_glass_cost=total_glass_cost,
        total_coat_cost=total_coat + finish_extra_amt,
        total_labor_cost=total_labor,
        total_hardware_cost=total_hard + total_part_hardware,
        total_jali_cost=total_jali,
        total_louver_cost=total_louver,
        total_part_sheet_cost=total_part_sheet_cost,
        total_extra_cost=total_extra_cost,
        base_cost=base_cost,
        profit_amt=profit_amt,
        transport=transport,
        extra=extra,
        sub_total=sub_total,
        gst_amount=gst_amount,
        total_windows=total_qty,
        grand_total=grand_total,
        packed_data=packed,
        cutting_summary=cut_sum,
        glass_details=glass_details,
        total_glass_sqft=total_glass_sqft,
        billing_sqft=final_billing_sqft,
        billing_sub_total=billing_sub_total,
        billing_gst=billing_gst,
        billing_grand_total=billing_grand_total,
        billing_mode=billing_mode,
        min_billing_enabled=min_billing,
        min_applied=min_applied,
        billing_details=billing_details
    )
