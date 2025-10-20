import 'package:flutter/material.dart';
import 'undo_redo_manager.dart';
import 'annotation_models.dart';
import 'survey_map_model.dart';

// Smear Commands
class AddSmearCommand extends Command {
  final SurveyMapModel model;
  final SmearAnnotation smear;

  AddSmearCommand(this.model, this.smear);

  @override
  void execute() {
    model.addSmearDirect(smear);
  }

  @override
  void undo() {
    model.removeSmearDirect(smear);
  }

  @override
  String get description => 'Add Smear ${smear.id}';
}

class RemoveSmearCommand extends Command {
  final SurveyMapModel model;
  final SmearAnnotation smear;
  final int originalIndex;

  RemoveSmearCommand(this.model, this.smear, this.originalIndex);

  @override
  void execute() {
    model.removeSmearDirect(smear);
  }

  @override
  void undo() {
    model.addSmearDirectAt(smear, originalIndex);
  }

  @override
  String get description => 'Remove Smear ${smear.id}';
}

class MoveSmearCommand extends Command {
  final SurveyMapModel model;
  final SmearAnnotation smear;
  final Offset oldPosition;
  final Offset newPosition;

  MoveSmearCommand(this.model, this.smear, this.oldPosition, this.newPosition);

  @override
  void execute() {
    model.updateSmearPositionDirect(smear, newPosition);
  }

  @override
  void undo() {
    model.updateSmearPositionDirect(smear, oldPosition);
  }

  @override
  String get description => 'Move Smear ${smear.id}';
}

// Dose Rate Commands
class AddDoseRateCommand extends Command {
  final SurveyMapModel model;
  final DoseRateAnnotation doseRate;

  AddDoseRateCommand(this.model, this.doseRate);

  @override
  void execute() {
    model.addDoseRateDirect(doseRate);
  }

  @override
  void undo() {
    model.removeDoseRateDirect(doseRate);
  }

  @override
  String get description => 'Add Dose Rate';
}

class RemoveDoseRateCommand extends Command {
  final SurveyMapModel model;
  final DoseRateAnnotation doseRate;
  final int originalIndex;

  RemoveDoseRateCommand(this.model, this.doseRate, this.originalIndex);

  @override
  void execute() {
    model.removeDoseRateDirect(doseRate);
  }

  @override
  void undo() {
    model.addDoseRateDirectAt(doseRate, originalIndex);
  }

  @override
  String get description => 'Remove Dose Rate';
}

class MoveDoseRateCommand extends Command {
  final SurveyMapModel model;
  final DoseRateAnnotation doseRate;
  final Offset oldPosition;
  final Offset newPosition;

  MoveDoseRateCommand(this.model, this.doseRate, this.oldPosition, this.newPosition);

  @override
  void execute() {
    model.updateDoseRatePositionDirect(doseRate, newPosition);
  }

  @override
  void undo() {
    model.updateDoseRatePositionDirect(doseRate, oldPosition);
  }

  @override
  String get description => 'Move Dose Rate';
}

class EditDoseRateCommand extends Command {
  final SurveyMapModel model;
  final DoseRateAnnotation oldDoseRate;
  final DoseRateAnnotation newDoseRate;
  final int index;

  EditDoseRateCommand(this.model, this.oldDoseRate, this.newDoseRate, this.index);

  @override
  void execute() {
    model.updateDoseRateAt(index, newDoseRate);
  }

  @override
  void undo() {
    model.updateDoseRateAt(index, oldDoseRate);
  }

  @override
  String get description => 'Edit Dose Rate';
}

// Boundary Commands
class AddBoundaryCommand extends Command {
  final SurveyMapModel model;
  final BoundaryAnnotation boundary;

  AddBoundaryCommand(this.model, this.boundary);

  @override
  void execute() {
    model.addBoundaryDirect(boundary);
  }

  @override
  void undo() {
    model.deleteBoundaryDirect(boundary);
  }

  @override
  String get description => 'Add Boundary';
}

class DeleteBoundaryCommand extends Command {
  final SurveyMapModel model;
  final BoundaryAnnotation boundary;
  final int originalIndex;

  DeleteBoundaryCommand(this.model, this.boundary, this.originalIndex);

  @override
  void execute() {
    model.deleteBoundaryDirect(boundary);
  }

  @override
  void undo() {
    model.addBoundaryDirectAt(boundary, originalIndex);
  }

  @override
  String get description => 'Delete Boundary';
}

// Equipment Commands
class AddEquipmentCommand extends Command {
  final SurveyMapModel model;
  final EquipmentAnnotation equipment;

  AddEquipmentCommand(this.model, this.equipment);

  @override
  void execute() {
    model.addEquipmentDirect(equipment);
  }

  @override
  void undo() {
    model.removeEquipmentDirect(equipment);
  }

  @override
  String get description => 'Add Equipment';
}

class RemoveEquipmentCommand extends Command {
  final SurveyMapModel model;
  final EquipmentAnnotation equipment;
  final int originalIndex;

  RemoveEquipmentCommand(this.model, this.equipment, this.originalIndex);

  @override
  void execute() {
    model.removeEquipmentDirect(equipment);
  }

  @override
  void undo() {
    model.addEquipmentDirectAt(equipment, originalIndex);
  }

  @override
  String get description => 'Remove Equipment';
}

class MoveEquipmentCommand extends Command {
  final SurveyMapModel model;
  final EquipmentAnnotation equipment;
  final Offset oldPosition;
  final Offset newPosition;

  MoveEquipmentCommand(this.model, this.equipment, this.oldPosition, this.newPosition);

  @override
  void execute() {
    model.updateEquipmentPositionDirect(equipment, newPosition);
  }

  @override
  void undo() {
    model.updateEquipmentPositionDirect(equipment, oldPosition);
  }

  @override
  String get description => 'Move Equipment';
}

class ResizeEquipmentCommand extends Command {
  final SurveyMapModel model;
  final EquipmentAnnotation equipment;
  final double oldWidth;
  final double oldHeight;
  final double newWidth;
  final double newHeight;

  ResizeEquipmentCommand(
    this.model,
    this.equipment,
    this.oldWidth,
    this.oldHeight,
    this.newWidth,
    this.newHeight,
  );

  @override
  void execute() {
    model.updateEquipmentSizeDirect(equipment, newWidth, newHeight);
  }

  @override
  void undo() {
    model.updateEquipmentSizeDirect(equipment, oldWidth, oldHeight);
  }

  @override
  String get description => 'Resize Equipment';
}

class RotateEquipmentCommand extends Command {
  final SurveyMapModel model;
  final EquipmentAnnotation equipment;
  final double oldRotation;
  final double newRotation;

  RotateEquipmentCommand(
    this.model,
    this.equipment,
    this.oldRotation,
    this.newRotation,
  );

  @override
  void execute() {
    model.updateEquipmentRotationDirect(equipment, newRotation);
  }

  @override
  void undo() {
    model.updateEquipmentRotationDirect(equipment, oldRotation);
  }

  @override
  String get description => 'Rotate Equipment';
}

// Comment Commands
class AddCommentCommand extends Command {
  final SurveyMapModel model;
  final CommentAnnotation comment;

  AddCommentCommand(this.model, this.comment);

  @override
  void execute() {
    model.addCommentDirect(comment);
  }

  @override
  void undo() {
    model.removeCommentDirect(comment);
  }

  @override
  String get description => 'Add Comment ${comment.id}';
}

class RemoveCommentCommand extends Command {
  final SurveyMapModel model;
  final CommentAnnotation comment;
  final int originalIndex;

  RemoveCommentCommand(this.model, this.comment, this.originalIndex);

  @override
  void execute() {
    model.removeCommentDirect(comment);
  }

  @override
  void undo() {
    model.addCommentDirectAt(comment, originalIndex);
  }

  @override
  String get description => 'Remove Comment ${comment.id}';
}

class MoveCommentCommand extends Command {
  final SurveyMapModel model;
  final CommentAnnotation comment;
  final Offset oldPosition;
  final Offset newPosition;

  MoveCommentCommand(this.model, this.comment, this.oldPosition, this.newPosition);

  @override
  void execute() {
    model.updateCommentPositionDirect(comment, newPosition);
  }

  @override
  void undo() {
    model.updateCommentPositionDirect(comment, oldPosition);
  }

  @override
  String get description => 'Move Comment ${comment.id}';
}

class EditCommentCommand extends Command {
  final SurveyMapModel model;
  final CommentAnnotation oldComment;
  final CommentAnnotation newComment;
  final int index;

  EditCommentCommand(this.model, this.oldComment, this.newComment, this.index);

  @override
  void execute() {
    model.updateCommentAt(index, newComment);
  }

  @override
  void undo() {
    model.updateCommentAt(index, oldComment);
  }

  @override
  String get description => 'Edit Comment ${newComment.id}';
}
