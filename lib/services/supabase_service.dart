import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;
import '../dashboard/task_model.dart';
import '../auth/auth_service.dart';
import '../auth/profile_model.dart';
import '../project/project_model.dart';
import '../project/project_task_model.dart';

class SupabaseService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AuthService _authService = AuthService();

  // Auth methods
  Future<AuthResponse> login(String email, String password) async {
    try {
      final response = await _authService.login(email, password);

      // Check if the user has a profile and create one if they don't
      if (response.user != null) {
        await _ensureProfileExists(response.user!.id, email);
      }

      notifyListeners();
      return response;
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  // Public method to ensure the current user has a profile
  Future<void> ensureCurrentUserHasProfile() async {
    final user = currentUser;
    if (user != null) {
      await _ensureProfileExists(user.id, user.email ?? '');
    }
  }

  // Checks if a profile exists for the user and creates one if it doesn't
  Future<void> _ensureProfileExists(String userId, String email) async {
    try {
      // Check if profile exists
      final existingProfile = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      // If no profile exists, create one
      if (existingProfile == null) {
        await _createProfile(userId, email);
      }
    } catch (e) {
      debugPrint('Error checking/creating profile: $e');
    }
  }

  Future<AuthResponse> signup(String email, String password) async {
    try {
      final response = await _authService.signup(email, password);

      // Create a profile for the user if signup is successful
      if (response.user != null) {
        await _createProfile(response.user!.id, email);
      }

      notifyListeners();
      return response;
    } catch (e) {
      throw Exception('Signup failed: $e');
    }
  }

  // Create user profile in the profiles table
  Future<void> _createProfile(String userId, String email) async {
    try {
      await _supabase.from('profiles').insert({
        'id': userId,
        'username':
            email.split('@')[0], // Using part of email as default username
        'bio': '', // Empty bio by default
      });
    } catch (e) {
      // Profile might already exist or there might be other errors
      // We'll just log it but not fail the signup process
      debugPrint('Failed to create profile: $e');
    }
  }

  // Get user profile
  Future<Profile?> getUserProfile(String userId) async {
    try {
      final data =
          await _supabase.from('profiles').select().eq('id', userId).single();

      return Profile.fromJson(data);
    } catch (e) {
      debugPrint('Error fetching profile: $e');
      return null;
    }
  }

  // Update user profile
  Future<void> updateUserProfile(Profile profile) async {
    try {
      await _supabase
          .from('profiles')
          .update(profile.toJson())
          .eq('id', profile.id);

      notifyListeners();
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // Upload profile image
  Future<String?> uploadProfileImage(String userId, File imageFile) async {
    try {
      final fileExt = path.extension(imageFile.path);
      final fileName = '$userId$fileExt';
      final filePath = 'profiles/$fileName';

      // Upload the file to Supabase Storage
      await _supabase.storage.from('avatars').upload(
            filePath,
            imageFile,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      // Get the public URL
      final imageUrl = _supabase.storage.from('avatars').getPublicUrl(filePath);

      // Update the profile with the avatar URL
      await _supabase
          .from('profiles')
          .update({'avatar_url': imageUrl}).eq('id', userId);

      notifyListeners();
      return imageUrl;
    } catch (e) {
      debugPrint('Error uploading profile image: $e');
      return null;
    }
  }

  // Get profile image URL
  String? getProfileImageUrl(String userId) {
    try {
      return _supabase.storage.from('avatars').getPublicUrl('profiles/$userId');
    } catch (e) {
      debugPrint('Error getting profile image URL: $e');
      return null;
    }
  }

  Future<void> logout() async {
    try {
      await _authService.logout();
      notifyListeners();
    } catch (e) {
      throw Exception('Logout failed: $e');
    }
  }

  Future<void> resendVerificationEmail(String email) async {
    await _authService.resendVerificationEmail(email);
  }

  User? get currentUser => _authService.currentUser;
  Stream<AuthState> get authStateChanges => _authService.authStateChanges;

  // Task methods
  Future<List<Task>> getTasks(String userId) async {
    try {
      final response = await _supabase
          .from('tasks')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List).map((task) => Task.fromJson(task)).toList();
    } catch (e) {
      throw Exception('Failed to fetch tasks: $e');
    }
  }

  Future<void> addTask(Task task) async {
    try {
      await _supabase.from('tasks').insert(task.toJson());
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to add task: $e');
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      await _supabase.from('tasks').delete().eq('id', taskId);
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to delete task: $e');
    }
  }

  Future<void> updateTask(Task task) async {
    try {
      await _supabase.from('tasks').update(task.toJson()).eq('id', task.id);
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to update task: $e');
    }
  }

  // Project methods
  Future<List<Project>> getProjects(String userId) async {
    try {
      final response = await _supabase
          .from('projects')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((project) => Project.fromJson(project))
          .toList();
    } catch (e) {
      debugPrint('Failed to fetch projects: $e');
      return [];
    }
  }

  Future<Project?> getProject(String projectId) async {
    try {
      final response = await _supabase
          .from('projects')
          .select()
          .eq('id', projectId)
          .single();

      return Project.fromJson(response);
    } catch (e) {
      debugPrint('Failed to fetch project: $e');
      return null;
    }
  }

  Future<void> addProject(Project project) async {
    try {
      await _supabase.from('projects').insert(project.toJson());
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to add project: $e');
    }
  }

  Future<void> updateProject(Project project) async {
    try {
      await _supabase
          .from('projects')
          .update(project.toJson())
          .eq('id', project.id);
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to update project: $e');
    }
  }

  Future<void> deleteProject(String projectId) async {
    try {
      // First delete all tasks associated with this project
      await _supabase
          .from('project_tasks')
          .delete()
          .eq('project_id', projectId);
      // Then delete the project
      await _supabase.from('projects').delete().eq('id', projectId);
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to delete project: $e');
    }
  }

  // Project Task methods
  Future<List<ProjectTask>> getProjectTasks(String projectId) async {
    try {
      final response = await _supabase
          .from('project_tasks')
          .select()
          .eq('project_id', projectId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((task) => ProjectTask.fromJson(task))
          .toList();
    } catch (e) {
      debugPrint('Failed to fetch project tasks: $e');
      return [];
    }
  }

  Future<void> addProjectTask(ProjectTask task) async {
    try {
      await _supabase.from('project_tasks').insert(task.toJson());

      // Update the project's taskIds list
      final project = await getProject(task.projectId);
      if (project != null) {
        final updatedTaskIds = [...project.taskIds, task.id];
        await updateProject(project.copyWith(taskIds: updatedTaskIds));
      }

      notifyListeners();
    } catch (e) {
      throw Exception('Failed to add project task: $e');
    }
  }

  Future<void> updateProjectTask(ProjectTask task) async {
    try {
      await _supabase
          .from('project_tasks')
          .update(task.toJson())
          .eq('id', task.id);
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to update project task: $e');
    }
  }

  Future<void> deleteProjectTask(ProjectTask task) async {
    try {
      await _supabase.from('project_tasks').delete().eq('id', task.id);

      // Update the project's taskIds list
      final project = await getProject(task.projectId);
      if (project != null) {
        final updatedTaskIds =
            project.taskIds.where((id) => id != task.id).toList();
        await updateProject(project.copyWith(taskIds: updatedTaskIds));
      }

      notifyListeners();
    } catch (e) {
      throw Exception('Failed to delete project task: $e');
    }
  }

  Future<void> toggleProjectTaskCompletion(ProjectTask task) async {
    try {
      final updatedTask = task.copyWith(isCompleted: !task.isCompleted);
      await updateProjectTask(updatedTask);
    } catch (e) {
      throw Exception('Failed to toggle task completion: $e');
    }
  }
}
