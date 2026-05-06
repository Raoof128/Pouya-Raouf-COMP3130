import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mq_navigation/app/l10n/generated/app_localizations.dart';

/// Persistent bottom navigation shell wrapping the main tab destinations.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navLabelColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((states) {
          return TextStyle(color: navLabelColor);
        }),
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          // Navigate to the chosen branch. If the user taps the active tab,
          // the branch's navigation stack pops back to its root.
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, color: navLabelColor),
            selectedIcon: Icon(Icons.home, color: navLabelColor),
            label: l10n.home,
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined, color: navLabelColor),
            selectedIcon: Icon(Icons.map, color: navLabelColor),
            label: l10n.navigation,
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined, color: navLabelColor),
            selectedIcon: Icon(Icons.settings, color: navLabelColor),
            label: l10n.settings,
          ),
        ],
      ),
    );
  }
}
