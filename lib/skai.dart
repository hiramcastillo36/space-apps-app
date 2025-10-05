import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:skai/services/auth_service.dart';
import 'package:skai/services/conversation_service.dart';

// Modelo de mensaje
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

class _SkaiPageState extends State<SkaiPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  bool _isInitialState = true;   // estamos en la vista inicial

  // Animación de salida del sphere (intro)
  late final AnimationController _introCtrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;
  bool _isHidingIntro = false;   // para no duplicar animaciones
  String? _pendingFirstMessage;  // texto a enviar tras animación (si fue por Enter)

  // Gradiente de marca (consistente con Index/Profile)
  static const LinearGradient _brandGradient = LinearGradient(
    colors: [Color(0xFF5B86E5), Color(0xFF9C27B0), Color(0xFFE91E63)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // WebSocket
  late WebSocketChannel _channel;
  bool _isConnected = false;
  StreamSubscription? _subscription;
  int? _conversationId;

  // Text-to-Speech
  late FlutterTts _flutterTts;
  bool _isSpeaking = false;

  // Speech-to-Text
  late stt.SpeechToText _speech;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _introCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _scaleAnim = CurvedAnimation(parent: _introCtrl, curve: Curves.easeIn);
    _fadeAnim =
        CurvedAnimation(parent: _introCtrl, curve: Curves.easeInOutCubic);
    _initTts();
    _initSpeech();
    _createNewConversation();
  }

  Future<void> _createNewConversation() async {
    try {
      // Obtener el token de autenticación
      final token = await AuthService.getToken();
      if (token == null) {
        print('No auth token available');
        return;
      }

      // Crear una nueva conversación cada vez que se abre SkAI
      final conversationResult = await ConversationService.createConversation(
        'Chat ${DateTime.now().toString().split('.')[0]}'
      );

      if (!conversationResult['success']) {
        print('Failed to create conversation: ${conversationResult['error']}');
        return;
      }

      _conversationId = ConversationService.getConversationId(conversationResult);
      if (_conversationId == null) {
        print('No conversation ID received');
        return;
      }

      print('New conversation created with ID: $_conversationId');

      // Ahora conectar al WebSocket
      _connectWebSocket();
    } catch (e) {
      print('Error creating conversation: $e');
    }
  }

  void _connectWebSocket() async {
    try {
      if (_conversationId == null) {
        print('No conversation ID available');
        return;
      }

      // Conectar al WebSocket con el ID de conversación
      final wsUrl = 'ws://20.151.177.103:8080/ws/chat/$_conversationId/';

      _channel = WebSocketChannel.connect(
        Uri.parse(wsUrl),
      );

      if (!mounted) return;
      setState(() {
        _isConnected = true;
      });

      _subscription = _channel.stream.listen(
        (message) {
          if (!mounted) return;
          try {
            final data = json.decode(message);
            if (!mounted) return;
            final responseText = data['message'] ?? message.toString();
            setState(() {
              if (_isInitialState) {
                _messages.clear();
                _isInitialState = false;
              }
              _messages.add(ChatMessage(
                text: responseText,
                isUser: false,
              ));
            });
            _speak(responseText);
            Timer(const Duration(milliseconds: 100), _scrollToBottom);
          } catch (e) {
            if (!mounted) return;
            final responseText = message.toString();
            setState(() {
              _messages.add(ChatMessage(
                text: responseText,
                isUser: false,
              ));
            });
            _speak(responseText);
          }
        },
        onError: (error) {
          if (!mounted) return;
          setState(() {
            _isConnected = false;
          });
        },
        onDone: () {
          if (!mounted) return;
          setState(() {
            _isConnected = false;
          });
        },
      );
    } catch (e) {
      print('Error WebSocket: $e');
    }
  }

  void _initTts() {
    _flutterTts = FlutterTts();
    _flutterTts.setLanguage("es-ES");
    _flutterTts.setSpeechRate(0.5);
    _flutterTts.setVolume(1.0);
    _flutterTts.setPitch(1.0);

    _flutterTts.setStartHandler(() {
      if (mounted) {
        setState(() {
          _isSpeaking = true;
        });
      }
    });

    _flutterTts.setCompletionHandler(() {
      if (mounted) {
        setState(() {
          _isSpeaking = false;
        });
      }
    });

    _flutterTts.setErrorHandler((msg) {
      if (mounted) {
        setState(() {
          _isSpeaking = false;
        });
      }
    });
  }

  void _initSpeech() async {
    _speech = stt.SpeechToText();
    await _speech.initialize(
      onError: (error) => print('Speech error: $error'),
      onStatus: (status) => print('Speech status: $status'),
    );
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      // Detener escucha
      await _speech.stop();
      setState(() => _isListening = false);
    } else {
      // Iniciar escucha
      final available = await _speech.initialize();
      if (!available) {
        print('Speech recognition not available');
        return;
      }

      setState(() => _isListening = true);

      await _speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            setState(() {
              _controller.text = result.recognizedWords;
              _isListening = false;
            });
          }
        },
        localeId: 'es_ES', // Español
        cancelOnError: true,
        listenMode: stt.ListenMode.confirmation,
      );
    }
  }

  Future<void> _speak(String text) async {
    if (text.isNotEmpty) {
      await _flutterTts.speak(text);
    }
  }

  Future<void> _stopSpeaking() async {
    await _flutterTts.stop();
  }

  // --- Envío de mensajes ---

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty || !_isConnected) return;

    FocusScope.of(context).unfocus();

    if (_isInitialState) {
      // Si todavía estamos en la intro, primero ocultamos con animación
      _pendingFirstMessage = text;
      _controller.clear();
      _startChatTransition(addPendingAfter: true);
      return;
    }

    // Flujo normal (ya en chat)
    final userMessage = ChatMessage(text: text, isUser: true);
    setState(() {
      _messages.add(userMessage);
    });

    // Enviar mensaje por WebSocket
    final jsonMessage = json.encode({
      'message': text,
    });
    _channel.sink.add(jsonMessage);

    _controller.clear();
    _scrollToBottom();
  }


  // --- Transición de la intro (sphere) al chat ---

  void _startChatTransition({bool addPendingAfter = false}) {
    if (_isHidingIntro) return;
    _isHidingIntro = true;

    _introCtrl.forward().whenCompleteOrCancel(() {
      if (!mounted) return;
      setState(() {
        _isInitialState = false;
      });

      // Si la transición fue gatillada por el primer envío, lo agregamos ahora
      if (addPendingAfter && _pendingFirstMessage != null) {
        final first = _pendingFirstMessage!;
        _pendingFirstMessage = null;

        final userMessage = ChatMessage(text: first, isUser: true);
        setState(() {
          _messages.add(userMessage);
        });

        // Enviar mensaje por WebSocket
        final jsonMessage = json.encode({
          'message': first,
        });
        _channel.sink.add(jsonMessage);
      }

      // Limpia bandera después de terminar
      _isHidingIntro = false;

      // Asegura scroll al final
      _scrollToBottom();
    });
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

  // --- UI ---

  @override
  void dispose() {
    _introCtrl.dispose();
    _flutterTts.stop();
    _speech.stop();
    _subscription?.cancel();
    _channel.sink.close();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // 1) Fondo base (gradiente)
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
            // 2) Semicírculos
            const Positioned.fill(
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
                  // Vista inicial con animación
                  if (_isInitialState) _buildAnimatedIntro(),
                  // Chat visible cuando se sale de la intro
                  if (!_isInitialState) Expanded(child: _buildChatList()),
                  if (!_isInitialState)
                    SafeArea(top: false, child: _buildInputArea()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Intro animada (texto + sphere con Scale+Fade) ---
  Widget _buildAnimatedIntro() {
    return Expanded(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: AnimatedBuilder(
            animation: _introCtrl,
            builder: (context, child) {
              final scale = 1.0 - (_scaleAnim.value * 0.6); // escala 1 → 0.4
              final opacity = 1.0 - _fadeAnim.value;         // opacidad 1 → 0
              return Opacity(
                opacity: opacity.clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: scale.clamp(0.4, 1.0),
                  child: child,
                ),
              );
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) =>
                      _brandGradient.createShader(bounds),
                  child: Text(
                    'What activity\ndo you want\nto do today?',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white, // necesario para el gradiente
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                // Tap en el sphere dispara la transición
                GestureDetector(
                  onTap: () => _startChatTransition(),
                  child: Hero(
                    tag: 'skai-sphere-hero',
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/sphere.gif',
                        width: 250,
                        height: 250,
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                        semanticLabel: 'Animated sphere assistant',
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
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
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return _buildChatBubble(message);
      },
    );
  }

  // --- Burbujas ---
  Widget _buildChatBubble(ChatMessage message) {
    final isUser = message.isUser;

    if (!isUser) {
      // SkAI: GIF + tarjeta (sin Hero para evitar conflictos)
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _skaiGifCircle(size: 44),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
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
                  style: GoogleFonts.poppins(
                    color: Colors.black87,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Usuario
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
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
            style: GoogleFonts.poppins(
              color: Colors.pink.shade400,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  // Sphere como avatar circular
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

  // Input
Widget _buildInputArea() {
  return Padding(
    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
    child: Row(
      children: [
        // Caja de texto
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
              enabled: _isConnected,
            ),
          ),
        ),

        const SizedBox(width: 8),

        // Botón enviar
        InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: _sendMessage,
          child: Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: _brandGradient,
            ),
            child: const Icon(Icons.send, color: Colors.white, size: 22),
          ),
        ),

        const SizedBox(width: 8),

        // Botón micrófono con speech-to-text
        InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: _toggleListening,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: _isListening
                  ? const LinearGradient(
                      colors: [Color(0xFFEF5350), Color(0xFFE91E63)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : _brandGradient,
            ),
            child: Icon(
              _isListening ? Icons.mic : Icons.mic_none,
              color: Colors.white,
              size: 22,
            ),
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
