import 'package:play_smart/core/supabase/supabase_config.dart';
import 'package:play_smart/shared/types/domain_types.dart';

/// Payment repository — read-only access to `public.subscription_plans` and
/// `public.payment_transactions`.
///
/// There is intentionally no `subscribe()`/`purchaseBoost()` here: per
/// architecture.md invariant #4 and code-standards.md, subscription/
/// transaction state changes only via a verified payment-provider webhook,
/// never a client call — and as of `lib/supabase-integration.md` section 7,
/// that webhook isn't deployed yet, so there is no real path to create these
/// rows from the app. `BillingScreen` shows plans/history read-only and
/// surfaces a "coming soon" message where the old mock let you "subscribe".
class PaymentRepository {
  static const _plansTable = 'subscription_plans';
  static const _transactionsTable = 'payment_transactions';

  /// Get available subscription plans, optionally filtered to the ones
  /// relevant to a role.
  Future<List<SubscriptionPlan>> getPlans({AccountRole? forRole}) async {
    final rows = await supabase.from(_plansTable).select();
    final plans =
        (rows as List).map((r) => SubscriptionPlan.fromJson(r as Map<String, dynamic>)).toList();
    if (forRole == null) return plans;
    return plans.where((p) => _planForRole(p.tier, forRole)).toList();
  }

  bool _planForRole(SubscriptionTier tier, AccountRole role) {
    return switch (role) {
      AccountRole.athlete => tier == SubscriptionTier.free ||
          tier == SubscriptionTier.premiumMonthly ||
          tier == SubscriptionTier.premiumAnnual,
      AccountRole.recruiter => tier == SubscriptionTier.free ||
          tier == SubscriptionTier.recruiterBasic ||
          tier == SubscriptionTier.recruiterPro,
      AccountRole.club => tier == SubscriptionTier.free ||
          tier == SubscriptionTier.clubGrassroots ||
          tier == SubscriptionTier.clubProfessional ||
          tier == SubscriptionTier.clubEnterprise,
      AccountRole.admin || AccountRole.guest => tier == SubscriptionTier.free,
    };
  }

  Future<SubscriptionPlan?> getPlan(SubscriptionTier tier) async {
    final row = await supabase
        .from(_plansTable)
        .select()
        .eq('tier', tier.toDb())
        .maybeSingle();
    return row != null ? SubscriptionPlan.fromJson(row) : null;
  }

  Future<List<PaymentTransaction>> getTransactionHistory(String userId) async {
    final rows = await supabase
        .from(_transactionsTable)
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((r) => PaymentTransaction.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  /// Check if a subscription tier grants access to a feature, by scanning
  /// its plan's feature list. This is a UI convenience only — actual feature
  /// gating must be enforced server-side (RLS), not derived from this call.
  Future<bool> hasFeatureAccess(SubscriptionTier tier, String feature) async {
    final plan = await getPlan(tier);
    if (plan == null) return false;
    return plan.features.any((f) => f.toLowerCase().contains(feature.toLowerCase()));
  }

  /// Get max shortlists for a tier. Pure lookup — mirrors the limits in
  /// `context/supabase-backend.md`; not itself an enforcement point.
  int getMaxShortlists(SubscriptionTier tier) {
    return switch (tier) {
      SubscriptionTier.free => 1,
      SubscriptionTier.premiumMonthly || SubscriptionTier.premiumAnnual => 3,
      SubscriptionTier.recruiterBasic || SubscriptionTier.clubGrassroots => 5,
      SubscriptionTier.recruiterPro ||
      SubscriptionTier.clubProfessional ||
      SubscriptionTier.clubEnterprise =>
        999,
    };
  }
}
