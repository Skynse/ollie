import 'card.dart';
import 'user.dart';
import 'priority.dart';

/// A hydrated version of Card that contains full User objects instead of just IDs
/// This eliminates the need for multiple async lookups in the UI layer
class HydratedCard {
  final Card card;
  final List<User> assignees;
  final User creator;

  HydratedCard({
    required this.card,
    required this.assignees,
    required this.creator,
  });

  // Convenience getters that delegate to the underlying card
  String get id => card.id;
  String get columnId => card.columnId;
  String get title => card.title;
  String? get description => card.description;
  int get position => card.position;
  List<String> get assigneeIds => card.assigneeIds;
  List<String> get labelIds => card.labelIds;
  Priority get priority => card.priority;
  DateTime? get dueDate => card.dueDate;
  int get commentCount => card.commentCount;
  DateTime get createdAt => card.createdAt;
  DateTime get updatedAt => card.updatedAt;
  String get createdBy => card.createdBy;
  double? get estimatedHours => card.estimatedHours;
  double get totalLoggedHours => card.totalLoggedHours;
  String? get sprintId => card.sprintId;
  String get rank => card.rank;
  bool get completed => card.completed;

  /// Create a copy with updated card data
  /// Note: This only updates the card data, not the hydrated users
  /// To update users, create a new HydratedCard instance
  HydratedCard copyWith({Card? card, List<User>? assignees, User? creator}) {
    return HydratedCard(
      card: card ?? this.card,
      assignees: assignees ?? this.assignees,
      creator: creator ?? this.creator,
    );
  }

  /// Update the underlying card while preserving hydrated data
  HydratedCard updateCard(Card updatedCard) {
    return HydratedCard(
      card: updatedCard,
      assignees: assignees,
      creator: creator,
    );
  }
}
