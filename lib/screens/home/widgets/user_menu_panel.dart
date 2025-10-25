import 'package:flutter/material.dart';
import 'package:ollie/components/ollie_ui/theme_extensions.dart';

/// Modern user menu panel that slides up from bottom-left
class UserMenuPanel extends StatelessWidget {
  final dynamic user;
  final VoidCallback onClose;
  final VoidCallback onLogout;

  const UserMenuPanel({
    super.key,
    required this.user,
    required this.onClose,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClose,
      child: Container(
        color: Colors.black38,
        child: Align(
          alignment: Alignment.bottomLeft,
          child: GestureDetector(
            onTap: () {}, // Prevent closing when tapping panel
            child: Container(
              width: 320,
              margin: const EdgeInsets.only(left: 8, bottom: 8),
              decoration: BoxDecoration(
                color: context.surfaceColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: context.shadowMedium,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header with user info
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: context.surfaceVariantColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: context.primaryColor.withOpacity(
                            0.2,
                          ),
                          radius: 24,
                          child: Text(
                            user?.name?.substring(0, 1).toUpperCase() ?? 'U',
                            style: TextStyle(
                              color: context.primaryColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.name ?? 'User Name',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: context.textColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                user?.email ?? 'user@example.com',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: context.secondaryTextColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Menu items
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      children: [
                        // Future menu items can be uncommented here:
                        // _UserMenuItem(
                        //   icon: Icons.person_outline,
                        //   label: 'Profile',
                        //   onTap: () {
                        //     onClose();
                        //     // TODO: Navigate to profile
                        //   },
                        // ),
                        // _UserMenuItem(
                        //   icon: Icons.settings_outlined,
                        //   label: 'Settings',
                        //   onTap: () {
                        //     onClose();
                        //     // TODO: Navigate to settings
                        //   },
                        // ),
                        // _UserMenuItem(
                        //   icon: Icons.help_outline,
                        //   label: 'Help & Support',
                        //   onTap: () {
                        //     onClose();
                        //     // TODO: Navigate to help
                        //   },
                        // ),
                        const Divider(height: 1),
                        _UserMenuItem(
                          icon: Icons.logout,
                          label: 'Logout',
                          isDestructive: true,
                          onTap: onLogout,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Individual menu item in user panel
class _UserMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _UserMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? context.dangerColor : context.textColor;
    final iconColor = isDestructive
        ? context.dangerColor
        : context.secondaryTextColor;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
