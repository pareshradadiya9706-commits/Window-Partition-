"""
Unit tests for 1D BFD Cutting Optimizer and formatDora fraction formatter.
Verifies exact 1-to-1 parity with verified JavaScript source logic.
"""
import unittest
from python_backend.calculations.cutting_optimizer import pack_bfd, format_dora, MaxRectsPacker

class TestCuttingOptimizer(unittest.TestCase):
    def test_format_dora_fractions(self):
        """
        Tests decimal to inch-soot fraction conversions from source formatDora:
        - 48.0 -> 48"
        - 46.5 -> 46 1/2"
        - 20.75 -> 20 3/4"
        - 20.125 -> 20 1/8"
        - 0 -> -
        """
        self.assertEqual(format_dora(48.0), '48"')
        self.assertEqual(format_dora(46.5), '46 1/2"')
        self.assertEqual(format_dora(20.75), '20 3/4"')
        self.assertEqual(format_dora(20.125), '20 1/8"')
        self.assertEqual(format_dora(0.0), '-')
        self.assertEqual(format_dora(None), '-')

    def test_pack_bfd_linear_cuts(self):
        """
        Input: cuts [48.0, 48.0, 48.0], allowed stock [12, 15, 16] ft
        12 ft = 144 inches.
        Cuts + kerf (0.15):
        Cut 1: 48.0 -> remaining = 144 - 48.0 = 96.0
        Cut 2: 48.0 + 0.15 = 48.15 -> remaining = 96.0 - 48.15 = 47.85
        Cut 3: 48.0 needs 48.15 > 47.85 -> Opens new 12ft bin (144 - 48.0 = 96.0 remaining)
        Total bins = 2
        """
        cuts = [48.0, 48.0, 48.0]
        bins = pack_bfd(cuts, allowed=[12, 15, 16], kerf=0.15)
        self.assertEqual(len(bins), 2)
        self.assertEqual(bins[0]["size"], 144)
        self.assertEqual(len(bins[0]["cuts"]), 2)
        self.assertAlmostEqual(bins[0]["rem"], 144.0 - 48.0 - 48.15, places=4)
        self.assertEqual(bins[1]["size"], 144)
        self.assertEqual(len(bins[1]["cuts"]), 1)
        self.assertAlmostEqual(bins[1]["rem"], 144.0 - 48.0, places=4)

    def test_maxrects_packer_2d(self):
        """
        Tests 2D nesting of two 24x48 panels in a 48x96 sheet.
        Both should fit in a single 48x96 sheet.
        """
        packer = MaxRectsPacker(48.0, 96.0, kerf=0.12, allow_rot=True)
        blocks = [
            {"w": 24.0, "h": 48.0, "id": "P1"},
            {"w": 24.0, "h": 48.0, "id": "P2"}
        ]
        packer.fit(blocks)
        self.assertEqual(len(packer.used), 2)
        self.assertIsNotNone(packer.used[0].get("fit"))
        self.assertIsNotNone(packer.used[1].get("fit"))

if __name__ == "__main__":
    unittest.main()
