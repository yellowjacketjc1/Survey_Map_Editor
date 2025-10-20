import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:io';

/// Tool to help manually tag SVG files for searchability
class SvgTaggerTool extends StatefulWidget {
  const SvgTaggerTool({super.key});

  @override
  State<SvgTaggerTool> createState() => _SvgTaggerToolState();
}

class _SvgTaggerToolState extends State<SvgTaggerTool> {
  List<SvgMetadata> _svgFiles = [];
  int _currentIndex = 0;
  final TextEditingController _tagsController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSvgFiles();
  }

  Future<void> _loadSvgFiles() async {
    setState(() => _loading = true);

    try {
      // Load asset manifest
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);

      // Filter SVG files from Postings directory
      final svgPaths = manifestMap.keys
          .where((key) => key.startsWith('assets/Postings/') && key.endsWith('.svg'))
          .toList();

      svgPaths.sort();

      _svgFiles = svgPaths.map((path) {
        final filename = path.split('/').last;
        return SvgMetadata(
          path: path,
          filename: filename,
          displayName: filename.replaceAll('.svg', ''),
          tags: [],
        );
      }).toList();

      if (_svgFiles.isNotEmpty) {
        _updateControllers();
      }
    } catch (e) {
      print('Error loading SVG files: $e');
    }

    setState(() => _loading = false);
  }

  void _updateControllers() {
    if (_currentIndex < _svgFiles.length) {
      final current = _svgFiles[_currentIndex];
      _nameController.text = current.displayName;
      _tagsController.text = current.tags.join(', ');
    }
  }

  void _saveCurrentAndNext() {
    if (_currentIndex < _svgFiles.length) {
      final tags = _tagsController.text
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      _svgFiles[_currentIndex] = _svgFiles[_currentIndex].copyWith(
        displayName: _nameController.text.trim(),
        tags: tags,
      );

      if (_currentIndex < _svgFiles.length - 1) {
        setState(() {
          _currentIndex++;
          _updateControllers();
        });
      } else {
        _exportMetadata();
      }
    }
  }

  void _previous() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _updateControllers();
      });
    }
  }

  Future<void> _exportMetadata() async {
    final jsonData = _svgFiles
        .map((svg) => {
              'filename': svg.filename,
              'path': svg.path,
              'displayName': svg.displayName,
              'tags': svg.tags,
            })
        .toList();

    final jsonString = const JsonEncoder.withIndent('  ').convert(jsonData);

    // Show export dialog
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Metadata'),
        content: SingleChildScrollView(
          child: SelectableText(jsonString),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: jsonString));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied to clipboard!')),
              );
            },
            child: const Text('Copy to Clipboard'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_svgFiles.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('No SVG files found in assets/Postings/')),
      );
    }

    final current = _svgFiles[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text('SVG Tagger (${_currentIndex + 1}/${_svgFiles.length})'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportMetadata,
            tooltip: 'Export Metadata',
          ),
        ],
      ),
      body: Row(
        children: [
          // Left side: SVG preview
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.grey[200],
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400, maxHeight: 400),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(24),
                  child: SvgPicture.asset(
                    current.path,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),

          // Right side: Tagging interface
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    current.filename,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Display Name',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: 'e.g., Radiation Area',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Tags (comma-separated)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _tagsController,
                    decoration: const InputDecoration(
                      hintText: 'e.g., radiation, caution, yellow',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'Suggested tags:\ncaution, radiation, warning, danger, contamination, airborne, protective, clothing, dosimetry, survey, high, restricted, controlled, rba, hotspot',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),

                  const Spacer(),

                  // Navigation buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _currentIndex > 0 ? _previous : null,
                          child: const Text('Previous'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _saveCurrentAndNext,
                          child: Text(_currentIndex < _svgFiles.length - 1
                              ? 'Next'
                              : 'Finish & Export'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  LinearProgressIndicator(
                    value: (_currentIndex + 1) / _svgFiles.length,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tagsController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}

class SvgMetadata {
  final String path;
  final String filename;
  final String displayName;
  final List<String> tags;

  SvgMetadata({
    required this.path,
    required this.filename,
    required this.displayName,
    required this.tags,
  });

  SvgMetadata copyWith({
    String? path,
    String? filename,
    String? displayName,
    List<String>? tags,
  }) {
    return SvgMetadata(
      path: path ?? this.path,
      filename: filename ?? this.filename,
      displayName: displayName ?? this.displayName,
      tags: tags ?? this.tags,
    );
  }
}
