import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:html' as html;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle, ByteData;
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../models/survey_map_model.dart';
import '../models/building_map_model.dart';
import '../services/pdf_service.dart';
import '../services/icon_loader.dart';
import '../services/export_service.dart';
import '../services/pdf_export_service.dart';
import '../widgets/map_canvas.dart';
import '../widgets/top_toolbar.dart';
import '../widgets/editing_panel.dart';
import '../widgets/map_browser_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = false;
  final GlobalKey _canvasKey = GlobalKey();
  String? _currentProjectId;
  String? _currentProjectName;

  @override
  void initState() {
    super.initState();
    _loadIcons();
  }

  Future<void> _loadIcons() async {
    final model = context.read<SurveyMapModel>();

    // Load all icon types
    final embeddedIcons = IconLoader.loadEmbeddedIcons();
    final postingIcons = await IconLoader.loadPostingsFromJson();
    final materialIcons = IconLoader.loadMaterialIcons();

    model.setIconLibrary([...embeddedIcons, ...postingIcons, ...materialIcons]);
  }

  Future<void> _pickAndLoadPdf() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final pdfBytes = await PdfService.pickPdfFile();
      if (pdfBytes != null) {
        final model = context.read<SurveyMapModel>();
        model.setPdfBytes(pdfBytes);

        final image = await PdfService.loadPdfPage(pdfBytes);
        if (image != null) {
          model.setPdfImage(image);
        } else {
          _showError('Failed to load PDF page');
        }
      }
    } catch (e) {
      _showError('Error loading PDF: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _browseMaps() async {
    final selectedMap = await showDialog<BuildingMap>(
      context: context,
      builder: (context) => const MapBrowserDialog(),
    );

    if (selectedMap != null && mounted) {
      setState(() {
        _isLoading = true;
      });

      try {
        Uint8List pdfBytes;

        if (kIsWeb) {
          // On web, load from bundled assets
          print('Loading map from assets: ${selectedMap.filePath}');
          final ByteData data = await rootBundle.load(selectedMap.filePath);
          pdfBytes = data.buffer.asUint8List();
        } else {
          // On desktop, use file picker to grant access
          final result = await FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['pdf'],
            dialogTitle: 'Select: ${selectedMap.building} - ${selectedMap.room}',
            initialDirectory: '/Users/coyle/Documents/Coding Projects/survey_map_flutter/Current Maps/${selectedMap.building}',
          );

          if (result == null) return;
          pdfBytes = result.files.single.bytes ?? await File(result.files.single.path!).readAsBytes();
        }

        if (mounted) {
          final model = context.read<SurveyMapModel>();
          final mapName = '${selectedMap.building} - ${selectedMap.room}';
          model.setPdfBytes(pdfBytes, mapName: mapName);

          final image = await PdfService.loadPdfPage(pdfBytes);
          if (image != null) {
            model.setPdfImage(image, mapName: mapName);
            // Pre-fill the title card with building/room info
            final buildingNum = selectedMap.building.replaceAll('Building ', '');
            // Remove building number prefix from room if present (e.g., "203 G158" -> "G158")
            String roomNum = selectedMap.room;
            if (roomNum.startsWith(buildingNum)) {
              roomNum = roomNum.substring(buildingNum.length).trim();
            }
            model.updateTitleCardField(
              buildingNumber: buildingNum,
              roomNumber: roomNum,
            );
          } else {
            _showError('Failed to load PDF page');
          }
        }
      } catch (e) {
        _showError('Error loading map: $e');
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _exportMap() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final pngBytes = await ExportService.captureWidget(_canvasKey);
      if (pngBytes != null) {
        final filePath = await ExportService.savePngToFile(pngBytes);
        if (filePath != null) {
          _showSuccess('Map exported to: $filePath');
        } else {
          _showError('Failed to save PNG file');
        }
      } else {
        _showError('Failed to capture map');
      }
    } catch (e) {
      _showError('Error exporting map: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _exportPdf() async {
    setState(() {
      _isLoading = true;
    });

    // Give UI time to update
    await Future.delayed(const Duration(milliseconds: 100));

    try {
      final model = context.read<SurveyMapModel>();
      await PdfExportService.exportToPdf(model, _canvasKey);
      if (mounted) {
        _showSuccess('PDF exported successfully');
      }
    } catch (e) {
      if (mounted) {
        _showError('Error exporting PDF: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _printMap() async {
    setState(() {
      _isLoading = true;
    });

    // Give UI time to update
    await Future.delayed(const Duration(milliseconds: 100));

    try {
      final model = context.read<SurveyMapModel>();
      await PdfExportService.printMap(model, _canvasKey);
    } catch (e) {
      if (mounted) {
        _showError('Error printing map: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _resetView() {
    final model = context.read<SurveyMapModel>();
    final size = MediaQuery.of(context).size;
    model.resetView(Size(size.width * 0.7, size.height));
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _saveProject() async {
    final model = context.read<SurveyMapModel>();

    if (!model.hasPdf) {
      _showError('Please load a map first');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create the save data with all annotation information and map reference
      final saveData = {
        'version': '1.0',
        'savedDate': DateTime.now().toIso8601String(),
        'mapName': model.mapName, // The map to load (e.g., "Building 203 - H174")
        'mapData': model.toJson(includeImage: false), // All annotations and positions
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(saveData);

      if (kIsWeb) {
        // For web, trigger a download to user's computer
        final bytes = utf8.encode(jsonString);
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', 'survey_map_${DateTime.now().millisecondsSinceEpoch}.json')
          ..click();
        html.Url.revokeObjectUrl(url);

        _showSuccess('Project JSON file downloaded to your Downloads folder');
      } else {
        // For desktop, use file picker
        final String? outputPath = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Survey Map Project',
          fileName: 'survey_map_${DateTime.now().millisecondsSinceEpoch}.json',
          type: FileType.custom,
          allowedExtensions: ['json'],
        );

        if (outputPath != null) {
          final file = File(outputPath);
          await file.writeAsString(jsonString);
          _showSuccess('Project saved to: $outputPath');
        }
      }
    } catch (e) {
      _showError('Error saving project: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadProject() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Pick the JSON file from user's computer
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: 'Load Survey Map Project',
        withData: kIsWeb, // Need bytes for web
      );

      if (result == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      String jsonString;
      if (kIsWeb) {
        // On web, use bytes
        if (result.files.single.bytes == null) {
          throw Exception('Failed to read file');
        }
        jsonString = utf8.decode(result.files.single.bytes!);
      } else {
        // On desktop, use path
        if (result.files.single.path == null) {
          throw Exception('Failed to get file path');
        }
        final file = File(result.files.single.path!);
        jsonString = await file.readAsString();
      }

      // Parse the JSON
      final saveData = json.decode(jsonString) as Map<String, dynamic>;
      final mapName = saveData['mapName'] as String?;
      final mapData = saveData['mapData'] as Map<String, dynamic>;

      // Load the annotation data
      final model = context.read<SurveyMapModel>();
      await model.fromJson(mapData);

      // Try to load the referenced map
      if (mapName != null && mapName.isNotEmpty) {
        await _reloadMapByName(mapName);
        if (mounted) {
          _showSuccess('Project loaded successfully with map: $mapName');
        }
      } else {
        if (mounted) {
          _showError('Project loaded, but no map reference found. Please select a map using "Browse Maps".');
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Error loading project: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        _showError('Error loading project: $e');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _reloadMapByName(String mapName) async {
    try {
      debugPrint('Attempting to reload map: $mapName');

      // Load building maps
      final jsonString = await rootBundle.loadString('assets/building_maps.json');
      final data = json.decode(jsonString) as Map<String, dynamic>;
      final maps = (data['maps'] as List)
          .map((m) {
            final mapData = m as Map<String, dynamic>;
            return BuildingMap(
              building: mapData['building'] as String,
              room: mapData['room'] as String,
              filePath: mapData['path'] as String, // JSON uses 'path' not 'filePath'
            );
          })
          .toList();

      debugPrint('Loaded ${maps.length} maps from building_maps.json');
      debugPrint('Looking for map with name: "$mapName"');

      // Try multiple matching strategies
      BuildingMap? selectedMap;

      // Strategy 1: Exact match on "Building XXX - Room YYY"
      selectedMap = maps.cast<BuildingMap?>().firstWhere(
        (m) => '${m!.building} - ${m.room}' == mapName,
        orElse: () => null,
      );
      if (selectedMap != null) debugPrint('Strategy 1: Found exact match');

      // Strategy 2: Match building and room separately
      if (selectedMap == null && mapName.contains(' - ')) {
        debugPrint('Strategy 2: Trying building and room match');
        final parts = mapName.split(' - ');
        if (parts.length == 2) {
          final building = parts[0].trim();
          final room = parts[1].trim();
          debugPrint('  Building: "$building", Room: "$room"');

          // Try exact match first
          selectedMap = maps.cast<BuildingMap?>().firstWhere(
            (m) => m!.building.trim() == building && m.room.trim() == room,
            orElse: () => null,
          );

          // Handle format like "Building 203 - 203 G158" where room in JSON is just "203 G158"
          if (selectedMap == null) {
            debugPrint('  Strategy 2a: Trying without building number prefix');
            // Extract building number (e.g., "Building 203" -> "203")
            final buildingNum = building.replaceAll('Building ', '').trim();
            debugPrint('  Building number: "$buildingNum"');

            // The room in the saved file might be "203 P101" but in JSON it's also "203 P101"
            // So this should match directly
            selectedMap = maps.cast<BuildingMap?>().firstWhere(
              (m) {
                final match = m!.building.trim() == building && m.room.trim() == room;
                if (match) {
                  debugPrint('    Found match: ${m.building} - ${m.room}');
                }
                return match;
              },
              orElse: () => null,
            );
          }
          if (selectedMap != null) debugPrint('Strategy 2: Found match');
        }
      }

      // Strategy 3: Match by building number and room contains
      if (selectedMap == null) {
        final buildingMatch = RegExp(r'Building (\d+)').firstMatch(mapName);
        if (buildingMatch != null) {
          final buildingNum = buildingMatch.group(1)!;
          // Extract room part after " - "
          final roomPart = mapName.contains(' - ') ? mapName.split(' - ').last.trim() : '';

          if (roomPart.isNotEmpty) {
            // Remove building number prefix from room if present
            final roomWithoutPrefix = roomPart.replaceFirst('$buildingNum ', '').trim();

            selectedMap = maps.cast<BuildingMap?>().firstWhere(
              (m) => m!.building.contains(buildingNum) && (m.room == roomPart || m.room == roomWithoutPrefix),
              orElse: () => null,
            );
          }
        }
      }

      // Strategy 4: Flexible partial match
      if (selectedMap == null) {
        selectedMap = maps.cast<BuildingMap?>().firstWhere(
          (m) => m!.filePath.contains(mapName) || mapName.contains(m.room),
          orElse: () => null,
        );
      }

      if (selectedMap == null) {
        throw Exception('Map not found: $mapName. Available maps: ${maps.map((m) => "${m.building} - ${m.room}").join(", ")}');
      }

      debugPrint('Found map: ${selectedMap.building} - ${selectedMap.room} at ${selectedMap.filePath}');

      // Load the map
      final ByteData data2 = await rootBundle.load(selectedMap.filePath);
      final pdfBytes = data2.buffer.asUint8List();

      final model = context.read<SurveyMapModel>();
      final fullMapName = '${selectedMap.building} - ${selectedMap.room}';
      model.setPdfBytes(pdfBytes, mapName: fullMapName);

      final image = await PdfService.loadPdfPage(pdfBytes);
      if (image != null) {
        model.setPdfImage(image, mapName: fullMapName);
        debugPrint('Map loaded successfully');
      }
    } catch (e, stackTrace) {
      debugPrint('Could not reload map: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        _showError('Project loaded, but could not reload map "$mapName". Please select the map manually.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<SurveyMapModel>(
        builder: (context, model, child) {
          return Stack(
            children: [
              if (!model.hasPdf) _buildUploadSection() else _buildWorkspace(),
              if (_isLoading)
                Container(
                  color: Colors.black54,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildUploadSection() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade50,
            Colors.blue.shade100,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Header
            const Icon(
              Icons.map,
              size: 80,
              color: Colors.blue,
            ),
            const SizedBox(height: 16),
            const Text(
              'SurveyMap',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Radiological Survey Mapping Tool',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 48),
            // Upload area
            Container(
              width: 500,
              padding: const EdgeInsets.all(48),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.picture_as_pdf,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Upload PDF Map',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Click the button below to select your PDF file',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _browseMaps,
                        icon: const Icon(Icons.folder_open),
                        label: const Text('Browse Maps'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          textStyle: const TextStyle(fontSize: 16),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: _pickAndLoadPdf,
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Upload File'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          textStyle: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Browse from pre-defined building maps or upload your own PDF',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),
                  const Text(
                    'or',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _loadProject,
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Load Saved Project'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Load a previously saved project with all annotations',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkspace() {
    return Stack(
      children: [
        // Main workspace with padding to account for toolbar
        Padding(
          padding: const EdgeInsets.only(top: 60),
          child: Row(
            children: [
              // Main map area
              Expanded(
                child: RepaintBoundary(
                  key: _canvasKey,
                  child: const MapCanvas(),
                ),
              ),
              // Right editing panel
              const EditingPanel(),
            ],
          ),
        ),
        // Top toolbar (on top of everything)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: TopToolbar(
            onReset: _resetView,
            onSave: _saveProject,
            onLoad: _loadProject,
            onExportPdf: _exportPdf,
            onPrint: _printMap,
          ),
        ),
      ],
    );
  }
}
