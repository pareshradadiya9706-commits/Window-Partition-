import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../models/calculation_result.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_dropdown.dart';

class ScrapScreen extends StatefulWidget {
  final AppState appState;

  const ScrapScreen({super.key, required this.appState});

  @override
  State<ScrapScreen> createState() => _ScrapScreenState();
}

class _ScrapScreenState extends State<ScrapScreen> {
  String _selectedSection = '18x40 Top/Bottom';
  final _lengthCtrl = TextEditingController(text: '48');
  final _qtyCtrl = TextEditingController(text: '1');

  final List<String> _sectionOptions = [
    '18x40 Top/Bottom',
    '18x40 Handle/Interlock',
    '18x40 Top/Bottom Track',
    '18x40 Side Track',
    '60mm Outer Frame',
    '60mm Shutter Profile',
    'Domal Track',
    'Domal Shutter',
    'Partition Outer DP',
    'Partition Door Vertical',
    'Partition Snap Clip',
    'General Tube / Pipe',
  ];

  @override
  void dispose() {
    _lengthCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  void _addScrapItem() {
    final len = double.tryParse(_lengthCtrl.text) ?? 0.0;
    final qty = int.tryParse(_qtyCtrl.text) ?? 1;

    if (len <= 0) return;

    for (int i = 0; i < qty; i++) {
      widget.appState.addScrapItem(
        ScrapItem(
          id: '${DateTime.now().millisecondsSinceEpoch}_$i',
          section: _selectedSection,
          length: len,
        ),
      );
    }

    _lengthCtrl.text = '48';
    _qtyCtrl.text = '1';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added $qty scrap off-cut piece(s) to inventory!'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.appState.isDarkMode;
    final scrapItems = widget.appState.scrapItems;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Scrap Entry Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.recycling, size: 18, color: AppTheme.accentEmerald),
                      SizedBox(width: 8),
                      Text(
                        'ADD WORKSHOP SCRAP / OFF-CUT',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  CustomDropdown<String>(
                    label: 'Section / Extrusion Profile',
                    value: _selectedSection,
                    items: _sectionOptions
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedSection = v);
                    },
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: CustomTextField(
                          label: 'Off-Cut Length (Inches)',
                          controller: _lengthCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          suffixText: 'inch',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 1,
                        child: CustomTextField(
                          label: 'Qty',
                          controller: _qtyCtrl,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _addScrapItem,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('SAVE TO SCRAP INVENTORY'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentEmerald,
                            foregroundColor: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Scrap Inventory Table Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.inventory, size: 18, color: AppTheme.accentCyan),
                          const SizedBox(width: 8),
                          Text(
                            'SCRAP INVENTORY (${scrapItems.length} PIECES)',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      if (scrapItems.isNotEmpty)
                        TextButton.icon(
                          onPressed: () {
                            for (var s in List.from(scrapItems)) {
                              widget.appState.removeScrapItem(s.id);
                            }
                          },
                          icon: const Icon(Icons.delete_outline, size: 16, color: AppTheme.accentRose),
                          label: const Text('Clear All', style: TextStyle(color: AppTheme.accentRose, fontSize: 12)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'The 1D cutting optimizer prioritizes these off-cuts before consuming fresh 12ft, 15ft, or 16ft raw pipes.',
                    style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 12),

                  if (scrapItems.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      alignment: Alignment.center,
                      child: Column(
                        children: const [
                          Icon(Icons.inventory_2_outlined, size: 36, color: Color(0xFF64748B)),
                          SizedBox(height: 8),
                          Text(
                            'No scrap pieces registered. Add leftover pipes above.',
                            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: scrapItems.length,
                      separatorBuilder: (_, __) => const Divider(height: 12, color: Color(0xFF334155)),
                      itemBuilder: (context, index) {
                        final item = scrapItems[index];
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppTheme.accentEmerald.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.content_cut, color: AppTheme.accentEmerald, size: 16),
                          ),
                          title: Text(item.section, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            'Length: ${item.length.toStringAsFixed(1)}" (${(item.length / 12).toStringAsFixed(2)} ft)',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppTheme.accentRose, size: 18),
                            onPressed: () => widget.appState.removeScrapItem(item.id),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
