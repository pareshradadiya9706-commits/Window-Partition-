import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../models/project_rates.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_text_field.dart';

class RatesScreen extends StatefulWidget {
  final AppState appState;

  const RatesScreen({super.key, required this.appState});

  @override
  State<RatesScreen> createState() => _RatesScreenState();
}

class _RatesScreenState extends State<RatesScreen> {
  late TextEditingController _aluCtrl;
  late TextEditingController _partDpCtrl;
  late TextEditingController _partDoorCtrl;
  late TextEditingController _partClipCtrl;
  late TextEditingController _partSheetCtrl;
  late TextEditingController _glassCtrl;
  late TextEditingController _laborCtrl;
  late TextEditingController _hardCtrl;
  late TextEditingController _jaliCtrl;
  late TextEditingController _louverCtrl;
  late TextEditingController _doorHwCtrl;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    final r = widget.appState.rates;
    _aluCtrl = TextEditingController(text: r.aluRate.toStringAsFixed(0));
    _partDpCtrl = TextEditingController(text: r.partDpRate.toStringAsFixed(0));
    _partDoorCtrl = TextEditingController(text: r.partDoorRate.toStringAsFixed(0));
    _partClipCtrl = TextEditingController(text: r.partClipRate.toStringAsFixed(0));
    _partSheetCtrl = TextEditingController(text: r.partSheetRate.toStringAsFixed(0));
    _glassCtrl = TextEditingController(text: r.glassRateDefault.toStringAsFixed(0));
    _laborCtrl = TextEditingController(text: r.laborRateDefault.toStringAsFixed(0));
    _hardCtrl = TextEditingController(text: r.hardRateDefault.toStringAsFixed(0));
    _jaliCtrl = TextEditingController(text: r.jaliRateDefault.toStringAsFixed(0));
    _louverCtrl = TextEditingController(text: r.louverRateDefault.toStringAsFixed(0));
    _doorHwCtrl = TextEditingController(text: r.partDoorHwRate.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _aluCtrl.dispose();
    _partDpCtrl.dispose();
    _partDoorCtrl.dispose();
    _partClipCtrl.dispose();
    _partSheetCtrl.dispose();
    _glassCtrl.dispose();
    _laborCtrl.dispose();
    _hardCtrl.dispose();
    _jaliCtrl.dispose();
    _louverCtrl.dispose();
    _doorHwCtrl.dispose();
    super.dispose();
  }

  void _saveRates() {
    final newRates = ProjectRates(
      aluRate: double.tryParse(_aluCtrl.text) ?? 480.0,
      partDpRate: double.tryParse(_partDpCtrl.text) ?? 460.0,
      partDoorRate: double.tryParse(_partDoorCtrl.text) ?? 460.0,
      partClipRate: double.tryParse(_partClipCtrl.text) ?? 130.0,
      partSheetRate: double.tryParse(_partSheetCtrl.text) ?? 55.0,
      glassRateDefault: double.tryParse(_glassCtrl.text) ?? 58.0,
      laborRateDefault: double.tryParse(_laborCtrl.text) ?? 20.0,
      hardRateDefault: double.tryParse(_hardCtrl.text) ?? 15.0,
      jaliRateDefault: double.tryParse(_jaliCtrl.text) ?? 16.0,
      louverRateDefault: double.tryParse(_louverCtrl.text) ?? 130.0,
      partDoorHwRate: double.tryParse(_doorHwCtrl.text) ?? 850.0,
    );

    widget.appState.updateRates(newRates);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Master rates updated successfully!'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _resetDefaults() {
    widget.appState.resetDefaultRates();
    _initControllers();
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reset to standard factory default rates.'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Reset Action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.currency_rupee, size: 18, color: AppTheme.accentCyan),
                  SizedBox(width: 8),
                  Text(
                    'MASTER MATERIAL & LABOR RATES',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: _resetDefaults,
                icon: const Icon(Icons.refresh, size: 16, color: AppTheme.accentAmber),
                label: const Text('Defaults', style: TextStyle(color: AppTheme.accentAmber, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Aluminum & Metal Rates Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ALUMINUM EXTRUSION RATES (₹/KG)',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.accentCyan),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          label: 'Window Alu Rate',
                          controller: _aluCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          suffixText: '₹/kg',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: CustomTextField(
                          label: 'Partition Outer DP',
                          controller: _partDpCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          suffixText: '₹/kg',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          label: 'Partition Door Ver.',
                          controller: _partDoorCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          suffixText: '₹/kg',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: CustomTextField(
                          label: 'Partition Snap Clip',
                          controller: _partClipCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          suffixText: '₹/kg',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Glass, Labor & Hardware Rates Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'GLASS, LABOR & ACCESSORIES (₹/SQFT)',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.accentCyan),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          label: 'Plain Glass (4/5mm)',
                          controller: _glassCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          suffixText: '₹/sqft',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: CustomTextField(
                          label: 'Fabrication Labor',
                          controller: _laborCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          suffixText: '₹/sqft',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          label: 'Standard Hardware',
                          controller: _hardCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          suffixText: '₹/sqft',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: CustomTextField(
                          label: 'Mosquito Mesh (Jali)',
                          controller: _jaliCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          suffixText: '₹/sqft',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          label: 'Louver Mechanism',
                          controller: _louverCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          suffixText: '₹/sqft',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: CustomTextField(
                          label: 'Partition ACP Sheet',
                          controller: _partSheetCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          suffixText: '₹/sqft',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  CustomTextField(
                    label: 'Partition Door Hardware Set (Lock, Hinges, Handle)',
                    controller: _doorHwCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    suffixText: '₹/door',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          ElevatedButton.icon(
            onPressed: _saveRates,
            icon: const Icon(Icons.save, size: 18),
            label: const Text('SAVE MASTER RATES'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
