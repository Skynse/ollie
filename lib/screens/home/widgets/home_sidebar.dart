import 'package:flutter/material.dart';
import 'package:ollie/components/ollie_ui/theme_extensions.dart';

/// Sidebar navigation component for the homepage
class HomeSidebar extends StatelessWidget {
  final String selectedView;
  final Function(String) onViewChanged;
  final dynamic user;
  final bool isLoadingAuth;
  final int myProjectsCount;
  final int sharedProjectsCount;
  final VoidCallback onUserMenuTap;

  const HomeSidebar({
    super.key,
    required this.selectedView,
    required this.onViewChanged,
    required this.user,
    required this.isLoadingAuth,
    required this.myProjectsCount,
    required this.sharedProjectsCount,
    required this.onUserMenuTap,
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
          // Header
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
                Text(
                  'Ollie',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: context.textColor,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Navigation items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _SidebarItem(
                  icon: Icons.dashboard_outlined,
                  label: 'My Projects',
                  isSelected: selectedView == 'my-projects',
                  onTap: () => onViewChanged('my-projects'),
                  count: myProjectsCount,
                ),
                _SidebarItem(
                  icon: Icons.people_outline,
                  label: 'Shared with Me',
                  isSelected: selectedView == 'shared',
                  onTap: () => onViewChanged('shared'),
                  count: sharedProjectsCount,
                ),
              ],
            ),
          ),

          // User menu at bottom
          const Divider(height: 1),
          InkWell(
            onTap: onUserMenuTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: isLoadingAuth
                  ? const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: context.primaryColor.withOpacity(
                            0.2,
                          ),
                          radius: 18,
                          child: Text(
                            user?.name?.substring(0, 1).toUpperCase() ?? 'U',
                            style: TextStyle(
                              color: context.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.name ?? 'User Name',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: context.textColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                user?.email ?? 'user@example.com',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: context.secondaryTextColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.more_horiz,
                          color: context.secondaryTextColor,
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sidebar navigation item
class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final int? count;

  const _SidebarItem({
    required this.icon,
    required this.label,
    this.isSelected = false,
    required this.onTap,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ListTile(
        leading: Icon(
          icon,
          size: 20,
          color: isSelected ? context.primaryColor : context.secondaryTextColor,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? context.primaryColor : context.textColor,
          ),
        ),
        trailing: count != null
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? context.primaryColor
                      : context.borderColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? context.surfaceColor
                        : context.secondaryTextColor,
                  ),
                ),
              )
            : null,
        selected: isSelected,
        selectedTileColor: context.primaryColor.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        onTap: onTap,
      ),
    );
  }
}
