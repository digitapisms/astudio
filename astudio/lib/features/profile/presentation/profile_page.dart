import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/shimmer_blocks.dart';
import '../../../router/app_router.dart';
import '../../auth/application/auth_controller.dart';
import '../application/profile_providers.dart';
import '../data/profile_repository.dart';
import '../domain/portfolio_media.dart';
import '../domain/profile_review.dart';
import '../domain/user_profile.dart';
import '../../trust/application/trust_providers.dart';
import '../../trust/domain/identity_verification_request.dart';
import '../../trust/presentation/verification_request_sheet.dart';
import '../../trust/presentation/safety_report_sheet.dart';
import '../../trust/presentation/policy_ack_sheet.dart';
import 'portfolio_item_sheet.dart';
import 'review_sheet.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentProfile = ref.watch(authControllerProvider).profile;

    if (currentProfile == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final profile = currentProfile;
    final isOwner = true;
    final portfolioAsync = ref.watch(portfolioProvider(profile.id));
    final reviewsAsync = ref.watch(profileReviewsProvider(profile.id));
    final averageRatingAsync =
        ref.watch(profileAverageRatingProvider(profile.id));
    final verificationAsync = ref.watch(identityVerificationProvider);
    final policyAckAsync = ref.watch(policyAcknowledgementProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Portfolio'),
        actions: [
          IconButton(
            tooltip: 'Edit profile',
            onPressed: () => context.pushNamed(AppRoute.profileEdit.name),
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Manage profile',
            onPressed: () => context.pushNamed(AppRoute.profileManage.name),
            icon: const Icon(Icons.manage_accounts_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(portfolioProvider(profile.id));
          await ref.read(authControllerProvider.notifier).refreshProfile();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _ProfileHeader(profile: profile),
            const SizedBox(height: 16),
            _ProfileDetails(profile: profile),
            const SizedBox(height: 16),
            _VisibilityToggle(profile: profile),
            const SizedBox(height: 24),
            _PortfolioSection(
              portfolioAsync: portfolioAsync,
              profile: profile,
            ),
            const SizedBox(height: 24),
            _ReviewsSection(
              profile: profile,
              reviewsAsync: reviewsAsync,
              averageRatingAsync: averageRatingAsync,
              isOwner: isOwner,
            ),
            const SizedBox(height: 24),
            _TrustComplianceSection(
              verificationAsync: verificationAsync,
              policyAckAsync: policyAckAsync,
              profile: profile,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundImage: profile.avatarUrl != null
                      ? CachedNetworkImageProvider(profile.avatarUrl!)
                      : null,
                  child: profile.avatarUrl == null
                      ? Text(
                          profile.fullName.isNotEmpty
                              ? profile.fullName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(fontSize: 24),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.fullName,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      if (profile.profession != null)
                        Text(
                          profile.profession!,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Colors.white70),
                        ),
                      Wrap(
                        spacing: 8,
                        children: [
                          Chip(
                            label: Text(profile.role.label),
                          ),
                          Chip(
                            backgroundColor: profile.status.isActive
                                ? Colors.green.withValues(alpha: 0.2)
                                : Colors.orange.withValues(alpha: 0.2),
                            label: Text(profile.status.label),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (profile.bio != null && profile.bio!.isNotEmpty)
              Text(profile.bio!),
          ],
        ),
      ),
    );
  }
}

class _ProfileDetails extends StatelessWidget {
  const _ProfileDetails({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _InfoTile(
                    label: 'Location',
                    value: profile.location ?? 'Not set',
                  ),
                ),
                Expanded(
                  child: _InfoTile(
                    label: 'Age',
                    value: profile.age?.toString() ?? '—',
                  ),
                ),
                Expanded(
                  child: _InfoTile(
                    label: 'Gender',
                    value: profile.gender ?? '—',
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            if (profile.skills.isNotEmpty)
              _TagSection(
                title: 'Skills',
                tags: profile.skills,
              ),
            if (profile.languages.isNotEmpty) ...[
              const SizedBox(height: 12),
              _TagSection(
                title: 'Languages',
                tags: profile.languages,
              ),
            ],
            if (_hasSocialLinks(profile)) ...[
              const SizedBox(height: 12),
              Text(
                'Social links',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 12,
                children: [
                  if (profile.instagram?.isNotEmpty == true)
                    _LinkChip('Instagram', profile.instagram!),
                  if (profile.youtube?.isNotEmpty == true)
                    _LinkChip('YouTube', profile.youtube!),
                  if (profile.tiktok?.isNotEmpty == true)
                    _LinkChip('TikTok', profile.tiktok!),
                  if (profile.website?.isNotEmpty == true)
                    _LinkChip('Website', profile.website!),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _hasSocialLinks(UserProfile profile) {
    return (profile.instagram?.isNotEmpty == true) ||
        (profile.youtube?.isNotEmpty == true) ||
        (profile.tiktok?.isNotEmpty == true) ||
        (profile.website?.isNotEmpty == true);
  }
}

class _VisibilityToggle extends ConsumerStatefulWidget {
  const _VisibilityToggle({required this.profile});

  final UserProfile profile;

  @override
  ConsumerState<_VisibilityToggle> createState() => _VisibilityToggleState();
}

class _VisibilityToggleState extends ConsumerState<_VisibilityToggle> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final messenger = ScaffoldMessenger.of(context);
    return SwitchListTile(
      value: profile.isVisible,
      onChanged: _isLoading
          ? null
          : (value) async {
              setState(() => _isLoading = true);
              try {
                await ref
                    .read(profileRepositoryProvider)
                    .updateProfileVisibility(
                      profileId: profile.id,
                      isVisible: value,
                    );
                await ref
                    .read(authControllerProvider.notifier)
                    .refreshProfile();
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Failed to update visibility: $e')),
                );
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
      title: const Text('Visible to casting directors'),
      subtitle: const Text('Approved profiles can appear in search results'),
    );
  }
}

class _PortfolioSection extends ConsumerWidget {
  const _PortfolioSection({
    required this.portfolioAsync,
    required this.profile,
  });

  final AsyncValue<List<PortfolioMedia>> portfolioAsync;
  final UserProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOwner = true; // viewing own profile
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Portfolio',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (isOwner)
              TextButton.icon(
                onPressed: () async {
                  final saved = await showModalBottomSheet<bool>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => PortfolioItemSheet(profileId: profile.id),
                  );
                  if (saved == true) {
                    ref.invalidate(portfolioProvider(profile.id));
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Add item'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        portfolioAsync.when(
          data: (items) {
            if (items.isEmpty) {
              return const Text(
                'Show off your work by adding headshots, reels, or links.',
              );
            }
            return GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.1,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final media = items[index];
                return _PortfolioCard(
                  media: media,
                  onEdit: () async {
                    final saved = await showModalBottomSheet<bool>(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => PortfolioItemSheet(
                        profileId: profile.id,
                        existing: media,
                      ),
                    );
                    if (saved == true) {
                      ref.invalidate(portfolioProvider(profile.id));
                    }
                  },
                  onDelete: () async {
                    final repo = ref.read(profileRepositoryProvider);
                    await repo.deletePortfolioMedia(media.id);
                    ref.invalidate(portfolioProvider(profile.id));
                  },
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Text('Failed to load portfolio: $error'),
        ),
      ],
    );
  }
}

class _PortfolioCard extends StatelessWidget {
  const _PortfolioCard({
    required this.media,
    required this.onEdit,
    required this.onDelete,
  });

  final PortfolioMedia media;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    Widget preview;
    if (media.mediaType == PortfolioMediaType.image) {
      preview = CachedNetworkImage(
        imageUrl: media.mediaUrl,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
      );
    } else {
      preview = Center(
        child: Icon(
          media.mediaType == PortfolioMediaType.video
              ? Icons.video_collection
              : Icons.link,
          size: 42,
          color: AppColors.sunsetGold,
        ),
      );
    }

    return Card(
      child: InkWell(
        onTap: () {},
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: Container(
                  width: double.infinity,
                  color: AppColors.charcoal.withValues(alpha: 0.2),
                  child: preview,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    media.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (media.description?.isNotEmpty == true)
                    Text(
                      media.description!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18),
                        onPressed: onEdit,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18),
                        onPressed: onDelete,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Colors.white70),
        ),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _TagSection extends StatelessWidget {
  const _TagSection({required this.title, required this.tags});

  final String title;
  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tags
              .map((tag) => Chip(
                    label: Text(tag),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

class _LinkChip extends StatelessWidget {
  const _LinkChip(this.label, this.url);

  final String label;
  final String url;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: const Icon(Icons.link, size: 16),
      label: Text(label),
      onPressed: () {},
    );
  }
}

class _ReviewsSection extends ConsumerWidget {
  const _ReviewsSection({
    required this.profile,
    required this.reviewsAsync,
    required this.averageRatingAsync,
    required this.isOwner,
  });

  final UserProfile profile;
  final AsyncValue<List<ProfileReview>> reviewsAsync;
  final AsyncValue<double> averageRatingAsync;
  final bool isOwner;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AsyncValueWidget<double>(
                  value: averageRatingAsync,
                  builder: (context, rating) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reviews & ratings',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          ...List.generate(
                            5,
                            (index) => Icon(
                              index < rating.round()
                                  ? Icons.star
                                  : Icons.star_border,
                              color: Colors.amber,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(rating.toStringAsFixed(1)),
                        ],
                      ),
                    ],
                  ),
                ),
                if (!isOwner)
                  TextButton.icon(
                    onPressed: () async {
                      final result = await showModalBottomSheet<bool>(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => ReviewSheet(profileId: profile.id),
                      );
                      if (result == true) {
                        ref.invalidate(profileReviewsProvider(profile.id));
                        ref.invalidate(
                            profileAverageRatingProvider(profile.id));
                      }
                    },
                    icon: const Icon(Icons.edit_note),
                    label: const Text('Leave review'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            reviewsAsync.when(
              data: (reviews) {
                if (reviews.isEmpty) {
                  return const Text('No reviews yet.');
                }
                return Column(
                  children: reviews
                      .map(
                        (review) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(review.title ?? 'Feedback'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: List.generate(
                                  5,
                                  (index) => Icon(
                                    index < review.rating
                                        ? Icons.star
                                        : Icons.star_border,
                                    size: 16,
                                    color: Colors.amber,
                                  ),
                                ),
                              ),
                              if (review.comment != null)
                                Text(review.comment!),
                              Text(
                                review.reviewerName ?? 'Anonymous',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: ShimmerList(itemCount: 2, itemHeight: 60),
              ),
              error: (error, stackTrace) =>
                  Text('Unable to load reviews: $error'),
            ),
          ],
        ),
      ),
    );
  }
}

class AsyncValueWidget<T> extends StatelessWidget {
  const AsyncValueWidget({super.key, required this.value, required this.builder});

  final AsyncValue<T> value;
  final Widget Function(BuildContext, T data) builder;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: (data) => builder(context, data),
      loading: () => const CircularProgressIndicator(),
      error: (error, stackTrace) => Text('Error: $error'),
    );
  }
}

class _TrustComplianceSection extends ConsumerWidget {
  const _TrustComplianceSection({
    required this.verificationAsync,
    required this.policyAckAsync,
    required this.profile,
  });

  final AsyncValue<IdentityVerificationRequest?> verificationAsync;
  final AsyncValue<bool> policyAckAsync;
  final UserProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trust & compliance',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            verificationAsync.when(
              data: (verification) {
                if (verification == null) {
                  return _buildVerificationPrompt(context, ref);
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.verified_user,
                          color: _verificationColor(verification.status),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Status: ${verification.status.label}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    if (verification.reviewerNotes?.isNotEmpty == true)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          verification.reviewerNotes!,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.white70),
                        ),
                      ),
                    if (verification.status != VerificationStatus.approved)
                      TextButton(
                        onPressed: () => _openVerificationSheet(context, ref),
                        child: const Text('Resubmit documents'),
                      ),
                  ],
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (error, stackTrace) =>
                  _buildVerificationPrompt(context, ref),
            ),
            const Divider(height: 24),
            policyAckAsync.when(
              data: (acknowledged) => Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    acknowledged
                        ? 'Code of Conduct acknowledged'
                        : 'Code of Conduct pending',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (!acknowledged)
                    TextButton(
                      onPressed: () => _openPolicySheet(context, ref),
                      child: const Text('Review & acknowledge'),
                    )
                  else
                    const Icon(Icons.check_circle, color: Colors.green),
                ],
              ),
              loading: () => const LinearProgressIndicator(),
              error: (error, stackTrace) =>
                  Text('Unable to load policy status'),
            ),
            const Divider(height: 24),
            Text(
              'Need help or noticed something concerning?',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _openReportSheet(context),
              icon: const Icon(Icons.report_gmailerrorred),
              label: const Text('Report a concern'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationPrompt(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Get verified to build trust with producers and casting directors.',
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: () => _openVerificationSheet(context, ref),
          icon: const Icon(Icons.verified),
          label: const Text('Submit verification'),
        ),
      ],
    );
  }

  Future<void> _openVerificationSheet(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const VerificationRequestSheet(),
    );
    if (result == true) {
      ref.invalidate(identityVerificationProvider);
    }
  }

  Future<void> _openPolicySheet(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const PolicyAckSheet(),
    );
    if (result == true) {
      ref.invalidate(policyAcknowledgementProvider);
    }
  }

  void _openReportSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => SafetyReportSheet(targetProfileId: profile.id),
    );
  }

  Color _verificationColor(VerificationStatus status) {
    if (status == VerificationStatus.approved) {
      return Colors.green;
    }
    if (status == VerificationStatus.pending) {
      return Colors.orangeAccent;
    }
    return AppColors.errorRed;
  }
}

