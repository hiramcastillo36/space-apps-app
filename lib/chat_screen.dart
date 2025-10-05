import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];
  late WebSocketChannel _channel;
  bool _isConnected = false;
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
  }

  String _getHost() {
    if (kIsWeb) return 'localhost';
    // Para Android emulador usa 10.0.2.2, para iOS/otros usa localhost
    // Por ahora siempre usar 10.0.2.2 ya que estás en emulador Android
    return '10.0.2.2';
  }

  void _connectWebSocket() {
    try {
      final host = _getHost();
      final wsUrl = 'ws://$host:8080/ws/chat/70/';

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
            setState(() {
              _messages.add(ChatMessage(
                text: data['message'] ?? message.toString(),
                isMe: false,
              ));
            });
          } catch (e) {
            if (!mounted) return;
            setState(() {
              _messages.add(ChatMessage(
                text: message.toString(),
                isMe: false,
              ));
            });
          }
        },
        onError: (error) {
          if (!mounted) return;
          setState(() {
            _isConnected = false;
          });
          _showError('Error de conexión: $error');
        },
        onDone: () {
          if (!mounted) return;
          setState(() {
            _isConnected = false;
          });
        },
      );
    } catch (e) {
      _showError('No se pudo conectar al WebSocket: $e');
    }
  }

  void _sendMessage() {
    if (_controller.text.isNotEmpty && _isConnected) {
      final message = _controller.text;

      // Enviar como JSON
      final jsonMessage = json.encode({
        'message': message,
      });
      _channel.sink.add(jsonMessage);

      setState(() {
        _messages.add(ChatMessage(
          text: message,
          isMe: true,
        ));
      });

      _controller.clear();
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _channel.sink.close();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        actions: [
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
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[_messages.length - 1 - index];
                return ChatBubble(message: message);
              },
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  offset: const Offset(0, -2),
                  blurRadius: 4,
                  color: Colors.black.withOpacity(0.1),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: 'Escribe un mensaje...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                        enabled: _isConnected,
                      ),
                    ),
                    const SizedBox(width: 8),
                    FloatingActionButton(
                      onPressed: _isConnected ? _sendMessage : null,
                      child: const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isMe;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isMe,
  }) : timestamp = DateTime.now();
}

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Align(
        alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.7,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: message.isMe
                ? Theme.of(context).primaryColor
                : Colors.grey[300],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            message.text,
            style: TextStyle(
              color: message.isMe ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}
