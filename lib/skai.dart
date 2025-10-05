import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Modelo de mensaje
// --- Modelos y Enums ---
class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage({required this.text, required this.isUser});
}

enum WeatherTheme { normal, sunny, verySunny, rainy }

// --- Widget Principal ---
class SkaiPage extends StatefulWidget {
  const SkaiPage({super.key});

  @override
  State<SkaiPage> createState() => _SkaiPageState();
}

class _SkaiPageState extends State<SkaiPage>
    with SingleTickerProviderStateMixin {
class _SkaiPageState extends State<SkaiPage> with TickerProviderStateMixin {
  // 1. DECLARACIÓN DE VARIABLES DE ESTADO
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final LinearGradient _brandGradient = LinearGradient(
    colors: [Colors.pink.shade300, Colors.purple.shade400],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  bool _isInitialState = true;
  bool _isTyping = false;
  int _replySession = 0;
  WeatherTheme _currentTheme = WeatherTheme.normal;

  // Controladores de animación declarados como 'late'
  late final AnimationController _sunController;
  late final AnimationController _rainController;

  // 2. MÉTODOS DE CICLO DE VIDA (initState y dispose)
  @override
  void initState() {
    super.initState();
    // Inicialización de los controladores de animación
    _sunController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _rainController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _messages.add(
      ChatMessage(
        text: "Hola! Soy SkAI, tu asistente de actividades. ¿Qué te gustaría hacer hoy?",
        isUser: false,
      ),
    );
  }

  @override
  void dispose() {
    // Desechar todos los controladores
    _controller.dispose();
    _scrollController.dispose();
    _sunController.dispose();
    _rainController.dispose();
    super.dispose();
  }

  // --- Envío de mensajes ---

  // 3. MÉTODO BUILD
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedContainer(
                duration: const Duration(seconds: 1),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  gradient: _getCurrentGradient(),
                ),
              ),
            ),
            _buildWeatherAnimations(), // Animaciones de clima
            Positioned.fill(
              child: IgnorePointer(
                child: BackgroundArcs(
                  color: const Color(0xFFEDEFF3).withOpacity(0.5),
                  stroke: 20,
                  gap: 20,
                  maxCoverage: 0.50,
                  alignment: Alignment.centerLeft,
                ),
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => FocusScope.of(context).unfocus(),
              child: Column(
                children: [
                  Expanded(
                    child: _isInitialState
                        ? _buildInitialView()
                        : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      itemCount: _messages.length + (_isTyping ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (_isTyping && index == _messages.length) {
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8.0, horizontal: 4.0),
                              child: _skaiGifCircle(size: 56),
                            ),
                          );
                        }
                        final message = _messages[index];
                        return _buildChatBubble(message);
                      },
                    ),
                  ),
                  SafeArea(top: false, child: _buildInputArea()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 4. MÉTODOS AYUDANTES Y DE LÓGICA
  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final userMessage = ChatMessage(text: text, isUser: true);
    setState(() {
      if (_isInitialState) {
        _messages.clear();
        _isInitialState = false;
      }
      _messages.add(userMessage);
    });

    _controller.clear();
    _getSkaiResponse(userMessage.text);
    _scrollToBottom();
  }

  Future<void> _getSkaiResponse(String userInput) async {
    final int session = ++_replySession;
    String responseText;
    final input = userInput.toLowerCase();

    WeatherTheme newTheme = _currentTheme;

    if (input.contains('soccer') || input.contains('jugar')) {
      responseText =
      "No te recomiendo jugar ahora, parece que habrá lluvia cerca de las 4 PM. Mejor planea algo en interiores.";
      newTheme = WeatherTheme.rainy;
    } else if (input.contains('20') || input.contains('soleado')) {
      responseText = "Claro, el clima para hoy es soleado con una temperatura de 20°C.";
      newTheme = WeatherTheme.sunny;
    } else if (input.contains('35') || input.contains('calor')) {
      responseText = "¡Sí, hace mucho calor! La temperatura es de 35°C, un día ultra soleado.";
      newTheme = WeatherTheme.verySunny;
    } else {
      responseText = "¡Claro! ¿En qué más te puedo ayudar?";
      newTheme = WeatherTheme.normal;
    }

    setState(() => _isTyping = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted || session != _replySession) return;

    setState(() {
      _messages.add(ChatMessage(text: responseText, isUser: false));
      _currentTheme = newTheme;
      _isTyping = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  LinearGradient _getCurrentGradient() {
    switch (_currentTheme) {
      case WeatherTheme.sunny:
        return LinearGradient(colors: [Colors.lightBlue.shade200, Colors.yellow.shade400], begin: Alignment.topLeft, end: Alignment.bottomRight);
      case WeatherTheme.verySunny:
        return LinearGradient(colors: [Colors.yellow.shade500, Colors.orange.shade700], begin: Alignment.topLeft, end: Alignment.bottomRight);
      case WeatherTheme.rainy:
        return LinearGradient(colors: [Colors.blueGrey.shade700, Colors.grey.shade500], begin: Alignment.topLeft, end: Alignment.bottomRight);
      case WeatherTheme.normal:
      default:
        return LinearGradient(colors: [Colors.lightBlue.shade100, Colors.pink.shade100], begin: Alignment.topLeft, end: Alignment.bottomRight);
    }
  }



  // 5. WIDGETS DE UI (BUILDERS)
  Widget _buildWeatherAnimations() {
    return Stack(
      children: [
        AnimatedOpacity(
          duration: const Duration(milliseconds: 800),
          opacity: (_currentTheme == WeatherTheme.sunny || _currentTheme == WeatherTheme.verySunny) ? 1.0 : 0.0,
          child: _SunWidget(
            controller: _sunController, // SIN '!'
            isVerySunny: _currentTheme == WeatherTheme.verySunny,
          ),
        ),
        AnimatedOpacity(
          duration: const Duration(milliseconds: 800),
          opacity: _currentTheme == WeatherTheme.rainy ? 1.0 : 0.0,
          child: _RainWidget(controller: _rainController), // SIN '!'
        ),
      ],
    );
  }


  Widget _buildInitialView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ShaderMask(
              shaderCallback: (bounds) => _brandGradient.createShader(bounds),
              child: Text(
                'What activity\ndo you want\nto do today?',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 40),
            Image.asset('assets/images/sphere.gif',
                width: 250, height: 250, fit: BoxFit.cover, gaplessPlayback: true,
                errorBuilder: (_, __, ___) => const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }

  // --- Lista de chat ---
  Widget _buildChatList() {
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        8 + MediaQuery.of(context).viewInsets.bottom, // evita que lo tape el teclado
      ),
      itemCount: _messages.length + (_isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (_isTyping && index == _messages.length) {
          // “Typing” con sphere pequeño
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
            child: Row(
              children: [
                _skaiGifCircle(size: 40),
                const SizedBox(width: 10),
                Expanded(
                  child: Opacity(
                    opacity: 0.7,
                    child: Container(
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        final message = _messages[index];
        return _buildChatBubble(message);
      },
    );
  }

  // --- Burbujas ---
  Widget _buildChatBubble(ChatMessage message) {
    if (!message.isUser) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _skaiGifCircle(size: 44),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 6.0),
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Text(
                message.text,
                style: GoogleFonts.poppins(color: Colors.black87, fontSize: 16),
              ),
            ),
          ),
        ],
      );
    }

    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6.0),
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.85),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Text(
          message.text,
          style: GoogleFonts.poppins(color: Colors.pink.shade400, fontSize: 16),
        ),
      ),
    );
  }

  Widget _skaiGifCircle({double size = 56}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: size * 0.06),
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/images/sphere.gif',
          fit: BoxFit.cover,
          gaplessPlayback: true,
          semanticLabel: 'Animated sphere assistant',
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: 'Ask SkAI something...',
                hintStyle: GoogleFonts.poppins(color: Colors.black45),
                filled: true,
                fillColor: Colors.white.withOpacity(0.9),
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide(color: Colors.black12.withOpacity(0.05)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide(color: Colors.black12.withOpacity(0.05)),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(30.0)),
                  borderSide: BorderSide(color: Color(0xFF9C27B0), width: 1.2),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8.0),
          InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration:  BoxDecoration(
                shape: BoxShape.circle,
                gradient: _brandGradient,
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Widget de Fondo (sin cambios) ---
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
      canvas.drawArc(rect, -1.57079632679, 3.14159265359, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// --- NUEVOS WIDGETS DE ANIMACIÓN ---

class _SunWidget extends StatelessWidget {
  final AnimationController controller;
  final bool isVerySunny;

  const _SunWidget({required this.controller, required this.isVerySunny});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 40,
      right: 40,
      child: RotationTransition(
        turns: controller,
        child: Icon(
          Icons.wb_sunny_rounded,
          color: isVerySunny ? Colors.orangeAccent.shade400.withOpacity(0.8) : Colors.yellow.shade600.withOpacity(0.8),
          size: isVerySunny ? 120 : 100,
          shadows: [
            BoxShadow(
              color: isVerySunny ? Colors.orange.withOpacity(0.5) : Colors.yellow.withOpacity(0.5),
              blurRadius: 30,
              spreadRadius: 10,
            )
          ],
        ),
      ),
    );
  }
}

class _RainWidget extends StatefulWidget {
  final AnimationController controller;
  const _RainWidget({required this.controller});

  @override
  State<_RainWidget> createState() => _RainWidgetState();
}

class _RainWidgetState extends State<_RainWidget> {
  late final List<_Raindrop> raindrops;

  @override
  void initState() {
    super.initState();
    raindrops = List.generate(
      100,
          (index) => _Raindrop(
        x: math.Random().nextDouble(),
        y: math.Random().nextDouble(),
        speed: math.Random().nextDouble() * 0.4 + 0.2,
        length: math.Random().nextDouble() * 15 + 10,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: _RainPainter(
            raindrops: raindrops,
            animationValue: widget.controller.value,
          ),
        );
      },
    );
  }
}

class _RainPainter extends CustomPainter {
  final List<_Raindrop> raindrops;
  final double animationValue;

  _RainPainter({required this.raindrops, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    for (var drop in raindrops) {
      final startY = (drop.y + animationValue * drop.speed) % 1.0;
      final p1 = Offset(drop.x * size.width, startY * size.height);
      final p2 = Offset(drop.x * size.width, (startY * size.height) + drop.length);
      canvas.drawLine(p1, p2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RainPainter oldDelegate) {
    return animationValue != oldDelegate.animationValue;
  }
}

class _Raindrop {
  final double x;
  final double y;
  final double speed;
  final double length;
  _Raindrop({required this.x, required this.y, required this.speed, required this.length});
}