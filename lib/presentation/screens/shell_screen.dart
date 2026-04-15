// lib/presentation/screens/shell_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_theme.dart';
import '../providers/providers.dart';
import 'activity/activity_screen.dart';
import 'add_landmark/add_landmark_screen.dart';
import 'list/list_screen.dart';
import 'map/map_screen.dart';

final _tabProvider = StateProvider<int>((ref) => 0);

class ShellScreen extends ConsumerStatefulWidget {
  const ShellScreen({super.key});

  @override
  ConsumerState<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends ConsumerState<ShellScreen> {
  static const _screens = [
    MapScreen(),
    ListScreen(),
    ActivityScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Start connectivity listener for auto-sync
    ref.read(networkInfoProvider).onConnectivityChanged.listen((online) {
      if (online) {
        ref.read(landmarkProvider.notifier).syncQueuedVisits();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tab = ref.watch(_tabProvider);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: IndexedStack(index: tab, children: _screens),
      floatingActionButton: tab == 1
          ? FloatingActionButton.extended(
              heroTag: 'add_landmark_fab',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const AddLandmarkScreen()),
              ),
              icon: const Icon(Icons.add_location_alt_outlined),
              label: Text('Add Landmark',
                  style: GoogleFonts.sora(
                      fontWeight: FontWeight.w600, fontSize: 13)),
              backgroundColor: AppTheme.accent,
              foregroundColor: Colors.black,
            )
          : null,
      bottomNavigationBar: _BottomNav(
        currentIndex: tab,
        onTap: (i) => ref.read(_tabProvider.notifier).state = i,
      ),
    );
  }
}

class _BottomNav extends ConsumerWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceCard,
        border: Border(top: BorderSide(color: AppTheme.surfaceElevated, width: 1)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              _NavItem(
                icon: Icons.map_rounded,
                label: 'Map',
                selected: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavItem(
                icon: Icons.explore_rounded,
                label: 'Landmarks',
                selected: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              _NavItem(
                icon: Icons.history_rounded,
                label: 'Activity',
                selected: currentIndex == 2,
                onTap: () => onTap(2),
                badge: _PendingBadge(),
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
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget? badge;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppTheme.accent.withOpacity(0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: selected
                          ? AppTheme.accent
                          : AppTheme.onSurfaceMuted,
                      size: 22,
                    ),
                  ),
                  if (badge != null)
                    Positioned(top: 2, right: 2, child: badge!),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected
                      ? AppTheme.accent
                      : AppTheme.onSurfaceMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PendingBadge extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<int>(
      future: ref.read(landmarkRepositoryProvider).getPendingVisitCount(),
      builder: (_, snap) {
        final count = snap.data ?? 0;
        if (count == 0) return const SizedBox.shrink();
        return Container(
          width: 14,
          height: 14,
          decoration: const BoxDecoration(
            color: AppTheme.accent,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$count',
              style: GoogleFonts.jetBrainsMono(
                  fontSize: 8,
                  color: Colors.black,
                  fontWeight: FontWeight.w700),
            ),
          ),
        );
      },
    );
  }
}
