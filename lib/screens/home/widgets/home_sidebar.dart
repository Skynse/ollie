import 'package:flutter/material.dart';
import 'package:ollie/components/ollie_ui/theme_extensions.dart';

class HomeSidebar extends StatelessWidget {
  final String selectedView;
  final Function(String) onViewChanged;
  final int projectsCount;
  final int archivedProjectsCount;

  const HomeSidebar({
    super.key,
    required this.selectedView,
    required this.onViewChanged,
    required this.projectsCount,
    required this.archivedProjectsCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: context.surfaceVariantColor,
        border: Border(right: BorderSide(color: context.borderColor, width: 1)),
        boxShadow: context.shadowSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        context.primaryColor,
                        context.primaryColor.withOpacity(0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.dashboard_rounded,
                    color: context.surfaceColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Ollie',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: context.textColor,
                        ),
                      ),
                      const TextSpan(
                        text: ' beta',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 7),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _SidebarItem(
                  icon: Icons.dashboard_outlined,
                  label: 'Projects',
                  isSelected: selectedView == 'projects',
                  onTap: () => onViewChanged('projects'),
                  count: projectsCount,
                ),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Divider(height: 1),
                ),
                _SidebarItem(
                  icon: Icons.archive_outlined,
                  label: 'Archived',
                  isSelected: selectedView == 'archived',
                  onTap: () => onViewChanged('archived'),
                  count: archivedProjectsCount,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final int count;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: isSelected
            ? context.primaryColor.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected
                      ? context.primaryColor
                      : context.secondaryTextColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                          ? context.primaryColor
                          : context.textColor,
                    ),
                  ),
                ),
                if (count > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? context.primaryColor.withOpacity(0.15)
                          : context.surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      count.toString(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? context.primaryColor
                            : context.secondaryTextColor,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
