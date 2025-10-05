import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
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

// ACTUALIZADO: Enum con todos los temas de clima
enum WeatherTheme { normal, sunny, verySunny, rainy, windy, stormy, snowy, cloudy }

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

  // ACTUALIZADO: Todos los controladores de animación
  late final AnimationController _sunController;
  late final AnimationController _rainController;
  late final AnimationController _windController;
  late final AnimationController _stormController;
  late final AnimationController _snowController;

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

    // ACTUALIZADO: Inicializar todos los controladores de clima
    _sunController = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat();
    _rainController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _windController = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat();
    _snowController = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
    _stormController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));

    _initTts();
    _initSpeech();
    _createNewConversation();
  }

  @override
  void dispose() {
    _introCtrl.dispose();
    _sunController.dispose();
    _rainController.dispose();
    // ACTUALIZADO: Desechar los nuevos controladores
    _windController.dispose();
    _stormController.dispose();
    _snowController.dispose();

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

  // --- Lógica de Conexión y Voz (sin cambios) ---
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
      if (mounted) setState(() => _isSpeaking = true);
    });
    _flutterTts.setCompletionHandler(() {
      if (mounted) setState(() => _isSpeaking = false);
    });
    _flutterTts.setErrorHandler((msg) {
      if (mounted) setState(() => _isSpeaking = false);
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
      if (!available) return;

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
    if (text.isNotEmpty) await _flutterTts.speak(text);
  }

  // --- Lógica de Temas y Mensajes ---

  // ACTUALIZADO: para manejar nuevos moods del backend
  void _setWeatherThemeFromMood(String mood) {
    WeatherTheme newTheme = WeatherTheme.normal; // Default
    switch (mood.toLowerCase()) {
      case 'rainy': newTheme = WeatherTheme.rainy; break;
      case 'sunny': newTheme = WeatherTheme.sunny; break;
      case 'verysunny': case 'very_sunny': newTheme = WeatherTheme.verySunny; break;
      case 'windy': newTheme = WeatherTheme.windy; break;
      case 'stormy': newTheme = WeatherTheme.stormy; break;
      case 'snowy': newTheme = WeatherTheme.snowy; break;
      case 'cold': newTheme = WeatherTheme.cloudy; break;
      case 'snow': newTheme = WeatherTheme.snowy; break;

    // Los moods que no son de clima se mapean a 'normal'
      case 'success':
      case 'loading':
      case 'neutral':
      default:
        newTheme = WeatherTheme.normal; break;
    }
    if (newTheme != _currentTheme) setState(() => _currentTheme = newTheme);
  }

  // ACTUALIZADO: para detectar nuevas palabras clave
  void _detectWeatherTheme(String text) {
    final input = text.toLowerCase();
    WeatherTheme newTheme = _currentTheme;

    // --- 0. Helpers ---
    bool containsAny(List<String> list) => list.any((k) => input.contains(k));

    final negationKeywords = [
      'sin probabilidad',
      'sin probabilidad de',
      'sin precipitación',
      'sin lluvia',
      'no llover',
      'no lloverá',
      'no hay lluvia',
      'no hay precipitación',
      'poca probabilidad',
      'baja probabilidad',
      'sin'
    ];

    bool _hasNegationBefore(String key, {int window = 40}) {
      final idxKey = input.indexOf(key);
      if (idxKey <= 0) return false;
      for (final neg in negationKeywords) {
        final idxNeg = input.indexOf(neg);
        if (idxNeg >= 0 && idxNeg < idxKey && (idxKey - idxNeg) <= window) return true;
      }
      return false;
    }

    // --- 1. Temperature first (autoridad) ---
    final RegExp numberRegex = RegExp(r'(-?\d+(\.\d+)?)');
    final Match? numberMatch = numberRegex.firstMatch(input);
    if (numberMatch != null) {
      final double? temperature = double.tryParse(numberMatch.group(0)!);
      if (temperature != null) {
        if (temperature <= 0) {
          if (_currentTheme != WeatherTheme.snowy) setState(() => _currentTheme = WeatherTheme.snowy);
          return;
        } else if (temperature >= 30) {
          if (_currentTheme != WeatherTheme.verySunny) setState(() => _currentTheme = WeatherTheme.verySunny);
          return;
        } else if (temperature >= 10) {
          if (_currentTheme != WeatherTheme.sunny) setState(() => _currentTheme = WeatherTheme.sunny);
          return;
        } else {
          if (_currentTheme != WeatherTheme.normal) setState(() => _currentTheme = WeatherTheme.normal);
          return;
        }
      }
    }

    // --- 2. Keyword lists ---
    final stormWords = ['tormenta', 'vendaval', 'ráfagas fuertes', 'viento fuerte', '⛈', 'peligro'];
    final windyWords = ['viento fuerte', 'ráfagas', 'viento', 'vendaval'];
    final snowWords = ['nieve', 'snow', 'nevando'];
    final cloudyWords = ['nublado', 'nubes', 'cubierto', 'gris', '☁'];
    final sunnyWords = ['soleado', 'despejado', 'perfecto', 'excelente', 'ideal', '☀', 'sol'];
    final rainWords = ['lluv', 'precip', 'mojado', 'llover', '🌧', 'paraguas'];

    // --- 3. Detección ordenada ---
    if (containsAny(stormWords)) {
      newTheme = WeatherTheme.stormy;
    } else if (containsAny(windyWords)) {
      newTheme = WeatherTheme.windy;
    } else if (containsAny(snowWords)) {
      newTheme = WeatherTheme.snowy;
    } else if (containsAny(cloudyWords)) {
      newTheme = WeatherTheme.cloudy;
    } else if (containsAny(sunnyWords)) {
      newTheme = WeatherTheme.sunny;
    } else {
      // Detect rain but ignore it if there's a nearby negation like "sin probabilidad..."
      for (final r in rainWords) {
        if (input.contains(r) && !_hasNegationBefore(r)) {
          newTheme = WeatherTheme.rainy;
          break;
        }
      }

      if (newTheme == _currentTheme) {
        if (input.contains('sin probabilidad') || input.contains('sin precipitación') || input.contains('sin lluvia')) {
          newTheme = WeatherTheme.snowy;
        }
      }
    }

    if (newTheme != _currentTheme) {
      setState(() => _currentTheme = newTheme);
    }
  }

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
    setState(() => _messages.add(userMessage));

    _channel.sink.add(json.encode({'message': text}));
    _controller.clear();
    _scrollToBottom();
  }

  void _startChatTransition({bool addPendingAfter = false}) {
    if (_isHidingIntro) return;
    _isHidingIntro = true;

    _introCtrl.forward().whenCompleteOrCancel(() {
      if (!mounted) return;
      setState(() => _isInitialState = false);

      if (addPendingAfter && _pendingFirstMessage != null) {
        final first = _pendingFirstMessage!;
        _pendingFirstMessage = null;
        final userMessage = ChatMessage(text: first, isUser: true);
        setState(() => _messages.add(userMessage));
        _channel.sink.add(json.encode({'message': first}));
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

  // ACTUALIZADO: para manejar los nuevos gradientes
  LinearGradient _getCurrentGradient() {
    switch (_currentTheme) {
      case WeatherTheme.sunny: return LinearGradient(colors: [Colors.lightBlue.shade200, Colors.yellow.shade400], begin: Alignment.topLeft, end: Alignment.bottomRight);
      case WeatherTheme.verySunny: return LinearGradient(colors: [Colors.yellow.shade500, Colors.orange.shade700], begin: Alignment.topLeft, end: Alignment.bottomRight);
      case WeatherTheme.rainy: return LinearGradient(colors: [Colors.blueGrey.shade700, Colors.grey.shade500], begin: Alignment.topLeft, end: Alignment.bottomRight);
      case WeatherTheme.windy: return LinearGradient(colors: [Colors.blueGrey.shade200, Colors.lightBlue.shade100], begin: Alignment.topLeft, end: Alignment.bottomRight);
      case WeatherTheme.stormy: return LinearGradient(colors: [Colors.indigo.shade900, Colors.blueGrey.shade800], begin: Alignment.topLeft, end: Alignment.bottomRight);
      case WeatherTheme.snowy: return LinearGradient(colors: [Colors.lightBlue.shade100, Colors.grey.shade300], begin: Alignment.topLeft, end: Alignment.bottomRight);
      case WeatherTheme.cloudy: return LinearGradient(colors: [Colors.blueGrey.shade300, Colors.grey.shade500], begin: Alignment.topLeft, end: Alignment.bottomRight);
      case WeatherTheme.normal: default: return LinearGradient(colors: [Colors.lightBlue.shade100, Colors.pink.shade100], begin: Alignment.topLeft, end: Alignment.bottomRight);
    }
  }

  // --- Widgets de UI (BUILDERS) ---

  // ACTUALIZADO: para mostrar todas las animaciones
  Widget _buildWeatherAnimations() {
    return IgnorePointer(
      child: Stack(
        children: [
          AnimatedOpacity(
            duration: const Duration(milliseconds: 800),
            opacity: (_currentTheme == WeatherTheme.sunny || _currentTheme == WeatherTheme.verySunny) ? 1.0 : 0.0,
            child: _SunWidget(controller: _sunController!, isVerySunny: _currentTheme == WeatherTheme.verySunny),
          ),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 800),
            opacity: (_currentTheme == WeatherTheme.rainy || _currentTheme == WeatherTheme.stormy) ? 1.0 : 0.0,
            child: _RainWidget(controller: _rainController!),
          ),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 800),
            opacity: _currentTheme == WeatherTheme.windy ? 1.0 : 0.0,
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
      ),
    );
  }

  Widget _buildAnimatedIntro() {
    // ... (sin cambios)
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
    // ... (sin cambios)
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
                enabled: _isConnected,
              ),
            ),
          ),
          const SizedBox(width: 8),
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
          InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: _toggleListening,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: _isListening
                    ? const LinearGradient(colors: [Color(0xFFEF5350), Color(0xFFE91E63)])
                    : _brandGradient,
              ),
              child: Icon(_isListening ? Icons.mic : Icons.mic_none, color: Colors.white, size: 22),
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
  bool shouldRepaint(covariant _RainPainter oldDelegate) => animationValue != oldDelegate.animationValue;
}

class _Raindrop {
  final double x;
  final double y;
  final double speed;
  final double length;
  _Raindrop({required this.x, required this.y, required this.speed, required this.length});
}

// --- NUEVOS WIDGETS DE ANIMACIÓN ---

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
    windLines = List.generate(30, (i) => _WindLine());
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
      final horizontalShift = animationValue * size.width * line.speed;

      path.moveTo(0, size.height * line.y + math.sin(horizontalShift / line.frequency) * line.amplitude);

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
  final double amplitude = math.Random().nextDouble() * 20 + 10;
  final double frequency = math.Random().nextDouble() * 50 + 50;
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
    final startX = math.Random().nextDouble() * 0.6 + 0.2;
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
    final flashOpacity = math.sin(animationValue * math.pi);
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