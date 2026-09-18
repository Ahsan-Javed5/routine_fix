import 'package:flutter/material.dart';
import '../../../utils/app_theme.dart';

class AiPresetChipBar extends StatelessWidget {
  final List<String> presets;
  final ValueChanged<String> onSelected;

  const AiPresetChipBar({
    super.key,
    required this.presets,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: presets.map((p) {
        return InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => onSelected(p),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.signalTeal.withOpacity(0.4)),
            ),
            child: Text(p,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
          ),
        );
      }).toList(),
    );
  }
}
