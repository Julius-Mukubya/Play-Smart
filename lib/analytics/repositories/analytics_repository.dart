import 'package:play_smart/shared/types/domain_types.dart';

/// Mock/In-memory Analytics repository — ready to be wired up with Firebase Firestore/Analytics.
class AnalyticsRepository {
  Future<void> recordView({
    required String athleteId,
    String? viewerId,
    String? viewerName,
  }) async {}

  Future<int> getViewCount(String athleteId) async {
    return 12;
  }

  Future<int> getShortlistCount(String athleteId) async {
    return 3;
  }

  Future<List<AnalyticsEvent>> getFullAnalytics(String athleteId) async {
    return [];
  }
}
