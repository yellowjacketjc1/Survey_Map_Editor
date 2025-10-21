import 'package:flutter/material.dart';

/// Represents a smear annotation
class SmearAnnotation {
  int id;
  Offset position;

  SmearAnnotation({
    required this.id,
    required this.position,
  });

  SmearAnnotation copyWith({int? id, Offset? position}) {
    return SmearAnnotation(
      id: id ?? this.id,
      position: position ?? this.position,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'x': position.dx,
      'y': position.dy,
    };
  }

  factory SmearAnnotation.fromJson(Map<String, dynamic> json) {
    return SmearAnnotation(
      id: json['id'] as int,
      position: Offset(
        (json['x'] as num).toDouble(),
        (json['y'] as num).toDouble(),
      ),
    );
  }
}

/// Represents a dose rate annotation
class DoseRateAnnotation {
  Offset position;
  double value;
  String unit;
  DoseType type;
  double fontSize;

  DoseRateAnnotation({
    required this.position,
    required this.value,
    this.unit = 'μR/hr',
    this.type = DoseType.gamma,
    this.fontSize = 24.0,
  });

  DoseRateAnnotation copyWith({
    Offset? position,
    double? value,
    String? unit,
    DoseType? type,
    double? fontSize,
  }) {
    return DoseRateAnnotation(
      position: position ?? this.position,
      value: value ?? this.value,
      unit: unit ?? this.unit,
      type: type ?? this.type,
      fontSize: fontSize ?? this.fontSize,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'x': position.dx,
      'y': position.dy,
      'value': value,
      'unit': unit,
      'type': type.name,
      'fontSize': fontSize,
    };
  }

  factory DoseRateAnnotation.fromJson(Map<String, dynamic> json) {
    return DoseRateAnnotation(
      position: Offset(
        (json['x'] as num).toDouble(),
        (json['y'] as num).toDouble(),
      ),
      value: (json['value'] as num).toDouble(),
      unit: json['unit'] as String? ?? 'μR/hr',
      type: DoseType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => DoseType.gamma,
      ),
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 14.0,
    );
  }
}

enum DoseType {
  gamma,
  neutron,
}

/// Represents a boundary (polygon)
class BoundaryAnnotation {
  List<Offset> points;
  int id;

  BoundaryAnnotation({
    required this.points,
    required this.id,
  });

  BoundaryAnnotation copyWith({List<Offset>? points, int? id}) {
    return BoundaryAnnotation(
      points: points ?? List.from(this.points),
      id: id ?? this.id,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'points': points.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
    };
  }

  factory BoundaryAnnotation.fromJson(Map<String, dynamic> json) {
    return BoundaryAnnotation(
      id: json['id'] as int,
      points: (json['points'] as List)
          .map((p) => Offset(
                (p['x'] as num).toDouble(),
                (p['y'] as num).toDouble(),
              ))
          .toList(),
    );
  }
}

/// Represents an equipment/icon annotation
class EquipmentAnnotation {
  final String id;
  Offset position;
  String iconFile;
  String iconSvg;
  double width;
  double height;
  double rotation;
  EquipmentType type;

  EquipmentAnnotation({
    String? id,
    required this.position,
    required this.iconFile,
    required this.iconSvg,
    this.width = 80,
    this.height = 80,
    this.rotation = 0,
    this.type = EquipmentType.icon,
  }) : id = id ?? '${DateTime.now().microsecondsSinceEpoch}_${iconFile}';

  EquipmentAnnotation copyWith({
    Offset? position,
    String? iconFile,
    String? iconSvg,
    double? width,
    double? height,
    double? rotation,
    EquipmentType? type,
  }) {
    return EquipmentAnnotation(
      id: id, // Preserve the same ID
      position: position ?? this.position,
      iconFile: iconFile ?? this.iconFile,
      iconSvg: iconSvg ?? this.iconSvg,
      width: width ?? this.width,
      height: height ?? this.height,
      rotation: rotation ?? this.rotation,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'x': position.dx,
      'y': position.dy,
      'iconFile': iconFile,
      'iconSvg': iconSvg,
      'width': width,
      'height': height,
      'rotation': rotation,
      'type': type.name,
    };
  }

  factory EquipmentAnnotation.fromJson(Map<String, dynamic> json) {
    // Generate a unique ID for legacy data that doesn't have one
    final id = json['id'] as String? ??
               '${DateTime.now().microsecondsSinceEpoch}_${json['iconFile']}_${json['x']}_${json['y']}';

    return EquipmentAnnotation(
      id: id,
      position: Offset(
        (json['x'] as num).toDouble(),
        (json['y'] as num).toDouble(),
      ),
      iconFile: json['iconFile'] as String,
      iconSvg: json['iconSvg'] as String,
      width: (json['width'] as num?)?.toDouble() ?? 80,
      height: (json['height'] as num?)?.toDouble() ?? 80,
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0,
      type: EquipmentType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => EquipmentType.icon,
      ),
    );
  }
}

enum EquipmentType {
  icon,
  legacy,
}

/// Represents icon metadata for the icon library
class IconMetadata {
  final String file;
  final String name;
  final String? svgText;
  final String? assetPath;
  final IconCategory category;
  final List<String> keywords;
  final dynamic metadata; // For PostingMetadata or other custom data

  IconMetadata({
    required this.file,
    required this.name,
    this.svgText,
    this.assetPath,
    required this.category,
    required this.keywords,
    this.metadata,
  });
}

enum IconCategory {
  caution,
  danger,
  radiation,
  contamination,
  restricted,
  equipment,
  posting,
  other,
}

extension IconCategoryExtension on IconCategory {
  String get displayName {
    switch (this) {
      case IconCategory.caution:
        return 'Caution Signs';
      case IconCategory.danger:
        return 'Danger Signs';
      case IconCategory.radiation:
        return 'Radiation Areas';
      case IconCategory.contamination:
        return 'Contamination Areas';
      case IconCategory.restricted:
        return 'Restricted Areas';
      case IconCategory.equipment:
        return 'Equipment';
      case IconCategory.posting:
        return 'Postings';
      case IconCategory.other:
        return 'Other';
    }
  }

  Color get color {
    switch (this) {
      case IconCategory.caution:
        return Colors.orange;
      case IconCategory.danger:
        return Colors.red;
      case IconCategory.radiation:
        return Colors.purple;
      case IconCategory.contamination:
        return Colors.pink;
      case IconCategory.restricted:
        return Colors.brown;
      case IconCategory.equipment:
        return Colors.green;
      case IconCategory.posting:
        return Colors.yellow;
      case IconCategory.other:
        return Colors.blueGrey;
    }
  }
}

/// Represents a comment/note annotation
class CommentAnnotation {
  int id;
  Offset position;
  String text;

  CommentAnnotation({
    required this.id,
    required this.position,
    required this.text,
  });

  CommentAnnotation copyWith({int? id, Offset? position, String? text}) {
    return CommentAnnotation(
      id: id ?? this.id,
      position: position ?? this.position,
      text: text ?? this.text,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'x': position.dx,
      'y': position.dy,
      'text': text,
    };
  }

  factory CommentAnnotation.fromJson(Map<String, dynamic> json) {
    return CommentAnnotation(
      id: json['id'] as int,
      position: Offset(
        (json['x'] as num).toDouble(),
        (json['y'] as num).toDouble(),
      ),
      text: json['text'] as String,
    );
  }
}

/// Current tool state
enum ToolType {
  none,
  smearAdd,
  smearRemove,
  doseAdd,
  doseRemove,
  boundary,
  boundaryDelete,
  equipmentDelete,
  commentAdd,
  commentRemove,
}

/// Resize handle positions
enum ResizeHandle {
  nw,
  ne,
  sw,
  se,
}

/// Represents a title card with survey metadata
class TitleCard {
  Offset position;
  String surveyId;
  String surveyorName;
  DateTime date;
  String buildingNumber;
  String roomNumber;
  bool visible;
  double scale; // Scale factor for resizing the title card

  TitleCard({
    required this.position,
    this.surveyId = '',
    this.surveyorName = '',
    DateTime? date,
    this.buildingNumber = '',
    this.roomNumber = '',
    this.visible = true,
    this.scale = 1.0,
  }) : date = date ?? DateTime.now();

  TitleCard copyWith({
    Offset? position,
    String? surveyId,
    String? surveyorName,
    DateTime? date,
    String? buildingNumber,
    String? roomNumber,
    bool? visible,
    double? scale,
  }) {
    return TitleCard(
      position: position ?? this.position,
      surveyId: surveyId ?? this.surveyId,
      surveyorName: surveyorName ?? this.surveyorName,
      date: date ?? this.date,
      buildingNumber: buildingNumber ?? this.buildingNumber,
      roomNumber: roomNumber ?? this.roomNumber,
      visible: visible ?? this.visible,
      scale: scale ?? this.scale,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'x': position.dx,
      'y': position.dy,
      'surveyId': surveyId,
      'surveyorName': surveyorName,
      'date': date.toIso8601String(),
      'buildingNumber': buildingNumber,
      'roomNumber': roomNumber,
      'visible': visible,
      'scale': scale,
    };
  }

  factory TitleCard.fromJson(Map<String, dynamic> json) {
    return TitleCard(
      position: Offset(
        (json['x'] as num).toDouble(),
        (json['y'] as num).toDouble(),
      ),
      surveyId: json['surveyId'] as String? ?? '',
      surveyorName: json['surveyorName'] as String? ?? '',
      date: json['date'] != null
          ? DateTime.parse(json['date'] as String)
          : DateTime.now(),
      buildingNumber: json['buildingNumber'] as String? ?? '',
      roomNumber: json['roomNumber'] as String? ?? '',
      visible: json['visible'] as bool? ?? true,
      scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
    );
  }
}

/// Represents a statistics card showing smear count and highest dose rate
class StatsCard {
  Offset position;
  bool visible;
  double scale; // Scale factor for resizing the stats card

  StatsCard({
    required this.position,
    this.visible = true,
    this.scale = 1.0,
  });

  StatsCard copyWith({
    Offset? position,
    bool? visible,
    double? scale,
  }) {
    return StatsCard(
      position: position ?? this.position,
      visible: visible ?? this.visible,
      scale: scale ?? this.scale,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'x': position.dx,
      'y': position.dy,
      'visible': visible,
      'scale': scale,
    };
  }

  factory StatsCard.fromJson(Map<String, dynamic> json) {
    return StatsCard(
      position: Offset(
        (json['x'] as num).toDouble(),
        (json['y'] as num).toDouble(),
      ),
      visible: json['visible'] as bool? ?? true,
      scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
    );
  }
}
