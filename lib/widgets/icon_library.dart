import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../models/survey_map_model.dart';
import '../models/annotation_models.dart';
import '../models/posting_model.dart';

class IconLibrary extends StatefulWidget {
  final bool isExpanded;
  final bool postingsOnly;

  const IconLibrary({super.key, this.isExpanded = false, this.postingsOnly = false});

  @override
  State<IconLibrary> createState() => _IconLibraryState();
}

class _IconLibraryState extends State<IconLibrary> {
  final Set<String> _selectedTags = {};
  Set<String> _allTags = {};

  @override
  Widget build(BuildContext context) {
    return Consumer<SurveyMapModel>(
      builder: (context, model, child) {
        // Extract all unique tags from icons with counts
        final tagCounts = <String, int>{};
        for (final icon in model.iconLibrary) {
          final iconTags = <String>{};
          iconTags.addAll(icon.keywords.map((k) => k.toLowerCase()));
          if (icon.metadata is PostingMetadata) {
            final posting = icon.metadata as PostingMetadata;
            iconTags.addAll(posting.tags);
          }
          // Count each unique tag
          for (final tag in iconTags) {
            tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
          }
        }
        // Only include tags that have at least 1 result
        _allTags = tagCounts.keys.toSet();

        // Filter icons based on search and selected tags
        final filteredIcons = model.iconLibrary.where((icon) {
          // If postingsOnly mode, only show postings
          if (widget.postingsOnly) {
            if (icon.category != IconCategory.posting) {
              return false;
            }
          } else {
            // If not expanded (sidebar view), exclude posting icons
            // Postings should only be accessible via the pop-out dialog
            if (!widget.isExpanded && icon.category == IconCategory.posting) {
              return false;
            }
          }

          // Check category filter
          final matchesCategory = model.iconCategoryFilter == null ||
              icon.category == model.iconCategoryFilter;

          // Check search query
          final searchQuery = model.iconSearchQuery.toLowerCase();
          bool matchesSearch = searchQuery.isEmpty;

          if (!matchesSearch) {
            // Search in name
            if (icon.name.toLowerCase().contains(searchQuery)) {
              matchesSearch = true;
            }
            // Search in keywords
            if (icon.keywords.any((k) => k.toLowerCase().contains(searchQuery))) {
              matchesSearch = true;
            }
            // Search in posting metadata
            if (icon.metadata is PostingMetadata) {
              final posting = icon.metadata as PostingMetadata;
              if (posting.fullText.toLowerCase().contains(searchQuery) ||
                  posting.id.toLowerCase().contains(searchQuery)) {
                matchesSearch = true;
              }
            }
          }

          // Check tag filter
          bool matchesTags = _selectedTags.isEmpty;
          if (!matchesTags) {
            final iconTags = icon.keywords.map((k) => k.toLowerCase()).toSet();
            if (icon.metadata is PostingMetadata) {
              final posting = icon.metadata as PostingMetadata;
              iconTags.addAll(posting.tags);
            }
            matchesTags = _selectedTags.any((tag) => iconTags.contains(tag));
          }

          return matchesCategory && matchesSearch && matchesTags;
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search field (always visible)
            TextField(
              decoration: InputDecoration(
                hintText: widget.isExpanded ? 'Search icons and postings...' : 'Search icons...',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (value) => model.setIconSearchQuery(value),
            ),
            const SizedBox(height: 8),

            // Category dropdown and tag filters only show in expanded/pop-out view
            if (widget.isExpanded) ...[
              // Category dropdown
              DropdownButtonFormField<IconCategory?>(
                value: model.iconCategoryFilter,
                decoration: const InputDecoration(
                  labelText: 'Type',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: const [
                  DropdownMenuItem(value: null, child: Text('All')),
                  DropdownMenuItem(value: IconCategory.posting, child: Text('Postings')),
                  DropdownMenuItem(value: IconCategory.equipment, child: Text('Material Icons')),
                ],
                onChanged: (value) {
                  model.setIconCategoryFilter(value);
                  setState(() {});
                },
              ),
              const SizedBox(height: 8),

              // Tag filter chips
              if (_allTags.isNotEmpty) ...[
                const Text(
                  'Filter by tags:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _allTags.take(20).map((tag) {
                      final isSelected = _selectedTags.contains(tag);
                      return Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: FilterChip(
                          label: Text(
                            tag,
                            style: TextStyle(fontSize: 10),
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedTags.add(tag);
                              } else {
                                _selectedTags.remove(tag);
                              }
                            });
                          },
                          padding: EdgeInsets.zero,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                if (_selectedTags.isNotEmpty) ...[
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedTags.clear();
                      });
                    },
                    icon: const Icon(Icons.clear, size: 16),
                    label: const Text('Clear filters', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 30),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
              ],
            ],

            // Icon grid
            widget.isExpanded
                ? Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: filteredIcons.isEmpty
                          ? const Center(
                              child: Text(
                                'No postings found',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : GridView.builder(
                              padding: const EdgeInsets.all(8),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                childAspectRatio: 1.2,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                              itemCount: filteredIcons.length,
                              itemBuilder: (context, index) {
                                final icon = filteredIcons[index];
                                return _IconCard(icon: icon, isExpanded: true);
                              },
                            ),
                    ),
                  )
                : Container(
                    height: 300,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: filteredIcons.isEmpty
                        ? const Center(
                            child: Text(
                              'No postings found',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(8),
                            itemCount: filteredIcons.length,
                            itemBuilder: (context, index) {
                              final icon = filteredIcons[index];
                              return _IconCard(icon: icon, isExpanded: false);
                            },
                          ),
                  ),
          ],
        );
      },
    );
  }
}

class _IconCard extends StatelessWidget {
  final IconMetadata icon;
  final bool isExpanded;

  const _IconCard({required this.icon, this.isExpanded = false});

  Widget _buildIconPreview(IconMetadata icon) {
    // Check if it's a Material Icon
    if (icon.metadata is Map && icon.metadata['type'] == 'material') {
      final iconData = icon.metadata['iconData'] as IconData;
      return Icon(iconData, size: isExpanded ? 48 : 40, color: Colors.black87);
    }

    // SVG string
    if (icon.svgText != null) {
      return SvgPicture.string(
        icon.svgText!,
        width: isExpanded ? null : 50,
        height: isExpanded ? null : 50,
        fit: BoxFit.contain,
      );
    }

    // SVG asset
    if (icon.assetPath != null) {
      return SvgPicture.asset(
        icon.assetPath!,
        width: isExpanded ? null : 50,
        height: isExpanded ? null : 50,
        fit: BoxFit.contain,
      );
    }

    return const Icon(Icons.image_not_supported);
  }

  @override
  Widget build(BuildContext context) {
    if (isExpanded) {
      // Grid view card
      return Draggable<IconMetadata>(
        data: icon,
        feedback: Material(
          elevation: 4,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.blue, width: 2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: _buildIconPreview(icon),
            ),
          ),
        ),
        childWhenDragging: Opacity(
          opacity: 0.5,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: _buildIconPreview(icon),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    icon.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
        child: Card(
          child: InkWell(
            onTap: () => _onIconTap(context),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon preview
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: _buildIconPreview(icon),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Icon name
                  Text(
                    icon.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // List view card
    return Draggable<IconMetadata>(
      data: icon,
      feedback: Material(
        elevation: 4,
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.blue, width: 2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: _buildIconPreview(icon),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Icon preview
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: _buildIconPreview(icon),
                  ),
                ),
                const SizedBox(width: 12),
                // Icon info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        icon.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: icon.category.color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          icon.category.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            color: icon.category.color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.add_circle_outline, color: Colors.blue),
              ],
            ),
          ),
        ),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          onTap: () => _onIconTap(context),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Icon preview
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: _buildIconPreview(icon),
                  ),
                ),
                const SizedBox(width: 12),
                // Icon info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        icon.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: icon.category.color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          icon.category.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            color: icon.category.color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.add_circle_outline, color: Colors.blue),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onIconTap(BuildContext context) {
    final model = context.read<SurveyMapModel>();

    // Show a snackbar to inform user to click on canvas
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Click on the map to place "${icon.name}"'),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'Cancel',
          onPressed: () {},
        ),
      ),
    );

    // For now, we'll add the equipment at center of PDF
    // In a real implementation, you'd enable a placement mode
    final centerPosition = Offset(
      model.pdfSize.width / 2,
      model.pdfSize.height / 2,
    );

    // Get icon content - handle Material Icons differently
    String iconContent = '';

    if (icon.metadata is Map && icon.metadata['type'] == 'material') {
      // For Material Icons, store the icon data as metadata
      iconContent = 'material:${icon.file}';
    } else {
      // Get SVG content - either from inline text or load from asset
      iconContent = icon.svgText ?? '';
      if (iconContent.isEmpty && icon.assetPath != null) {
        iconContent = icon.assetPath!;
      }
    }

    model.addEquipment(
      EquipmentAnnotation(
        position: centerPosition,
        iconFile: icon.file,
        iconSvg: iconContent,
        width: 80,
        height: 80,
      ),
    );
  }
}
