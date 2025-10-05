import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:skai/services/auth_service.dart';
import 'package:skai/services/conversation_service.dart';

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

class _SkaiPageState extends State<SkaiPage> with TickerProviderStateMixin {
  // 1. DECLARACIÓN DE VARIABLES DE ESTADO
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  bool _isInitialState = true;
  WeatherTheme _currentTheme = WeatherTheme.normal;

  // Animación de salida del sphere (intro)
  late final AnimationController _introCtrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;
  bool _isHidingIntro = false;
  String? _pendingFirstMessage;

  // Gradiente de marca
  static const LinearGradient _brandGradient = LinearGradient(
    colors: [Color(0xFF5B86E5), Color(0xFF9C27B0), Color(0xFFE91E63)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Controladores de animación de clima
  late final AnimationController _sunController;
  late final AnimationController _rainController;

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

  // 2. MÉTODOS DE CICLO DE VIDA (initState y dispose)
  @override
  void initState() {
    super.initState();

    // Animación intro
    _introCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _scaleAnim = CurvedAnimation(parent: _introCtrl, curve: Curves.easeIn);
    _fadeAnim = CurvedAnimation(parent: _introCtrl, curve: Curves.easeInOutCubic);

    // Animaciones de clima
    _sunController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _rainController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _initTts();
    _initSpeech();
    _createNewConversation();
  }

  @override
  void dispose() {
    _introCtrl.dispose();
    _sunController.dispose();
    _rainController.dispose();
    _flutterTts.stop();
    _speech.stop();
    _subscription?.cancel();
    _channel.sink.close();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

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
                        ? _buildAnimatedIntro()
                        : _buildChatList(),
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

  // Crear nueva conversación
  Future<void> _createNewConversation() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        print('No auth token available');
        return;
      }

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
            final mood = data['mood'] as String?;

            setState(() {
              if (_isInitialState) {
                _messages.clear();
                _isInitialState = false;
              }
              _messages.add(ChatMessage(
                text: responseText,
                isUser: false,
              ));

              // Detectar tema del clima desde el campo 'mood' o desde el texto
              if (mood != null) {
                _setWeatherThemeFromMood(mood);
              } else {
                _detectWeatherTheme(responseText);
              }
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
              _detectWeatherTheme(responseText);
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
      await _speech.stop();
      setState(() => _isListening = false);
    } else {
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
        localeId: 'es_ES',
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

  // Establecer tema del clima desde el campo 'mood' del backend
  void _setWeatherThemeFromMood(String mood) {
    WeatherTheme newTheme = WeatherTheme.normal;

    switch (mood.toLowerCase()) {
      case 'rainy':
        newTheme = WeatherTheme.rainy;
        break;
      case 'sunny':
        newTheme = WeatherTheme.sunny;
        break;
      case 'verysunny':
      case 'very_sunny':
        newTheme = WeatherTheme.verySunny;
        break;
      case 'normal':
      default:
        newTheme = WeatherTheme.normal;
        break;
    }

    if (newTheme != _currentTheme) {
      _currentTheme = newTheme;
    }
  }

  // Detectar tema del clima desde la respuesta de texto
  void _detectWeatherTheme(String text) {
    final input = text.toLowerCase();
    WeatherTheme newTheme = WeatherTheme.normal;

    if (input.contains('lluvia') || input.contains('rain') || input.contains('precipitación') ||
        input.contains('llovizna')) {
      newTheme = WeatherTheme.rainy;
    } else if (input.contains('35') || input.contains('muy calor') || input.contains('very hot') ||
        input.contains('ultra soleado')) {
      newTheme = WeatherTheme.verySunny;
    } else if (input.contains('sol') || input.contains('sunny') || input.contains('soleado') ||
        input.contains('20') || input.contains('25') || input.contains('30')) {
      newTheme = WeatherTheme.sunny;
    }

    if (newTheme != _currentTheme) {
      _currentTheme = newTheme;
    }
  }

  // 4. MÉTODOS AYUDANTES Y DE LÓGICA
  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty || !_isConnected) return;

    FocusScope.of(context).unfocus();

    if (_isInitialState) {
      _pendingFirstMessage = text;
      _controller.clear();
      _startChatTransition(addPendingAfter: true);
      return;
    }

    final userMessage = ChatMessage(text: text, isUser: true);
    setState(() {
      _messages.add(userMessage);
    });

    final jsonMessage = json.encode({
      'message': text,
    });
    _channel.sink.add(jsonMessage);

    _controller.clear();
    _scrollToBottom();
  }

  void _startChatTransition({bool addPendingAfter = false}) {
    if (_isHidingIntro) return;
    _isHidingIntro = true;

    _introCtrl.forward().whenCompleteOrCancel(() {
      if (!mounted) return;
      setState(() {
        _isInitialState = false;
      });

      if (addPendingAfter && _pendingFirstMessage != null) {
        final first = _pendingFirstMessage!;
        _pendingFirstMessage = null;

        final userMessage = ChatMessage(text: first, isUser: true);
        setState(() {
          _messages.add(userMessage);
        });

        final jsonMessage = json.encode({
          'message': first,
        });
        _channel.sink.add(jsonMessage);
      }

      _isHidingIntro = false;
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
    return IgnorePointer(
      child: Stack(
        children: [
          if (_currentTheme == WeatherTheme.sunny || _currentTheme == WeatherTheme.verySunny)
            _SunWidget(
              controller: _sunController,
              isVerySunny: _currentTheme == WeatherTheme.verySunny,
            ),
          if (_currentTheme == WeatherTheme.rainy)
            _RainWidget(controller: _rainController),
        ],
      ),
    );
  }


  Widget _buildAnimatedIntro() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: AnimatedBuilder(
          animation: _introCtrl,
          builder: (context, child) {
            final scale = 1.0 - (_scaleAnim.value * 0.6);
            final opacity = 1.0 - _fadeAnim.value;
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
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatList() {
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        8 + MediaQuery.of(context).viewInsets.bottom,
      ),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return _buildChatBubble(message);
      },
    );
  }

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
    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: const EdgeInsets.only(top: 40, right: 40),
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