import 'package:flutter/material.dart';
import 'package:ollie/components/ollie_ui/theme_extensions.dart';

/// Empty state shown when there are no boards
class EmptyBoardsState extends StatelessWidget {
  final VoidCallback onCreateBoard;

  const EmptyBoardsState({super.key, required this.onCreateBoard});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  context.primaryColor.withOpacity(0.1),
                  context.primaryColor.withOpacity(0.2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.dashboard_outlined,
              size: 56,
              color: context.primaryColor.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No boards yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: context.textColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Create your first board to start organizing your work',
            style: TextStyle(fontSize: 15, color: context.secondaryTextColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: onCreateBoard,
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Create Your First Board'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              backgroundColor: context.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Empty state shown when search returns no results
class NoSearchResultsState extends StatelessWidget {
  const NoSearchResultsState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: context.secondaryTextColor.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No boards found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: context.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try searching with different keywords',
            style: TextStyle(fontSize: 14, color: context.secondaryTextColor),
          ),
        ],
      ),
    );
  }
}

/// Empty state shown for shared boards section
class EmptySharedBoardsState extends StatelessWidget {
  const EmptySharedBoardsState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: context.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.people_outline,
              size: 40,
              color: context.primaryColor.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No shared boards yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: context.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Boards shared with you will appear here',
            style: TextStyle(fontSize: 14, color: context.secondaryTextColor),
          ),
        ],
      ),
    );
  }
}

/// Error state shown when something goes wrong
class BoardsErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const BoardsErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: context.dangerColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.error_outline,
              size: 48,
              color: context.dangerColor.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Something went wrong',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: context.textColor,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              message,
              style: TextStyle(fontSize: 15, color: context.secondaryTextColor),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 20),
            label: const Text('Try Again'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              backgroundColor: context.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton loading card for better UX
class SkeletonBoardCard extends StatefulWidget {
  const SkeletonBoardCard({super.key});

  @override
  State<SkeletonBoardCard> createState() => _SkeletonBoardCardState();
}

class _SkeletonBoardCardState extends State<SkeletonBoardCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.6).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
        boxShadow: context.shadowSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Skeleton header bar
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Container(
                height: 8,
                decoration: BoxDecoration(
                  color: context.borderColor.withOpacity(_animation.value),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(15),
                  ),
                ),
              );
            },
          ),

          // Skeleton content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Skeleton title
                      AnimatedBuilder(
                        animation: _animation,
                        builder: (context, child) {
                          return Container(
                            height: 20,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: context.borderColor.withOpacity(
                                _animation.value,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      // Skeleton description lines
                      AnimatedBuilder(
                        animation: _animation,
                        builder: (context, child) {
                          return Container(
                            height: 14,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: context.borderColor.withOpacity(
                                _animation.value,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      AnimatedBuilder(
                        animation: _animation,
                        builder: (context, child) {
                          return Container(
                            height: 14,
                            width: 150,
                            decoration: BoxDecoration(
                              color: context.borderColor.withOpacity(
                                _animation.value,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  // Skeleton member badge
                  AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return Container(
                        height: 28,
                        width: 60,
                        decoration: BoxDecoration(
                          color: context.borderColor.withOpacity(
                            _animation.value,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      );
                    },
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

/// Grid view of skeleton loading cards
class SkeletonBoardsLoader extends StatelessWidget {
  const SkeletonBoardsLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(32),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 380,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 1.8,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return const SkeletonBoardCard();
      },
    );
  }
}
