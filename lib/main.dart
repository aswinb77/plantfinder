import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/home_screen.dart';

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    cameras = await availableCameras();
  } catch (e) {
    debugPrint('Error getting cameras: $e');
  }

  try {
    // Note: User needs to run `flutterfire configure` to generate firebase_options.dart
    await Firebase.initializeApp(
      // options: DefaultFirebaseOptions.currentPlatform, 
    );
  } catch (e) {
    debugPrint('Firebase not configured yet: $e');
  }

  runApp(const PlantAnalyzerApp());
}

class PlantAnalyzerApp extends StatelessWidget {
  const PlantAnalyzerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Plant Analyzer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
