import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/sync_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const HtmlViewerApp());
}

class HtmlViewerApp extends StatelessWidget {
  const HtmlViewerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HTML Viewer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const SyncScreen(),
    );
  }
}
