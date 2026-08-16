import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/app_state.dart';
import '../models/window_item.dart';
import '../theme/app_theme.dart';

class ShareService {
  /// Builds a formatted text quotation ready for WhatsApp sharing
  static String buildQuotationText(AppState appState) {
    final res = appState.result;
    final displayGrandTotal = appState.billingMode == 'actual' && !appState.minBilling
        ? res.grandTotal
        : res.billingGrandTotal;

    final customer = appState.customerName.isNotEmpty ? appState.customerName : 'Valued Customer';
    final project = appState.projectName.isNotEmpty ? appState.projectName : 'Architectural Fabrication';
    final phone = appState.phone.isNotEmpty ? appState.phone : '';

    final StringBuffer sb = StringBuffer();
    sb.writeln('📋 *WINDOW SECTION PRO — ESTIMATE*');
    sb.writeln('👤 *Customer:* $customer');
    if (phone.isNotEmpty) sb.writeln('📞 *Contact:* $phone');
    sb.writeln('🏗️ *Project:* $project');
    sb.writeln('🎨 *Coating:* ${appState.coating} (${appState.weightType})');
    sb.writeln('────────────────────────');
    sb.writeln('*ITEM SCHEDULE:*');

    for (int i = 0; i < appState.cart.length; i++) {
      final item = appState.cart[i];
      if (item is WindowItem) {
        if (item.series == 'Repairing') {
          sb.writeln('${i + 1}. 🔧 Repair: ${item.desc} (Qty: ${item.qty})');
        } else {
          sb.writeln('${i + 1}. 🪟 ${item.series} ${item.track} — ${item.w}" × ${item.h}" | Qty: ${item.qty} | ${item.sqft.toStringAsFixed(1)} sqft${item.jali ? " (+Jali)" : ""}');
        }
      } else if (item is PartitionItem) {
        sb.writeln('${i + 1}. 🚪 Partition — ${item.w}" × ${item.h}" | Door: ${item.dw}" × ${item.dh}" | Qty: ${item.qty} | ${item.sqft.toStringAsFixed(1)} sqft');
      }
    }

    if (appState.extraItems.isNotEmpty) {
      sb.writeln('\n*ADDITIONAL HARDWARE / EXTRAS:*');
      for (var ex in appState.extraItems) {
        sb.writeln('• ${ex.name}: ₹${ex.total.toStringAsFixed(0)}');
      }
    }

    sb.writeln('────────────────────────');
    sb.writeln('📐 *Total Area:* ${res.totalSqft.toStringAsFixed(1)} Sq.Ft');
    sb.writeln('📊 *Billing Area:* ${res.billingSqft.toStringAsFixed(1)} Sq.Ft (${appState.billingMode == "three_inch" ? "+3 Inch Rule" : "Actual"})');
    if (appState.useGst) {
      sb.writeln('💰 *Sub Total:* ₹${res.subTotal.toStringAsFixed(0)}');
      sb.writeln('🏛️ *GST (18%):* ₹${res.gstAmount.toStringAsFixed(0)}');
    }
    sb.writeln('🏷️ *ESTIMATED TOTAL: ₹${displayGrandTotal.toStringAsFixed(0)}*');
    sb.writeln('────────────────────────');
    sb.writeln('Generated via Window Section Pro (Offline Engine)');
    sb.writeln('Thank you for your business! 🙏');

    return sb.toString();
  }

  /// Builds a formatted bill & cost summary text ready for WhatsApp sharing
  static String buildBillSummaryText(AppState appState) {
    final res = appState.result;
    final customer = appState.customerName.isNotEmpty ? appState.customerName : 'Client';
    final displayGrandTotal = appState.billingMode == 'actual' && !appState.minBilling
        ? res.grandTotal
        : res.billingGrandTotal;

    final StringBuffer sb = StringBuffer();
    sb.writeln('🧾 *FABRICATION COST & BILL SUMMARY*');
    sb.writeln('👤 *Client:* $customer');
    sb.writeln('🎨 *Finish:* ${appState.coating} (${appState.weightType})');
    sb.writeln('────────────────────────');
    sb.writeln('• Aluminum Material: ₹${res.totalAluCost.toStringAsFixed(0)}');
    sb.writeln('• Glass Material: ₹${res.totalGlassCost.toStringAsFixed(0)}');
    sb.writeln('• Labor Charges: ₹${res.totalLaborCost.toStringAsFixed(0)}');
    sb.writeln('• Hardware & Rollers: ₹${res.totalHardwareCost.toStringAsFixed(0)}');
    if (res.totalCoatCost > 0) {
      sb.writeln('• Powder/Anodize Coating: ₹${res.totalCoatCost.toStringAsFixed(0)}');
    }
    sb.writeln('────────────────────────');
    sb.writeln('• Base Fabrication: ₹${res.baseCost.toStringAsFixed(0)}');
    sb.writeln('• Profit Margin (${appState.profit.toStringAsFixed(0)}%): ₹${res.profitAmt.toStringAsFixed(0)}');
    if (appState.transport > 0) sb.writeln('• Transport: ₹${appState.transport.toStringAsFixed(0)}');
    if (appState.useGst) sb.writeln('• GST Tax: ₹${res.gstAmount.toStringAsFixed(0)}');
    sb.writeln('🏷️ *GRAND TOTAL: ₹${displayGrandTotal.toStringAsFixed(0)}*');
    sb.writeln('────────────────────────');

    return sb.toString();
  }

  /// Displays the interactive WhatsApp / Android Share modal
  static void showShareDialog({
    required BuildContext context,
    required String title,
    required String shareText,
    String? subtitle,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.share, color: AppTheme.accentEmerald, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        title,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF94A3B8), size: 20),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                ),
              ],
              const SizedBox(height: 16),

              // Preview Box
              Container(
                constraints: const BoxConstraints(maxHeight: 140),
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    shareText,
                    style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Color(0xFFCBD5E1)),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Share Actions
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: shareText));
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Copied formatted text for WhatsApp! Ready to paste into chat.'),
                            backgroundColor: AppTheme.accentEmerald,
                            duration: Duration(seconds: 3),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Copy for WhatsApp', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentEmerald,
                        foregroundColor: const Color(0xFF0F172A),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}
