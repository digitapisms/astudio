import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/application/auth_controller.dart';
import '../features/auth/application/auth_state.dart';
import '../features/auth/presentation/auth_shell_page.dart';
import '../features/auth/presentation/pending_approval_page.dart';
import '../features/auth/presentation/rejected_profile_page.dart';
import '../features/auth/presentation/splash_page.dart';
import '../features/auditions/presentation/audition_detail_page.dart';
import '../features/auditions/presentation/audition_inbox_page.dart';
import '../features/casting/presentation/casting_applications_page.dart';
import '../features/casting/presentation/casting_board_page.dart';
import '../features/casting/presentation/casting_detail_page.dart';
import '../features/casting/presentation/casting_form_page.dart';
import '../features/dashboard/presentation/admin_dashboard_page.dart';
import '../features/dashboard/presentation/artist_dashboard_page.dart';
import '../features/dashboard/presentation/producer_dashboard_page.dart';
import '../features/learning/presentation/course_detail_page.dart';
import '../features/learning/presentation/learning_hub_page.dart';
import '../features/learning/presentation/lesson_detail_page.dart';
import '../features/learning/presentation/quiz_page.dart';
import '../features/messaging/presentation/conversation_detail_page.dart';
import '../features/messaging/presentation/conversation_list_page.dart';
import '../features/messaging/presentation/new_conversation_page.dart';
import '../features/profile/presentation/edit_profile_page.dart';
import '../features/profile/presentation/profile_management_page.dart';
import '../features/profile/presentation/profile_page.dart';
import '../features/profile/domain/profile_status.dart';
import '../features/profile/domain/user_role.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        name: AppRoute.splash.name,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/auth',
        name: AppRoute.auth.name,
        pageBuilder: (context, state) =>
            const MaterialPage(child: AuthShellPage()),
      ),
      GoRoute(
        path: '/artist',
        name: AppRoute.artist.name,
        pageBuilder: (context, state) =>
            const MaterialPage(child: ArtistDashboardPage()),
      ),
      GoRoute(
        path: '/producer',
        name: AppRoute.producer.name,
        pageBuilder: (context, state) =>
            const MaterialPage(child: ProducerDashboardPage()),
      ),
      GoRoute(
        path: '/admin',
        name: AppRoute.admin.name,
        pageBuilder: (context, state) =>
            const MaterialPage(child: AdminDashboardPage()),
      ),
      GoRoute(
        path: '/pending',
        name: AppRoute.pending.name,
        pageBuilder: (context, state) =>
            const MaterialPage(child: PendingApprovalPage()),
      ),
      GoRoute(
        path: '/rejected',
        name: AppRoute.rejected.name,
        pageBuilder: (context, state) =>
            const MaterialPage(child: RejectedProfilePage()),
      ),
      GoRoute(
        path: '/castings',
        name: AppRoute.castings.name,
        pageBuilder: (context, state) =>
            const MaterialPage(child: CastingBoardPage()),
        routes: [
          GoRoute(
            path: 'new',
            name: AppRoute.castingForm.name,
            pageBuilder: (context, state) =>
                const MaterialPage(child: CastingFormPage()),
          ),
          GoRoute(
            path: ':castingId',
            name: AppRoute.castingDetail.name,
            pageBuilder: (context, state) {
              final castingId = state.pathParameters['castingId']!;
              return MaterialPage(
                child: CastingDetailPage(castingId: castingId),
              );
            },
            routes: [
              GoRoute(
                path: 'edit',
                name: AppRoute.castingEdit.name,
                pageBuilder: (context, state) {
                  final castingId = state.pathParameters['castingId']!;
                  return MaterialPage(
                    child: CastingFormPage(castingId: castingId),
                  );
                },
              ),
              GoRoute(
                path: 'applications',
                name: AppRoute.castingApplications.name,
                pageBuilder: (context, state) {
                  final castingId = state.pathParameters['castingId']!;
                  return MaterialPage(
                    child: CastingApplicationsPage(castingId: castingId),
                  );
                },
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/profile',
        name: AppRoute.profile.name,
        pageBuilder: (context, state) =>
            const MaterialPage(child: ProfilePage()),
        routes: [
          GoRoute(
            path: 'edit',
            name: AppRoute.profileEdit.name,
            pageBuilder: (context, state) =>
                const MaterialPage(child: EditProfilePage()),
          ),
          GoRoute(
            path: 'manage',
            name: AppRoute.profileManage.name,
            pageBuilder: (context, state) =>
                const MaterialPage(child: ProfileManagementPage()),
          ),
        ],
      ),
      GoRoute(
        path: '/auditions',
        name: AppRoute.auditions.name,
        pageBuilder: (context, state) =>
            const MaterialPage(child: AuditionInboxPage()),
        routes: [
          GoRoute(
            path: ':auditionId',
            name: AppRoute.auditionDetail.name,
            pageBuilder: (context, state) {
              final auditionId = state.pathParameters['auditionId']!;
              return MaterialPage(
                child: AuditionDetailPage(auditionId: auditionId),
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/messages',
        name: AppRoute.messages.name,
        pageBuilder: (context, state) =>
            const MaterialPage(child: ConversationListPage()),
        routes: [
          GoRoute(
            path: 'new',
            name: AppRoute.newConversation.name,
            pageBuilder: (context, state) =>
                const MaterialPage(child: NewConversationPage()),
          ),
          GoRoute(
            path: ':conversationId',
            name: AppRoute.conversationDetail.name,
            pageBuilder: (context, state) {
              final conversationId = state.pathParameters['conversationId']!;
              return MaterialPage(
                child:
                    ConversationDetailPage(conversationId: conversationId),
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/learn',
        name: AppRoute.learning.name,
        pageBuilder: (context, state) =>
            const MaterialPage(child: LearningHubPage()),
        routes: [
          GoRoute(
            path: ':courseId',
            name: AppRoute.courseDetail.name,
            pageBuilder: (context, state) {
              final courseId = state.pathParameters['courseId']!;
              return MaterialPage(
                child: CourseDetailPage(courseId: courseId),
              );
            },
            routes: [
              GoRoute(
                path: 'lessons/:lessonId',
                name: AppRoute.lessonDetail.name,
                pageBuilder: (context, state) {
                  final courseId = state.pathParameters['courseId']!;
                  final lessonId = state.pathParameters['lessonId']!;
                  return MaterialPage(
                    child: LessonDetailPage(
                      courseId: courseId,
                      lessonId: lessonId,
                    ),
                  );
                },
              ),
              GoRoute(
                path: 'quiz/:quizId',
                name: AppRoute.quiz.name,
                pageBuilder: (context, state) {
                  final courseId = state.pathParameters['courseId']!;
                  final quizId = state.pathParameters['quizId']!;
                  return MaterialPage(
                    child: QuizPage(courseId: courseId, quizId: quizId),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    ],
    redirect: (context, state) {
      final status = authState.status;
      final isAuthRoute = state.matchedLocation == '/auth';
      final isSplashRoute = state.matchedLocation == '/splash';
      final currentLocation = state.matchedLocation;

      if (status == AuthStatus.unknown) {
        return isSplashRoute ? null : '/splash';
      }

      if (status == AuthStatus.unauthenticated) {
        return isAuthRoute ? null : '/auth';
      }

      if (status == AuthStatus.authenticated) {
        final profile = authState.profile;
        if (profile == null) {
          return '/auth';
        }

        final profileStatus = profile.status;
        if (profileStatus == ProfileStatus.pending) {
          return currentLocation == '/pending' ? null : '/pending';
        }

        if (profileStatus == ProfileStatus.rejected) {
          return currentLocation == '/rejected' ? null : '/rejected';
        }

        if (currentLocation.startsWith('/castings') ||
            currentLocation.startsWith('/profile') ||
            currentLocation.startsWith('/auditions') ||
            currentLocation.startsWith('/messages') ||
            currentLocation.startsWith('/learn')) {
          return null;
        }

        final role = profile.role;
        String targetRoute = '/artist';
        if (role == UserRole.producer) {
          targetRoute = '/producer';
        } else if (role.isStaff) {
          targetRoute = '/admin';
        } else if (role == UserRole.viewer) {
          targetRoute = '/artist';
        }

        if (state.matchedLocation == targetRoute) {
          return null;
        }
        return targetRoute;
      }

      return null;
    },
  );
});

enum AppRoute {
  splash,
  auth,
  artist,
  producer,
  admin,
  pending,
  rejected,
  castings,
  castingDetail,
  castingForm,
  castingEdit,
  castingApplications,
  auditions,
  auditionDetail,
  messages,
  conversationDetail,
  newConversation,
  profile,
  profileEdit,
  profileManage,
  learning,
  courseDetail,
  lessonDetail,
  quiz,
}
