import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// --- Modelos y Enums ---
class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage({required this.text, required this.isUser});
}

// ACTUALIZADO: Nuevos temas de clima
enum WeatherTheme { normal, sunny, verySunny, rainy, windy, stormy, snowy }

// --- Widget Principal ---
class SkaiPage extends StatefulWidget {
  const SkaiPage({super.key});

  @override
  State<SkaiPage> createState() => _SkaiPageState();
}

class _SkaiPageState extends State<SkaiPage> with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  bool _isInitialState = true;
  bool _isTyping = false;
  int _replySession = 0;

  WeatherTheme _currentTheme = WeatherTheme.normal;

  // Controladores de animación
  AnimationController? _sunController;
  AnimationController? _rainController;
  AnimationController? _windController;
  AnimationController? _stormController;
  AnimationController? _snowController;

  static const LinearGradient _brandGradient = LinearGradient(
    colors: [Color(0xFF5B86E5), Color(0xFF9C27B0), Color(0xFFE91E63)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  @override
  void initState() {
    super.initState();
    _sunController = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat();
    _rainController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _windController = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat();
    _snowController = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
    // El controlador de la tormenta es diferente, se dispara, no se repite
    _stormController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _sunController?.dispose();
    _rainController?.dispose();
    _windController?.dispose();
    _stormController?.dispose();
    _snowController?.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    FocusScope.of(context).unfocus();

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

    WeatherTheme newTheme = WeatherTheme.normal;

    if (input.contains('soccer') || input.contains('jugar')) {
      responseText = "No te recomiendo jugar ahora, parece que habrá lluvia cerca de las 4 PM. Mejor planea algo en interiores.";
      newTheme = WeatherTheme.rainy;
    } else if (input.contains('20') || input.contains('soleado')) {
      responseText = "Claro, el clima para hoy es soleado con una temperatura de 20°C.";
      newTheme = WeatherTheme.sunny;
    } else if (input.contains('35') || input.contains('calor')) {
      responseText = "¡Sí, hace mucho calor! La temperatura es de 35°C, un día ultra soleado.";
      newTheme = WeatherTheme.verySunny;
    } else if (input.contains('viento') || input.contains('20km')) {
      responseText = "Hay mucho viento hoy, con ráfagas de más de 20 km/h. ¡Sujeta tu sombrero!";
      newTheme = WeatherTheme.windy;
    } else if (input.contains('tormenta')) {
      responseText = "¡Cuidado! Se pronostica una tormenta eléctrica. Es mejor quedarse en casa.";
      newTheme = WeatherTheme.stormy;
    } else if (input.contains('nieve')) {
      responseText = "¡Qué frío! Está nevando. Perfecto para una bebida caliente.";
      newTheme = WeatherTheme.snowy;
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
      case WeatherTheme.windy:
        return LinearGradient(colors: [Colors.blueGrey.shade200, Colors.lightBlue.shade100], begin: Alignment.topLeft, end: Alignment.bottomRight);
      case WeatherTheme.stormy:
        return LinearGradient(colors: [Colors.indigo.shade900, Colors.blueGrey.shade800], begin: Alignment.topLeft, end: Alignment.bottomRight);
      case WeatherTheme.snowy:
        return LinearGradient(colors: [Colors.lightBlue.shade100, Colors.grey.shade300], begin: Alignment.topLeft, end: Alignment.bottomRight);
      case WeatherTheme.normal:
      default:
        return LinearGradient(colors: [Colors.lightBlue.shade100, Colors.pink.shade100], begin: Alignment.topLeft, end: Alignment.bottomRight);
    }
  }

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

            _buildWeatherAnimations(),

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

  // --- Widgets de UI ---

  Widget _buildWeatherAnimations() {
    return Stack(
      children: [
        AnimatedOpacity(
          duration: const Duration(milliseconds: 800),
          opacity: (_currentTheme == WeatherTheme.sunny || _currentTheme == WeatherTheme.verySunny) ? 1.0 : 0.0,
          child: _SunWidget(
            controller: _sunController!,
            isVerySunny: _currentTheme == WeatherTheme.verySunny,
          ),
        ),
        AnimatedOpacity(
          duration: const Duration(milliseconds: 800),
          opacity: (_currentTheme == WeatherTheme.rainy || _currentTheme == WeatherTheme.stormy) ? 1.0 : 0.0,
          child: _RainWidget(controller: _rainController!),
        ),
        // ACTUALIZADO: Animación de Viento
        AnimatedOpacity(
          duration: const Duration(milliseconds: 800),
          opacity: _currentTheme == WeatherTheme.windy ? 1.0 : 0.0, // Más opaco
          child: _WindWidget(controller: _windController!),
        ),
        AnimatedOpacity(
          duration: const Duration(milliseconds: 800),
          opacity: _currentTheme == WeatherTheme.stormy ? 1.0 : 0.0,
          child: _StormWidget(controller: _stormController!),
        ),
        AnimatedOpacity(
          duration: const Duration(milliseconds: 800),
          opacity: _currentTheme == WeatherTheme.snowy ? 1.0 : 0.0,
          child: _SnowWidget(controller: _snowController!),
        ),
      ],
    );
  }

  Widget _buildInitialView() {
    // ... (sin cambios)
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

  Widget _buildChatBubble(ChatMessage message) {
    // ... (sin cambios)
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
    // ... (sin cambios)
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
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    // ... (sin cambios)
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
              decoration: const BoxDecoration(
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

// --- Widget de Fondo ---
class BackgroundArcs extends StatelessWidget {
  // ... (sin cambios)
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
  // ... (sin cambios)
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

// --- WIDGETS DE ANIMACIÓN ---

class _SunWidget extends StatelessWidget {
  // ... (sin cambios)
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
  // ... (sin cambios)
  final AnimationController controller;
  const _RainWidget({required this.controller});

  @override
  State<_RainWidget> createState() => _RainWidgetState();
}

class _RainWidgetState extends State<_RainWidget> {
  // ... (sin cambios)
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
  // ... (sin cambios)
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
  // ... (sin cambios)
  final double x;
  final double y;
  final double speed;
  final double length;
  _Raindrop({required this.x, required this.y, required this.speed, required this.length});
}

// ACTUALIZADO: Animación de Viento
class _WindWidget extends StatefulWidget {
  final AnimationController controller;
  const _WindWidget({required this.controller});

  @override
  State<_WindWidget> createState() => _WindWidgetState();
}

class _WindWidgetState extends State<_WindWidget> {
  late final List<_WindLine> windLines;

  @override
  void initState() {
    super.initState();
    windLines = List.generate(30, (i) => _WindLine()); // Más líneas
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: _WindPainter(windLines, widget.controller.value),
        );
      },
    );
  }
}

class _WindPainter extends CustomPainter {
  final List<_WindLine> lines;
  final double animationValue;
  _WindPainter(this.lines, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (var line in lines) {
      final path = Path();
      // El desplazamiento horizontal ahora mueve toda la onda
      final horizontalShift = animationValue * size.width * line.speed;

      // Empezar a dibujar desde la izquierda
      path.moveTo(0, size.height * line.y + math.sin(horizontalShift / line.frequency) * line.amplitude);

      // Dibujar la onda a lo largo de toda la pantalla
      for (double x = 1; x <= size.width; x++) {
        final y = size.height * line.y +
            math.sin((x + horizontalShift) / line.frequency) * line.amplitude;
        path.lineTo(x, y);
      }

      paint.color = Colors.white.withOpacity(line.opacity);
      paint.strokeWidth = line.stroke;
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _WindLine {
  final double y = math.Random().nextDouble();
  final double speed = math.Random().nextDouble() * 0.2 + 0.1;
  final double amplitude = math.Random().nextDouble() * 10 + 10;
  final double frequency = math.Random().nextDouble() * 30 + 50;
  final double stroke = math.Random().nextDouble() * 1.5 + 1;
  final double opacity = math.Random().nextDouble() * 0.5 + 0.2;
}

class _StormWidget extends StatefulWidget {
  final AnimationController controller;
  const _StormWidget({required this.controller});

  @override
  State<_StormWidget> createState() => _StormWidgetState();
}

class _StormWidgetState extends State<_StormWidget> {
  Timer? _timer;
  Path? _lightningPath;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        _createLightningPath();
        widget.controller.forward(from: 0.0);
      }
    });
  }

  void _createLightningPath() {
    final path = Path();
    final startX = math.Random().nextDouble() * 0.6 + 0.2; // Centered
    path.moveTo(startX, 0);

    double currentY = 0;
    while (currentY < 1.0) {
      double nextX = startX + (math.Random().nextDouble() - 0.5) * 0.2;
      double nextY = currentY + math.Random().nextDouble() * 0.2;
      path.lineTo(nextX, nextY);
      currentY = nextY;
    }
    setState(() => _lightningPath = path);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: _LightningPainter(widget.controller.value, _lightningPath),
        );
      },
    );
  }
}

class _LightningPainter extends CustomPainter {
  final double animationValue;
  final Path? path;
  _LightningPainter(this.animationValue, this.path);

  @override
  void paint(Canvas canvas, Size size) {
    if (path == null || animationValue == 0) return;

    final flashOpacity = math.sin(animationValue * math.pi); // Fade in and out

    final paint = Paint()
      ..color = Colors.yellow.withOpacity(flashOpacity * 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final Path scaledPath = path!.transform(Matrix4.diagonal3Values(size.width, size.height, 1.0).storage);
    canvas.drawPath(scaledPath, paint);

    final glowPaint = Paint()
      ..color = Colors.white.withOpacity(flashOpacity * 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), glowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _SnowWidget extends StatefulWidget {
  final AnimationController controller;
  const _SnowWidget({required this.controller});

  @override
  State<_SnowWidget> createState() => _SnowWidgetState();
}

class _SnowWidgetState extends State<_SnowWidget> {
  late final List<_Snowflake> snowflakes;

  @override
  void initState() {
    super.initState();
    snowflakes = List.generate(150, (i) => _Snowflake());
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: _SnowPainter(snowflakes, widget.controller.value),
        );
      },
    );
  }
}

class _SnowPainter extends CustomPainter {
  final List<_Snowflake> flakes;
  final double animationValue;
  _SnowPainter(this.flakes, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;

    for (var flake in flakes) {
      final y = (flake.y + animationValue * flake.speed) % 1.0;
      final x = flake.x + math.sin(animationValue * math.pi * 2 + flake.y) * 0.1;
      paint.color = Colors.white.withOpacity(flake.opacity);
      canvas.drawCircle(Offset(x * size.width, y * size.height), flake.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _Snowflake {
  final double x = math.Random().nextDouble();
  final double y = math.Random().nextDouble();
  final double radius = math.Random().nextDouble() * 2 + 1.5;
  final double speed = math.Random().nextDouble() * 0.1 + 0.05;
  final double opacity = math.Random().nextDouble() * 0.7 + 0.3;
}