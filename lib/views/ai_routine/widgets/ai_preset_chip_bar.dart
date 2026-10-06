import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../utils/app_theme.dart';

class AiPresetChipBar extends StatelessWidget {
  final List<String> presets;
  final ValueChanged<String> onSelected;
  final int initialVisibleCount;

  // GetX Reactive variable
  final RxBool _isExpanded = false.obs;

  AiPresetChipBar({
    super.key,
    required this.presets,
    required this.onSelected,
    this.initialVisibleCount = 7,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final visiblePresets = _isExpanded.value
          ? presets
          : presets.take(initialVisibleCount).toList();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...visiblePresets.map((p) {
                return InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    onSelected(p);
                    if (_isExpanded.value) {
                      _isExpanded.value = false;
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.signalTeal.withOpacity(0.4),
                      ),
                    ),
                    child: Text(
                      p,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }),

              // "See More" / "See Less" Toggle Button
              if (presets.length > initialVisibleCount)
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    // GetX toggle without setState
                    _isExpanded.toggle();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.signalTeal.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.signalTeal),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _isExpanded.value ? "See Less" : "See More",
                          style: const TextStyle(
                            color: AppColors.signalTeal,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          _isExpanded.value
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: AppColors.signalTeal,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      );
    });
  }
}
