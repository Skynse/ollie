import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ollie/components/ollie_ui/ollie_textfield.dart';
import '../providers/boards_provider.dart';
import 'ollie_ui/ollie_dialog.dart';
import 'ollie_ui/ollie_button.dart';

/// Dialog for inviting members to a board by email
class InviteMemberDialog extends ConsumerStatefulWidget {
  final String boardId;

  const InviteMemberDialog({super.key, required this.boardId});

  @override
  ConsumerState<InviteMemberDialog> createState() => _InviteMemberDialogState();
}

class _InviteMemberDialogState extends ConsumerState<InviteMemberDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OllieDialog(
      title: 'Invite Member',
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter the email address of the person you want to invite',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 16),

              // Email input
              OllieTextfield.email(
                hint: 'Invite a friend',
                controller: _emailController,
                label: 'Email Address',

                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
                enabled: !_isLoading,
              ),

              const SizedBox(height: 16),

              // Error message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Success message
              if (_successMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: Colors.green.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _successMessage!,
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              if (_errorMessage != null || _successMessage != null)
                const SizedBox(height: 16),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OllieButton.outline(
                    text: 'Cancel',
                    onPressed: () => Navigator.pop(context),
                    disabled: _isLoading,
                  ),
                  const SizedBox(width: 12),
                  OllieButton(
                    text: _isLoading ? 'Inviting...' : 'Invite',
                    onPressed: _inviteMember,
                    icon: _isLoading ? null : Icons.send,
                    disabled: _isLoading,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _inviteMember() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final email = _emailController.text.trim().toLowerCase();
      final userRepository = ref.read(userRepositoryProvider);

      // First, check if user already exists
      final existingUser = await userRepository.getUserByEmail(email);

      if (existingUser != null) {
        // User exists, add them to the board
        await ref
            .read(boardRepositoryProvider)
            .addMember(widget.boardId, existingUser.id);

        setState(() {
          _isLoading = false;
          _successMessage = '${existingUser.name} has been added to the board!';
          _emailController.clear();
        });

        // Close dialog after 2 seconds
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.pop(context);
        }
      } else {
        // User doesn't exist, send invite
        await userRepository.inviteUserByEmail(email, boardId: widget.boardId);

        setState(() {
          _isLoading = false;
          _successMessage = 'Invitation sent to $email!';
          _emailController.clear();
        });

        // Close dialog after 2 seconds
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to invite member: ${e.toString()}';
      });
    }
  }
}
