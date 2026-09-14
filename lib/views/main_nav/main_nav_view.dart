import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/theme_controller.dart';
import '../../utils/app_theme.dart';
import '../home/home_view.dart';
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
    OccasionalView(),
    ReportsView(),
    SettingsView(),
  ];

  final _titles = const [
    'RoutineFix',
    'Occasional Reminders',
    'Reports',
    'Settings'
  ];

  void _toggleFab() => setState(() => _fabOpen = !_fabOpen);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(title: Text(_titles[_index])),
      drawer: _AppDrawer(onSelect: (i) {
        setState(() => _index = i);
        Navigator.pop(context);
      }),
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
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.checklist_rounded), label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.event_available_rounded), label: 'Occasional'),
          NavigationDestination(
              icon: Icon(Icons.insights_rounded), label: 'Reports'),
          NavigationDestination(
              icon: Icon(Icons.settings_rounded), label: 'Settings'),
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
      children: [
        AnimatedScale(
          scale: isOpen ? 1 : 0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutBack,
          child: AnimatedOpacity(
            opacity: isOpen ? 1 : 0,
            duration: const Duration(milliseconds: 150),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _miniAction(
                  icon: Icons.event_note_rounded,
                  label: 'Occasion',
                  color: AppColors.amberGold,
                  onTap: onAddOccasional,
                ),
                const SizedBox(height: 10),
                _miniAction(
                  icon: Icons.task_alt_rounded,
                  label: 'Task',
                  color: AppColors.signalTeal,
                  onTap: onAddTask,
                ),
                const SizedBox(height: 14),
              ],
            ),
          ),
        ),
        FloatingActionButton(
          onPressed: onToggle,
          backgroundColor: AppColors.charcoal,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: AnimatedRotation(
            turns: isOpen ? 0.125 : 0,
            duration: const Duration(milliseconds: 300),
            child: const Icon(
              Icons.add_rounded,
              //color: Colors.white,
            ),
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 12)),
        ),
        const SizedBox(width: 8),
        FloatingActionButton.small(
          heroTag: label,
          backgroundColor: color,
          onPressed: onTap,
          child: Icon(icon, color: Colors.white),
        ),
      ],
    );
  }
}

class _AppDrawer extends StatelessWidget {
  final ValueChanged<int> onSelect;
  const _AppDrawer({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final themeCtrl = Get.find<ThemeController>();
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              color: AppColors.inkNavy,
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.bolt_rounded,
                      color: AppColors.signalTeal, size: 36),
                  SizedBox(height: 10),
                  Text('RoutineFix',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Stay disciplined, one tick at a time.',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home_rounded),
              title: const Text('Home'),
              onTap: () => onSelect(0),
            ),
            ListTile(
              leading: const Icon(Icons.event_available_rounded),
              title: const Text('Occasional Reminders'),
              onTap: () => onSelect(1),
            ),
            ListTile(
              leading: const Icon(Icons.insights_rounded),
              title: const Text('Reports'),
              onTap: () => onSelect(2),
            ),
            const Divider(),
            Obx(() => ListTile(
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
            ListTile(
              leading: const Icon(Icons.settings_rounded),
              title: const Text('Settings'),
              onTap: () => onSelect(3),
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
}
