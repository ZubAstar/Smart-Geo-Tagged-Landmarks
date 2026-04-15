// lib/presentation/widgets/landmark_card.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/constants/app_theme.dart';
import '../../domain/entities/landmark_entity.dart';

class LandmarkCard extends StatelessWidget {
  final LandmarkEntity landmark;
  final VoidCallback? onVisit;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;
  final int index;

  const LandmarkCard({
    super.key,
    required this.landmark,
    this.onVisit,
    this.onDelete,
    this.onTap,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.surfaceElevated, width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image banner
              _ImageBanner(imageUrl: landmark.image),

              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            landmark.title,
                            style: GoogleFonts.sora(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.onSurface,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _ScoreBadge(score: landmark.score),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _StatChip(
                          icon: Icons.place_outlined,
                          label: landmark.scoreLabel,
                          color: _scoreColor(landmark.score),
                        ),
                        const SizedBox(width: 8),
                        _StatChip(
                          icon: Icons.people_outline,
                          label: '${landmark.visitCount} visits',
                          color: AppTheme.onSurfaceMuted,
                        ),
                        if (landmark.avgDistance > 0) ...[
                          const SizedBox(width: 8),
                          _StatChip(
                            icon: Icons.straighten_outlined,
                            label: '${landmark.avgDistance.toStringAsFixed(1)} km',
                            color: AppTheme.onSurfaceMuted,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onVisit,
                            icon: const Icon(Icons.my_location, size: 15),
                            label: const Text('Visit'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.accent,
                              side: const BorderSide(color: AppTheme.accent),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              textStyle: GoogleFonts.sora(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: onDelete,
                          icon: const Icon(Icons.delete_outline, size: 18),
                          style: IconButton.styleFrom(
                            foregroundColor: AppTheme.error,
                            backgroundColor: AppTheme.error.withOpacity(0.08),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: index * 60))
        .fadeIn(duration: 350.ms)
        .slideY(begin: 0.1, end: 0, duration: 350.ms, curve: Curves.easeOut);
  }

  Color _scoreColor(double score) {
    if (score >= 6.5) return AppTheme.scoreHigh;
    if (score >= 3.0) return AppTheme.scoreMid;
    return AppTheme.scoreLow;
  }
}

class _ImageBanner extends StatelessWidget {
  final String? imageUrl;
  const _ImageBanner({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return Container(
        height: 130,
        color: AppTheme.surfaceElevated,
        child: const Center(
          child: Icon(Icons.landscape, size: 40, color: AppTheme.onSurfaceMuted),
        ),
      );
    }
    return CachedNetworkImage(
      imageUrl: imageUrl!,
      height: 130,
      width: double.infinity,
      fit: BoxFit.cover,
      placeholder: (_, __) => Shimmer.fromColors(
        baseColor: AppTheme.surfaceElevated,
        highlightColor: AppTheme.surfaceCard,
        child: Container(height: 130, color: AppTheme.surfaceElevated),
      ),
      errorWidget: (_, __, ___) => Container(
        height: 130,
        color: AppTheme.surfaceElevated,
        child: const Center(
          child: Icon(Icons.broken_image_outlined, size: 36, color: AppTheme.onSurfaceMuted),
        ),
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  final double score;
  const _ScoreBadge({required this.score});

  Color get _color {
    if (score >= 6.5) return AppTheme.scoreHigh;
    if (score >= 3.0) return AppTheme.scoreMid;
    return AppTheme.scoreLow;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _color.withOpacity(0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: 13, color: _color),
          const SizedBox(width: 3),
          Text(
            score.toStringAsFixed(1),
            style: GoogleFonts.jetBrainsMono(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _color,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _StatChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
