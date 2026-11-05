import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/board.dart';
import '../models/board_column.dart';
import '../models/card.dart' as model;
import '../providers/boards_provider.dart';
import 'ollie_ui/ollie_toast.dart';

enum ExportFormat { json, csv }

class ExportBoardDialog extends ConsumerStatefulWidget {
  final Board board;
  final List<BoardColumn> columns;

  const ExportBoardDialog({
    super.key,
    required this.board,
    required this.columns,
  });

  @override
  ConsumerState<ExportBoardDialog> createState() => _ExportBoardDialogState();
}

class _ExportBoardDialogState extends ConsumerState<ExportBoardDialog> {
  ExportFormat _selectedFormat = ExportFormat.json;
  bool _includeCards = true;
  bool _isExporting = false;
  String? _exportedData;

  Future<void> _generateExport() async {
    setState(() => _isExporting = true);

    try {
      final repository = ref.read(boardRepositoryProvider);
      final cardsByColumn = <String, List<model.Card>>{};
      for (final column in widget.columns) {
        cardsByColumn[column.id] = await repository.getCardsByColumn(column.id);
      }

      String data;
      if (_selectedFormat == ExportFormat.json) {
        data = _generateJsonExport(cardsByColumn);
      } else {
        data = _generateCsvExport(cardsByColumn);
      }

      setState(() {
        _exportedData = data;
        _isExporting = false;
      });
    } catch (e) {
      setState(() => _isExporting = false);
      if (mounted) {
        OllieToast.error(context, 'Export failed: ${e.toString()}');
      }
    }
  }

  String _generateJsonExport(Map<String, List<model.Card>> cardsByColumn) {
    final Map<String, dynamic> exportData = {
      'board': {
        'id': widget.board.id,
        'name': widget.board.name,
        'description': widget.board.description,
        'archived': widget.board.archived,
        'createdAt': widget.board.createdAt.toIso8601String(),
        'updatedAt': widget.board.updatedAt.toIso8601String(),
      },
      'columns': widget.columns.map((column) {
        return {
          'id': column.id,
          'name': column.name,
          'position': column.position,
          'color': column.color,
          'wipLimit': column.wipLimit,
          'cardCount': cardsByColumn[column.id]?.length ?? 0,
        };
      }).toList(),
    };

    if (_includeCards) {
      final allCards = <Map<String, dynamic>>[];
      for (final column in widget.columns) {
        for (final card in cardsByColumn[column.id] ?? const <model.Card>[]) {
          allCards.add({
            'id': card.id,
            'columnId': card.columnId,
            'columnName': column.name,
            'title': card.title,
            'description': card.description,
            'priority': card.priority.toString(),
            'rank': card.rank,
            'completed': card.completed,
            'estimatedHours': card.estimatedHours,
            'totalLoggedHours': card.totalLoggedHours,
            'sprintId': card.sprintId,
            'subtaskCount': card.subtaskCount,
            'completedSubtaskCount': card.completedSubtaskCount,
            'dueDate': card.dueDate?.toIso8601String(),
            'createdAt': card.createdAt.toIso8601String(),
            'updatedAt': card.updatedAt.toIso8601String(),
          });
        }
      }
      exportData['cards'] = allCards;
    }

    return const JsonEncoder.withIndent('  ').convert(exportData);
  }

  String _generateCsvExport(Map<String, List<model.Card>> cardsByColumn) {
    final buffer = StringBuffer();
    if (!_includeCards) {
      buffer.writeln('Column ID,Name,Position,Color,WIP Limit,Card Count');
      for (final column in widget.columns) {
        buffer.writeln(
          '"${column.id}","${column.name}",${column.position},${column.color},'
          '${column.wipLimit ?? ''},'
          '${cardsByColumn[column.id]?.length ?? 0}',
        );
      }
      return buffer.toString();
    }

    buffer.writeln(
      'Card ID,Column,Title,Description,Priority,Rank,Completed,'
      'Estimated Hours,Logged Hours,Sprint ID,Due Date,Created At,Updated At',
    );
    for (final column in widget.columns) {
      for (final card in cardsByColumn[column.id] ?? const <model.Card>[]) {
        buffer.writeln(
          '"${card.id}","${column.name}","${_escapeCsv(card.title)}",'
          '"${_escapeCsv(card.description ?? '')}",'
          '"${card.priority.toString()}","${card.rank}",${card.completed},'
          '${card.estimatedHours ?? ''},${card.totalLoggedHours},'
          '"${card.sprintId ?? ''}",'
          '"${card.dueDate?.toIso8601String() ?? ''}",'
          '"${card.createdAt.toIso8601String()}",'
          '"${card.updatedAt.toIso8601String()}"',
        );
      }
    }
    return buffer.toString();
  }

  String _escapeCsv(String value) {
    return value.replaceAll('"', '""');
  }

  void _copyToClipboard() {
    if (_exportedData != null) {
      Clipboard.setData(ClipboardData(text: _exportedData!));
      OllieToast.success(context, 'Copied to clipboard');
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
                color: Theme.of(context).colorScheme.primaryContainer,
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.file_download,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Export Board',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),

            // Options
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Export Format',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _FormatOption(
                          icon: Icons.code,
                          title: 'JSON',
                          description: 'Structured data format',
                          isSelected: _selectedFormat == ExportFormat.json,
                          onTap: () => setState(
                            () => _selectedFormat = ExportFormat.json,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _FormatOption(
                          icon: Icons.table_chart,
                          title: 'CSV',
                          description: 'Spreadsheet format',
                          isSelected: _selectedFormat == ExportFormat.csv,
                          onTap: () => setState(
                            () => _selectedFormat = ExportFormat.csv,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  CheckboxListTile(
                    value: _includeCards,
                    onChanged: (value) =>
                        setState(() => _includeCards = value ?? true),
                    title: const Text('Include all cards'),
                    subtitle: const Text('Export cards with full details'),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 20),
                  if (_exportedData == null)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _isExporting ? null : _generateExport,
                        icon: _isExporting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.download),
                        label: Text(
                          _isExporting ? 'Generating...' : 'Generate Export',
                        ),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Export preview
            if (_exportedData != null)
              Expanded(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        border: Border(
                          top: BorderSide(color: Colors.grey.shade200),
                          bottom: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green.shade700,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Export generated successfully',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          IconButton(
                            onPressed: _copyToClipboard,
                            icon: const Icon(Icons.copy),
                            tooltip: 'Copy to clipboard',
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.all(20),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.outline.withValues(alpha: 0.3),
                          ),
                        ),
                        child: SingleChildScrollView(
                          child: SelectableText(
                            _exportedData!,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
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

class _FormatOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const _FormatOption({
    required this.icon,
    required this.title,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade50 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? Colors.blue : Colors.grey.shade700,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isSelected ? Colors.blue.shade900 : Colors.grey.shade900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
