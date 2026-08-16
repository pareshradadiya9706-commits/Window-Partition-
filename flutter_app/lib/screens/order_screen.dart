import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../models/window_item.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_dropdown.dart';

class OrderScreen extends StatefulWidget {
  final AppState appState;

  const OrderScreen({super.key, required this.appState});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  // Form Controllers & State
  String _selectedSeries = '18x40';
  String _selectedTrack = '2Track';
  final _widthCtrl = TextEditingController(text: '48');
  final _heightCtrl = TextEditingController(text: '48');
  final _qtyCtrl = TextEditingController(text: '1');
  bool _hasJali = false;

  // Partition specific
  final _doorWidthCtrl = TextEditingController(text: '36');
  final _doorHeightCtrl = TextEditingController(text: '84');
  final _bottomHeightCtrl = TextEditingController(text: '36');
  String _topMat = 'sheet';
  String _midDes = 'standard';
  String _paneWSize = '36-42';

  // Repairing specific
  final _repairDescCtrl = TextEditingController(text: 'Glass replacement');
  final _repairGlassCtrl = TextEditingController(text: '500');
  final _repairHwCtrl = TextEditingController(text: '200');
  final _repairLaborCtrl = TextEditingController(text: '300');

  // Extra items
  final _extraNameCtrl = TextEditingController();
  final _extraRateCtrl = TextEditingController();
  final _extraQtyCtrl = TextEditingController(text: '1');

  @override
  void dispose() {
    _widthCtrl.dispose();
    _heightCtrl.dispose();
    _qtyCtrl.dispose();
    _doorWidthCtrl.dispose();
    _doorHeightCtrl.dispose();
    _bottomHeightCtrl.dispose();
    _repairDescCtrl.dispose();
    _repairGlassCtrl.dispose();
    _repairHwCtrl.dispose();
    _repairLaborCtrl.dispose();
    _extraNameCtrl.dispose();
    _extraRateCtrl.dispose();
    _extraQtyCtrl.dispose();
    super.dispose();
  }

  void _addItemToCart() {
    final qty = int.tryParse(_qtyCtrl.text) ?? 1;

    if (_selectedSeries == 'Repairing') {
      final item = WindowItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        series: 'Repairing',
        track: '-',
        w: 0,
        h: 0,
        qty: qty,
        desc: _repairDescCtrl.text,
        glass: double.tryParse(_repairGlassCtrl.text) ?? 0.0,
        hw: double.tryParse(_repairHwCtrl.text) ?? 0.0,
        labor: double.tryParse(_repairLaborCtrl.text) ?? 0.0,
      );
      widget.appState.addWindowItem(item);
    } else if (_selectedSeries == 'Partition') {
      final w = double.tryParse(_widthCtrl.text) ?? 0.0;
      final h = double.tryParse(_heightCtrl.text) ?? 0.0;
      if (w <= 0 || h <= 0) return;

      final pItem = PartitionItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        w: w,
        h: h,
        qty: qty,
        dw: double.tryParse(_doorWidthCtrl.text) ?? 36.0,
        dh: double.tryParse(_doorHeightCtrl.text) ?? 84.0,
        bh: double.tryParse(_bottomHeightCtrl.text) ?? 36.0,
        topMat: _topMat,
        midDes: _midDes,
        paneWSize: _paneWSize,
      );
      widget.appState.addPartitionItem(pItem);
    } else {
      final w = double.tryParse(_widthCtrl.text) ?? 0.0;
      final h = double.tryParse(_heightCtrl.text) ?? 0.0;
      if (w <= 0 || h <= 0) return;

      final item = WindowItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        series: _selectedSeries,
        track: _selectedTrack,
        w: w,
        h: h,
        qty: qty,
        jali: _hasJali,
      );
      widget.appState.addWindowItem(item);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Item added to cart!'),
        duration: Duration(milliseconds: 900),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _addExtraItem() {
    final name = _extraNameCtrl.text.trim();
    final rate = double.tryParse(_extraRateCtrl.text) ?? 0.0;
    final qty = double.tryParse(_extraQtyCtrl.text) ?? 1.0;

    if (name.isEmpty || rate <= 0) return;

    widget.appState.addExtraItem(
      ExtraItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        rate: rate,
        qty: qty,
      ),
    );

    _extraNameCtrl.clear();
    _extraRateCtrl.clear();
    _extraQtyCtrl.text = '1';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.appState.isDarkMode;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Customer Details Card
          _buildCustomerCard(isDark),
          const SizedBox(height: 16),

          // Window / Partition Entry Form
          _buildItemEntryForm(isDark),
          const SizedBox(height: 20),

          // Cart Items List
          _buildCartListCard(isDark),
          const SizedBox(height: 20),

          // Extra Items Section
          _buildExtraItemsCard(isDark),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.person_outline, size: 18, color: AppTheme.accentCyan),
                SizedBox(width: 8),
                Text(
                  'CUSTOMER & PROJECT INFO',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: CustomTextField(
                    label: 'Customer Name',
                    hint: 'e.g. Ramesh Patel',
                    initialValue: widget.appState.customerName,
                    onChanged: (val) => widget.appState.updateCustomerInfo(name: val),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: CustomTextField(
                    label: 'Project Title',
                    hint: 'e.g. Villa 402',
                    initialValue: widget.appState.projectName,
                    onChanged: (val) => widget.appState.updateCustomerInfo(project: val),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: CustomTextField(
                    label: 'Phone',
                    hint: '9876543210',
                    keyboardType: TextInputType.phone,
                    initialValue: widget.appState.phone,
                    onChanged: (val) => widget.appState.updateCustomerInfo(phone: val),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemEntryForm(bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.add_box_outlined, size: 18, color: AppTheme.accentCyan),
                SizedBox(width: 8),
                Text(
                  'WINDOW & PARTITION ENTRY',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Series Selector
            Row(
              children: [
                Expanded(
                  child: CustomDropdown<String>(
                    label: 'Series / Type',
                    value: _selectedSeries,
                    items: const [
                      DropdownMenuItem(value: '18x40', child: Text('18x40 Series')),
                      DropdownMenuItem(value: '60mm', child: Text('60mm Series')),
                      DropdownMenuItem(value: 'Domal', child: Text('Domal 27x65')),
                      DropdownMenuItem(value: 'R40', child: Text('R40 Series')),
                      DropdownMenuItem(value: 'Louver', child: Text('Louver Window')),
                      DropdownMenuItem(value: 'Partition', child: Text('Aluminum Partition')),
                      DropdownMenuItem(value: 'Repairing', child: Text('Repairing / Job Work')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedSeries = val;
                          if (val == 'Louver') {
                            _selectedTrack = 'Glass Blade';
                          } else if (val != 'Partition' && val != 'Repairing') {
                            _selectedTrack = '2Track';
                          }
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),

                // Track Selector if standard window
                if (_selectedSeries != 'Partition' && _selectedSeries != 'Repairing')
                  Expanded(
                    child: CustomDropdown<String>(
                      label: _selectedSeries == 'Louver' ? 'Blade Type' : 'Track',
                      value: _selectedTrack,
                      items: _selectedSeries == 'Louver'
                          ? const [
                              DropdownMenuItem(value: 'Glass Blade', child: Text('Glass Blade')),
                              DropdownMenuItem(value: 'Acrylic Blade', child: Text('Acrylic Blade')),
                            ]
                          : const [
                              DropdownMenuItem(value: '2Track', child: Text('2 Track (2 Panes)')),
                              DropdownMenuItem(value: '3Track', child: Text('3 Track (3 Panes)')),
                              DropdownMenuItem(value: '4Track', child: Text('4 Track (4 Panes)')),
                              DropdownMenuItem(value: 'Openable', child: Text('Openable Casement')),
                            ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedTrack = val);
                      },
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Form Fields for Standard Windows & Louver
            if (_selectedSeries != 'Partition' && _selectedSeries != 'Repairing') ...[
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: 'Width (Inches)',
                      controller: _widthCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      suffixText: 'inch',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CustomTextField(
                      label: 'Height (Inches)',
                      controller: _heightCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      suffixText: 'inch',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CustomTextField(
                      label: 'Quantity',
                      controller: _qtyCtrl,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Mosquito net checkbox
              if (_selectedSeries != 'Louver')
                CheckboxListTile(
                  title: const Text('Add Mosquito Mesh / Jali (₹16/sqft)', style: TextStyle(fontSize: 13)),
                  value: _hasJali,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  activeColor: AppTheme.accentCyan,
                  onChanged: (val) => setState(() => _hasJali = val == true),
                ),
            ],

            // Partition Form Fields
            if (_selectedSeries == 'Partition') ...[
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: 'Total Width (Inches)',
                      controller: _widthCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      suffixText: 'inch',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CustomTextField(
                      label: 'Total Height (Inches)',
                      controller: _heightCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      suffixText: 'inch',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CustomTextField(
                      label: 'Quantity',
                      controller: _qtyCtrl,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: 'Door Width (Inches)',
                      controller: _doorWidthCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      suffixText: 'inch',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CustomTextField(
                      label: 'Door Height (Inches)',
                      controller: _doorHeightCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      suffixText: 'inch',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CustomTextField(
                      label: 'Kick-Plate Height',
                      controller: _bottomHeightCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      suffixText: 'inch',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: CustomDropdown<String>(
                      label: 'Top Transom',
                      value: _topMat,
                      items: const [
                        DropdownMenuItem(value: 'sheet', child: Text('ACP Sheet')),
                        DropdownMenuItem(value: 'glass', child: Text('Clear Glass')),
                      ],
                      onChanged: (v) => setState(() => _topMat = v ?? 'sheet'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CustomDropdown<String>(
                      label: 'Middle Design',
                      value: _midDes,
                      items: const [
                        DropdownMenuItem(value: 'standard', child: Text('Standard Panes')),
                        DropdownMenuItem(value: 'cross', child: Text('Cross Design')),
                        DropdownMenuItem(value: 't_pattern', child: Text('T-Pattern')),
                        DropdownMenuItem(value: 'vertical', child: Text('Vertical Only')),
                        DropdownMenuItem(value: 'single', child: Text('Single Big Pane')),
                      ],
                      onChanged: (v) => setState(() => _midDes = v ?? 'standard'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CustomDropdown<String>(
                      label: 'Pane Width Rule',
                      value: _paneWSize,
                      items: const [
                        DropdownMenuItem(value: '36-42', child: Text('36" to 42"')),
                        DropdownMenuItem(value: '42-48', child: Text('42" to 48"')),
                        DropdownMenuItem(value: '48-54', child: Text('48" to 54"')),
                        DropdownMenuItem(value: 'auto', child: Text('Auto Balanced')),
                      ],
                      onChanged: (v) => setState(() => _paneWSize = v ?? '36-42'),
                    ),
                  ),
                ],
              ),
            ],

            // Repairing Form Fields
            if (_selectedSeries == 'Repairing') ...[
              CustomTextField(
                label: 'Work Description',
                controller: _repairDescCtrl,
                hint: 'e.g. Broken glass, rollers replacement',
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: 'Glass Cost (₹)',
                      controller: _repairGlassCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CustomTextField(
                      label: 'Hardware Cost (₹)',
                      controller: _repairHwCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CustomTextField(
                      label: 'Labor Cost (₹)',
                      controller: _repairLaborCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _addItemToCart,
                    icon: const Icon(Icons.add_shopping_cart, size: 18),
                    label: const Text('ADD TO CART'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartListCard(bool isDark) {
    final cart = widget.appState.cart;

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
                  children: [
                    const Icon(Icons.shopping_bag_outlined, size: 18, color: AppTheme.accentCyan),
                    const SizedBox(width: 8),
                    Text(
                      'ORDER CART (${cart.length} ITEMS)',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                if (cart.isNotEmpty)
                  TextButton.icon(
                    onPressed: () {
                      widget.appState.clearCart();
                    },
                    icon: const Icon(Icons.delete_sweep, size: 16, color: AppTheme.accentRose),
                    label: const Text('Clear All', style: TextStyle(color: AppTheme.accentRose, fontSize: 12)),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            if (cart.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                alignment: Alignment.center,
                child: Column(
                  children: const [
                    Icon(Icons.inventory_2_outlined, size: 40, color: Color(0xFF64748B)),
                    SizedBox(height: 8),
                    Text(
                      'Cart is empty. Add windows or partitions above.',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: cart.length,
                separatorBuilder: (_, __) => const Divider(height: 16, color: Color(0xFF334155)),
                itemBuilder: (context, index) {
                  final item = cart[index];
                  if (item is WindowItem) {
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        radius: 14,
                        backgroundColor: AppTheme.accentCyan.withOpacity(0.2),
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.accentCyan),
                        ),
                      ),
                      title: Text(
                        item.series == 'Repairing'
                            ? 'Repairing: ${item.desc}'
                            : '${item.series} - ${item.track} (${item.w}" × ${item.h}")',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        item.series == 'Repairing'
                            ? 'Qty: ${item.qty} | G: ₹${item.glass} | H: ₹${item.hw} | L: ₹${item.labor}'
                            : 'Qty: ${item.qty} | Area: ${item.sqft.toStringAsFixed(2)} sqft ${item.jali ? "| +Jali" : ""}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppTheme.accentRose, size: 20),
                        onPressed: () => widget.appState.removeCartItem(index),
                      ),
                    );
                  } else if (item is PartitionItem) {
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        radius: 14,
                        backgroundColor: AppTheme.accentAmber.withOpacity(0.2),
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.accentAmber),
                        ),
                      ),
                      title: Text(
                        'Partition (${item.w}" × ${item.h}") - Door: ${item.dw}"×${item.dh}"',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        'Qty: ${item.qty} | Area: ${item.sqft.toStringAsFixed(2)} sqft | Top: ${item.topMat} | Design: ${item.midDes}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppTheme.accentRose, size: 20),
                        onPressed: () => widget.appState.removeCartItem(index),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildExtraItemsCard(bool isDark) {
    final extraItems = widget.appState.extraItems;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.monetization_on_outlined, size: 18, color: AppTheme.accentAmber),
                SizedBox(width: 8),
                Text(
                  'EXTRA CHARGES / ACCESSORIES',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: CustomTextField(
                    label: 'Item Name',
                    hint: 'e.g. Extra Lock, Silicon, Clip',
                    controller: _extraNameCtrl,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: CustomTextField(
                    label: 'Rate (₹)',
                    hint: '150',
                    controller: _extraRateCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: CustomTextField(
                    label: 'Qty',
                    controller: _extraQtyCtrl,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 18.0),
                  child: ElevatedButton(
                    onPressed: _addExtraItem,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    child: const Text('Add'),
                  ),
                ),
              ],
            ),
            if (extraItems.isNotEmpty) ...[
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: extraItems.length,
                itemBuilder: (context, index) {
                  final ex = extraItems[index];
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(ex.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    subtitle: Text('Rate: ₹${ex.rate} × ${ex.qty} = ₹${ex.total.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                    trailing: IconButton(
                      icon: const Icon(Icons.close, color: AppTheme.accentRose, size: 18),
                      onPressed: () => widget.appState.removeExtraItem(index),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
