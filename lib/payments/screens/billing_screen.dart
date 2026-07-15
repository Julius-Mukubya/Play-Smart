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
///
/// Plans and transaction history are read from Supabase. Subscribing and
/// purchasing a Post Boost are not wired to a real payment flow yet — there
/// is no deployed payment-provider webhook to create the transaction/
/// subscription rows (see `lib/supabase-integration.md` section 7), so those
/// actions surface a "coming soon" message instead of pretending to succeed.
class BillingScreen extends ConsumerStatefulWidget {
  const BillingScreen({super.key});

  @override
  ConsumerState<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends ConsumerState<BillingScreen> {
  List<SubscriptionPlan> _plans = [];
  List<PaymentTransaction> _transactions = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final auth = ref.read(authProvider);
    if (auth is! AuthAuthenticated) {
      setState(() => _isLoading = false);
      return;
    }
    final repo = ref.read(paymentRepositoryProvider);
    try {
      final plans = await repo.getPlans(forRole: auth.user.role);
      final transactions = await repo.getTransactionHistory(auth.user.id);
      if (!mounted) return;
      setState(() {
        _plans = plans;
        _transactions = transactions;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showComingSoon(String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$action isn\'t available yet — payment provider integration is in progress.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = ref.watch(authProvider);

    if (auth is! AuthAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('Billing')),
        body: Center(child: Text('Please sign in to manage billing.', style: theme.textTheme.bodyMedium)),
      );
    }

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Billing & Subscription')),
        body: Center(child: Text('Could not load billing info: $_error')),
      );
    }

    final user = auth.user;

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
          ..._plans.where((p) => p.tier != SubscriptionTier.free).map((plan) => Card(
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
                        onPressed: () => _showComingSoon('Subscribing'),
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
                      onPressed: () => _showComingSoon('Post Boost'),
                      child: const Text('Boost'),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Transaction history
          if (_transactions.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('Transaction History', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            ..._transactions.map((tx) => Card(
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
}
