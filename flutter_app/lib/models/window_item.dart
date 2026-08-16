// Models for Window, Partition, Extra and Scrap Items

class WindowItem {
  final String id;
  final String series; // '18x40', '60mm', 'Domal', 'R40', 'Louver', 'Repairing'
  final String track;  // '2Track', '3Track', '4Track', 'Openable', 'Glass Blade', etc.
  final double w;      // Width in inches
  final double h;      // Height in inches
  final int qty;
  final String? desc;
  final String? color;
  final bool jali;     // Mosquito net
  final double? glass; // Repairing glass cost
  final double? hw;    // Repairing hardware cost
  final double? labor; // Repairing labor cost

  WindowItem({
    required this.id,
    required this.series,
    this.track = '2Track',
    required this.w,
    required this.h,
    this.qty = 1,
    this.desc,
    this.color,
    this.jali = false,
    this.glass,
    this.hw,
    this.labor,
  });

  double get sqft => (w * h) / 144.0 * qty;

  Map<String, dynamic> toJson() => {
    'id': id,
    'series': series,
    'track': track,
    'w': w,
    'h': h,
    'qty': qty,
    'desc': desc,
    'color': color,
    'jali': jali,
    'glass': glass,
    'hw': hw,
    'labor': labor,
  };

  factory WindowItem.fromJson(Map<String, dynamic> json) => WindowItem(
    id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
    series: json['series']?.toString() ?? '18x40',
    track: json['track']?.toString() ?? '2Track',
    w: (json['w'] as num?)?.toDouble() ?? 0.0,
    h: (json['h'] as num?)?.toDouble() ?? 0.0,
    qty: (json['qty'] as num?)?.toInt() ?? 1,
    desc: json['desc']?.toString(),
    color: json['color']?.toString(),
    jali: json['jali'] == true,
    glass: (json['glass'] as num?)?.toDouble(),
    hw: (json['hw'] as num?)?.toDouble(),
    labor: (json['labor'] as num?)?.toDouble(),
  );

  WindowItem copyWith({
    String? id,
    String? series,
    String? track,
    double? w,
    double? h,
    int? qty,
    String? desc,
    String? color,
    bool? jali,
    double? glass,
    double? hw,
    double? labor,
  }) {
    return WindowItem(
      id: id ?? this.id,
      series: series ?? this.series,
      track: track ?? this.track,
      w: w ?? this.w,
      h: h ?? this.h,
      qty: qty ?? this.qty,
      desc: desc ?? this.desc,
      color: color ?? this.color,
      jali: jali ?? this.jali,
      glass: glass ?? this.glass,
      hw: hw ?? this.hw,
      labor: labor ?? this.labor,
    );
  }
}

class PartitionItem {
  final String id;
  final String series; // Always 'Partition'
  final double w;      // Total Width in inches
  final double h;      // Total Height in inches
  final int qty;
  final double dw;     // Door width (inches)
  final double dh;     // Door height (inches)
  final String topMat; // 'sheet' or 'glass'
  final String midDes; // 'standard', 'cross', 't_pattern', 'vertical', 'single'
  final double bh;     // Bottom height (kick plate)
  final String paneWSize; // '36-42', '42-48', '48-54', 'auto'
  final double glassRate;
  final double laborRate;
  final String bottomMat;

  PartitionItem({
    required this.id,
    this.series = 'Partition',
    required this.w,
    required this.h,
    this.qty = 1,
    this.dw = 36.0,
    this.dh = 84.0,
    this.topMat = 'sheet',
    this.midDes = 'standard',
    this.bh = 36.0,
    this.paneWSize = '36-42',
    this.glassRate = 58.0,
    this.laborRate = 20.0,
    this.bottomMat = 'sheet',
  });

  double get sqft => (w * h) / 144.0 * qty;

  Map<String, dynamic> toJson() => {
    'id': id,
    'series': 'Partition',
    'w': w,
    'h': h,
    'qty': qty,
    'dw': dw,
    'dh': dh,
    'topMat': topMat,
    'midDes': midDes,
    'bh': bh,
    'paneWSize': paneWSize,
    'glassRate': glassRate,
    'laborRate': laborRate,
    'bottomMat': bottomMat,
  };

  factory PartitionItem.fromJson(Map<String, dynamic> json) => PartitionItem(
    id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
    series: 'Partition',
    w: (json['w'] as num?)?.toDouble() ?? 0.0,
    h: (json['h'] as num?)?.toDouble() ?? 0.0,
    qty: (json['qty'] as num?)?.toInt() ?? 1,
    dw: (json['dw'] as num?)?.toDouble() ?? 36.0,
    dh: (json['dh'] as num?)?.toDouble() ?? 84.0,
    topMat: json['topMat']?.toString() ?? 'sheet',
    midDes: json['midDes']?.toString() ?? 'standard',
    bh: (json['bh'] as num?)?.toDouble() ?? 36.0,
    paneWSize: json['paneWSize']?.toString() ?? '36-42',
    glassRate: (json['glassRate'] as num?)?.toDouble() ?? 58.0,
    laborRate: (json['laborRate'] as num?)?.toDouble() ?? 20.0,
    bottomMat: json['bottomMat']?.toString() ?? 'sheet',
  );

  PartitionItem copyWith({
    String? id,
    double? w,
    double? h,
    int? qty,
    double? dw,
    double? dh,
    String? topMat,
    String? midDes,
    double? bh,
    String? paneWSize,
    double? glassRate,
    double? laborRate,
    String? bottomMat,
  }) {
    return PartitionItem(
      id: id ?? this.id,
      w: w ?? this.w,
      h: h ?? this.h,
      qty: qty ?? this.qty,
      dw: dw ?? this.dw,
      dh: dh ?? this.dh,
      topMat: topMat ?? this.topMat,
      midDes: midDes ?? this.midDes,
      bh: bh ?? this.bh,
      paneWSize: paneWSize ?? this.paneWSize,
      glassRate: glassRate ?? this.glassRate,
      laborRate: laborRate ?? this.laborRate,
      bottomMat: bottomMat ?? this.bottomMat,
    );
  }
}

class ExtraItem {
  final String id;
  final String name;
  final double rate;
  final double qty;

  ExtraItem({
    required this.id,
    required this.name,
    required this.rate,
    this.qty = 1.0,
  });

  double get total => rate * qty;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'rate': rate,
    'qty': qty,
  };

  factory ExtraItem.fromJson(Map<String, dynamic> json) => ExtraItem(
    id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
    name: json['name']?.toString() ?? '',
    rate: (json['rate'] as num?)?.toDouble() ?? 0.0,
    qty: (json['qty'] as num?)?.toDouble() ?? 1.0,
  );
}

class ScrapItem {
  final String id;
  final String series;
  final String part;
  final double length; // in inches
  final int qty;

  ScrapItem({
    required this.id,
    required this.series,
    required this.part,
    required this.length,
    this.qty = 1,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'series': series,
    'part': part,
    'length': length,
    'qty': qty,
  };

  factory ScrapItem.fromJson(Map<String, dynamic> json) => ScrapItem(
    id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
    series: json['series']?.toString() ?? '',
    part: json['part']?.toString() ?? '',
    length: (json['length'] as num?)?.toDouble() ?? 0.0,
    qty: (json['qty'] as num?)?.toInt() ?? 1,
  );
}
