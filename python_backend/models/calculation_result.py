"""
SOURCE: Data models for calculation outputs returned by calculate_project().
Direct 1-to-1 parity with verified JavaScript source structures.
"""
from dataclasses import dataclass, field
from typing import List, Dict, Any, Optional

@dataclass
class CutSummaryRow:
    """
    SOURCE: cut_sum item in calculate_project()
    """
    no: int
    series: str
    track: str
    w: Any  # float or "-"
    h: Any  # float or "-"
    qty: int
    gw: Optional[float] = None
    gh: Optional[float] = None
    gq: Optional[int] = None
    jali: bool = False
    glass: float = 0.0
    hw: float = 0.0
    labor: float = 0.0

@dataclass
class GlassDetail:
    """
    SOURCE: glass_details item in calculate_project()
    """
    no: int
    w: float
    h: float
    qty: int
    sqft: float

@dataclass
class PipeCutBin:
    """
    SOURCE: pack_bfd / best item in calculate_project()
    """
    size_ft: int
    cuts: List[Any]
    waste: float
    weight: float

@dataclass
class PackedSection:
    """
    SOURCE: packed[sec] in calculate_project()
    """
    pipes: List[PipeCutBin] = field(default_factory=list)
    scrapUsed: int = 0
    totalNeeded: int = 0

@dataclass
class BillingDetail:
    """
    SOURCE: window._billingData.details item in calculate_project()
    """
    no: int
    w: float
    h: float
    bw: float
    bh: float
    actualSqftPerPiece: float
    billingSqftPerPiece: float
    qty: int
    minApplied: bool

@dataclass
class CalculationResult:
    """
    SOURCE: Return object of calculate_project() in JS source
    """
    total_sqft: float
    total_weight: float
    total_alu_cost: float
    total_glass_cost: float
    total_coat_cost: float
    total_labor_cost: float
    total_hardware_cost: float
    total_jali_cost: float
    total_louver_cost: float
    total_part_sheet_cost: float
    total_extra_cost: float
    base_cost: float
    profit_amt: float
    transport: float
    extra: float
    sub_total: float
    gst_amount: float
    total_windows: int
    grand_total: float
    packed_data: Dict[str, PackedSection]
    cutting_summary: List[CutSummaryRow]
    glass_details: List[GlassDetail]
    total_glass_sqft: float
    billing_sqft: float
    billing_sub_total: float
    billing_gst: float
    billing_grand_total: float
    billing_mode: str
    min_billing_enabled: bool
    min_applied: bool
    billing_details: List[BillingDetail]
