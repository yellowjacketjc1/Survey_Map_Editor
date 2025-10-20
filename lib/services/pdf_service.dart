import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:file_picker/file_picker.dart';
import 'package:pdfx/pdfx.dart';

class PdfService {
  static Future<Uint8List?> pickPdfFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.bytes != null) {
        return result.files.single.bytes;
      }
    } catch (e) {
      print('Error picking PDF file: $e');
    }
    return null;
  }

  static Future<ui.Image?> loadPdfPage(Uint8List pdfBytes,
      {int pageNumber = 1}) async {
    try {
      print('Opening PDF document...');
      final document = await PdfDocument.openData(pdfBytes);
      print('PDF opened. Page count: ${document.pagesCount}');

      if (pageNumber > document.pagesCount || pageNumber < 1) {
        print('Invalid page number: $pageNumber (total pages: ${document.pagesCount})');
        await document.close();
        return null;
      }

      print('Getting page $pageNumber...');
      final page = await document.getPage(pageNumber);
      print('Page dimensions: ${page.width}x${page.height}');

      // Render at high resolution (2x device pixel ratio)
      const pixelRatio = 2.0;
      print('Rendering page...');
      final pageImage = await page.render(
        width: page.width * pixelRatio,
        height: page.height * pixelRatio,
      );

      if (pageImage == null) {
        print('Failed to render page - render returned null');
        await page.close();
        await document.close();
        return null;
      }

      print('Page rendered. Image size: ${pageImage.width}x${pageImage.height}');

      // Convert to ui.Image using codec instead of decodeImageFromPixels
      print('Converting to ui.Image...');
      final codec = await ui.instantiateImageCodec(pageImage.bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      print('Image converted successfully: ${image.width}x${image.height}');

      await page.close();
      await document.close();

      return image;
    } catch (e, stackTrace) {
      print('Error loading PDF page: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }
}
