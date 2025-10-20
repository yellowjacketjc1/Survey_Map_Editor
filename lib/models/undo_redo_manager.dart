import 'package:flutter/foundation.dart';

/// Command pattern for undo/redo functionality
abstract class Command {
  void execute();
  void undo();
  String get description;
}

class UndoRedoManager extends ChangeNotifier {
  final List<Command> _undoStack = [];
  final List<Command> _redoStack = [];
  static const int _maxStackSize = 50;

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  String? get undoDescription => canUndo ? _undoStack.last.description : null;
  String? get redoDescription => canRedo ? _redoStack.last.description : null;

  void executeCommand(Command command) {
    command.execute();
    _undoStack.add(command);
    _redoStack.clear();

    // Limit stack size
    if (_undoStack.length > _maxStackSize) {
      _undoStack.removeAt(0);
    }

    notifyListeners();
  }

  /// Add a command to the undo stack without executing it
  /// Useful when the action has already been performed (e.g., during drag)
  void addCommandWithoutExecuting(Command command) {
    _undoStack.add(command);
    _redoStack.clear();

    // Limit stack size
    if (_undoStack.length > _maxStackSize) {
      _undoStack.removeAt(0);
    }

    notifyListeners();
  }

  void undo() {
    if (!canUndo) return;

    final command = _undoStack.removeLast();
    command.undo();
    _redoStack.add(command);

    notifyListeners();
  }

  void redo() {
    if (!canRedo) return;

    final command = _redoStack.removeLast();
    command.execute();
    _undoStack.add(command);

    notifyListeners();
  }

  void clear() {
    _undoStack.clear();
    _redoStack.clear();
    notifyListeners();
  }
}
