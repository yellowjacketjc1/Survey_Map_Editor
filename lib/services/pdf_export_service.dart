import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/survey_map_model.dart';

class PdfExportService {
  static Future<void> exportToPdf(
    SurveyMapModel model,
    GlobalKey canvasKey,
  ) async {
    if (model.pdfImage == null) {
      throw Exception('No PDF loaded');
    }

    try {
      debugPrint('Starting PDF export...');

      // Capture the canvas as an image at 2x resolution (balance between quality and speed)
      debugPrint('Capturing canvas...');
      final imageBytes = await _captureCanvasAsImage(canvasKey, pixelRatio: 2.0);
      debugPrint('Canvas captured: ${imageBytes.length} bytes');

      // Create PDF document
      debugPrint('Creating PDF...');
      final pdf = pw.Document();

      // Use the actual PDF size for the page format (in points: 72 points = 1 inch)
      final pageWidth = model.pdfSize.width;
      final pageHeight = model.pdfSize.height;

      debugPrint('PDF page size: ${pageWidth}x${pageHeight} points');

      // Add page with the map at original size
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat(
            pageWidth,
            pageHeight,
            marginAll: 0,
          ),
          margin: pw.EdgeInsets.zero,
          build: (context) {
            return pw.Image(
              pw.MemoryImage(imageBytes),
              width: pageWidth,
              height: pageHeight,
              fit: pw.BoxFit.fill,
            );
          },
        ),
      );

      // Add comments page if there are comments
      if (model.comments.isNotEmpty) {
        debugPrint('Adding comments page...');
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.letter,
            build: (context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Comments / Notes',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  ...model.comments.map((comment) {
                    return pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 12),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Container(
                            width: 30,
                            height: 30,
                            decoration: pw.BoxDecoration(
                              border: pw.Border.all(width: 2),
                              shape: pw.BoxShape.circle,
                            ),
                            child: pw.Center(
                              child: pw.Text(
                                '${comment.id}',
                                style: pw.TextStyle(
                                  fontSize: 14,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          pw.SizedBox(width: 12),
                          pw.Expanded(
                            child: pw.Text(
                              comment.text,
                              style: const pw.TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              );
            },
          ),
        );
      }

      debugPrint('Saving PDF...');
      final pdfBytes = await pdf.save();
      debugPrint('PDF saved: ${pdfBytes.length} bytes');

      // Use sharePdf which works on all platforms (web, desktop, mobile)
      debugPrint('Opening share dialog...');
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'survey_map_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      debugPrint('Share dialog closed');
    } catch (e, stackTrace) {
      debugPrint('Error during PDF export: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  static Future<void> printMap(
    SurveyMapModel model,
    GlobalKey canvasKey,
  ) async {
    if (model.pdfImage == null) {
      throw Exception('No PDF loaded');
    }

    try {
      debugPrint('Starting print process...');

      // Capture the canvas as an image at 2x resolution (balance between quality and speed)
      debugPrint('Capturing canvas...');
      final imageBytes = await _captureCanvasAsImage(canvasKey, pixelRatio: 2.0);
      debugPrint('Canvas captured: ${imageBytes.length} bytes');

      // Create PDF document
      debugPrint('Creating PDF...');
      final pdf = pw.Document();

      // Use the actual PDF size for the page format
      final pageWidth = model.pdfSize.width;
      final pageHeight = model.pdfSize.height;

      debugPrint('PDF page size: ${pageWidth}x${pageHeight} points');

      // Add page with the map at original size
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat(
            pageWidth,
            pageHeight,
            marginAll: 0,
          ),
          margin: pw.EdgeInsets.zero,
          build: (context) {
            return pw.Image(
              pw.MemoryImage(imageBytes),
              width: pageWidth,
              height: pageHeight,
              fit: pw.BoxFit.fill,
            );
          },
        ),
      );

      // Add comments page if there are comments
      if (model.comments.isNotEmpty) {
        debugPrint('Adding comments page...');
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.letter,
            build: (context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Comments / Notes',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  ...model.comments.map((comment) {
                    return pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 12),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Container(
                            width: 30,
                            height: 30,
                            decoration: pw.BoxDecoration(
                              border: pw.Border.all(width: 2),
                              shape: pw.BoxShape.circle,
                            ),
                            child: pw.Center(
                              child: pw.Text(
                                '${comment.id}',
                                style: pw.TextStyle(
                                  fontSize: 14,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          pw.SizedBox(width: 12),
                          pw.Expanded(
                            child: pw.Text(
                              comment.text,
                              style: const pw.TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              );
            },
          ),
        );
      }

      debugPrint('Saving PDF...');
      final pdfBytes = await pdf.save();
      debugPrint('PDF saved: ${pdfBytes.length} bytes');

      debugPrint('Opening print dialog...');
      // Show print dialog - use sharePdf which is more reliable on macOS
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'survey_map_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      debugPrint('Print dialog closed');
    } catch (e, stackTrace) {
      debugPrint('Error during print: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  static Future<Uint8List> _captureCanvasAsImage(
    GlobalKey canvasKey, {
    double pixelRatio = 2.0,
  }) async {
    try {
      // Find the RenderRepaintBoundary
      final RenderRepaintBoundary boundary =
          canvasKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

      // Capture as image at high resolution for crisp output
      debugPrint('Capturing at ${pixelRatio}x pixel ratio');
      final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
      debugPrint('Image size: ${image.width}x${image.height} pixels');

      // Convert to PNG bytes
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      return byteData!.buffer.asUint8List();
    } catch (e) {
      throw Exception('Failed to capture canvas: $e');
    }
  }
}
