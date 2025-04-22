import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app/theme.dart';
import 'app/theme_provider.dart';
import 'auth/login_screen.dart';
import 'auth/signup_screen.dart';
import 'dashboard/dashboard_screen.dart';
import 'services/supabase_service.dart';
import 'home/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://urynacdzilbulbgvnmrj.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVyeW5hY2R6aWxidWxiZ3ZubXJqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDUxNTAwMTksImV4cCI6MjA2MDcyNjAxOX0.pXrwZ1iokXLIitTieJtltHHscd7EuqcJlTNoQZPKUdw',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SupabaseService()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Mini TaskHub',
            theme: themeProvider.isDarkTheme ? AppTheme.darkTheme : AppTheme.lightTheme,
            initialRoute: '/',
            routes: {
              '/': (context) => const HomeScreen(),
              '/login': (context) => const LoginScreen(),
              '/signup': (context) => const SignupScreen(),
              '/dashboard': (context) => const DashboardScreen(),
            },
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: context.read<SupabaseService>().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final session = snapshot.data!.session;
          if (session != null) {
            return const DashboardScreen();
          }
        }
        return const LoginScreen();
      },
    );
  }
}
