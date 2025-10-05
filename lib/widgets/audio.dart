import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechToTextExample extends StatefulWidget {
  @override
  _SpeechToTextExampleState createState() => _SpeechToTextExampleState();
}

class _SpeechToTextExampleState extends State<SpeechToTextExample> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _text = "Presiona el botón y habla...";
  double _confidence = 1.0;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
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
              _text = "No se pudo entender el audio. Intenta hablar más claro.";
            } else {
              _text = "Error: ${val.errorMsg}";
            }
          });
        },
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            _text = val.recognizedWords;
            if (val.hasConfidenceRating && val.confidence > 0) {
              _confidence = val.confidence;
            }
          }),
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 5),
          cancelOnError: true,
          listenMode: stt.ListenMode.confirmation,
        );
      } else {
        setState(() {
          _text = "Reconocimiento de voz no disponible";
        });
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Voz a Texto')),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Text(
                _text,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w400),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Text("Confianza: ${(_confidence * 100).toStringAsFixed(1)}%"),
          const SizedBox(height: 10),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _listen,
        child: Icon(_isListening ? Icons.mic : Icons.mic_none),
      ),
    );
  }
}