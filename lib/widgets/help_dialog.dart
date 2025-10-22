import 'package:flutter/material.dart';

class HelpDialog extends StatelessWidget {
  const HelpDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 700,
        height: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.help_outline, size: 32, color: Colors.blue),
                const SizedBox(width: 12),
                const Text(
                  'SurveyMap Editor - User Guide',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 32),
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSection(
                      title: 'Getting Started',
                      icon: Icons.play_arrow,
                      content: [
                        '• Click "Browse Maps" to select a pre-loaded building map, or "Upload File" to load your own PDF',
                        '• The map will appear in the center canvas ready for annotation',
                        '• Use the editing panel on the right to add survey data',
                      ],
                    ),
                    _buildSection(
                      title: 'Navigation & View Controls',
                      icon: Icons.navigation,
                      content: [
                        '• Pan the map: Click and drag with left mouse button',
                        '• Zoom: Use mouse wheel or trackpad scroll gesture',
                        '• Rotate: Use the rotation slider in the top toolbar (0-360°)',
                        '• Scale: Use the zoom slider in the top toolbar (10-500%)',
                        '• Reset view: Click the "Reset" button to center and fit the map',
                      ],
                    ),
                    _buildSection(
                      title: 'Mouse & Keyboard Shortcuts',
                      icon: Icons.keyboard,
                      content: [
                        '• ESC key: Exit current tool/mode and return to selection',
                        '• Right-click: Open edit dialog for dose rates',
                        '• Double-click: End boundary drawing',
                        '• R key: Rotate selected icon (when an icon is selected)',
                        '• Click & drag: Move annotations and icons to new positions',
                        '• Undo/Redo: Use the buttons in the top toolbar',
                      ],
                    ),
                    _buildSection(
                      title: 'Adding Removable Smears',
                      icon: Icons.circle_outlined,
                      content: [
                        '• Click "Add Removable Smears" in the editing panel',
                        '• Click anywhere on the map to place a numbered smear marker',
                        '• Smears are automatically numbered in sequence',
                        '• Click and drag to reposition smears on the map',
                        '• Use the editing panel to manage smear locations',
                      ],
                    ),
                    _buildSection(
                      title: 'Adding Dose Rates',
                      icon: Icons.analytics_outlined,
                      content: [
                        '• Click "Add Dose Rates" in the editing panel',
                        '• Enter the dose rate value in the text field',
                        '• Select unit (μR/hr, mR/hr, R/hr, or cpm for gamma)',
                        '• Choose type: Gamma (default) or Neutron',
                        '• Optional: Check "Include Distance" and select measurement distance',
                        '• Adjust font size with the slider',
                        '• Click on the map to place the dose rate annotation',
                        '• Right-click a dose rate to open the edit dialog and modify it',
                        '• Neutron measurements show a blue dot indicator',
                      ],
                    ),
                    _buildSection(
                      title: 'Distance Tracking',
                      icon: Icons.straighten,
                      content: [
                        '• Available for gamma and neutron dose rates only',
                        '• Check "Include Distance" to enable distance field',
                        '• Choose preset: Contact (0 cm), 10 cm, or 30 cm',
                        '• Select "Custom" to enter any distance value',
                        '• Distance displays on map with @ symbol (e.g., "100 μR/hr @10 cm")',
                      ],
                    ),
                    _buildSection(
                      title: 'Drawing Boundaries',
                      icon: Icons.border_outer,
                      content: [
                        '• Click "Add Boundaries" in the editing panel',
                        '• Click on the map to place boundary points',
                        '• Continue clicking to create a multi-segment boundary line',
                        '• Double-click to finish the boundary, or press ESC to cancel',
                        '• Boundaries display as dashed lines in yellow and magenta',
                        '• Use the editing panel to manage boundaries',
                      ],
                    ),
                    _buildSection(
                      title: 'Adding Comments/Notes',
                      icon: Icons.comment,
                      content: [
                        '• Click "Add Comments/Notes" in the editing panel',
                        '• Click on the map to place a comment marker',
                        '• Enter your text in the dialog that appears',
                        '• Comments appear as numbered speech bubbles',
                        '• All comments are listed in the editing panel for reference',
                      ],
                    ),
                    _buildSection(
                      title: 'Icon Library & Postings',
                      icon: Icons.image,
                      content: [
                        '• Click "Icon Library" to expand equipment icons',
                        '• Search and filter icons by category',
                        '• Drag icons onto the map to place them',
                        '• Click an icon on the map to select it',
                        '• Drag corner handles to resize selected icons',
                        '• Press "R" key to rotate a selected icon',
                        '• Click "Radiological Postings" for regulatory signs',
                      ],
                    ),
                    _buildSection(
                      title: 'Survey Information Card',
                      icon: Icons.info,
                      content: [
                        '• The title card appears automatically on the map',
                        '• Fill in Survey ID, Surveyor Name, Building, and Room fields',
                        '• Click "Change" to update the survey date',
                        '• Card shows statistics: smear count and highest dose rate',
                        '• Click and drag to reposition the card',
                        '• Card is included in PDF exports',
                      ],
                    ),
                    _buildSection(
                      title: 'Saving & Loading Projects',
                      icon: Icons.save,
                      content: [
                        '• Click "Save" to save your project as a JSON file',
                        '• All annotations, settings, and map data are preserved',
                        '• Click "Load" to open a previously saved project',
                        '• Projects include the original map for easy continuation',
                      ],
                    ),
                    _buildSection(
                      title: 'Exporting',
                      icon: Icons.download,
                      content: [
                        '• Click "Export PDF" to generate a professional PDF report',
                        '• PDF includes the map with all annotations and the survey info card',
                        '• The exported PDF preserves all visual elements exactly as shown',
                        '• Files are automatically named with building and room information',
                      ],
                    ),
                    _buildSection(
                      title: 'Tips & Best Practices',
                      icon: Icons.lightbulb_outline,
                      content: [
                        '• Use Undo/Redo frequently - all major actions are reversible',
                        '• Save your work regularly to avoid data loss',
                        '• Use the Reset view button if you lose track of the map position',
                        '• Adjust font size for dose rates to ensure readability at different zoom levels',
                        '• Use boundaries to mark contamination areas or survey zones',
                        '• Comments are great for noting unusual findings or conditions',
                        '• The editing panel can be scrolled if it extends beyond screen height',
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.tips_and_updates, color: Colors.blue.shade700),
                              const SizedBox(width: 8),
                              Text(
                                'Quick Tip',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Press ESC at any time to cancel the current operation and return to selection mode. This works for all annotation tools!',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<String> content,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...content.map((item) => Padding(
                padding: const EdgeInsets.only(left: 28, bottom: 4),
                child: Text(
                  item,
                  style: const TextStyle(fontSize: 14, height: 1.5),
                ),
              )),
        ],
      ),
    );
  }
}
