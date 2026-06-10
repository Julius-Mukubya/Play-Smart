import 'package:play_smart/shared/types/domain_types.dart';
import 'package:play_smart/shared/utils/mock_data.dart';

/// Analytics repository — handles profile view tracking and analytics queries.
class AnalyticsRepository {
  final List<AnalyticsEvent> _events = List.from(MockData.analyticsEvents);

  /// Record a profile view event.
  Future<AnalyticsEvent> recordView({
    required String athleteId,
    String? viewerId,
    String? viewerName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final event = AnalyticsEvent(
      id: 'ae-${DateTime.now().millisecondsSinceEpoch}',
      athleteId: athleteId,
      viewerId: viewerId,
      viewerName: viewerName,
      eventType: 'view',
    );
    _events.add(event);
    return event;
  }

  /// Record a shortlist event.
  Future<AnalyticsEvent> recordShortlist({
    required String athleteId,
    required String viewerId,
    required String viewerName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final event = AnalyticsEvent(
      id: 'ae-${DateTime.now().millisecondsSinceEpoch}',
      athleteId: athleteId,
      viewerId: viewerId,
      viewerName: viewerName,
      eventType: 'shortlist',
    );
    _events.add(event);
    return event;
  }

  /// Get view count for an athlete (free tier — aggregate only).
  int getViewCount(String athleteId) {
    return _events.where((e) => e.athleteId == athleteId && e.eventType == 'view').length;
  }

  /// Get shortlist count for an athlete.
  int getShortlistCount(String athleteId) {
    return _events.where((e) => e.athleteId == athleteId && e.eventType == 'shortlist').length;
  }

  /// Get full analytics events for an athlete (premium tier — includes viewer identity).
  List<AnalyticsEvent> getFullAnalytics(String athleteId) {
    return _events.where((e) => e.athleteId == athleteId).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Get recent (anonymous) views for free tier.
  int getRecentViewCount(String athleteId, {Duration within = const Duration(days: 7)}) {
    final cutoff = DateTime.now().subtract(within);
    return _events.where((e) =>
        e.athleteId == athleteId &&
        e.eventType == 'view' &&
        e.timestamp.isAfter(cutoff)).length;
  }

  /// Get unique viewers (premium tier).
  int getUniqueViewerCount(String athleteId) {
    return _events
        .where((e) => e.athleteId == athleteId && e.eventType == 'view' && e.viewerId != null)
        .map((e) => e.viewerId)
        .toSet()
        .length;
  }
}