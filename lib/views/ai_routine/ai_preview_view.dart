import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/task_controller.dart';
import '../../services/ad_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/custom_snackbar.dart';

class AiPreviewView extends StatefulWidget {
  final String goal;
  final List<Map<String, dynamic>> suggestions;

  const AiPreviewView(
      {super.key, required this.goal, required this.suggestions});

  @override
  State<AiPreviewView> createState() => _AiPreviewViewState();
}

class _AiPreviewViewState extends State<AiPreviewView> {
  late List<Map<String, dynamic>> _suggestions;
  late List<bool> _selected;
  bool _regenerating = false;

  @override
  void initState() {
    super.initState();
    _suggestions = widget.suggestions;
    _selected = List<bool>.filled(_suggestions.length, true);
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
            child: Stack(
              children: [
                ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: _suggestions.length,
                  itemBuilder: (context, i) {
                    final t = _suggestions[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                            color: (_selected[i]
                                    ? AppColors.signalTeal
                                    : Colors.grey)
                                .withOpacity(0.25)),
                      ),
                      child: CheckboxListTile(
                        value: _selected[i],
                        onChanged: (v) =>
                            setState(() => _selected[i] = v ?? false),
                        activeColor: AppColors.signalTeal,
                        title: Text(t['title'] ?? '',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 14.5)),
                        subtitle: Text(
                          '${t['description'] ?? ''}'
                          '${t['time'] != null ? " • ${t['time']}" : ""}',
                          style: TextStyle(
                              fontSize: 12.5, color: Colors.grey[600]),
                        ),
                      ),
                    );
                  },
                ),
                if (_regenerating)
                  Container(
                    color: Colors.black.withOpacity(0.08),
                    child: const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Card(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 20, vertical: 16),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2)),
                                SizedBox(width: 12),
                                Text('Regenerating...'),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
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
                      foregroundColor: AppColors.signalTeal,
                      side: BorderSide(
                          color: AppColors.signalTeal.withOpacity(0.5)),
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
    if (!controller.canUseAiToday) {
      if (!controller.canWatchAdForCredit) {
        CustomSnackbar.error(
          'Limit reached',
          'No generations left. ${controller.aiLimitResetLabel}',
        );
        return;
      }
      final watch = await _askToWatchAd();
      if (watch != true) return;
      final rewarded = await AdService.instance.showForAiCredit();
      if (!rewarded) return;
    }
    setState(() => _regenerating = true);
    try {
      final fresh =
          await controller.generateAiSuggestions(widget.goal, regenerate: true);
      if (!mounted) return;
      setState(() {
        _suggestions = fresh;
        _selected = List<bool>.filled(fresh.length, true);
        _regenerating = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _regenerating = false);
      CustomSnackbar.error(
        'AI Error',
        e.toString(),
      );
    }
  }

  Future<bool?> _askToWatchAd() => Get.dialog<bool>(
        AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Free generation used'),
          content: const Text(
              'Watch a short ad to get 1 more AI generation and regenerate this routine.'),
          actions: [
            TextButton(
                onPressed: () => Get.back(result: false),
                child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.signalTeal,
                  foregroundColor: Colors.white),
              onPressed: () => Get.back(result: true),
              child: const Text('Watch ad'),
            ),
          ],
        ),
      );

  Future<void> _confirm() async {
    final controller = Get.find<TaskController>();
    final picked = <Map<String, dynamic>>[
      for (int i = 0; i < _suggestions.length; i++)
        if (_selected[i]) _suggestions[i],
    ];
    await controller.addAiTasks(widget.goal, _suggestions, picked);
    Get.back();
    CustomSnackbar.success(
      'Added',
      '${picked.length} tasks added to your routine',
    );
  }
}
