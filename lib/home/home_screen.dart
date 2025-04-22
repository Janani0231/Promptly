import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app/theme_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Theme Toggle Button
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: Icon(
                    isDark ? Icons.light_mode : Icons.dark_mode,
                    color: Colors.purple,
                  ),
                  onPressed: () {
                    // Toggle theme
                    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
                    themeProvider.toggleTheme();
                  },
                ),
              ),
              const Spacer(),
              // Centered Image
              Image.asset(
                'assets/images/productive_bg.jpg',
                height: 200,
                width: 200,
              ),
              const SizedBox(height: 32),
              // Quote Text
              const Text(
                'PROMPTLY DONE,\nPERFECTLY WON!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
              const Spacer(),
              // Get Started Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/login');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Let's Get Started",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Sign Up Button
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/signup');
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.purple,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Create an Account',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 