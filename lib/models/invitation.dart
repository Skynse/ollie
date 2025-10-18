class Invitation {
  final String id;
  final String email;
  final String boardId;
  final String invitedBy;
  final InvitationStatus status;
  final DateTime createdAt;
  final DateTime? acceptedAt;

  Invitation({
    required this.id,
    required this.email,
    required this.boardId,
    required this.invitedBy,
    required this.status,
    required this.createdAt,
    this.acceptedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'boardId': boardId,
      'invitedBy': invitedBy,
      'status': status.name,
      'acceptedAt': acceptedAt?.toIso8601String(),
    };
  }

  factory Invitation.fromJson(Map<String, dynamic> json) {
    return Invitation(
      id: (json['id'] ?? json['\$id']) as String,
      email: json['email'] as String,
      boardId: json['boardId'] as String,
      invitedBy: json['invitedBy'] as String,
      status: InvitationStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => InvitationStatus.pending,
      ),
      createdAt: json['\$createdAt'] != null
          ? DateTime.parse(json['\$createdAt'] as String)
          : DateTime.now(),
      acceptedAt: json['acceptedAt'] != null
          ? DateTime.parse(json['acceptedAt'] as String)
          : null,
    );
  }
}

enum InvitationStatus { pending, accepted, expired }
