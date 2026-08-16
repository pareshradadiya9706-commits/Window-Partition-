import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/app_state.dart';
import '../models/window_item.dart';
import '../models/calculation_result.dart';
import '../theme/app_theme.dart';

/// Lightweight, 100% Offline Pure-Dart PDF 1.4 Engine
/// Generates standard A4 PDF documents with zero external dependencies.
class SimplePdfWriter {
  final List<String> _objects = [];
  final List<int> _pageObjectIds = [];
  final List<String> _pageContents = [];

  void addPage(String contentStream) {
    _pageContents.add(contentStream);
  }

  Uint8List buildPdf() {
    final StringBuffer out = StringBuffer();
    out.writeln('%PDF-1.4');
    out.writeln('%\xFF\xFF\xFF\xFF');

    // 1 0 obj: Catalog
    // 2 0 obj: Pages
    // 3 0 obj: Font Helvetica
    // 4 0 obj: Font Helvetica-Bold
    // 5 0 obj: Font Helvetica-Oblique
    // 6 0 obj: Font Courier
    // For each page:
    //   Page obj: /Type /Page ...
    //   Content obj: stream ... endstream

    final int catalogId = 1;
    final int pagesRootId = 2;
    final int fontRegId = 3;
    final int fontBoldId = 4;
    final int fontItalicId = 5;
    final int fontMonoId = 6;

    int currentObjId = 7;
    final List<int> pageIds = [];
    final List<int> contentIds = [];

    for (int i = 0; i < _pageContents.length; i++) {
      pageIds.add(currentObjId++);
      contentIds.add(currentObjId++);
    }

    final List<int> offsets = [];

    void writeObj(int id, String content) {
      offsets.add(out.length);
      out.writeln('$id 0 obj');
      out.writeln(content);
      out.writeln('endobj');
    }

    // Write Catalog
    writeObj(catalogId, '<< /Type /Catalog /Pages $pagesRootId 0 R >>');

    // Write Pages Root
    final kidsStr = pageIds.map((id) => '$id 0 R').join(' ');
    writeObj(pagesRootId, '<< /Type /Pages /Kids [ $kidsStr ] /Count ${pageIds.length} >>');

    // Write Fonts
    writeObj(fontRegId, '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica /Encoding /WinAnsiEncoding >>');
    writeObj(fontBoldId, '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold /Encoding /WinAnsiEncoding >>');
    writeObj(fontItalicId, '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Oblique /Encoding /WinAnsiEncoding >>');
    writeObj(fontMonoId, '<< /Type /Font /Subtype /Type1 /BaseFont /Courier /Encoding /WinAnsiEncoding >>');

    // Write Pages & Contents
    for (int i = 0; i < _pageContents.length; i++) {
      final pId = pageIds[i];
      final cId = contentIds[i];
      final stream = _pageContents[i];
      final streamBytes = utf8.encode(stream);

      // Page object (A4: 595.28 x 841.89 points)
      writeObj(pId, '<< /Type /Page /Parent $pagesRootId 0 R /MediaBox [0 0 595.28 841.89] /Contents $cId 0 R /Resources << /Font << /F1 $fontRegId 0 R /F2 $fontBoldId 0 R /F3 $fontItalicId 0 R /F4 $fontMonoId 0 R >> >> >>');

      // Content object
      writeObj(cId, '<< /Length ${streamBytes.length} >>\nstream\n$stream\nendstream');
    }

    // Write xref
    final int xrefOffset = out.length;
    final int totalObjs = currentObjId;
    out.writeln('xref');
    out.writeln('0 $totalObjs');
    out.writeln('0000000000 65535 f ');
    for (int off in offsets) {
      out.writeln('${off.toString().padLeft(10, '0')} 00000 n ');
    }

    // Write trailer
    out.writeln('trailer');
    out.writeln('<< /Size $totalObjs /Root $catalogId 0 R >>');
    out.writeln('startxref');
    out.writeln('$xrefOffset');
    out.writeln('%%EOF');

    return Uint8List.fromList(utf8.encode(out.toString()));
  }
}

/// Helper for drawing pages and layouts in PDF coordinate system (A4: 595 x 842 pt)
class PdfPageContext {
  final StringBuffer _sb = StringBuffer();
  double currentY = 790.0;
  final double leftMargin = 36.0;
  final double rightMargin = 559.0;
  final double pageWidth = 595.28;
  final double pageHeight = 841.89;

  String escape(String text) {
    return text.replaceAll('\\', '\\\\').replaceAll('(', '\\(').replaceAll(')', '\\)');
  }

  void drawRect(double x, double y, double w, double h, {List<double>? fillColor, List<double>? strokeColor, double lineWidth = 1.0}) {
    if (fillColor != null) {
      _sb.writeln('${fillColor[0]} ${fillColor[1]} ${fillColor[2]} rg');
    }
    if (strokeColor != null) {
      _sb.writeln('${strokeColor[0]} ${strokeColor[1]} ${strokeColor[2]} RG');
      _sb.writeln('$lineWidth w');
    }
    _sb.writeln('$x $y $w $h re ${fillColor != null && strokeColor != null ? 'B' : (fillColor != null ? 'f' : 'S')}');
  }

  void drawLine(double x1, double y1, double x2, double y2, {List<double>? strokeColor, double lineWidth = 1.0}) {
    final color = strokeColor ?? [0.2, 0.2, 0.2];
    _sb.writeln('${color[0]} ${color[1]} ${color[2]} RG');
    _sb.writeln('$lineWidth w');
    _sb.writeln('$x1 $y1 m $x2 $y2 l S');
  }

  void drawText(String text, double x, double y, {String font = '/F1', double size = 10, List<double>? color}) {
    final textColor = color ?? [0.1, 0.1, 0.1];
    _sb.writeln('BT');
    _sb.writeln('$font $size Tf');
    _sb.writeln('${textColor[0]} ${textColor[1]} ${textColor[2]} rg');
    _sb.writeln('$x $y Td');
    _sb.writeln('(${escape(text)}) Tj');
    _sb.writeln('ET');
  }

  void drawTextRight(String text, double xRight, double y, {String font = '/F1', double size = 10, List<double>? color, double charWidthApprox = 5.5}) {
    final double textWidth = text.length * charWidthApprox * (size / 10.0);
    final double x = xRight - textWidth;
    drawText(text, x > leftMargin ? x : leftMargin, y, font: font, size: size, color: color);
  }

  void drawDharamWindowHeader({
    required String docTitle,
    required String refLabel,
    required String dateStr,
  }) {
    // 1. Clean White Header Background Card with Navy Top Border
    drawRect(36, 742, 523, 66, fillColor: [0.98, 0.99, 1.0], strokeColor: [0.0, 0.17, 0.29], lineWidth: 1.2);
    drawRect(36, 805, 523, 3, fillColor: [0.0, 0.17, 0.29]);

    // 2. Official DW Monogram Left Block
    drawRect(44, 748, 42, 52, fillColor: [0.0, 0.17, 0.29]); // Navy D block
    drawRect(50, 755, 30, 38, fillColor: [0.22, 0.74, 0.96], strokeColor: [0.8, 0.85, 0.9], lineWidth: 1.5);
    drawLine(65, 755, 65, 793, strokeColor: [1.0, 1.0, 1.0], lineWidth: 1.0);
    drawLine(50, 774, 80, 774, strokeColor: [1.0, 1.0, 1.0], lineWidth: 1.0);

    // Silver/Metallic 'W' beside 'D'
    drawText('W', 90, 752, font: '/F2', size: 38, color: [0.45, 0.52, 0.60]);

    // 3. DHARAM WINDOW Brand Typography
    drawText('DHARAM WINDOW', 134, 783, font: '/F2', size: 16, color: [0.0, 0.17, 0.29]);
    
    // Tagline: CALCULATE • OPTIMIZE • ESTIMATE
    drawText('CALCULATE  •  OPTIMIZE  •  ESTIMATE', 134, 768, font: '/F2', size: 7.5, color: [0.01, 0.52, 0.78]);
    drawText('ARCHITECTURAL WINDOW SECTION SOLUTIONS', 134, 755, font: '/F3', size: 6.5, color: [0.35, 0.45, 0.55]);

    // 4. Right Document Badge & Metadata
    drawTextRight(docTitle, 548, 784, font: '/F2', size: 9.5, color: [0.0, 0.17, 0.29]);
    drawTextRight('DATE: $dateStr', 548, 769, font: '/F1', size: 8, color: [0.25, 0.35, 0.45]);
    drawTextRight(refLabel, 548, 755, font: '/F2', size: 7.5, color: [0.01, 0.52, 0.78]);
  }

  String getStream() => _sb.toString();
}

/// Service that builds verified Quotation, Bill, and Cutting List PDFs
class PdfService {
  /// Builds a complete offline Quotation / Estimate PDF document
  static Uint8List generateQuotationPdf(AppState state) {
    final writer = SimplePdfWriter();
    final res = state.result;
    final displayGrandTotal = state.billingMode == 'actual' && !state.minBilling
        ? res.grandTotal
        : res.billingGrandTotal;

    final customer = state.customerName.isNotEmpty ? state.customerName : 'Valued Customer';
    final project = state.projectName.isNotEmpty ? state.projectName : 'Architectural Fabrication';
    final phone = state.phone.isNotEmpty ? state.phone : 'N/A';
    final now = DateTime.now();
    final dateStr = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

    PdfPageContext page = PdfPageContext();

    // 1. Official Header Banner with DHARAM WINDOW Logo & Tagline
    page.drawDharamWindowHeader(
      docTitle: 'OFFICIAL ESTIMATE & QUOTATION',
      refLabel: 'REF: EST-${now.millisecondsSinceEpoch.toString().substring(7)}',
      dateStr: dateStr,
    );

    // 2. Client & Metadata Box
    page.drawRect(36, 670, 523, 62, fillColor: [0.96, 0.97, 0.99], strokeColor: [0.8, 0.85, 0.9], lineWidth: 1);
    page.drawText('CUSTOMER & PROJECT DETAILS', 46, 718, font: '/F2', size: 9, color: [0.1, 0.2, 0.4]);
    page.drawText('Client Name: $customer', 46, 704, font: '/F2', size: 9);
    page.drawText('Contact Phone: $phone', 46, 690, font: '/F1', size: 8.5);
    page.drawText('Project Site: $project', 46, 678, font: '/F1', size: 8.5);

    page.drawText('Coating Finish: ${state.coating}', 320, 704, font: '/F2', size: 9);
    page.drawText('Section Weight: ${state.weightType}', 320, 690, font: '/F1', size: 8.5);
    page.drawText('Billing Calculation: ${state.billingMode == "three_inch" ? "+3 Inch Rule" : "Actual Measurements"}', 320, 678, font: '/F1', size: 8.5);

    // 3. Item Schedule Table
    double y = 640;
    page.drawRect(36, y, 523, 20, fillColor: [0.15, 0.23, 0.36]);
    page.drawText('#', 44, y + 6, font: '/F2', size: 8, color: [1, 1, 1]);
    page.drawText('DESCRIPTION / SERIES', 65, y + 6, font: '/F2', size: 8, color: [1, 1, 1]);
    page.drawText('SIZE (W x H)', 255, y + 6, font: '/F2', size: 8, color: [1, 1, 1]);
    page.drawText('QTY', 355, y + 6, font: '/F2', size: 8, color: [1, 1, 1]);
    page.drawText('AREA (SQFT)', 410, y + 6, font: '/F2', size: 8, color: [1, 1, 1]);
    page.drawTextRight('OPTIONS', 545, y + 6, font: '/F2', size: 8, color: [1, 1, 1]);

    y -= 18;
    for (int i = 0; i < state.cart.length; i++) {
      final item = state.cart[i];
      final isEven = i % 2 == 0;
      page.drawRect(36, y - 2, 523, 18, fillColor: isEven ? [0.98, 0.99, 1.0] : [0.93, 0.95, 0.98]);

      page.drawText('${i + 1}', 44, y + 3, font: '/F1', size: 8);
      if (item is WindowItem) {
        if (item.series == 'Repairing') {
          page.drawText('Repair: ${item.desc}', 65, y + 3, font: '/F2', size: 8);
          page.drawText('-', 255, y + 3, font: '/F1', size: 8);
          page.drawText('${item.qty}', 355, y + 3, font: '/F1', size: 8);
          page.drawText('0.0', 410, y + 3, font: '/F1', size: 8);
          page.drawTextRight('Service', 545, y + 3, font: '/F1', size: 8);
        } else {
          page.drawText('${item.series} ${item.track}', 65, y + 3, font: '/F2', size: 8);
          page.drawText('${item.w.toStringAsFixed(1)}" x ${item.h.toStringAsFixed(1)}"', 255, y + 3, font: '/F1', size: 8);
          page.drawText('${item.qty}', 355, y + 3, font: '/F1', size: 8);
          page.drawText(item.sqft.toStringAsFixed(2), 410, y + 3, font: '/F1', size: 8);
          page.drawTextRight(item.jali ? 'Mesh (+Jali)' : 'Standard', 545, y + 3, font: '/F1', size: 8);
        }
      } else if (item is PartitionItem) {
        page.drawText('Aluminum Partition', 65, y + 3, font: '/F2', size: 8);
        page.drawText('${item.w.toStringAsFixed(1)}" x ${item.h.toStringAsFixed(1)}"', 255, y + 3, font: '/F1', size: 8);
        page.drawText('${item.qty}', 355, y + 3, font: '/F1', size: 8);
        page.drawText(item.sqft.toStringAsFixed(2), 410, y + 3, font: '/F1', size: 8);
        page.drawTextRight('Door: ${item.dw.toStringAsFixed(0)}x${item.dh.toStringAsFixed(0)}"', 545, y + 3, font: '/F1', size: 8);
      }
      y -= 18;
    }

    // Extra items if any
    if (state.extraItems.isNotEmpty) {
      y -= 8;
      page.drawText('ADDITIONAL HARDWARE / EXTRAS:', 36, y, font: '/F2', size: 8.5, color: [0.1, 0.2, 0.4]);
      y -= 14;
      for (var ex in state.extraItems) {
        page.drawText('• ${ex.name} (Qty: ${ex.qty} @ Rs.${ex.rate.toStringAsFixed(0)})', 46, y, font: '/F1', size: 8);
        page.drawTextRight('Rs. ${ex.total.toStringAsFixed(0)}', 545, y, font: '/F2', size: 8);
        y -= 14;
      }
    }

    // 4. Financial & Area Summary Box
    y -= 15;
    page.drawRect(36, y - 85, 523, 90, fillColor: [0.96, 0.98, 1.0], strokeColor: [0.2, 0.4, 0.7], lineWidth: 1.2);
    page.drawText('ESTIMATE FINANCIAL SUMMARY', 46, y - 8, font: '/F2', size: 9, color: [0.1, 0.2, 0.4]);

    page.drawText('Total Physical Area:', 46, y - 24, font: '/F1', size: 8.5);
    page.drawText('${res.totalSqft.toStringAsFixed(2)} Sq.Ft', 180, y - 24, font: '/F2', size: 8.5);

    page.drawText('Total Billing Area:', 46, y - 38, font: '/F1', size: 8.5);
    page.drawText('${res.billingSqft.toStringAsFixed(2)} Sq.Ft (${state.billingMode == "three_inch" ? "+3 Inch" : "Actual"})', 180, y - 38, font: '/F2', size: 8.5);

    if (state.useGst) {
      page.drawText('Sub Total (Pre-Tax):', 330, y - 24, font: '/F1', size: 8.5);
      page.drawTextRight('Rs. ${res.subTotal.toStringAsFixed(2)}', 545, y - 24, font: '/F1', size: 8.5);

      page.drawText('GST (18% Applicable):', 330, y - 38, font: '/F1', size: 8.5);
      page.drawTextRight('Rs. ${res.gstAmount.toStringAsFixed(2)}', 545, y - 38, font: '/F1', size: 8.5);
    }

    page.drawRect(46, y - 80, 503, 30, fillColor: [0.06, 0.09, 0.16]);
    page.drawText('ESTIMATED GRAND TOTAL:', 60, y - 62, font: '/F2', size: 11, color: [1, 1, 1]);
    page.drawTextRight('Rs. ${displayGrandTotal.toStringAsFixed(0)} /-', 535, y - 62, font: '/F2', size: 13, color: [0.22, 0.74, 0.96]);

    // 5. Terms & Signature Footer
    page.drawText('TERMS & CONDITIONS:', 36, 95, font: '/F2', size: 8, color: [0.3, 0.3, 0.3]);
    page.drawText('1. Quotation is valid for 15 days from issue date.', 36, 83, font: '/F1', size: 7.5, color: [0.4, 0.4, 0.4]);
    page.drawText('2. 50% advance payment upon order confirmation.', 36, 73, font: '/F1', size: 7.5, color: [0.4, 0.4, 0.4]);
    page.drawText('3. Final measurements subject to physical site verification.', 36, 63, font: '/F1', size: 7.5, color: [0.4, 0.4, 0.4]);

    page.drawTextRight('Authorized Signatory', 545, 55, font: '/F2', size: 8.5);
    page.drawLine(410, 68, 545, 68, strokeColor: [0.4, 0.4, 0.4]);

    page.drawText('Generated completely offline via Dharam Window (DW Ultimate Pro) - Page 1 of 1', 36, 25, font: '/F3', size: 7, color: [0.6, 0.6, 0.6]);

    writer.addPage(page.getStream());
    return writer.buildPdf();
  }

  /// Builds a complete offline Bill & Material Cost Analysis PDF document
  static Uint8List generateBillPdf(AppState state) {
    final writer = SimplePdfWriter();
    final res = state.result;
    final displayGrandTotal = state.billingMode == 'actual' && !state.minBilling
        ? res.grandTotal
        : res.billingGrandTotal;

    final customer = state.customerName.isNotEmpty ? state.customerName : 'Valued Client';
    final project = state.projectName.isNotEmpty ? state.projectName : 'Fabrication Order';
    final now = DateTime.now();
    final dateStr = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

    PdfPageContext page = PdfPageContext();

    // 1. Official Header Banner with DHARAM WINDOW Logo & Tagline
    page.drawDharamWindowHeader(
      docTitle: 'FABRICATION INVOICE & BILL',
      refLabel: 'INV: INV-${now.millisecondsSinceEpoch.toString().substring(7)}',
      dateStr: dateStr,
    );

    // 2. Client Info Card
    page.drawRect(36, 675, 523, 55, fillColor: [0.96, 0.97, 0.99], strokeColor: [0.8, 0.85, 0.9], lineWidth: 1);
    page.drawText('BILL TO: $customer', 46, 712, font: '/F2', size: 9.5);
    page.drawText('Project Site: $project', 46, 698, font: '/F1', size: 8.5);
    page.drawText('Total Windows/Units: ${state.cart.length}', 46, 685, font: '/F1', size: 8.5);

    page.drawText('Finish: ${state.coating} (${state.weightType})', 320, 712, font: '/F2', size: 9);
    page.drawText('Total Aluminum Weight: ${res.totalWeight.toStringAsFixed(2)} Kg', 320, 698, font: '/F1', size: 8.5);
    page.drawText('Total Glass Area: ${res.totalGlassSqft.toStringAsFixed(2)} Sq.Ft', 320, 685, font: '/F1', size: 8.5);

    // 3. Cost Breakdown Table
    double y = 640;
    page.drawRect(36, y, 523, 20, fillColor: [0.15, 0.23, 0.36]);
    page.drawText('#', 44, y + 6, font: '/F2', size: 8, color: [1, 1, 1]);
    page.drawText('COST COMPONENT / MATERIAL CATEGORY', 65, y + 6, font: '/F2', size: 8, color: [1, 1, 1]);
    page.drawText('CALCULATION BASIS', 300, y + 6, font: '/F2', size: 8, color: [1, 1, 1]);
    page.drawTextRight('AMOUNT (INR)', 545, y + 6, font: '/F2', size: 8, color: [1, 1, 1]);

    final List<Map<String, dynamic>> costItems = [
      {'title': 'Aluminum Extrusion Material', 'desc': '${res.totalWeight.toStringAsFixed(2)} Kg @ Rs.${state.rates.aluRate.toStringAsFixed(0)}/Kg', 'amt': res.totalAluCost},
      {'title': 'Glass Material & Panes', 'desc': '${res.totalGlassSqft.toStringAsFixed(1)} SqFt Panes', 'amt': res.totalGlassCost},
      {'title': 'Labor Charges', 'desc': '${res.totalSqft.toStringAsFixed(1)} SqFt Base Work', 'amt': res.totalLaborCost},
      {'title': 'Hardware & Rollers', 'desc': 'Bearings, Locks & Fasteners', 'amt': res.totalHardwareCost},
    ];

    if (res.totalCoatCost > 0) {
      costItems.add({'title': 'Powder / Anodize Coating', 'desc': '${state.coating} Treatment', 'amt': res.totalCoatCost});
    }
    if (res.totalJaliCost > 0) {
      costItems.add({'title': 'Mosquito Mesh / Jali', 'desc': 'SS / Fiber Mesh Panels', 'amt': res.totalJaliCost});
    }
    if (res.totalPartSheetCost > 0) {
      costItems.add({'title': 'Partition ACP / Sheets', 'desc': 'Door & Wall Panels', 'amt': res.totalPartSheetCost});
    }
    if (res.totalExtraCost > 0) {
      costItems.add({'title': 'Extra Hardware & Custom Items', 'desc': '${state.extraItems.length} Accessories', 'amt': res.totalExtraCost});
    }

    y -= 18;
    for (int i = 0; i < costItems.length; i++) {
      final item = costItems[i];
      final isEven = i % 2 == 0;
      page.drawRect(36, y - 2, 523, 18, fillColor: isEven ? [0.98, 0.99, 1.0] : [0.93, 0.95, 0.98]);

      page.drawText('${i + 1}', 44, y + 3, font: '/F1', size: 8);
      page.drawText(item['title'] as String, 65, y + 3, font: '/F2', size: 8);
      page.drawText(item['desc'] as String, 300, y + 3, font: '/F1', size: 8);
      page.drawTextRight('Rs. ${(item['amt'] as double).toStringAsFixed(2)}', 545, y + 3, font: '/F2', size: 8);
      y -= 18;
    }

    // 4. Commercial Markup & Summary Box
    y -= 15;
    page.drawRect(36, y - 100, 523, 105, fillColor: [0.96, 0.98, 1.0], strokeColor: [0.2, 0.4, 0.7], lineWidth: 1.2);
    page.drawText('COMMERCIAL CALCULATION BREAKDOWN', 46, y - 8, font: '/F2', size: 9, color: [0.1, 0.2, 0.4]);

    page.drawText('Base Fabrication Cost:', 46, y - 24, font: '/F1', size: 8.5);
    page.drawText('Rs. ${res.baseCost.toStringAsFixed(2)}', 200, y - 24, font: '/F2', size: 8.5);

    page.drawText('Profit Margin (${state.profit.toStringAsFixed(0)}%):', 46, y - 38, font: '/F1', size: 8.5);
    page.drawText('Rs. ${res.profitAmt.toStringAsFixed(2)}', 200, y - 38, font: '/F2', size: 8.5);

    if (state.transport > 0) {
      page.drawText('Transport & Delivery:', 320, y - 24, font: '/F1', size: 8.5);
      page.drawTextRight('Rs. ${state.transport.toStringAsFixed(2)}', 545, y - 24, font: '/F2', size: 8.5);
    }
    if (state.useGst) {
      page.drawText('GST (18% Tax):', 320, y - 38, font: '/F1', size: 8.5);
      page.drawTextRight('Rs. ${res.gstAmount.toStringAsFixed(2)}', 545, y - 38, font: '/F2', size: 8.5);
    }

    page.drawRect(46, y - 92, 503, 30, fillColor: [0.06, 0.09, 0.16]);
    page.drawText('FINAL BILL AMOUNT (INCL. MARGINS):', 60, y - 74, font: '/F2', size: 11, color: [1, 1, 1]);
    page.drawTextRight('Rs. ${displayGrandTotal.toStringAsFixed(0)} /-', 535, y - 74, font: '/F2', size: 13, color: [0.22, 0.74, 0.96]);

    page.drawText('Generated completely offline via Dharam Window (DW Ultimate Pro) - Page 1 of 1', 36, 25, font: '/F3', size: 7, color: [0.6, 0.6, 0.6]);

    writer.addPage(page.getStream());
    return writer.buildPdf();
  }

  /// Builds a complete offline Profile & Glass Cutting Schedule PDF document
  static Uint8List generateCuttingListPdf(AppState state) {
    final writer = SimplePdfWriter();
    final res = state.result;
    final now = DateTime.now();
    final dateStr = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

    PdfPageContext page = PdfPageContext();

    // 1. Official Header Banner with DHARAM WINDOW Logo & Tagline
    page.drawDharamWindowHeader(
      docTitle: 'PROFILE & GLASS CUTTING REPORT',
      refLabel: 'STOCK: ${state.allowedPipes.join(", ")} FT',
      dateStr: dateStr,
    );

    // 2. Extrusion Profile Cutting Optimization Table
    double y = 720;
    page.drawText('1. ALUMINUM EXTRUSION PROFILE CUTTING SCHEDULE (KERF: 0.15")', 36, y, font: '/F2', size: 9.5, color: [0.1, 0.2, 0.4]);
    y -= 16;

    page.drawRect(36, y, 523, 18, fillColor: [0.15, 0.23, 0.36]);
    page.drawText('PROFILE / SECTION', 44, y + 5, font: '/F2', size: 7.5, color: [1, 1, 1]);
    page.drawText('BAR #', 160, y + 5, font: '/F2', size: 7.5, color: [1, 1, 1]);
    page.drawText('STOCK', 200, y + 5, font: '/F2', size: 7.5, color: [1, 1, 1]);
    page.drawText('CUTS ARRANGEMENT (INCHES)', 245, y + 5, font: '/F2', size: 7.5, color: [1, 1, 1]);
    page.drawText('WASTE', 450, y + 5, font: '/F2', size: 7.5, color: [1, 1, 1]);
    page.drawTextRight('WEIGHT', 545, y + 5, font: '/F2', size: 7.5, color: [1, 1, 1]);

    y -= 16;
    int rowCount = 0;
    res.packedData.forEach((sectionName, packedSec) {
      for (int b = 0; b < packedSec.pipes.length; b++) {
        if (y < 240) break; // Keep on page 1 for standard summary
        final bin = packedSec.pipes[b];
        final isEven = rowCount % 2 == 0;
        page.drawRect(36, y - 2, 523, 16, fillColor: isEven ? [0.98, 0.99, 1.0] : [0.93, 0.95, 0.98]);

        page.drawText(b == 0 ? sectionName : '', 44, y + 3, font: '/F2', size: 7.5);
        page.drawText('Bar ${b + 1}', 160, y + 3, font: '/F1', size: 7.5);
        page.drawText('${bin.sizeFt}ft', 200, y + 3, font: '/F2', size: 7.5);
        final cutsStr = bin.cuts.map((c) => c.toString()).join(' + ');
        page.drawText(cutsStr.length > 40 ? '${cutsStr.substring(0, 37)}...' : cutsStr, 245, y + 3, font: '/F4', size: 7);
        page.drawText('${bin.waste.toStringAsFixed(1)}"', 450, y + 3, font: '/F1', size: 7.5);
        page.drawTextRight('${bin.weight.toStringAsFixed(2)}kg', 545, y + 3, font: '/F1', size: 7.5);

        y -= 16;
        rowCount++;
      }
    });

    // 3. Glass Cutting Dimensions Schedule
    y -= 15;
    page.drawText('2. GLASS CUTTING DIMENSIONS SCHEDULE', 36, y, font: '/F2', size: 9.5, color: [0.1, 0.2, 0.4]);
    y -= 16;

    page.drawRect(36, y, 523, 18, fillColor: [0.15, 0.23, 0.36]);
    page.drawText('#', 44, y + 5, font: '/F2', size: 7.5, color: [1, 1, 1]);
    page.drawText('WINDOW SERIES', 65, y + 5, font: '/F2', size: 7.5, color: [1, 1, 1]);
    page.drawText('OUTER SIZE', 180, y + 5, font: '/F2', size: 7.5, color: [1, 1, 1]);
    page.drawText('GLASS CUTTING SIZE (W x H)', 270, y + 5, font: '/F2', size: 7.5, color: [1, 1, 1]);
    page.drawText('PANES', 430, y + 5, font: '/F2', size: 7.5, color: [1, 1, 1]);
    page.drawTextRight('TOTAL GLASS SQFT', 545, y + 5, font: '/F2', size: 7.5, color: [1, 1, 1]);

    y -= 16;
    for (int i = 0; i < res.cuttingSummary.length; i++) {
      if (y < 60) break;
      final row = res.cuttingSummary[i];
      final isEven = i % 2 == 0;
      page.drawRect(36, y - 2, 523, 16, fillColor: isEven ? [0.98, 0.99, 1.0] : [0.93, 0.95, 0.98]);

      page.drawText('${row.no}', 44, y + 3, font: '/F1', size: 7.5);
      page.drawText('${row.series} ${row.track}', 65, y + 3, font: '/F2', size: 7.5);
      page.drawText('${row.w}" x ${row.h}"', 180, y + 3, font: '/F1', size: 7.5);
      page.drawText('${row.gw ?? "-"} x ${row.gh ?? "-"}', 270, y + 3, font: '/F4', size: 7.5);
      page.drawText('${row.gq ?? 0} panes', 430, y + 3, font: '/F1', size: 7.5);
      final double rowSqft = row.qty * (row.w is num && row.h is num ? ((row.w as num).toDouble() * (row.h as num).toDouble() / 144.0) : 0.0);
      page.drawTextRight('${rowSqft.toStringAsFixed(1)} sqft', 545, y + 3, font: '/F1', size: 7.5);

      y -= 16;
    }

    page.drawText('Generated completely offline via Dharam Window (DW Ultimate Pro) - Page 1 of 1', 36, 25, font: '/F3', size: 7, color: [0.6, 0.6, 0.6]);

    writer.addPage(page.getStream());
    return writer.buildPdf();
  }

  /// Displays the interactive PDF Export modal dialog
  static void showPdfExportModal({
    required BuildContext context,
    required String title,
    required String fileName,
    required Uint8List pdfBytes,
    required String description,
  }) {
    final sizeKb = (pdfBytes.lengthInBytes / 1024).toStringAsFixed(1);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.picture_as_pdf, color: AppTheme.accentRose, size: 22),
            SizedBox(width: 8),
            Text('PDF Document Ready', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              description,
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.maxFinite,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• File: $fileName.pdf', style: const TextStyle(fontSize: 12, color: AppTheme.accentCyan, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('• Format: Standard A4 Print PDF', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                  Text('• Size: $sizeKb KB (Vector)', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                  Text('• Status: 100% Offline Generated', style: const TextStyle(fontSize: 11, color: AppTheme.accentEmerald)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$fileName.pdf generated and ready for local save! ($sizeKb KB)'),
                  backgroundColor: AppTheme.accentEmerald,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 3),
                ),
              );
            },
            icon: const Icon(Icons.download_done, size: 16),
            label: const Text('Confirm PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentCyan,
              foregroundColor: const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}
