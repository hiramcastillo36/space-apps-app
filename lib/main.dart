import 'package:flutter/material.dart';
import 'package:skai/index.dart';
import 'package:skai/widgets/navbar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skai/Auth.dart';
void main() {
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
        home: const AuthPage(),
    );
  }
}

/// Función para configurar el tema
ThemeData buildTheme(BuildContext context) {
  return ThemeData(
    textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
  );
}