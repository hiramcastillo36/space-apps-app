import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:skai/utils/constans.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  // Un PageController para manejar la transición entre Login y Registro
  final PageController _pageController = PageController();
  bool _isLoginView = true;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _toggleView(bool isLogin) {
    setState(() {
      _isLoginView = isLogin;
    });
    _pageController.animateToPage(
      isLogin ? 0 : 1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 40),
              _buildToggleButtons(),
              const SizedBox(height: 20),
              SizedBox(
                height: 350, // Altura fija para el PageView
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _isLoginView = index == 0;
                    });
                  },
                  children: const [
                    AuthForm(isLogin: true),
                    AuthForm(isLogin: false),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const FaIcon(FontAwesomeIcons.rocket, size: 60, color: primaryTextColor),
        const SizedBox(height: 20),
        Text(
          'Welcome to SKAI',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: primaryCardColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Your personal activity companion',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildToggleButtons() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _toggleView(true),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _isLoginView ? primaryTextColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  'Login',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: _isLoginView ? Colors.white : Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _toggleView(false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !_isLoginView ? primaryTextColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  'Sign Up',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: !_isLoginView ? Colors.white : Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Widget de formulario reutilizable para Login y Registro
class AuthForm extends StatelessWidget {
  final bool isLogin;
  const AuthForm({super.key, required this.isLogin});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTextField(icon: Icons.email_outlined, hintText: 'Email'),
          const SizedBox(height: 16),
          _buildTextField(icon: Icons.lock_outline, hintText: 'Password', obscureText: true),
          if (!isLogin) ...[
            const SizedBox(height: 16),
            _buildTextField(icon: Icons.lock_outline, hintText: 'Confirm Password', obscureText: true),
          ],
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement login/signup logic
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryCardColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Text(
              isLogin ? 'Login' : 'Create Account',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({required IconData icon, required String hintText, bool obscureText = false}) {
    return TextField(
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.poppins(color: Colors.grey),
        prefixIcon: Icon(icon, color: Colors.grey),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: primaryTextColor),
        ),
      ),
    );
  }
}
