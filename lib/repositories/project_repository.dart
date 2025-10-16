import '../models/project.dart';

/// Abstract repository interface - backend agnostic
abstract class ProjectRepository {
  Future<Project> getProject(String projectId);
  Future<List<Project>> getProjectsByUser(String userId);
  Future<Project> createProject(Project project);
  Future<Project> updateProject(Project project);
  Future<void> deleteProject(String projectId);
  Future<void> addMember(String projectId, String userId);
  Future<void> removeMember(String projectId, String userId);
}
