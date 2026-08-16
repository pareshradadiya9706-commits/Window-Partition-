// Calculation Result Models mapping 1-to-1 with python calculation engine

class PipeCutBin {
  final int sizeFt;
  final List<dynamic> cuts;
  final double waste;
  final double weight;

  PipeCutBin({
    required this.sizeFt,
    required this.cuts,
    required this.waste,
    required this.weight,
  });

  Map<String, dynamic> toJson() => {
    'size_ft': sizeFt,
    'cuts': cuts,
    'waste': waste,
    'weight': weight,
  };

  factory PipeCutBin.fromJson(Map<String, dynamic> json) => PipeCutBin(
    sizeFt: (json['size_ft'] as num?)?.toInt() ?? 12,
    cuts: (json['cuts'] as List<dynamic>?) ?? [],
    waste: (json['waste'] as num?)?.toDouble() ?? 0.0,
    weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
  );
}

class PackedSection {
  final List<PipeCutBin> pipes;
  final int scrapUsed;
  final int totalNeeded;

  PackedSection({
    required this.pipes,
    required this.scrapUsed,
    required this.totalNeeded,
  });

  Map<String, dynamic> toJson() => {
    'pipes': pipes.map((e) => e.toJson()).toList(),
    'scrapUsed': scrapUsed,
    'totalNeeded': totalNeeded,
  };

  factory PackedSection.fromJson(Map<String, dynamic> json) => PackedSection(
    pipes: (json['pipes'] as List<dynamic>?)
            ?.map((e) => PipeCutBin.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
    scrapUsed: (json['scrapUsed'] as num?)?.toInt() ?? 0,
    totalNeeded: (json['totalNeeded'] as num?)?.toInt() ?? 0,
  );
}

class CutSummaryRow {
  final int no;
  final String series;
  final String track;
  final dynamic w;
  final dynamic h;
  final int qty;
  final dynamic gw;
  final dynamic gh;
  final int? gq;
  final bool jali;
  final double? glass;
  final double? hw;
  final double? labor;

  CutSummaryRow({
    required this.no,
    required this.series,
    required this.track,
    required this.w,
    required this.h,
    required this.qty,
    this.gw,
    this.gh,
    this.gq,
    this.jali = false,
    this.glass,
    this.hw,
    this.labor,
  });

  factory CutSummaryRow.fromJson(Map<String, dynamic> json) => CutSummaryRow(
    no: (json['no'] as num?)?.toInt() ?? 1,
    series: json['series']?.toString() ?? '',
    track: json['track']?.toString() ?? '-',
    w: json['w'],
    h: json['h'],
    qty: (json['qty'] as num?)?.toInt() ?? 1,
    gw: json['gw'],
    gh: json['gh'],
    gq: (json['gq'] as num?)?.toInt(),
    jali: json['jali'] == true,
    glass: (json['glass'] as num?)?.toDouble(),
    hw: (json['hw'] as num?)?.toDouble(),
    labor: (json['labor'] as num?)?.toDouble(),
  );
}

class GlassDetail {
  final int no;
  final dynamic w;
  final dynamic h;
  final int qty;
  final double sqft;

  GlassDetail({
    required this.no,
    required this.w,
    required this.h,
    required this.qty,
    required this.sqft,
  });

  factory GlassDetail.fromJson(Map<String, dynamic> json) => GlassDetail(
    no: (json['no'] as num?)?.toInt() ?? 1,
    w: json['w'],
    h: json['h'],
    qty: (json['qty'] as num?)?.toInt() ?? 1,
    sqft: (json['sqft'] as num?)?.toDouble() ?? 0.0,
  );
}

class BillingDetail {
  final int no;
  final double w;
  final double h;
  final double bw;
  final double bh;
  final double actualSqftPerPiece;
  final double billingSqftPerPiece;
  final int qty;
  final bool minApplied;

  BillingDetail({
    required this.no,
    required this.w,
    required this.h,
    required this.bw,
    required this.bh,
    required this.actualSqftPerPiece,
    required this.billingSqftPerPiece,
    required this.qty,
    required this.minApplied,
  });

  factory BillingDetail.fromJson(Map<String, dynamic> json) => BillingDetail(
    no: (json['no'] as num?)?.toInt() ?? 1,
    w: (json['w'] as num?)?.toDouble() ?? 0.0,
    h: (json['h'] as num?)?.toDouble() ?? 0.0,
    bw: (json['bw'] as num?)?.toDouble() ?? 0.0,
    bh: (json['bh'] as num?)?.toDouble() ?? 0.0,
    actualSqftPerPiece: (json['actualSqftPerPiece'] as num?)?.toDouble() ?? 0.0,
    billingSqftPerPiece: (json['billingSqftPerPiece'] as num?)?.toDouble() ?? 0.0,
    qty: (json['qty'] as num?)?.toInt() ?? 1,
    minApplied: json['minApplied'] == true,
  );
}

class CalculationResult {
  final double totalSqft;
  final double totalWeight;
  final double totalAluCost;
  final double totalGlassCost;
  final double totalCoatCost;
  final double totalLaborCost;
  final double totalHardwareCost;
  final double totalJaliCost;
  final double totalLouverCost;
  final double totalPartSheetCost;
  final double totalExtraCost;
  final double baseCost;
  final double profitAmt;
  final double transport;
  final double extra;
  final double subTotal;
  final double gstAmount;
  final int totalWindows;
  final double grandTotal;
  final Map<String, PackedSection> packedData;
  final List<CutSummaryRow> cuttingSummary;
  final List<GlassDetail> glassDetails;
  final double totalGlassSqft;
  final double billingSqft;
  final double billingSubTotal;
  final double billingGst;
  final double billingGrandTotal;
  final String billingMode;
  final bool minBillingEnabled;
  final bool minApplied;
  final List<BillingDetail> billingDetails;

  CalculationResult({
    this.totalSqft = 0.0,
    this.totalWeight = 0.0,
    this.totalAluCost = 0.0,
    this.totalGlassCost = 0.0,
    this.totalCoatCost = 0.0,
    this.totalLaborCost = 0.0,
    this.totalHardwareCost = 0.0,
    this.totalJaliCost = 0.0,
    this.totalLouverCost = 0.0,
    this.totalPartSheetCost = 0.0,
    this.totalExtraCost = 0.0,
    this.baseCost = 0.0,
    this.profitAmt = 0.0,
    this.transport = 0.0,
    this.extra = 0.0,
    this.subTotal = 0.0,
    this.gstAmount = 0.0,
    this.totalWindows = 0,
    this.grandTotal = 0.0,
    this.packedData = const {},
    this.cuttingSummary = const [],
    this.glassDetails = const [],
    this.totalGlassSqft = 0.0,
    this.billingSqft = 0.0,
    this.billingSubTotal = 0.0,
    this.billingGst = 0.0,
    this.billingGrandTotal = 0.0,
    this.billingMode = 'actual',
    this.minBillingEnabled = false,
    this.minApplied = false,
    this.billingDetails = const [],
  });

  factory CalculationResult.fromJson(Map<String, dynamic> json) {
    Map<String, PackedSection> packed = {};
    if (json['packed_data'] is Map) {
      (json['packed_data'] as Map).forEach((k, v) {
        if (v is Map) {
          packed[k.toString()] = PackedSection.fromJson(Map<String, dynamic>.from(v));
        }
      });
    }

    return CalculationResult(
      totalSqft: (json['total_sqft'] as num?)?.toDouble() ?? 0.0,
      totalWeight: (json['total_weight'] as num?)?.toDouble() ?? 0.0,
      totalAluCost: (json['total_alu_cost'] as num?)?.toDouble() ?? 0.0,
      totalGlassCost: (json['total_glass_cost'] as num?)?.toDouble() ?? 0.0,
      totalCoatCost: (json['total_coat_cost'] as num?)?.toDouble() ?? 0.0,
      totalLaborCost: (json['total_labor_cost'] as num?)?.toDouble() ?? 0.0,
      totalHardwareCost: (json['total_hardware_cost'] as num?)?.toDouble() ?? 0.0,
      totalJaliCost: (json['total_jali_cost'] as num?)?.toDouble() ?? 0.0,
      totalLouverCost: (json['total_louver_cost'] as num?)?.toDouble() ?? 0.0,
      totalPartSheetCost: (json['total_part_sheet_cost'] as num?)?.toDouble() ?? 0.0,
      totalExtraCost: (json['total_extra_cost'] as num?)?.toDouble() ?? 0.0,
      baseCost: (json['base_cost'] as num?)?.toDouble() ?? 0.0,
      profitAmt: (json['profit_amt'] as num?)?.toDouble() ?? 0.0,
      transport: (json['transport'] as num?)?.toDouble() ?? 0.0,
      extra: (json['extra'] as num?)?.toDouble() ?? 0.0,
      subTotal: (json['sub_total'] as num?)?.toDouble() ?? 0.0,
      gstAmount: (json['gst_amount'] as num?)?.toDouble() ?? 0.0,
      totalWindows: (json['total_windows'] as num?)?.toInt() ?? 0,
      grandTotal: (json['grand_total'] as num?)?.toDouble() ?? 0.0,
      packedData: packed,
      cuttingSummary: (json['cutting_summary'] as List<dynamic>?)
              ?.map((e) => CutSummaryRow.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [],
      glassDetails: (json['glass_details'] as List<dynamic>?)
              ?.map((e) => GlassDetail.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [],
      totalGlassSqft: (json['total_glass_sqft'] as num?)?.toDouble() ?? 0.0,
      billingSqft: (json['billing_sqft'] as num?)?.toDouble() ?? 0.0,
      billingSubTotal: (json['billing_sub_total'] as num?)?.toDouble() ?? 0.0,
      billingGst: (json['billing_gst'] as num?)?.toDouble() ?? 0.0,
      billingGrandTotal: (json['billing_grand_total'] as num?)?.toDouble() ?? 0.0,
      billingMode: json['billing_mode']?.toString() ?? 'actual',
      minBillingEnabled: json['min_billing_enabled'] == true,
      minApplied: json['min_applied'] == true,
      billingDetails: (json['billing_details'] as List<dynamic>?)
              ?.map((e) => BillingDetail.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [],
    );
  }
}
