import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class AiService {
  static final AiService instance = AiService._internal();
  AiService._internal();

  static final String _apiKey = String.fromEnvironment('GEMINI_KEY',
      defaultValue: dotenv.env['API_KEY'].toString());

  List<dynamic>? _localRoutinesCache;
  List<Map<String, dynamic>> _aiTaskPool = [];
  List<String> _shownTaskTitles = [];

  Future<List<Map<String, dynamic>>> generateRoutine(
      String goal, bool isRegenerate) async {
    final cleanGoal = goal.trim().toLowerCase();

    // =============================================================
    // STEP 1: Local Asset Match Check ($0 Cost & Offline)
    // =============================================================
    try {
      if (_localRoutinesCache == null) {
        final jsonString =
            await rootBundle.loadString('assets/data/predefined_routines.json');
        final decodedData = jsonDecode(jsonString);
        _localRoutinesCache = decodedData['routines'];
      }

      if (_localRoutinesCache != null) {
        final matched = _localRoutinesCache!.firstWhere(
          (r) {
            final List tags = r['tags'] ?? [];
            return tags.any((tag) {
              final t = tag.toString().toLowerCase();
              return t == cleanGoal ||
                  cleanGoal.contains(t) ||
                  t.contains(cleanGoal);
            });
          },
          orElse: () => null,
        );

        if (matched != null && matched['tasks'] is List) {
          List tasks = List.from(matched['tasks']);

          // Exclude previously shown task titles on Regenerate
          if (isRegenerate && _shownTaskTitles.isNotEmpty) {
            final avoidLower =
                _shownTaskTitles.map((e) => e.toLowerCase()).toSet();
            tasks = tasks
                .where((t) =>
                    !avoidLower.contains(t['title'].toString().toLowerCase()))
                .toList();
          }

          if (tasks.isNotEmpty) {
            tasks.shuffle(Random());
            final count = min(tasks.length, 4);
            final selected = tasks.take(count).toList();

            // Save shown task titles
            _shownTaskTitles.addAll(
              selected.map((e) => e['title'].toString()),
            );

            return selected
                .map<Map<String, dynamic>>((e) => {
                      'title': (e['title'] ?? 'Untitled Task').toString(),
                      'description': (e['description'] ?? '').toString(),
                      'time': e['time']?.toString() ?? '09:00',
                    })
                .toList();
          }
        }
      }
    } catch (e) {
      print("Local Asset Search Exception: $e");
    }

    // =============================================================
    // STEP 2: Use Memory Pool for Unique API Query (Regenerate Flow)
    // =============================================================
    if (isRegenerate && _aiTaskPool.isNotEmpty) {
      final remainingTasks = _aiTaskPool.where((task) {
        final title = task['title'].toString().toLowerCase();
        return !_shownTaskTitles.map((e) => e.toLowerCase()).contains(title);
      }).toList();

      if (remainingTasks.length >= 3) {
        remainingTasks.shuffle(Random());
        final nextBatch = remainingTasks.take(4).toList();

        _shownTaskTitles.addAll(
          nextBatch.map((e) => e['title'].toString()),
        );

        return nextBatch;
      }
    }

    // =============================================================
    // STEP 3: Fallback Gemini API Call (Fetch 15-20 Tasks Pool Once)
    // =============================================================
    if (!isRegenerate) {
      _aiTaskPool.clear();
      _shownTaskTitles.clear();
    }

    final model = GenerativeModel(
      model: 'gemini-3.5-flash-lite',
      apiKey: _apiKey,
      generationConfig: GenerationConfig(responseMimeType: 'application/json'),
    );

    final prompt = '''
Generate a helpful daily routine for this goal: "$goal".
Return EXACTLY a JSON array of 15 to 20 tasks.
Each item format: {"title": string, "description": string, "time": "HH:mm"}
No extra text, only the JSON array.
''';

    final response = await model.generateContent([Content.text(prompt)]);
    final raw = response.text;
    if (raw == null || raw.trim().isEmpty) {
      throw Exception('Empty response from AI');
    }

    final decoded = jsonDecode(raw);
    if (decoded is! List) throw Exception('Unexpected AI response format');

    final fetchedTasks = decoded
        .whereType<Map>()
        .map<Map<String, dynamic>>((e) => {
              'title': (e['title'] ?? 'Untitled Task').toString(),
              'description': (e['description'] ?? '').toString(),
              'time': e['time']?.toString() ?? '09:00',
            })
        .toList();

    _aiTaskPool = fetchedTasks;
    _aiTaskPool.shuffle(Random());

    final initialDisplay = _aiTaskPool.take(4).toList();
    _shownTaskTitles =
        initialDisplay.map((e) => e['title'].toString()).toList();

    return initialDisplay;
  }
}
