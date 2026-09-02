import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrivacySettings {
  final bool publicProfile;
  final bool showLocation;
  final bool allowMessageRequests;
  final bool showInSearch;
  final bool analyticsOptIn;
  final List<String> blockedUserIds;

  const PrivacySettings({
    this.publicProfile = true,
    this.showLocation = true,
    this.allowMessageRequests = true,
    this.showInSearch = true,
    this.analyticsOptIn = true,
    this.blockedUserIds = const [],
  });

  PrivacySettings copyWith({
    bool? publicProfile,
    bool? showLocation,
    bool? allowMessageRequests,
    bool? showInSearch,
    bool? analyticsOptIn,
    List<String>? blockedUserIds,
  }) {
    return PrivacySettings(
      publicProfile: publicProfile ?? this.publicProfile,
      showLocation: showLocation ?? this.showLocation,
      allowMessageRequests: allowMessageRequests ?? this.allowMessageRequests,
      showInSearch: showInSearch ?? this.showInSearch,
      analyticsOptIn: analyticsOptIn ?? this.analyticsOptIn,
      blockedUserIds: blockedUserIds ?? this.blockedUserIds,
    );
  }
}

class PrivacyNotifier extends Notifier<PrivacySettings> {
  static const _keyPublic = 'privacy_public_profile';
  static const _keyLocation = 'privacy_show_location';
  static const _keyMessages = 'privacy_allow_messages';
  static const _keySearch = 'privacy_show_in_search';
  static const _keyAnalytics = 'privacy_analytics_opt_in';
  static const _keyBlocked = 'privacy_blocked_users';

  @override
  PrivacySettings build() {
    _loadSettings();
    return const PrivacySettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = PrivacySettings(
        publicProfile: prefs.getBool(_keyPublic) ?? true,
        showLocation: prefs.getBool(_keyLocation) ?? true,
        allowMessageRequests: prefs.getBool(_keyMessages) ?? true,
        showInSearch: prefs.getBool(_keySearch) ?? true,
        analyticsOptIn: prefs.getBool(_keyAnalytics) ?? true,
        blockedUserIds: prefs.getStringList(_keyBlocked) ?? [],
      );
    } catch (_) {}
  }

  Future<void> setPublicProfile(bool value) async {
    state = state.copyWith(publicProfile: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPublic, value);
  }

  Future<void> setShowLocation(bool value) async {
    state = state.copyWith(showLocation: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyLocation, value);
  }

  Future<void> setAllowMessageRequests(bool value) async {
    state = state.copyWith(allowMessageRequests: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyMessages, value);
  }

  Future<void> setShowInSearch(bool value) async {
    state = state.copyWith(showInSearch: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySearch, value);
  }

  Future<void> setAnalyticsOptIn(bool value) async {
    state = state.copyWith(analyticsOptIn: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAnalytics, value);
  }

  Future<void> blockUser(String userId) async {
    if (state.blockedUserIds.contains(userId)) return;
    final updated = [...state.blockedUserIds, userId];
    state = state.copyWith(blockedUserIds: updated);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyBlocked, updated);
  }

  Future<void> unblockUser(String userId) async {
    final updated = state.blockedUserIds.where((id) => id != userId).toList();
    state = state.copyWith(blockedUserIds: updated);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyBlocked, updated);
  }

  bool isUserBlocked(String userId) {
    return state.blockedUserIds.contains(userId);
  }
}

final privacyProvider = NotifierProvider<PrivacyNotifier, PrivacySettings>(
  PrivacyNotifier.new,
);
