import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import '../models/building_map_model.dart';

class MapBrowserDialog extends StatefulWidget {
  const MapBrowserDialog({super.key});

  @override
  State<MapBrowserDialog> createState() => _MapBrowserDialogState();
}

class _MapBrowserDialogState extends State<MapBrowserDialog> {
  Map<String, List<BuildingMap>> _buildingMaps = {};
  String? _selectedBuilding;
  BuildingMap? _selectedMap;
  bool _isLoading = true;
  String _searchQuery = '';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMaps();
  }

  Future<void> _loadMaps() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load building maps from JSON asset
      final jsonString = await rootBundle.loadString('assets/building_maps.json');
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      final mapsList = jsonData['maps'] as List;

      final Map<String, List<BuildingMap>> maps = {};

      for (final mapData in mapsList) {
        final building = mapData['building'] as String;
        final room = mapData['room'] as String;
        // Store relative path - we'll resolve it when loading
        final filePath = mapData['path'] as String;

        if (!maps.containsKey(building)) {
          maps[building] = [];
        }

        maps[building]!.add(BuildingMap(
          building: building,
          room: room,
          filePath: filePath,
        ));
      }

      // Sort rooms alphabetically within each building
      for (final building in maps.keys) {
        maps[building]!.sort((a, b) => a.room.compareTo(b.room));
      }

      setState(() {
        _buildingMaps = Map.fromEntries(
          maps.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
        );
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading maps: $e');
      setState(() {
        _errorMessage = 'Error loading maps: $e';
        _isLoading = false;
      });
    }
  }

  String _extractRoomNumber(String filename) {
    // Try to extract room number from filename
    // This is a simple extraction - you can enhance it based on your naming convention
    return filename;
  }

  List<String> get _filteredBuildings {
    if (_searchQuery.isEmpty) {
      return _buildingMaps.keys.toList();
    }
    return _buildingMaps.keys
        .where((building) =>
            building.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  List<BuildingMap> get _filteredRooms {
    if (_selectedBuilding == null) return [];

    final rooms = _buildingMaps[_selectedBuilding] ?? [];

    if (_searchQuery.isEmpty) {
      return rooms;
    }

    return rooms
        .where((map) =>
            map.room.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 900,
        height: 600,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade700,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.folder_open, color: Colors.white),
                  const SizedBox(width: 8),
                  const Text(
                    'Browse Building Maps',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Search bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search buildings or rooms...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  isDense: true,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildingMaps.isEmpty
                      ? Center(
                          child: Text(
                            _errorMessage ?? 'No maps found in "Current Maps" folder',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        )
                      : Row(
                          children: [
                            // Buildings list
                            Expanded(
                              flex: 1,
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border(
                                    right: BorderSide(color: Colors.grey.shade300),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                      child: Text(
                                        'Buildings (${_filteredBuildings.length})',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: ListView.builder(
                                        itemCount: _filteredBuildings.length,
                                        itemBuilder: (context, index) {
                                          final building = _filteredBuildings[index];
                                          final isSelected = building == _selectedBuilding;
                                          return ListTile(
                                            title: Text(building),
                                            selected: isSelected,
                                            selectedTileColor: Colors.blue.shade50,
                                            onTap: () {
                                              setState(() {
                                                _selectedBuilding = building;
                                                _selectedMap = null;
                                              });
                                            },
                                            trailing: Text(
                                              '${_buildingMaps[building]?.length ?? 0} rooms',
                                              style: TextStyle(
                                                color: Colors.grey.shade600,
                                                fontSize: 12,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Rooms list
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    child: Text(
                                      _selectedBuilding == null
                                          ? 'Select a building'
                                          : 'Rooms (${_filteredRooms.length})',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: _selectedBuilding == null
                                        ? const Center(
                                            child: Text(
                                              'Select a building to view rooms',
                                              style: TextStyle(color: Colors.grey),
                                            ),
                                          )
                                        : ListView.builder(
                                            itemCount: _filteredRooms.length,
                                            itemBuilder: (context, index) {
                                              final map = _filteredRooms[index];
                                              final isSelected = map == _selectedMap;
                                              return ListTile(
                                                title: Text(map.room),
                                                selected: isSelected,
                                                selectedTileColor: Colors.blue.shade50,
                                                onTap: () {
                                                  setState(() {
                                                    _selectedMap = map;
                                                  });
                                                },
                                              );
                                            },
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
            ),
            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_selectedMap != null)
                    Expanded(
                      child: Text(
                        'Selected: ${_selectedMap!.building} - ${_selectedMap!.room}',
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    )
                  else
                    const Text(
                      'No map selected',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _selectedMap == null
                            ? null
                            : () => Navigator.pop(context, _selectedMap),
                        child: const Text('Load Map'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
