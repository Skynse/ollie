import 'package:appwrite/appwrite.dart';
import '../../models/project.dart';
import '../project_repository.dart';

class AppwriteProjectRepository implements ProjectRepository {
  final Databases databases;
  final String databaseId;

  AppwriteProjectRepository({
    required this.databases,
    required this.databaseId,
  });

  static const String projectsCollection = 'projects';

  @override
  Future<Project> getProject(String projectId) async {
    final doc = await databases.getDocument(
      databaseId: databaseId,
      collectionId: projectsCollection,
      documentId: projectId,
    );
    return Project.fromJson(doc.data);
  }

  @override
  Future<List<Project>> getProjectsByUser(String userId) async {
    final docs = await databases.listDocuments(
      databaseId: databaseId,
      collectionId: projectsCollection,
      queries: [Query.equal('members', userId)],
    );
    return docs.documents.map((doc) => Project.fromJson(doc.data)).toList();
  }

  @override
  Future<Project> createProject(Project project) async {
    final doc = await databases.createDocument(
      databaseId: databaseId,
      collectionId: projectsCollection,
      documentId: ID.unique(),
      data: project.toJson(),
    );
    return Project.fromJson(doc.data);
  }

  @override
  Future<Project> updateProject(Project project) async {
    final doc = await databases.updateDocument(
      databaseId: databaseId,
      collectionId: projectsCollection,
      documentId: project.id,
      data: project.toJson(),
    );
    return Project.fromJson(doc.data);
  }

  @override
  Future<void> deleteProject(String projectId) async {
    await databases.deleteDocument(
      databaseId: databaseId,
      collectionId: projectsCollection,
      documentId: projectId,
    );
  }

  @override
  Future<void> addMember(String projectId, String userId) async {
    final project = await getProject(projectId);
    final updatedMemberIds = [...project.memberIds, userId];
    await databases.updateDocument(
      databaseId: databaseId,
      collectionId: projectsCollection,
      documentId: projectId,
      data: {'members': updatedMemberIds},
    );
  }

  @override
  Future<void> removeMember(String projectId, String userId) async {
    final project = await getProject(projectId);
    final updatedMemberIds = project.memberIds
        .where((id) => id != userId)
        .toList();
    await databases.updateDocument(
      databaseId: databaseId,
      collectionId: projectsCollection,
      documentId: projectId,
      data: {'members': updatedMemberIds},
    );
  }
}
