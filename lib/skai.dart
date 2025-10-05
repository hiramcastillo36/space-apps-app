import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Modelo simple para un mensaje en el chat
class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}

class SkaiPage extends StatefulWidget {
  const SkaiPage({super.key});

  @override
  State<SkaiPage> createState() => _SkaiPageState();
}

class _SkaiPageState extends State<SkaiPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  bool _isInitialState = true;
  bool _isTyping = false;

  // Control de concurrencia para respuestas (evita carreras)
  int _replySession = 0;

  // Gradiente consistente con Index/Profile
  static const LinearGradient _brandGradient = LinearGradient(
    colors: [Color(0xFF5B86E5), Color(0xFF9C27B0), Color(0xFFE91E63)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
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
    final int session = ++_replySession; // token de sesión
    String responseText;
    final input = userInput.toLowerCase();

    if (input.contains('soccer') || input.contains('jugar')) {
      responseText =
          "Hey Chino, I wouldn't recommend playing right now, looks like there's a chance of rain around 4 PM in San Luis Potosi. Maybe plan something indoors so you don't get caught in the rain";
    } else if (input.contains('hot') || input.contains('calor')) {
      responseText = "It’s very hot";
    } else {
      responseText = "You're welcome Chino :)";
    }

    setState(() => _isTyping = true);

    // Simula “pensando…”
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted || session != _replySession) return;
    setState(() {
      _messages.add(ChatMessage(text: responseText, isUser: false));
    });
    _scrollToBottom();

    // Secuencia de “gracias”
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted || session != _replySession) return;
    setState(() {
      _messages.add(ChatMessage(text: "Thanks Oliv", isUser: true));
    });
    _scrollToBottom();

    await Future.delayed(const Duration(seconds: 1));
    if (!mounted || session != _replySession) return;
    setState(() {
      _messages.add(ChatMessage(text: "You're welcome Chino :)", isUser: false));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // 1) Fondo base (gradiente) - ABAJO
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.lightBlue.shade100, Colors.pink.shade100],
                  ),
                ),
              ),
            ),
            // 2) Semicírculos - ARRIBA del gradiente
            Positioned.fill(
              child: IgnorePointer(
                child: BackgroundArcs(
                color: Color(0xFFEDEFF3),
                stroke: 20,
                gap: 20,
                maxCoverage: 0.50,
                alignment: Alignment.centerLeft,
              ),
              ),
            ),
            // 3) Contenido
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
                                // sphere.gif como "typing bubble"
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
                  // Área de entrada
                  SafeArea(top: false, child: _buildInputArea()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- UI secciones ---

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
                  color: Colors.white, // necesario para pintar gradiente
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
    if (!message.isUser) {
      // SkAI: GIF a la izquierda + tarjeta con texto
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

    // Usuario: burbuja a la derecha
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

  // sphere.gif como “burbuja” circular / avatar
  Widget _skaiGifCircle({double size = 56}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: size * 0.06), // aro sutil
      ),
      child: ClipOval(
        child: Image.asset(
          // ⚠️ En Flutter usa ruta relativa de assets (no D:\...). Decláralo en pubspec.yaml
          'assets/images/sphere.gif',
          fit: BoxFit.cover,
          gaplessPlayback: true,
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

/// ===== Fondo con semicírculos concéntricos lado izquierdo (reusable) =====
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
      // Semicírculo derecho
      canvas.drawArc(rect, -1.57079632679, 3.14159265359, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
