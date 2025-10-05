import 'package:flutter/material.dart';
import 'package:skai/index.dart';
import 'package:skai/widgets/navbar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skai/Auth.dart';
import 'package:skai/services/auth_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SKAI',
      theme: buildTheme(context),
      home: FutureBuilder<bool>(
        future: AuthService.isAuthenticated(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return snapshot.data == true ? const Index() : const AuthPage();
        },
      ),
    );
  }
}

/// Función para configurar el tema
ThemeData buildTheme(BuildContext context) {
  return ThemeData(
    textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
  );
}