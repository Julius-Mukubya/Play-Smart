import 'package:play_smart/shared/types/domain_types.dart';

/// Mock/In-memory Payment repository — ready to be wired up with Firebase Firestore.
class PaymentRepository {
  Future<List<SubscriptionPlan>> getPlans({AccountRole? forRole}) async {
    return [];
  }

  Future<SubscriptionPlan?> getPlan(SubscriptionTier tier) async {
    return null;
  }

  Future<List<PaymentTransaction>> getTransactionHistory(String userId) async {
    return [];
  }

  Future<bool> hasFeatureAccess(SubscriptionTier tier, String feature) async {
    return false;
  }

  int getMaxShortlists(SubscriptionTier tier) {
    return 1;
  }
}
