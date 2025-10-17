import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ollie/providers/boards_provider.dart';
import '../models/card.dart' as model;
import '../models/priority.dart';
import '../models/sprint.dart';
import '../providers/board_provider.dart';
import '../providers/sprint_provider.dart';
import '../providers/user_provider.dart';

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

      await ref.read(boardRepositoryProvider).updateCard(updatedCard);

      // Update sprint cardIds if sprint changed
      if (_selectedSprintId != null &&
          _selectedSprintId != widget.card.sprintId) {
        // Remove from old sprint if exists
        if (widget.card.sprintId != null) {
          await ref
              .read(sprintNotifierProvider(widget.boardId).notifier)
              .removeCardFromSprint(widget.card.sprintId!, widget.card.id);
        }
        // Add to new sprint
        await ref
            .read(sprintNotifierProvider(widget.boardId).notifier)
            .addCardToSprint(_selectedSprintId!, widget.card.id);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Card updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update card: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 800,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Icon(Icons.edit_note, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  const Text(
                    'Edit Card',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    style: IconButton.styleFrom(backgroundColor: Colors.white),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      _buildSectionTitle('Title'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          hintText: 'Enter card title',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Title is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Description
                      _buildSectionTitle('Description'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          hintText: 'Add a description...',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        maxLines: 4,
                      ),
                      const SizedBox(height: 20),

                      // Row: Priority and Due Date
                      Row(
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionTitle('Estimated Hours'),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _estimatedHoursController,
                                  decoration: const InputDecoration(
                                    hintText: 'e.g., 5.5',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                    suffixText: 'hours',
                                  ),
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'^\d+\.?\d{0,2}'),
                                    ),
                                  ],
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
                    ],
                  ),
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: _isLoading ? null : _saveCard,
                    child: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save Changes'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade700,
      ),
    );
  }

  Widget _buildPrioritySelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Priority>(
          value: _selectedPriority,
          isExpanded: true,
          isDense: true,
          items: Priority.values.map((priority) {
            final color = _getPriorityColor(priority);
            return DropdownMenuItem(
              value: priority,
              child: Row(
                children: [
                  Icon(Icons.flag, size: 16, color: color),
                  const SizedBox(width: 8),
                  Text(
                    priority.toString().split('.').last.toUpperCase(),
                    style: TextStyle(color: color, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (priority) {
            if (priority != null) {
              setState(() => _selectedPriority = priority);
            }
          },
        ),
      ),
    );
  }

  Widget _buildDueDateSelector() {
    return InkWell(
      onTap: () => _selectDate(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade700),
            const SizedBox(width: 8),
            Text(
              _selectedDueDate != null
                  ? '${_selectedDueDate!.month}/${_selectedDueDate!.day}/${_selectedDueDate!.year}'
                  : 'No due date',
              style: TextStyle(
                fontSize: 14,
                color: _selectedDueDate != null
                    ? Colors.black87
                    : Colors.grey.shade500,
              ),
            ),
            const Spacer(),
            if (_selectedDueDate != null)
              InkWell(
                onTap: () => setState(() => _selectedDueDate = null),
                child: Icon(Icons.clear, size: 16, color: Colors.grey.shade600),
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
        final availableSprints = sprints
            .where((s) => s.status != SprintStatus.completed)
            .toList();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(4),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: _selectedSprintId,
              isExpanded: true,
              isDense: true,
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
                              ? Colors.green.shade700
                              : Colors.grey.shade600,
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
        style: TextStyle(color: Colors.red.shade600),
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
                      ? Colors.blue.shade700
                      : Colors.grey.shade300,
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? Colors.white : Colors.grey.shade700,
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
        style: TextStyle(color: Colors.red.shade600),
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
