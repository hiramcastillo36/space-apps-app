import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skai/utils/constans.dart';
import 'package:skai/chat_screen.dart';

class Index extends StatelessWidget {
  const Index({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 30),
                _buildAskOlivCard(context),
                const SizedBox(height: 30),
                _buildSectionTitle('Popular activities'),
                const SizedBox(height: 20),
                _buildPopularActivitiesGrid(),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
      //bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  // ---------------- Header con degradado en ambas líneas ----------------
  Widget _buildHeader() {
    const gradient = LinearGradient(
      colors: [
        Color(0xFF5B86E5), // azul
        Color(0xFF9C27B0), // violeta
        Color(0xFFE91E63), // rosa
      ],
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
              color: Colors.white, // necesario para que el Shader pinte el gradiente
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
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ChatScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: primaryCardColor,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Ask Oliv',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                gradient: const LinearGradient(
                  colors: [Color(0xFFE1BEE7), Color(0xFFBBDEFB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Helper: círculo con aro blanco + (opcional) gradiente suave + GIF animado dentro
  ///
  /// [size]         Tamaño total del círculo (externo).
  /// [ringWidthPx]  Grosor del aro blanco (en px). Si es null, se calcula proporcionalmente.
  /// [gapPx]        Separación interna entre aro y GIF (en px). Menos gap => GIF más grande.
  Widget _olivGifCircle({
    double size = 110,
    double? ringWidthPx,
    double? gapPx,
  }) {
    final borderW  = ringWidthPx ?? size * 0.055; // más delgado que antes
    final innerPad = gapPx ?? size * 0.05;        // menos espacio => GIF más grande
    final glow     = size * 0.07;

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
            errorBuilder: (context, error, stackTrace) {
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  // ---------------- Sección: título con degradado ----------------
  Widget _buildSectionTitle(String title) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [Color(0xFFAB47BC), Color(0xFF42A5F5)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(bounds),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  // ---------------- Grid de actividades ----------------
  Widget _buildPopularActivitiesGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        _buildActivityCard(FontAwesomeIcons.personRunning, 'Running'),
        _buildActivityCard(FontAwesomeIcons.mountain, 'Climbing'),
        _buildActivityCard(FontAwesomeIcons.personSwimming, 'Surfing'),
        _buildActivityCard(FontAwesomeIcons.ellipsis, 'More'),
      ],
    );
  }

  Widget _buildActivityCard(IconData icon, String label) {
    return Container(
      decoration: BoxDecoration(
        color: cardBackgroundColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FaIcon(icon, size: 30, color: Colors.grey[700]),
          const SizedBox(height: 12),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- Bottom bar ----------------
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
          _buildNavItem(Icons.home, 'Home', true),
          _buildOlivItem(),
          _buildNavItem(Icons.person_outline, 'Profile', false),
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

  Widget _buildOlivItem() {
    return Container(
      width: 60,
      height: 60,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: FaIcon(
          FontAwesomeIcons.ring,
          color: primaryTextColor,
        ),
      ),
    );
  }
}
