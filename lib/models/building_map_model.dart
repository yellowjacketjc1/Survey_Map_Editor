class BuildingMap {
  final String building;
  final String room;
  final String filePath;

  BuildingMap({
    required this.building,
    required this.room,
    required this.filePath,
  });

  @override
  String toString() => '$building - $room';
}
