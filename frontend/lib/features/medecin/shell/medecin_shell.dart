import 'package:flutter/material.dart';
import 'package:lupus_plus/core/constants/app_strings.dart';
import 'package:lupus_plus/core/theme/app_colors.dart';
import 'package:lupus_plus/features/medecin/home/home_page.dart';
import 'package:lupus_plus/features/medecin/shell/placeholder_page.dart';

// The doctor's main screen: the current tab + the bottom bar.
class MedecinShell extends StatefulWidget {
  const MedecinShell({super.key});

  @override
  State<MedecinShell> createState() => _MedecinShellState();
}

class _MedecinShellState extends State<MedecinShell> {
  // Index of the selected tab: 0 = Accueil, 1 = Patients, 2 = Agenda, 3 = Profil.
  int _currentIndex = 0;

  // The 4 pages, in the same order as the indexes above.
  final List<Widget> _pages = const [
    HomePage(),
    PlaceholderPage(title: AppStrings.navPatients),
    PlaceholderPage(title: AppStrings.navAgenda),
    PlaceholderPage(title: AppStrings.navProfil),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack shows only the selected page but keeps the others alive,
      // so the home page doesn't reload every time you come back to it.
      body: IndexedStack(index: _currentIndex, children: _pages),

      // Center "+" button, docked in the middle of the bar.
      floatingActionButton: FloatingActionButton(
        // Nothing happens until the "add patient" feature exists.
        onPressed: () {},
        backgroundColor: AppColors.accent,
        elevation: 2,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // Bottom bar with a round notch for the "+" button.
      bottomNavigationBar: BottomAppBar(
        color: AppColors.navBar,
        surfaceTintColor: Colors.transparent,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        height: 64,
        padding: EdgeInsets.zero,
        child: Row(
          children: [
            // Two tabs on the left.
            _NavItem(
              icon: Icons.home_outlined,
              label: AppStrings.navAccueil,
              selected: _currentIndex == 0,
              onTap: () => setState(() => _currentIndex = 0),
            ),
            _NavItem(
              icon: Icons.people_outline,
              label: AppStrings.navPatients,
              selected: _currentIndex == 1,
              onTap: () => setState(() => _currentIndex = 1),
            ),
            // Empty space under the "+" button.
            const SizedBox(width: 72),
            // Two tabs on the right.
            _NavItem(
              icon: Icons.calendar_today_outlined,
              label: AppStrings.navAgenda,
              selected: _currentIndex == 2,
              onTap: () => setState(() => _currentIndex = 2),
            ),
            _NavItem(
              icon: Icons.person_outline,
              label: AppStrings.navProfil,
              selected: _currentIndex == 3,
              onTap: () => setState(() => _currentIndex = 3),
            ),
          ],
        ),
      ),
    );
  }
}

// One tab of the bottom bar: an icon with a label under it.
// The leading "_" makes this class private to this file.
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected; // true = this tab is the current one
  final VoidCallback onTap; // what to do when tapped

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Purple when selected, grey otherwise.
    final color = selected ? AppColors.primary : AppColors.textGrey;

    // Expanded: the 4 tabs share the available width equally.
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}