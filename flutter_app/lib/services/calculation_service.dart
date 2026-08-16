import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import '../models/window_item.dart';
import '../models/project_rates.dart';
import '../models/calculation_result.dart';

class FlutterCalculationService {
  static const MethodChannel _channel = MethodChannel('com.aistudio.windowsection/calc');

  /// Converts the project calculation parameters into a JSON-compatible map for the Python backend.
  static Map<String, dynamic> buildPayload({
    required List<dynamic> cart,
    List<int> allowed = const [12, 15, 16],
    required ProjectRates rates,
    String coat = 'Powder',
    String wType = 'Medium',
    double profit = 10.0,
    double transport = 0.0,
    double extra = 0.0,
    bool useGst = true,
    String billingMode = 'actual',
    bool minBilling = false,
    List<ScrapItem> scrap = const [],
    List<ExtraItem> extraItems = const [],
  }) {
    List<Map<String, dynamic>> cartPayload = [];
    for (var item in cart) {
      if (item is WindowItem) {
        cartPayload.add({
          'series': item.series,
          'track': item.track,
          'w': item.w,
          'h': item.h,
          'qty': item.qty,
          'jali': item.jali,
          'gtype': item.color ?? 'Plain/Clear',
          if (item.desc != null) 'desc': item.desc,
          'glass': item.glass ?? 0.0,
          'hw': item.hw ?? 0.0,
          'labor': item.labor ?? 0.0,
        });
      } else if (item is PartitionItem) {
        cartPayload.add({
          'series': 'Partition',
          'track': '-',
          'w': item.w,
          'h': item.h,
          'qty': item.qty,
          'dw': item.dw,
          'dh': item.dh,
          'topMat': item.topMat,
          'midDes': item.midDes,
          'bh': item.bh,
          'paneWSize': item.paneWSize,
          'jali': false,
          'gtype': '',
        });
      } else if (item is Map) {
        cartPayload.add(Map<String, dynamic>.from(item));
      }
    }

    return {
      'cart': cartPayload,
      'allowed_pipes': allowed,
      'rates': rates.toJson(),
      'coating': coat,
      'weight_type': wType,
      'profit': profit,
      'transport': transport,
      'extra': extra,
      'use_gst': useGst,
      'billing_mode': billingMode,
      'min_billing': minBilling,
      'scrap': scrap.map((s) => s.toJson()).toList(),
      'extra_items': extraItems.map((e) => e.toJson()).toList(),
    };
  }

  /// Calculates project asynchronously via Chaquopy Python in-process runtime with fallback
  static Future<CalculationResult> calculateProjectAsync({
    required List<dynamic> cart,
    List<int> allowed = const [12, 15, 16],
    required ProjectRates rates,
    String coat = 'Powder',
    String wType = 'Medium',
    double profit = 10.0,
    double transport = 0.0,
    double extra = 0.0,
    bool useGst = true,
    String billingMode = 'actual',
    bool minBilling = false,
    List<ScrapItem> scrap = const [],
    List<ExtraItem> extraItems = const [],
  }) async {
    try {
      final payload = buildPayload(
        cart: cart,
        allowed: allowed,
        rates: rates,
        coat: coat,
        wType: wType,
        profit: profit,
        transport: transport,
        extra: extra,
        useGst: useGst,
        billingMode: billingMode,
        minBilling: minBilling,
        scrap: scrap,
        extraItems: extraItems,
      );

      final String payloadJson = jsonEncode(payload);
      final String? resultJson = await _channel.invokeMethod<String>('calculate', payloadJson);

      if (resultJson != null && resultJson.isNotEmpty) {
        final Map<String, dynamic> resultMap = jsonDecode(resultJson) as Map<String, dynamic>;
        return CalculationResult.fromJson(resultMap);
      }
    } catch (e) {
      // If MethodChannel is not available (e.g. running on JVM / pure Dart), compute directly
    }

    return calculateProject(
      cart: cart,
      allowed: allowed,
      rates: rates,
      coat: coat,
      wType: wType,
      profit: profit,
      transport: transport,
      extra: extra,
      useGst: useGst,
      billingMode: billingMode,
      minBilling: minBilling,
      scrap: scrap,
      extraItems: extraItems,
    );
  }
  /// SOURCE: formatDora from verified JavaScript / Python engine
  static String formatDora(dynamic v) {
    if (v == null || v == '-' || v == '') return '-';
    double val = (v is num) ? v.toDouble() : double.tryParse(v.toString()) ?? 0.0;
    if (val == 0.0) return '-';
    int inch = val.floor();
    double frac = val - inch;
    int s16 = (frac * 16.0).round();
    if (s16 == 16) {
      inch += 1;
      s16 = 0;
    }
    if (s16 == 0) return '$inch"';

    int gcd(int a, int b) => b == 0 ? a : gcd(b, a % b);
    int g = gcd(s16, 16);
    int numFrac = s16 ~/ g;
    int denFrac = 16 ~/ g;

    if (inch == 0) return '$numFrac/$denFrac"';
    return '$inch $numFrac/$denFrac"';
  }

  /// 1D Best Fit Decreasing Linear Stock Packing
  static List<Map<String, dynamic>> packBfd(
    List<dynamic> lengths,
    List<int> allowedFt, {
    double kerf = 0.15,
  }) {
    List<double> cuts = [];
    for (var l in lengths) {
      double len = (l is Map) ? (l['len'] as num).toDouble() : (l is num ? l.toDouble() : double.tryParse(l.toString()) ?? 0.0);
      if (len > 0) cuts.add(len);
    }
    cuts.sort((a, b) => b.compareTo(a));

    List<int> allowedInches = allowedFt.map((f) => f * 12).toList()..sort();
    List<Map<String, dynamic>> bins = [];

    for (double cut in cuts) {
      bool placed = false;
      for (var b in bins) {
        double rem = (b['rem'] as num).toDouble();
        if (rem >= (cut + kerf)) {
          (b['cuts'] as List).add(cut);
          b['rem'] = rem - (cut + kerf);
          placed = true;
          break;
        }
      }
      if (!placed) {
        int bestSize = -1;
        for (int sz in allowedInches) {
          if (sz >= cut) {
            bestSize = sz;
            break;
          }
        }
        if (bestSize == -1) {
          bestSize = allowedInches.last;
        }
        bins.add({
          'size': bestSize,
          'cuts': [cut],
          'rem': bestSize - cut,
        });
      }
    }
    return bins;
  }

  /// Evaluates full project estimation with 100% mathematical parity
  static CalculationResult calculateProject({
    required List<dynamic> cart,
    List<int> allowed = const [12, 15, 16],
    required ProjectRates rates,
    String coat = 'Powder',
    String wType = 'Medium',
    double profit = 10.0,
    double transport = 0.0,
    double extra = 0.0,
    bool useGst = true,
    String billingMode = 'actual',
    bool minBilling = false,
    List<ScrapItem> scrap = const [],
    List<ExtraItem> extraItems = const [],
  }) {
    Map<String, List<Map<String, dynamic>>> master = {};
    double totalSqft = 0.0;
    double totalGlassSqft = 0.0;
    double totalJali = 0.0;
    double totalLouver = 0.0;
    List<GlassDetail> glassDetails = [];
    List<CutSummaryRow> cutSum = [];
    double totalGlassCost = 0.0;
    double totalLabor = 0.0;
    double totalHard = 0.0;
    int totalQty = 0;
    double totalPartSheetCost = 0.0;
    double totalPartHardware = 0.0;
    double totalExtraCost = 0.0;

    List<BillingDetail> billingDetails = [];
    double totalBillingSqft = 0.0;
    bool minApplied = false;

    // Build scrap map
    Map<String, List<double>> scrapMap = {};
    for (var s in scrap) {
      String key = '${s.series} ${s.part}';
      scrapMap.putIfAbsent(key, () => []);
      for (int k = 0; k < s.qty; k++) {
        scrapMap[key]!.add(s.length);
      }
    }

    void addCut(String section, double length, int count, {int? winNo}) {
      master.putIfAbsent(section, () => []);
      for (int k = 0; k < count; k++) {
        master[section]!.add({'len': length, 'win': winNo});
      }
    }

    for (int i = 0; i < cart.length; i++) {
      var item = cart[i];
      if (item is WindowItem && item.series == 'Repairing') {
        int q = item.qty;
        totalQty += q;
        double gCost = (item.glass ?? 0.0) * q;
        double hCost = (item.hw ?? 0.0) * q;
        double lCost = (item.labor ?? 0.0) * q;
        totalGlassCost += gCost;
        totalHard += hCost;
        totalLabor += lCost;
        cutSum.add(CutSummaryRow(
          no: i + 1,
          series: 'Repairing',
          track: item.desc ?? '',
          w: '-',
          h: '-',
          qty: q,
          glass: item.glass ?? 0.0,
          hw: item.hw ?? 0.0,
          labor: item.labor ?? 0.0,
        ));
        continue;
      }

      double w = (item is WindowItem) ? item.w : (item as PartitionItem).w;
      double h = (item is WindowItem) ? item.h : (item as PartitionItem).h;
      int qty = (item is WindowItem) ? item.qty : (item as PartitionItem).qty;
      String sr = (item is WindowItem) ? item.series : 'Partition';
      String tr = (item is WindowItem) ? item.track : '-';
      bool jali = (item is WindowItem) ? item.jali : false;

      double sqft = (w * h) / 144.0 * qty;
      totalSqft += sqft;
      totalQty += qty;

      double bw = w;
      double bh = h;
      if (billingMode == 'plus3') {
        bw = (w / 3.0).ceil() * 3.0;
        bh = (h / 3.0).ceil() * 3.0;
      }
      double billingSqftPerPiece = (bw * bh) / 144.0;
      bool minAppliedForThis = false;
      if (minBilling && billingSqftPerPiece < 11.0) {
        billingSqftPerPiece = 11.0;
        minAppliedForThis = true;
      }
      totalBillingSqft += billingSqftPerPiece * qty;
      if (minAppliedForThis) minApplied = true;

      billingDetails.add(BillingDetail(
        no: i + 1,
        w: w,
        h: h,
        bw: bw,
        bh: bh,
        actualSqftPerPiece: (w * h) / 144.0,
        billingSqftPerPiece: billingSqftPerPiece,
        qty: qty,
        minApplied: minAppliedForThis,
      ));

      if (sr == 'Partition') {
        var pItem = item as PartitionItem;
        double dw = pItem.dw;
        double dh = pItem.dh;
        double bhVal = pItem.bh;

        int minPaneW = 36;
        int maxPaneW = 42;
        if (pItem.paneWSize == '42-48') {
          minPaneW = 42;
          maxPaneW = 48;
        } else if (pItem.paneWSize == '48-54') {
          minPaneW = 48;
          maxPaneW = 54;
        } else if (pItem.paneWSize == 'auto') {
          minPaneW = 30;
          maxPaneW = 60;
        }

        int cols = 1;
        double paneW = 0.0;
        bool found = false;
        double pt = 1.5;

        for (int c = 1; c <= 20; c++) {
          double totalPosts = (dw > 0) ? (c + 2) * pt : (c + 1) * pt;
          double calcW = (w - dw - totalPosts) / c;
          if (calcW >= minPaneW && calcW <= maxPaneW) {
            cols = c;
            paneW = calcW;
            found = true;
            break;
          }
        }
        if (!found) {
          cols = max(1, ((w - dw - 6.0) / maxPaneW).ceil());
          double totalPosts = (dw > 0) ? (cols + 2) * pt : (cols + 1) * pt;
          paneW = (w - dw - totalPosts) / cols;
        }

        double topH = (h - dh) - 2 * pt;
        if (topH < 0) topH = 0.0;
        double glassH = (dh - bhVal - 2 * pt);
        if (glassH < 0) glassH = 0.0;

        for (int q = 0; q < qty; q++) {
          addCut('Partition DP Pipe', h, 2, winNo: i + 1);
          addCut('Partition DP Pipe', w - 3.0, 1, winNo: i + 1);
          addCut('Partition DP Pipe', h - 1.5, 1, winNo: i + 1);
          addCut('Partition DP Pipe', w - dw - 4.5, 1, winNo: i + 1);
          if (cols > 1) {
            addCut('Partition DP Pipe', h - 3.0, (cols - 1), winNo: i + 1);
          }
          if (dw > 0) {
            addCut('Partition DP Pipe', dw, 1, winNo: i + 1);
          }
          addCut('Partition DP Pipe', paneW, cols * 2, winNo: i + 1);

          if (dw > 0 && dh > 0) {
            addCut('Partition Door Pipe', dh, 2, winNo: i + 1);
            addCut('Partition Door Pipe', dw, 3, winNo: i + 1);
          }
        }

        double pGlassSqft = 0.0;
        if (pItem.topMat == 'glass') {
          pGlassSqft += ((w * topH) / 144.0) * qty;
        }
        pGlassSqft += ((cols * paneW * glassH) / 144.0) * qty;
        totalGlassSqft += pGlassSqft;

        totalPartHardware += (dw > 0 ? rates.partDoorHwRate : 0.0) * qty;
        totalLabor += (sqft * rates.laborRateDefault);
        totalGlassCost += (pGlassSqft * rates.glassRateDefault);

        cutSum.add(CutSummaryRow(
          no: i + 1,
          series: 'Partition',
          track: tr,
          w: w,
          h: h,
          qty: qty,
          gw: paneW,
          gh: topH,
        ));
      } else {
        // Standard window series
        double gW = 0.0;
        double gH = 0.0;
        int gQty = 0;
        double wGlassSqft = 0.0;
        double wJaliCost = 0.0;
        double wLouverCost = 0.0;

        int trMult = 2;
        if (tr == '3Track') trMult = 3;
        if (tr == '4Track') trMult = 4;

        if (sr == '18x40') {
          double hnd = h - 1.5;
          double hor = 0.0;
          if (tr == '2Track') hor = (w - 6.5) / 2.0;
          if (tr == '3Track') hor = (w - 7.5) / 3.0;
          if (tr == '4Track') hor = (w - 8.5) / 4.0;
          gW = hor + 0.65;
          gH = h - 4.0;
          gQty = (trMult * 2 ~/ 2) * qty;

          for (int q = 0; q < qty; q++) {
            addCut('18x40 $tr Bottom', w, 1, winNo: i + 1);
            addCut('18x40 $tr Top', w, 1, winNo: i + 1);
            addCut('18x40 $tr Top', h, 2, winNo: i + 1);
            addCut('18x40 BearingPatti', hor, trMult * 2, winNo: i + 1);
            addCut('18x40 Handle', hnd, 2, winNo: i + 1);
            addCut('18x40 Interlock', hnd, (trMult - 1) * 2, winNo: i + 1);
          }
        } else if (sr == '60mm') {
          double hnd = h - 1.5;
          double hor = 0.0;
          if (tr == '2Track') hor = (w + 1.5) / 2.0;
          if (tr == '3Track') hor = (w + 2.5) / 3.0;
          if (tr == '4Track') hor = (w + 3.5) / 4.0;
          gW = hor - 4.125;
          gH = h - 5.5;
          gQty = (trMult * 2 ~/ 2) * qty;

          for (int q = 0; q < qty; q++) {
            addCut('60mm $tr Bottom', w, 1, winNo: i + 1);
            addCut('60mm $tr Top', w, 1, winNo: i + 1);
            addCut('60mm $tr Top', h, 2, winNo: i + 1);
            addCut('60mm BearingPatti', hor, trMult * 2, winNo: i + 1);
            addCut('60mm Handle', hnd, 2, winNo: i + 1);
            addCut('60mm Interlock', hnd, (trMult - 1) * 2, winNo: i + 1);
          }
        } else if (sr == 'Domal' || sr == 'R40') {
          double hnd = h - 2.75;
          double hor = 0.0;
          if (tr == '2Track') hor = (w + 0.5) / 2.0;
          if (tr == '3Track') hor = (w + 1.5) / 3.0;
          if (tr == '4Track') hor = (w + 2.5) / 4.0;
          gW = hor - 4.125;
          gH = hnd - 4.125;
          gQty = (trMult * 2 ~/ 2) * qty;

          for (int q = 0; q < qty; q++) {
            addCut('$sr $tr Frame', w, 2, winNo: i + 1);
            addCut('$sr $tr Frame', h, 2, winNo: i + 1);
            addCut('$sr Handle', hor, trMult * 2, winNo: i + 1);
            addCut('$sr Handle', hnd, 2, winNo: i + 1);
            addCut('$sr Interlock', hnd, (trMult - 1) * 2, winNo: i + 1);
          }
        } else if (sr == 'Louver') {
          int blades = max(1, ((h - 1.0) / 3.5).round());
          gW = w - 1.5;
          gH = 4.0;
          gQty = blades * qty;
          wLouverCost = blades * qty * rates.louverRateDefault;

          for (int q = 0; q < qty; q++) {
            addCut('18x40 2Track Top', w, 2, winNo: i + 1);
            addCut('18x40 2Track Top', h, 2, winNo: i + 1);
          }
        }

        if (sr != 'Louver') {
          wGlassSqft = (gW * gH) / 144.0 * gQty;
          totalGlassSqft += wGlassSqft;
          if (jali) {
            wJaliCost = sqft * rates.jaliRateDefault;
            totalJali += wJaliCost;
          }
        }

        totalLouver += wLouverCost;
        double wGlassCost = wGlassSqft * rates.glassRateDefault;
        double wLaborCost = sqft * rates.laborRateDefault;
        double wHardCost = sqft * rates.hardRateDefault;

        totalGlassCost += wGlassCost;
        totalLabor += wLaborCost;
        totalHard += wHardCost;

        if (sr != 'Louver' && gQty > 0) {
          glassDetails.add(GlassDetail(
            no: i + 1,
            w: gW,
            h: gH,
            qty: gQty,
            sqft: wGlassSqft,
          ));
        }

        cutSum.add(CutSummaryRow(
          no: i + 1,
          series: sr,
          track: tr,
          w: w,
          h: h,
          qty: qty,
          gw: gW,
          gh: gH,
          gq: gQty,
          jali: jali,
        ));
      }
    }

    // Extra items
    for (var ex in extraItems) {
      totalExtraCost += ex.rate * ex.qty;
    }

    // Section packing & weights
    Map<String, PackedSection> packed = {};
    double totalWt = 0.0;
    double totalAlu = 0.0;
    double totalCoat = 0.0;
    double finishExtraAmt = 0.0;

    const Map<String, Map<String, double>> weightsPerFt = {
      '18x40_Handle': {'Light': 0.16, 'Medium': 0.20, 'Heavy': 0.24},
      '18x40_Interlock': {'Light': 0.16, 'Medium': 0.20, 'Heavy': 0.24},
      '18x40_2Track_Top': {'Light': 0.28, 'Medium': 0.35, 'Heavy': 0.42},
      '18x40_2Track_Bottom': {'Light': 0.30, 'Medium': 0.38, 'Heavy': 0.45},
      '18x40_3Track_Top': {'Light': 0.42, 'Medium': 0.52, 'Heavy': 0.62},
      '18x40_3Track_Bottom': {'Light': 0.45, 'Medium': 0.56, 'Heavy': 0.68},
      '18x40_4Track_Top': {'Light': 0.56, 'Medium': 0.70, 'Heavy': 0.84},
      '18x40_4Track_Bottom': {'Light': 0.60, 'Medium': 0.75, 'Heavy': 0.90},
      '18x40_BearingPatti': {'Light': 0.14, 'Medium': 0.18, 'Heavy': 0.22},
      '60mm_Handle': {'Light': 0.22, 'Medium': 0.28, 'Heavy': 0.34},
      '60mm_Interlock': {'Light': 0.22, 'Medium': 0.28, 'Heavy': 0.34},
      '60mm_2Track_Top': {'Light': 0.35, 'Medium': 0.44, 'Heavy': 0.53},
      '60mm_2Track_Bottom': {'Light': 0.38, 'Medium': 0.48, 'Heavy': 0.58},
      '60mm_3Track_Top': {'Light': 0.52, 'Medium': 0.65, 'Heavy': 0.78},
      '60mm_3Track_Bottom': {'Light': 0.56, 'Medium': 0.70, 'Heavy': 0.84},
      '60mm_4Track_Top': {'Light': 0.70, 'Medium': 0.88, 'Heavy': 1.05},
      '60mm_4Track_Bottom': {'Light': 0.75, 'Medium': 0.94, 'Heavy': 1.12},
      '60mm_BearingPatti': {'Light': 0.18, 'Medium': 0.22, 'Heavy': 0.27},
      'Domal_2Track_Frame': {'Light': 0.45, 'Medium': 0.58, 'Heavy': 0.70},
      'Domal_3Track_Frame': {'Light': 0.65, 'Medium': 0.82, 'Heavy': 0.98},
      'Domal_Handle': {'Light': 0.32, 'Medium': 0.40, 'Heavy': 0.48},
      'Domal_Interlock': {'Light': 0.32, 'Medium': 0.40, 'Heavy': 0.48},
      'R40_2Track_Frame': {'Light': 0.42, 'Medium': 0.52, 'Heavy': 0.64},
      'R40_3Track_Frame': {'Light': 0.60, 'Medium': 0.75, 'Heavy': 0.90},
      'R40_Handle': {'Light': 0.28, 'Medium': 0.36, 'Heavy': 0.44},
      'R40_Interlock': {'Light': 0.28, 'Medium': 0.36, 'Heavy': 0.44},
      'Partition_DP_Pipe': {'Light': 0.38, 'Medium': 0.48, 'Heavy': 0.58},
      'Partition_Door_Pipe': {'Light': 0.42, 'Medium': 0.52, 'Heavy': 0.62},
      'Partition_Clip': {'Light': 0.0, 'Medium': 0.0, 'Heavy': 0.0},
    };

    const Map<String, Map<String, double>> coatingRates = {
      '18x40_Handle': {'Powder': 12.0, 'Anodize': 15.0, 'Wooden': 25.0},
      '18x40_Interlock': {'Powder': 12.0, 'Anodize': 15.0, 'Wooden': 25.0},
      '18x40_2Track_Top': {'Powder': 16.0, 'Anodize': 20.0, 'Wooden': 35.0},
      '18x40_2Track_Bottom': {'Powder': 16.0, 'Anodize': 20.0, 'Wooden': 35.0},
      '18x40_3Track_Top': {'Powder': 22.0, 'Anodize': 28.0, 'Wooden': 48.0},
      '18x40_3Track_Bottom': {'Powder': 22.0, 'Anodize': 28.0, 'Wooden': 48.0},
      '18x40_4Track_Top': {'Powder': 28.0, 'Anodize': 35.0, 'Wooden': 60.0},
      '18x40_4Track_Bottom': {'Powder': 28.0, 'Anodize': 35.0, 'Wooden': 60.0},
      '18x40_BearingPatti': {'Powder': 10.0, 'Anodize': 12.0, 'Wooden': 20.0},
      '60mm_Handle': {'Powder': 15.0, 'Anodize': 18.0, 'Wooden': 30.0},
      '60mm_Interlock': {'Powder': 15.0, 'Anodize': 18.0, 'Wooden': 30.0},
      '60mm_2Track_Top': {'Powder': 20.0, 'Anodize': 25.0, 'Wooden': 42.0},
      '60mm_2Track_Bottom': {'Powder': 20.0, 'Anodize': 25.0, 'Wooden': 42.0},
      '60mm_3Track_Top': {'Powder': 28.0, 'Anodize': 35.0, 'Wooden': 58.0},
      '60mm_3Track_Bottom': {'Powder': 28.0, 'Anodize': 35.0, 'Wooden': 58.0},
      '60mm_4Track_Top': {'Powder': 36.0, 'Anodize': 45.0, 'Wooden': 75.0},
      '60mm_4Track_Bottom': {'Powder': 36.0, 'Anodize': 45.0, 'Wooden': 75.0},
      '60mm_BearingPatti': {'Powder': 12.0, 'Anodize': 15.0, 'Wooden': 25.0},
      'Domal_2Track_Frame': {'Powder': 25.0, 'Anodize': 32.0, 'Wooden': 55.0},
      'Domal_3Track_Frame': {'Powder': 35.0, 'Anodize': 45.0, 'Wooden': 75.0},
      'Domal_Handle': {'Powder': 18.0, 'Anodize': 22.0, 'Wooden': 38.0},
      'Domal_Interlock': {'Powder': 18.0, 'Anodize': 22.0, 'Wooden': 38.0},
      'R40_2Track_Frame': {'Powder': 22.0, 'Anodize': 28.0, 'Wooden': 48.0},
      'R40_3Track_Frame': {'Powder': 32.0, 'Anodize': 40.0, 'Wooden': 68.0},
      'R40_Handle': {'Powder': 16.0, 'Anodize': 20.0, 'Wooden': 35.0},
      'R40_Interlock': {'Powder': 16.0, 'Anodize': 20.0, 'Wooden': 35.0},
      'Partition_DP_Pipe': {'Powder': 22.0, 'Anodize': 28.0, 'Wooden': 45.0},
      'Partition_Door_Pipe': {'Powder': 25.0, 'Anodize': 32.0, 'Wooden': 52.0},
      'Partition_Clip': {'Powder': 0.0, 'Anodize': 0.0, 'Wooden': 0.0},
    };

    for (var sec in master.keys) {
      List<double> scrapForSec = List<double>.from(scrapMap[sec] ?? []);
      List<Map<String, dynamic>> needed = List<Map<String, dynamic>>.from(master[sec] ?? []);

      needed.sort((a, b) => ((b['len'] as num).toDouble()).compareTo((a['len'] as num).toDouble()));
      scrapForSec.sort((a, b) => b.compareTo(a));

      List<Map<String, dynamic>> remaining = [];
      int scrapUsed = 0;
      List<double> scrapCopy = List<double>.from(scrapForSec);

      for (var need in needed) {
        double needLen = (need['len'] as num).toDouble();
        int foundIdx = scrapCopy.indexWhere((s) => s >= needLen);
        if (foundIdx != -1) {
          scrapCopy.removeAt(foundIdx);
          scrapUsed++;
        } else {
          remaining.add(need);
        }
      }

      String wtKey = sec.replaceAll(' ', '_').replaceAll('_Center_Open', '');
      var wtDict = weightsPerFt[wtKey] ?? {};
      double wtPf = wtDict[wType] ?? (wtDict['Medium'] ?? 0.0);

      var coatDict = coatingRates[wtKey] ?? {};
      double cRate = (coat != 'Mill Finish') ? (coatDict[coat] ?? 0.0) : 0.0;

      double aluRt = rates.aluRate;
      if (wtKey == 'Partition_DP_Pipe') {
        aluRt = rates.partDpRate;
      } else if (wtKey == 'Partition_Door_Pipe') {
        aluRt = rates.partDoorRate;
      } else if (wtKey == 'Partition_Clip') {
        aluRt = 0.0;
        wtPf = 0.0;
      }

      var bins = packBfd(remaining, allowed, kerf: 0.15);
      List<PipeCutBin> best = [];

      for (var b in bins) {
        int sz = ((b['size'] as num).toDouble() / 12.0).ceil();
        best.add(PipeCutBin(
          sizeFt: sz,
          cuts: b['cuts'] as List,
          waste: (b['rem'] as num).toDouble(),
          weight: sz * wtPf,
        ));
      }

      packed[sec] = PackedSection(
        pipes: best,
        scrapUsed: scrapUsed,
        totalNeeded: needed.length,
      );

      for (var p in best) {
        totalWt += p.weight;
        totalAlu += p.weight * aluRt;
        if (wtKey == 'Partition_Clip') {
          totalAlu += (p.sizeFt / 12.0) * rates.partClipRate;
        }
        if (sec.contains('Partition')) {
          finishExtraAmt += p.sizeFt * cRate;
        } else {
          totalCoat += p.sizeFt * cRate;
        }
      }
    }

    double baseCost = totalAlu +
        totalGlassCost +
        totalCoat +
        totalLabor +
        totalHard +
        totalJali +
        totalLouver +
        totalPartSheetCost +
        totalPartHardware +
        finishExtraAmt +
        totalExtraCost;

    double profitAmt = baseCost * (profit / 100.0);
    double subTotal = baseCost + profitAmt + transport + extra;
    double gstAmount = useGst ? (subTotal * 0.18) : 0.0;
    double grandTotal = subTotal + gstAmount;

    double actualTotal = totalSqft;
    double billingTotal = totalBillingSqft;
    double billingFactor = (actualTotal > 0 && billingTotal > 0) ? (billingTotal / actualTotal) : 1.0;
    double billingSub = subTotal * billingFactor;
    double billingGst = useGst ? (billingSub * 0.18) : 0.0;
    double billingGrand = billingSub + billingGst;

    if (billingMode == 'actual' && !minBilling) {
      billingTotal = actualTotal;
      billingGrand = grandTotal;
      billingSub = subTotal;
      billingGst = gstAmount;
    }

    return CalculationResult(
      totalSqft: totalSqft,
      totalWeight: totalWt,
      totalAluCost: totalAlu,
      totalGlassCost: totalGlassCost,
      totalCoatCost: totalCoat + finishExtraAmt,
      totalLaborCost: totalLabor,
      totalHardwareCost: totalHard + totalPartHardware,
      totalJaliCost: totalJali,
      totalLouverCost: totalLouver,
      totalPartSheetCost: totalPartSheetCost,
      totalExtraCost: totalExtraCost,
      baseCost: baseCost,
      profitAmt: profitAmt,
      transport: transport,
      extra: extra,
      subTotal: subTotal,
      gstAmount: gstAmount,
      totalWindows: totalQty,
      grandTotal: grandTotal,
      packedData: packed,
      cuttingSummary: cutSum,
      glassDetails: glassDetails,
      totalGlassSqft: totalGlassSqft,
      billingSqft: billingTotal,
      billingSubTotal: billingSub,
      billingGst: billingGst,
      billingGrandTotal: billingGrand,
      billingMode: billingMode,
      minBillingEnabled: minBilling,
      minApplied: minApplied,
      billingDetails: billingDetails,
    );
  }
}
