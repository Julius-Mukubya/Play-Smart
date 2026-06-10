import 'package:play_smart/shared/types/domain_types.dart';
import 'package:play_smart/shared/utils/mock_data.dart';

/// Payment repository — handles subscriptions, transactions, and Post Boost.
class PaymentRepository {
  final List<PaymentTransaction> _transactions = List.from(MockData.transactions);
  final List<SubscriptionPlan> _plans = List.from(MockData.subscriptionPlans);

  /// Get available subscription plans.
  List<SubscriptionPlan> getPlans({AccountRole? forRole}) {
    if (forRole == null) return List.unmodifiable(_plans);
    return _plans.where((p) => _planForRole(p.tier, forRole)).toList();
  }

  bool _planForRole(SubscriptionTier tier, AccountRole role) {
    return switch (role) {
      AccountRole.athlete => tier == SubscriptionTier.free || tier == SubscriptionTier.premiumMonthly || tier == SubscriptionTier.premiumAnnual,
      AccountRole.recruiter => tier == SubscriptionTier.free || tier == SubscriptionTier.recruiterBasic || tier == SubscriptionTier.recruiterPro,
      AccountRole.club => tier == SubscriptionTier.free || tier == SubscriptionTier.clubGrassroots || tier == SubscriptionTier.clubProfessional || tier == SubscriptionTier.clubEnterprise,
      AccountRole.guest => tier == SubscriptionTier.free,
    };
  }

  /// Get a plan by tier.
  SubscriptionPlan? getPlan(SubscriptionTier tier) {
    try {
      return _plans.firstWhere((p) => p.tier == tier);
    } catch (_) {
      return null;
    }
  }

  /// Subscribe to a plan.
  Future<User> subscribe({
    required User user,
    required SubscriptionTier tier,
    required PaymentProvider provider,
    required double amountUgx,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    // Record transaction
    _transactions.add(PaymentTransaction(
      id: 'tx-${DateTime.now().millisecondsSinceEpoch}',
      userId: user.id,
      amountUgx: amountUgx,
      provider: provider,
      description: '${tier.name} subscription',
      success: true,
    ));

    // Return updated user with new tier (mock — no actual persistence)
    return User(
      id: user.id, name: user.name, email: user.email,
      role: user.role, verificationStatus: user.verificationStatus,
      subscriptionTier: tier, dateOfBirth: user.dateOfBirth,
      isUnder18: user.isUnder18, createdAt: user.createdAt,
    );
  }

  /// Purchase a Post Boost.
  Future<PaymentTransaction> purchaseBoost({
    required String userId,
    required PaymentProvider provider,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final tx = PaymentTransaction(
      id: 'tx-${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      amountUgx: 5000, // Fixed boost price
      provider: provider,
      description: 'Post Boost — 7 days promotion',
      success: true,
    );
    _transactions.add(tx);
    return tx;
  }

  /// Get transaction history for a user.
  List<PaymentTransaction> getTransactionHistory(String userId) {
    return _transactions.where((t) => t.userId == userId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Check if a subscription tier grants access to a feature.
  bool hasFeatureAccess(SubscriptionTier tier, String feature) {
    final plan = getPlan(tier);
    if (plan == null) return false;
    return plan.features.any((f) => f.toLowerCase().contains(feature.toLowerCase()));
  }

  /// Get max shortlists for a tier.
  int getMaxShortlists(SubscriptionTier tier) {
    return switch (tier) {
      SubscriptionTier.free => 1,
      SubscriptionTier.premiumMonthly || SubscriptionTier.premiumAnnual => 3,
      SubscriptionTier.recruiterBasic || SubscriptionTier.clubGrassroots => 5,
      SubscriptionTier.recruiterPro || SubscriptionTier.clubProfessional || SubscriptionTier.clubEnterprise => 999,
    };
  }
}