"""
Unit tests for Full Cost Calculator and calculate_project() integration.
Verifies exact 1-to-1 parity with verified JavaScript source logic.
"""
import unittest
from python_backend.models.window import WindowItem, ExtraItem, ScrapItem
from python_backend.models.project import DEFAULT_RATES
from python_backend.calculations.project_calculator import calculate_project

class TestCostCalculator(unittest.TestCase):
    def setUp(self):
        self.rates = dict(DEFAULT_RATES)

    def test_single_window_actual_mode(self):
        """
        Input: 18x40 2Track Window, 48" x 48", Qty 1, Actual billing mode, no profit, no transport, GST 18%
        Area: (48 * 48) / 144 = 16.0 sqft
        """
        cart = [WindowItem(series="18x40", track="2Track", w=48.0, h=48.0, qty=1, jali=False)]
        res = calculate_project(
            cart=cart,
            allowed=[12, 15, 16],
            rates=self.rates,
            coat="Powder",
            w_type="Medium",
            profit=0.0,
            transport=0.0,
            extra=0.0,
            use_gst=True,
            billing_mode="actual",
            min_billing=False
        )
        self.assertAlmostEqual(res.total_sqft, 16.0, places=4)
        self.assertAlmostEqual(res.billing_sqft, 16.0, places=4)
        self.assertEqual(res.total_windows, 1)

        # Base cost checks:
        # Glass cost = 16 sqft * 58 = 928.0
        # Labor cost = 16 sqft * 20 = 320.0
        # Hardw cost = 16 sqft * 15 = 240.0
        self.assertAlmostEqual(res.total_glass_cost, 928.0, places=4)
        self.assertAlmostEqual(res.total_labor_cost, 320.0, places=4)
        self.assertAlmostEqual(res.total_hardware_cost, 240.0, places=4)

        # Sub total = base_cost + 0
        # GST = sub_total * 0.18
        # Grand total = sub_total + GST
        self.assertAlmostEqual(res.sub_total, res.base_cost, places=4)
        self.assertAlmostEqual(res.gst_amount, res.sub_total * 0.18, places=4)
        self.assertAlmostEqual(res.grand_total, res.sub_total + res.gst_amount, places=4)
        self.assertAlmostEqual(res.billing_grand_total, res.grand_total, places=4)

    def test_plus3_billing_mode_and_min11(self):
        """
        Input: 18x40 2Track Window, 34" x 35", Qty 1
        Actual Area = (34 * 35) / 144 = 8.263888... sqft
        +3 Inch Area:
        bw = ceil(34/3)*3 = 12*3 = 36"
        bh = ceil(35/3)*3 = 12*3 = 36"
        billing area per piece = (36 * 36) / 144 = 9.0 sqft
        With min_billing=True (11 sqft minimum):
        Since 9.0 < 11.0, billing area becomes 11.0 sqft
        """
        cart = [WindowItem(series="18x40", track="2Track", w=34.0, h=35.0, qty=1, jali=False)]
        res = calculate_project(
            cart=cart,
            allowed=[12, 15, 16],
            rates=self.rates,
            coat="Powder",
            w_type="Medium",
            profit=10.0,
            transport=500.0,
            extra=200.0,
            use_gst=True,
            billing_mode="plus3",
            min_billing=True
        )
        self.assertAlmostEqual(res.total_sqft, (34.0 * 35.0) / 144.0, places=4)
        self.assertAlmostEqual(res.billing_sqft, 11.0, places=4)
        self.assertTrue(res.min_applied)

        # Check billing factor scaling:
        billing_factor = 11.0 / res.total_sqft
        expected_billing_sub = res.sub_total * billing_factor
        expected_billing_gst = expected_billing_sub * 0.18
        expected_billing_grand = expected_billing_sub + expected_billing_gst
        self.assertAlmostEqual(res.billing_sub_total, expected_billing_sub, places=4)
        self.assertAlmostEqual(res.billing_gst, expected_billing_gst, places=4)
        self.assertAlmostEqual(res.billing_grand_total, expected_billing_grand, places=4)

    def test_scrap_deduction(self):
        """
        Input: 18x40 Handle cut of 46.5" needed.
        Scrap available: 18x40 Handle of 47.0"
        The scrap should be used, reducing the number of required new cuts.
        """
        cart = [WindowItem(series="18x40", track="2Track", w=48.0, h=48.0, qty=1)]
        scrap = [ScrapItem(series="18x40", part="Handle", length=47.0, qty=1)]
        res = calculate_project(
            cart=cart,
            allowed=[12, 15, 16],
            rates=self.rates,
            scrap=scrap
        )
        handle_packed = res.packed_data.get("18x40 Handle")
        self.assertIsNotNone(handle_packed)
        self.assertEqual(handle_packed.scrapUsed, 1)

if __name__ == "__main__":
    unittest.main()
