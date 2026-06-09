import 'package:flutter_test/flutter_test.dart';
import 'package:play_smart/profiles/services/trust_badge_service.dart';
import 'package:play_smart/shared/types/domain_types.dart';

void main() {
  group('TrustBadgeService', () {
    late TrustBadgeService service;

    setUp(() {
      service = TrustBadgeService();
    });

    test('self-reported achievement needs coach endorsement', () {
      final achievement = Achievement(
        id: 'ach-1',
        title: 'Test Achievement',
        badgeLevel: TrustBadgeLevel.selfReported,
      );

      final action = service.getUpgradeAction(achievement);
      expect(action, BadgeUpgradeAction.requestCoachEndorsement);
    });

    test('coach-endorsed achievement needs club verification', () {
      final achievement = Achievement(
        id: 'ach-1',
        title: 'Test Achievement',
        badgeLevel: TrustBadgeLevel.coachEndorsed,
      );

      final action = service.getUpgradeAction(achievement);
      expect(action, BadgeUpgradeAction.requestClubVerification);
    });

    test('club-verified achievement is at max level', () {
      final achievement = Achievement(
        id: 'ach-1',
        title: 'Test Achievement',
        badgeLevel: TrustBadgeLevel.clubVerified,
      );

      final action = service.getUpgradeAction(achievement);
      expect(action, BadgeUpgradeAction.alreadyMaxLevel);
    });

    test('non-athlete can endorse self-reported achievement', () {
      final achievement = Achievement(
        id: 'ach-1',
        title: 'Test Achievement',
        badgeLevel: TrustBadgeLevel.selfReported,
      );

      final upgraded = service.upgradeBadge(
        achievement: achievement,
        actorRole: AccountRole.recruiter, // coach/scout account
        actorId: 'coach-1',
        actorName: 'Coach Wasswa',
      );

      expect(upgraded.badgeLevel, TrustBadgeLevel.coachEndorsed);
      expect(upgraded.endorsedById, 'coach-1');
      expect(upgraded.endorsedByName, 'Coach Wasswa');
    });

    test('athlete cannot self-endorse own achievement', () {
      final achievement = Achievement(
        id: 'ach-1',
        title: 'Test Achievement',
        badgeLevel: TrustBadgeLevel.selfReported,
      );

      expect(
        () => service.upgradeBadge(
          achievement: achievement,
          actorRole: AccountRole.athlete,
          actorId: 'athlete-1',
          actorName: 'Self',
        ),
        throwsA(isA<BadgeUpgradeException>()),
      );
    });

    test('club can verify coach-endorsed achievement', () {
      final achievement = Achievement(
        id: 'ach-1',
        title: 'Test Achievement',
        badgeLevel: TrustBadgeLevel.coachEndorsed,
        endorsedById: 'coach-1',
        endorsedByName: 'Coach Wasswa',
      );

      final upgraded = service.upgradeBadge(
        achievement: achievement,
        actorRole: AccountRole.club,
        actorId: 'club-1',
        actorName: 'Express FC',
      );

      expect(upgraded.badgeLevel, TrustBadgeLevel.clubVerified);
      expect(upgraded.endorsedById, 'club-1');
      expect(upgraded.endorsedByName, 'Express FC');
    });

    test('non-club cannot verify coach-endorsed achievement', () {
      final achievement = Achievement(
        id: 'ach-1',
        title: 'Test Achievement',
        badgeLevel: TrustBadgeLevel.coachEndorsed,
      );

      expect(
        () => service.upgradeBadge(
          achievement: achievement,
          actorRole: AccountRole.recruiter,
          actorId: 'recruiter-1',
          actorName: 'James',
        ),
        throwsA(isA<BadgeUpgradeException>()),
      );
    });

    test('club-verified achievement cannot be upgraded further', () {
      final achievement = Achievement(
        id: 'ach-1',
        title: 'Test Achievement',
        badgeLevel: TrustBadgeLevel.clubVerified,
      );

      expect(
        () => service.upgradeBadge(
          achievement: achievement,
          actorRole: AccountRole.club,
          actorId: 'club-1',
          actorName: 'Express FC',
        ),
        throwsA(isA<BadgeUpgradeException>()),
      );
    });

    test('getProfileBadgeLevel returns highest badge level', () {
      final achievements = [
        Achievement(id: '1', title: 'A', badgeLevel: TrustBadgeLevel.selfReported),
        Achievement(id: '2', title: 'B', badgeLevel: TrustBadgeLevel.coachEndorsed),
        Achievement(id: '3', title: 'C', badgeLevel: TrustBadgeLevel.selfReported),
      ];

      expect(service.getProfileBadgeLevel(achievements), TrustBadgeLevel.coachEndorsed);
    });

    test('getProfileBadgeLevel returns self-reported for empty list', () {
      expect(service.getProfileBadgeLevel([]), TrustBadgeLevel.selfReported);
    });
  });
}