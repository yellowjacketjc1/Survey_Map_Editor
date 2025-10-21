import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:vector_graphics/vector_graphics.dart' as vg_lib;
import '../models/survey_map_model.dart';
import '../models/annotation_models.dart';
import '../models/commands.dart';
import 'map_painter.dart';

class MapCanvas extends StatefulWidget {
  const MapCanvas({super.key});

  @override
  State<MapCanvas> createState() => _MapCanvasState();
}

class _MapCanvasState extends State<MapCanvas> {
  Offset? _lastPanPosition;
  Offset? _gestureStartPosition;
  SmearAnnotation? _draggedSmear;
  Offset? _smearDragOffset;
  Offset? _smearDragStartPosition;
  DoseRateAnnotation? _draggedDoseRate;
  Offset? _doseRateDragOffset;
  Offset? _doseRateDragStartPosition;
  EquipmentAnnotation? _draggedIcon;
  Offset? _iconDragOffset;
  Offset? _iconDragStartPosition;
  CommentAnnotation? _draggedComment;
  Offset? _commentDragOffset;
  Offset? _commentDragStartPosition;
  bool _draggedTitleCard = false;
  Offset? _titleCardDragOffset;
  Offset? _titleCardDragStartPosition;
  bool _draggedStatsCard = false;
  Offset? _statsCardDragOffset;
  Offset? _statsCardDragStartPosition;
  final Map<String, ui.Image> _iconCache = {};
  double _lastScale = 1.0;

  // Track selected annotations for keyboard deletion
  SmearAnnotation? _selectedSmear;
  DoseRateAnnotation? _selectedDoseRate;
  CommentAnnotation? _selectedComment;
  BoundaryAnnotation? _selectedBoundary;
  bool _selectedTitleCard = false;
  bool _selectedStatsCard = false;

  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resetView();
      _preloadIcons();

      // Listen for equipment changes and load new icons
      final model = context.read<SurveyMapModel>();
      model.addListener(_onModelChanged);
    });
  }

  void _onModelChanged() {
    final model = context.read<SurveyMapModel>();
    // Load any equipment icons that aren't in cache yet
    for (final equipment in model.equipment) {
      if (!_iconCache.containsKey(equipment.iconFile)) {
        _loadEquipmentIcon(equipment);
      }
    }
  }

  Future<void> _loadEquipmentIcon(EquipmentAnnotation equipment) async {
    final model = context.read<SurveyMapModel>();
    final icon = model.iconLibrary.firstWhere(
      (icon) => icon.file == equipment.iconFile,
      orElse: () {
        debugPrint('⚠️ Icon not found in library: ${equipment.iconFile}');
        return null as IconMetadata; // Will be caught below
      },
    );

    if (icon == null) {
      debugPrint('⚠️ Skipping icon load for ${equipment.iconFile} - not in library');
      return;
    }

    if (icon.metadata is Map && icon.metadata['type'] == 'material') {
      final iconData = icon.metadata['iconData'] as IconData;
      await _loadMaterialIconToImage(iconData, equipment.iconFile);
    } else {
      // Determine content source - prefer inline SVG text over asset path
      String content;
      bool isAsset;

      if (icon.svgText != null && icon.svgText!.isNotEmpty) {
        // Use inline SVG text (already loaded during app startup)
        content = icon.svgText!;
        isAsset = false;
        debugPrint('📄 Loading ${equipment.iconFile} from inline SVG (${content.length} chars)');
      } else if (icon.assetPath != null && icon.assetPath!.isNotEmpty) {
        // Fallback to asset path
        content = icon.assetPath!;
        isAsset = true;
        debugPrint('📁 Loading ${equipment.iconFile} from asset path: $content');
      } else {
        // Use equipment's iconSvg as last resort
        content = equipment.iconSvg;
        isAsset = equipment.iconSvg.startsWith('assets/') || equipment.iconSvg.contains('.svg');
        debugPrint('📋 Loading ${equipment.iconFile} from equipment data (isAsset: $isAsset)');
      }

      await _loadSvgToImage(content, equipment.iconFile, isAsset: isAsset);
    }
  }

  @override
  void dispose() {
    final model = context.read<SurveyMapModel>();
    model.removeListener(_onModelChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _resetView() {
    final model = context.read<SurveyMapModel>();
    final size = MediaQuery.of(context).size;
    model.resetView(Size(size.width * 0.7, size.height));
  }

  void _handleKeyEvent(KeyEvent event, SurveyMapModel model) {
    if (event is! KeyDownEvent) return;

    // Handle ESC key - return to selection/drag mode
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      debugPrint('ESC key pressed - returning to selection mode');
      model.setTool(ToolType.none);
      // Clear all selections
      model.selectIcon(null);
      model.selectTitleCard(false);
      model.selectStatsCard(false);
      setState(() {
        _selectedSmear = null;
        _selectedDoseRate = null;
        _selectedComment = null;
        _selectedBoundary = null;
        _selectedTitleCard = false;
        _selectedStatsCard = false;
      });
      return;
    }

    // Handle R key - rotate selected icon
    if (event.logicalKey == LogicalKeyboardKey.keyR) {
      if (model.selectedIcon != null) {
        debugPrint('R key pressed - rotating icon');
        final currentRotation = model.selectedIcon!.rotation;
        final newRotation = (currentRotation + 45) % 360;
        model.updateEquipmentRotation(model.selectedIcon!, newRotation);
      }
      return;
    }

    // Handle Delete or Backspace key
    if (event.logicalKey == LogicalKeyboardKey.delete ||
        event.logicalKey == LogicalKeyboardKey.backspace) {
      debugPrint('Delete key pressed');

      // Check for selected equipment/icon (highest priority since it has visual selection)
      if (model.selectedIcon != null) {
        debugPrint('Deleting selected equipment: ${model.selectedIcon!.iconFile}');
        model.removeEquipment(model.selectedIcon!);
        return;
      }

      // Check for selected smear
      if (_selectedSmear != null) {
        debugPrint('Deleting selected smear: ${_selectedSmear!.id}');
        model.removeSmear(_selectedSmear!);
        setState(() {
          _selectedSmear = null;
        });
        return;
      }

      // Check for selected dose rate
      if (_selectedDoseRate != null) {
        debugPrint('Deleting selected dose rate');
        model.removeDoseRate(_selectedDoseRate!);
        setState(() {
          _selectedDoseRate = null;
        });
        return;
      }

      // Check for selected comment
      if (_selectedComment != null) {
        debugPrint('Deleting selected comment: ${_selectedComment!.id}');
        model.removeComment(_selectedComment!);
        setState(() {
          _selectedComment = null;
        });
        return;
      }

      // Check for selected boundary
      if (_selectedBoundary != null) {
        debugPrint('Deleting selected boundary: ${_selectedBoundary!.id}');
        model.deleteBoundary(_selectedBoundary!);
        setState(() {
          _selectedBoundary = null;
        });
        return;
      }

      debugPrint('No item selected for deletion');
    }
  }

  Future<void> _preloadIcons() async {
    final model = context.read<SurveyMapModel>();
    debugPrint('Starting icon preload. Icon library size: ${model.iconLibrary.length}');

    int materialIconsLoaded = 0;
    int svgIconsLoaded = 0;
    int postingsLoaded = 0;

    for (final icon in model.iconLibrary) {
      // Skip Material Icons - they're rendered differently
      if (icon.metadata is Map && icon.metadata['type'] == 'material') {
        final iconData = icon.metadata['iconData'] as IconData;
        await _loadMaterialIconToImage(iconData, icon.file);
        materialIconsLoaded++;
        continue;
      }

      if (icon.svgText != null) {
        await _loadSvgToImage(icon.svgText!, icon.file, isAsset: false);
        svgIconsLoaded++;
      } else if (icon.assetPath != null) {
        await _loadSvgToImage(icon.assetPath!, icon.file, isAsset: true);
        if (icon.category == IconCategory.posting) {
          postingsLoaded++;
        }
        svgIconsLoaded++;
      }
    }

    debugPrint('Icon library preload complete: $materialIconsLoaded material, $svgIconsLoaded SVG (including $postingsLoaded postings)');

    // Also load equipment icons
    debugPrint('Loading equipment icons. Equipment count: ${model.equipment.length}');
    for (final equipment in model.equipment) {
      // Skip if already cached
      if (_iconCache.containsKey(equipment.iconFile)) {
        debugPrint('Equipment icon already cached: ${equipment.iconFile}');
        continue;
      }

      debugPrint('Loading equipment icon: ${equipment.iconFile}');
      // Check if it's a Material Icon
      if (equipment.iconSvg.startsWith('material:')) {
        // Extract the icon key and load from icon library
        final materialIcon = model.iconLibrary.firstWhere(
          (icon) => icon.file == equipment.iconFile,
          orElse: () => throw Exception('Material icon not found: ${equipment.iconFile}'),
        );
        final iconData = materialIcon.metadata['iconData'] as IconData;
        await _loadMaterialIconToImage(iconData, equipment.iconFile);
      } else {
        // Determine if it's an asset path or inline SVG
        final isAsset = equipment.iconSvg.startsWith('assets/') ||
                        equipment.iconSvg.contains('.svg');
        debugPrint('Equipment icon type: ${isAsset ? "asset" : "inline SVG"}');
        await _loadSvgToImage(equipment.iconSvg, equipment.iconFile, isAsset: isAsset);
      }
    }

    debugPrint('Icon preload finished. Total cached icons: ${_iconCache.length}');
  }

  Future<void> _loadMaterialIconToImage(IconData iconData, String key) async {
    if (_iconCache.containsKey(key)) return;

    try {
      debugPrint('Loading Material Icon: $key');

      const size = 100.0; // Base size for the icon
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Create a text painter to render the icon
      final textPainter = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(iconData.codePoint),
          style: TextStyle(
            fontSize: size,
            fontFamily: iconData.fontFamily,
            package: iconData.fontPackage,
            color: Colors.black,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(canvas, Offset.zero);

      final image = await recorder.endRecording().toImage(
            textPainter.width.toInt(),
            textPainter.height.toInt(),
          );

      if (mounted) {
        setState(() {
          _iconCache[key] = image;
        });
        debugPrint('Material Icon cached: $key');
      }
    } catch (e, stackTrace) {
      debugPrint('Error loading Material Icon $key: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  Future<void> _loadSvgToImage(String svgContent, String key, {required bool isAsset}) async {
    if (_iconCache.containsKey(key)) {
      print('   ℹ️  Icon already in cache: $key');
      return;
    }

    // Declare processedContent outside try block so it's accessible in catch
    String processedContent = svgContent;

    try {
      print('📂 Loading SVG: $key');
      print('   isAsset: $isAsset');
      print('   content length: ${svgContent.length}');
      print('   content preview: ${svgContent.substring(0, svgContent.length.clamp(0, 80))}');

      // For inline SVG content, strip XML declaration and comments that can cause parsing issues
      processedContent = svgContent;
      if (!isAsset) {
        print('   🔧 Cleaning inline SVG content...');
        // Remove XML declaration (<?xml ... ?>)
        processedContent = processedContent.replaceAll(RegExp(r'<\?xml[^?]*\?>'), '');
        // Remove standalone XML/DOCTYPE declarations
        processedContent = processedContent.replaceAll(RegExp(r'<!DOCTYPE[^>]*>'), '');
        // Remove HTML comments (<!-- ... -->)
        processedContent = processedContent.replaceAll(RegExp(r'<!--.*?-->', dotAll: true), '');
        // Trim whitespace
        processedContent = processedContent.trim();
        print('   ✂️  Stripped XML declarations and comments');
        print('   📏 New length: ${processedContent.length}');
        print('   👀 New preview: ${processedContent.substring(0, processedContent.length.clamp(0, 80))}');
      } else {
        print('   📦 Using asset loader (no preprocessing)');
      }

      // Create the appropriate loader based on whether the content is an asset path or raw SVG text.
      final BytesLoader loader = isAsset
          ? SvgAssetLoader(svgContent, assetBundle: rootBundle)
          : SvgStringLoader(processedContent);

      // Load the SVG directly from the loader (which contains the preprocessed content)
      print('   🎨 Converting to picture using ${isAsset ? "asset" : "string"} loader...');
      final PictureInfo pictureInfo = await vg_lib.vg.loadPicture(loader, null);
      print('   ✓ Picture created, size: ${pictureInfo.size}');
      
      // Check for zero or invalid dimensions
      if (pictureInfo.size.width <= 0 || pictureInfo.size.height <= 0) {
        print('   ⚠️  WARNING: SVG $key has invalid dimensions: ${pictureInfo.size}');
        pictureInfo.picture.dispose();
        return;
      }

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawPicture(pictureInfo.picture);

      final image = await recorder.endRecording().toImage(
            pictureInfo.size.width.toInt(),
            pictureInfo.size.height.toInt(),
          );

      if (mounted) {
        setState(() {
          _iconCache[key] = image;
        });
        print('   ✅ SVG cached successfully: $key (${_iconCache.length} total in cache)');
      } else {
        print('   ⚠️  Widget unmounted, could not cache: $key');
      }

      pictureInfo.picture.dispose();
    } catch (e, stackTrace) {
      print('❌ ERROR loading SVG $key');
      print('   isAsset: $isAsset');
      if (isAsset) {
        print('   Asset path: ${svgContent.substring(0, svgContent.length.clamp(0, 150))}');
      } else {
        print('   Original content preview: ${svgContent.substring(0, svgContent.length.clamp(0, 80))}');
        print('   Processed content preview: ${processedContent.substring(0, processedContent.length.clamp(0, 80))}');
      }
      print('   Error: $e');
      print('   Stack trace: $stackTrace');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SurveyMapModel>(
      builder: (context, model, child) {
        if (!model.hasPdf) {
          return const Center(
            child: Text('No PDF loaded'),
          );
        }

        return Focus(
          focusNode: _focusNode,
          autofocus: true,
          onKeyEvent: (node, event) {
            _handleKeyEvent(event, model);
            return KeyEventResult.handled;
          },
          child: DragTarget<IconMetadata>(
            onAcceptWithDetails: (details) => _handleIconDrop(details, model),
            builder: (context, candidateData, rejectedData) {
              return Listener(
                onPointerSignal: (event) {
                  if (event is PointerScrollEvent) {
                    _handleScrollZoom(event, model);
                  }
                },
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (details) {
                    _handleTapDown(details, model);
                    // Request focus when user clicks on the map
                    _focusNode.requestFocus();
                  },
                  onTapUp: (details) => _handleTapUp(details, model),
                  onScaleStart: _handleScaleStart,
                  onScaleUpdate: (details) => _handleScaleUpdate(details, model),
                  onScaleEnd: _handleScaleEnd,
                  onSecondaryTapDown: (details) {
                    // Prevent default context menu and handle right-click
                    _handleRightClick(details, model);
                  },
                  onDoubleTap: () => _handleDoubleTapForEdit(model),
                  child: MouseRegion(
                    cursor: _getCursor(model),
                    child: CustomPaint(
                      painter: MapPainter(
                        model: model,
                        iconCache: _iconCache,
                        selectedSmear: _selectedSmear,
                        selectedDoseRate: _selectedDoseRate,
                        selectedComment: _selectedComment,
                        selectedBoundary: _selectedBoundary,
                        selectedTitleCard: _selectedTitleCard,
                      ),
                      size: Size.infinite,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  MouseCursor _getCursor(SurveyMapModel model) {
    if (_draggedSmear != null || _draggedDoseRate != null || _draggedIcon != null || _draggedComment != null) {
      return SystemMouseCursors.grabbing;
    }

    switch (model.currentTool) {
      case ToolType.smearAdd:
      case ToolType.doseAdd:
      case ToolType.boundary:
      case ToolType.commentAdd:
        return SystemMouseCursors.precise;
      case ToolType.smearRemove:
      case ToolType.doseRemove:
      case ToolType.boundaryDelete:
      case ToolType.equipmentDelete:
      case ToolType.commentRemove:
        return SystemMouseCursors.click;
      default:
        return SystemMouseCursors.grab;
    }
  }

  void _handleScrollZoom(PointerScrollEvent event, SurveyMapModel model) {
    // Skip trackpad events due to Flutter framework assertion bug
    // This is a known issue in Flutter web with trackpad scrolling
    if (event.kind == PointerDeviceKind.trackpad) {
      return;
    }

    // If title card is selected, resize it instead of zooming
    if (model.selectedTitleCard && model.titleCard != null) {
      final scrollDelta = event.scrollDelta.dy;
      // Invert for natural scaling (scroll up = larger)
      final scaleDelta = -scrollDelta / 500.0;
      final newScale = (model.titleCard!.scale + scaleDelta).clamp(0.5, 3.0);
      model.updateTitleCard(model.titleCard!.copyWith(scale: newScale));
      return;
    }

    // If stats card is selected, resize it instead of zooming
    if (model.selectedStatsCard && model.statsCard != null) {
      final scrollDelta = event.scrollDelta.dy;
      // Invert for natural scaling (scroll up = larger)
      final scaleDelta = -scrollDelta / 500.0;
      final newScale = (model.statsCard!.scale + scaleDelta).clamp(0.5, 3.0);
      model.updateStatsCard(model.statsCard!.copyWith(scale: newScale));
      return;
    }

    // Calculate zoom delta from scroll
    final scrollDelta = event.scrollDelta.dy;

    // Invert scroll direction for natural zoom (scroll up = zoom in)
    final zoomDelta = -scrollDelta / 100.0;

    final size = MediaQuery.of(context).size;
    model.zoom(zoomDelta, event.localPosition, size);
  }

  void _handleTapDown(TapDownDetails details, SurveyMapModel model) {
    debugPrint('TapDown: tool=${model.currentTool}');
    _gestureStartPosition = details.localPosition;
    _lastPanPosition = details.localPosition;
  }

  void _handleTapUp(TapUpDetails details, SurveyMapModel model) {
    debugPrint('TapUp: tool=${model.currentTool}');

    if (_gestureStartPosition == null) return;

    // Check if this was a simple tap (not a drag)
    final distance = (details.localPosition - _gestureStartPosition!).distance;
    if (distance > 10) {
      debugPrint('TapUp: Movement detected ($distance px), ignoring as tap');
      return;
    }

    final pagePosition = model.canvasToPage(details.localPosition);
    debugPrint('TapUp: Handling as tap at $pagePosition');

    // Handle equipment delete
    if (model.currentTool == ToolType.equipmentDelete) {
      final equipment = model.getEquipmentAtPosition(pagePosition);
      if (equipment != null) {
        debugPrint('✓ Deleted: ${equipment.iconFile}');
        model.removeEquipment(equipment);
      } else {
        debugPrint('✗ No icon at tap position (${model.equipment.length} total)');
      }
      return;
    }

    // Handle boundary drawing
    if (model.currentTool == ToolType.boundary) {
      debugPrint('Adding boundary point');
      model.addBoundaryPoint(pagePosition);
      return;
    }

    // Handle boundary delete
    if (model.currentTool == ToolType.boundaryDelete) {
      final boundary = model.getBoundaryAtPosition(pagePosition, 15);
      if (boundary != null) {
        setState(() {
          _selectedBoundary = boundary;
          _selectedSmear = null;
          _selectedDoseRate = null;
          _selectedComment = null;
        });
        model.deleteBoundary(boundary);
      }
      return;
    }

    // Handle annotation addition
    if (model.currentTool == ToolType.smearAdd) {
      debugPrint('Adding smear at $pagePosition');
      model.addSmear(pagePosition);
      return;
    }

    if (model.currentTool == ToolType.doseAdd) {
      debugPrint('Adding dose rate at $pagePosition');
      // Validate dose rate value before showing dialog
      if (!model.validateDoseRateValue()) {
        debugPrint('Dose rate validation failed - no value entered');
        return;
      }
      _showAddDoseRateDialog(model, pagePosition);
      return;
    }

    if (model.currentTool == ToolType.commentAdd) {
      debugPrint('Adding comment at $pagePosition');
      _showAddCommentDialog(model, pagePosition);
      return;
    }

    // Handle smear removal
    if (model.currentTool == ToolType.smearRemove) {
      final smear = model.getSmearAtPosition(pagePosition, 40 / model.scale);
      if (smear != null) {
        model.removeSmear(smear);
      }
      return;
    }

    // Handle dose removal
    if (model.currentTool == ToolType.doseRemove) {
      final dose = model.getDoseRateAtPosition(pagePosition, 50 / model.scale);
      if (dose != null) {
        model.removeDoseRate(dose);
      }
      return;
    }

    // Handle comment removal
    if (model.currentTool == ToolType.commentRemove) {
      final comment = model.getCommentAtPosition(pagePosition, 40 / model.scale);
      if (comment != null) {
        model.removeComment(comment);
      }
      return;
    }

    // Handle selection when no tool active (for keyboard deletion)
    if (model.currentTool == ToolType.none) {
      // Check for equipment/icon first
      final equipment = model.getEquipmentAtPosition(pagePosition);
      if (equipment != null) {
        model.selectIcon(equipment);
        setState(() {
          _selectedSmear = null;
          _selectedDoseRate = null;
          _selectedComment = null;
          _selectedBoundary = null;
          _selectedTitleCard = false;
          _selectedStatsCard = false;
        });
        return;
      }

      // Check for smear
      final smear = model.getSmearAtPosition(pagePosition, 40 / model.scale);
      if (smear != null) {
        model.selectIcon(null); // Clear icon selection
        setState(() {
          _selectedSmear = smear;
          _selectedDoseRate = null;
          _selectedComment = null;
          _selectedBoundary = null;
          _selectedTitleCard = false;
          _selectedStatsCard = false;
        });
        debugPrint('Smear selected: ${smear.id}');
        return;
      }

      // Check for dose rate
      final doseRate = model.getDoseRateAtPosition(pagePosition, 50 / model.scale);
      if (doseRate != null) {
        model.selectIcon(null); // Clear icon selection
        setState(() {
          _selectedSmear = null;
          _selectedDoseRate = doseRate;
          _selectedComment = null;
          _selectedBoundary = null;
          _selectedTitleCard = false;
          _selectedStatsCard = false;
        });
        debugPrint('Dose rate selected');
        return;
      }

      // Check for comment
      final comment = model.getCommentAtPosition(pagePosition, 40 / model.scale);
      if (comment != null) {
        model.selectIcon(null); // Clear icon selection
        setState(() {
          _selectedSmear = null;
          _selectedDoseRate = null;
          _selectedComment = comment;
          _selectedBoundary = null;
          _selectedTitleCard = false;
          _selectedStatsCard = false;
        });
        debugPrint('Comment selected: ${comment.id}');
        return;
      }

      // Check for boundary
      final boundary = model.getBoundaryAtPosition(pagePosition, 15);
      if (boundary != null) {
        model.selectIcon(null); // Clear icon selection
        setState(() {
          _selectedSmear = null;
          _selectedDoseRate = null;
          _selectedComment = null;
          _selectedBoundary = boundary;
          _selectedTitleCard = false;
          _selectedStatsCard = false;
        });
        debugPrint('Boundary selected: ${boundary.id}');
        return;
      }

      // Check for title card
      if (model.isTitleCardAtPosition(pagePosition)) {
        model.selectIcon(null); // Clear icon selection
        model.selectTitleCard(true); // Select title card in model
        setState(() {
          _selectedSmear = null;
          _selectedDoseRate = null;
          _selectedComment = null;
          _selectedBoundary = null;
          _selectedTitleCard = true;
          _selectedStatsCard = false;
        });
        debugPrint('Title card selected');
        return;
      }

      // Check for stats card
      if (model.isStatsCardAtPosition(pagePosition)) {
        model.selectIcon(null); // Clear icon selection
        model.selectStatsCard(true); // Select stats card in model
        setState(() {
          _selectedSmear = null;
          _selectedDoseRate = null;
          _selectedComment = null;
          _selectedBoundary = null;
          _selectedTitleCard = false;
          _selectedStatsCard = true;
        });
        debugPrint('Stats card selected');
        return;
      }

      // Nothing selected - clear all selections
      model.selectIcon(null);
      setState(() {
        _selectedSmear = null;
        _selectedDoseRate = null;
        _selectedComment = null;
        _selectedBoundary = null;
        _selectedTitleCard = false;
        _selectedStatsCard = false;
      });
    }
  }

  void _handleScaleStart(ScaleStartDetails details) {
    final model = context.read<SurveyMapModel>();
    final pagePosition = model.canvasToPage(details.localFocalPoint);

    debugPrint('ScaleStart: tool=${model.currentTool}, pos=${details.localFocalPoint}');

    // Store positions for tap/drag detection
    _gestureStartPosition = details.localFocalPoint;
    _lastPanPosition = details.localFocalPoint;
    _lastScale = 1.0;


    // Only check for dragging when no tool is active
    if (model.currentTool == ToolType.none) {
      debugPrint('Checking for draggable items at page position: $pagePosition');
      debugPrint('Equipment count: ${model.equipment.length}, Dose rates: ${model.doseRates.length}, Smears: ${model.smears.length}');
    } else {
      debugPrint('Tool is active (${model.currentTool}), skipping drag detection');
    }

    if (model.currentTool == ToolType.none) {

      // Check for icon resize handle
      if (model.selectedIcon != null) {
        final handle = model.getResizeHandleAtPosition(
          model.selectedIcon!,
          pagePosition,
          model.scale,
        );
        if (handle != null) {
          model.startResize(handle);
          debugPrint('Resize handle grabbed');
          return;
        }
      }

      // Check for title card drag
      if (model.isTitleCardAtPosition(pagePosition)) {
        model.selectTitleCard(true); // Select title card in model
        setState(() {
          _selectedTitleCard = true;
          _selectedStatsCard = false;
          _selectedSmear = null;
          _selectedDoseRate = null;
          _selectedComment = null;
          _selectedBoundary = null;
        });
        model.selectIcon(null);
        _draggedTitleCard = true;
        _titleCardDragOffset = pagePosition - model.titleCard!.position;
        _titleCardDragStartPosition = model.titleCard!.position;
        debugPrint('Title card drag started');
        return;
      }

      // Check for stats card drag
      if (model.isStatsCardAtPosition(pagePosition)) {
        model.selectStatsCard(true); // Select stats card in model
        setState(() {
          _selectedStatsCard = true;
          _selectedTitleCard = false;
          _selectedSmear = null;
          _selectedDoseRate = null;
          _selectedComment = null;
          _selectedBoundary = null;
        });
        model.selectIcon(null);
        _draggedStatsCard = true;
        _statsCardDragOffset = pagePosition - model.statsCard!.position;
        _statsCardDragStartPosition = model.statsCard!.position;
        debugPrint('Stats card drag started');
        return;
      }

      // Check for icon drag
      final equipment = model.getEquipmentAtPosition(pagePosition);
      debugPrint('Equipment check result: ${equipment != null ? "Found ${equipment.iconFile}" : "None found"}');
      if (equipment != null) {
        debugPrint('Icon drag started: ${equipment.iconFile} at ${equipment.position}');
        model.selectIcon(equipment);
        setState(() {
          _selectedSmear = null;
          _selectedDoseRate = null;
          _selectedComment = null;
          _selectedBoundary = null;
          _selectedTitleCard = false;
          _selectedStatsCard = false;
        });
        _draggedIcon = equipment;
        _iconDragOffset = pagePosition - equipment.position;
        _iconDragStartPosition = equipment.position;
        return;
      }

      // Check for smear drag (increased threshold for easier grabbing)
      final smear = model.getSmearAtPosition(pagePosition, 40 / model.scale);
      if (smear != null) {
        setState(() {
          _selectedSmear = smear;
          _selectedDoseRate = null;
          _selectedComment = null;
          _selectedBoundary = null;
          _selectedTitleCard = false;
          _selectedStatsCard = false;
        });
        _draggedSmear = smear;
        _smearDragOffset = pagePosition - smear.position;
        _smearDragStartPosition = smear.position;
        debugPrint('Smear drag started: ${smear.position}');
        return;
      }

      // Check for dose rate drag (increased threshold for easier grabbing)
      final doseRate = model.getDoseRateAtPosition(pagePosition, 50 / model.scale);
      if (doseRate != null) {
        setState(() {
          _selectedSmear = null;
          _selectedDoseRate = doseRate;
          _selectedComment = null;
          _selectedBoundary = null;
          _selectedTitleCard = false;
          _selectedStatsCard = false;
        });
        _draggedDoseRate = doseRate;
        _doseRateDragOffset = pagePosition - doseRate.position;
        _doseRateDragStartPosition = doseRate.position;
        debugPrint('Dose rate drag started: ${doseRate.position}');
        return;
      }

      // Check for comment drag (increased threshold for easier grabbing)
      final comment = model.getCommentAtPosition(pagePosition, 40 / model.scale);
      if (comment != null) {
        setState(() {
          _selectedSmear = null;
          _selectedDoseRate = null;
          _selectedComment = comment;
          _selectedBoundary = null;
          _selectedTitleCard = false;
          _selectedStatsCard = false;
        });
        _draggedComment = comment;
        _commentDragOffset = pagePosition - comment.position;
        _commentDragStartPosition = comment.position;
        debugPrint('Comment drag started: ${comment.position}');
        return;
      }
    }
  }

  void _handleScaleUpdate(ScaleUpdateDetails details, SurveyMapModel model) {
    debugPrint('ScaleUpdate: pointers=${details.pointerCount}, scale=${details.scale}, focal=${details.localFocalPoint}');
    debugPrint('  _draggedIcon=$_draggedIcon, _draggedDoseRate=$_draggedDoseRate, _draggedSmear=$_draggedSmear');
    debugPrint('  _draggedComment=$_draggedComment, _draggedTitleCard=$_draggedTitleCard, _draggedStatsCard=$_draggedStatsCard');

    if (_draggedTitleCard) {
      debugPrint('→ Dragging title card');
      _dragTitleCard(details.localFocalPoint, model);
      return;
    }

    if (_draggedStatsCard) {
      debugPrint('→ Dragging stats card');
      _dragStatsCard(details.localFocalPoint, model);
      return;
    }

    if (_draggedSmear != null) {
      debugPrint('→ Dragging smear');
      _dragSmear(details.localFocalPoint, model);
      return;
    }

    if (_draggedDoseRate != null) {
      debugPrint('→ Dragging dose rate');
      _dragDoseRate(details.localFocalPoint, model);
      return;
    }

    if (_draggedIcon != null) {
      debugPrint('→ Dragging icon');
      _dragIcon(details.localFocalPoint, model);
      return;
    }

    if (_draggedComment != null) {
      _dragComment(details.localFocalPoint, model);
      return;
    }

    if (model.isResizing) {
      _resizeIcon(details.localFocalPoint, model);
      return;
    }

    // Handle pinch-to-zoom (works on trackpads and touch screens)
    // Note: On web/trackpad, pointerCount might be 1 even during pinch
    if (details.scale != 1.0 && details.scale != _lastScale) {
      // Calculate zoom change from last scale value
      final scaleDelta = details.scale - _lastScale;

      // Only process if there's a significant scale change
      if (scaleDelta.abs() > 0.001) {
        // Convert to zoom delta (similar to mouse wheel)
        // Multiply by a factor to make pinch zoom more responsive
        final zoomDelta = scaleDelta * 10.0;

        final size = MediaQuery.of(context).size;
        model.zoom(zoomDelta, details.localFocalPoint, size);

        _lastScale = details.scale;
        _lastPanPosition = details.localFocalPoint;
        return;
      }
    }

    // Handle pan - only when no tool is active or when using pan-compatible tools
    if (_lastPanPosition != null && model.currentTool == ToolType.none && details.pointerCount == 1) {
      debugPrint('→ Panning map (no items being dragged)');
      final delta = details.localFocalPoint - _lastPanPosition!;
      model.updateOffset(delta);
    }

    // Always update last position for distance tracking (but don't use for panning unless tool is none)
    _lastPanPosition = details.localFocalPoint;
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    final model = context.read<SurveyMapModel>();

    // Check if this was a tap (no significant movement)
    final wasDragging = _draggedSmear != null || _draggedDoseRate != null || _draggedIcon != null || _draggedComment != null || _draggedTitleCard || _draggedStatsCard || model.isResizing;

    bool isTap = false;
    double distance = 0;
    if (_gestureStartPosition != null) {
      if (_lastPanPosition != null) {
        distance = (_lastPanPosition! - _gestureStartPosition!).distance;
        // If moved less than 5 pixels, consider it a tap (more strict for better tap detection)
        isTap = distance < 5.0;
      } else {
        // If _lastPanPosition is null, it means no pan occurred, so it's definitely a tap
        isTap = true;
      }
    }

    debugPrint('ScaleEnd: drag=$wasDragging, dist=${distance.toStringAsFixed(1)}px, tap=$isTap, tool=${model.currentTool}');

    // Create undo/redo commands for completed drags
    if (_draggedSmear != null && _smearDragStartPosition != null && _draggedSmear!.position != _smearDragStartPosition) {
      debugPrint('Smear dragged from $_smearDragStartPosition to ${_draggedSmear!.position}');
      // Add command to undo stack without executing (position already updated via Direct methods)
      model.undoRedoManager.addCommandWithoutExecuting(
        MoveSmearCommand(model, _draggedSmear!, _smearDragStartPosition!, _draggedSmear!.position)
      );
    }

    if (_draggedDoseRate != null && _doseRateDragStartPosition != null && _draggedDoseRate!.position != _doseRateDragStartPosition) {
      debugPrint('Dose rate dragged from $_doseRateDragStartPosition to ${_draggedDoseRate!.position}');
      // Add command to undo stack without executing (position already updated via Direct methods)
      model.undoRedoManager.addCommandWithoutExecuting(
        MoveDoseRateCommand(model, _draggedDoseRate!, _doseRateDragStartPosition!, _draggedDoseRate!.position)
      );
    }

    if (_draggedIcon != null && _iconDragStartPosition != null && _draggedIcon!.position != _iconDragStartPosition) {
      debugPrint('Icon dragged from $_iconDragStartPosition to ${_draggedIcon!.position}');
      // Add command to undo stack without executing (position already updated via Direct methods)
      model.undoRedoManager.addCommandWithoutExecuting(
        MoveEquipmentCommand(model, _draggedIcon!, _iconDragStartPosition!, _draggedIcon!.position)
      );
    }

    if (_draggedComment != null && _commentDragStartPosition != null && _draggedComment!.position != _commentDragStartPosition) {
      debugPrint('Comment dragged from $_commentDragStartPosition to ${_draggedComment!.position}');
      // Add command to undo stack without executing (position already updated via Direct methods)
      model.undoRedoManager.addCommandWithoutExecuting(
        MoveCommentCommand(model, _draggedComment!, _commentDragStartPosition!, _draggedComment!.position)
      );
    }

    // Always handle tap if it's a tap gesture and not dragging
    if (!wasDragging && isTap) {
      // This was a tap, not a drag - handle tool actions
      _handleTap(model);
    }

    _gestureStartPosition = null;
    _lastPanPosition = null;
    _draggedSmear = null;
    _smearDragOffset = null;
    _smearDragStartPosition = null;
    _draggedDoseRate = null;
    _doseRateDragOffset = null;
    _doseRateDragStartPosition = null;
    _draggedIcon = null;
    _iconDragOffset = null;
    _iconDragStartPosition = null;
    _draggedComment = null;
    _commentDragOffset = null;
    _commentDragStartPosition = null;
    _draggedTitleCard = false;
    _titleCardDragOffset = null;
    _titleCardDragStartPosition = null;
    _draggedStatsCard = false;
    _statsCardDragOffset = null;
    _statsCardDragStartPosition = null;
    _lastScale = 1.0;
    model.endResize();
  }

  void _handleTap(SurveyMapModel model) {
    if (_gestureStartPosition == null) {
      debugPrint('_handleTap: gestureStartPosition is null');
      return;
    }

    final pagePosition = model.canvasToPage(_gestureStartPosition!);
    debugPrint('_handleTap called: tool=${model.currentTool}, pagePos=$pagePosition');

    // Handle boundary drawing
    if (model.currentTool == ToolType.boundary) {
      debugPrint('Adding boundary point');
      model.addBoundaryPoint(pagePosition);
      return;
    }

    // Handle boundary delete
    if (model.currentTool == ToolType.boundaryDelete) {
      final boundary = model.getBoundaryAtPosition(pagePosition, 15);
      if (boundary != null) {
        setState(() {
          _selectedBoundary = boundary;
          _selectedSmear = null;
          _selectedDoseRate = null;
          _selectedComment = null;
        });
        model.deleteBoundary(boundary);
      }
      return;
    }

    // Handle annotation addition
    if (model.currentTool == ToolType.smearAdd) {
      debugPrint('Adding smear at $pagePosition');
      model.addSmear(pagePosition);
      return;
    }

    if (model.currentTool == ToolType.doseAdd) {
      debugPrint('Adding dose rate at $pagePosition');
      // Validate dose rate value before showing dialog
      if (!model.validateDoseRateValue()) {
        debugPrint('Dose rate validation failed - no value entered');
        return;
      }
      _showAddDoseRateDialog(model, pagePosition);
      return;
    }

    // Handle smear removal
    if (model.currentTool == ToolType.smearRemove) {
      final smear = model.getSmearAtPosition(pagePosition, 40 / model.scale);
      if (smear != null) {
        model.removeSmear(smear);
      }
      return;
    }

    // Handle dose removal
    if (model.currentTool == ToolType.doseRemove) {
      final dose = model.getDoseRateAtPosition(pagePosition, 50 / model.scale);
      if (dose != null) {
        model.removeDoseRate(dose);
      }
      return;
    }

    // Handle equipment delete
    if (model.currentTool == ToolType.equipmentDelete) {
      final equipment = model.getEquipmentAtPosition(pagePosition);
      if (equipment != null) {
        debugPrint('✓ Deleted: ${equipment.iconFile}');
        model.removeEquipment(equipment);
      } else {
        debugPrint('✗ No icon at click position (${model.equipment.length} total icons)');
      }
      return;
    }

    // Handle comment addition
    if (model.currentTool == ToolType.commentAdd) {
      debugPrint('Comment add detected! Position: $pagePosition');
      _showAddCommentDialog(model, pagePosition);
      return;
    }

    // Handle comment removal
    if (model.currentTool == ToolType.commentRemove) {
      final comment = model.getCommentAtPosition(pagePosition, 40 / model.scale);
      if (comment != null) {
        model.removeComment(comment);
      }
      return;
    }

    // Handle selection when no tool active (for keyboard deletion)
    if (model.currentTool == ToolType.none) {
      // Check for equipment/icon first
      final equipment = model.getEquipmentAtPosition(pagePosition);
      if (equipment != null) {
        model.selectIcon(equipment);
        setState(() {
          _selectedSmear = null;
          _selectedDoseRate = null;
          _selectedComment = null;
          _selectedBoundary = null;
          _selectedTitleCard = false;
          _selectedStatsCard = false;
        });
        return;
      }

      // Check for smear
      final smear = model.getSmearAtPosition(pagePosition, 40 / model.scale);
      if (smear != null) {
        model.selectIcon(null); // Clear icon selection
        setState(() {
          _selectedSmear = smear;
          _selectedDoseRate = null;
          _selectedComment = null;
          _selectedBoundary = null;
          _selectedTitleCard = false;
          _selectedStatsCard = false;
        });
        debugPrint('Smear selected: ${smear.id}');
        return;
      }

      // Check for dose rate
      final doseRate = model.getDoseRateAtPosition(pagePosition, 50 / model.scale);
      if (doseRate != null) {
        model.selectIcon(null); // Clear icon selection
        setState(() {
          _selectedSmear = null;
          _selectedDoseRate = doseRate;
          _selectedComment = null;
          _selectedBoundary = null;
          _selectedTitleCard = false;
          _selectedStatsCard = false;
        });
        debugPrint('Dose rate selected');
        return;
      }

      // Check for comment
      final comment = model.getCommentAtPosition(pagePosition, 40 / model.scale);
      if (comment != null) {
        model.selectIcon(null); // Clear icon selection
        setState(() {
          _selectedSmear = null;
          _selectedDoseRate = null;
          _selectedComment = comment;
          _selectedBoundary = null;
          _selectedTitleCard = false;
          _selectedStatsCard = false;
        });
        debugPrint('Comment selected: ${comment.id}');
        return;
      }

      // Check for boundary
      final boundary = model.getBoundaryAtPosition(pagePosition, 15);
      if (boundary != null) {
        model.selectIcon(null); // Clear icon selection
        setState(() {
          _selectedSmear = null;
          _selectedDoseRate = null;
          _selectedComment = null;
          _selectedBoundary = boundary;
          _selectedTitleCard = false;
          _selectedStatsCard = false;
        });
        debugPrint('Boundary selected: ${boundary.id}');
        return;
      }

      // Check for title card
      if (model.isTitleCardAtPosition(pagePosition)) {
        model.selectIcon(null); // Clear icon selection
        model.selectTitleCard(true); // Select title card in model
        setState(() {
          _selectedSmear = null;
          _selectedDoseRate = null;
          _selectedComment = null;
          _selectedBoundary = null;
          _selectedTitleCard = true;
          _selectedStatsCard = false;
        });
        debugPrint('Title card selected');
        return;
      }

      // Check for stats card
      if (model.isStatsCardAtPosition(pagePosition)) {
        model.selectIcon(null); // Clear icon selection
        model.selectStatsCard(true); // Select stats card in model
        setState(() {
          _selectedSmear = null;
          _selectedDoseRate = null;
          _selectedComment = null;
          _selectedBoundary = null;
          _selectedTitleCard = false;
          _selectedStatsCard = true;
        });
        debugPrint('Stats card selected');
        return;
      }

      // Nothing selected - clear all selections
      model.selectIcon(null);
      setState(() {
        _selectedSmear = null;
        _selectedDoseRate = null;
        _selectedComment = null;
        _selectedBoundary = null;
        _selectedTitleCard = false;
        _selectedStatsCard = false;
      });
    }
  }

  void _handleRightClick(TapDownDetails details, SurveyMapModel model) {
    final pagePosition = model.canvasToPage(details.localPosition);

    // Check if right-clicked on a dose rate (scale-aware threshold)
    final doseRate = model.getDoseRateAtPosition(pagePosition, 50 / model.scale);
    if (doseRate != null) {
      _showEditDoseRateDialog(model, doseRate);
      return;
    }

    // Handle boundary undo point
    if (model.currentTool == ToolType.boundary) {
      model.removeLastBoundaryPoint();
    }
  }

  void _handleDoubleTapForEdit(SurveyMapModel model) {
    if (_gestureStartPosition == null) return;

    final pagePosition = model.canvasToPage(_gestureStartPosition!);

    // Check if double-clicked on a comment (scale-aware threshold)
    final comment = model.getCommentAtPosition(pagePosition, 40 / model.scale);
    if (comment != null) {
      _showEditCommentDialog(model, comment);
      return;
    }

    // Check if double-clicked on a dose rate (scale-aware threshold)
    final doseRate = model.getDoseRateAtPosition(pagePosition, 50 / model.scale);
    if (doseRate != null) {
      _showEditDoseRateDialog(model, doseRate);
      return;
    }

    // Handle boundary double-click (finish drawing)
    if (model.currentTool == ToolType.boundary) {
      model.finishCurrentBoundary();
    }
  }

  void _showEditDoseRateDialog(SurveyMapModel model, DoseRateAnnotation doseRate) {
    final valueController = TextEditingController(text: doseRate.value.toString());
    String selectedUnit = doseRate.unit;
    DoseType selectedType = doseRate.type;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Dose Rate'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: valueController,
                decoration: const InputDecoration(
                  labelText: 'Value',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                autofocus: true,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedUnit,
                decoration: const InputDecoration(
                  labelText: 'Unit',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'μR/hr', child: Text('μR/hr')),
                  DropdownMenuItem(value: 'mR/hr', child: Text('mR/hr')),
                  DropdownMenuItem(value: 'R/hr', child: Text('R/hr')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedUnit = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<DoseType>(
                      title: const Text('Gamma'),
                      value: DoseType.gamma,
                      groupValue: selectedType,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedType = value;
                          });
                        }
                      },
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<DoseType>(
                      title: const Text('Neutron'),
                      value: DoseType.neutron,
                      groupValue: selectedType,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedType = value;
                          });
                        }
                      },
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final newValue = double.tryParse(valueController.text);
                if (newValue != null) {
                  model.editDoseRate(doseRate, newValue, selectedUnit, selectedType);
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid number')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCommentDialog(SurveyMapModel model, Offset pagePosition) {
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Comment'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            labelText: 'Comment Text',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final text = textController.text.trim();
              if (text.isNotEmpty) {
                model.addComment(pagePosition, text);
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter some text')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddDoseRateDialog(SurveyMapModel model, Offset pagePosition) {
    // Simply add the dose rate with the value from the side panel
    model.addDoseRate(pagePosition);
  }

  void _showEditCommentDialog(SurveyMapModel model, CommentAnnotation comment) {
    final textController = TextEditingController(text: comment.text);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Comment #${comment.id}'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            labelText: 'Comment Text',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final text = textController.text.trim();
              if (text.isNotEmpty) {
                model.editComment(comment, text);
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter some text')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleIconDrop(DragTargetDetails<IconMetadata> details, SurveyMapModel model) async {
    final icon = details.data;
    final dropPosition = details.offset;

    print('🎯 Icon drop detected: ${icon.name} (${icon.file}) at $dropPosition');
    print('   Category: ${icon.category}');
    print('   hasAssetPath: ${icon.assetPath != null} ${icon.assetPath != null ? '(${icon.assetPath})' : ''}');
    print('   hasSvgText: ${icon.svgText != null} ${icon.svgText != null ? '(len ${icon.svgText!.length})' : ''}');

    // Convert screen position to page position
    final pagePosition = model.canvasToPage(dropPosition);

    // Get icon content
    String iconContent = '';
    bool isAsset = false;
    if (icon.metadata is Map && icon.metadata['type'] == 'material') {
      iconContent = 'material:${icon.file}';
      print('   → Material icon detected');
    } else {
      iconContent = icon.svgText ?? '';
      if (iconContent.isEmpty && icon.assetPath != null) {
        iconContent = icon.assetPath!;
        isAsset = true;
        print('   → Asset path icon detected: $iconContent');
      } else if (iconContent.isNotEmpty) {
        print('   → Inline SVG detected, length: ${iconContent.length}');
      } else {
        print('   ⚠️  WARNING: No icon content available!');
      }
    }

    // Add equipment at drop position
    final equipment = EquipmentAnnotation(
      position: pagePosition,
      iconFile: icon.file,
      iconSvg: iconContent,
      width: 80,
      height: 80,
    );

    print('   Adding equipment to model: file=${equipment.iconFile}');
    model.addEquipment(equipment);

    // Load the icon for this equipment (await to ensure it's in cache before adding)
    if (icon.metadata is Map && icon.metadata['type'] == 'material') {
      final iconData = icon.metadata['iconData'] as IconData;
      print('   Loading material icon to cache...');
      await _loadMaterialIconToImage(iconData, icon.file);
    } else {
      print('   📥 Loading SVG to cache: ${icon.file} (isAsset: $isAsset, content: ${iconContent.substring(0, iconContent.length.clamp(0, 50))})');
      await _loadSvgToImage(iconContent, icon.file, isAsset: isAsset);
    }

    print('✅ Equipment drop complete. Total equipment: ${model.equipment.length}');
  }

  void _dragSmear(Offset focalPoint, SurveyMapModel model) {
    if (_draggedSmear == null || _smearDragOffset == null) return;

    final pagePosition = model.canvasToPage(focalPoint);
    final newPosition = pagePosition - _smearDragOffset!;

    // Use Direct method to avoid creating undo/redo commands on every frame
    model.updateSmearPositionDirect(_draggedSmear!, newPosition);

    // Update reference to the modified smear
    final index = model.smears.indexWhere((s) => s.id == _draggedSmear!.id);
    if (index != -1) {
      _draggedSmear = model.smears[index];
    }
  }

  void _dragDoseRate(Offset focalPoint, SurveyMapModel model) {
    if (_draggedDoseRate == null || _doseRateDragOffset == null) return;

    final pagePosition = model.canvasToPage(focalPoint);
    final newPosition = pagePosition - _doseRateDragOffset!;

    // Use Direct method to avoid creating undo/redo commands on every frame
    model.updateDoseRatePositionDirect(_draggedDoseRate!, newPosition);

    // Update reference to the modified dose rate by finding the exact same object
    // Use identical() to check object identity, not property equality
    final index = model.doseRates.indexWhere(
      (d) => identical(d, _draggedDoseRate)
    );
    if (index != -1) {
      _draggedDoseRate = model.doseRates[index];
    } else {
      // If we can't find by identity, try to find by the start position
      // This handles the case where the object was replaced
      if (_doseRateDragStartPosition != null) {
        final matchingIndex = model.doseRates.indexWhere(
          (d) => d.value == _draggedDoseRate!.value &&
                 d.unit == _draggedDoseRate!.unit &&
                 d.type == _draggedDoseRate!.type &&
                 (d.position - newPosition).distance < 1.0 // Must be at the current drag position
        );
        if (matchingIndex != -1) {
          _draggedDoseRate = model.doseRates[matchingIndex];
        }
      }
    }
  }

  void _dragIcon(Offset focalPoint, SurveyMapModel model) {
    if (_draggedIcon == null || _iconDragOffset == null) {
      debugPrint('_dragIcon called but _draggedIcon or _iconDragOffset is null');
      return;
    }

    final pagePosition = model.canvasToPage(focalPoint);
    final newPosition = pagePosition - _iconDragOffset!;

    // Use Direct method to avoid creating undo/redo commands on every frame
    model.updateEquipmentPositionDirect(_draggedIcon!, newPosition);

    // Update the _draggedIcon reference to the updated equipment (which is now selectedIcon)
    _draggedIcon = model.selectedIcon;
  }

  void _dragComment(Offset focalPoint, SurveyMapModel model) {
    if (_draggedComment == null || _commentDragOffset == null) return;

    final pagePosition = model.canvasToPage(focalPoint);
    final newPosition = pagePosition - _commentDragOffset!;

    // Use Direct method to avoid creating undo/redo commands on every frame
    model.updateCommentPositionDirect(_draggedComment!, newPosition);

    // Update reference to the modified comment
    final index = model.comments.indexWhere((c) => c.id == _draggedComment!.id);
    if (index != -1) {
      _draggedComment = model.comments[index];
    }
  }

  void _dragTitleCard(Offset focalPoint, SurveyMapModel model) {
    if (!_draggedTitleCard || _titleCardDragOffset == null) return;

    final pagePosition = model.canvasToPage(focalPoint);
    final newPosition = pagePosition - _titleCardDragOffset!;

    debugPrint('Dragging title card to: $newPosition (page: $pagePosition, offset: $_titleCardDragOffset)');

    // Update position directly (no undo/redo needed for title card positioning)
    model.updateTitleCardPosition(newPosition);
  }

  void _dragStatsCard(Offset focalPoint, SurveyMapModel model) {
    if (!_draggedStatsCard || _statsCardDragOffset == null) return;

    final pagePosition = model.canvasToPage(focalPoint);
    final newPosition = pagePosition - _statsCardDragOffset!;

    debugPrint('Dragging stats card to: $newPosition (page: $pagePosition, offset: $_statsCardDragOffset)');

    // Update position directly (no undo/redo needed for stats card positioning)
    model.updateStatsCardPosition(newPosition);
  }

  void _resizeIcon(Offset focalPoint, SurveyMapModel model) {
    if (model.selectedIcon == null || model.resizeHandle == null) return;

    final pagePosition = model.canvasToPage(focalPoint);
    final icon = model.selectedIcon!;
    const minSize = 20.0;
    const maxSize = 200.0;

    double newWidth = icon.width;
    double newHeight = icon.height;

    final aspectRatio = icon.width / icon.height;

    switch (model.resizeHandle!) {
      case ResizeHandle.se:
        newWidth = (pagePosition.dx - (icon.position.dx - icon.width / 2)).abs();
        newHeight = (pagePosition.dy - (icon.position.dy - icon.height / 2)).abs();
        break;
      case ResizeHandle.sw:
        newWidth = ((icon.position.dx + icon.width / 2) - pagePosition.dx).abs();
        newHeight = (pagePosition.dy - (icon.position.dy - icon.height / 2)).abs();
        break;
      case ResizeHandle.ne:
        newWidth = (pagePosition.dx - (icon.position.dx - icon.width / 2)).abs();
        newHeight = ((icon.position.dy + icon.height / 2) - pagePosition.dy).abs();
        break;
      case ResizeHandle.nw:
        newWidth = ((icon.position.dx + icon.width / 2) - pagePosition.dx).abs();
        newHeight = ((icon.position.dy + icon.height / 2) - pagePosition.dy).abs();
        break;
    }

    // Clamp dimensions
    newWidth = newWidth.clamp(minSize, maxSize);
    newHeight = newHeight.clamp(minSize, maxSize);

    // Maintain aspect ratio
    if (newWidth / newHeight > aspectRatio) {
      newWidth = newHeight * aspectRatio;
    } else {
      newHeight = newWidth / aspectRatio;
    }

    model.updateEquipmentSize(icon, newWidth, newHeight);
  }
}
