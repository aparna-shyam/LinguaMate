import 'package:flutter/material.dart';

void main() {
  runApp(const LinguamateApp());
}

class LinguamateApp extends StatelessWidget {
  const LinguamateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Linguamate',
      debugShowCheckedModeBanner:
          false, // Add this line to remove the debug banner
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
                            // This is where you would handle the navigation to the next page
                            // For now, we'll just print the selected language.
                            debugPrint('Selected Language: $_selectedLanguage');
                            // Example of a snackbar to confirm selection
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Starting your journey in $_selectedLanguage!',
                                ),
                                duration: const Duration(seconds: 2),
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
