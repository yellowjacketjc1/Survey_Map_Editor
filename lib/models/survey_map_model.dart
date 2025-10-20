import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'annotation_models.dart';
import 'undo_redo_manager.dart';
import 'commands.dart';

class SurveyMapModel extends ChangeNotifier {
  // PDF data
  Uint8List? _pdfBytes;
  ui.Image? _pdfImage;
  Size _pdfSize = Size.zero;
  String? _mapName; // Name of the currently loaded map

  // Transformation state
  double _rotation = 0;
  double _scale = 1.0;
  Offset _offset = Offset.zero;

  // Annotations
  final List<SmearAnnotation> _smears = [];
  final List<DoseRateAnnotation> _doseRates = [];
  final List<BoundaryAnnotation> _boundaries = [];
  final List<EquipmentAnnotation> _equipment = [];
  final List<CommentAnnotation> _comments = [];

  // Title Card
  TitleCard? _titleCard;

  // Stats Card
  StatsCard? _statsCard;

  // Smear ID counter
  int _nextSmearId = 1;

  // Comment ID counter
  int _nextCommentId = 1;

  // Current tool
  ToolType _currentTool = ToolType.none;

  // Current boundary being drawn
  BoundaryAnnotation? _currentBoundary;

  // Dose rate controls
  double _doseValue = 100;
  String _doseUnit = 'μR/hr';
  DoseType _doseType = DoseType.gamma;

  // Icon selection and resizing
  EquipmentAnnotation? _selectedIcon;
  bool _isResizing = false;
  ResizeHandle? _resizeHandle;

  // Title card selection
  bool _selectedTitleCard = false;

  // Stats card selection
  bool _selectedStatsCard = false;

  // Icon library
  final List<IconMetadata> _iconLibrary = [];
  String _iconSearchQuery = '';
  IconCategory? _iconCategoryFilter;

  // Undo/Redo manager
  final UndoRedoManager undoRedoManager = UndoRedoManager();

  // Getters
  Uint8List? get pdfBytes => _pdfBytes;
  ui.Image? get pdfImage => _pdfImage;
  Size get pdfSize => _pdfSize;
  String? get mapName => _mapName;
  double get rotation => _rotation;
  double get scale => _scale;
  Offset get offset => _offset;
  List<SmearAnnotation> get smears => List.unmodifiable(_smears);
  List<DoseRateAnnotation> get doseRates => List.unmodifiable(_doseRates);
  List<BoundaryAnnotation> get boundaries => List.unmodifiable(_boundaries);
  List<EquipmentAnnotation> get equipment => List.unmodifiable(_equipment);
  List<CommentAnnotation> get comments => List.unmodifiable(_comments);
  TitleCard? get titleCard => _titleCard;
  StatsCard? get statsCard => _statsCard;
  int get nextSmearId => _nextSmearId;
  int get nextCommentId => _nextCommentId;
  ToolType get currentTool => _currentTool;
  BoundaryAnnotation? get currentBoundary => _currentBoundary;
  double get doseValue => _doseValue;
  String get doseUnit => _doseUnit;
  DoseType get doseType => _doseType;
  EquipmentAnnotation? get selectedIcon => _selectedIcon;
  bool get isResizing => _isResizing;
  ResizeHandle? get resizeHandle => _resizeHandle;
  bool get selectedTitleCard => _selectedTitleCard;
  bool get selectedStatsCard => _selectedStatsCard;
  List<IconMetadata> get iconLibrary => List.unmodifiable(_iconLibrary);
  String get iconSearchQuery => _iconSearchQuery;
  IconCategory? get iconCategoryFilter => _iconCategoryFilter;

  bool get hasPdf => _pdfImage != null;

  // Helper to get highest dose rate across all annotations
  ({double value, String unit, DoseType type})? get highestDoseRate {
    if (_doseRates.isEmpty) return null;

    double maxInMicroRem = 0.0;
    DoseRateAnnotation? maxDoseRate;

    for (final doseRate in _doseRates) {
      // Convert all to microrem for comparison
      double valueInMicroRem = doseRate.value;

      if (doseRate.unit.contains('mR') || doseRate.unit.contains('mrem')) {
        // milli = 1000 micro
        valueInMicroRem = doseRate.value * 1000;
      } else if (doseRate.unit.contains('R/') && !doseRate.unit.contains('μ') && !doseRate.unit.contains('m')) {
        // R/hr (Roentgen) = 1,000,000 microrem
        valueInMicroRem = doseRate.value * 1000000;
      }
      // else assume already in micro (μR, μrem)

      if (valueInMicroRem > maxInMicroRem) {
        maxInMicroRem = valueInMicroRem;
        maxDoseRate = doseRate;
      }
    }

    if (maxDoseRate == null) return null;

    return (
      value: maxDoseRate.value,
      unit: maxDoseRate.unit,
      type: maxDoseRate.type,
    );
  }

  // Filtered icons
  List<IconMetadata> get filteredIcons {
    return _iconLibrary.where((icon) {
      final matchesSearch = _iconSearchQuery.isEmpty ||
          icon.keywords.any((keyword) =>
              keyword.toLowerCase().contains(_iconSearchQuery.toLowerCase()));
      final matchesCategory =
          _iconCategoryFilter == null || icon.category == _iconCategoryFilter;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  // PDF loading
  void setPdfBytes(Uint8List bytes, {String? mapName}) {
    _pdfBytes = bytes;
    if (mapName != null) {
      _mapName = mapName;
    }
    notifyListeners();
  }

  void setPdfImage(ui.Image image, {String? mapName}) {
    _pdfImage = image;
    _pdfSize = Size(image.width.toDouble(), image.height.toDouble());
    if (mapName != null) {
      _mapName = mapName;
    }

    // Initialize title card if it doesn't exist
    initializeTitleCard(_pdfSize);

    notifyListeners();
  }

  void setMapName(String? name) {
    _mapName = name;
    notifyListeners();
  }

  // Transformation methods
  void setRotation(double value) {
    _rotation = value;
    notifyListeners();
  }

  void setScale(double value) {
    _scale = value;
    notifyListeners();
  }

  void setOffset(Offset value) {
    _offset = value;
    notifyListeners();
  }

  void updateOffset(Offset delta) {
    _offset += delta;
    notifyListeners();
  }

  void zoom(double delta, Offset focalPoint, Size canvasSize) {
    const zoomIntensity = 0.1;
    final scaleFactor = 1 + delta * zoomIntensity;

    // Position of the focal point relative to the transformed page
    final worldX = (focalPoint.dx - _offset.dx) / _scale;
    final worldY = (focalPoint.dy - _offset.dy) / _scale;

    _scale *= scaleFactor;
    _scale = _scale.clamp(0.1, 5.0);

    // Adjust offset to keep the point under focus stationary
    _offset = Offset(
      focalPoint.dx - worldX * _scale,
      focalPoint.dy - worldY * _scale,
    );

    notifyListeners();
  }

  void resetView(Size canvasSize) {
    if (_pdfSize == Size.zero) return;

    // Calculate scale to fit
    final scaleX = canvasSize.width / _pdfSize.width;
    final scaleY = canvasSize.height / _pdfSize.height;
    _scale = (scaleX < scaleY ? scaleX : scaleY) * 0.95;

    // Center the page
    _offset = Offset(
      (canvasSize.width - (_pdfSize.width * _scale)) / 2,
      (canvasSize.height - (_pdfSize.height * _scale)) / 2,
    );

    _rotation = 0;
    notifyListeners();
  }

  // Tool management
  void setTool(ToolType tool) {
    debugPrint('setTool called: $tool, current: $_currentTool');

    // Allow all tools to toggle on/off
    if (_currentTool == tool) {
      _currentTool = ToolType.none;
      debugPrint('Tool toggled off, now: $_currentTool');
      if (tool == ToolType.boundary) {
        finishCurrentBoundary();
      }
    } else {
      _currentTool = tool;
      debugPrint('Tool set to: $_currentTool');
      if (_currentTool != ToolType.boundary) {
        finishCurrentBoundary();
      }
    }
    notifyListeners();
  }

  void clearTool() {
    _currentTool = ToolType.none;
    notifyListeners();
  }

  // Smear methods (with undo/redo)
  void addSmear(Offset position) {
    final smear = SmearAnnotation(
      id: _nextSmearId++,
      position: position,
    );
    undoRedoManager.executeCommand(AddSmearCommand(this, smear));
    debugPrint('✓ Smear added at $position, total: ${_smears.length}');
  }

  void removeSmear(SmearAnnotation smear) {
    final index = _smears.indexOf(smear);
    if (index != -1) {
      undoRedoManager.executeCommand(RemoveSmearCommand(this, smear, index));
    }
  }

  void updateSmearPosition(SmearAnnotation smear, Offset newPosition) {
    final oldPosition = smear.position;
    if (oldPosition != newPosition) {
      undoRedoManager.executeCommand(MoveSmearCommand(this, smear, oldPosition, newPosition));
    }
  }

  // Direct methods (used by commands, no undo/redo)
  void addSmearDirect(SmearAnnotation smear) {
    _smears.add(smear);
    notifyListeners();
  }

  void addSmearDirectAt(SmearAnnotation smear, int index) {
    _smears.insert(index, smear);
    notifyListeners();
  }

  void removeSmearDirect(SmearAnnotation smear) {
    _smears.remove(smear);
    renumberSmears();
    notifyListeners();
  }

  void updateSmearPositionDirect(SmearAnnotation smear, Offset newPosition) {
    final index = _smears.indexOf(smear);
    if (index != -1) {
      _smears[index] = smear.copyWith(position: newPosition);
      notifyListeners();
    }
  }

  void renumberSmears() {
    _smears.sort((a, b) => a.id.compareTo(b.id));
    for (int i = 0; i < _smears.length; i++) {
      _smears[i] = _smears[i].copyWith(id: i + 1);
    }
    _nextSmearId = _smears.length + 1;
  }

  SmearAnnotation? getSmearAtPosition(Offset position, double threshold) {
    for (final smear in _smears.reversed) {
      final distance = (smear.position - position).distance;
      if (distance < threshold) {
        return smear;
      }
    }
    return null;
  }

  // Dose rate methods
  void setDoseValue(double value) {
    _doseValue = value;
    notifyListeners();
  }

  void setDoseUnit(String unit) {
    _doseUnit = unit;
    notifyListeners();
  }

  void setDoseType(DoseType type) {
    _doseType = type;
    notifyListeners();
  }

  void addDoseRate(Offset position) {
    final doseRate = DoseRateAnnotation(
      position: position,
      value: _doseValue,
      unit: _doseUnit,
      type: _doseType,
    );
    undoRedoManager.executeCommand(AddDoseRateCommand(this, doseRate));
    debugPrint('✓ Dose rate added at $position: $_doseValue $_doseUnit, total: ${_doseRates.length}');
  }

  void removeDoseRate(DoseRateAnnotation doseRate) {
    final index = _doseRates.indexOf(doseRate);
    if (index != -1) {
      undoRedoManager.executeCommand(RemoveDoseRateCommand(this, doseRate, index));
    }
  }

  void updateDoseRatePosition(DoseRateAnnotation doseRate, Offset newPosition) {
    final oldPosition = doseRate.position;
    if (oldPosition != newPosition) {
      undoRedoManager.executeCommand(MoveDoseRateCommand(this, doseRate, oldPosition, newPosition));
    }
  }

  void editDoseRate(DoseRateAnnotation oldDoseRate, double newValue, String newUnit, DoseType newType) {
    final index = _doseRates.indexOf(oldDoseRate);
    if (index != -1) {
      final newDoseRate = oldDoseRate.copyWith(
        value: newValue,
        unit: newUnit,
        type: newType,
      );
      undoRedoManager.executeCommand(EditDoseRateCommand(this, oldDoseRate, newDoseRate, index));
    }
  }

  // Direct methods (used by commands, no undo/redo)
  void addDoseRateDirect(DoseRateAnnotation doseRate) {
    _doseRates.add(doseRate);
    notifyListeners();
  }

  void addDoseRateDirectAt(DoseRateAnnotation doseRate, int index) {
    _doseRates.insert(index, doseRate);
    notifyListeners();
  }

  void removeDoseRateDirect(DoseRateAnnotation doseRate) {
    _doseRates.remove(doseRate);
    notifyListeners();
  }

  void updateDoseRatePositionDirect(DoseRateAnnotation doseRate, Offset newPosition) {
    final index = _doseRates.indexOf(doseRate);
    if (index != -1) {
      _doseRates[index] = doseRate.copyWith(position: newPosition);
      notifyListeners();
    }
  }

  void updateDoseRateAt(int index, DoseRateAnnotation doseRate) {
    if (index >= 0 && index < _doseRates.length) {
      _doseRates[index] = doseRate;
      notifyListeners();
    }
  }

  DoseRateAnnotation? getDoseRateAtPosition(Offset position, double threshold) {
    for (final doseRate in _doseRates.reversed) {
      final distance = (doseRate.position - position).distance;
      if (distance < threshold) {
        return doseRate;
      }
    }
    return null;
  }

  // Boundary methods
  void addBoundaryPoint(Offset position) {
    if (_currentBoundary == null) {
      _currentBoundary = BoundaryAnnotation(
        points: [position],
        id: DateTime.now().millisecondsSinceEpoch,
      );
    } else {
      _currentBoundary!.points.add(position);
    }
    notifyListeners();
  }

  void removeLastBoundaryPoint() {
    if (_currentBoundary != null && _currentBoundary!.points.isNotEmpty) {
      _currentBoundary!.points.removeLast();
      if (_currentBoundary!.points.isEmpty) {
        _currentBoundary = null;
      }
      notifyListeners();
    }
  }

  void finishCurrentBoundary() {
    if (_currentBoundary != null && _currentBoundary!.points.length > 1) {
      final boundary = _currentBoundary!;
      _currentBoundary = null;
      undoRedoManager.executeCommand(AddBoundaryCommand(this, boundary));
    } else {
      _currentBoundary = null;
      notifyListeners();
    }
  }

  void deleteBoundary(BoundaryAnnotation boundary) {
    final index = _boundaries.indexOf(boundary);
    if (index != -1) {
      undoRedoManager.executeCommand(DeleteBoundaryCommand(this, boundary, index));
    }
  }

  // Direct methods (used by commands)
  void addBoundaryDirect(BoundaryAnnotation boundary) {
    _boundaries.add(boundary);
    notifyListeners();
  }

  void addBoundaryDirectAt(BoundaryAnnotation boundary, int index) {
    _boundaries.insert(index, boundary);
    notifyListeners();
  }

  void deleteBoundaryDirect(BoundaryAnnotation boundary) {
    _boundaries.remove(boundary);
    notifyListeners();
  }

  BoundaryAnnotation? getBoundaryAtPosition(Offset position, double threshold) {
    for (final boundary in _boundaries.reversed) {
      if (boundary.points.length < 2) continue;

      for (int i = 0; i < boundary.points.length - 1; i++) {
        final p1 = boundary.points[i];
        final p2 = boundary.points[i + 1];
        final distance = _distanceToLineSegment(position, p1, p2);
        if (distance <= threshold) {
          return boundary;
        }
      }
    }
    return null;
  }

  double _distanceToLineSegment(Offset p, Offset p1, Offset p2) {
    final a = p.dx - p1.dx;
    final b = p.dy - p1.dy;
    final c = p2.dx - p1.dx;
    final d = p2.dy - p1.dy;

    final dot = a * c + b * d;
    final lenSq = c * c + d * d;

    if (lenSq == 0) {
      return (p - p1).distance;
    }

    double param = dot / lenSq;
    param = param.clamp(0.0, 1.0);

    final xx = p1.dx + param * c;
    final yy = p1.dy + param * d;

    final dx = p.dx - xx;
    final dy = p.dy - yy;

    return sqrt(dx * dx + dy * dy);
  }

  // Equipment methods (with undo/redo)
  void addEquipment(EquipmentAnnotation equipment) {
    undoRedoManager.executeCommand(AddEquipmentCommand(this, equipment));
  }

  void removeEquipment(EquipmentAnnotation equipment) {
    final index = _equipment.indexWhere((e) => e.id == equipment.id);
    if (index != -1) {
      undoRedoManager.executeCommand(RemoveEquipmentCommand(this, equipment, index));
    }
  }

  void updateEquipmentPosition(EquipmentAnnotation equipment, Offset newPosition) {
    final oldPosition = equipment.position;
    if (oldPosition != newPosition) {
      undoRedoManager.executeCommand(MoveEquipmentCommand(this, equipment, oldPosition, newPosition));
    }
  }

  void updateEquipmentSize(EquipmentAnnotation equipment, double width, double height) {
    final oldWidth = equipment.width;
    final oldHeight = equipment.height;
    if (oldWidth != width || oldHeight != height) {
      undoRedoManager.executeCommand(
        ResizeEquipmentCommand(this, equipment, oldWidth, oldHeight, width, height),
      );
    }
  }

  void updateEquipmentRotation(EquipmentAnnotation equipment, double rotation) {
    final oldRotation = equipment.rotation;
    if (oldRotation != rotation) {
      undoRedoManager.executeCommand(
        RotateEquipmentCommand(this, equipment, oldRotation, rotation),
      );
    }
  }

  // Direct methods (used by commands, no undo/redo)
  void addEquipmentDirect(EquipmentAnnotation equipment) {
    _equipment.add(equipment);
    notifyListeners();
  }

  void addEquipmentDirectAt(EquipmentAnnotation equipment, int index) {
    _equipment.insert(index, equipment);
    notifyListeners();
  }

  void removeEquipmentDirect(EquipmentAnnotation equipment) {
    final index = _equipment.indexWhere((e) => e.id == equipment.id);
    if (index != -1) {
      _equipment.removeAt(index);
      if (_selectedIcon?.id == equipment.id) {
        _selectedIcon = null;
      }
      notifyListeners();
    }
  }

  void updateEquipmentPositionDirect(EquipmentAnnotation equipment, Offset newPosition) {
    final index = _equipment.indexWhere((e) => e.id == equipment.id);
    if (index != -1) {
      _equipment[index] = equipment.copyWith(position: newPosition);
      if (_selectedIcon?.id == equipment.id) {
        _selectedIcon = _equipment[index];
      }
      notifyListeners();
    }
  }

  void updateEquipmentSizeDirect(EquipmentAnnotation equipment, double width, double height) {
    final index = _equipment.indexWhere((e) => e.id == equipment.id);
    if (index != -1) {
      _equipment[index] = equipment.copyWith(width: width, height: height);
      if (_selectedIcon?.id == equipment.id) {
        _selectedIcon = _equipment[index];
      }
      notifyListeners();
    }
  }

  void updateEquipmentRotationDirect(EquipmentAnnotation equipment, double rotation) {
    final index = _equipment.indexWhere((e) => e.id == equipment.id);
    if (index != -1) {
      _equipment[index] = equipment.copyWith(rotation: rotation);
      if (_selectedIcon?.id == equipment.id) {
        _selectedIcon = _equipment[index];
      }
      notifyListeners();
    }
  }

  EquipmentAnnotation? getEquipmentAtPosition(Offset position) {
    for (final equipment in _equipment.reversed) {
      // Use minimal 3px padding for very precise click detection
      final padding = 3.0;
      final halfWidth = (equipment.width / 2) + padding;
      final halfHeight = (equipment.height / 2) + padding;

      if (position.dx >= equipment.position.dx - halfWidth &&
          position.dx <= equipment.position.dx + halfWidth &&
          position.dy >= equipment.position.dy - halfHeight &&
          position.dy <= equipment.position.dy + halfHeight) {
        return equipment;
      }
    }
    return null;
  }

  // Title Card methods
  void initializeTitleCard(Size pdfSize) {
    if (_titleCard == null) {
      // Position in bottom-right corner with 20px padding
      _titleCard = TitleCard(
        position: Offset(pdfSize.width - 250, pdfSize.height - 180),
      );
      notifyListeners();
    }
    // Also initialize stats card
    if (_statsCard == null) {
      // Position in bottom-left corner with 20px padding
      _statsCard = StatsCard(
        position: Offset(20, pdfSize.height - 120),
      );
      notifyListeners();
    }
  }

  void updateTitleCardField({
    String? surveyId,
    String? surveyorName,
    DateTime? date,
    String? buildingNumber,
    String? roomNumber,
    bool? visible,
  }) {
    if (_titleCard != null) {
      _titleCard = _titleCard!.copyWith(
        surveyId: surveyId,
        surveyorName: surveyorName,
        date: date,
        buildingNumber: buildingNumber,
        roomNumber: roomNumber,
        visible: visible,
      );
      notifyListeners();
    }
  }

  void updateTitleCardPosition(Offset newPosition) {
    if (_titleCard != null) {
      _titleCard = _titleCard!.copyWith(position: newPosition);
      notifyListeners();
    }
  }

  void toggleTitleCardVisibility() {
    if (_titleCard != null) {
      _titleCard = _titleCard!.copyWith(visible: !_titleCard!.visible);
      notifyListeners();
    }
  }

  void updateTitleCard(TitleCard updatedCard) {
    _titleCard = updatedCard;
    notifyListeners();
  }

  void selectTitleCard(bool selected) {
    _selectedTitleCard = selected;
    notifyListeners();
  }

  bool isTitleCardAtPosition(Offset position) {
    if (_titleCard == null || !_titleCard!.visible) return false;

    // Title card is approximately 240x210 pixels (increased to include statistics)
    const width = 240.0;
    const height = 210.0;

    final scaledWidth = width * _titleCard!.scale;
    final scaledHeight = height * _titleCard!.scale;

    return position.dx >= _titleCard!.position.dx &&
        position.dx <= _titleCard!.position.dx + scaledWidth &&
        position.dy >= _titleCard!.position.dy &&
        position.dy <= _titleCard!.position.dy + scaledHeight;
  }

  // Stats Card methods
  void updateStatsCard(StatsCard updatedCard) {
    _statsCard = updatedCard;
    notifyListeners();
  }

  void updateStatsCardPosition(Offset newPosition) {
    if (_statsCard != null) {
      _statsCard = _statsCard!.copyWith(position: newPosition);
      notifyListeners();
    }
  }

  void selectStatsCard(bool selected) {
    _selectedStatsCard = selected;
    notifyListeners();
  }

  bool isStatsCardAtPosition(Offset position) {
    if (_statsCard == null || !_statsCard!.visible) return false;

    // Stats card is approximately 200x100 pixels
    const width = 200.0;
    const height = 100.0;

    final scaledWidth = width * _statsCard!.scale;
    final scaledHeight = height * _statsCard!.scale;

    return position.dx >= _statsCard!.position.dx &&
        position.dx <= _statsCard!.position.dx + scaledWidth &&
        position.dy >= _statsCard!.position.dy &&
        position.dy <= _statsCard!.position.dy + scaledHeight;
  }

  // Icon selection
  void selectIcon(EquipmentAnnotation? icon) {
    _selectedIcon = icon;
    notifyListeners();
  }

  void startResize(ResizeHandle handle) {
    _isResizing = true;
    _resizeHandle = handle;
    notifyListeners();
  }

  void endResize() {
    _isResizing = false;
    _resizeHandle = null;
    notifyListeners();
  }

  ResizeHandle? getResizeHandleAtPosition(
      EquipmentAnnotation equipment, Offset position, double scale) {
    final halfWidth = equipment.width / 2;
    final halfHeight = equipment.height / 2;
    final handleSize = 8 / scale;
    final margin = 5 / scale;

    final handles = {
      ResizeHandle.nw: Offset(
          equipment.position.dx - halfWidth - margin,
          equipment.position.dy - halfHeight - margin),
      ResizeHandle.ne: Offset(
          equipment.position.dx + halfWidth + margin,
          equipment.position.dy - halfHeight - margin),
      ResizeHandle.sw: Offset(
          equipment.position.dx - halfWidth - margin,
          equipment.position.dy + halfHeight + margin),
      ResizeHandle.se: Offset(
          equipment.position.dx + halfWidth + margin,
          equipment.position.dy + halfHeight + margin),
    };

    for (final entry in handles.entries) {
      if ((position - entry.value).distance < handleSize) {
        return entry.key;
      }
    }
    return null;
  }

  // Comment methods (with undo/redo)
  void addComment(Offset position, String text) {
    final comment = CommentAnnotation(
      id: _nextCommentId++,
      position: position,
      text: text,
    );
    undoRedoManager.executeCommand(AddCommentCommand(this, comment));
    debugPrint('✓ Comment added at $position, total: ${_comments.length}');
  }

  void removeComment(CommentAnnotation comment) {
    final index = _comments.indexOf(comment);
    if (index != -1) {
      undoRedoManager.executeCommand(RemoveCommentCommand(this, comment, index));
    }
  }

  void updateCommentPosition(CommentAnnotation comment, Offset newPosition) {
    final oldPosition = comment.position;
    if (oldPosition != newPosition) {
      undoRedoManager.executeCommand(MoveCommentCommand(this, comment, oldPosition, newPosition));
    }
  }

  void editComment(CommentAnnotation oldComment, String newText) {
    final index = _comments.indexOf(oldComment);
    if (index != -1) {
      final newComment = oldComment.copyWith(text: newText);
      undoRedoManager.executeCommand(EditCommentCommand(this, oldComment, newComment, index));
    }
  }

  // Direct methods (used by commands, no undo/redo)
  void addCommentDirect(CommentAnnotation comment) {
    _comments.add(comment);
    notifyListeners();
  }

  void addCommentDirectAt(CommentAnnotation comment, int index) {
    _comments.insert(index, comment);
    notifyListeners();
  }

  void removeCommentDirect(CommentAnnotation comment) {
    _comments.remove(comment);
    renumberComments();
    notifyListeners();
  }

  void updateCommentPositionDirect(CommentAnnotation comment, Offset newPosition) {
    final index = _comments.indexOf(comment);
    if (index != -1) {
      _comments[index] = comment.copyWith(position: newPosition);
      notifyListeners();
    }
  }

  void updateCommentAt(int index, CommentAnnotation comment) {
    if (index >= 0 && index < _comments.length) {
      _comments[index] = comment;
      notifyListeners();
    }
  }

  void renumberComments() {
    _comments.sort((a, b) => a.id.compareTo(b.id));
    for (int i = 0; i < _comments.length; i++) {
      _comments[i] = _comments[i].copyWith(id: i + 1);
    }
    _nextCommentId = _comments.length + 1;
  }

  CommentAnnotation? getCommentAtPosition(Offset position, double threshold) {
    for (final comment in _comments.reversed) {
      final distance = (comment.position - position).distance;
      if (distance < threshold) {
        return comment;
      }
    }
    return null;
  }

  // Icon library
  void setIconLibrary(List<IconMetadata> icons) {
    _iconLibrary.clear();
    _iconLibrary.addAll(icons);
    notifyListeners();
  }

  void setIconSearchQuery(String query) {
    _iconSearchQuery = query;
    notifyListeners();
  }

  void setIconCategoryFilter(IconCategory? category) {
    _iconCategoryFilter = category;
    notifyListeners();
  }

  // Clear all
  void clearAllAnnotations() {
    _smears.clear();
    _doseRates.clear();
    _boundaries.clear();
    _equipment.clear();
    _comments.clear();
    _currentBoundary = null;
    _nextSmearId = 1;
    _nextCommentId = 1;
    _selectedIcon = null;
    notifyListeners();
  }

  // Save/Load functionality
  Map<String, dynamic> toJson({bool includeImage = false}) {
    return {
      'version': '1.0',
      'mapName': _mapName,
      'rotation': _rotation,
      'scale': _scale,
      'offset': {'dx': _offset.dx, 'dy': _offset.dy},
      'smears': _smears.map((s) => s.toJson()).toList(),
      'doseRates': _doseRates.map((d) => d.toJson()).toList(),
      'boundaries': _boundaries.map((b) => b.toJson()).toList(),
      'equipment': _equipment.map((e) => e.toJson()).toList(),
      'comments': _comments.map((c) => c.toJson()).toList(),
      'titleCard': _titleCard?.toJson(),
      'statsCard': _statsCard?.toJson(),
      'nextSmearId': _nextSmearId,
      'nextCommentId': _nextCommentId,
      // Only include image if explicitly requested (for export)
      // For save, we'll track the map name instead
      if (includeImage && _pdfBytes != null)
        'pdfBytes': base64Encode(_pdfBytes!),
    };
  }

  Future<void> fromJson(Map<String, dynamic> json) async {
    // Clear existing data
    _smears.clear();
    _doseRates.clear();
    _boundaries.clear();
    _equipment.clear();
    _comments.clear();
    undoRedoManager.clear();

    // Load metadata
    _mapName = json['mapName'] as String?;

    // Load data
    _rotation = (json['rotation'] as num?)?.toDouble() ?? 0;
    _scale = (json['scale'] as num?)?.toDouble() ?? 1.0;
    if (json['offset'] != null) {
      final offset = json['offset'] as Map<String, dynamic>;
      _offset = Offset(
        (offset['dx'] as num).toDouble(),
        (offset['dy'] as num).toDouble(),
      );
    }

    // Load annotations
    if (json['smears'] != null) {
      for (final smearJson in json['smears'] as List) {
        _smears.add(SmearAnnotation.fromJson(smearJson as Map<String, dynamic>));
      }
    }

    if (json['doseRates'] != null) {
      for (final doseJson in json['doseRates'] as List) {
        _doseRates.add(DoseRateAnnotation.fromJson(doseJson as Map<String, dynamic>));
      }
    }

    if (json['boundaries'] != null) {
      for (final boundaryJson in json['boundaries'] as List) {
        _boundaries.add(BoundaryAnnotation.fromJson(boundaryJson as Map<String, dynamic>));
      }
    }

    if (json['equipment'] != null) {
      for (final equipmentJson in json['equipment'] as List) {
        _equipment.add(EquipmentAnnotation.fromJson(equipmentJson as Map<String, dynamic>));
      }
    }

    if (json['comments'] != null) {
      for (final commentJson in json['comments'] as List) {
        _comments.add(CommentAnnotation.fromJson(commentJson as Map<String, dynamic>));
      }
    }

    if (json['titleCard'] != null) {
      _titleCard = TitleCard.fromJson(json['titleCard'] as Map<String, dynamic>);
    }

    if (json['statsCard'] != null) {
      _statsCard = StatsCard.fromJson(json['statsCard'] as Map<String, dynamic>);
    }

    _nextSmearId = (json['nextSmearId'] as int?) ?? 1;
    _nextCommentId = (json['nextCommentId'] as int?) ?? 1;

    // Load PDF if available
    if (json['pdfBytes'] != null) {
      _pdfBytes = base64Decode(json['pdfBytes'] as String);
      // Note: PDF image will need to be reloaded separately
    }

    notifyListeners();
  }

  // Coordinate transformations
  Offset canvasToPage(Offset canvasPoint) {
    if (_rotation == 0) {
      return Offset(
        (canvasPoint.dx - _offset.dx) / _scale,
        (canvasPoint.dy - _offset.dy) / _scale,
      );
    } else {
      final centerX = _pdfSize.width / 2;
      final centerY = _pdfSize.height / 2;

      double x = (canvasPoint.dx - _offset.dx) / _scale;
      double y = (canvasPoint.dy - _offset.dy) / _scale;

      x -= centerX;
      y -= centerY;

      final radians = -_rotation * 3.14159265359 / 180;
      final cosValue = cos(radians);
      final sinValue = sin(radians);

      return Offset(
        x * cosValue - y * sinValue + centerX,
        x * sinValue + y * cosValue + centerY,
      );
    }
  }

  Offset pageToCanvas(Offset pagePoint) {
    if (_rotation == 0) {
      return Offset(
        pagePoint.dx * _scale + _offset.dx,
        pagePoint.dy * _scale + _offset.dy,
      );
    } else {
      final centerX = _pdfSize.width / 2;
      final centerY = _pdfSize.height / 2;

      double x = pagePoint.dx - centerX;
      double y = pagePoint.dy - centerY;

      final radians = _rotation * 3.14159265359 / 180;
      final cosValue = cos(radians);
      final sinValue = sin(radians);

      final rotatedX = x * cosValue - y * sinValue + centerX;
      final rotatedY = x * sinValue + y * cosValue + centerY;

      return Offset(
        rotatedX * _scale + _offset.dx,
        rotatedY * _scale + _offset.dy,
      );
    }
  }
}
