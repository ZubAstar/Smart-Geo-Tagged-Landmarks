// lib/presentation/screens/list/list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_theme.dart';
import '../../providers/providers.dart';
import '../../widgets/filter_sheet.dart';
import '../../widgets/landmark_card.dart';

class ListScreen extends ConsumerWidget {
  const ListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(landmarkProvider);
    final filtered = ref.watch(filteredLandmarksProvider);
    final filter = ref.watch(landmarkFilterProvider);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── App Bar ──────────────────────────────────────────────────────
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: AppTheme.surface,
            elevation: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Landmarks',
                    style: GoogleFonts.sora(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onSurface)),
                Text('Bangladesh · ${filtered.length} spots',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 12, color: AppTheme.onSurfaceMuted)),
              ],
            ),
            actions: [
              // Sync indicator
              Consumer(builder: (_, ref, __) {
                final conn = ref.watch(connectivityProvider);
                return conn.when(
                  data: (online) => online
                      ? const SizedBox.shrink()
                      : Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Chip(
                            label: Text('Offline',
                                style: GoogleFonts.jetBrainsMono(
                                    fontSize: 10, color: AppTheme.error)),
                            backgroundColor: AppTheme.error.withOpacity(0.1),
                            side: BorderSide(
                                color: AppTheme.error.withOpacity(0.3)),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                );
              }),
              IconButton(
                icon: const Icon(Icons.tune_rounded, color: AppTheme.onSurface),
                onPressed: () => showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  isScrollControlled: true,
                  builder: (_) => const FilterSheet(),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: AppTheme.onSurface),
                onPressed: () => ref.read(landmarkProvider.notifier).loadLandmarks(),
              ),
            ],
          ),

          // ── Active Filters Banner ─────────────────────────────────────────
          if (filter.minScore > 0)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppTheme.accent.withOpacity(0.25), width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.filter_alt_rounded,
                        size: 14, color: AppTheme.accent),
                    const SizedBox(width: 6),
                    Text(
                      'Min score: ${filter.minScore.toStringAsFixed(1)}',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 12, color: AppTheme.accent),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => ref
                          .read(landmarkFilterProvider.notifier)
                          .state = filter.copyWith(minScore: 0),
                      child: Text('Clear',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: AppTheme.accent,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ),

          // ── Body ──────────────────────────────────────────────────────────
          if (state.isLoading)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => const _ShimmerCard(),
                childCount: 5,
              ),
            )
          else if (state.error != null && filtered.isEmpty)
            SliverFillRemaining(
              child: _ErrorView(
                message: state.error!,
                onRetry: () =>
                    ref.read(landmarkProvider.notifier).loadLandmarks(),
              ),
            )
          else if (filtered.isEmpty)
            const SliverFillRemaining(child: _EmptyView())
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) {
                  final landmark = filtered[i];
                  return LandmarkCard(
                    landmark: landmark,
                    index: i,
                    onVisit: () async {
                      final msg = await ref
                          .read(landmarkProvider.notifier)
                          .visitLandmark(landmark.id, landmark.title);
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(
                            content: Text(msg),
                            backgroundColor: msg.contains('km') || msg.contains('queued')
                                ? AppTheme.success
                                : AppTheme.error,
                          ),
                        );
                      }
                    },
                    onDelete: () async {
                      final confirm = await _confirmDelete(ctx, landmark.title);
                      if (confirm == true && ctx.mounted) {
                        final msg = await ref
                            .read(landmarkProvider.notifier)
                            .deleteLandmark(landmark.id);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text(msg),
                              action: SnackBarAction(
                                label: 'Undo',
                                textColor: AppTheme.accent,
                                onPressed: () => ref
                                    .read(landmarkProvider.notifier)
                                    .restoreLandmark(landmark.id),
                              ),
                            ),
                          );
                        }
                      }
                    },
                  );
                },
                childCount: filtered.length,
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext ctx, String title) {
    return showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Remove Landmark',
            style: GoogleFonts.sora(color: AppTheme.onSurface, fontSize: 18)),
        content: Text(
          'Remove "$title" from the list? You can restore it later.',
          style: GoogleFonts.plusJakartaSans(
              color: AppTheme.onSurfaceMuted, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: GoogleFonts.plusJakartaSans(color: AppTheme.onSurfaceMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: Text('Remove',
                style: GoogleFonts.sora(
                    color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  const _ShimmerCard();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppTheme.surfaceCard,
      highlightColor: AppTheme.surfaceElevated,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        height: 220,
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.wifi_off_rounded,
                  color: AppTheme.error, size: 40),
            ),
            const SizedBox(height: 16),
            Text('Connection Error',
                style: GoogleFonts.sora(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.onSurface)),
            const SizedBox(height: 8),
            Text(message,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 13, color: AppTheme.onSurfaceMuted),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.explore_off_rounded,
              size: 48, color: AppTheme.onSurfaceMuted),
          const SizedBox(height: 16),
          Text('No landmarks found',
              style: GoogleFonts.sora(
                  fontSize: 16, color: AppTheme.onSurfaceMuted)),
          const SizedBox(height: 8),
          Text('Try adjusting filters',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13, color: AppTheme.onSurfaceMuted)),
        ],
      ),
    );
  }
}
