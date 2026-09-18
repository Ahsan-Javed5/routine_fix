import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class AiService {
  static final AiService instance = AiService._internal();
  AiService._internal();

  static final String _apiKey = String.fromEnvironment('GEMINI_KEY',
      defaultValue: dotenv.env['API_KEY'].toString());

  Future<List<Map<String, dynamic>>> generateRoutine(String goal,
      {List<String>? avoidTitles}) async {
    final model = GenerativeModel(
      model: 'gemini-3.5-flash-lite',
      apiKey: _apiKey,
      generationConfig: GenerationConfig(responseMimeType: 'application/json'),
    );

    final avoidBlock = (avoidTitles != null && avoidTitles.isNotEmpty)
        ? '\nThis is a REGENERATE request. Produce a noticeably different routine. '
            'Avoid repeating these previously suggested tasks: '
            '${avoidTitles.join(", ")}.'
        : '';

    final prompt = '''
Generate a helpful daily routine for this goal: "$goal".
Return EXACTLY a JSON array of 3 to 5 tasks.
Each item format: {"title": string, "description": string, "time": "HH:mm"}
No extra text, only the JSON array.$avoidBlock
''';

    final response = await model.generateContent([Content.text(prompt)]);
    final raw = response.text;
    if (raw == null || raw.trim().isEmpty) {
      throw Exception('Empty response from AI');
    }

    final decoded = jsonDecode(raw);
    if (decoded is! List) throw Exception('Unexpected AI response format');

    return decoded
        .whereType<Map>()
        .map((e) => {
              'title': (e['title'] ?? 'Untitled Task').toString(),
              'description': (e['description'] ?? '').toString(),
              'time': e['time']?.toString(),
            })
        .toList();
  }
}
