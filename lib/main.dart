import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/bible_voice_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Set immersive dark status bar styling
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.bgMidnight,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const ScriptureLiveApp());
}

class ScriptureLiveApp extends StatelessWidget {
  const ScriptureLiveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scripture Live - Gemini Bible AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.themeData,
      home: const BibleVoiceScreen(),
    );
  }
}
