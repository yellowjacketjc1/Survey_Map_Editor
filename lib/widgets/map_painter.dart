import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/annotation_models.dart';
import '../models/survey_map_model.dart';

class MapPainter extends CustomPainter {
  final SurveyMapModel model;
  final Map<String, ui.Image> iconCache;
  final SmearAnnotation? selectedSmear;
  final DoseRateAnnotation? selectedDoseRate;
  final CommentAnnotation? selectedComment;
  final BoundaryAnnotation? selectedBoundary;
  final bool selectedTitleCard;

  MapPainter({
    required this.model,
    required this.iconCache,
    this.selectedSmear,
    this.selectedDoseRate,
    this.selectedComment,
    this.selectedBoundary,
    this.selectedTitleCard = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (model.pdfImage == null) return;

    canvas.save();

    // Apply offset
    canvas.translate(model.offset.dx, model.offset.dy);

    // Apply rotation around center
    final centerX = model.pdfSize.width / 2;
    final centerY = model.pdfSize.height / 2;
    canvas.translate(centerX * model.scale, centerY * model.scale);
    canvas.rotate(model.rotation * 3.14159265359 / 180);
    canvas.translate(-centerX * model.scale, -centerY * model.scale);

    // Apply scale
    canvas.scale(model.scale);

    // Draw PDF
    canvas.drawImage(model.pdfImage!, Offset.zero, Paint());

    canvas.restore();

    // Draw annotations (in page coordinates but transformed)
    _drawAnnotations(canvas);
  }

  void _drawAnnotations(Canvas canvas) {
    canvas.save();
    canvas.translate(model.offset.dx, model.offset.dy);
    canvas.scale(model.scale);

    // Draw smears
    for (final smear in model.smears) {
      _drawSmear(canvas, smear);
    }

    // Draw dose rates
    for (final dose in model.doseRates) {
      _drawDoseRate(canvas, dose);
    }

    // Draw equipment
    for (final equipment in model.equipment) {
      _drawEquipment(canvas, equipment);
    }

    // Draw boundaries
    for (final boundary in model.boundaries) {
      _drawBoundary(canvas, boundary);
    }

    // Draw current boundary being drawn
    if (model.currentBoundary != null &&
        model.currentBoundary!.points.isNotEmpty) {
      _drawCurrentBoundary(canvas, model.currentBoundary!);
    }

    // Draw comments
    for (final comment in model.comments) {
      _drawComment(canvas, comment);
    }

    // Draw title card (with integrated statistics)
    if (model.titleCard != null && model.titleCard!.visible) {
      _drawTitleCard(canvas, model.titleCard!);
    }

    canvas.restore();
  }

  void _drawSmear(Canvas canvas, SmearAnnotation smear) {
    final isSelected = selectedSmear?.id == smear.id;

    final paint = Paint()
      ..color = const Color(0x99FFC107)
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = const Color(0xFFFFC107)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(smear.position, 15, paint);
    canvas.drawCircle(smear.position, 15, strokePaint);

    // Draw selection indicator
    if (isSelected) {
      final selectionPaint = Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawCircle(smear.position, 22, selectionPaint);

      // Draw outer glow
      final glowPaint = Paint()
        ..color = Colors.blue.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6;
      canvas.drawCircle(smear.position, 24, glowPaint);
    }

    // Draw ID
    final textPainter = TextPainter(
      text: TextSpan(
        text: smear.id.toString(),
        style: const TextStyle(
          color: Colors.black,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        smear.position.dx - textPainter.width / 2,
        smear.position.dy - textPainter.height / 2,
      ),
    );
  }

  void _drawDoseRate(Canvas canvas, DoseRateAnnotation dose) {
    // Use object identity to check if this is the selected dose rate
    final isSelected = selectedDoseRate != null && identical(selectedDoseRate, dose);

    final displayValue = '${dose.value} ${dose.unit}';

    final textPainter = TextPainter(
      text: TextSpan(
        text: displayValue,
        style: TextStyle(
          color: Colors.black,
          fontSize: dose.fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    // Draw selection indicator background
    if (isSelected) {
      final padding = 6.0;
      final bgRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: dose.position,
          width: textPainter.width + padding * 2,
          height: textPainter.height + padding * 2,
        ),
        const Radius.circular(4),
      );

      // Draw outer glow
      final glowPaint = Paint()
        ..color = Colors.blue.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          bgRect.outerRect.inflate(3),
          const Radius.circular(6),
        ),
        glowPaint,
      );

      // Draw selection border
      final selectionPaint = Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawRRect(bgRect, selectionPaint);
    }

    // Draw neutron indicator if needed
    if (dose.type == DoseType.neutron) {
      final dotX = dose.position.dx - (textPainter.width / 2) - 8;
      final dotPaint = Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(dotX, dose.position.dy), 3, dotPaint);
    }

    textPainter.paint(
      canvas,
      Offset(
        dose.position.dx - textPainter.width / 2,
        dose.position.dy - textPainter.height / 2,
      ),
    );
  }

  void _drawEquipment(Canvas canvas, EquipmentAnnotation equipment) {
    // Try to get cached image
    final cachedImage = iconCache[equipment.iconFile];

    if (cachedImage != null) {
      canvas.save();

      // Apply rotation if needed
      if (equipment.rotation != 0) {
        canvas.translate(equipment.position.dx, equipment.position.dy);
        canvas.rotate(equipment.rotation * 3.14159265359 / 180);
        canvas.translate(-equipment.position.dx, -equipment.position.dy);
      }

      // Draw the image
      final rect = Rect.fromCenter(
        center: equipment.position,
        width: equipment.width,
        height: equipment.height,
      );
      canvas.drawImageRect(
        cachedImage,
        Rect.fromLTWH(
          0,
          0,
          cachedImage.width.toDouble(),
          cachedImage.height.toDouble(),
        ),
        rect,
        Paint(),
      );

      canvas.restore();

      // Draw selection handles if selected
      if (model.selectedIcon == equipment) {
        _drawSelectionHandles(canvas, equipment);
      }
    } else {
      // Draw placeholder with warning
      debugPrint('⚠️  Drawing placeholder for equipment: ${equipment.iconFile} (not in cache)');
      final rect = Rect.fromCenter(
        center: equipment.position,
        width: equipment.width,
        height: equipment.height,
      );

      // Draw red placeholder to make it obvious something is missing
      canvas.drawRect(
        rect,
        Paint()
          ..color = Colors.red.withValues(alpha: 0.3)
          ..style = PaintingStyle.fill,
      );
      canvas.drawRect(
        rect,
        Paint()
          ..color = Colors.red
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );

      // Draw an X to indicate missing icon
      final paint = Paint()
        ..color = Colors.red
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset(rect.left, rect.top),
        Offset(rect.right, rect.bottom),
        paint,
      );
      canvas.drawLine(
        Offset(rect.right, rect.top),
        Offset(rect.left, rect.bottom),
        paint,
      );
    }
  }

  void _drawSelectionHandles(Canvas canvas, EquipmentAnnotation equipment) {
    final halfWidth = equipment.width / 2;
    final halfHeight = equipment.height / 2;
    const handleSize = 6.0;
    const margin = 5.0;

    // Draw selection border
    final rect = Rect.fromCenter(
      center: equipment.position,
      width: equipment.width + margin * 2,
      height: equipment.height + margin * 2,
    );

    final borderPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawRect(rect, borderPaint);

    // Draw resize handles
    final handlePaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    final handles = [
      Offset(equipment.position.dx - halfWidth - margin,
          equipment.position.dy - halfHeight - margin),
      Offset(equipment.position.dx + halfWidth + margin,
          equipment.position.dy - halfHeight - margin),
      Offset(equipment.position.dx - halfWidth - margin,
          equipment.position.dy + halfHeight + margin),
      Offset(equipment.position.dx + halfWidth + margin,
          equipment.position.dy + halfHeight + margin),
    ];

    for (final handle in handles) {
      canvas.drawRect(
        Rect.fromCenter(center: handle, width: handleSize, height: handleSize),
        handlePaint,
      );
    }
  }

  void _drawBoundary(Canvas canvas, BoundaryAnnotation boundary) {
    if (boundary.points.length < 2) return;

    final isSelected = selectedBoundary?.id == boundary.id;

    // Draw selection highlight first (if selected)
    if (isSelected) {
      // Draw a thicker, brighter line behind the boundary
      final selectionPaint = Paint()
        ..color = Colors.blue.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8;

      final selectionPath = Path();
      selectionPath.moveTo(boundary.points[0].dx, boundary.points[0].dy);
      for (int i = 1; i < boundary.points.length; i++) {
        selectionPath.lineTo(boundary.points[i].dx, boundary.points[i].dy);
      }
      canvas.drawPath(selectionPath, selectionPaint);

      // Draw selection points with blue circles
      final pointPaint = Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.fill;
      final pointStrokePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      for (final point in boundary.points) {
        canvas.drawCircle(point, 6, pointPaint);
        canvas.drawCircle(point, 6, pointStrokePaint);
      }
    }

    final path = Path();
    path.moveTo(boundary.points[0].dx, boundary.points[0].dy);
    for (int i = 1; i < boundary.points.length; i++) {
      path.lineTo(boundary.points[i].dx, boundary.points[i].dy);
    }

    // Draw dashed line with alternating yellow and magenta
    if (isSelected) {
      // Selection: use blue
      final paint = Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      _drawDashedPath(canvas, path, paint, const [8.0, 4.0]);
    } else {
      // Normal: alternating yellow and magenta
      _drawAlternatingDashedPath(canvas, path, const [8.0, 4.0], Colors.yellow, const Color(0xFFFF00FF), 2);
    }
  }

  void _drawCurrentBoundary(Canvas canvas, BoundaryAnnotation boundary) {
    if (boundary.points.isEmpty) return;

    // Draw lines
    if (boundary.points.length > 1) {
      final path = Path();
      path.moveTo(boundary.points[0].dx, boundary.points[0].dy);
      for (int i = 1; i < boundary.points.length; i++) {
        path.lineTo(boundary.points[i].dx, boundary.points[i].dy);
      }

      // Draw with brighter alternating yellow and magenta for current boundary
      _drawAlternatingDashedPath(canvas, path, const [8.0, 4.0], Colors.yellow.shade700, const Color(0xFFFF1493), 2);
    }

    // Draw points
    final pointPaint = Paint()
      ..color = const Color(0xFF6F42C1)
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (final point in boundary.points) {
      canvas.drawCircle(point, 4, pointPaint);
      canvas.drawCircle(point, 4, strokePaint);
    }
  }

  void _drawDashedPath(
      Canvas canvas, Path path, Paint paint, List<double> pattern) {
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double distance = 0;
      bool draw = true;
      int patternIndex = 0;

      while (distance < metric.length) {
        final length = pattern[patternIndex % pattern.length];
        if (draw) {
          final extractPath = metric.extractPath(distance, distance + length);
          canvas.drawPath(extractPath, paint);
        }
        distance += length;
        draw = !draw;
        patternIndex++;
      }
    }
  }

  void _drawAlternatingDashedPath(
      Canvas canvas, Path path, List<double> pattern, Color color1, Color color2, double strokeWidth) {
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double distance = 0;
      bool draw = true;
      bool useFirstColor = true;
      int patternIndex = 0;

      while (distance < metric.length) {
        final length = pattern[patternIndex % pattern.length];
        if (draw) {
          final paint = Paint()
            ..color = useFirstColor ? color1 : color2
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth;

          final extractPath = metric.extractPath(distance, distance + length);
          canvas.drawPath(extractPath, paint);

          // Alternate colors for each dash
          useFirstColor = !useFirstColor;
        }
        distance += length;
        draw = !draw;
        patternIndex++;
      }
    }
  }

  void _drawTitleCard(Canvas canvas, TitleCard titleCard) {
    // Apply scaling
    canvas.save();
    canvas.translate(titleCard.position.dx, titleCard.position.dy);
    canvas.scale(titleCard.scale, titleCard.scale);
    canvas.translate(-titleCard.position.dx, -titleCard.position.dy);

    const cardWidth = 240.0;
    const cardHeight = 240.0; // Increased to fit larger text
    final cardRect = Rect.fromLTWH(
      titleCard.position.dx,
      titleCard.position.dy,
      cardWidth,
      cardHeight,
    );

    // Draw selection highlight if selected
    if (selectedTitleCard) {
      // Draw outer glow
      final glowRect = cardRect.inflate(4);
      final glowPaint = Paint()
        ..color = Colors.blue.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill;
      canvas.drawRect(glowRect, glowPaint);

      // Draw selection border
      final selectionPaint = Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4;
      canvas.drawRect(cardRect.inflate(2), selectionPaint);
    }

    // Draw card background with border
    final bgPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = selectedTitleCard ? Colors.blue : Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = selectedTitleCard ? 3 : 2;

    canvas.drawRect(cardRect, bgPaint);
    canvas.drawRect(cardRect, borderPaint);

    // Draw header
    final headerRect = Rect.fromLTWH(
      titleCard.position.dx,
      titleCard.position.dy,
      cardWidth,
      30,
    );

    final headerPaint = Paint()
      ..color = Colors.blue.shade700
      ..style = PaintingStyle.fill;

    canvas.drawRect(headerRect, headerPaint);

    // Draw "Survey Information" title
    final titlePainter = TextPainter(
      text: const TextSpan(
        text: 'Survey Information',
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    titlePainter.layout();
    titlePainter.paint(
      canvas,
      Offset(titleCard.position.dx + 8, titleCard.position.dy + 8),
    );

    // Draw fields
    double yOffset = titleCard.position.dy + 40;
    const lineHeight = 28.0;

    _drawField(canvas, 'Survey ID:', titleCard.surveyId, titleCard.position.dx + 8, yOffset);
    yOffset += lineHeight;

    _drawField(canvas, 'Surveyor:', titleCard.surveyorName, titleCard.position.dx + 8, yOffset);
    yOffset += lineHeight;

    final dateStr = '${titleCard.date.month}/${titleCard.date.day}/${titleCard.date.year}';
    _drawField(canvas, 'Date:', dateStr, titleCard.position.dx + 8, yOffset);
    yOffset += lineHeight;

    _drawField(canvas, 'Building:', titleCard.buildingNumber, titleCard.position.dx + 8, yOffset);
    yOffset += lineHeight;

    _drawField(canvas, 'Room:', titleCard.roomNumber, titleCard.position.dx + 8, yOffset);
    yOffset += lineHeight + 4;

    // Draw divider line
    final dividerPaint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(titleCard.position.dx + 8, yOffset),
      Offset(titleCard.position.dx + cardWidth - 8, yOffset),
      dividerPaint,
    );
    yOffset += 8;

    // Draw statistics section
    _drawStatistics(canvas, titleCard.position.dx + 8, yOffset);

    canvas.restore();
  }

  void _drawStatistics(Canvas canvas, double x, double y) {
    double yOffset = y;

    // Draw smear count
    final smearCountPainter = TextPainter(
      text: TextSpan(
        children: [
          const TextSpan(
            text: 'Smears: ',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(
            text: '${model.smears.length}',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 14,
            ),
          ),
        ],
      ),
      textDirection: TextDirection.ltr,
    );
    smearCountPainter.layout();
    smearCountPainter.paint(canvas, Offset(x, yOffset));
    yOffset += 24;

    // Draw highest dose rate
    final highestDose = model.highestDoseRate;

    if (highestDose != null) {
      final doseTypeStr = highestDose.type == DoseType.gamma ? 'γ' : 'n';
      final doseRatePainter = TextPainter(
        text: TextSpan(
          children: [
            const TextSpan(
              text: 'Max Dose: ',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(
              text: '${highestDose.value} ${highestDose.unit}',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 14,
              ),
            ),
            TextSpan(
              text: ' ($doseTypeStr)',
              style: TextStyle(
                color: highestDose.type == DoseType.gamma ? Colors.blue : Colors.red,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        textDirection: TextDirection.ltr,
      );
      doseRatePainter.layout();
      doseRatePainter.paint(canvas, Offset(x, yOffset));
    } else {
      final noDosePainter = TextPainter(
        text: const TextSpan(
          text: 'Max Dose: —',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      noDosePainter.layout();
      noDosePainter.paint(canvas, Offset(x, yOffset));
    }
  }

  void _drawField(Canvas canvas, String label, String value, double x, double y) {
    final labelPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    labelPainter.layout();
    labelPainter.paint(canvas, Offset(x, y));

    final valuePainter = TextPainter(
      text: TextSpan(
        text: value.isEmpty ? '—' : value,
        style: TextStyle(
          color: value.isEmpty ? Colors.grey : Colors.black,
          fontSize: 14,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    valuePainter.layout();
    valuePainter.paint(canvas, Offset(x + 70, y));
  }

  void _drawComment(Canvas canvas, CommentAnnotation comment) {
    final isSelected = selectedComment?.id == comment.id;

    final bubblePaint = Paint()
      ..color = Colors.lightBlue.shade100
      ..style = PaintingStyle.fill;

    final bubbleStrokePaint = Paint()
      ..color = Colors.blue.shade700
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Create speech bubble path
    final path = Path();
    final center = comment.position;
    final width = 36.0;
    final height = 28.0;
    final tailSize = 6.0;
    final cornerRadius = 8.0;

    // Draw selection indicator first (so it appears behind the bubble)
    if (isSelected) {
      final selectionRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center,
          width: width + 12,
          height: height + 12,
        ),
        const Radius.circular(14),
      );

      // Draw outer glow
      final glowPaint = Paint()
        ..color = Colors.blue.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          selectionRect.outerRect.inflate(2),
          const Radius.circular(16),
        ),
        glowPaint,
      );

      // Draw selection border
      final selectionPaint = Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawRRect(selectionRect, selectionPaint);
    }

    // Main rounded rectangle bubble
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: center,
        width: width,
        height: height,
      ),
      Radius.circular(cornerRadius),
    );
    path.addRRect(rect);

    // Add small tail pointing down-left
    final tailPath = Path();
    tailPath.moveTo(center.dx - 8, center.dy + height / 2);
    tailPath.lineTo(center.dx - 12, center.dy + height / 2 + tailSize);
    tailPath.lineTo(center.dx - 6, center.dy + height / 2);
    tailPath.close();
    path.addPath(tailPath, Offset.zero);

    // Draw the bubble
    canvas.drawPath(path, bubblePaint);
    canvas.drawPath(path, bubbleStrokePaint);

    // Draw comment ID number
    final textPainter = TextPainter(
      text: TextSpan(
        text: comment.id.toString(),
        style: TextStyle(
          color: Colors.blue.shade900,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant MapPainter oldDelegate) {
    return true; // Always repaint for simplicity
  }
}
