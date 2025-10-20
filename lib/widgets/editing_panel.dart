import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/survey_map_model.dart';
import '../models/annotation_models.dart';
import 'icon_library.dart';

class EditingPanel extends StatefulWidget {
  const EditingPanel({super.key});

  @override
  State<EditingPanel> createState() => _EditingPanelState();
}

class _EditingPanelState extends State<EditingPanel> {
  final TextEditingController _surveyIdController = TextEditingController();
  final TextEditingController _surveyorController = TextEditingController();
  final TextEditingController _buildingController = TextEditingController();
  final TextEditingController _roomController = TextEditingController();
  final TextEditingController _doseValueController = TextEditingController();

  bool _iconsExpanded = false;
  final FocusNode _doseValueFocusNode = FocusNode();
  final GlobalKey _doseValueFieldKey = GlobalKey();
  bool _highlightDoseValue = false;
  OverlayEntry? _tooltipOverlay;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final model = context.read<SurveyMapModel>();
      model.setDoseRateValidationCallback(_onDoseRateValidationFailed);
    });
  }

  @override
  void dispose() {
    _surveyIdController.dispose();
    _surveyorController.dispose();
    _buildingController.dispose();
    _roomController.dispose();
    _doseValueController.dispose();
    _doseValueFocusNode.dispose();
    _removeTooltip();
    super.dispose();
  }

  void _onDoseRateValidationFailed() {
    setState(() {
      _highlightDoseValue = true;
    });
    _doseValueFocusNode.requestFocus();
    _showTooltip();

    // Remove highlight and tooltip after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _highlightDoseValue = false;
        });
        _removeTooltip();
      }
    });
  }

  void _showTooltip() {
    _removeTooltip(); // Remove any existing tooltip first

    final RenderBox? renderBox = _doseValueFieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    _tooltipOverlay = OverlayEntry(
      builder: (context) => Positioned(
        left: position.dx + size.width / 2 - 60,
        top: position.dy - 40,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.red.shade700,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.warning, color: Colors.white, size: 16),
                SizedBox(width: 6),
                Text(
                  'Enter value',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_tooltipOverlay!);
  }

  void _removeTooltip() {
    _tooltipOverlay?.remove();
    _tooltipOverlay = null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 350,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(-2, 0),
          ),
        ],
      ),
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
            child: const Row(
              children: [
                Icon(Icons.edit, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Editing Tools',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: Consumer<SurveyMapModel>(
              builder: (context, model, child) {
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildTitleCardSection(context, model),
                    const SizedBox(height: 16),
                    _buildSmearSection(context, model),
                    const SizedBox(height: 16),
                    _buildDoseRateSection(context, model),
                    const SizedBox(height: 16),
                    _buildBoundarySection(context, model),
                    const SizedBox(height: 16),
                    _buildCommentSection(context, model),
                    const SizedBox(height: 16),
                    _buildEquipmentSection(context, model),
                    const SizedBox(height: 16),
                    _buildPostingsSection(context, model),
                    const SizedBox(height: 16),
                    _buildClearAllSection(context, model),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildSmearSection(BuildContext context, SurveyMapModel model) {
    final isActive = model.currentTool == ToolType.smearAdd;

    return InkWell(
      onTap: () {
        // Toggle between smearAdd and none
        if (model.currentTool == ToolType.smearAdd) {
          model.setTool(ToolType.none);
        } else {
          model.setTool(ToolType.smearAdd);
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? Colors.blue.withValues(alpha: 0.1) : Colors.transparent,
          border: Border.all(
            color: isActive ? Colors.blue : Colors.grey.shade300,
            width: isActive ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.add_circle_outline,
              size: 20,
              color: isActive ? Colors.blue : Colors.grey.shade600,
            ),
            const SizedBox(width: 8),
            const Text(
              'Add Removable Smears',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isActive ? Colors.blue.withValues(alpha: 0.2) : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${model.smears.length}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isActive ? Colors.blue.shade700 : Colors.black54,
                ),
              ),
            ),
            const Spacer(),
            if (isActive)
              Icon(
                Icons.check_circle,
                color: Colors.blue,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoseRateSection(BuildContext context, SurveyMapModel model) {
    final isActive = model.currentTool == ToolType.doseAdd;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            // Toggle between doseAdd and none
            if (model.currentTool == ToolType.doseAdd) {
              model.setTool(ToolType.none);
            } else {
              model.setTool(ToolType.doseAdd);
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: isActive ? Colors.blue.withValues(alpha: 0.1) : Colors.transparent,
              border: Border.all(
                color: isActive ? Colors.blue : Colors.grey.shade300,
                width: isActive ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.add_circle_outline,
                  size: 20,
                  color: isActive ? Colors.blue : Colors.grey.shade600,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Add Dose Rates',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (isActive)
                  Icon(
                    Icons.check_circle,
                    color: Colors.blue,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
        if (model.currentTool == ToolType.doseAdd) ...[
              const SizedBox(height: 8),
              Focus(
                autofocus: false,
                onKeyEvent: (node, event) {
                  if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
                    // When user presses Escape while focused inside the dose panel (for example the
                    // value TextField), return to selection mode by clearing the tool.
                    model.setTool(ToolType.none);
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                },
                child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          key: _doseValueFieldKey,
                          controller: _doseValueController,
                          focusNode: _doseValueFocusNode,
                          decoration: InputDecoration(
                            labelText: 'Value',
                            hintText: 'Enter dose rate',
                            border: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: _highlightDoseValue ? Colors.red : Colors.grey,
                                width: _highlightDoseValue ? 2 : 1,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: _highlightDoseValue ? Colors.red : Colors.grey,
                                width: _highlightDoseValue ? 2 : 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: _highlightDoseValue ? Colors.red : Colors.blue,
                                width: 2,
                              ),
                            ),
                            filled: _highlightDoseValue,
                            fillColor: _highlightDoseValue ? Colors.red.withOpacity(0.1) : null,
                            isDense: true,
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            if (value.trim().isEmpty) {
                              // User cleared the field - reset the flag
                              model.clearDoseValue();
                              return;
                            }
                            final parsed = double.tryParse(value);
                            if (parsed != null && parsed > 0) {
                              model.setDoseValue(parsed);
                              // Remove highlight when user enters a value
                              if (_highlightDoseValue) {
                                setState(() {
                                  _highlightDoseValue = false;
                                });
                                _removeTooltip();
                              }
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: model.doseUnit,
                          decoration: const InputDecoration(
                            labelText: 'Unit',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: 'μR/hr', child: Text('μR/hr')),
                            DropdownMenuItem(
                                value: 'mR/hr', child: Text('mR/hr')),
                            DropdownMenuItem(value: 'R/hr', child: Text('R/hr')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              model.setDoseUnit(value);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Flexible(
                      child: InkWell(
                        onTap: () => model.setDoseType(DoseType.gamma),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Radio<DoseType>(
                              value: DoseType.gamma,
                              groupValue: model.doseType,
                              onChanged: (value) {
                                if (value != null) {
                                  model.setDoseType(value);
                                }
                              },
                              visualDensity: VisualDensity.compact,
                            ),
                            const Text('Gamma', style: TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: InkWell(
                        onTap: () => model.setDoseType(DoseType.neutron),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Radio<DoseType>(
                              value: DoseType.neutron,
                              groupValue: model.doseType,
                              onChanged: (value) {
                                if (value != null) {
                                  model.setDoseType(value);
                                }
                              },
                              visualDensity: VisualDensity.compact,
                            ),
                            const Text('Neutron', style: TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Font Size', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                        Text('${model.doseFontSize.round()}', style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                    Slider(
                      value: model.doseFontSize,
                      min: 8,
                      max: 24,
                      divisions: 16,
                      label: model.doseFontSize.round().toString(),
                      onChanged: (value) {
                        model.setDoseFontSize(value);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBoundarySection(BuildContext context, SurveyMapModel model) {
    final isActive = model.currentTool == ToolType.boundary;

    return InkWell(
      onTap: () {
        // Toggle between boundary and none
        if (model.currentTool == ToolType.boundary) {
          model.setTool(ToolType.none);
        } else {
          model.setTool(ToolType.boundary);
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? Colors.blue.withValues(alpha: 0.1) : Colors.transparent,
          border: Border.all(
            color: isActive ? Colors.blue : Colors.grey.shade300,
            width: isActive ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.add_circle_outline,
              size: 20,
              color: isActive ? Colors.blue : Colors.grey.shade600,
            ),
            const SizedBox(width: 8),
            const Text(
              'Add Boundaries',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            if (isActive)
              Icon(
                Icons.check_circle,
                color: Colors.blue,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentSection(BuildContext context, SurveyMapModel model) {
    final isActive = model.currentTool == ToolType.commentAdd;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            // Toggle between commentAdd and none
            if (model.currentTool == ToolType.commentAdd) {
              model.setTool(ToolType.none);
            } else {
              model.setTool(ToolType.commentAdd);
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: isActive ? Colors.blue.withValues(alpha: 0.1) : Colors.transparent,
              border: Border.all(
                color: isActive ? Colors.blue : Colors.grey.shade300,
                width: isActive ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.add_circle_outline,
                  size: 20,
                  color: isActive ? Colors.blue : Colors.grey.shade600,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Add Comments/Notes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.blue.withValues(alpha: 0.2) : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${model.comments.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isActive ? Colors.blue.shade700 : Colors.black54,
                    ),
                  ),
                ),
                const Spacer(),
                if (isActive)
                  Icon(
                    Icons.check_circle,
                    color: Colors.blue,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
        if (model.comments.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              children: model.comments.map((comment) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.blue.shade700, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            '${comment.id}',
                            style: TextStyle(
                              color: Colors.blue.shade900,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          comment.text,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEquipmentSection(BuildContext context, SurveyMapModel model) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _iconsExpanded = !_iconsExpanded;
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey.shade300,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.image, size: 20, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Icon Library',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Icon(
                  _iconsExpanded ? Icons.expand_less : Icons.expand_more,
                  size: 20,
                  color: Colors.grey.shade600,
                ),
              ],
            ),
          ),
        ),
        if (_iconsExpanded) ...[
          const SizedBox(height: 8),
          const IconLibrary(),
        ],
      ],
    );
  }

  Widget _buildPostingsSection(BuildContext context, SurveyMapModel model) {
    return InkWell(
      onTap: () => _showPostingsBrowserDialog(context),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.grey.shade300,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.open_in_browser, size: 20, color: Colors.blue),
            const SizedBox(width: 8),
            const Text(
              '☢️',
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 8),
            const Text(
              'Radiological Postings',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade600),
          ],
        ),
      ),
    );
  }

  void _showPostingsBrowserDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: SizedBox(
          width: 900,
          height: 700,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      '☢️ Radiological Postings',
                      style: TextStyle(
                        fontSize: 20,
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
                const SizedBox(height: 16),
                const Expanded(
                  child: IconLibrary(isExpanded: true, postingsOnly: true),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClearAllSection(BuildContext context, SurveyMapModel model) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Clear All Annotations'),
              content: const Text(
                  'Are you sure you want to clear all annotations? This cannot be undone.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    model.clearAllAnnotations();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Clear All'),
                ),
              ],
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
        child: const Text('Clear All Annotations'),
      ),
    );
  }

  Widget _buildTitleCardSection(BuildContext context, SurveyMapModel model) {
    if (model.titleCard == null) return const SizedBox.shrink();

    // Update controllers only if text differs (avoid cursor jump)
    if (_surveyIdController.text != model.titleCard!.surveyId) {
      _surveyIdController.text = model.titleCard!.surveyId;
    }
    if (_surveyorController.text != model.titleCard!.surveyorName) {
      _surveyorController.text = model.titleCard!.surveyorName;
    }
    if (_buildingController.text != model.titleCard!.buildingNumber) {
      _buildingController.text = model.titleCard!.buildingNumber;
    }
    if (_roomController.text != model.titleCard!.roomNumber) {
      _roomController.text = model.titleCard!.roomNumber;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Survey Information',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Survey ID',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                controller: _surveyIdController,
                textDirection: TextDirection.ltr,
                onChanged: (value) {
                  model.updateTitleCardField(surveyId: value);
                },
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Surveyor Name',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                controller: _surveyorController,
                textDirection: TextDirection.ltr,
                onChanged: (value) {
                  model.updateTitleCardField(surveyorName: value);
                },
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Building Number',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                controller: _buildingController,
                textDirection: TextDirection.ltr,
                onChanged: (value) {
                  model.updateTitleCardField(buildingNumber: value);
                },
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Room Number',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                controller: _roomController,
                textDirection: TextDirection.ltr,
                onChanged: (value) {
                  model.updateTitleCardField(roomNumber: value);
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Date: ${model.titleCard!.date.month}/${model.titleCard!.date.day}/${model.titleCard!.date.year}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: model.titleCard!.date,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (date != null) {
                        model.updateTitleCardField(date: date);
                      }
                    },
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: const Text('Change'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
