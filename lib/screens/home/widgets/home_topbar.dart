import 'package:flutter/material.dart';
import 'package:ollie/components/ollie_ui/theme_extensions.dart';
import 'package:ollie/components/ollie_ui/theme_toggle.dart';
import '../../../utils/responsive.dart';

/// Top bar for the homepage with search, sorting, and view controls
class HomeTopBar extends StatelessWidget {
  final String selectedView;
  final TextEditingController searchController;
  final String searchQuery;
  final Function(String) onSearchChanged;
  final VoidCallback onSearchClear;
  final String sortBy;
  final Function(String) onSortChanged;
  final bool isGridView;
  final Function(bool) onViewChanged;
  final VoidCallback onCreateBoard;
  final VoidCallback? onMenuTap;

  const HomeTopBar({
    super.key,
    required this.selectedView,
    required this.searchController,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onSearchClear,
    required this.sortBy,
    required this.onSortChanged,
    required this.isGridView,
    required this.onViewChanged,
    required this.onCreateBoard,
    this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;

    if (isMobile) {
      return _buildMobileTopBar(context);
    }

    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      decoration: BoxDecoration(
        color: context.surfaceColor.withValues(alpha: 0.95),
        border: Border(bottom: BorderSide(color: context.borderColor)),
        boxShadow: context.shadowSmall,
      ),
      child: Row(
        children: [
          // Title
          Text(
            selectedView == 'archived' ? 'Archived' : 'Projects',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: context.textColor,
            ),
          ),
          const SizedBox(width: 24),

          // Search bar
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              child: TextField(
                controller: searchController,
                onChanged: onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search boards...',
                  hintStyle: TextStyle(
                    color: context.secondaryTextColor.withValues(alpha: 0.6),
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: context.secondaryTextColor.withValues(alpha: 0.6),
                    size: 20,
                  ),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.close,
                            color: context.secondaryTextColor.withValues(
                              alpha: 0.6,
                            ),
                            size: 18,
                          ),
                          onPressed: onSearchClear,
                        )
                      : null,
                  filled: true,
                  fillColor: context.surfaceVariantColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  isDense: true,
                ),
              ),
            ),
          ),
          const Spacer(),

          // View toggle
          Container(
            decoration: BoxDecoration(
              color: context.surfaceVariantColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                _ViewToggleButton(
                  icon: Icons.grid_view_rounded,
                  isSelected: isGridView,
                  onTap: () => onViewChanged(true),
                ),
                _ViewToggleButton(
                  icon: Icons.view_list_rounded,
                  isSelected: !isGridView,
                  onTap: () => onViewChanged(false),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Sort dropdown
          PopupMenuButton<String>(
            initialValue: sortBy,
            onSelected: onSortChanged,
            offset: const Offset(0, 45),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'updated',
                child: Builder(
                  builder: (context) => Row(
                    children: [
                      Icon(
                        Icons.update,
                        size: 18,
                        color: context.secondaryTextColor,
                      ),
                      const SizedBox(width: 12),
                      const Text('Last Updated'),
                    ],
                  ),
                ),
              ),
              PopupMenuItem(
                value: 'created',
                child: Builder(
                  builder: (context) => Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 18,
                        color: context.secondaryTextColor,
                      ),
                      const SizedBox(width: 12),
                      const Text('Date Created'),
                    ],
                  ),
                ),
              ),
              PopupMenuItem(
                value: 'name',
                child: Builder(
                  builder: (context) => Row(
                    children: [
                      Icon(
                        Icons.sort_by_alpha,
                        size: 18,
                        color: context.secondaryTextColor,
                      ),
                      const SizedBox(width: 12),
                      const Text('Name (A-Z)'),
                    ],
                  ),
                ),
              ),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: context.surfaceVariantColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.sort, size: 18, color: context.secondaryTextColor),
                  const SizedBox(width: 8),
                  Text(
                    sortBy == 'updated'
                        ? 'Updated'
                        : sortBy == 'created'
                        ? 'Created'
                        : 'Name',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: context.textColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_drop_down,
                    size: 20,
                    color: context.secondaryTextColor,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),

          // New Board button
          FilledButton.icon(
            onPressed: onCreateBoard,
            icon: const Icon(Icons.add, size: 20),
            label: const Text('New Board'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              backgroundColor: context.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          ThemeToggle(),
        ],
      ),
    );
  }

  Widget _buildMobileTopBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.surfaceColor.withValues(alpha: 0.95),
        border: Border(bottom: BorderSide(color: context.borderColor)),
        boxShadow: context.shadowSmall,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: Title and Create button
          Row(
            children: [
              // Menu button for mobile
              if (onMenuTap != null)
                IconButton(
                  onPressed: onMenuTap,
                  icon: const Icon(Icons.menu, size: 20),
                  style: IconButton.styleFrom(
                    padding: const EdgeInsets.all(8),
                    minimumSize: const Size(36, 36),
                  ),
                  tooltip: 'Menu',
                ),
              Expanded(
                child: Text(
                  selectedView == 'archived' ? 'Archived' : 'Projects',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                    color: context.textColor,
                  ),
                ),
              ),
              IconButton(
                onPressed: onCreateBoard,
                icon: const Icon(Icons.add, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: context.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(8),
                  minimumSize: const Size(36, 36),
                ),
                tooltip: 'New Board',
              ),
              const SizedBox(width: 4),
              ThemeToggle(),
            ],
          ),
          const SizedBox(height: 12),

          // Row 2: Search and controls
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: searchController,
                  onChanged: onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    hintStyle: TextStyle(
                      color: context.secondaryTextColor.withValues(alpha: 0.6),
                      fontSize: 13,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: context.secondaryTextColor.withValues(alpha: 0.6),
                      size: 18,
                    ),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.close,
                              color: context.secondaryTextColor.withValues(
                                alpha: 0.6,
                              ),
                              size: 16,
                            ),
                            onPressed: onSearchClear,
                          )
                        : null,
                    filled: true,
                    fillColor: context.surfaceVariantColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // View toggle
              Container(
                decoration: BoxDecoration(
                  color: context.surfaceVariantColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ViewToggleButton(
                      icon: Icons.grid_view_rounded,
                      isSelected: isGridView,
                      onTap: () => onViewChanged(true),
                    ),
                    _ViewToggleButton(
                      icon: Icons.view_list_rounded,
                      isSelected: !isGridView,
                      onTap: () => onViewChanged(false),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// View toggle button for switching between grid and list views
class _ViewToggleButton extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ViewToggleButton({
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? context.surfaceColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected ? context.shadowSmall : null,
        ),
        child: Icon(
          icon,
          size: 20,
          color: isSelected ? context.primaryColor : context.secondaryTextColor,
        ),
      ),
    );
  }
}
