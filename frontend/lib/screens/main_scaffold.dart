import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/nav_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/aurora_background.dart';
import '../widgets/mini_player.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'library_screen.dart';
import 'profile_screen.dart';
import 'rooms_screen.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  // Keep all 4 screens in memory
  final List<Widget> _screens = const [
    HomeScreen(),
    SearchScreen(),
    LibraryScreen(),
    ProfileScreen(),
  ];

  @override
    @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // REMOVED backgroundColor: Colors.transparent 
      // so it uses the proper dark/light theme background!
      body: AuroraBackground(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, // Forces full width
          children: [
            Expanded(
              child: IndexedStack(
                index: nav.index,
                children: _screens,
              ),
            ),
            const MiniPlayer(),
          ],
        ),
      ),

      floatingActionButton: Transform.translate(
        offset: const Offset(0, 12),
        child: SizedBox(
          width: 56,
          height: 56,
          child: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RoomsScreen()),
              );
            },
            backgroundColor: AppColors.primary,
            elevation: 6,
            shape: const CircleBorder(),
            child: const Icon(Icons.add, color: Colors.white, size: 26),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomAppBar(
        color: isDark
            ? AppColors.darkSurface.withOpacity(0.95)
            : AppColors.lightSurface.withOpacity(0.95),
        elevation: 0,
        shape: const CircularNotchedRectangle(),
        notchMargin: 10,
        clipBehavior: Clip.antiAliasWithSaveLayer,
        padding: EdgeInsets.zero,
        child: SizedBox(
          height: 78,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // ... (keep the _NavItems exactly as they were)
              _NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: 'Home',
                isActive: nav.index == 0,
                onTap: () => context.read<NavProvider>().setIndex(0),
              ),
              _NavItem(
                icon: Icons.search_outlined,
                activeIcon: Icons.search,
                label: 'Search',
                isActive: nav.index == 1,
                onTap: () => context.read<NavProvider>().setIndex(1),
              ),
              const SizedBox(width: 56),
              _NavItem(
                icon: Icons.library_music_outlined,
                activeIcon: Icons.library_music,
                label: 'Library',
                isActive: nav.index == 2,
                onTap: () => context.read<NavProvider>().setIndex(2),
              ),
              _NavItem(
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: 'You',
                isActive: nav.index == 3,
                onTap: () => context.read<NavProvider>().setIndex(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inactiveColor =
        isDark ? AppColors.darkTextSubtle : AppColors.lightTextSubtle;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isActive ? activeIcon : icon,
            color: isActive ? AppColors.primary : inactiveColor,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isActive ? AppColors.primary : inactiveColor,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}