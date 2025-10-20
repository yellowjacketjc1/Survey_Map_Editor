import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/survey_map_model.dart';

class ControlsPanel extends StatefulWidget {
  final VoidCallback onReset;
  final VoidCallback onSave;
  final VoidCallback onLoad;
  final VoidCallback onExportPdf;
  final VoidCallback onPrint;

  const ControlsPanel({
    super.key,
    required this.onReset,
    required this.onSave,
    required this.onLoad,
    required this.onExportPdf,
    required this.onPrint,
  });

  @override
  State<ControlsPanel> createState() => _ControlsPanelState();
}

class _ControlsPanelState extends State<ControlsPanel> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 16,
      left: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Menu toggle button
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            icon: const Icon(Icons.menu),
            label: const Text('Controls'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          // Controls panel
          if (_isExpanded)
            Container(
              width: 300,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Consumer<SurveyMapModel>(
                builder: (context, model, child) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Use mouse wheel or pinch to zoom, click-drag to pan.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Transform Controls',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Rotation slider
                      Row(
                        children: [
                          const SizedBox(
                            width: 70,
                            child: Text('Rotation:'),
                          ),
                          Expanded(
                            child: Slider(
                              value: model.rotation,
                              min: 0,
                              max: 360,
                              divisions: 360,
                              onChanged: (value) {
                                model.setRotation(value);
                              },
                            ),
                          ),
                          SizedBox(
                            width: 50,
                            child: Text(
                              '${model.rotation.toInt()}°',
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Scale slider
                      Row(
                        children: [
                          const SizedBox(
                            width: 70,
                            child: Text('Scale:'),
                          ),
                          Expanded(
                            child: Slider(
                              value: model.scale,
                              min: 0.1,
                              max: 5.0,
                              divisions: 98,
                              onChanged: (value) {
                                model.setScale(value);
                              },
                            ),
                          ),
                          SizedBox(
                            width: 50,
                            child: Text(
                              '${(model.scale * 100).toInt()}%',
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Undo/Redo buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: model.undoRedoManager.canUndo
                                  ? () => model.undoRedoManager.undo()
                                  : null,
                              icon: const Icon(Icons.undo, size: 18),
                              label: const Text('Undo'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: model.undoRedoManager.canRedo
                                  ? () => model.undoRedoManager.redo()
                                  : null,
                              icon: const Icon(Icons.redo, size: 18),
                              label: const Text('Redo'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Save/Load buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: widget.onSave,
                              icon: const Icon(Icons.save, size: 18),
                              label: const Text('Save'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: widget.onLoad,
                              icon: const Icon(Icons.folder_open, size: 18),
                              label: const Text('Load'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // PDF Export button
                      ElevatedButton.icon(
                        onPressed: widget.onExportPdf,
                        icon: const Icon(Icons.picture_as_pdf, size: 18),
                        label: const Text('Export PDF'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          minimumSize: const Size(double.infinity, 40),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Reset button
                      ElevatedButton(
                        onPressed: widget.onReset,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          minimumSize: const Size(double.infinity, 40),
                        ),
                        child: const Text('Reset View'),
                      ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
