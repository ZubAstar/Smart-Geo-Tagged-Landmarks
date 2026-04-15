// lib/presentation/widgets/filter_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_theme.dart';
import '../providers/providers.dart';

class FilterSheet extends ConsumerWidget {
  const FilterSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(landmarkFilterProvider);

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Filter & Sort',
              style: GoogleFonts.sora(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.onSurface,
              )),
          const SizedBox(height: 20),
          Text('Minimum Score: ${filter.minScore.toStringAsFixed(1)}',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 14, color: AppTheme.onSurfaceMuted)),
          Slider(
            value: filter.minScore,
            min: 0,
            max: 10,
            divisions: 20,
            activeColor: AppTheme.accent,
            inactiveColor: AppTheme.surfaceElevated,
            onChanged: (v) {
              ref.read(landmarkFilterProvider.notifier).state =
                  filter.copyWith(minScore: v);
            },
          ),
          const SizedBox(height: 16),
          Text('Sort By',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 14, color: AppTheme.onSurfaceMuted)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: SortOrder.values
                .map((s) => _SortChip(sort: s, selected: filter.sortOrder == s))
                .toList(),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Apply', style: GoogleFonts.sora(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SortChip extends ConsumerWidget {
  final SortOrder sort;
  final bool selected;
  const _SortChip({required this.sort, required this.selected});

  String get _label {
    switch (sort) {
      case SortOrder.scoreDesc:
        return 'Score ↓';
      case SortOrder.scoreAsc:
        return 'Score ↑';
      case SortOrder.nameAsc:
        return 'Name A-Z';
      case SortOrder.visitCountDesc:
        return 'Most Visited';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ChoiceChip(
      label: Text(_label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.black : AppTheme.onSurfaceMuted,
          )),
      selected: selected,
      selectedColor: AppTheme.accent,
      backgroundColor: AppTheme.surfaceElevated,
      side: BorderSide.none,
      onSelected: (_) {
        final filter = ref.read(landmarkFilterProvider);
        ref.read(landmarkFilterProvider.notifier).state =
            filter.copyWith(sortOrder: sort);
      },
    );
  }
}
