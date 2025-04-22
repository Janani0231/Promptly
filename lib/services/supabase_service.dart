import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../dashboard/task_model.dart';
import '../auth/auth_service.dart';

class SupabaseService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AuthService _authService = AuthService();

  // Auth methods
  Future<AuthResponse> login(String email, String password) async {
    try {
      final response = await _authService.login(email, password);
      notifyListeners();
      return response;
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  Future<AuthResponse> signup(String email, String password) async {
    try {
      final response = await _authService.signup(email, password);
      notifyListeners();
      return response;
    } catch (e) {
      throw Exception('Signup failed: $e');
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

      return (response as List)
          .map((task) => Task.fromJson(task))
          .toList();
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
      await _supabase
          .from('tasks')
          .update(task.toJson())
          .eq('id', task.id);
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to update task: $e');
    }
  }
} 