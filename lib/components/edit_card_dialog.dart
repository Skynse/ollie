import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ollie/components/ollie_ui/ollie_button.dart';
import 'package:ollie/components/ollie_ui/ollie_dialog.dart';
import 'package:ollie/components/ollie_ui/ollie_textfield.dart';
import 'package:ollie/components/ollie_ui/ollie_toast.dart';
import '../models/card.dart' as model;
import '../models/checklist.dart';
import '../models/checklist_item.dart';
import '../models/priority.dart';
import '../models/sprint.dart';
import '../providers/board_provider.dart';
import '../providers/boards_provider.dart';
import '../providers/sprint_provider.dart';
import 'ollie_ui/theme_extensions.dart';
import 'card_timer_widget.dart';

/// Comprehensive dialog for editing all card properties
class EditCardDialog extends ConsumerStatefulWidget {
  final model.Card card;
  final String boardId;

  const EditCardDialog({super.key, required this.card, required this.boardId});

  @override
  ConsumerState<EditCardDialog> createState() => _EditCardDialogState();
}

class _EditCardDialogState extends ConsumerState<EditCardDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _estimatedHoursController;

  late Priority _selectedPriority;
  DateTime? _selectedDueDate;
  String? _selectedSprintId;
  bool _isLoading = false;

  // Subtasks
  List<ChecklistItem> _subtasks = [];
  String? _checklistId;
  final _newSubtaskController = TextEditingController();
  bool _subtasksLoading = true;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.card.title);
    _descriptionController = TextEditingController(
      text: widget.card.description ?? '',
    );
    _estimatedHoursController = TextEditingController(
      text: widget.card.estimatedHours?.toString() ?? '',
    );
    _selectedPriority = widget.card.priority;
    _selectedDueDate = widget.card.dueDate;
    _selectedSprintId = widget.card.sprintId;
    _loadSubtasks();
  }

  Future<void> _loadSubtasks() async {
    try {
      final repo = ref.read(boardRepositoryProvider);
      final checklists = await repo.getChecklistsByCard(widget.card.id);
      if (mounted && checklists.isNotEmpty) {
        _checklistId = checklists.first.id;
        _subtasks = List.from(checklists.first.items);
      }
    } catch (_) {
      // Non-fatal: subtasks just won't pre-populate
    } finally {
      if (mounted) setState(() => _subtasksLoading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _estimatedHoursController.dispose();
    _newSubtaskController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );

    if (picked != null) {
      setState(() {
        _selectedDueDate = picked;
      });
    }
  }

  Future<void> _saveCard() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final estimatedHours = _estimatedHoursController.text.trim().isEmpty
          ? null
          : double.tryParse(_estimatedHoursController.text.trim());

      await _saveSubtasks();

      final completedCount = _subtasks.where((s) => s.isCompleted).length;

      // Update card via repository
      final updatedCard = widget.card.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        priority: _selectedPriority,
        dueDate: _selectedDueDate,
        estimatedHours: estimatedHours,
        sprintId: _selectedSprintId,
        subtaskCount: _subtasks.length,
        completedSubtaskCount: completedCount,
        updatedAt: DateTime.now(),
      );

      await ref
          .read(boardNotifierProvider(widget.boardId).notifier)
          .updateCard(updatedCard: updatedCard);

      // Membership lives in cards.sprint_id. Time logs deliberately stay
      // attached to the sprint they were logged in; never delete history when
      // a card moves between sprints.
      if (_selectedSprintId != widget.card.sprintId) {
        final sprintNotifier = ref.read(
          sprintNotifierProvider(widget.boardId).notifier,
        );
        if (widget.card.sprintId != null) {
          await sprintNotifier.removeCardFromSprint(
            widget.card.sprintId!,
            widget.card.id,
          );
        }
        if (_selectedSprintId != null) {
          await sprintNotifier.addCardToSprint(
            _selectedSprintId!,
            widget.card.id,
          );
        }
      }

      if (mounted) {
        Navigator.of(context).pop();
        OllieToast.success(context, 'Card updated successfully');
      }
    } catch (e) {
      if (mounted) {
        OllieToast.error(context, 'Failed to update card: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveSubtasks() async {
    final repo = ref.read(boardRepositoryProvider);
    if (_checklistId == null && _subtasks.isEmpty) return;

    if (_checklistId == null && _subtasks.isNotEmpty) {
      final created = await repo.createChecklist(
        Checklist(
          id: '',
          cardId: widget.card.id,
          title: 'Subtasks',
          items: _subtasks,
        ),
      );
      _checklistId = created.id;
    } else if (_checklistId != null && _subtasks.isNotEmpty) {
      await repo.updateChecklist(
        Checklist(
          id: _checklistId!,
          cardId: widget.card.id,
          title: 'Subtasks',
          items: _subtasks,
        ),
      );
    } else if (_checklistId != null && _subtasks.isEmpty) {
      await repo.deleteChecklist(_checklistId!);
      _checklistId = null;
    }
  }

  void _addSubtask() {
    final text = _newSubtaskController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _subtasks.add(
        ChecklistItem(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          text: text,
        ),
      );
      _newSubtaskController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return OllieDialog(
      title: 'Edit Card',
      width: 800,
      actions: [
        OllieButton.text(
          text: 'Cancel',
          onPressed: () => Navigator.of(context).pop(),
          disabled: _isLoading,
        ),
        OllieButton(
          text: 'Save Changes',
          onPressed: _saveCard,
          loading: _isLoading,
        ),
      ],
      content: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            OllieTextfield.simple(
              label: 'Title',
              controller: _titleController,
              hint: 'Enter card title',
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Title is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Description
            OllieTextfield.multiline(
              label: 'Description',
              controller: _descriptionController,
              hint: 'Add a description...',
              maxLines: 4,
            ),
            const SizedBox(height: 20),

            // Row: Priority and Due Date
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Priority'),
                      const SizedBox(height: 8),
                      _buildPrioritySelector(),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Due Date'),
                      const SizedBox(height: 8),
                      _buildDueDateSelector(),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Row: Sprint and Estimated Hours
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Sprint'),
                      const SizedBox(height: 8),
                      _buildSprintSelector(),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OllieTextfield.simple(
                    label: 'Estimated Hours',
                    controller: _estimatedHoursController,
                    hint: 'e.g., 5.5',
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Subtasks
            _buildSubtasksSection(),
            const SizedBox(height: 20),

            // Time Tracking
            _buildSectionTitle('Time Tracking'),
            const SizedBox(height: 8),
            CardTimerWidget(card: widget.card, boardId: widget.boardId),
          ],
        ),
      ),
    );
  }

  Widget _buildSubtasksSection() {
    final done = _subtasks.where((s) => s.isCompleted).length;
    final total = _subtasks.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildSectionTitle('Subtasks'),
            if (total > 0) ...[
              const SizedBox(width: 8),
              Text(
                '($done/$total)',
                style: TextStyle(
                  fontSize: 12,
                  color: done == total
                      ? context.successColor
                      : context.secondaryTextColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        if (_subtasksLoading)
          const Center(child: CircularProgressIndicator())
        else ...[
          ...List.generate(_subtasks.length, (i) {
            final item = _subtasks[i];
            return Row(
              children: [
                Checkbox(
                  value: item.isCompleted,
                  onChanged: (checked) {
                    setState(() {
                      _subtasks[i] = item.copyWith(
                        isCompleted: checked ?? false,
                      );
                    });
                  },
                ),
                Expanded(
                  child: Text(
                    item.text,
                    style: TextStyle(
                      fontSize: 14,
                      color: item.isCompleted
                          ? context.secondaryTextColor
                          : context.textColor,
                      decoration: item.isCompleted
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    size: 16,
                    color: context.secondaryTextColor,
                  ),
                  onPressed: () {
                    setState(() => _subtasks.removeAt(i));
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            );
          }),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: OllieTextfield.simple(
                  controller: _newSubtaskController,
                  hint: 'Add a subtask...',
                  onSubmitted: (_) => _addSubtask(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.add, color: context.primaryColor),
                onPressed: _addSubtask,
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: context.secondaryTextColor,
      ),
    );
  }

  Widget _buildPrioritySelector() {
    return Row(
      children: Priority.values.map((priority) {
        final isSelected = _selectedPriority == priority;
        return Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: ChoiceChip(
            label: Text(priority.name.toUpperCase()),
            selected: isSelected,
            onSelected: (selected) {
              if (selected) {
                setState(() => _selectedPriority = priority);
              }
            },
            selectedColor: _getPriorityColor(priority),
            labelStyle: TextStyle(
              color: isSelected ? context.surfaceColor : context.textColor,
              fontWeight: FontWeight.bold,
            ),
            side: BorderSide(
              color: isSelected
                  ? _getPriorityColor(priority)
                  : context.borderColor,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDueDateSelector() {
    return InkWell(
      onTap: () => _selectDate(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: context.borderColor, width: 1.5),
          borderRadius: BorderRadius.circular(12),
          color: context.surfaceVariantColor,
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: 16,
              color: context.secondaryTextColor,
            ),
            const SizedBox(width: 8),
            Text(
              _selectedDueDate != null
                  ? '${_selectedDueDate!.month}/${_selectedDueDate!.day}/${_selectedDueDate!.year}'
                  : 'No due date',
              style: TextStyle(
                fontSize: 16,
                color: _selectedDueDate != null
                    ? context.textColor
                    : context.secondaryTextColor,
              ),
            ),
            const Spacer(),
            if (_selectedDueDate != null)
              InkWell(
                onTap: () => setState(() => _selectedDueDate = null),
                child: Icon(
                  Icons.clear,
                  size: 18,
                  color: context.secondaryTextColor,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSprintSelector() {
    final sprintsAsync = ref.watch(boardSprintsProvider(widget.boardId));

    return sprintsAsync.when(
      data: (sprints) {
        // Deduplicate sprints by ID to avoid duplicate dropdown values
        final seenIds = <String>{};
        final availableSprints = sprints
            .where((s) => s.status != SprintStatus.completed)
            .where((s) {
              if (seenIds.contains(s.id)) return false;
              seenIds.add(s.id);
              return true;
            })
            .toList();

        // Validate selected sprint ID exists in available sprints
        final sprintIds = availableSprints.map((s) => s.id).toSet();
        if (_selectedSprintId != null &&
            !sprintIds.contains(_selectedSprintId)) {
          // Sprint no longer exists or is completed, clear selection
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _selectedSprintId = null;
              });
            }
          });
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: context.borderColor, width: 1.5),
            borderRadius: BorderRadius.circular(12),
            color: context.surfaceVariantColor,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: _selectedSprintId,
              isExpanded: true,
              hint: const Text('No sprint'),
              items: [
                const DropdownMenuItem(value: null, child: Text('No sprint')),
                ...availableSprints.map((sprint) {
                  return DropdownMenuItem(
                    value: sprint.id,
                    child: Row(
                      children: [
                        Icon(
                          sprint.status == SprintStatus.active
                              ? Icons.play_circle
                              : Icons.schedule,
                          size: 16,
                          color: sprint.status == SprintStatus.active
                              ? context.successColor
                              : context.secondaryTextColor,
                        ),
                        const SizedBox(width: 8),
                        Text(sprint.name),
                      ],
                    ),
                  );
                }),
              ],
              onChanged: (sprintId) {
                setState(() => _selectedSprintId = sprintId);
              },
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Text(
        'Failed to load sprints',
        style: TextStyle(color: context.dangerColor),
      ),
    );
  }

  Color _getPriorityColor(Priority priority) {
    switch (priority) {
      case Priority.high:
        return Colors.red;
      case Priority.medium:
        return Colors.orange;
      case Priority.low:
        return Colors.grey;
    }
  }
}
