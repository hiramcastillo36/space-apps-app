import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:skai/utils/constans.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const CustomBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
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
          // Item de Home
          _buildNavItem(
            icon: selectedIndex == 0 ? FontAwesomeIcons.solidHouse : FontAwesomeIcons.house,
            label: 'Home',
            index: 0,
          ),
          // Item central de SkAI
          _buildSkaiItem(index: 1),
          // Item de Perfil
          _buildNavItem(
            icon: selectedIndex == 2 ? FontAwesomeIcons.solidUser : FontAwesomeIcons.user,
            label: 'Profile',
            index: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    bool isActive = selectedIndex == index;
    return GestureDetector(
      onTap: () => onItemTapped(index),
      child: Column(
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
      ),
    );
  }

  Widget _buildSkaiItem({required int index}) {
    // El botón central también es clickeable
    return GestureDetector(
      onTap: () => onItemTapped(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade200,
            ),
            child: const Center(
              child: FaIcon(
                FontAwesomeIcons.ring, // Ícono de ejemplo
                color: primaryTextColor,
              ),
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
      ),
    );
  }
}