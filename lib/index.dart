import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skai/utils/constans.dart';
import 'package:skai/skai.dart';
import 'package:skai/widgets/weather_card.dart';

class Index extends StatelessWidget {
  const Index({super.key, this.onOpenSkai});

  final VoidCallback? onOpenSkai;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: SafeArea(
        child: Stack(
          children: [
            const PositionedFillBackgroundArcs(),
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 20),
                    const WeatherCard(), // ⬅️ NUEVA CARD (clima) arriba
                    _buildAskOlivCard(context),
                    const SizedBox(height: 16),
                    // ⛔️ Se quitó “Popular activities”
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    const gradient = LinearGradient(
      colors: [Color(0xFF5B86E5), Color(0xFF9C27B0), Color(0xFFE91E63)],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShaderMask(
          shaderCallback: (bounds) => gradient.createShader(bounds),
          child: Text(
            'Hello, Chino!',
            style: GoogleFonts.poppins(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 12),
        ShaderMask(
          shaderCallback: (bounds) => gradient.createShader(bounds),
          child: Text(
            'What do you have planned for today?',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAskOlivCard(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: () {
          if (onOpenSkai != null) {
            onOpenSkai!();
          } else {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SkaiPage()));
          }
        },
        child: Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFEF5350), Color(0xFFAB47BC), Color(0xFF5C6BC0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withOpacity(0.15),
                spreadRadius: 2,
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Ask SkAI',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _olivGifCircle(size: 120, ringWidthPx: 5, gapPx: 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _olivGifCircle({double size = 110, double? ringWidthPx, double? gapPx}) {
    final borderW = ringWidthPx ?? size * 0.055;
    final innerPad = gapPx ?? size * 0.05;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: borderW),
      ),
      child: Padding(
        padding: EdgeInsets.all(innerPad),
        child: ClipOval(
          child: Image.asset(
            'assets/images/sphere.gif',
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}

/// ===== Fondo con semicírculos (componente reutilizable) =====
class PositionedFillBackgroundArcs extends StatelessWidget {
  const PositionedFillBackgroundArcs({super.key});

  @override
  Widget build(BuildContext context) {
    return const Positioned.fill(
      child: IgnorePointer(
        child: BackgroundArcs(
          color: Color(0xFFEDEFF3),
          stroke: 20,
          gap: 20,
          maxCoverage: 0.50,
          alignment: Alignment.centerLeft,
        ),
      ),
    );
  }
}

class BackgroundArcs extends StatelessWidget {
  const BackgroundArcs({
    super.key,
    this.color = const Color(0xFFE9EDF2),
    this.stroke = 12.0,
    this.gap = 12.0,
    this.maxCoverage = 0.75,
    this.alignment = Alignment.centerLeft,
  });

  final Color color;
  final double stroke;
  final double gap;
  final double maxCoverage;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return CustomPaint(
          size: size,
          painter: _ArcsPainter(
            color: color,
            stroke: stroke,
            gap: gap,
            maxCoverage: maxCoverage,
            alignment: alignment,
          ),
        );
      },
    );
  }
}

class _ArcsPainter extends CustomPainter {
  _ArcsPainter({
    required this.color,
    required this.stroke,
    required this.gap,
    required this.maxCoverage,
    required this.alignment,
  });

  final Color color;
  final double stroke;
  final double gap;
  final double maxCoverage;
  final Alignment alignment;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..isAntiAlias = true
      ..strokeCap = StrokeCap.round;

    final centerY = (alignment.y + 1) / 2 * size.height;
    final center = Offset(0, centerY);
    final maxRadius = size.width * maxCoverage;
    final step = stroke + gap;
    final count = (maxRadius / step).floor();

    for (int i = 0; i < count; i++) {
      final r = maxRadius - i * step;
      if (r <= 0) break;
      final rect = Rect.fromCircle(center: center, radius: r);
      canvas.drawArc(rect, -1.57079632679, 3.14159265359, false, paint); // -90° a 90°
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
