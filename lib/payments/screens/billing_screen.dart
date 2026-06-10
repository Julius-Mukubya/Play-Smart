import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:play_smart/auth/models/auth_state.dart';
import 'package:play_smart/auth/providers/auth_provider.dart';
import 'package:play_smart/payments/repositories/payment_repository.dart';
import 'package:play_smart/shared/types/domain_types.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepository();
});

/// Billing and subscription management screen.
class BillingScreen extends ConsumerWidget {
  const BillingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final auth = ref.watch(authProvider);
    final repo = ref.read(paymentRepositoryProvider);
    final txRepo = ref.read(paymentRepositoryProvider);

    if (auth is! AuthAuthenticated) {
      return Scaffold(appBar: AppBar(title: const Text('Billing')),
        body: Center(child: Text('Please sign in to manage billing.', style: theme.textTheme.bodyMedium)));
    }

    final user = auth.user;
    final plans = repo.getPlans(forRole: user.role);
    final transactions = txRepo.getTransactionHistory(user.id);

    return Scaffold(
      appBar: AppBar(title: const Text('Billing & Subscription')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Current plan
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Current Plan', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  _tierName(user.subscriptionTier),
                  style: theme.textTheme.headlineMedium?.copyWith(color: theme.colorScheme.primary),
                ),
                const SizedBox(height: 4),
                Text(_tierDescription(user.subscriptionTier), style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Available plans
          Text('Available Plans', style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          ...plans.where((p) => p.tier != SubscriptionTier.free).map((plan) => Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(plan.name, style: theme.textTheme.titleMedium),
                      ),
                      if (plan.isPopular)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('Popular', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('UGX ${plan.priceUgx.toStringAsFixed(0)}/mo', style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  ...plan.features.map((f) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(children: [
                      Icon(Icons.check, size: 16, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(child: Text(f, style: theme.textTheme.bodyMedium)),
                    ]),
                  )),
                  const SizedBox(height: 12),
                  if (user.subscriptionTier != plan.tier)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _subscribe(context, ref, user, plan.tier),
                        child: Text(plan.priceUgx > 0 ? 'Subscribe — UGX ${plan.priceUgx.toStringAsFixed(0)}' : 'Switch to Free'),
                      ),
                    ),
                ],
              ),
            ),
          )),

          // Post Boost (athletes only)
          if (user.role == AccountRole.athlete) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.rocket_launch, color: theme.colorScheme.primary, size: 32),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Post Boost', style: theme.textTheme.titleMedium),
                          Text('Promote a post to the top of recruiter feeds for 7 days. UGX 5,000', style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => _purchaseBoost(context, ref, user),
                      child: const Text('Boost'),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Transaction history
          if (transactions.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('Transaction History', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            ...transactions.map((tx) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(tx.success ? Icons.check_circle : Icons.cancel,
                  color: tx.success ? theme.colorScheme.primary : theme.colorScheme.error),
                title: Text(tx.description, style: theme.textTheme.bodyMedium),
                subtitle: Text('UGX ${tx.amountUgx.toStringAsFixed(0)} — ${tx.provider.name}', style: theme.textTheme.bodySmall),
                trailing: Text('${tx.createdAt.day}/${tx.createdAt.month}', style: theme.textTheme.bodySmall),
              ),
            )),
          ],
        ],
      ),
    );
  }

  String _tierName(SubscriptionTier tier) {
    return switch (tier) {
      SubscriptionTier.free => 'Free',
      SubscriptionTier.premiumMonthly => 'Premium Monthly',
      SubscriptionTier.premiumAnnual => 'Premium Annual',
      SubscriptionTier.recruiterBasic => 'Recruiter Basic',
      SubscriptionTier.recruiterPro => 'Recruiter Pro',
      SubscriptionTier.clubGrassroots => 'Club Grassroots',
      SubscriptionTier.clubProfessional => 'Club Professional',
      SubscriptionTier.clubEnterprise => 'Club Enterprise',
    };
  }

  String _tierDescription(SubscriptionTier tier) {
    return switch (tier) {
      SubscriptionTier.free => 'Basic access. Upgrade to unlock more features.',
      SubscriptionTier.premiumMonthly || SubscriptionTier.premiumAnnual => 'Full analytics with viewer identity, priority in search, Post Boost access.',
      SubscriptionTier.recruiterBasic => 'Limited shortlists and trials. Upgrade to Pro for unlimited access.',
      SubscriptionTier.recruiterPro => 'Unlimited shortlists, export to PDF, post unlimited trials.',
      SubscriptionTier.clubGrassroots => 'Basic club tools for grassroots organizations.',
      SubscriptionTier.clubProfessional => 'All features including roster confirmation and scout management.',
      SubscriptionTier.clubEnterprise => 'Custom enterprise pricing with dedicated support.',
    };
  }

  void _subscribe(BuildContext context, WidgetRef ref, User user, SubscriptionTier tier) async {
    final repo = ref.read(paymentRepositoryProvider);
    final plan = repo.getPlan(tier);
    if (plan == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Simulating payment of UGX ${plan.priceUgx.toStringAsFixed(0)}...')),
    );

    // Simulate payment delay and subscribe
    final updated = await repo.subscribe(
      user: user,
      tier: tier,
      provider: PaymentProvider.mtnMobileMoney,
      amountUgx: plan.priceUgx,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Subscribed to ${plan.name}!'), backgroundColor: Colors.green),
      );
    }
  }

  void _purchaseBoost(BuildContext context, WidgetRef ref, User user) async {
    final repo = ref.read(paymentRepositoryProvider);
    await repo.purchaseBoost(userId: user.id, provider: PaymentProvider.mtnMobileMoney);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Post Boost activated! Your post will be promoted for 7 days.'), backgroundColor: Colors.green),
      );
    }
  }
}