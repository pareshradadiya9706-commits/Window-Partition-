"""
SOURCE: Calculation Service facade wrapping calculate_project() and export utilities.
"""
from typing import List, Dict, Any, Optional, Union
from python_backend.models.window import WindowItem, PartitionItem, ExtraItem, ScrapItem
from python_backend.models.calculation_result import CalculationResult
from python_backend.calculations.project_calculator import calculate_project
from python_backend.calculations.cutting_optimizer import format_dora

class CalculationService:
    """
    Facade service orchestrating project estimations, cutting lists, and worker share text generation.
    """
    @staticmethod
    def calculate(
        cart: List[Union[WindowItem, PartitionItem, Dict[str, Any]]],
        allowed_pipes: Optional[List[int]] = None,
        rates: Optional[Dict[str, float]] = None,
        coating: str = "Powder",
        weight_type: str = "Medium",
        profit: float = 10.0,
        transport: float = 0.0,
        extra: float = 0.0,
        use_gst: bool = True,
        billing_mode: str = "actual",
        min_billing: bool = False,
        scrap: Optional[List[Union[ScrapItem, Dict[str, Any]]]] = None,
        extra_items: Optional[List[Union[ExtraItem, Dict[str, Any]]]] = None
    ) -> CalculationResult:
        """
        Calculates complete project BOQ, cutting lists, and totals.
        """
        return calculate_project(
            cart=cart,
            allowed=allowed_pipes,
            rates=rates,
            coat=coating,
            w_type=weight_type,
            profit=profit,
            transport=transport,
            extra=extra,
            use_gst=use_gst,
            billing_mode=billing_mode,
            min_billing=min_billing,
            scrap=scrap,
            extra_items=extra_items
        )

    @staticmethod
    def generate_worker_text(customer_name: str, result: CalculationResult) -> str:
        """
        SOURCE: function shareWorkerWA() in JavaScript source.
        """
        c_name = customer_name if customer_name else "Customer"
        lines = [f"*DW Worker Cut*", f"Customer: {c_name}", ""]
        for sec, packed in result.packed_data.items():
            lines.append(f"*{sec}* - {len(packed.pipes)} pipes")
            for i, b in enumerate(packed.pipes):
                cuts_str = " + ".join(format_dora(c if not isinstance(c, dict) else c.get("len", c)) for c in b.cuts)
                lines.append(f"Pipe {i + 1} ({b.size_ft}Ft): {cuts_str}")
            lines.append("")
        return "\n".join(lines)
