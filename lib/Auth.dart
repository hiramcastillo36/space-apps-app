import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skai/utils/constans.dart';
import 'package:skai/widgets/navigation_shell.dart';
import 'package:skai/services/auth_service.dart';
import 'package:skai/index.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool _isLoginView = true;

  // Gradiente de marca (mismo que usas en Index/Profile)
  static const LinearGradient _brandGradient = LinearGradient(
    colors: [Color(0xFF5B86E5), Color(0xFF9C27B0), Color(0xFFE91E63)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  void _toggleView(bool isLogin) {
    setState(() {
      _isLoginView = isLogin;
    });
  }

  // Helper para texto con degradado
  Widget _gradientText(String text,
      {double size = 16, FontWeight weight = FontWeight.w600}) {
    return ShaderMask(
      shaderCallback: (bounds) => _brandGradient.createShader(bounds),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(
          fontSize: size,
          fontWeight: weight,
          color: Colors.white, // requerido para que pinte el gradient
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: SafeArea(
        // Fondo de semicírculos como painter, contenido como child
        child: BackgroundArcs(
          color: const Color(0xFFEDEFF3),
          stroke: 20,
          gap: 20,
          maxCoverage: 0.55,
          alignment: Alignment.centerLeft,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                // Título con gradiente
                _gradientText(_isLoginView ? 'Welcome back' : 'Create your account',
                    size: 22, weight: FontWeight.bold),
                const SizedBox(height: 30),
                _buildToggleButtons(),
                const SizedBox(height: 20),
                // Mostrar formulario sin PageView para evitar problemas de altura
                _isLoginView
                    ? const AuthForm(isLogin: true)
                    : const AuthForm(isLogin: false),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Image.asset('assets/images/logoG.png', width: 220, height: 220),
        const SizedBox(height: 8),
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
                  borderRadius: BorderRadius.circular(30),
                  color: Colors.transparent,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: _isLoginView ? _brandGradient : null,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: _isLoginView
                      ? Text('Login',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ))
                      : _gradientText('Login'),
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
                  borderRadius: BorderRadius.circular(30),
                  color: Colors.transparent,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: !_isLoginView ? _brandGradient : null,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: !_isLoginView
                      ? Text('Sign Up',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ))
                      : _gradientText('Sign Up'),
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
class AuthForm extends StatefulWidget {
  final bool isLogin;
  const AuthForm({super.key, required this.isLogin});

  @override
  State<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    // Validaciones
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showError('Please fill all fields');
      return;
    }

    if (!widget.isLogin && _nameController.text.isEmpty) {
      _showError('Name is required');
      return;
    }

    if (!widget.isLogin && _passwordController.text != _confirmPasswordController.text) {
      _showError('Passwords do not match');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = widget.isLogin
          ? await AuthService.login(_emailController.text, _passwordController.text)
          : await AuthService.register(
              _nameController.text,
              _emailController.text,
              _passwordController.text,
            );

      setState(() => _isLoading = false);

      if (result['success']) {
        if (!mounted) return;
        // Navegar a la pantalla principal con NavigationShell
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const NavigationShell()),
        );
      } else {
        _showError(result['error']);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('An error occurred: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // Botón con fondo degradado y texto blanco
  Widget _gradientButton({
    required String label,
    required VoidCallback onTap,
  }) {
    const LinearGradient brandGradient = LinearGradient(
      colors: [Color(0xFF5B86E5), Color(0xFF9C27B0), Color(0xFFE91E63)],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Ink(
          decoration: const BoxDecoration(
            gradient: brandGradient,
            borderRadius: BorderRadius.all(Radius.circular(30)),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            alignment: Alignment.center,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white, // ← texto blanco
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!widget.isLogin) ...[
            _buildTextField(
              controller: _nameController,
              icon: Icons.person_outline,
              hintText: 'Name',
            ),
            const SizedBox(height: 16),
          ],
          _buildTextField(
            controller: _emailController,
            icon: Icons.email_outlined,
            hintText: 'Email',
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _passwordController,
            icon: Icons.lock_outline,
            hintText: 'Password',
            obscureText: true,
          ),
          if (!widget.isLogin) ...[
            const SizedBox(height: 16),
            _buildTextField(
              controller: _confirmPasswordController,
              icon: Icons.lock_outline,
              hintText: 'Confirm Password',
              obscureText: true,
            ),
          ],
          const SizedBox(height: 30),
          Container(
  decoration: BoxDecoration(
    gradient: const LinearGradient(
      colors: [
        Color(0xFF5B86E5),
        Color(0xFF9C27B0),
        Color(0xFFE91E63),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(30),
  ),
  child: ElevatedButton(
    onPressed: _isLoading ? null : _handleSubmit,
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.transparent,
      shadowColor: Colors.transparent,
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
    ),
    child: _isLoading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          )
        : Text(
            widget.isLogin ? 'Login' : 'Create Account',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
  ),
)

        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    required String hintText,
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
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
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(30)),
          borderSide: BorderSide(color: primaryTextColor),
        ),
      ),
    );
  }
}

/// ===== Fondo con semicírculos concéntricos al fondo (reusable con child) =====
class BackgroundArcs extends StatelessWidget {
  const BackgroundArcs({
    super.key,
    this.child,
    this.color = const Color(0xFFE9EDF2),
    this.stroke = 12.0,
    this.gap = 12.0,
    this.maxCoverage = 0.75,
    this.alignment = Alignment.centerLeft,
  });

  final Widget? child;
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
          painter: _ArcsPainter(
            color: color,
            stroke: stroke,
            gap: gap,
            maxCoverage: maxCoverage,
            alignment: alignment,
          ),
          size: size,
          child: child, // El contenido va ENCIMA del fondo pintado
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

    // Centro a la izquierda; alignment.y: -1 arriba, 0 centro, 1 abajo
    final centerY = (alignment.y + 1) / 2 * size.height;
    final center = Offset(0, centerY);

    final maxRadius = size.width * maxCoverage;
    final step = stroke + gap;
    final count = (maxRadius / step).floor();

    for (int i = 0; i < count; i++) {
      final r = maxRadius - i * step;
      if (r <= 0) break;
      final rect = Rect.fromCircle(center: center, radius: r);
      canvas.drawArc(rect, -1.57079632679, 3.14159265359, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
