import 'window_item.dart';
import 'project_rates.dart';
import 'calculation_result.dart';

class SavedProject {
  final String id;
  final String customerName;
  final String projectName;
  final String phone;
  final String date;
  final String coating;
  final String weightType;
  final double profit;
  final double transport;
  final double extra;
  final bool useGst;
  final String billingMode;
  final bool minBilling;
  final List<dynamic> cart;
  final List<ExtraItem> extraItems;
  final List<ScrapItem> scrapItems;
  final List<int> allowedPipes;
  final ProjectRates rates;
  final CalculationResult result;

  SavedProject({
    required this.id,
    required this.customerName,
    required this.projectName,
    this.phone = '',
    required this.date,
    this.coating = 'Powder',
    this.weightType = 'Medium',
    this.profit = 10.0,
    this.transport = 0.0,
    this.extra = 0.0,
    this.useGst = true,
    this.billingMode = 'actual',
    this.minBilling = false,
    required this.cart,
    this.extraItems = const [],
    this.scrapItems = const [],
    this.allowedPipes = const [12, 15, 16],
    required this.rates,
    required this.result,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'customerName': customerName,
    'projectName': projectName,
    'phone': phone,
    'date': date,
    'coating': coating,
    'weightType': weightType,
    'profit': profit,
    'transport': transport,
    'extra': extra,
    'useGst': useGst,
    'billingMode': billingMode,
    'minBilling': minBilling,
    'cart': cart.map((e) => e is WindowItem ? e.toJson() : (e as PartitionItem).toJson()).toList(),
    'extraItems': extraItems.map((e) => e.toJson()).toList(),
    'scrapItems': scrapItems.map((e) => e.toJson()).toList(),
    'allowedPipes': allowedPipes,
    'rates': rates.toJson(),
    'grandTotal': result.grandTotal,
    'billingGrandTotal': result.billingGrandTotal,
    'totalSqft': result.totalSqft,
    'billingSqft': result.billingSqft,
  };

  factory SavedProject.fromJson(Map<String, dynamic> json) {
    List<dynamic> loadedCart = [];
    if (json['cart'] is List) {
      for (var item in json['cart']) {
        if (item is Map) {
          final itemMap = Map<String, dynamic>.from(item);
          if (itemMap['series'] == 'Partition') {
            loadedCart.add(PartitionItem.fromJson(itemMap));
          } else {
            loadedCart.add(WindowItem.fromJson(itemMap));
          }
        }
      }
    }

    List<ExtraItem> loadedExtras = [];
    if (json['extraItems'] is List) {
      for (var item in json['extraItems']) {
        if (item is Map) {
          loadedExtras.add(ExtraItem.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    List<ScrapItem> loadedScraps = [];
    if (json['scrapItems'] is List) {
      for (var item in json['scrapItems']) {
        if (item is Map) {
          loadedScraps.add(ScrapItem.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    List<int> loadedPipes = [12, 15, 16];
    if (json['allowedPipes'] is List) {
      loadedPipes = (json['allowedPipes'] as List).map((e) => (e as num).toInt()).toList();
      if (loadedPipes.isEmpty) loadedPipes = [12, 15, 16];
    }

    ProjectRates loadedRates = const ProjectRates();
    if (json['rates'] is Map) {
      loadedRates = ProjectRates.fromJson(Map<String, dynamic>.from(json['rates']));
    }

    final double gTotal = (json['grandTotal'] as num?)?.toDouble() ?? 0.0;
    final double bgTotal = (json['billingGrandTotal'] as num?)?.toDouble() ?? gTotal;
    final double tSqft = (json['totalSqft'] as num?)?.toDouble() ?? 0.0;
    final double bSqft = (json['billingSqft'] as num?)?.toDouble() ?? tSqft;

    return SavedProject(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      customerName: json['customerName']?.toString() ?? 'Saved Project',
      projectName: json['projectName']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      coating: json['coating']?.toString() ?? 'Powder',
      weightType: json['weightType']?.toString() ?? 'Medium',
      profit: (json['profit'] as num?)?.toDouble() ?? 10.0,
      transport: (json['transport'] as num?)?.toDouble() ?? 0.0,
      extra: (json['extra'] as num?)?.toDouble() ?? 0.0,
      useGst: json['useGst'] == true,
      billingMode: json['billingMode']?.toString() ?? 'actual',
      minBilling: json['minBilling'] == true,
      cart: loadedCart,
      extraItems: loadedExtras,
      scrapItems: loadedScraps,
      allowedPipes: loadedPipes,
      rates: loadedRates,
      result: CalculationResult(
        grandTotal: gTotal,
        billingGrandTotal: bgTotal,
        totalSqft: tSqft,
        billingSqft: bSqft,
      ),
    );
  }
}
