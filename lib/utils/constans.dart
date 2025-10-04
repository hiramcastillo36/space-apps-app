import 'package:flutter/material.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';

const Color primaryTextColor = Color(0xFF64B5F6);
const Color secondaryTextColor = Colors.grey;
const Color cardBackgroundColor = Color(0xFFF0F4F8);
const Color primaryCardColor = Color(0xFF1A237E);


void showSnackBar(BuildContext context, String texto, int duracion, String titulo, ContentType tipo) {
  // Crea el SnackBar
  final snackBar = SnackBar(
    elevation: 0,
    behavior: SnackBarBehavior.floating,
    backgroundColor: Colors.transparent,
    content: AwesomeSnackbarContent(
      title: titulo,
      message: texto,
      contentType: tipo, // Recibe ContentType directamente
    ),
    duration: Duration(seconds: duracion),
  );

  // Muestra el SnackBar usando el ScaffoldMessenger
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(snackBar);
}