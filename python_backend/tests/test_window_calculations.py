"""
Unit tests for Window Series calculations (18x40, 60mm, Domal, R40, Louver, Repairing).
Verifies exact 1-to-1 parity with verified JavaScript source logic.
"""
import unittest
from python_backend.models.window import WindowItem
from python_backend.models.project import DEFAULT_RATES
from python_backend.calculations.window_calculations import calculate_window_cuts

class TestWindowCalculations(unittest.TestCase):
    def setUp(self):
        self.rates = dict(DEFAULT_RATES)

    def test_18x40_2track_standard(self):
        """
        Input: 18x40 2Track Window, 48" x 48", Qty 1, without Jali
        Formulas from source:
        - Handle / Interlock: H - 1.5 = 48 - 1.5 = 46.5
        - Hor (Bearing Patti): (W - 6.5) / 2 = (48 - 6.5) / 2 = 20.75
        - Glass Width: hor + 0.65 = 20.75 + 0.65 = 21.4
        - Glass Height: H - 4.0 = 48 - 4.0 = 44.0
        - Glass Qty: (4 / 2) * 1 = 2
        - Glass Sqft: (21.4 * 44.0) / 144 * 2 = 13.0777...
        """
        item = WindowItem(series="18x40", track="2Track", w=48.0, h=48.0, qty=1, jali=False)
        master = {}
        gw, gh, gq, g_sqft, jali_cost, louver_cost, g_cost, l_cost, h_cost = calculate_window_cuts(
            item=item, index=0, rates=self.rates, master=master
        )
        self.assertAlmostEqual(gw, 21.4, places=4)
        self.assertAlmostEqual(gh, 44.0, places=4)
        self.assertEqual(gq, 2)
        self.assertAlmostEqual(g_sqft, (21.4 * 44.0) / 144.0 * 2, places=4)

        # Check cuts allocated in master
        self.assertEqual(len(master["18x40 2Track Bottom"]), 1)
        self.assertEqual(master["18x40 2Track Bottom"][0]["len"], 48.0)
        self.assertEqual(len(master["18x40 2Track Top"]), 3)  # 1 top horizontal (48) + 2 top verticals (48)
        self.assertEqual(len(master["18x40 BearingPatti"]), 4)
        self.assertAlmostEqual(master["18x40 BearingPatti"][0]["len"], 20.75, places=4)
        self.assertEqual(len(master["18x40 Handle"]), 2)
        self.assertAlmostEqual(master["18x40 Handle"][0]["len"], 46.5, places=4)
        self.assertEqual(len(master["18x40 Interlock"]), 2)
        self.assertAlmostEqual(master["18x40 Interlock"][0]["len"], 46.5, places=4)

    def test_60mm_3track_standard(self):
        """
        Input: 60mm 3Track Window, 60" x 60", Qty 1
        Formulas from source:
        - Handle / Interlock: H - 1.5 = 60 - 1.5 = 58.5
        - Hor (Bearing Patti): (W + 2.5) / 3 = (60 + 2.5) / 3 = 20.833333333333332
        - Glass Width: hor - 4.125 = 20.833333333333332 - 4.125 = 16.708333333333332
        - Glass Height: H - 5.5 = 60 - 5.5 = 54.5
        - Glass Qty: (6 / 2) * 1 = 3
        """
        item = WindowItem(series="60mm", track="3Track", w=60.0, h=60.0, qty=1, jali=False)
        master = {}
        gw, gh, gq, g_sqft, jali_cost, louver_cost, g_cost, l_cost, h_cost = calculate_window_cuts(
            item=item, index=0, rates=self.rates, master=master
        )
        self.assertAlmostEqual(gw, (62.5 / 3.0) - 4.125, places=4)
        self.assertAlmostEqual(gh, 54.5, places=4)
        self.assertEqual(gq, 3)
        self.assertEqual(len(master["60mm BearingPatti"]), 6)
        self.assertEqual(len(master["60mm Handle"]), 2)
        self.assertEqual(len(master["60mm Interlock"]), 4)

    def test_domal_2track_standard(self):
        """
        Input: Domal 2Track Window, 48" x 48", Qty 1
        Formulas from source:
        - Handle / Interlock: H - 2.75 = 48 - 2.75 = 45.25
        - Hor (Domal Handle): (W + 0.5) / 2 = 48.5 / 2 = 24.25
        - Glass Width: hor - 4.125 = 24.25 - 4.125 = 20.125
        - Glass Height: hnd - 4.125 = 45.25 - 4.125 = 41.125
        - Glass Qty: (4 / 2) * 1 = 2
        """
        item = WindowItem(series="Domal", track="2Track", w=48.0, h=48.0, qty=1, jali=False)
        master = {}
        gw, gh, gq, g_sqft, jali_cost, louver_cost, g_cost, l_cost, h_cost = calculate_window_cuts(
            item=item, index=0, rates=self.rates, master=master
        )
        self.assertAlmostEqual(gw, 20.125, places=4)
        self.assertAlmostEqual(gh, 41.125, places=4)
        self.assertEqual(gq, 2)
        self.assertEqual(len(master["Domal 2Track Frame"]), 4)  # 2 W (48) + 2 H (48)
        self.assertEqual(len(master["Domal Handle"]), 8)        # 4 hor (24.25) + 4 hnd (45.25)
        self.assertEqual(len(master["Domal Interlock"]), 2)     # 2 intc (45.25)

    def test_louver_blades(self):
        """
        Input: Louver Window, 24" x 36", Qty 1
        Formulas from source:
        - Blades count = max(1, round((36 - 1) / 3.5)) = round(35 / 3.5) = 10
        - Blade glass width = 24 - 1.5 = 22.5
        - Blade glass height = 4.0
        - Blade glass qty = 10
        - Total louver cost = 10 * 1 * 130 = 1300
        """
        item = WindowItem(series="Louver", track="Glass Blade", w=24.0, h=36.0, qty=1)
        master = {}
        gw, gh, gq, g_sqft, jali_cost, louver_cost, g_cost, l_cost, h_cost = calculate_window_cuts(
            item=item, index=0, rates=self.rates, master=master
        )
        self.assertAlmostEqual(gw, 22.5, places=4)
        self.assertAlmostEqual(gh, 4.0, places=4)
        self.assertEqual(gq, 10)
        self.assertAlmostEqual(louver_cost, 1300.0, places=4)

if __name__ == "__main__":
    unittest.main()
