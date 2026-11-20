import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lupus_plus/core/constants/app_strings.dart';
import 'package:lupus_plus/core/theme/app_colors.dart';
import 'package:lupus_plus/features/medecin/agenda/agenda_page.dart';
import 'package:lupus_plus/features/medecin/home/accueil_navigator.dart';
import 'package:lupus_plus/features/medecin/patients/patients_navigator.dart';
import 'package:lupus_plus/features/medecin/profile/profile_page.dart';

// The doctor's main screen: the current tab + the bottom bar.
class MedecinShell extends StatefulWidget {
  const MedecinShell({super.key});

  @override
  State<MedecinShell> createState() => _MedecinShellState();
}

class _MedecinShellState extends State<MedecinShell> {
  // Selected tab: 0 = Accueil, 1 = Patients, 2 = Agenda, 3 = Profil.
  int _currentIndex = 0;

  // Keys to control the own navigators of the Accueil and Patients tabs.
  final GlobalKey<NavigatorState> _accueilNavKey = GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> _patientsNavKey = GlobalKey<NavigatorState>();

  // Navigator of the selected tab (only Accueil and Patients have one).
  NavigatorState? get _navigateurActuel => switch (_currentIndex) {
        0 => _accueilNavKey.currentState,
        1 => _patientsNavKey.currentState,
        _ => null,
      };

  void _allerA(int index) {
    // Tapping the tab you are already on goes back to its first page.
    if (index == _currentIndex) {
      _navigateurActuel?.popUntil((route) => route.isFirst);
      return;
    }
    setState(() => _currentIndex = index);
  }

  // The 4 pages, in the same order as the indexes above.
  late final List<Widget> _pages = [
    AccueilNavigator(
      navigatorKey: _accueilNavKey,
      onVoirTout: () => _allerA(1),
    ),
    PatientsNavigator(
      navigatorKey: _patientsNavKey,
      onRetourAccueil: () => _allerA(0),
    ),
    const AgendaPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    // System back button: closes a page inside the tab first, then goes to
    // the Accueil tab, and only then leaves the app.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        final nav = _navigateurActuel;
        if (nav != null && nav.canPop()) {
          nav.pop();
        } else if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        // IndexedStack shows only the selected page but keeps the others alive.
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
              _NavItem(
                icon: Icons.home_outlined,
                label: AppStrings.navAccueil,
                selected: _currentIndex == 0,
                onTap: () => _allerA(0),
              ),
              _NavItem(
                icon: Icons.people_outline,
                label: AppStrings.navPatients,
                selected: _currentIndex == 1,
                onTap: () => _allerA(1),
              ),
              // Empty space under the "+" button.
              const SizedBox(width: 72),
              _NavItem(
                icon: Icons.calendar_today_outlined,
                label: AppStrings.navAgenda,
                selected: _currentIndex == 2,
                onTap: () => _allerA(2),
              ),
              _NavItem(
                icon: Icons.person_outline,
                label: AppStrings.navProfil,
                selected: _currentIndex == 3,
                onTap: () => _allerA(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// One tab of the bottom bar: an icon with a label under it.
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textGrey;

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