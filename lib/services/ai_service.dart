import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class AiService {
  static final AiService instance = AiService._internal();
  AiService._internal();

  final String _apiKey = String.fromEnvironment('GEMINI_KEY',
      defaultValue: dotenv.env['API_KEY'].toString());

  Future<List<Map<String, dynamic>>> generateRoutine(String goal) async {
    final model = GenerativeModel(
      model: 'gemini-3.5-flash-lite',
      apiKey: _apiKey,
      generationConfig: GenerationConfig(responseMimeType: 'application/json'),
    );

    final prompt = '''
Generate a practical daily routine for this goal: "$goal".

Return EXACTLY a JSON array containing 3 to 5 tasks.
Each task must have:
- "title": short, clear task name (max 6 words)
- "description": brief actionable instruction (max 12 words)
- "time": suggested time in HH:mm format

Keep tasks specific, realistic, and non-repetitive.
No extra text. Return only the JSON array.
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
