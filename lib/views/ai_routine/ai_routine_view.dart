import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/task_controller.dart';
import '../../utils/app_theme.dart';
import 'widgets/ai_preset_chip_bar.dart';
import 'widgets/ai_history_card.dart';
import 'ai_preview_view.dart';

class AiRoutineView extends StatefulWidget {
  const AiRoutineView({super.key});

  @override
  State<AiRoutineView> createState() => _AiRoutineViewState();
}

class _AiRoutineViewState extends State<AiRoutineView> {
  final _goalCtrl = TextEditingController();
  bool _loading = false;

  static const _presets = [
    'Better sleep',
    'Exam prep',
    'Fitness & workout',
    'Morning discipline',
    'Deep work / focus',
  ];

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TaskController>();

    // Obx makes this whole section reactive: usage count, reset countdown,
    // and history all update live — no manual refresh needed, even after
    // navigating back from the preview/regenerate screen.
    return Scaffold(
      body: Obx(() {
        final usesLeft = TaskController.dailyAiLimit - controller.aiUsesToday;
        final limitReached = usesLeft <= 0;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            _usageBadge(usesLeft, limitReached, controller),
            const SizedBox(height: 16),
            _inputCard(context, controller, limitReached),
            const SizedBox(height: 24),
            if (controller.aiHistory.isNotEmpty) ...[
              const Text('Recent Routines',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 10),
              ...controller.aiHistory.map((h) => AiHistoryCard(log: h)),
            ] else
              _emptyHistory(),
          ],
        );
      }),
    );
  }

  Widget _usageBadge(
      int usesLeft, bool limitReached, TaskController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: limitReached
            ? AppColors.emberCoral.withOpacity(0.12)
            : AppColors.signalTeal.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            limitReached ? Icons.hourglass_bottom_rounded : Icons.bolt_rounded,
            size: 18,
            color: limitReached ? AppColors.emberCoral : AppColors.signalTeal,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              limitReached
                  ? 'Daily AI limit reached — ${controller.aiLimitResetLabel}'
                  : '$usesLeft of ${TaskController.dailyAiLimit} AI generations left · ${controller.aiLimitResetLabel.isEmpty ? "resets 24h after first use" : controller.aiLimitResetLabel}',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color:
                    limitReached ? AppColors.emberCoral : AppColors.signalTeal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputCard(
      BuildContext context, TaskController controller, bool limitReached) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.inkNavy, AppColors.inkNavy.withOpacity(0.88)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.inkNavy.withOpacity(0.22),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.signalTeal.withOpacity(0.16),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome_rounded,
                    color: AppColors.signalTeal, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Build my routine with AI',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          if (controller.todayTaskCount > 0)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                'You already have ${controller.todayTaskCount} task(s) today — '
                'new ones will be added alongside them.',
                style: const TextStyle(color: Colors.white54, fontSize: 11.5),
              ),
            ),
          const SizedBox(height: 14),
          AiPresetChipBar(
            presets: _presets,
            onSelected: (p) => setState(() => _goalCtrl.text = p),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _goalCtrl,
            style: const TextStyle(color: Colors.white, fontSize: 14.5),
            minLines: 3,
            maxLines: 4,
            textAlignVertical: TextAlignVertical.top,
            decoration: InputDecoration(
              hintText: 'Or describe your goal in your own words...',
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 13.5),
              filled: true,
              fillColor: Colors.white.withOpacity(0.08),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.signalTeal,
              ),
              onPressed: (_loading || limitReached)
                  ? null
                  : () => _generate(context, controller),
              icon: _loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.auto_awesome_rounded, size: 18),
              label: Text(_loading ? 'Generating...' : 'Generate Routine'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyHistory() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.history_rounded, size: 40, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text('Your generated routines will show up here',
                style: TextStyle(color: Colors.grey[600], fontSize: 12.5)),
          ],
        ),
      ),
    );
  }

  Future<void> _generate(
      BuildContext context, TaskController controller) async {
    final goal = _goalCtrl.text.trim();
    if (goal.isEmpty) {
      Get.snackbar('Missing goal', 'Please enter or pick a goal first',
          backgroundColor: AppColors.emberCoral, colorText: Colors.white);
      return;
    }
    setState(() => _loading = true);
    try {
      final suggestions = await controller.generateAiSuggestions(goal);
      if (!mounted) return;
      setState(() => _loading = false);
      _goalCtrl.clear();
      Get.to(() => AiPreviewView(goal: goal, suggestions: suggestions));
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      Get.snackbar('AI Error', e.toString(),
          backgroundColor: AppColors.emberCoral, colorText: Colors.white);
    }
  }
}
