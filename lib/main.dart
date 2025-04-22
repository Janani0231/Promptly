import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app/theme.dart';
import 'app/theme_provider.dart';
import 'auth/login_screen.dart';
import 'auth/signup_screen.dart';
import 'auth/profile_screen.dart';
import 'home/home_dashboard_screen.dart';
import 'project/projects_screen.dart';
import 'services/supabase_service.dart';
import 'home/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://urynacdzilbulbgvnmrj.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVyeW5hY2R6aWxidWxiZ3ZubXJqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDUxNTAwMTksImV4cCI6MjA2MDcyNjAxOX0.pXrwZ1iokXLIitTieJtltHHscd7EuqcJlTNoQZPKUdw',
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
            theme: themeProvider.isDarkTheme
                ? AppTheme.darkTheme
                : AppTheme.lightTheme,
            initialRoute: '/',
            routes: {
              '/': (context) => const HomeScreen(),
              '/login': (context) => const LoginScreen(),
              '/signup': (context) => const SignupScreen(),
              '/dashboard': (context) {
                // Ensure user profile exists before loading dashboard
                final service =
                    Provider.of<SupabaseService>(context, listen: false);
                service.ensureCurrentUserHasProfile();
                return const HomeDashboardScreen();
              },
              '/profile': (context) => const ProfileScreen(),
              '/projects': (context) => const ProjectsScreen(),
            },
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    // Check current user and ensure they have a profile
    _checkCurrentUserProfile();
  }

  Future<void> _checkCurrentUserProfile() async {
    final supabaseService = context.read<SupabaseService>();
    final user = supabaseService.currentUser;
    if (user != null) {
      // If user is logged in, ensure they have a profile
      await supabaseService.ensureCurrentUserHasProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: context.read<SupabaseService>().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final session = snapshot.data!.session;
          if (session != null) {
            return const HomeDashboardScreen();
          }
        }
        return const LoginScreen();
      },
    );
  }
}
