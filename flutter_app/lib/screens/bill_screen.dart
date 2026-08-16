import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_dropdown.dart';
import '../services/share_service.dart';
import '../services/pdf_service.dart';

class BillScreen extends StatelessWidget {
  final AppState appState;

  const BillScreen({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    final isDark = appState.isDarkMode;
    final res = appState.result;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Commercial Controls Card
          _buildCommercialControlsCard(context, isDark),
          const SizedBox(height: 16),

          // Billing Comparison Card (+3 Inch & Min 11 Rule)
          _buildBillingComparisonCard(context, isDark),
          const SizedBox(height: 16),

          // Cost Breakdown Table Card
          _buildCostBreakdownCard(context, isDark),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCommercialControlsCard(BuildContext context, bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.tune, size: 18, color: AppTheme.accentCyan),
                SizedBox(width: 8),
                Text(
                  'COMMERCIAL & BILLING OPTIONS',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: CustomDropdown<String>(
                    label: 'Coating / Finish',
                    value: appState.coating,
                    items: const [
                      DropdownMenuItem(value: 'Powder', child: Text('Powder Coating')),
                      DropdownMenuItem(value: 'Anodize', child: Text('Anodized Finish')),
                      DropdownMenuItem(value: 'Wooden', child: Text('Wooden Finish')),
                      DropdownMenuItem(value: 'Mill Finish', child: Text('Mill Finish (Raw)')),
                    ],
                    onChanged: (v) => appState.updateOptions(coating: v),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: CustomDropdown<String>(
                    label: 'Weight Profile',
                    value: appState.weightType,
                    items: const [
                      DropdownMenuItem(value: 'Light', child: Text('Light Weight')),
                      DropdownMenuItem(value: 'Medium', child: Text('Medium Standard')),
                      DropdownMenuItem(value: 'Heavy', child: Text('Heavy Gauge')),
                    ],
                    onChanged: (v) => appState.updateOptions(weightType: v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    label: 'Profit Margin (%)',
                    initialValue: appState.profit.toStringAsFixed(0),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    suffixText: '%',
                    onChanged: (v) => appState.updateOptions(profit: double.tryParse(v) ?? 0.0),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: CustomTextField(
                    label: 'Transport (₹)',
                    initialValue: appState.transport.toStringAsFixed(0),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    suffixText: '₹',
                    onChanged: (v) => appState.updateOptions(transport: double.tryParse(v) ?? 0.0),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: CustomTextField(
                    label: 'Extra Exp (₹)',
                    initialValue: appState.extra.toStringAsFixed(0),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    suffixText: '₹',
                    onChanged: (v) => appState.updateOptions(extra: double.tryParse(v) ?? 0.0),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: CustomDropdown<String>(
                    label: 'Billing SqFt Mode',
                    value: appState.billingMode,
                    items: const [
                      DropdownMenuItem(value: 'actual', child: Text('Actual Area (Direct)')),
                      DropdownMenuItem(value: 'plus3', child: Text('+3 Inch Rounding Rule')),
                    ],
                    onChanged: (v) => appState.updateOptions(billingMode: v),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 18.0),
                    child: CheckboxListTile(
                      title: const Text('Apply GST 18%', style: TextStyle(fontSize: 13)),
                      value: appState.useGst,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      activeColor: AppTheme.accentCyan,
                      onChanged: (v) => appState.updateOptions(useGst: v == true),
                    ),
                  ),
                ),
              ],
            ),
            CheckboxListTile(
              title: const Text('Minimum 11 SqFt / piece rule', style: TextStyle(fontSize: 13)),
              subtitle: const Text('Small windows are billed at minimum 11 sqft', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
              value: appState.minBilling,
              contentPadding: EdgeInsets.zero,
              dense: true,
              activeColor: AppTheme.accentAmber,
              onChanged: (v) => appState.updateOptions(minBilling: v == true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillingComparisonCard(BuildContext context, bool isDark) {
    final res = appState.result;

    return Card(
      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: res.minApplied ? AppTheme.accentAmber : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
          width: res.minApplied ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(Icons.compare_arrows, size: 18, color: AppTheme.accentAmber),
                    SizedBox(width: 8),
                    Text(
                      'BILLING COMPARISON',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                if (res.minApplied)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.accentAmber.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.accentAmber),
                    ),
                    child: const Text(
                      'MIN 11 SQFT APPLIED',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.accentAmber),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    'Actual Total Area',
                    '${res.totalSqft.toStringAsFixed(2)} SqFt',
                    Colors.white70,
                    isDark,
                  ),
                ),
                Expanded(
                  child: _buildMetricTile(
                    'Billing Total Area',
                    '${res.billingSqft.toStringAsFixed(2)} SqFt',
                    AppTheme.accentAmber,
                    isDark,
                  ),
                ),
              ],
            ),
            const Divider(height: 16, color: Color(0xFF334155)),
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    'Quotation Grand Total',
                    '₹${(appState.billingMode == 'actual' && !appState.minBilling ? res.grandTotal : res.billingGrandTotal).toStringAsFixed(2)}',
                    AppTheme.accentCyan,
                    isDark,
                    isLarge: true,
                  ),
                ),
                Expanded(
                  child: _buildMetricTile(
                    'Rate per Billing SqFt',
                    res.billingSqft > 0
                        ? '₹${((appState.billingMode == 'actual' && !appState.minBilling ? res.grandTotal : res.billingGrandTotal) / res.billingSqft).toStringAsFixed(1)}/sqft'
                        : '₹0.0/sqft',
                    AppTheme.accentEmerald,
                    isDark,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, Color valueColor, bool isDark, {bool isLarge = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: isLarge ? 17 : 14,
            fontWeight: FontWeight.w900,
            color: isDark ? valueColor : AppTheme.primaryBlue,
          ),
        ),
      ],
    );
  }

  Widget _buildCostBreakdownCard(BuildContext context, bool isDark) {
    final res = appState.result;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.receipt_long, size: 18, color: AppTheme.accentCyan),
                SizedBox(width: 8),
                Text(
                  'DETAILED COST BREAKDOWN',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            _buildCostRow('Aluminum Profiles & Pipes', '₹${res.totalAluCost.toStringAsFixed(2)}', '${res.totalWeight.toStringAsFixed(1)} kg'),
            _buildCostRow('Glass Material (${res.totalGlassSqft.toStringAsFixed(1)} sqft)', '₹${res.totalGlassCost.toStringAsFixed(2)}', ''),
            _buildCostRow('Coating & Anodizing Finish', '₹${res.totalCoatCost.toStringAsFixed(2)}', appState.coating),
            _buildCostRow('Fabrication Labor Charges', '₹${res.totalLaborCost.toStringAsFixed(2)}', ''),
            _buildCostRow('Hardware, Rollers & Locks', '₹${res.totalHardwareCost.toStringAsFixed(2)}', ''),
            if (res.totalJaliCost > 0)
              _buildCostRow('Mosquito Net Mesh (Jali)', '₹${res.totalJaliCost.toStringAsFixed(2)}', ''),
            if (res.totalLouverCost > 0)
              _buildCostRow('Louver Mechanism & Blades', '₹${res.totalLouverCost.toStringAsFixed(2)}', ''),
            if (res.totalPartSheetCost > 0)
              _buildCostRow('Partition ACP Sheets', '₹${res.totalPartSheetCost.toStringAsFixed(2)}', ''),
            if (res.totalExtraCost > 0)
              _buildCostRow('Extra Accessories & Charges', '₹${res.totalExtraCost.toStringAsFixed(2)}', ''),

            const Divider(height: 20, color: Color(0xFF475569)),

            _buildCostRow('Base Factory Cost', '₹${res.baseCost.toStringAsFixed(2)}', '', isBold: true),
            _buildCostRow('Profit Margin (${appState.profit.toStringAsFixed(0)}%)', '₹${res.profitAmt.toStringAsFixed(2)}', ''),
            if (appState.transport > 0)
              _buildCostRow('Transport & Cartage', '₹${appState.transport.toStringAsFixed(2)}', ''),
            if (appState.extra > 0)
              _buildCostRow('Additional Extra Expenses', '₹${appState.extra.toStringAsFixed(2)}', ''),

            const Divider(height: 16, color: Color(0xFF334155)),

            _buildCostRow('Sub Total', '₹${res.subTotal.toStringAsFixed(2)}', '', isBold: true),
            if (appState.useGst)
              _buildCostRow('GST (18%)', '₹${res.gstAmount.toStringAsFixed(2)}', ''),

            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.accentCyan.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.accentCyan.withOpacity(0.4)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'GRAND TOTAL',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppTheme.accentCyan),
                  ),
                  Text(
                    '₹${res.grandTotal.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppTheme.accentCyan),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final pdfBytes = PdfService.generateBillPdf(appState);
                      final customer = appState.customerName.isNotEmpty ? appState.customerName.replaceAll(RegExp(r'\s+'), '_') : 'Client';
                      final fileName = 'Bill_${customer}_${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

                      PdfService.showPdfExportModal(
                        context: context,
                        title: 'Fabrication Bill PDF',
                        fileName: fileName,
                        pdfBytes: pdfBytes,
                        description: 'Detailed material cost breakdown and invoice PDF generated offline with verified calculations.',
                      );
                    },
                    icon: const Icon(Icons.picture_as_pdf, size: 15),
                    label: const Text('Export PDF', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentRose,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final text = ShareService.buildBillSummaryText(appState);
                      ShareService.showShareDialog(
                        context: context,
                        title: 'Share Bill Summary',
                        subtitle: 'Cost breakdown ready for WhatsApp sharing',
                        shareText: text,
                      );
                    },
                    icon: const Icon(Icons.share, size: 15),
                    label: const Text('WhatsApp', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentEmerald,
                      foregroundColor: const Color(0xFF0F172A),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCostRow(String title, String amount, String detail, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                    color: isBold ? Colors.white : const Color(0xFFCBD5E1),
                  ),
                ),
                if (detail.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Text('($detail)', style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                ],
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: isBold ? Colors.white : const Color(0xFFF1F5F9),
            ),
          ),
        ],
      ),
    );
  }
}
