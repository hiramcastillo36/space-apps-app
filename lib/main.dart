import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skai/Auth.dart';
import 'package:skai/widgets/audio.dart';
import 'package:skai/widgets/voz.dart';
import 'package:skai/widgets/navigation_shell.dart';

void main() async{
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SKAI',
      theme: buildTheme(context),
        home: const NavigationShell(),
        routes: {
          '/login': (context) => const AuthPage(),
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