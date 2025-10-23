import 'package:appwrite/appwrite.dart';
import '../../models/sprint.dart';
import '../../models/time_log.dart';
import '../../models/burndown_snapshot.dart';
import '../sprint_repository.dart';

/// Appwrite implementation of SprintRepository
class AppwriteSprintRepository implements SprintRepository {
  final Databases databases;
  final String databaseId;

  AppwriteSprintRepository({required this.databases, required this.databaseId});

  static const String sprintsCollection = 'sprints';
  static const String timeLogsCollection = 'time_logs';
  static const String burndownSnapshotsCollection = 'burdown_snapshots';

  // Sprint operations
  @override
  Future<Sprint> getSprint(String sprintId) async {
    final doc = await databases.getDocument(
      databaseId: databaseId,
      collectionId: sprintsCollection,
      documentId: sprintId,
    );
    return Sprint.fromJson(doc.data);
  }

  @override
  Future<List<Sprint>> getSprintsByBoard(String boardId) async {
    final docs = await databases.listDocuments(
      databaseId: databaseId,
      collectionId: sprintsCollection,
      queries: [
        Query.equal('boardId', boardId),
        Query.orderDesc('\$createdAt'),
      ],
    );
    return docs.documents.map((doc) => Sprint.fromJson(doc.data)).toList();
  }

  @override
  Future<Sprint?> getActiveSprint(String boardId) async {
    final docs = await databases.listDocuments(
      databaseId: databaseId,
      collectionId: sprintsCollection,
      queries: [
        Query.equal('boardId', boardId),
        Query.equal('status', 'active'),
        Query.limit(1),
      ],
    );
    if (docs.documents.isEmpty) return null;
    return Sprint.fromJson(docs.documents.first.data);
  }

  @override
  Future<Sprint> createSprint(Sprint sprint) async {
    final doc = await databases.createDocument(
      databaseId: databaseId,
      collectionId: sprintsCollection,
      documentId: ID.unique(),
      data: sprint.toJson(),
    );
    return Sprint.fromJson(doc.data);
  }

  @override
  Future<Sprint> updateSprint(Sprint sprint) async {
    final doc = await databases.updateDocument(
      databaseId: databaseId,
      collectionId: sprintsCollection,
      documentId: sprint.id,
      data: sprint.toJson(),
    );
    return Sprint.fromJson(doc.data);
  }

  @override
  Future<void> deleteSprint(String sprintId) async {
    await databases.deleteDocument(
      databaseId: databaseId,
      collectionId: sprintsCollection,
      documentId: sprintId,
    );
  }

  // Time log operations
  @override
  Future<TimeLog> getTimeLog(String timeLogId) async {
    final doc = await databases.getDocument(
      databaseId: databaseId,
      collectionId: timeLogsCollection,
      documentId: timeLogId,
    );
    return TimeLog.fromJson(doc.data);
  }

  @override
  Future<List<TimeLog>> getTimeLogsByCard(String cardId) async {
    final docs = await databases.listDocuments(
      databaseId: databaseId,
      collectionId: timeLogsCollection,
      queries: [Query.equal('cardId', cardId), Query.orderDesc('\$createdAt')],
    );
    return docs.documents.map((doc) => TimeLog.fromJson(doc.data)).toList();
  }

  @override
  Future<List<TimeLog>> getTimeLogsBySprint(String sprintId) async {
    final docs = await databases.listDocuments(
      databaseId: databaseId,
      collectionId: timeLogsCollection,
      queries: [
        Query.equal('sprintId', sprintId),
        Query.orderDesc('\$createdAt'),
      ],
    );
    return docs.documents.map((doc) => TimeLog.fromJson(doc.data)).toList();
  }

  @override
  Future<TimeLog?> getActiveTimeLog(String userId) async {
    final docs = await databases.listDocuments(
      databaseId: databaseId,
      collectionId: timeLogsCollection,
      queries: [
        Query.equal('userId', userId),
        Query.equal('isActive', true),
        Query.limit(1),
      ],
    );
    if (docs.documents.isEmpty) return null;
    return TimeLog.fromJson(docs.documents.first.data);
  }

  @override
  Future<TimeLog> createTimeLog(TimeLog timeLog) async {
    final doc = await databases.createDocument(
      databaseId: databaseId,
      collectionId: timeLogsCollection,
      documentId: ID.unique(),
      data: timeLog.toJson(),
    );
    return TimeLog.fromJson(doc.data);
  }

  @override
  Future<TimeLog> updateTimeLog(TimeLog timeLog) async {
    final doc = await databases.updateDocument(
      databaseId: databaseId,
      collectionId: timeLogsCollection,
      documentId: timeLog.id,
      data: timeLog.toJson(),
    );
    return TimeLog.fromJson(doc.data);
  }

  @override
  Future<void> deleteTimeLog(String timeLogId) async {
    await databases.deleteDocument(
      databaseId: databaseId,
      collectionId: timeLogsCollection,
      documentId: timeLogId,
    );
  }

  // Burndown snapshot operations
  @override
  Future<BurndownSnapshot> getBurndownSnapshot(String snapshotId) async {
    final doc = await databases.getDocument(
      databaseId: databaseId,
      collectionId: burndownSnapshotsCollection,
      documentId: snapshotId,
    );
    return BurndownSnapshot.fromJson(doc.data);
  }

  @override
  Future<List<BurndownSnapshot>> getBurndownSnapshotsBySprint(
    String sprintId,
  ) async {
    final docs = await databases.listDocuments(
      databaseId: databaseId,
      collectionId: burndownSnapshotsCollection,
      queries: [Query.equal('sprintId', sprintId), Query.orderAsc('date')],
    );
    return docs.documents
        .map((doc) => BurndownSnapshot.fromJson(doc.data))
        .toList();
  }

  @override
  Future<BurndownSnapshot> createBurndownSnapshot(
    BurndownSnapshot snapshot,
  ) async {
    final doc = await databases.createDocument(
      databaseId: databaseId,
      collectionId: burndownSnapshotsCollection,
      documentId: ID.unique(),
      data: snapshot.toJson(),
    );
    return BurndownSnapshot.fromJson(doc.data);
  }

  @override
  Future<void> deleteBurndownSnapshot(String snapshotId) async {
    await databases.deleteDocument(
      databaseId: databaseId,
      collectionId: burndownSnapshotsCollection,
      documentId: snapshotId,
    );
  }
}
