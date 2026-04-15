// lib/presentation/screens/activity/activity_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_theme.dart';
import '../../../domain/entities/visit_entity.dart';
import '../../providers/providers.dart';

class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(visitHistoryProvider);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: AppTheme.surface,
            elevation: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Activity',
                    style: GoogleFonts.sora(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onSurface)),
                Text('Your visit history',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 12, color: AppTheme.onSurfaceMuted)),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: AppTheme.onSurface),
                onPressed: () => ref.invalidate(visitHistoryProvider),
              ),
            ],
          ),

          // Pending sync banner
          _PendingSyncBanner(),

          historyAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: AppTheme.accent),
              ),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(
                child: Text('Error: $e',
                    style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.error)),
              ),
            ),
            data: (history) {
              if (history.isEmpty) {
                return const SliverFillRemaining(child: _EmptyActivity());
              }

              // Group by date
              final grouped = _groupByDate(history);
              final dates = grouped.keys.toList();

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) {
                    final date = dates[i];
                    final visits = grouped[date]!;
                    return _DateGroup(
                      date: date,
                      visits: visits,
                      groupIndex: i,
                    );
                  },
                  childCount: dates.length,
                ),
              );
            },
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Map<String, List<VisitEntity>> _groupByDate(List<VisitEntity> visits) {
    final map = <String, List<VisitEntity>>{};
    for (final v in visits) {
      final key = DateFormat('MMMM d, yyyy').format(v.visitTime);
      map.putIfAbsent(key, () => []).add(v);
    }
    return map;
  }
}

class _PendingSyncBanner extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SliverToBoxAdapter(
      child: FutureBuilder<int>(
        future: ref.read(landmarkRepositoryProvider).getPendingVisitCount(),
        builder: (_, snap) {
          final count = snap.data ?? 0;
          if (count == 0) return const SizedBox.shrink();
          return Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.cloud_upload_outlined,
                    color: AppTheme.accent, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '$count visit${count > 1 ? 's' : ''} pending sync',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 13, color: AppTheme.accent),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    await ref
                        .read(landmarkProvider.notifier)
                        .syncQueuedVisits();
                    ref.invalidate(visitHistoryProvider);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.accent,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  child: Text('Sync Now',
                      style: GoogleFonts.sora(
                          fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1);
        },
      ),
    );
  }
}

class _DateGroup extends StatelessWidget {
  final String date;
  final List<VisitEntity> visits;
  final int groupIndex;

  const _DateGroup({
    required this.date,
    required this.visits,
    required this.groupIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            date,
            style: GoogleFonts.sora(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.onSurfaceMuted,
              letterSpacing: 0.3,
            ),
          ),
        ),
        ...visits.asMap().entries.map(
              (entry) => _VisitTile(
                visit: entry.value,
                index: groupIndex * 10 + entry.key,
              ),
            ),
      ],
    );
  }
}

class _VisitTile extends StatelessWidget {
  final VisitEntity visit;
  final int index;

  const _VisitTile({required this.visit, required this.index});

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('h:mm a').format(visit.visitTime);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surfaceElevated, width: 1),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: visit.synced
                ? AppTheme.primary.withOpacity(0.15)
                : AppTheme.accent.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            visit.synced
                ? Icons.check_circle_outline_rounded
                : Icons.cloud_upload_outlined,
            color:
                visit.synced ? AppTheme.primary : AppTheme.accent,
            size: 22,
          ),
        ),
        title: Text(
          visit.landmarkName,
          style: GoogleFonts.sora(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.onSurface,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Icon(Icons.access_time, size: 11, color: AppTheme.onSurfaceMuted),
              const SizedBox(width: 4),
              Text(timeStr,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 11, color: AppTheme.onSurfaceMuted)),
              if (visit.distance > 0) ...[
                const SizedBox(width: 10),
                Icon(Icons.straighten_outlined,
                    size: 11, color: AppTheme.onSurfaceMuted),
                const SizedBox(width: 4),
                Text(
                  '${visit.distance.toStringAsFixed(2)} km away',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 11, color: AppTheme.onSurfaceMuted),
                ),
              ],
            ],
          ),
        ),
        trailing: visit.synced
            ? null
            : Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Pending',
                  style: GoogleFonts.jetBrainsMono(
                      fontSize: 10, color: AppTheme.accent),
                ),
              ),
      ),
    )
        .animate(delay: Duration(milliseconds: index * 50))
        .fadeIn(duration: 300.ms)
        .slideX(begin: -0.05, end: 0, duration: 300.ms);
  }
}

class _EmptyActivity extends StatelessWidget {
  const _EmptyActivity();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.history_rounded,
                size: 44, color: AppTheme.onSurfaceMuted),
          ),
          const SizedBox(height: 20),
          Text('No visits yet',
              style: GoogleFonts.sora(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onSurface)),
          const SizedBox(height: 8),
          Text('Visit a landmark to see your history here',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13, color: AppTheme.onSurfaceMuted)),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.95, 0.95));
  }
}
