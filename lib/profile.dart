import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:skai/utils/constans.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  static const LinearGradient _titleGradient = LinearGradient(
    colors: [
      Color(0xFF5B86E5),
      Color(0xFF9C27B0),
      Color(0xFFE91E63),
    ],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  Widget _gradientTitle(
    String text, {
    double fontSize = 20,
    FontWeight weight = FontWeight.w600,
  }) {
    return ShaderMask(
      shaderCallback: (bounds) => _titleGradient.createShader(bounds),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: fontSize,
          fontWeight: weight,
          color: Colors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned.fill(
              child: BackgroundArcs(
                color: Color(0xFFEDEFF3),
                stroke: 20,
                gap: 20,
                maxCoverage: 0.50,
                alignment: Alignment.centerLeft,
              ),
            ),
            // Contenido
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: _buildHeader()),
                    const SizedBox(height: 40),
                    _buildSectionTitle('Most recent activities'),
                    const SizedBox(height: 20),
                    _buildActivityGrid(const [
                      FontAwesomeIcons.personRunning,
                      FontAwesomeIcons.mountain,
                      FontAwesomeIcons.personSwimming,
                      FontAwesomeIcons.personBiking,
                    ]),
                    const SizedBox(height: 40),
                    _buildSectionTitle('My favorite activities'),
                    const SizedBox(height: 20),
                    _buildActivityGrid(const [
                      FontAwesomeIcons.personRunning,
                      FontAwesomeIcons.mountain,
                      FontAwesomeIcons.personSwimming,
                      FontAwesomeIcons.personBiking,
                    ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Widgets ---

  Widget _buildHeader() {
    return Column(
      children: [
        const Icon(Icons.person, size: 100, color: Colors.grey),
        const SizedBox(height: 16),
        _gradientTitle('Chino', fontSize: 28, weight: FontWeight.bold),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return _gradientTitle(title, fontSize: 18, weight: FontWeight.w600);
  }

  Widget _buildActivityGrid(List<IconData> icons) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: icons.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) => _buildActivityIcon(icons[index]),
    );
  }

  Widget _buildActivityIcon(IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: cardBackgroundColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Center(
        child: FaIcon(icon, size: 28, color: Colors.grey[700]),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 5,
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.home_outlined, 'Home', false),
          _buildSkaiItem(),
          _buildNavItem(Icons.person, 'Profile', true),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: isActive ? primaryTextColor : Colors.grey, size: 28),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: isActive ? primaryTextColor : Colors.grey,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            fontSize: 12,
          ),
        )
      ],
    );
  }

  Widget _buildSkaiItem() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey.shade200,
          ),
        ),
        const SizedBox(height: 4),
        Text('SkAI', style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}

/// Fondo con semicírculos concéntricos en el lado izquierdo.
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
      // Semicírculo derecho (abre hacia la derecha): -90° a 90°
      canvas.drawArc(rect, -1.57079632679, 3.14159265359, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
