import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../models/window_item.dart';
import '../theme/app_theme.dart';
import '../services/share_service.dart';
import '../services/pdf_service.dart';

class QuotationScreen extends StatelessWidget {
  final AppState appState;

  const QuotationScreen({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    final isDark = appState.isDarkMode;
    final res = appState.result;
    final cart = appState.cart;
    final extras = appState.extraItems;

    final displayGrandTotal = appState.billingMode == 'actual' && !appState.minBilling
        ? res.grandTotal
        : res.billingGrandTotal;

    final now = DateTime.now();
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dateStr = '${now.day} ${months[now.month - 1]} ${now.year}';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Action Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'OFFICIAL QUOTATION',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _exportQuotationPdf(context),
                    icon: const Icon(Icons.picture_as_pdf, size: 15),
                    label: const Text('Export PDF', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentRose,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _copyWhatsAppQuotation(context),
                    icon: const Icon(Icons.share, size: 15),
                    label: const Text('WhatsApp', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentEmerald,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Quotation Document Card
          Card(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Workshop / Business Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.grid_view_rounded, color: AppTheme.accentCyan, size: 22),
                              SizedBox(width: 6),
                              Text(
                                'DW ULTIMATE PRO',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 0.8),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Architectural Aluminum & Glass Fabricators',
                            style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.accentCyan.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.accentCyan.withOpacity(0.4)),
                        ),
                        child: const Text(
                          'ESTIMATE / QUOTATION',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.accentCyan),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24, color: Color(0xFF334155)),

                  // Customer & Project Info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('CUSTOMER DETAILS', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text(
                            appState.customerName.isNotEmpty ? appState.customerName : 'Walk-in Client',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          if (appState.phone.isNotEmpty)
                            Text('Ph: ${appState.phone}', style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('PROJECT / DATE', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text(
                            appState.projectName.isNotEmpty ? appState.projectName : 'General Project',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          Text('Date: $dateStr', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Coating & Profile specs
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text('Coating: ${appState.coating}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                        Text('Weight: ${appState.weightType}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                        Text('Billing: ${appState.billingMode == "actual" ? "Actual SqFt" : "+3 Inch Rule"}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Itemized Schedule
                  const Text('ITEMIZED WINDOW & FABRICATION SCHEDULE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.accentCyan)),
                  const SizedBox(height: 8),

                  if (cart.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: Text('No items in cart.', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)))),
                    )
                  else
                    Table(
                      columnWidths: const {
                        0: FlexColumnWidth(1),
                        1: FlexColumnWidth(4),
                        2: FlexColumnWidth(1.2),
                        3: FlexColumnWidth(2),
                      },
                      children: [
                        TableRow(
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          ),
                          children: const [
                            Padding(padding: EdgeInsets.all(6.0), child: Text('#', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                            Padding(padding: EdgeInsets.all(6.0), child: Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                            Padding(padding: EdgeInsets.all(6.0), child: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                            Padding(padding: EdgeInsets.all(6.0), child: Text('Area (SqFt)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                          ],
                        ),
                        ...List.generate(cart.length, (idx) {
                          final item = cart[idx];
                          String desc = '';
                          String qtyStr = '';
                          String areaStr = '';

                          if (item is WindowItem) {
                            if (item.series == 'Repairing') {
                              desc = 'Repairing: ${item.desc}';
                              qtyStr = '${item.qty}';
                              areaStr = '-';
                            } else {
                              desc = '${item.series} ${item.track} (${item.w}" × ${item.h}")${item.jali ? " +Jali" : ""}';
                              qtyStr = '${item.qty}';
                              areaStr = item.sqft.toStringAsFixed(2);
                            }
                          } else if (item is PartitionItem) {
                            desc = 'Partition (${item.w}" × ${item.h}") Door: ${item.dw}"×${item.dh}"';
                            qtyStr = '${item.qty}';
                            areaStr = item.sqft.toStringAsFixed(2);
                          }

                          return TableRow(
                            children: [
                              Padding(padding: const EdgeInsets.all(6.0), child: Text('${idx + 1}', style: const TextStyle(fontSize: 11))),
                              Padding(padding: const EdgeInsets.all(6.0), child: Text(desc, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500))),
                              Padding(padding: const EdgeInsets.all(6.0), child: Text(qtyStr, style: const TextStyle(fontSize: 11))),
                              Padding(padding: const EdgeInsets.all(6.0), child: Text(areaStr, style: const TextStyle(fontSize: 11, color: AppTheme.accentCyan, fontWeight: FontWeight.bold))),
                            ],
                          );
                        }),
                      ],
                    ),
                  const SizedBox(height: 12),

                  // Extras table if any
                  if (extras.isNotEmpty) ...[
                    const Text('EXTRA ACCESSORIES / CHARGES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.accentAmber)),
                    const SizedBox(height: 6),
                    ...extras.map((ex) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('• ${ex.name} (₹${ex.rate} × ${ex.qty})', style: const TextStyle(fontSize: 11, color: Color(0xFFCBD5E1))),
                          Text('₹${ex.total.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )),
                    const SizedBox(height: 10),
                  ],

                  const Divider(height: 20, color: Color(0xFF334155)),

                  // Summary Totals
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Actual Area:', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                      Text('${res.totalSqft.toStringAsFixed(2)} SqFt', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Billing Area:', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                      Text('${res.billingSqft.toStringAsFixed(2)} SqFt', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.accentAmber)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Sub Total:', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                      Text('₹${res.subTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  if (appState.useGst) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('GST (18%):', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                        Text('₹${res.gstAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),

                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.accentCyan.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.accentCyan.withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('GRAND TOTAL:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppTheme.accentCyan)),
                        Text('₹${displayGrandTotal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.accentCyan)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Terms and conditions
                  const Text('Terms & Conditions:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
                  const SizedBox(height: 2),
                  const Text('1. 50% advance along with confirmed work order.', style: TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
                  const Text('2. Site civil preparation to be ready before installation.', style: TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
                  const Text('3. Quotation valid for 15 days from issue date.', style: TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _copyWhatsAppQuotation(BuildContext context) {
    final text = ShareService.buildQuotationText(appState);
    ShareService.showShareDialog(
      context: context,
      title: 'Share Quotation',
      subtitle: 'Formatted for instant WhatsApp client chats',
      shareText: text,
    );
  }

  void _exportQuotationPdf(BuildContext context) {
    final pdfBytes = PdfService.generateQuotationPdf(appState);
    final customer = appState.customerName.isNotEmpty ? appState.customerName.replaceAll(RegExp(r'\s+'), '_') : 'Customer';
    final fileName = 'Quotation_${customer}_${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    PdfService.showPdfExportModal(
      context: context,
      title: 'Official Quotation PDF',
      fileName: fileName,
      pdfBytes: pdfBytes,
      description: 'Professional Quotation A4 vector PDF generated completely offline with verified pricing.',
    );
  }
}
