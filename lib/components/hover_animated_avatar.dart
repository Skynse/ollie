import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ollie/models/user.dart';

class HoverAnimatedAvatar extends ConsumerStatefulWidget {
  final User user;

  const HoverAnimatedAvatar({required this.user});

  @override
  ConsumerState<HoverAnimatedAvatar> createState() =>
      _HoverAnimatedAvatarState();
}

class _HoverAnimatedAvatarState extends ConsumerState<HoverAnimatedAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _controller.forward(),
      onExit: (_) => _controller.reverse(),
      cursor: SystemMouseCursors.click,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Tooltip(
          message: widget.user.name,
          child: CircleAvatar(
            radius: 16,
            backgroundColor: Colors.blue.shade100,
            child: Text(
              widget.user.name.isNotEmpty
                  ? widget.user.name[0].toUpperCase()
                  : '?',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
