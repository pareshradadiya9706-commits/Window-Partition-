"""
SOURCE: Models for DW Ultimate Pro V3 Window + Partition items.
Direct 1-to-1 parity with verified JavaScript source structures.
"""
from dataclasses import dataclass, field
from typing import Optional, List, Dict, Any

@dataclass
class WindowItem:
    """
    SOURCE: CART item with series in ['18x40', '60mm', 'Domal', 'R40', 'Louver', 'Repairing']
    """
    series: str
    track: str = "-"
    w: float = 0.0
    h: float = 0.0
    qty: int = 1
    jali: bool = False
    gtype: str = "Plain/Clear"
    desc: Optional[str] = None
    glass: float = 0.0
    hw: float = 0.0
    labor: float = 0.0

@dataclass
class PartitionItem:
    """
    SOURCE: CART item with series == 'Partition'
    """
    series: str = "Partition"
    track: str = "-"
    w: float = 0.0
    h: float = 0.0
    qty: int = 1
    dw: float = 36.0
    dh: float = 84.0
    topMat: str = "sheet"        # 'glass' or 'sheet'
    midDes: str = "standard"     # 'standard', 'full_glass', 'full_sheet'
    bh: float = 36.0
    paneWSize: str = "36-42"     # '24-30', '30-36', '36-42', '42-48'
    jali: bool = False
    gtype: str = ""

@dataclass
class ExtraItem:
    """
    SOURCE: EXTRA_ITEMS array in JS source
    """
    name: str
    qty: int = 1
    rate: float = 0.0

@dataclass
class ScrapItem:
    """
    SOURCE: SCRAP array in JS source
    """
    series: str
    part: str
    length: float
    qty: int = 1
    date: int = 0
