import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/survey_map_model.dart';
import 'help_dialog.dart';

class TopToolbar extends StatelessWidget {
  final VoidCallback onReset;
  final VoidCallback onSave;
  final VoidCallback onLoad;
  final VoidCallback onExportPdf;
  final VoidCallback onPrint;

  const TopToolbar({
    super.key,
    required this.onReset,
    required this.onSave,
    required this.onLoad,
    required this.onExportPdf,
    required this.onPrint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Consumer<SurveyMapModel>(
        builder: (context, model, child) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Undo button
                IconButton(
                  onPressed: model.undoRedoManager.canUndo
                      ? () => model.undoRedoManager.undo()
                      : null,
                  icon: const Icon(Icons.undo),
                  tooltip: 'Undo',
                ),
                // Redo button
                IconButton(
                  onPressed: model.undoRedoManager.canRedo
                      ? () => model.undoRedoManager.redo()
                      : null,
                  icon: const Icon(Icons.redo),
                  tooltip: 'Redo',
                ),
                const SizedBox(width: 8),
                const VerticalDivider(),
                const SizedBox(width: 8),
                // Rotation control
                const Icon(Icons.rotate_right, size: 20),
                const SizedBox(width: 8),
                SizedBox(
                  width: 120,
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
                  width: 40,
                  child: Text(
                    '${model.rotation.toInt()}°',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(width: 16),
                // Scale control
                const Icon(Icons.zoom_in, size: 20),
                const SizedBox(width: 8),
                SizedBox(
                  width: 120,
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
                  width: 40,
                  child: Text(
                    '${(model.scale * 100).toInt()}%',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                const VerticalDivider(),
                const SizedBox(width: 8),
                // Reset view button
                TextButton.icon(
                  onPressed: onReset,
                  icon: const Icon(Icons.center_focus_strong, size: 18),
                  label: const Text('Reset'),
                ),
                const SizedBox(width: 8),
                const VerticalDivider(),
                const SizedBox(width: 8),
                // Save button
                TextButton.icon(
                  onPressed: onSave,
                  icon: const Icon(Icons.save, size: 18),
                  label: const Text('Save'),
                ),
                // Load button
                TextButton.icon(
                  onPressed: onLoad,
                  icon: const Icon(Icons.folder_open, size: 18),
                  label: const Text('Load'),
                ),
                const SizedBox(width: 8),
                const VerticalDivider(),
                const SizedBox(width: 8),
                // Export PDF button
                ElevatedButton.icon(
                  onPressed: onExportPdf,
                  icon: const Icon(Icons.picture_as_pdf, size: 18),
                  label: const Text('Export PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                const Spacer(),
                // Help button
                IconButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => const HelpDialog(),
                    );
                  },
                  icon: const Icon(Icons.help_outline),
                  tooltip: 'Help & User Guide',
                  iconSize: 24,
                  color: Colors.blue.shade700,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
