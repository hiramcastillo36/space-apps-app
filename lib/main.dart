import 'package:flutter/material.dart';
import 'package:skai/index.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skai/Auth.dart';
import 'package:skai/profile.dart';
import 'package:skai/widgets/navbar.dart';
import 'package:skai/widgets/navigation_shell.dart';
import 'package:skai/services/auth_service.dart';
import 'package:skai/widgets/audio.dart';
import 'package:skai/widgets/voz.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SKAI',
      theme: buildTheme(context),
      home: const Index(),
      routes: {
        '/login': (context) => const AuthPage(),
        '/home': (context) => const NavigationShell(),
      },
    );
  }
}

/// Función para configurar el tema
ThemeData buildTheme(BuildContext context) {
  return ThemeData(
    textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
  );
}
