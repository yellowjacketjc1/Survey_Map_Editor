import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';

/// Service for saving and loading survey map data using browser's localStorage
class StorageService {
  static const String _projectsKey = 'survey_map_projects';
  static const String _lastOpenedKey = 'survey_map_last_opened';

  /// Get list of all saved projects
  static List<SavedProject> getSavedProjects() {
    try {
      final projectsJson = html.window.localStorage[_projectsKey];
      if (projectsJson == null) return [];

      final projectsList = json.decode(projectsJson) as List;
      return projectsList
          .map((p) => SavedProject.fromJson(p as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error loading projects list: $e');
      return [];
    }
  }

  /// Save a project
  static Future<bool> saveProject(SavedProject project) async {
    try {
      final projects = getSavedProjects();

      // Check if project with this ID already exists
      final existingIndex = projects.indexWhere((p) => p.id == project.id);

      if (existingIndex >= 0) {
        // Update existing project
        projects[existingIndex] = project;
      } else {
        // Add new project
        projects.add(project);
      }

      // Save to localStorage
      final projectsJson = json.encode(projects.map((p) => p.toJson()).toList());
      html.window.localStorage[_projectsKey] = projectsJson;

      // Update last opened
      html.window.localStorage[_lastOpenedKey] = project.id;

      debugPrint('✓ Project saved: ${project.name} (${project.id})');
      return true;
    } catch (e) {
      debugPrint('Error saving project: $e');
      return false;
    }
  }

  /// Load a project by ID
  static SavedProject? loadProject(String projectId) {
    try {
      final projects = getSavedProjects();
      final project = projects.firstWhere(
        (p) => p.id == projectId,
        orElse: () => throw Exception('Project not found'),
      );

      // Update last opened
      html.window.localStorage[_lastOpenedKey] = projectId;

      debugPrint('✓ Project loaded: ${project.name}');
      return project;
    } catch (e) {
      debugPrint('Error loading project: $e');
      return null;
    }
  }

  /// Delete a project by ID
  static bool deleteProject(String projectId) {
    try {
      final projects = getSavedProjects();
      projects.removeWhere((p) => p.id == projectId);

      final projectsJson = json.encode(projects.map((p) => p.toJson()).toList());
      html.window.localStorage[_projectsKey] = projectsJson;

      // Clear last opened if it was this project
      if (html.window.localStorage[_lastOpenedKey] == projectId) {
        html.window.localStorage.remove(_lastOpenedKey);
      }

      debugPrint('✓ Project deleted: $projectId');
      return true;
    } catch (e) {
      debugPrint('Error deleting project: $e');
      return false;
    }
  }

  /// Get the ID of the last opened project
  static String? getLastOpenedProjectId() {
    return html.window.localStorage[_lastOpenedKey];
  }

  /// Get storage usage information
  static String getStorageInfo() {
    try {
      final projects = getSavedProjects();
      final projectsJson = html.window.localStorage[_projectsKey] ?? '';
      final sizeKB = (projectsJson.length / 1024).toStringAsFixed(2);
      return '${projects.length} projects, ~$sizeKB KB used';
    } catch (e) {
      return 'Unable to calculate storage';
    }
  }
}

/// Represents a saved project
class SavedProject {
  final String id;
  final String name;
  final String? mapName;
  final DateTime lastModified;
  final Map<String, dynamic> mapData;

  SavedProject({
    String? id,
    required this.name,
    this.mapName,
    DateTime? lastModified,
    required this.mapData,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        lastModified = lastModified ?? DateTime.now();

  SavedProject copyWith({
    String? name,
    String? mapName,
    DateTime? lastModified,
    Map<String, dynamic>? mapData,
  }) {
    return SavedProject(
      id: id,
      name: name ?? this.name,
      mapName: mapName ?? this.mapName,
      lastModified: lastModified ?? this.lastModified,
      mapData: mapData ?? this.mapData,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'mapName': mapName,
      'lastModified': lastModified.toIso8601String(),
      'mapData': mapData,
    };
  }

  factory SavedProject.fromJson(Map<String, dynamic> json) {
    return SavedProject(
      id: json['id'] as String,
      name: json['name'] as String,
      mapName: json['mapName'] as String?,
      lastModified: json['lastModified'] != null
          ? DateTime.parse(json['lastModified'] as String)
          : DateTime.now(),
      mapData: json['mapData'] as Map<String, dynamic>,
    );
  }
}
