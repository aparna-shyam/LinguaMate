import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_tts/flutter_tts.dart';

void main() {
  runApp(const LinguaMateApp());
}

class LinguaMateApp extends StatelessWidget {
  const LinguaMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LinguaMate',
      debugShowCheckedModeBanner: false, // 🚫 Removed debug banner
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      home: const ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final FlutterTts flutterTts = FlutterTts();
  final List<_ChatMessage> _messages = [];
  bool _isLoading = false;

  Future<void> sendMessage() async {
    final userInput = _controller.text.trim();
    if (userInput.isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(text: userInput, isUser: true));
      _isLoading = true;
    });
    _controller.clear();

    try {
      const String backendUrl = "http://10.0.2.2:8000/correct"; // Update if needed

      final response = await http.post(
        Uri.parse(backendUrl),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "message": userInput,
          "language": "Spanish", // Change to dynamic later
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        String corrected = data['corrected'];
        String explanation = data['explanation'];
        String suggestion = data['suggestion'];

        String aiResponse =
            "✅ Corrected: $corrected\n📖 Explanation: $explanation\n💡 Suggestion: $suggestion";

        setState(() {
          _messages.add(_ChatMessage(text: aiResponse, isUser: false));
        });

        await flutterTts.setLanguage("es-ES");
        await flutterTts.speak(corrected);
      } else {
        setState(() {
          _messages.add(_ChatMessage(
              text: "❌ Error: ${response.statusCode}", isUser: false));
        });
      }
    } catch (e) {
      setState(() {
        _messages.add(_ChatMessage(
            text: "⚠️ Network error: $e", isUser: false));
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildMessage(_ChatMessage message) {
    return Align(
      alignment:
          message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 300),
        decoration: BoxDecoration(
          color: message.isUser ? Colors.deepPurple[100] : Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor:
                  message.isUser ? Colors.deepPurple : Colors.purpleAccent,
              child: Text(
                message.isUser ? '🧑‍💻' : '🤖',
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message.text,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LinguaMate'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple, // 🟣 AppBar solid color
      ),
      body: Container(
        color: const Color(0xFFE6E6FA), // 💜 Light lavender solid background
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                reverse: true,
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return _buildMessage(
                      _messages[_messages.length - 1 - index]);
                },
              ),
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        labelText: 'Type your sentence...',
                        border: OutlineInputBorder(),
                        fillColor: Colors.white,
                        filled: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send),
                    color: Colors.deepPurple,
                    onPressed: _isLoading ? null : sendMessage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ✅ Chat message class
class _ChatMessage {
  final String text;
  final bool isUser;

  _ChatMessage({required this.text, required this.isUser});
}

