// main.dart

import 'package:flutter/material.dart';
import 'package:text_to_speech/text_to_speech.dart';
import 'api_service.dart';

void main() {
  runApp(const LinguamateApp());
}

class LinguamateApp extends StatelessWidget {
  const LinguamateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Linguamate',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily:
            'Roboto', // Using a common font, you can change this in pubspec.yaml
      ),
      home: const WelcomePage(),
    );
  }
}

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  _WelcomePageState createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  // A variable to hold the currently selected language
  String? _selectedLanguage;

  // A list of language options for the dropdown
  final List<String> _languages = [
    'English',
    'Spanish',
    'French',
    'German',
    'Japanese',
  ];

  @override
  Widget build(BuildContext context) {
    // The Scaffold provides a basic structure for the page
    return Scaffold(
      body: Container(
        // Use a DecorationImage to set the background
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/template.jpg'),
            fit: BoxFit.cover,
            // You can add a color filter to make text more readable
            colorFilter: ColorFilter.mode(
              Colors.black54, // Adjust opacity as needed
              BlendMode.darken,
            ),
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                // App Icon/Logo - using a simple icon for now
                const Icon(
                  Icons.translate,
                  size: 80,
                  color: Colors.white, // Changed color for better contrast
                ),
                const SizedBox(height: 24),

                // Welcome Text
                const Text(
                  'Welcome to LinguaMate!',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // Changed color for better contrast
                  ),
                  textAlign: TextAlign.center,
                ),
                // Separate subheading text into a new widget
                const SizedBox(height: 16),
                const Text(
                  'Ready to embark on a journey of language discovery?',
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const Text(
                  'Please select a language to begin.',
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // Language Selection Dropdown
                Container(
                  width: 300,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      hint: const Text('Select a language'),
                      value: _selectedLanguage,
                      items: _languages.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedLanguage = newValue;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 48),

                // Start Learning Button
                SizedBox(
                  width: 300,
                  child: ElevatedButton(
                    onPressed: _selectedLanguage == null
                        ? null // The button is disabled if no language is selected
                        : () {
                            // Display the snackbar
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Starting your journey in $_selectedLanguage!',
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                            // Navigate to the chat page and pass the selected language
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ChatPage(language: _selectedLanguage!),
                              ),
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 0, 0, 0),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 5,
                    ),
                    child: const Text(
                      'Start Learning',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
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
}

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}

class ChatPage extends StatefulWidget {
  final String language; // New field to hold the language

  const ChatPage({super.key, required this.language}); // Updated constructor

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  // Simple chat messages as a list of ChatMessage objects
  final List<ChatMessage> _messages = [
    ChatMessage(text: "Hello! What do you want to learn today?", isUser: false),
  ];
  final TextEditingController _textController = TextEditingController();
  final ApiService _apiService = ApiService();
  final TextToSpeech tts = TextToSpeech();
  bool _isLoading = false;

  void _handleSubmitted(String text) async {
    _textController.clear();
    setState(() {
      _messages.add(
        ChatMessage(text: text, isUser: true),
      ); // Add the user's message
      _isLoading = true;
    });

    try {
      // Pass the language from the widget to the API service
      final response = await _apiService.checkGrammar(text, widget.language);

      if (response.containsKey('error')) {
        setState(() {
          _messages.add(
            ChatMessage(text: "API Error: ${response['error']}", isUser: false),
          );
          _isLoading = false;
        });
        return;
      }

      final correctedSentence = response['corrected_sentence'];
      final mistakes = (response['mistakes'] as List).cast<String>();
      final correctedTextForTts = response['corrected_text_for_tts'];

      setState(() {
        _messages.add(ChatMessage(text: correctedSentence, isUser: false));
        _messages.add(
          ChatMessage(text: "Mistakes: ${mistakes.join(', ')}", isUser: false),
        );
        _isLoading = false;
      });

      // Speak the corrected sentence
      tts.speak(correctedTextForTts);
    } catch (e) {
      setState(() {
        _messages.add(
          ChatMessage(text: "An error occurred: $e", isUser: false),
        );
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Colors.transparent, // Set to transparent to show the background
      appBar: AppBar(
        title: const Text(
          'LinguaMate Chatbot',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent, // Transparent AppBar
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/wallpaper.jpg'), // New background image
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black54, BlendMode.darken),
          ),
        ),
        child: Column(
          children: <Widget>[
            // Chat message list
            Flexible(
              child: ListView.builder(
                padding: const EdgeInsets.all(8.0),
                reverse: true,
                itemCount: _messages.length,
                itemBuilder: (_, int index) {
                  final ChatMessage message =
                      _messages[_messages.length - 1 - index];
                  return Container(
                    alignment: message.isUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(
                      vertical: 8.0,
                      horizontal: 16.0,
                    ),
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.7,
                      ),
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: message.isUser
                            ? Colors.amber.withOpacity(
                                0.8,
                              ) // User bubble color changed to amber
                            : Colors.black.withOpacity(
                                0.6,
                              ), // System bubble color changed to black
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(12),
                          topRight: const Radius.circular(12),
                          bottomLeft: message.isUser
                              ? const Radius.circular(12)
                              : const Radius.circular(0),
                          bottomRight: message.isUser
                              ? const Radius.circular(0)
                              : const Radius.circular(12),
                        ),
                      ),
                      child: Text(
                        message.text,
                        style: TextStyle(
                          color: message.isUser ? Colors.black : Colors.white,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            // Loading indicator
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(color: Colors.amber),
              ),
            const Divider(height: 1.0),
            // Input bar
            Container(
              decoration: const BoxDecoration(color: Colors.transparent),
              child: IconTheme(
                data: IconThemeData(
                  color: Theme.of(context).colorScheme.secondary,
                ),
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 8.0,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey[800],
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Row(
                    children: <Widget>[
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: TextField(
                            controller: _textController,
                            onSubmitted: _handleSubmitted,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration.collapsed(
                              hintText: 'Type a message...',
                              hintStyle: TextStyle(color: Colors.white54),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.send,
                          color: Colors.amber,
                        ), // Send button color changed to amber
                        onPressed: () => _handleSubmitted(_textController.text),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
