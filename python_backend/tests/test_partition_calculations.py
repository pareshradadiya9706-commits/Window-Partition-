"""
Unit tests for Partition calculations (Column solver, DP pipe cuts, Door pipe, Clips, Sheet pieces).
Verifies exact 1-to-1 parity with verified JavaScript source logic.
"""
import unittest
from python_backend.models.window import PartitionItem
from python_backend.models.project import DEFAULT_RATES
from python_backend.calculations.partition_calculations import calculate_partition_cuts

class TestPartitionCalculations(unittest.TestCase):
    def setUp(self):
        self.rates = dict(DEFAULT_RATES)

    def test_partition_standard_12x10(self):
        """
        Input: Partition 144" x 120", Door 36" x 84", Bottom Height 36", Pane Range "36-42"
        Calculations from source:
        - minPaneW=36, maxPaneW=42, pt=1.5
        - For c=1..20:
          c=1: (144 - 36 - 3*1.5)/1 = (108 - 4.5) = 103.5 (too big)
          c=2: (144 - 36 - 4*1.5)/2 = (108 - 6)/2 = 51.0 (too big)
          c=3: (144 - 36 - 5*1.5)/3 = (108 - 7.5)/3 = 100.5/3 = 33.5 (too small < 36)
          fallback: cols = max(1, ceil((144 - 36 - 6)/42)) = ceil(102/42) = 3
          paneW = (144 - 36 - 5*1.5)/3 = 33.5
        - topH = (120 - 84) - 2*1.5 = 36 - 3 = 33.0
        - glassH = (84 - 36 - 2*1.5) = 48 - 3 = 45.0
        """
        item = PartitionItem(
            series="Partition",
            w=144.0,
            h=120.0,
            qty=1,
            dw=36.0,
            dh=84.0,
            topMat="sheet",
            midDes="standard",
            bh=36.0,
            paneWSize="36-42"
        )
        master = {}
        last_partitions = []
        global_pieces = []

        pane_w, top_h, g_sqft, hw_cost, labor_cost = calculate_partition_cuts(
            item=item,
            index=0,
            rates=self.rates,
            master=master,
            last_partitions=last_partitions,
            global_pieces=global_pieces
        )

        self.assertAlmostEqual(pane_w, 33.5, places=4)
        self.assertAlmostEqual(top_h, 33.0, places=4)
        self.assertEqual(len(last_partitions), 1)
        self.assertEqual(last_partitions[0].cols, 3)
        self.assertAlmostEqual(last_partitions[0].glassH, 45.0, places=4)

        # Check DP Pipe cuts
        # add_c("Partition DP Pipe", h=120, 2)
        # add_c("Partition DP Pipe", w-3=141, 1)
        # add_c("Partition DP Pipe", h-1.5=118.5, 1)
        # add_c("Partition DP Pipe", w-dw-4.5=103.5, 1)
        # if cols>1 (cols=3): add_c("Partition DP Pipe", h-3=117, (3-1)*1=2)
        # if dw>0: add_c("Partition DP Pipe", dw=36, 1)
        # standard: add_c("Partition DP Pipe", paneW=33.5, cols*2=6)
        dp_cuts = master["Partition DP Pipe"]
        dp_lens = [c["len"] for c in dp_cuts]
        self.assertEqual(dp_lens.count(120.0), 2)
        self.assertEqual(dp_lens.count(141.0), 1)
        self.assertEqual(dp_lens.count(118.5), 1)
        self.assertEqual(dp_lens.count(103.5), 1)
        self.assertEqual(dp_lens.count(117.0), 2)
        self.assertEqual(dp_lens.count(36.0), 1)
        self.assertEqual(dp_lens.count(33.5), 6)

        # Check Door Pipe cuts: 2x84, 3x36
        door_cuts = master["Partition Door Pipe"]
        door_lens = [c["len"] for c in door_cuts]
        self.assertEqual(door_lens.count(84.0), 2)
        self.assertEqual(door_lens.count(36.0), 3)

        # Hardware cost = 850 * 1 = 850
        self.assertAlmostEqual(hw_cost, 850.0, places=4)

if __name__ == "__main__":
    unittest.main()
