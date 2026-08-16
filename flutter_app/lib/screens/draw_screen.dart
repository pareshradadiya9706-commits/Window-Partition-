import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../state/app_state.dart';
import '../models/window_item.dart';
import '../theme/app_theme.dart';
import '../widgets/elevation_painter.dart';
import '../services/share_service.dart';

class DrawScreen extends StatefulWidget {
  final AppState appState;

  const DrawScreen({super.key, required this.appState});

  @override
  State<DrawScreen> createState() => _DrawScreenState();
}

class _DrawScreenState extends State<DrawScreen> {
  int _selectedIndex = 0;
  final GlobalKey _repaintBoundaryKey = GlobalKey();
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.appState.isDarkMode;
    final cart = widget.appState.cart;

    if (cart.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.architecture, size: 48, color: Color(0xFF64748B)),
              SizedBox(height: 12),
              Text(
                'No Windows or Partitions to Draw',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 6),
              Text(
                'Add items in the Order tab to generate elevation cross-sections and partition schematics.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    if (_selectedIndex >= cart.length) {
      _selectedIndex = 0;
    }

    final selectedItem = cart[_selectedIndex];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Action & Chip Selector Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'SELECT ELEVATION ITEM',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
              ElevatedButton.icon(
                onPressed: _isExporting ? null : () => _exportBlueprintImage(context, selectedItem, _selectedIndex),
                icon: _isExporting
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : const Icon(Icons.image_outlined, size: 16),
                label: Text(_isExporting ? 'Exporting...' : 'Export PNG', style: const TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentCyan,
                  foregroundColor: const Color(0xFF0F172A),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Item Selector Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(cart.length, (idx) {
                final item = cart[idx];
                final isSel = idx == _selectedIndex;
                String title = 'Win #${idx + 1}';
                if (item is PartitionItem) title = 'Part #${idx + 1}';
                else if (item is WindowItem && item.series == 'Repairing') title = 'Rep #${idx + 1}';

                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(title),
                    selected: isSel,
                    selectedColor: AppTheme.accentCyan,
                    labelStyle: TextStyle(
                      color: isSel ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                      fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    onSelected: (val) {
                      if (val) setState(() => _selectedIndex = idx);
                    },
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 16),

          // Blueprint Drawing Canvas Card wrapped in RepaintBoundary
          RepaintBoundary(
            key: _repaintBoundaryKey,
            child: Card(
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
                            Icon(Icons.architecture, size: 18, color: AppTheme.accentCyan),
                            SizedBox(width: 8),
                            Text(
                              'ELEVATION BLUEPRINT',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.accentCyan.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            selectedItem is WindowItem
                                ? '${selectedItem.series} - ${selectedItem.track}'
                                : 'Aluminum Partition',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.accentCyan),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Custom Blueprint Canvas
                    Container(
                      height: 280,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0B132B) : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                      ),
                      child: CustomPaint(
                        painter: ElevationPainter(item: selectedItem, isDark: isDark),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Technical Specs for Selected Item
          _buildItemSpecsCard(selectedItem, isDark),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _exportBlueprintImage(BuildContext context, dynamic item, int index) async {
    try {
      setState(() => _isExporting = true);
      await Future.delayed(const Duration(milliseconds: 60));

      final boundary = _repaintBoundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception('Render boundary unavailable');
      }

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('Failed to encode PNG bytes');
      }

      final Uint8List pngBytes = byteData.buffer.asUint8List();
      final width = image.width;
      final height = image.height;
      final sizeKb = (pngBytes.lengthInBytes / 1024).toStringAsFixed(1);

      String itemName = item is WindowItem
          ? 'Window_${item.series}_${item.w.toStringAsFixed(0)}x${item.h.toStringAsFixed(0)}'
          : 'Partition_${(item as PartitionItem).w.toStringAsFixed(0)}x${item.h.toStringAsFixed(0)}';

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.check_circle, color: AppTheme.accentEmerald, size: 22),
              SizedBox(width: 8),
              Text('PNG Image Exported', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'High-resolution elevation blueprint generated successfully offline.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• Filename: $itemName.png', style: const TextStyle(fontSize: 12, color: AppTheme.accentCyan, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('• Resolution: ${width}px × ${height}px (3x Crisp)', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                    Text('• File Size: $sizeKb KB', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                    Text('• Format: Lossless PNG (Offline)', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 180),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.memory(pngBytes, fit: BoxFit.contain),
                ),
              ),
            ],
          ),
          actions: [
            TextButton.icon(
              onPressed: () {
                Navigator.of(ctx).pop();
                final StringBuffer sb = StringBuffer();
                sb.writeln('📐 *ARCHITECTURAL ELEVATION SPECIFICATIONS*');
                if (item is WindowItem) {
                  sb.writeln('• Type: Window (${item.series} ${item.track})');
                  sb.writeln('• Size: ${item.w}" Width × ${item.h}" Height');
                  sb.writeln('• Quantity: ${item.qty} units');
                  sb.writeln('• Total Area: ${item.sqft.toStringAsFixed(1)} SqFt');
                  sb.writeln('• Mosquito Mesh: ${item.jali ? "Yes" : "No"}');
                } else if (item is PartitionItem) {
                  sb.writeln('• Type: Aluminum Partition');
                  sb.writeln('• Outer Size: ${item.w}" Width × ${item.h}" Height');
                  sb.writeln('• Door Size: ${item.dw}" Width × ${item.dh}" Height');
                  sb.writeln('• Quantity: ${item.qty} units');
                  sb.writeln('• Total Area: ${item.sqft.toStringAsFixed(1)} SqFt');
                }
                sb.writeln('• Finish: ${widget.appState.coating} (${widget.appState.weightType})');
                sb.writeln('────────────────────────');
                ShareService.showShareDialog(
                  context: context,
                  title: 'Share Blueprint Specs',
                  subtitle: 'Item specifications for fabrication chat',
                  shareText: sb.toString(),
                );
              },
              icon: const Icon(Icons.share, size: 14),
              label: const Text('Share Specs on WhatsApp'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export blueprint image: $e'),
            backgroundColor: AppTheme.accentRose,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Widget _buildItemSpecsCard(dynamic item, bool isDark) {
    if (item is WindowItem) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'WINDOW SPECIFICATIONS',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
              const SizedBox(height: 10),
              _buildSpecRow('Series Profile', item.series),
              _buildSpecRow('Track Type', item.track),
              _buildSpecRow('Outer Dimensions', '${item.w}" Width × ${item.h}" Height'),
              _buildSpecRow('Quantity', '${item.qty} units'),
              _buildSpecRow('Total Actual Area', '${item.sqft.toStringAsFixed(2)} SqFt'),
              _buildSpecRow('Mosquito Mesh (Jali)', item.jali ? 'Yes (Included)' : 'No'),
            ],
          ),
        ),
      );
    } else if (item is PartitionItem) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'PARTITION SPECIFICATIONS',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
              const SizedBox(height: 10),
              _buildSpecRow('Partition Dimensions', '${item.w}" Width × ${item.h}" Height'),
              _buildSpecRow('Door Opening Size', '${item.dw}" Width × ${item.dh}" Height'),
              _buildSpecRow('Kick-Plate Height', '${item.bh}" Bottom'),
              _buildSpecRow('Top Transom Material', item.topMat == 'glass' ? 'Clear Glass' : 'ACP Sheet'),
              _buildSpecRow('Middle Panes Design', item.midDes.toUpperCase()),
              _buildSpecRow('Pane Width Range', item.paneWSize),
              _buildSpecRow('Total Actual Area', '${item.sqft.toStringAsFixed(2)} SqFt'),
            ],
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildSpecRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
        ],
      ),
    );
  }
}
