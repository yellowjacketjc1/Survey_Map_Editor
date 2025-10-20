// Conditional export based on platform
// This file exports the appropriate PDF service implementation
export 'pdf_service_io.dart' if (dart.library.html) 'pdf_service_web.dart';
