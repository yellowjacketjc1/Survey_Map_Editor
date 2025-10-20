import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:image/image.dart' as img;

class ExportService {
  static Future<Uint8List?> captureWidget(GlobalKey key) async {
    try {
      final boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      print('Error capturing widget: $e');
      return null;
    }
  }

  static Future<String?> savePngToFile(Uint8List pngBytes,
      {String fileName = 'survey_map.png'}) async {
    try {
      final directory = await getDownloadsDirectory();
      if (directory == null) {
        // Fallback to temporary directory if downloads not available
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsBytes(pngBytes);
        return file.path;
      }

      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(pngBytes);
      return file.path;
    } catch (e) {
      print('Error saving PNG file: $e');
      return null;
    }
  }

  static Future<Uint8List?> convertImageToPng(ui.Image image) async {
    try {
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      print('Error converting image to PNG: $e');
      return null;
    }
  }
}
