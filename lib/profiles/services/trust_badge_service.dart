import 'package:play_smart/shared/types/domain_types.dart';

/// Trust Badge service — enforces badge upgrade rules.
/// Invariant: Badges are never self-assigned by the athlete.
/// Each level requires the correct external actor to trigger.
class TrustBadgeService {
  /// Determine if an achievement can be upgraded from its current level.
  /// Returns the action needed to upgrade.
  BadgeUpgradeAction getUpgradeAction(Achievement achievement) {
    return switch (achievement.badgeLevel) {
      TrustBadgeLevel.selfReported => BadgeUpgradeAction.requestCoachEndorsement,
      TrustBadgeLevel.coachEndorsed => BadgeUpgradeAction.requestClubVerification,
      TrustBadgeLevel.clubVerified => BadgeUpgradeAction.alreadyMaxLevel,
    };
  }

  /// Upgrade an achievement to the next badge level.
  /// This should only be called by the appropriate external actor:
  /// - Self-Reported → Coach-Endorsed: called by a verified coach account
  /// - Coach-Endorsed → Club-Verified: called by a verified club account
  Achievement upgradeBadge({
    required Achievement achievement,
    required AccountRole actorRole,
    required String actorId,
    required String actorName,
  }) {
    if (achievement.badgeLevel == TrustBadgeLevel.selfReported) {
      if (actorRole != AccountRole.athlete) {
        // Only non-athlete actors (coaches, clubs) can endorse
        return Achievement(
          id: achievement.id,
          title: achievement.title,
          description: achievement.description,
          badgeLevel: TrustBadgeLevel.coachEndorsed,
          endorsedById: actorId,
          endorsedByName: actorName,
          createdAt: achievement.createdAt,
        );
      }
      throw BadgeUpgradeException('Athletes cannot self-endorse achievements.');
    }

    if (achievement.badgeLevel == TrustBadgeLevel.coachEndorsed) {
      if (actorRole == AccountRole.club) {
        return Achievement(
          id: achievement.id,
          title: achievement.title,
          description: achievement.description,
          badgeLevel: TrustBadgeLevel.clubVerified,
          endorsedById: actorId,
          endorsedByName: actorName,
          createdAt: achievement.createdAt,
        );
      }
      throw BadgeUpgradeException('Only clubs can verify achievements to Club-Verified.');
    }

    throw BadgeUpgradeException('This achievement is already at the maximum badge level.');
  }

  /// Get the profile-level badge (highest badge among all achievements).
  TrustBadgeLevel getProfileBadgeLevel(List<Achievement> achievements) {
    if (achievements.isEmpty) return TrustBadgeLevel.selfReported;
    final highest = achievements
        .map((a) => a.badgeLevel.index)
        .reduce((a, b) => a > b ? a : b);
    return TrustBadgeLevel.values[highest];
  }

  /// Check if a user can request an endorsement (for the endorser).
  bool canEndorse(AccountRole actorRole) {
    // Coaches and clubs can endorse. Athletes cannot self-endorse.
    return actorRole == AccountRole.athlete;
  }

  /// Check if a club can verify an achievement.
  bool canVerify(AccountRole actorRole) {
    return actorRole == AccountRole.club;
  }
}

/// Actions that can be taken to upgrade a badge.
enum BadgeUpgradeAction {
  requestCoachEndorsement,
  requestClubVerification,
  alreadyMaxLevel,
}

/// Exception thrown when a badge upgrade is invalid.
class BadgeUpgradeException implements Exception {
  final String message;
  BadgeUpgradeException(this.message);

  @override
  String toString() => message;
}