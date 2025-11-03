import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/board_column.dart';
import 'ollie_ui/ollie_toast.dart';
import 'edit_column_dialog.dart';
import 'ollie_ui/theme_extensions.dart';

class ManageColumnsDialog extends ConsumerStatefulWidget {
  final List<BoardColumn> columns;
  final Future<void> Function(String columnId) onDeleteColumn;
  final Future<void> Function(BoardColumn column) onUpdateColumn;
  final Future<void> Function(List<String> columnIds) onReorderColumns;

  const ManageColumnsDialog({
    super.key,
    required this.columns,
    required this.onDeleteColumn,
    required this.onUpdateColumn,
    required this.onReorderColumns,
  });

  @override
  ConsumerState<ManageColumnsDialog> createState() =>
      _ManageColumnsDialogState();
}

class _ManageColumnsDialogState extends ConsumerState<ManageColumnsDialog> {
  late List<BoardColumn> _columns;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _columns = List.from(widget.columns);
  }

  void _reorderColumn(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final column = _columns.removeAt(oldIndex);
      _columns.insert(newIndex, column);
      _hasChanges = true;
    });
  }

  Future<void> _saveOrder() async {
    try {
      final columnIds = _columns.map((c) => c.id).toList();
      await widget.onReorderColumns(columnIds);
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        OllieToast.error(context, 'Failed to reorder columns: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 700,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.primaryColor.withOpacity(0.1),
                border: Border(bottom: BorderSide(color: context.borderColor)),
              ),
              child: Row(
                children: [
                  Icon(Icons.view_column, color: context.primaryColor),
                  const SizedBox(width: 12),
                  const Text(
                    'Manage Columns',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  if (_hasChanges)
                    TextButton.icon(
                      onPressed: _saveOrder,
                      icon: const Icon(Icons.save),
                      label: const Text('Save Order'),
                    ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),

            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              color: context.primaryColor.withOpacity(0.05),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: context.secondaryTextColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Drag columns to reorder them. Click edit to change name, color, or WIP limit.',
                      style: TextStyle(color: context.secondaryTextColor),
                    ),
                  ),
                ],
              ),
            ),

            // Column list
            Expanded(
              child: _columns.isEmpty
                  ? _buildEmptyState()
                  : ReorderableListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _columns.length,
                      onReorder: _reorderColumn,
                      itemBuilder: (context, index) {
                        final column = _columns[index];
                        return _ColumnTile(
                          key: ValueKey(column.id),
                          column: column,
                          onEdit: () => _editColumn(column),
                          onDelete: () => _confirmDeleteColumn(column),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.view_column_outlined,
            size: 64,
            color: context.secondaryTextColor,
          ),
          const SizedBox(height: 16),
          Text(
            'No columns yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: context.secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editColumn(BoardColumn column) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => EditColumnDialog(column: column),
    );

    if (result != null && mounted) {
      try {
        final updatedColumn = column.copyWith(
          name: result['name'] as String,
          color: result['color'] as int,
          wipLimit: result['wipLimit'] as int?,
        );
        await widget.onUpdateColumn(updatedColumn);
        setState(() {
          final index = _columns.indexWhere((c) => c.id == column.id);
          if (index != -1) {
            _columns[index] = updatedColumn;
          }
        });
      } catch (e) {
        if (mounted) {
          OllieToast.error(context, 'Failed to update column: ${e.toString()}');
        }
      }
    }
  }

  Future<void> _confirmDeleteColumn(BoardColumn column) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Column'),
        content: Text(
          'Are you sure you want to delete "${column.name}"?\n\n'
          'This will also delete all ${column.cardIds.length} card(s) in this column.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await widget.onDeleteColumn(column.id);
        setState(() {
          _columns.removeWhere((c) => c.id == column.id);
        });
        if (mounted) {
          OllieToast.success(context, 'Column deleted successfully');
        }
      } catch (e) {
        if (mounted) {
          OllieToast.error(context, 'Failed to delete column: ${e.toString()}');
        }
      }
    }
  }
}

class _ColumnTile extends StatelessWidget {
  final BoardColumn column;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ColumnTile({
    super.key,
    required this.column,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.drag_handle,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Color(column.color),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ],
        ),
        title: Text(
          column.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          column.wipLimit != null
              ? '${column.cardIds.length} cards • WIP Limit: ${column.wipLimit}'
              : '${column.cardIds.length} cards',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: onEdit,
              icon: Icon(
                Icons.edit,
                color: Theme.of(context).colorScheme.primary,
              ),
              tooltip: 'Edit column',
            ),
            IconButton(
              onPressed: onDelete,
              icon: Icon(
                Icons.delete,
                color: Theme.of(context).colorScheme.error,
              ),
              tooltip: 'Delete column',
            ),
          ],
        ),
      ),
    );
  }
}
