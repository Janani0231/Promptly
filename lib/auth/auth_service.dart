import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<AuthResponse> signup(String email, String password) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: 'io.supabase.flutter://login-callback/',
      );
      
      if (response.user == null) {
        throw Exception('Please check your email for verification link. If the link has expired, you can request a new one.');
      }
      
      return response;
    } catch (e) {
      if (e is AuthException) {
        throw Exception(e.message);
      }
      throw Exception('Signup failed: $e');
    }
  }

  Future<void> resendVerificationEmail(String email) async {
    try {
      await _supabase.auth.resend(
        type: OtpType.signup,
        email: email,
        emailRedirectTo: 'io.supabase.flutter://login-callback/',
      );
    } catch (e) {
      if (e is AuthException) {
        throw Exception(e.message);
      }
      throw Exception('Failed to resend verification email: $e');
    }
  }

  Future<AuthResponse> login(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user == null) {
        throw Exception('User not found');
      }
      
      if (response.user!.emailConfirmedAt == null) {
        throw Exception('Please verify your email first. You can request a new verification link if the previous one has expired.');
      }
      
      return response;
    } catch (e) {
      if (e is AuthException) {
        throw Exception(e.message);
      }
      throw Exception('Login failed: $e');
    }
  }

  Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw Exception('Logout failed: $e');
    }
  }

  User? get currentUser => _supabase.auth.currentUser;
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
} 