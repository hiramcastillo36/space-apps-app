import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:skai/utils/constans.dart';
// ⬇️ Ajusta la ruta/caso del archivo según tu proyecto (recomendado: auth.dart en minúsculas)
import 'package:skai/Auth.dart';
import 'events.dart';
import 'eventsModel.dart';
import 'package:skai/services/user_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _userName = '';
  String _userEmail = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final userInfo = await UserService.getUserInfo();
    if (userInfo['success'] == true && mounted) {
      setState(() {
        _userName = userInfo['name'] ?? '';
        _userEmail = userInfo['email'] ?? '';
        _isLoading = false;
      });
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Gradiente usado en los títulos y ahora en el texto del botón
  static const LinearGradient _titleGradient = LinearGradient(
    colors: [Color(0xFF5B86E5), Color(0xFF9C27B0), Color(0xFFE91E63)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Helper para pintar texto con gradiente
  Widget _gradientTitle(
    String text, {
    double fontSize = 20,
    FontWeight weight = FontWeight.w600,
    TextAlign? align,
  }) {
    return ShaderMask(
      shaderCallback: (bounds) => _titleGradient.createShader(bounds),
      child: Text(
        text,
        textAlign: align,
        style: GoogleFonts.poppins(
          fontSize: fontSize,
          fontWeight: weight,
          color: Colors.white, // requerido para que el Shader pinte el gradiente
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

                    // ⬇️ Botón Cerrar sesión con texto en gradiente
                    _buildLogoutButton(context),
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
        _isLoading
            ? const CircularProgressIndicator()
            : _gradientTitle(_userName.isNotEmpty ? _userName : 'User', fontSize: 28, weight: FontWeight.bold),
        if (_userEmail.isNotEmpty && !_isLoading) ...[
          const SizedBox(height: 8),
          Text(
            _userEmail,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
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

  // ---------- Botón Cerrar sesión ----------
  Widget _buildLogoutButton(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        // Navega a Auth y reemplaza la pantalla actual
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AuthPage()),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
          // Borde suave
          border: Border.all(color: const Color(0xFFE6E8EE)),
        ),
        child: Center(
          child: _gradientTitle(
            'Cerrar sesión',
            fontSize: 18,
            weight: FontWeight.w700,
          ),
        ),
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

final List<Map<String, dynamic>> eventJsonList = [
  {
    "id": 1,
    "user_email": "user@example.com",
    "conversation_title": "Weather Consultation",
    "event_name": "Fiesta de cumpleaños",
    "event_date": "2027-08-29T21:00:00Z",
    "location_name": "Queretaro",
    "latitude": 20.58806,
    "longitude": -100.38806,
    "weather_data": {
      "temperature": "25.3 C",
      "precipitation": "0 mm"
    },
    "temperature": null,
    "precipitation": null,
    "wind_speed": null,
    "created_at": "2025-10-05T04:30:08.853633Z",
    "updated_at": "2025-10-05T04:30:08.853655Z"
  }
];

final List<Evento> sampleEvents =
    eventJsonList.map((json) => Evento.fromJson(json)).toList();

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
      // Semicírculo derecho (abre hacia la derecha)
      canvas.drawArc(rect, -1.57079632679, 3.14159265359, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
