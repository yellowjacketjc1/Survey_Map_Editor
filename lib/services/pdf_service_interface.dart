import 'dart:typed_data';
import 'dart:ui' as ui;

/// Platform-agnostic interface for PDF services
abstract class PdfServiceInterface {
  Future<Uint8List?> pickPdfFile();
  Future<ui.Image?> loadPdfPage(Uint8List pdfBytes, {int pageNumber = 1});
}
