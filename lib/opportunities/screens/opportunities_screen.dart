import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:play_smart/auth/models/auth_state.dart';
import 'package:play_smart/auth/providers/auth_provider.dart';
import 'package:play_smart/opportunities/providers/opportunity_provider.dart';
import 'package:play_smart/shared/types/domain_types.dart';
import 'package:play_smart/shared/widgets/opportunity_card.dart';

/// Opportunities screen — browse and post trial/open day listings.
class OpportunitiesScreen extends ConsumerStatefulWidget {
  const OpportunitiesScreen({super.key});

  @override
  ConsumerState<OpportunitiesScreen> createState() => _OpportunitiesScreenState();
}

class _OpportunitiesScreenState extends ConsumerState<OpportunitiesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.microtask(() {
      ref.read(opportunityProvider.notifier).loadOpenOpportunities();
      _loadMyPostingsIfNeeded();
    });
  }

  void _loadMyPostingsIfNeeded() {
    final auth = ref.read(authProvider);
    if (auth is AuthAuthenticated &&
        (auth.user.role == AccountRole.recruiter || auth.user.role == AccountRole.club)) {
      ref.read(opportunityProvider.notifier).loadMyPostings();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(opportunityProvider);
    final auth = ref.watch(authProvider);
    final isRecruiterOrClub = auth is AuthAuthenticated &&
        (auth.user.role == AccountRole.recruiter || auth.user.role == AccountRole.club);

    // Show snackbar for success/error messages
    if (state.successMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.successMessage!), backgroundColor: Colors.green),
        );
        ref.read(opportunityProvider.notifier).clearMessages();
      });
    }
    if (state.error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.error!), backgroundColor: Colors.red),
        );
        ref.read(opportunityProvider.notifier).clearMessages();
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Opportunities'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            const Tab(text: 'Browse'),
            if (isRecruiterOrClub) const Tab(text: 'My Postings'),
          ],
        ),
        actions: [
          if (isRecruiterOrClub)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showCreateDialog(context, theme),
            ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBrowseTab(context, theme, state),
          if (isRecruiterOrClub) _buildMyPostingsTab(context, theme, state),
        ],
      ),
    );
  }

  Widget _buildBrowseTab(BuildContext context, ThemeData theme, OpportunityState state) {
    if (state.isLoading) return const Center(child: CircularProgressIndicator());

    if (state.opportunities.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.event_busy, size: 64, color: theme.colorScheme.outline),
              const SizedBox(height: 16),
              Text('No open opportunities', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text('Check back later for new trial and open day listings.', style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(opportunityProvider.notifier).loadOpenOpportunities(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: state.opportunities.length,
        itemBuilder: (ctx, i) {
          final opp = state.opportunities[i];
          final auth = ref.read(authProvider);
          final isAthlete = auth is AuthAuthenticated && auth.user.role == AccountRole.athlete;
          return OpportunityCard(
            opportunity: opp,
            showApplyAction: isAthlete,
            onApply: () => _showApplyDialog(context, theme, opp),
          );
        },
      ),
    );
  }

  Widget _buildMyPostingsTab(BuildContext context, ThemeData theme, OpportunityState state) {
    if (state.isLoading) return const Center(child: CircularProgressIndicator());

    if (state.myPostings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle_outline, size: 64, color: theme.colorScheme.outline),
              const SizedBox(height: 16),
              Text('No postings yet', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text('Create a trial or open day opportunity for athletes.', style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _showCreateDialog(context, theme),
                icon: const Icon(Icons.add),
                label: const Text('Create Posting'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: state.myPostings.length,
      itemBuilder: (ctx, i) {
        final opp = state.myPostings[i];
        return Column(
          children: [
            OpportunityCard(opportunity: opp),
            if (!opp.isClosed)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _viewApplications(context, opp.id),
                        icon: const Icon(Icons.people, size: 18),
                        label: const Text('View Applications'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => ref.read(opportunityProvider.notifier).closeOpportunity(opp.id),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Close'),
                      style: OutlinedButton.styleFrom(foregroundColor: theme.colorScheme.error),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  void _showCreateDialog(BuildContext context, ThemeData theme) {
    final titleCtrl = TextEditingController();
    final sportCtrl = TextEditingController();
    final positionCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    int capacity = 0;
    DateTime? selectedDate;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Opportunity'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title', hintText: 'e.g. Open Trials')),
              const SizedBox(height: 8),
              TextField(controller: sportCtrl, decoration: const InputDecoration(labelText: 'Sport', hintText: 'e.g. Football')),
              const SizedBox(height: 8),
              TextField(controller: positionCtrl, decoration: const InputDecoration(labelText: 'Position (optional)', hintText: 'e.g. Striker')),
              const SizedBox(height: 8),
              TextField(controller: locationCtrl, decoration: const InputDecoration(labelText: 'Location', hintText: 'e.g. Kampala')),
              const SizedBox(height: 8),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description', hintText: 'Details about the opportunity'), maxLines: 2),
              const SizedBox(height: 8),
              TextField(
                decoration: const InputDecoration(labelText: 'Capacity', hintText: 'Max applicants'),
                keyboardType: TextInputType.number,
                onChanged: (v) => capacity = int.tryParse(v) ?? 0,
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(context: context, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                  if (date != null) selectedDate = date;
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(border: Border.all(color: theme.colorScheme.outlineVariant), borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [Icon(Icons.calendar_today), const SizedBox(width: 8), Text(selectedDate != null ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}' : 'Select date (optional)')]),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (titleCtrl.text.trim().isEmpty) return;
              final auth = ref.read(authProvider);
              if (auth is! AuthAuthenticated) return;
              final now = DateTime.now();
              ref.read(opportunityProvider.notifier).createOpportunity(
                Opportunity(
                  id: 'opp-${now.millisecondsSinceEpoch}',
                  creatorId: auth.user.id,
                  creatorRole: auth.user.role,
                  title: titleCtrl.text.trim(),
                  sport: sportCtrl.text.trim(),
                  position: positionCtrl.text.trim().isEmpty ? null : positionCtrl.text.trim(),
                  location: locationCtrl.text.trim().isEmpty ? null : locationCtrl.text.trim(),
                  date: selectedDate,
                  description: descCtrl.text.trim(),
                  capacity: capacity > 0 ? capacity : 0,
                ),
              );
              Navigator.pop(ctx);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showApplyDialog(BuildContext context, ThemeData theme, Opportunity opp) {
    final msgCtrl = TextEditingController();
    final auth = ref.read(authProvider);
    final name = auth is AuthAuthenticated ? auth.user.name : '';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Apply: ${opp.title}'),
        content: TextField(controller: msgCtrl, decoration: const InputDecoration(hintText: 'Optional message...'), maxLines: 2),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              ref.read(opportunityProvider.notifier).apply(opp.id, name, message: msgCtrl.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('Submit Application'),
          ),
        ],
      ),
    );
  }

  void _viewApplications(BuildContext context, String opportunityId) {
    ref.read(opportunityProvider.notifier).loadApplications(opportunityId);
    Navigator.push(context, MaterialPageRoute(builder: (_) => _ApplicationsScreen(opportunityId: opportunityId)));
  }
}

class _ApplicationsScreen extends ConsumerWidget {
  final String opportunityId;
  const _ApplicationsScreen({required this.opportunityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(opportunityProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Applications')),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.applications.isEmpty
              ? Center(child: Text('No applications yet.', style: theme.textTheme.bodyMedium))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.applications.length,
                  itemBuilder: (ctx, i) {
                    final app = state.applications[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(child: Text(app.athleteName.isNotEmpty ? app.athleteName[0].toUpperCase() : '?')),
                        title: Text(app.athleteName),
                        subtitle: app.message.isNotEmpty ? Text(app.message, maxLines: 2, overflow: TextOverflow.ellipsis) : null,
                        trailing: app.accepted
                            ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
                            : ElevatedButton(
                                onPressed: () => ref.read(opportunityProvider.notifier).loadApplications(opportunityId),
                                child: const Text('Accept'),
                              ),
                      ),
                    );
                  },
                ),
    );
  }
}