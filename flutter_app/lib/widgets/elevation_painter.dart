import 'package:flutter/material.dart';
import '../models/window_item.dart';
import '../theme/app_theme.dart';

class ElevationPainter extends CustomPainter {
  final dynamic item;
  final bool isDark;

  ElevationPainter({required this.item, this.isDark = true});

  @override
  void paint(Canvas canvas, Size size) {
    if (item == null) return;

    final double width = (item is WindowItem) ? item.w : (item as PartitionItem).w;
    final double height = (item is WindowItem) ? item.h : (item as PartitionItem).h;
    if (width <= 0 || height <= 0) return;

    final double padding = 24.0;
    final double availW = size.width - (padding * 2);
    final double availH = size.height - (padding * 2);

    final double scale = (availW / width < availH / height) ? availW / width : availH / height;
    final double drawW = width * scale;
    final double drawH = height * scale;

    final double startX = (size.width - drawW) / 2;
    final double startY = (size.height - drawH) / 2;

    final framePaint = Paint()
      ..color = isDark ? const Color(0xFF94A3B8) : const Color(0xFF334155)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final frameFillPaint = Paint()
      ..color = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)
      ..style = PaintingStyle.fill;

    final glassPaint = Paint()
      ..color = const Color(0xFF00E5FF).withOpacity(0.12)
      ..style = PaintingStyle.fill;

    final innerLinePaint = Paint()
      ..color = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final meshPaint = Paint()
      ..color = const Color(0xFFFFB300).withOpacity(0.15)
      ..style = PaintingStyle.fill;

    // Draw Outer Frame
    final outerRect = Rect.fromLTWH(startX, startY, drawW, drawH);
    canvas.drawRect(outerRect, frameFillPaint);
    canvas.drawRect(outerRect, framePaint);

    if (item is WindowItem) {
      final WindowItem win = item as WindowItem;
      int tracks = 2;
      if (win.track == '3Track') tracks = 3;
      if (win.track == '4Track') tracks = 4;

      double paneW = drawW / tracks;
      for (int i = 0; i < tracks; i++) {
        final paneRect = Rect.fromLTWH(startX + (i * paneW) + 4, startY + 4, paneW - 8, drawH - 8);
        if (win.jali && i == 0) {
          canvas.drawRect(paneRect, meshPaint);
        } else {
          canvas.drawRect(paneRect, glassPaint);
        }
        canvas.drawRect(paneRect, innerLinePaint);

        // Draw sash diagonal indicator
        final sashPath = Path();
        sashPath.moveTo(paneRect.left, paneRect.top);
        sashPath.lineTo(paneRect.right, paneRect.bottom);
        canvas.drawPath(sashPath, innerLinePaint..strokeWidth = 0.5);
      }
    } else if (item is PartitionItem) {
      final PartitionItem part = item as PartitionItem;
      double doorW = (part.dw * scale);
      double doorH = (part.dh * scale);
      double kickH = (part.bh * scale);

      // Draw Door Opening if dw > 0
      if (part.dw > 0 && part.dh > 0) {
        final doorRect = Rect.fromLTWH(startX + 4, startY + drawH - doorH, doorW - 4, doorH - 4);
        canvas.drawRect(
          doorRect,
          Paint()
            ..color = const Color(0xFFFFB300).withOpacity(0.18)
            ..style = PaintingStyle.fill,
        );
        canvas.drawRect(doorRect, innerLinePaint..strokeWidth = 2.0);

        // Door swing arc
        final arcRect = Rect.fromLTWH(startX + 4 - doorW, startY + drawH - doorH, doorW * 2, doorH * 2);
        canvas.drawArc(arcRect, 0, -1.57, false, innerLinePaint..strokeWidth = 1.0);
      }

      // Draw Transom / Top Glass
      double topH = (part.h - part.dh) * scale;
      if (topH > 0) {
        final topRect = Rect.fromLTWH(startX + 4, startY + 4, drawW - 8, topH - 8);
        canvas.drawRect(topRect, glassPaint);
        canvas.drawRect(topRect, innerLinePaint);
      }

      // Draw Bottom Kick-plate
      if (kickH > 0) {
        final kickRect = Rect.fromLTWH(startX + doorW + 4, startY + drawH - kickH, drawW - doorW - 8, kickH - 4);
        canvas.drawRect(
          kickRect,
          Paint()
            ..color = const Color(0xFF475569)
            ..style = PaintingStyle.fill,
        );
        canvas.drawRect(kickRect, innerLinePaint);
      }
    }

    // Draw Dimensions Text
    _drawDimensionText(canvas, '${width.toStringAsFixed(0)}"', Offset(startX + drawW / 2, startY - 14), isDark);
    _drawDimensionText(canvas, '${height.toStringAsFixed(0)}"', Offset(startX - 14, startY + drawH / 2), isDark, isVertical: true);
  }

  void _drawDimensionText(Canvas canvas, String text, Offset position, bool isDark, {bool isVertical = false}) {
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        color: isDark ? AppTheme.accentCyan : AppTheme.primaryBlue,
        fontSize: 11,
        fontWeight: FontWeight.bold,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    if (isVertical) {
      canvas.save();
      canvas.translate(position.dx, position.dy);
      canvas.rotate(-1.5708);
      textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
      canvas.restore();
    } else {
      textPainter.paint(canvas, Offset(position.dx - textPainter.width / 2, position.dy - textPainter.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
