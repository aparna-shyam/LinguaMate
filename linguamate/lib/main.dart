import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'api_service.dart';

void main() => runApp(const LinguamateApp());

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
        fontFamily: 'Roboto',
      ),
      home: const WelcomePage(),
    );
  }
}

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  WelcomePageState createState() => WelcomePageState();
}

class WelcomePageState extends State<WelcomePage> {
  String? selectedLanguage;
  final List<String> languages = [
    'English',
    'Spanish',
    'French',
    'German',
    'Japanese',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/template.jpg'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black54, BlendMode.darken),
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.translate, size: 80, color: Colors.white),
                const SizedBox(height: 24),
                const Text(
                  'Welcome to LinguaMate!',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
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
                      value: selectedLanguage,
                      items: languages
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(value),
                            ),
                          )
                          .toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedLanguage = newValue;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: 300,
                  child: ElevatedButton(
                    onPressed: selectedLanguage == null
                        ? null
                        : () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Starting your journey in $selectedLanguage!',
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ChatPage(language: selectedLanguage!),
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
  final String language;

  const ChatPage({super.key, required this.language});

  @override
  State<ChatPage> createState() => ChatPageState();
}

class ChatPageState extends State<ChatPage> {
  final List<ChatMessage> messages = [
    ChatMessage(text: 'Hello! What do you want to learn today?', isUser: false),
  ];
  final TextEditingController textController = TextEditingController();
  final ApiService apiService = ApiService();
  final FlutterTts flutterTts = FlutterTts();

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeTTS();
  }

  Future<void> _initializeTTS() async {
    await flutterTts.setLanguage('en-US');
    await flutterTts.setPitch(1.0);
    await flutterTts.setSpeechRate(1.0);
  }

  Future<void> handleSubmitted(String text) async {
    textController.clear();
    setState(() {
      messages.add(ChatMessage(text: text, isUser: true));
      isLoading = true;
    });

    try {
      final response = await apiService.checkGrammar(text, widget.language);

      if (response.containsKey('error')) {
        setState(() {
          messages.add(
            ChatMessage(text: 'API Error: ${response['error']}', isUser: false),
          );
          isLoading = false;
        });
        return;
      }

      final correctedSentence = response['corrected_sentence'];
      final mistakes = response['mistakes'] as List? ?? [];
      final correctedTextForTts = response['corrected_text_for_tts'];

      setState(() {
        messages.add(ChatMessage(text: correctedSentence, isUser: false));
        if (mistakes.isNotEmpty) {
          messages.add(
            ChatMessage(
              text: 'Mistakes: ${mistakes.join(", ")}',
              isUser: false,
            ),
          );
        }
        isLoading = false;
      });

      // Speak the corrected sentence
      if (correctedTextForTts != null) {
        await flutterTts.speak(correctedTextForTts);
      }
    } catch (e) {
      setState(() {
        messages.add(ChatMessage(text: 'An error occurred: $e', isUser: false));
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[900],
      appBar: AppBar(
        title: const Text(
          'LinguaMate Chatbot',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blueGrey[900],
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/wallpaper.jpg'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black54, BlendMode.darken),
          ),
        ),
        child: Column(
          children: [
            Flexible(
              child: ListView.builder(
                padding: const EdgeInsets.all(8.0),
                reverse: true,
                itemCount: messages.length,
                itemBuilder: (_, int index) {
                  final message = messages[messages.length - 1 - index];
                  return Container(
                    alignment: message.isUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(
                      vertical: 8.0,
                      horizontal: 16.0,
                    ),
                    child: Row(
                      mainAxisAlignment: message.isUser
                          ? MainAxisAlignment.end
                          : MainAxisAlignment.start,
                      children: [
                        if (!message.isUser &&
                            message.text !=
                                'Hello! What do you want to learn today?' &&
                            !message.text.startsWith('Mistakes:'))
                          IconButton(
                            icon: const Icon(
                              Icons.volume_up,
                              color: Colors.white,
                            ),
                            onPressed: () async {
                              await flutterTts.speak(message.text);
                            },
                          ),
                        Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.7,
                          ),
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: message.isUser
                                ? Colors.amber.withOpacity(0.8)
                                : Colors.black.withOpacity(0.6),
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
                              color: message.isUser
                                  ? Colors.black
                                  : Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(color: Colors.amber),
              ),
            const Divider(height: 1.0),
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
                    children: [
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: TextField(
                            controller: textController,
                            onSubmitted: handleSubmitted,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration.collapsed(
                              hintText: 'Type a message...',
                              hintStyle: TextStyle(color: Colors.white54),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send, color: Colors.amber),
                        onPressed: () => handleSubmitted(textController.text),
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
