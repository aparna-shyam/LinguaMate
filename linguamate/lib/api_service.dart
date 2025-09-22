import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Replace this with your actual API key
  static const _apiKey = 'AIzaSyDPaGWKprjT8Vh-x0EbB0Qe4la_pSpKr5g';
  static const _apiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-preview-05-20:generateContent?key=$_apiKey';

  Future<Map<String, dynamic>> checkGrammar(
    String text,
    String language,
  ) async {
    final payload = {
      "contents": [
        {
          "parts": [
            {
              // The API prompt now uses the 'language' parameter.
              "text":
                  "Correct the following $language sentence, explain the grammar mistakes, and provide a corrected version. The output should be a single JSON object with the following structure: {'corrected_sentence': '...', 'mistakes': ['...'], 'corrected_text_for_tts': '...'} and make sure the corrected_text_for_tts has no punctuation.: $text",
            },
          ],
        },
      ],
      "generationConfig": {
        "responseMimeType": "application/json",
        "responseSchema": {
          "type": "OBJECT",
          "properties": {
            "corrected_sentence": {"type": "STRING"},
            "mistakes": {
              "type": "ARRAY",
              "items": {"type": "STRING"},
            },
            "corrected_text_for_tts": {"type": "STRING"},
          },
        },
      },
    };

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final generatedText =
            jsonResponse['candidates'][0]['content']['parts'][0]['text'];
        return jsonDecode(generatedText);
      } else {
        return {
          'error':
              'Failed to get a response from the API. Status code: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'error': 'An error occurred while calling the API: $e'};
    }
  }
}
