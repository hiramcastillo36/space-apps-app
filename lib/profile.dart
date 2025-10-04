import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:skai/utils/constans.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 40),
                _buildSectionTitle('Most recent activities'),
                const SizedBox(height: 20),
                _buildActivityGrid([
                  FontAwesomeIcons.personRunning,
                  FontAwesomeIcons.mountain,
                  FontAwesomeIcons.personSwimming,
                  FontAwesomeIcons.personBiking,
                ]),
                const SizedBox(height: 40),
                _buildSectionTitle('My favorite activities'),
                const SizedBox(height: 20),
                _buildActivityGrid([
                  FontAwesomeIcons.personRunning,
                  FontAwesomeIcons.mountain,
                  FontAwesomeIcons.personSwimming,
                  FontAwesomeIcons.personBiking,
                ]),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  // --- Widgets Separados para Claridad ---

  Widget _buildHeader() {
    return Column(
      children: [
        const Icon(
          Icons.person,
          size: 100,
          color: Colors.grey,
        ),
        const SizedBox(height: 16),
        Text(
          'Chino',
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            foreground: Paint()
              ..shader = const LinearGradient(
                colors: <Color>[Color(0xFFCE93D8), Color(0xFF81D4FA)],
              ).createShader(const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0)),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: primaryTextColor,
      ),
    );
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
      itemBuilder: (context, index) {
        return _buildActivityIcon(icons[index]);
      },
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
        child: FaIcon(
          icon,
          size: 28,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    // Este es un duplicado de la barra de navegación de la página de inicio
    // para mantener la consistencia. En una app real, esto sería un widget reutilizable.
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
        Text(
          'SkAI',
          style: GoogleFonts.poppins(
            color: Colors.grey,
            fontSize: 12,
          ),
        )
      ],
    );
  }
}