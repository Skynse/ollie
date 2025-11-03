import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ollie/components/ollie_ui/ollie_button.dart';
import 'package:ollie/components/ollie_ui/ollie_dialog.dart';
import 'package:ollie/components/ollie_ui/ollie_textfield.dart';
import 'package:ollie/components/ollie_ui/ollie_toast.dart';
import '../models/card.dart' as model;
import '../models/priority.dart';
import '../models/sprint.dart';
import '../providers/board_provider.dart';
import '../providers/sprint_provider.dart';
import '../providers/user_provider.dart';
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
  List<String> _selectedAssigneeIds = [];
  bool _isLoading = false;

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
    _selectedAssigneeIds = List.from(widget.card.assigneeIds);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _estimatedHoursController.dispose();
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
        assigneeIds: _selectedAssigneeIds,
        updatedAt: DateTime.now(),
      );

      await ref
          .read(boardNotifierProvider(widget.boardId).notifier)
          .updateCard(updatedCard: updatedCard);

      // Update sprint cardIds if sprint changed
      if (_selectedSprintId != widget.card.sprintId) {
        // Remove from old sprint if exists
        if (widget.card.sprintId != null) {
          await ref
              .read(sprintNotifierProvider(widget.boardId).notifier)
              .removeCardFromSprint(widget.card.sprintId!, widget.card.id);

          final timeLogs = await ref
              .read(sprintRepositoryProvider)
              .getTimeLogsByCard(widget.card.id);

          // 2. Filter for logs from the old sprint and delete them.
          for (final log in timeLogs) {
            if (log.sprintId == widget.card.sprintId) {
              await ref.read(sprintRepositoryProvider).deleteTimeLog(log.id);
            }
          }
        }

        ref.invalidate(sprintNotifierProvider(widget.boardId));
        // Add to new sprint
        if (_selectedSprintId != null) {
          await ref
              .read(sprintNotifierProvider(widget.boardId).notifier)
              .addCardToSprint(_selectedSprintId!, widget.card.id);
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

            // Assignees
            _buildSectionTitle('Assignees'),
            const SizedBox(height: 8),
            _buildAssigneeSelector(),
            const SizedBox(height: 20),

            // Time Tracking
            _buildSectionTitle('Time Tracking'),
            const SizedBox(height: 8),
            CardTimerWidget(card: widget.card),
          ],
        ),
      ),
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
        final sprintIds = sprints.map((s) => s.id).toSet();
        if (_selectedSprintId != null &&
            !sprintIds.contains(_selectedSprintId)) {
          _selectedSprintId = null;
        }
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
      error: (_, __) => Text(
        'Failed to load sprints',
        style: TextStyle(color: context.dangerColor),
      ),
    );
  }

  Widget _buildAssigneeSelector() {
    final boardState = ref.watch(boardNotifierProvider(widget.boardId));

    return boardState.when(
      data: (state) {
        final members = state.board.memberIds;

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: members.map((memberId) {
            final isSelected = _selectedAssigneeIds.contains(memberId);
            final userAsync = ref.watch(userProvider(memberId));

            return userAsync.when(
              data: (user) => FilterChip(
                label: Text(user.name),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedAssigneeIds.add(memberId);
                    } else {
                      _selectedAssigneeIds.remove(memberId);
                    }
                  });
                },
                avatar: CircleAvatar(
                  backgroundColor: isSelected
                      ? context.primaryColor
                      : context.borderColor,
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected
                          ? context.surfaceColor
                          : context.secondaryTextColor,
                    ),
                  ),
                ),
              ),
              loading: () => const Chip(label: Text('Loading...')),
              error: (_, __) => const Chip(label: Text('Error')),
            );
          }).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Text(
        'Failed to load members',
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
