import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/app_state.dart';
import '../models/calculation_result.dart';
import '../theme/app_theme.dart';
import '../services/calculation_service.dart';
import '../services/pdf_service.dart';

class CuttingScreen extends StatelessWidget {
  final AppState appState;

  const CuttingScreen({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    final isDark = appState.isDarkMode;
    final res = appState.result;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Allowed Stock Pipes Selector Card
          _buildStockPipesCard(isDark),
          const SizedBox(height: 16),

          // Extrusion Profile Cutting Bins
          _buildExtrusionCuttingBins(context, isDark, res),
          const SizedBox(height: 16),

          // Glass Cutting Dimensions Table
          _buildGlassCuttingTable(context, isDark, res),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStockPipesCard(bool isDark) {
    return Card(
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
                    Icon(Icons.straighten, size: 18, color: AppTheme.accentCyan),
                    SizedBox(width: 8),
                    Text(
                      'STOCK PIPES & CUTTING',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    final pdfBytes = PdfService.generateCuttingListPdf(appState);
                    final customer = appState.customerName.isNotEmpty ? appState.customerName.replaceAll(RegExp(r'\s+'), '_') : 'Workshop';
                    final fileName = 'CuttingList_${customer}_${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

                    PdfService.showPdfExportModal(
                      context: context,
                      title: 'Profile Cutting List PDF',
                      fileName: fileName,
                      pdfBytes: pdfBytes,
                      description: 'Extrusion profile optimization arrangement and glass cutting dimensions PDF.',
                    );
                  },
                  icon: const Icon(Icons.picture_as_pdf, size: 15),
                  label: const Text('Export PDF', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentRose,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [12, 15, 16].map((ft) {
                final isSelected = appState.allowedPipes.contains(ft);
                return Padding(
                  padding: const EdgeInsets.only(right: 10.0),
                  child: FilterChip(
                    label: Text('$ft Feet (${ft * 12}")'),
                    selected: isSelected,
                    selectedColor: AppTheme.accentCyan,
                    labelStyle: TextStyle(
                      color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    onSelected: (_) => appState.togglePipeLength(ft),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExtrusionCuttingBins(BuildContext context, bool isDark, CalculationResult res) {
    final packedData = res.packedData;

    if (packedData.isEmpty) {
      return Card(
        child: Container(
          padding: const EdgeInsets.all(24),
          alignment: Alignment.center,
          child: Column(
            children: const [
              Icon(Icons.content_cut, size: 36, color: Color(0xFF64748B)),
              SizedBox(height: 8),
              Text(
                'No cutting lists generated. Add items to cart.',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.content_cut, size: 18, color: AppTheme.accentCyan),
                const SizedBox(width: 8),
                Text(
                  'EXTRUSION CUTTING LIST (${packedData.length} SECTIONS)',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            ElevatedButton.icon(
              onPressed: () {
                _copyWorkerText(context, res);
              },
              icon: const Icon(Icons.copy, size: 14),
              label: const Text('Worker WhatsApp', style: TextStyle(fontSize: 11)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                backgroundColor: AppTheme.accentEmerald,
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        ...packedData.entries.map((entry) {
          final sectionName = entry.key;
          final packed = entry.value;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        sectionName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accentCyan,
                        ),
                      ),
                      Row(
                        children: [
                          if (packed.scrapUsed > 0) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.accentEmerald.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${packed.scrapUsed} Scrap Used',
                                style: const TextStyle(fontSize: 10, color: AppTheme.accentEmerald, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            '${packed.pipes.length} Raw Pipes',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // List of Pipe Bins
                  ...List.generate(packed.pipes.length, (pIdx) {
                    final pipe = packed.pipes[pIdx];
                    final cutsFormatted = pipe.cuts
                        .map((c) => FlutterCalculationService.formatDora(c is Map ? c['len'] : c))
                        .join('  +  ');

                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.accentCyan.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'P${pIdx + 1} (${pipe.sizeFt}ft)',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.accentCyan,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              cutsFormatted,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                          Text(
                            'Rem: ${pipe.waste.toStringAsFixed(1)}"',
                            style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildGlassCuttingTable(BuildContext context, bool isDark, CalculationResult res) {
    final glassList = res.glassDetails;
    if (glassList.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.grid_on, size: 18, color: AppTheme.accentCyan),
                const SizedBox(width: 8),
                Text(
                  'GLASS CUTTING DETAILS (${res.totalGlassSqft.toStringAsFixed(1)} SqFt)',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Table(
              columnWidths: const {
                0: FlexColumnWidth(1),
                1: FlexColumnWidth(3),
                2: FlexColumnWidth(1.5),
                3: FlexColumnWidth(2),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                  children: const [
                    Padding(padding: EdgeInsets.all(6.0), child: Text('#', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                    Padding(padding: EdgeInsets.all(6.0), child: Text('Size (W × H)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                    Padding(padding: EdgeInsets.all(6.0), child: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                    Padding(padding: EdgeInsets.all(6.0), child: Text('Area (SqFt)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                  ],
                ),
                ...glassList.map((g) {
                  final gwStr = FlutterCalculationService.formatDora(g.w);
                  final ghStr = FlutterCalculationService.formatDora(g.h);

                  return TableRow(
                    children: [
                      Padding(padding: const EdgeInsets.all(6.0), child: Text('${g.no}', style: const TextStyle(fontSize: 11))),
                      Padding(padding: const EdgeInsets.all(6.0), child: Text('$gwStr × $ghStr', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      Padding(padding: const EdgeInsets.all(6.0), child: Text('${g.qty}', style: const TextStyle(fontSize: 11))),
                      Padding(padding: const EdgeInsets.all(6.0), child: Text(g.sqft.toStringAsFixed(2), style: const TextStyle(fontSize: 11, color: AppTheme.accentCyan))),
                    ],
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _copyWorkerText(BuildContext context, CalculationResult res) {
    final customer = appState.customerName.isNotEmpty ? appState.customerName : 'Customer';
    final StringBuffer sb = StringBuffer();
    sb.writeln('*DW Worker Cut*');
    sb.writeln('Customer: $customer\n');

    res.packedData.forEach((sec, packed) {
      sb.writeln('*$sec* - ${packed.pipes.length} pipes');
      for (int i = 0; i < packed.pipes.length; i++) {
        final b = packed.pipes[i];
        final cutsStr = b.cuts
            .map((c) => FlutterCalculationService.formatDora(c is Map ? c['len'] : c))
            .join(' + ');
        sb.writeln('Pipe ${i + 1} (${b.sizeFt}Ft): $cutsStr');
      }
      sb.writeln();
    });

    Clipboard.setData(ClipboardData(text: sb.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Worker Cutting List copied to clipboard!'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
