"""
SOURCE: Master Rates, Profile Weights, Coating Rates, and Project settings.
Direct 1-to-1 parity with verified JavaScript source structures.
"""
from dataclasses import dataclass, field
from typing import Dict, Any, List

# SOURCE: WEIGHTS_PER_FT in JavaScript source
WEIGHTS_PER_FT: Dict[str, Dict[str, float]] = {
    "18x40_2Track_Bottom": {"Light": 0.15, "Medium": 0.17, "Heavy": 0.21},
    "18x40_2Track_Top": {"Light": 0.125, "Medium": 0.15, "Heavy": 0.175},
    "18x40_3Track_Bottom": {"Light": 0.209, "Medium": 0.24, "Heavy": 0.3},
    "18x40_3Track_Top": {"Light": 0.175, "Medium": 0.2, "Heavy": 0.26},
    "18x40_4Track_Bottom": {"Light": 0.375, "Medium": 0.375, "Heavy": 0.375},
    "18x40_4Track_Top": {"Light": 0.334, "Medium": 0.334, "Heavy": 0.334},
    "18x40_Handle": {"Light": 0.1, "Medium": 0.11, "Heavy": 0.11},
    "18x40_Interlock": {"Light": 0.11, "Medium": 0.128, "Heavy": 0.128},
    "18x40_BearingPatti": {"Light": 0.1, "Medium": 0.11, "Heavy": 0.11},
    "60mm_2Track_Bottom": {"Light": 0.15, "Medium": 0.17, "Heavy": 0.21},
    "60mm_2Track_Top": {"Light": 0.125, "Medium": 0.15, "Heavy": 0.175},
    "60mm_3Track_Bottom": {"Light": 0.209, "Medium": 0.24, "Heavy": 0.3},
    "60mm_3Track_Top": {"Light": 0.175, "Medium": 0.2, "Heavy": 0.26},
    "60mm_4Track_Bottom": {"Light": 0.375, "Medium": 0.375, "Heavy": 0.375},
    "60mm_4Track_Top": {"Light": 0.334, "Medium": 0.334, "Heavy": 0.334},
    "60mm_Handle": {"Light": 0.167, "Medium": 0.167, "Heavy": 0.169},
    "60mm_Interlock": {"Light": 0.187, "Medium": 0.187, "Heavy": 0.19},
    "60mm_BearingPatti": {"Light": 0.167, "Medium": 0.167, "Heavy": 0.169},
    "Domal_2Track_Frame": {"Light": 0.24, "Medium": 0.25, "Heavy": 0.25},
    "Domal_3Track_Frame": {"Light": 0.342, "Medium": 0.325, "Heavy": 0.4},
    "Domal_4Track_Frame": {"Light": 0.563, "Medium": 0.563, "Heavy": 0.563},
    "Domal_Handle": {"Light": 0.22, "Medium": 0.24, "Heavy": 0.25},
    "Domal_Interlock": {"Light": 0.109, "Medium": 0.1, "Heavy": 0.109},
    "R40_Frame": {"Light": 0.192, "Medium": 0.192, "Heavy": 0.192},
    "R40_Shutter": {"Light": 0.217, "Medium": 0.217, "Heavy": 0.217},
    "R40_Mulleon": {"Light": 0.2, "Medium": 0.2, "Heavy": 0.2},
    "R40_Clip": {"Light": 0.092, "Medium": 0.092, "Heavy": 0.092},
    "Louver_Frame": {"Light": 0.15, "Medium": 0.18, "Heavy": 0.20},
    "Partition_DP_Pipe": {"Light": 2.5 / 15.0, "Medium": 2.5 / 15.0, "Heavy": 3.1 / 15.0},
    "Partition_Door_Pipe": {"Light": 2.0 / 12.0, "Medium": 3.0 / 12.0, "Heavy": 4.3 / 12.0}
}

# SOURCE: COATING_RATES in JavaScript source
COATING_RATES: Dict[str, Dict[str, float]] = {
    "18x40_2Track_Bottom": {"Anodized": 18.6, "Powder": 10.0, "Guaranteed": 17.3},
    "18x40_2Track_Top": {"Anodized": 16.6, "Powder": 10.0, "Guaranteed": 14.2},
    "18x40_3Track_Bottom": {"Anodized": 25.0, "Powder": 12.0, "Guaranteed": 22.0},
    "18x40_3Track_Top": {"Anodized": 22.0, "Powder": 12.0, "Guaranteed": 18.0},
    "18x40_4Track_Bottom": {"Anodized": 40.0, "Powder": 16.0, "Guaranteed": 34.0},
    "18x40_4Track_Top": {"Anodized": 35.0, "Powder": 16.0, "Guaranteed": 28.0},
    "18x40_Handle": {"Anodized": 9.5, "Powder": 6.25, "Guaranteed": 8.5},
    "18x40_Interlock": {"Anodized": 11.8, "Powder": 6.25, "Guaranteed": 10.4},
    "18x40_BearingPatti": {"Anodized": 12.0, "Powder": 6.25, "Guaranteed": 11.0},
    "60mm_2Track_Bottom": {"Anodized": 18.6, "Powder": 10.0, "Guaranteed": 17.3},
    "60mm_2Track_Top": {"Anodized": 16.6, "Powder": 10.0, "Guaranteed": 14.2},
    "60mm_3Track_Bottom": {"Anodized": 25.0, "Powder": 12.0, "Guaranteed": 22.0},
    "60mm_3Track_Top": {"Anodized": 22.0, "Powder": 12.0, "Guaranteed": 18.0},
    "60mm_4Track_Bottom": {"Anodized": 40.0, "Powder": 16.0, "Guaranteed": 34.0},
    "60mm_4Track_Top": {"Anodized": 35.0, "Powder": 16.0, "Guaranteed": 28.0},
    "60mm_Handle": {"Anodized": 14.4, "Powder": 9.25, "Guaranteed": 12.3},
    "60mm_Interlock": {"Anodized": 17.4, "Powder": 9.25, "Guaranteed": 13.5},
    "60mm_BearingPatti": {"Anodized": 14.4, "Powder": 9.25, "Guaranteed": 13.8},
    "Domal_2Track_Frame": {"Anodized": 26.0, "Powder": 16.0, "Guaranteed": 18.0},
    "Domal_3Track_Frame": {"Anodized": 35.0, "Powder": 21.0, "Guaranteed": 23.0},
    "Domal_4Track_Frame": {"Anodized": 42.0, "Powder": 27.0, "Guaranteed": 32.0},
    "Domal_Handle": {"Anodized": 20.0, "Powder": 12.0, "Guaranteed": 16.0},
    "Domal_Interlock": {"Anodized": 11.8, "Powder": 8.0, "Guaranteed": 9.0},
    "R40_Frame": {"Anodized": 17.0, "Powder": 12.0, "Guaranteed": 15.5},
    "R40_Shutter": {"Anodized": 20.0, "Powder": 12.0, "Guaranteed": 15.5},
    "R40_Mulleon": {"Anodized": 20.0, "Powder": 14.0, "Guaranteed": 15.5},
    "R40_Clip": {"Anodized": 11.0, "Powder": 7.0, "Guaranteed": 9.0},
    "Louver_Frame": {"Anodized": 15.0, "Powder": 10.0, "Guaranteed": 14.0},
    "Partition_DP_Pipe": {"Anodized": 12.0, "Powder": 10.0, "Guaranteed": 15.0},
    "Partition_Door_Pipe": {"Anodized": 12.0, "Powder": 10.0, "Guaranteed": 15.0},
    "Partition_Clip": {"Anodized": 4.5, "Powder": 3.0, "Guaranteed": 5.0}
}

# SOURCE: Default Rates in Settings tab HTML inputs
DEFAULT_RATES: Dict[str, float] = {
    "alu_rate": 480.0,
    "jali_rate": 0.0,
    "louver_rate": 130.0,
    "part_clip_rate": 130.0,
    "part_dp_rate": 460.0,
    "part_door_rate": 460.0,
    "part_sheet_rate": 55.0,
    "part_hw_rate": 850.0,
    "s18_glass": 58.0,
    "s18_labor": 20.0,
    "s18_hardw": 15.0,
    "s60_glass": 60.0,
    "s60_labor": 35.0,
    "s60_hardw": 26.0,
    "domal_glass": 75.0,
    "domal_labor": 60.0,
    "domal_hardw": 52.0,
    "r40_glass": 70.0,
    "r40_labor": 45.0,
    "r40_hardw": 60.0
}
