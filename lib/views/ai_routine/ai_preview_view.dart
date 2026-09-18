import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/task_controller.dart';
import '../../utils/app_theme.dart';

class AiPreviewView extends StatefulWidget {
  final String goal;
  final List<Map<String, dynamic>> suggestions;

  const AiPreviewView(
      {super.key, required this.goal, required this.suggestions});

  @override
  State<AiPreviewView> createState() => _AiPreviewViewState();
}

class _AiPreviewViewState extends State<AiPreviewView> {
  late List<bool> _selected;
  bool _regenerating = false;

  @override
  void initState() {
    super.initState();
    _selected = List<bool>.filled(widget.suggestions.length, true);
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = _selected.where((s) => s).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Routine Preview', overflow: TextOverflow.ellipsis),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'For: "${widget.goal}"',
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              itemCount: widget.suggestions.length,
              itemBuilder: (context, i) {
                final t = widget.suggestions[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                        color:
                            (_selected[i] ? AppColors.signalTeal : Colors.grey)
                                .withOpacity(0.25)),
                  ),
                  child: CheckboxListTile(
                    value: _selected[i],
                    onChanged: (v) => setState(() => _selected[i] = v ?? false),
                    activeColor: AppColors.signalTeal,
                    title: Text(t['title'] ?? '',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14.5)),
                    subtitle: Text(
                      '${t['description'] ?? ''}'
                      '${t['time'] != null ? " • ${t['time']}" : ""}',
                      style: TextStyle(fontSize: 12.5, color: Colors.grey[600]),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.inkNavy,
                      side:
                          BorderSide(color: AppColors.inkNavy.withOpacity(0.4)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _regenerating ? null : _regenerate,
                    icon: _regenerating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Regenerate'),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 48,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                        backgroundColor: AppColors.signalTeal),
                    onPressed: selectedCount == 0 ? null : _confirm,
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: Text(
                        'Add $selectedCount task${selectedCount == 1 ? '' : 's'}'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _regenerate() async {
    final controller = Get.find<TaskController>();
    setState(() => _regenerating = true);
    try {
      // Tell the AI which titles to avoid repeating.
      final avoid =
          widget.suggestions.map((e) => e['title'].toString()).toList();
      final fresh = await controller.generateAiSuggestions(widget.goal,
          avoidTitles: avoid);
      if (!mounted) return;
      Get.off(() => AiPreviewView(goal: widget.goal, suggestions: fresh));
    } catch (e) {
      if (!mounted) return;
      setState(() => _regenerating = false);
      Get.snackbar('AI Error', e.toString(),
          backgroundColor: AppColors.emberCoral, colorText: Colors.white);
    }
  }

  Future<void> _confirm() async {
    final controller = Get.find<TaskController>();
    final picked = <Map<String, dynamic>>[
      for (int i = 0; i < widget.suggestions.length; i++)
        if (_selected[i]) widget.suggestions[i],
    ];
    await controller.addAiTasks(widget.goal, widget.suggestions, picked);
    Get.back();
    Get.snackbar('Added', '${picked.length} tasks added to your routine',
        backgroundColor: AppColors.sageGreen, colorText: Colors.white);
  }
}
