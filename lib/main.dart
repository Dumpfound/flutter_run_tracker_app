import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_run_tracker_app/views/splash_screen_ui.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://djriyayodojiyfvhwhld.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRqcml5YXlvZG9qaXlmdmh3aGxkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTM0NzE0MTYsImV4cCI6MjEwOTA0NzQxNn0.rvypdVr6teroua6reSeNPGYBx-bQG5NGOzgrzS4dhjI', // ← วาง anon key ตรงนี้
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Run Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 5, 1, 80),
        ),
        useMaterial3: true,
      ),
      home: const SplashScreenUI(),
    );
  }
}
