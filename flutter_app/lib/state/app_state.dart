import 'package:flutter/material.dart';
import '../models/window_item.dart';
import '../models/project_rates.dart';
import '../models/calculation_result.dart';
import '../models/project_history.dart';
import '../services/calculation_service.dart';
import '../services/storage_service.dart';

class AppState extends ChangeNotifier {
  // Navigation & Theme
  int _currentTabIndex = 0;
  bool _isDarkMode = true;

  int get currentTabIndex => _currentTabIndex;
  bool get isDarkMode => _isDarkMode;

  void setTabIndex(int index) {
    if (_currentTabIndex != index) {
      _currentTabIndex = index;
      notifyListeners();
    }
  }

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  // Customer & Project Info
  String _customerName = '';
  String _projectName = '';
  String _phone = '';

  String get customerName => _customerName;
  String get projectName => _projectName;
  String get phone => _phone;

  void updateCustomerInfo({String? name, String? project, String? phone}) {
    if (name != null) _customerName = name;
    if (project != null) _projectName = project;
    if (phone != null) _phone = phone;
    notifyListeners();
  }

  // Cart & Extra Items
  final List<dynamic> _cart = [];
  final List<ExtraItem> _extraItems = [];
  List<ScrapItem> _scrapItems = [];
  List<int> _allowedPipes = [12, 15, 16];

  List<dynamic> get cart => List.unmodifiable(_cart);
  List<ExtraItem> get extraItems => List.unmodifiable(_extraItems);
  List<ScrapItem> get scrapItems => List.unmodifiable(_scrapItems);
  List<int> get allowedPipes => List.unmodifiable(_allowedPipes);

  // Commercial Options
  String _coating = 'Powder';
  String _weightType = 'Medium';
  double _profit = 10.0;
  double _transport = 0.0;
  double _extra = 0.0;
  bool _useGst = true;
  String _billingMode = 'actual';
  bool _minBilling = false;

  String get coating => _coating;
  String get weightType => _weightType;
  double get profit => _profit;
  double get transport => _transport;
  double get extra => _extra;
  bool get useGst => _useGst;
  String get billingMode => _billingMode;
  bool get minBilling => _minBilling;

  // Master Material Rates
  ProjectRates _rates = const ProjectRates();
  ProjectRates get rates => _rates;

  // Calculated Result & Calculation State
  CalculationResult _result = CalculationResult();
  CalculationResult get result => _result;

  bool _isCalculating = false;
  bool get isCalculating => _isCalculating;

  String? _calculationError;
  String? get calculationError => _calculationError;

  AppState() {
    _recalculate();
  }

  int _calcSequence = 0;

  Future<void> _recalculate() async {
    final int currentSeq = ++_calcSequence;
    _isCalculating = true;
    _calculationError = null;

    try {
      final res = await FlutterCalculationService.calculateProjectAsync(
        cart: _cart,
        allowed: _allowedPipes,
        rates: _rates,
        coat: _coating,
        wType: _weightType,
        profit: _profit,
        transport: _transport,
        extra: _extra,
        useGst: _useGst,
        billingMode: _billingMode,
        minBilling: _minBilling,
        scrap: _scrapItems,
        extraItems: _extraItems,
      );

      if (currentSeq == _calcSequence) {
        _result = res;
        _isCalculating = false;
        _calculationError = null;
        notifyListeners();
      }
    } catch (e, stack) {
      if (currentSeq == _calcSequence) {
        _calculationError = 'Calculation error: $e';
        _isCalculating = false;
        notifyListeners();
      }
    }
  }

  // Cart operations
  void addWindowItem(WindowItem item) {
    _cart.add(item);
    _recalculate();
  }

  void addPartitionItem(PartitionItem item) {
    _cart.add(item);
    _recalculate();
  }

  void removeCartItem(int index) {
    if (index >= 0 && index < _cart.length) {
      _cart.removeAt(index);
      _recalculate();
    }
  }

  void clearCart() {
    _cart.clear();
    _extraItems.clear();
    _recalculate();
  }

  // Extra items
  void addExtraItem(ExtraItem item) {
    _extraItems.add(item);
    _recalculate();
  }

  void removeExtraItem(int index) {
    if (index >= 0 && index < _extraItems.length) {
      _extraItems.removeAt(index);
      _recalculate();
    }
  }

  // Scrap items
  void addScrapItem(ScrapItem item) {
    _scrapItems.add(item);
    StorageService.addScrap(item);
    _recalculate();
  }

  void removeScrapItem(String id) {
    _scrapItems.removeWhere((s) => s.id == id);
    StorageService.removeScrap(id);
    _recalculate();
  }

  // Options update
  void updateOptions({
    String? coating,
    String? weightType,
    double? profit,
    double? transport,
    double? extra,
    bool? useGst,
    String? billingMode,
    bool? minBilling,
    List<int>? allowedPipes,
  }) {
    if (coating != null) _coating = coating;
    if (weightType != null) _weightType = weightType;
    if (profit != null) _profit = profit;
    if (transport != null) _transport = transport;
    if (extra != null) _extra = extra;
    if (useGst != null) _useGst = useGst;
    if (billingMode != null) _billingMode = billingMode;
    if (minBilling != null) _minBilling = minBilling;
    if (allowedPipes != null) _allowedPipes = allowedPipes;
    _recalculate();
  }

  void togglePipeLength(int lengthFt) {
    List<int> pipes = List<int>.from(_allowedPipes);
    if (pipes.contains(lengthFt)) {
      if (pipes.length > 1) {
        pipes.remove(lengthFt);
      }
    } else {
      pipes.add(lengthFt);
      pipes.sort();
    }
    _allowedPipes = pipes;
    _recalculate();
  }

  // Rates update
  void updateRates(ProjectRates newRates) {
    _rates = newRates;
    _recalculate();
  }

  void resetDefaultRates() {
    _rates = const ProjectRates();
    _recalculate();
  }

  // History operations
  void saveCurrentProject() {
    final now = DateTime.now();
    final dateStr = '${now.day}/${now.month}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final saved = SavedProject(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      customerName: _customerName.isNotEmpty ? _customerName : 'Walk-in Customer',
      projectName: _projectName.isNotEmpty ? _projectName : 'Window Project',
      phone: _phone,
      date: dateStr,
      coating: _coating,
      weightType: _weightType,
      profit: _profit,
      transport: _transport,
      extra: _extra,
      useGst: _useGst,
      billingMode: _billingMode,
      minBilling: _minBilling,
      cart: List.from(_cart),
      extraItems: List.from(_extraItems),
      scrapItems: List.from(_scrapItems),
      allowedPipes: List.from(_allowedPipes),
      rates: _rates,
      result: _result,
    );
    StorageService.saveProject(saved);
    notifyListeners();
  }

  void loadProject(SavedProject project) {
    _customerName = project.customerName;
    _projectName = project.projectName;
    _phone = project.phone;
    _coating = project.coating;
    _weightType = project.weightType;
    _profit = project.profit;
    _transport = project.transport;
    _extra = project.extra;
    _useGst = project.useGst;
    _billingMode = project.billingMode;
    _minBilling = project.minBilling;
    _allowedPipes = List.from(project.allowedPipes);
    _rates = project.rates;

    _cart.clear();
    _cart.addAll(project.cart);
    _extraItems.clear();
    _extraItems.addAll(project.extraItems);
    _scrapItems = List.from(project.scrapItems);

    _recalculate();
    _currentTabIndex = 0; // Navigate to Order screen
    notifyListeners();
  }

  String exportFullBackupJson() {
    return StorageService.exportFullBackup(
      customerName: _customerName,
      projectName: _projectName,
      phone: _phone,
      coating: _coating,
      weightType: _weightType,
      profit: _profit,
      transport: _transport,
      extra: _extra,
      useGst: _useGst,
      billingMode: _billingMode,
      minBilling: _minBilling,
      cart: _cart,
      extraItems: _extraItems,
      allowedPipes: _allowedPipes,
      rates: _rates,
      result: _result,
    );
  }

  void restoreFullBackup(Map<String, dynamic> data) {
    StorageService.applyValidatedStorage(data);

    final currentProj = data['current_project'];
    if (currentProj is Map) {
      final cp = Map<String, dynamic>.from(currentProj);
      _customerName = cp['customerName']?.toString() ?? '';
      _projectName = cp['projectName']?.toString() ?? '';
      _phone = cp['phone']?.toString() ?? '';
      _coating = cp['coating']?.toString() ?? 'Powder';
      _weightType = cp['weightType']?.toString() ?? 'Medium';
      _profit = (cp['profit'] as num?)?.toDouble() ?? 10.0;
      _transport = (cp['transport'] as num?)?.toDouble() ?? 0.0;
      _extra = (cp['extra'] as num?)?.toDouble() ?? 0.0;
      _useGst = cp['useGst'] == true;
      _billingMode = cp['billingMode']?.toString() ?? 'actual';
      _minBilling = cp['minBilling'] == true;

      if (cp['allowedPipes'] is List) {
        _allowedPipes = (cp['allowedPipes'] as List).map((e) => (e as num).toInt()).toList();
        if (_allowedPipes.isEmpty) _allowedPipes = [12, 15, 16];
      }

      if (cp['rates'] is Map) {
        _rates = ProjectRates.fromJson(Map<String, dynamic>.from(cp['rates']));
      }

      _cart.clear();
      if (cp['cart'] is List) {
        for (var item in cp['cart']) {
          if (item is Map) {
            final itemMap = Map<String, dynamic>.from(item);
            if (itemMap['series'] == 'Partition') {
              _cart.add(PartitionItem.fromJson(itemMap));
            } else {
              _cart.add(WindowItem.fromJson(itemMap));
            }
          }
        }
      }

      _extraItems.clear();
      if (cp['extraItems'] is List) {
        for (var item in cp['extraItems']) {
          if (item is Map) {
            _extraItems.add(ExtraItem.fromJson(Map<String, dynamic>.from(item)));
          }
        }
      }
    }

    _scrapItems = List.from(StorageService.getScrapItems());
    _recalculate();
    notifyListeners();
  }
}
