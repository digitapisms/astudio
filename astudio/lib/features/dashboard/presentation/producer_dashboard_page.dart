import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../router/app_router.dart';
import 'dashboard_scaffold.dart';

class ProducerDashboardPage extends StatelessWidget {
  const ProducerDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardScaffold(
      child: ListView(
        children: [
          const _ProducerCastingActions(),
          const SizedBox(height: 24),
          const _ProducerLearningCard(),
          const SizedBox(height: 24),
          _SectionCard(
            title: 'Active casting calls',
            subtitle:
                'Track applications, shortlist top talent, and keep momentum high.',
            actionLabel: 'Create new casting',
            items: const [
              _CastingTile(
                title: 'Feature film - Hero role',
                subtitle: '15 applicants · Karachi · Drama',
                progressLabel: 'Shortlisting',
              ),
              _CastingTile(
                title: 'Commercial - Sportswear',
                subtitle: '8 applicants · Lahore · TVC',
                progressLabel: 'Reviewing',
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SectionCard(
            title: 'Talent matches',
            subtitle:
                'Fresh profiles that align with your casting preferences.',
            actionLabel: 'View talent pool',
            items: const [
              _TalentTile(
                name: 'Ayesha Khan',
                subtitle: 'Actor · Karachi · Fluent Urdu, English',
                matchScore: '92% match',
              ),
              _TalentTile(
                name: 'Zain Malik',
                subtitle: 'Model · Lahore · Fit, Athletic',
                matchScore: '87% match',
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SectionCard(
            title: 'Pipeline health',
            subtitle: 'Monitor your casting pipeline at a glance.',
            items: const [
              _MetricRow(
                label: 'New applicants',
                value: '5',
                deltaLabel: '+2 since yesterday',
              ),
              _MetricRow(
                label: 'Interviews scheduled',
                value: '3',
                deltaLabel: 'Next in 2 days',
              ),
              _MetricRow(
                label: 'Contracts sent',
                value: '1',
                deltaLabel: 'Awaiting signature',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProducerLearningCard extends StatelessWidget {
  const _ProducerLearningCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 28,
              backgroundColor: Colors.white12,
              child: Icon(Icons.cast_for_education, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Training catalog',
                    style:
                        Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Recommend courses to your talent roster or review their progress.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            TextButton.icon(
              onPressed: () => context.pushNamed(AppRoute.learning.name),
              icon: const Icon(Icons.school_outlined),
              label: const Text('Open'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.items = const [],
  });

  final String title;
  final String subtitle;
  final String? actionLabel;
  final List<Widget> items;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                if (actionLabel != null)
                  TextButton(onPressed: () {}, child: Text(actionLabel!)),
              ],
            ),
            const SizedBox(height: 16),
            ..._withSpacing(items),
          ],
        ),
      ),
    );
  }
}

class _ProducerCastingActions extends StatelessWidget {
  const _ProducerCastingActions();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Casting operations',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: () =>
                      context.pushNamed(AppRoute.castingForm.name),
                  icon: const Icon(Icons.add),
                  label: const Text('Create casting'),
                ),
                OutlinedButton.icon(
                  onPressed: () =>
                      context.pushNamed(AppRoute.castings.name),
                  icon: const Icon(Icons.campaign_outlined),
                  label: const Text('View board'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

List<Widget> _withSpacing(List<Widget> widgets) {
  if (widgets.isEmpty) return widgets;
  return [
    for (var i = 0; i < widgets.length; i++) ...[
      widgets[i],
      if (i != widgets.length - 1) const Divider(height: 24),
    ],
  ];
}

class _CastingTile extends StatelessWidget {
  const _CastingTile({
    required this.title,
    required this.subtitle,
    required this.progressLabel,
  });

  final String title;
  final String subtitle;
  final String progressLabel;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const CircleAvatar(
        backgroundColor: Colors.white12,
        child: Icon(Icons.campaign_outlined, color: Colors.white),
      ),
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: Colors.white70),
      ),
      trailing: Chip(
        label: Text(
          progressLabel,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      onTap: () {},
    );
  }
}

class _TalentTile extends StatelessWidget {
  const _TalentTile({
    required this.name,
    required this.subtitle,
    required this.matchScore,
  });

  final String name;
  final String subtitle;
  final String matchScore;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const CircleAvatar(
        backgroundColor: Colors.white12,
        child: Icon(Icons.person_outline, color: Colors.white),
      ),
      title: Text(name),
      subtitle: Text(
        subtitle,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: Colors.white70),
      ),
      trailing: Chip(
        label: Text(
          matchScore,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      onTap: () {},
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.label,
    required this.value,
    required this.deltaLabel,
  });

  final String label;
  final String value;
  final String deltaLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                deltaLabel,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
