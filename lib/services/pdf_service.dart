// Conditional export based on platform
// This file exports the appropriate PDF service implementation
// For web: uses dart:html and PDF.js directly
// For mobile/desktop: uses pdfx package
export 'pdf_service_io.dart' if (dart.library.html) 'pdf_service_web.dart';
