"""
SOURCE: Partition models and 2D partition drawing data structures from JS source.
"""
from dataclasses import dataclass, field
from typing import List, Dict, Any, Optional

@dataclass
class PartitionDrawData:
    """
    SOURCE: lastDrawData.partitions in calculate_project()
    """
    w: float
    h: float
    dw: float
    dh: float
    bh: float
    cols: int
    paneW: float
    glassH: float
    topH: float
    topMat: str
    midDes: str

@dataclass
class SheetPiece:
    """
    SOURCE: globalPiecesObj in calculate_project()
    """
    w: float
    h: float
    id: str
    fit: Optional[Dict[str, float]] = None
    rotated: bool = False

@dataclass
class SheetUsed:
    """
    SOURCE: lastDrawData.sheets in calculate_project()
    """
    size: Dict[str, float]  # {'w': 48, 'h': 96}, etc.
    pieces: List[SheetPiece] = field(default_factory=list)
