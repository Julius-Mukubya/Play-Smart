import 'package:flutter/material.dart';
import 'package:play_smart/core/theme/app_theme.dart';
import 'package:play_smart/shared/types/domain_types.dart';

/// Shared Trust Badge component used across the app.
/// Displays the trust level of an achievement or the overall profile.
class TrustBadge extends StatelessWidget {
  final TrustBadgeLevel level;
  final BadgeSize size;

  const TrustBadge({
    super.key,
    required this.level,
    this.size = BadgeSize.md,
  });

  @override
  Widget build(BuildContext context) {
    if (level == TrustBadgeLevel.selfReported) {
      return const SizedBox.shrink();
    }
    final (label, color) = switch (level) {
      TrustBadgeLevel.selfReported => ('Self-Reported', AppColors.badgeSelf),
      TrustBadgeLevel.coachEndorsed => ('Coach-Endorsed', AppColors.badgeCoach),
      TrustBadgeLevel.clubVerified => ('Club-Verified', AppColors.badgeClub),
    };

    final iconSize = size == BadgeSize.sm ? 12.0 : 16.0;
    final fontSize = size == BadgeSize.sm ? 10.0 : 12.0;
    final padding = size == BadgeSize.sm ? const EdgeInsets.symmetric(horizontal: 8, vertical: 2) : const EdgeInsets.symmetric(horizontal: 12, vertical: 4);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified, size: iconSize, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

enum BadgeSize { sm, md }