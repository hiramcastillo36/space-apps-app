import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

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

  // WebSocket
  late WebSocketChannel _channel;
  bool _isConnected = false;
  StreamSubscription? _subscription;

  // Text-to-Speech
  late FlutterTts _flutterTts;
  bool _isSpeaking = false;

  // Speech-to-Text
  late stt.SpeechToText _speech;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _initTts();
    _initSpeech();
    _connectWebSocket();
  }

  void _connectWebSocket() {
    try {
      final wsUrl = 'ws://20.151.177.103:8080/ws/chat/1/';

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

  void _initSpeech() {
    _speech = stt.SpeechToText();
  }

  Future<void> _speak(String text) async {
    if (text.isNotEmpty) {
      await _flutterTts.speak(text);
    }
  }

  Future<void> _stopSpeaking() async {
    await _flutterTts.stop();
  }

  void _sendMessage() {
    if (_controller.text.isEmpty || !_isConnected) return;

    final message = _controller.text;
    final userMessage = ChatMessage(text: message, isUser: true);

    setState(() {
      if (_isInitialState) {
        _messages.clear();
        _isInitialState = false;
      }
      _messages.add(userMessage);
    });

    // Enviar mensaje por WebSocket
    final jsonMessage = json.encode({
      'message': message,
    });
    _channel.sink.add(jsonMessage);

    _controller.clear();
    Timer(const Duration(milliseconds: 100), _scrollToBottom);
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => print('Estado: $val'),
        onError: (val) {
          print('Error: $val');
          setState(() {
            _isListening = false;
            if (val.errorMsg == 'error_no_match') {
              _controller.text = "";
            }
          });
        },
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) {
            setState(() {
              _controller.text = val.recognizedWords;
            });
          },
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 5),
          cancelOnError: true,
          listenMode: stt.ListenMode.confirmation,
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void _scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _isSpeaking ? Icons.volume_up : Icons.volume_off,
              color: Colors.black87,
            ),
            onPressed: _isSpeaking ? _stopSpeaking : null,
            tooltip: _isSpeaking ? 'Detener audio' : 'Silencio',
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _isConnected ? Colors.green : Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.lightBlue.shade100,
              Colors.pink.shade100,
            ],
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 80),
            Expanded(
              child: _isInitialState
                  ? _buildInitialView()
                  : ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16.0),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return _buildChatBubble(message);
                },
              ),
            ),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Colors.blue, Colors.red],
              tileMode: TileMode.mirror,
            ).createShader(bounds),
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
          _buildDecorativeSphere(),
        ],
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: message.isUser ? Colors.transparent : Colors.transparent,
        ),
        child: Text(
          message.text,
          style: GoogleFonts.poppins(
            color: message.isUser ? Colors.pink.shade300 : Colors.black87,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: Colors.transparent,
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              _isListening ? Icons.mic : Icons.mic_none,
              color: _isListening ? Colors.red : Colors.blue,
            ),
            onPressed: _listen,
            tooltip: 'Hablar',
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Ask SkAI something...',
                filled: true,
                fillColor: Colors.white.withOpacity(0.8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
              enabled: _isConnected,
            ),
          ),
          const SizedBox(width: 8.0),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.blue),
            onPressed: _isConnected ? _sendMessage : null,
          ),
        ],
      ),
    );
  }

  Widget _buildDecorativeSphere() {
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Colors.white.withOpacity(0.8),
            Colors.blue.shade100.withOpacity(0.5),
            Colors.pink.shade100.withOpacity(0.5),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 5,
          )
        ],
      ),
    );
  }
}

