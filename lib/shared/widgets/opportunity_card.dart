import 'package:flutter/material.dart';
import 'package:play_smart/shared/types/domain_types.dart';

/// Shared OpportunityCard component used across the app.
class OpportunityCard extends StatelessWidget {
  final Opportunity opportunity;
  final bool showApplyAction;
  final VoidCallback? onApply;

  const OpportunityCard({
    super.key,
    required this.opportunity,
    this.showApplyAction = false,
    this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isClosed = opportunity.isClosed;
    final remaining = opportunity.capacity - opportunity.applicationCount;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(opportunity.title, style: theme.textTheme.titleMedium),
                ),
                if (isClosed)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('Closed', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)),
                  )
                else if (remaining <= 5)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('$remaining left', style: theme.textTheme.bodySmall),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.sports_soccer, size: 14, color: theme.colorScheme.primary),
                const SizedBox(width: 4),
                Text(opportunity.sport, style: theme.textTheme.bodySmall),
                if (opportunity.position != null) ...[
                  const SizedBox(width: 12),
                  Icon(Icons.person, size: 14, color: theme.colorScheme.primary),
                  const SizedBox(width: 4),
                  Text(opportunity.position!, style: theme.textTheme.bodySmall),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                if (opportunity.location != null) ...[
                  Icon(Icons.location_on, size: 14, color: theme.colorScheme.outline),
                  const SizedBox(width: 4),
                  Text(opportunity.location!, style: theme.textTheme.bodySmall),
                  const SizedBox(width: 12),
                ],
                if (opportunity.date != null) ...[
                  Icon(Icons.calendar_today, size: 14, color: theme.colorScheme.outline),
                  const SizedBox(width: 4),
                  Text(
                    '${opportunity.date!.day}/${opportunity.date!.month}/${opportunity.date!.year}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ],
            ),
            if (opportunity.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(opportunity.description, style: theme.textTheme.bodyMedium),
            ],
            if (!isClosed && opportunity.capacity > 0) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: opportunity.applicationCount / opportunity.capacity,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
              const SizedBox(height: 4),
              Text(
                '${opportunity.applicationCount}/${opportunity.capacity} applications',
                style: theme.textTheme.bodySmall,
              ),
            ],
            if (showApplyAction && !isClosed) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: onApply,
                  child: const Text('Apply Now'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}