import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:html' as html;
import 'dart:js_util' as js_util;
import 'package:file_picker/file_picker.dart';

/// PDF service implementation for web platform using PDF.js
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
      print('Loading PDF page on web...');

      // Get the PDF.js library from the global scope
      final pdfjsLib = js_util.getProperty(html.window, 'pdfjsLib');
      if (pdfjsLib == null) {
        print('PDF.js library not found. Make sure it is loaded in index.html');
        return null;
      }

      // Load the PDF document
      final loadingTask = js_util.callMethod(
        pdfjsLib,
        'getDocument',
        [js_util.jsify({'data': pdfBytes})],
      );

      final pdf = await js_util.promiseToFuture(
        js_util.getProperty(loadingTask, 'promise'),
      );

      print('PDF loaded successfully');

      // Get the page count
      final numPages = js_util.getProperty(pdf, 'numPages') as int;
      print('PDF has $numPages pages');

      if (pageNumber > numPages || pageNumber < 1) {
        print('Invalid page number: $pageNumber (total pages: $numPages)');
        return null;
      }

      // Get the specific page
      final page = await js_util.promiseToFuture(
        js_util.callMethod(pdf, 'getPage', [pageNumber]),
      );

      print('Got page $pageNumber');

      // Get the viewport at scale 2.0 for better quality
      final viewport = js_util.callMethod(page, 'getViewport', [
        js_util.jsify({'scale': 2.0})
      ]);

      final width = (js_util.getProperty(viewport, 'width') as num).toDouble();
      final height = (js_util.getProperty(viewport, 'height') as num).toDouble();

      print('Viewport size: ${width}x$height');

      // Create a canvas to render the PDF page
      final canvas = html.CanvasElement(
        width: width.toInt(),
        height: height.toInt(),
      );
      final context = canvas.context2D;

      // Render the page
      final renderContext = js_util.jsify({
        'canvasContext': context,
        'viewport': viewport,
      });

      await js_util.promiseToFuture(
        js_util.callMethod(page, 'render', [renderContext]),
      );

      print('Page rendered to canvas');

      // Convert canvas to image
      final blob = await canvas.toBlob('image/png');
      final reader = html.FileReader();
      final completer = Completer<Uint8List>();

      reader.onLoadEnd.listen((_) {
        final result = reader.result as Uint8List;
        completer.complete(result);
      });

      reader.onError.listen((error) {
        print('Error reading blob: $error');
        completer.completeError(error);
      });

      reader.readAsArrayBuffer(blob);
      final imageBytes = await completer.future;

      print('Converting to ui.Image...');

      // Decode the PNG bytes to ui.Image
      final codec = await ui.instantiateImageCodec(imageBytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      print('Image created: ${image.width}x${image.height}');

      return image;
    } catch (e, stackTrace) {
      print('Error loading PDF page on web: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }
}
