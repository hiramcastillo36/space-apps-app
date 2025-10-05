import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

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

  @override
  void initState() {
    super.initState();
  }

  void _sendMessage() {
    if (_controller.text.isEmpty) return;

    final userMessage = ChatMessage(text: _controller.text, isUser: true);

    setState(() {
      if (_isInitialState) {
        _messages.clear();
        _isInitialState = false;
      }
      _messages.add(userMessage);
    });

    // Simula la respuesta de SkAI
    _getSkaiResponse(userMessage.text);

    _controller.clear();
    // Espera un poco para que el widget se construya antes de hacer scroll
    Timer(const Duration(milliseconds: 100), _scrollToBottom);
  }

  void _getSkaiResponse(String userInput) {
    // Lógica simple para simular la respuesta del asistente
    String responseText;
    final input = userInput.toLowerCase();

    if (input.contains('soccer') || input.contains('jugar')) {
      responseText =
      "Hey Chino, I wouldn't recommend playing right now, looks like there's a chance of rain around 4 PM in San Luis Potosi. Maybe plan something indoors so you don't get caught in the rain";
    } else if (input.contains('hot') || input.contains('calor')) {
      responseText = "Its very hot";
    } else {
      responseText = "You're welcome Chino :)";
    }

    final skaiMessage = ChatMessage(text: responseText, isUser: false);
    final thanksMessage = ChatMessage(text: "Thanks Oliv", isUser: true);
    final welcomeMessage =
    ChatMessage(text: "You're welcome Chino :)", isUser: false);

    // Añade las respuestas con un pequeño retraso para simular que está "pensando"
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _messages.add(skaiMessage);
      });
      _scrollToBottom();
    });

    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _messages.add(thanksMessage);
      });
      _scrollToBottom();
    });

    Future.delayed(const Duration(seconds: 3), () {
      setState(() {
        _messages.add(welcomeMessage);
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            ),
          ),
          const SizedBox(width: 8.0),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.blue),
            onPressed: _sendMessage,
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

