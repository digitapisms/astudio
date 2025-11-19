import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../router/app_router.dart';
import '../../auth/application/auth_controller.dart';
import '../../profile/domain/user_role.dart';
import '../application/casting_providers.dart';
import '../domain/casting_call.dart';
import '../domain/casting_filter.dart';

class CastingBoardPage extends ConsumerWidget {
  const CastingBoardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(castingFilterProvider);
    final castings = ref.watch(castingFeedProvider);
    final authState = ref.watch(authControllerProvider);
    final profile = authState.profile;
    final isProducer =
        profile?.role.isStaff == true || profile?.role == UserRole.producer;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Casting Calls'),
        actions: [
          IconButton(
            tooltip: 'Reset filters',
            onPressed: () => ref.read(castingFilterProvider.notifier).reset(),
            icon: const Icon(Icons.filter_alt_off_outlined),
          ),
        ],
      ),
      floatingActionButton: isProducer
          ? FloatingActionButton.extended(
              onPressed: () => context.pushNamed(AppRoute.castingForm.name),
              icon: const Icon(Icons.add),
              label: const Text('New casting'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () async =>
            ref.invalidate(castingFeedProvider),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _FilterSection(filter: filter),
            const SizedBox(height: 16),
            castings.when(
              data: (items) {
                if (items.isEmpty) {
                  return _EmptyState(isProducer: isProducer);
                }
                return Column(
                  children: [
                    for (final casting in items)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _CastingCard(casting: casting),
                      ),
                  ],
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(48),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stackTrace) => _ErrorState(error: error),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterSection extends ConsumerStatefulWidget {
  const _FilterSection({required this.filter});

  final CastingFilter filter;

  @override
  ConsumerState<_FilterSection> createState() => _FilterSectionState();
}

class _FilterSectionState extends ConsumerState<_FilterSection> {
  late final TextEditingController _searchController;
  late final TextEditingController _cityController;

  @override
  void initState() {
    super.initState();
    _searchController =
        TextEditingController(text: widget.filter.searchTerm ?? '');
    _cityController = TextEditingController(text: widget.filter.city ?? '');

    ref.listen<CastingFilter>(
      castingFilterProvider,
      (previous, next) {
        final searchText = next.searchTerm ?? '';
        if (_searchController.text != searchText) {
          _searchController.text = searchText;
        }
        final cityText = next.city ?? '';
        if (_cityController.text != cityText) {
          _cityController.text = cityText;
        }
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(castingFilterProvider.notifier);
    final filter = ref.watch(castingFilterProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search roles, keywords, or production',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: notifier.updateSearch,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _cityController,
              decoration: const InputDecoration(
                labelText: 'City or region',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
              onChanged: notifier.updateCity,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: filter.category,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                  ),
                  items: const [
                    DropdownMenuItem(value: 'film', child: Text('Film')),
                    DropdownMenuItem(value: 'tv', child: Text('TV')),
                    DropdownMenuItem(value: 'commercial', child: Text('Commercial')),
                    DropdownMenuItem(value: 'theatre', child: Text('Theatre')),
                    DropdownMenuItem(value: 'voice', child: Text('Voice Over')),
                  ],
                  onChanged: notifier.updateCategory,
                ),
                FilterChip(
                  label: const Text('Only open roles'),
                  selected: filter.onlyOpen,
                  onSelected: notifier.toggleOnlyOpen,
                ),
                FilterChip(
                  label: const Text('My castings'),
                  selected: filter.onlyMine,
                  onSelected: notifier.toggleOnlyMine,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CastingCard extends ConsumerWidget {
  const _CastingCard({required this.casting});

  final CastingCall casting;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: () => context.pushNamed(
          AppRoute.castingDetail.name,
          pathParameters: {'castingId': casting.id},
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      casting.title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (casting.isMine)
                    Chip(
                      backgroundColor: Colors.blueGrey.withValues(alpha: 0.2),
                      label: const Text('My casting'),
                    ),
                  if (casting.hasApplied && !casting.isMine)
                    Chip(
                      backgroundColor: Colors.greenAccent.withValues(alpha: 0.2),
                      label: const Text('Applied'),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                casting.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _InfoChip(
                    icon: Icons.category_outlined,
                    label: casting.category ?? 'General',
                  ),
                  if (casting.city != null)
                    _InfoChip(
                      icon: Icons.location_on_outlined,
                      label: casting.city!,
                    ),
                  if (casting.budget != null)
                    _InfoChip(
                      icon: Icons.payments_outlined,
                      label: casting.budget!,
                    ),
                  if (casting.applicationDeadline != null)
                    _InfoChip(
                      icon: Icons.calendar_today_outlined,
                      label:
                          'Apply by ${_formatDate(casting.applicationDeadline!)}',
                      highlight: casting.isDeadlinePassed,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.charcoal.withValues(alpha: 0.4),
                    child: Text(
                      casting.creator?.fullName.substring(0, 1).toUpperCase() ??
                          '?',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      casting.creator?.fullName ?? 'Actor Studio Producer',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      backgroundColor: highlight
          ? AppColors.errorRed.withValues(alpha: 0.2)
          : AppColors.charcoal.withValues(alpha: 0.2),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isProducer});

  final bool isProducer;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.search_off, size: 48),
            const SizedBox(height: 12),
            Text(
              'No casting calls found',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              isProducer
                  ? 'Share your next role with the community by creating a casting.'
                  : 'Try adjusting your filters or check back later for new opportunities.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.errorRed.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Unable to load casting calls',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: const TextStyle(color: AppColors.errorRed),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
}

