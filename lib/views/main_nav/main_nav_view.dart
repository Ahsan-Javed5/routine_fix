import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/theme_controller.dart';
import '../../utils/app_theme.dart';
import '../ai_routine/ai_routine_view.dart';
import '../home/home_view.dart';
import '../home/widgets/ai_routine_sheet.dart';
import '../occasional_reminder/occasional_view.dart';
import '../reports/reports_view.dart';
import '../settings/settings_view.dart';
import '../add_task/add_task_view.dart';

class MainNavView extends StatefulWidget {
  const MainNavView({super.key});

  @override
  State<MainNavView> createState() => _MainNavViewState();
}

class _MainNavViewState extends State<MainNavView> {
  int _index = 0;
  bool _fabOpen = false;

  final _pages = const [
    HomeView(),
    AiRoutineView(),
    OccasionalView(),
    ReportsView(),
    SettingsView(),
  ];

  final _titles = const [
    'RoutineFix',
    'AI Routine',
    'Occasional Reminders',
    'Reports',
    'Settings',
  ];

  void _toggleFab() => setState(() => _fabOpen = !_fabOpen);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: Text(
          _titles[_index],
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 2,
      ),
      drawer: _AppDrawer(
        selectedIndex: _index,
        onSelect: (i) {
          setState(() => _index = i);
          Navigator.pop(context);
        },
      ),
      body: IndexedStack(index: _index, children: _pages),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: _index == 3
          ? null
          : _ExpandableFab(
              isOpen: _fabOpen,
              onToggle: _toggleFab,
              onAddTask: () {
                setState(() => _fabOpen = false);
                Get.to(() => const AddTaskView());
              },
              onAddOccasional: () {
                setState(() => _fabOpen = false);
                showAddOccasionalDialog(context);
              },
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        elevation: 3,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.checklist_rounded),
            selectedIcon: Icon(Icons.checklist_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: _AnimatedAiIcon(),
            selectedIcon: _AnimatedAiIcon(active: true),
            label: 'AI',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_available_outlined),
            selectedIcon: Icon(Icons.event_available_rounded),
            label: 'Occasional',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights_rounded),
            label: 'Reports',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class _ExpandableFab extends StatelessWidget {
  final bool isOpen;
  final VoidCallback onToggle;
  final VoidCallback onAddTask;
  final VoidCallback onAddOccasional;

  const _ExpandableFab({
    required this.isOpen,
    required this.onToggle,
    required this.onAddTask,
    required this.onAddOccasional,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        AnimatedSlide(
          offset: isOpen ? Offset.zero : const Offset(0, 0.3),
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutBack,
          child: AnimatedOpacity(
            opacity: isOpen ? 1 : 0,
            duration: const Duration(milliseconds: 180),
            child: IgnorePointer(
              ignoring: !isOpen,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _miniAction(
                    icon: Icons.event_note_rounded,
                    label: 'Occasion',
                    color: AppColors.amberGold,
                    onTap: onAddOccasional,
                  ),
                  const SizedBox(height: 12),
                  _miniAction(
                    icon: Icons.task_alt_rounded,
                    label: 'Task',
                    color: AppColors.signalTeal,
                    onTap: onAddTask,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
        FloatingActionButton(
          onPressed: onToggle,
          backgroundColor: AppColors.charcoal,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: AnimatedRotation(
            turns: isOpen ? 0.125 : 0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            child: const Icon(Icons.add_rounded, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _miniAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: onTap,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
          ),
        ),
      ],
    );
  }
}

class _AppDrawer extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  const _AppDrawer({required this.selectedIndex, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final themeCtrl = Get.find<ThemeController>();
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.inkNavy,
                    AppColors.inkNavy.withOpacity(0.85),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.signalTeal.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.bolt_rounded,
                        color: AppColors.signalTeal, size: 28),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'RoutineFix',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Stay disciplined, one tick at a time.',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                children: [
                  _drawerTile(
                    context,
                    icon: Icons.home_rounded,
                    label: 'Home',
                    selected: selectedIndex == 0,
                    onTap: () => onSelect(0),
                  ),
                  _drawerTile(
                    context,
                    icon: Icons.event_available_rounded,
                    label: 'Occasional Reminders',
                    selected: selectedIndex == 1,
                    onTap: () => onSelect(1),
                  ),
                  _drawerTile(
                    context,
                    icon: Icons.insights_rounded,
                    label: 'Reports',
                    selected: selectedIndex == 2,
                    onTap: () => onSelect(2),
                  ),
                ],
              ),
            ),
            const Divider(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Obx(() => ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    leading: const Icon(Icons.dark_mode_rounded),
                    title: const Text('Quick theme toggle'),
                    subtitle: Text(themeCtrl.themeMode.value.label),
                    onTap: () {
                      final next =
                          themeCtrl.themeMode.value == ThemeModeOption.light
                              ? ThemeModeOption.dark
                              : ThemeModeOption.light;
                      themeCtrl.setMode(next);
                    },
                  )),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: _drawerTile(
                context,
                icon: Icons.settings_rounded,
                label: 'Settings',
                selected: selectedIndex == 3,
                onTap: () => onSelect(3),
              ),
            ),
            const Spacer(),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('v1.0.0',
                  style: TextStyle(color: Colors.grey, fontSize: 11)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final color =
        selected ? AppColors.signalTeal : Theme.of(context).iconTheme.color;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.signalTeal.withOpacity(0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        leading: Icon(icon, color: color),
        title: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.signalTeal : null,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}

class _AnimatedAiIcon extends StatefulWidget {
  final bool active;

  const _AnimatedAiIcon({this.active = false});

  @override
  State<_AnimatedAiIcon> createState() => _AnimatedAiIconState();
}

class _AnimatedAiIconState extends State<_AnimatedAiIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, child) {
        return Transform.scale(
          scale: 1.0 + (_controller.value * 0.08),
          child: Icon(
            Icons.auto_awesome_rounded,
            color: widget.active
                ? AppColors.signalTeal
                : Theme.of(context).iconTheme.color,
          ),
        );
      },
    );
  }
}
