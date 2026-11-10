import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapittrip/core/network/api_client.dart';
import 'package:tapittrip/core/network/api_exceptions.dart';
import 'package:tapittrip/core/storage/token_storage.dart';
import 'package:tapittrip/core/theme/app_theme.dart';
import 'package:tapittrip/features/auth/domain/models/auth_state.dart';
import 'package:tapittrip/features/auth/domain/models/auth_user.dart';
import 'package:tapittrip/features/auth/presentation/providers/auth_provider.dart';
import 'package:tapittrip/features/circles/data/trip_circle_repository.dart';
import 'package:tapittrip/features/circles/domain/models/activity_event.dart';
import 'package:tapittrip/features/circles/domain/models/circle_member.dart';
import 'package:tapittrip/features/circles/domain/models/trip_invitation.dart';
import 'package:tapittrip/features/circles/presentation/pages/trip_circle_page.dart';
import 'package:tapittrip/features/circles/presentation/widgets/join_trip_sheet.dart';
import 'package:tapittrip/features/trips/data/trip_repository.dart';

class _FakeCircleApiClient extends ApiClient {
  _FakeCircleApiClient() : super(tokenStorage: InMemoryTokenStorage());

  bool throwForbiddenOnMembers = false;
  bool throwForbiddenOnInvitations = false;
  String previewStatus = 'active';
  String? lastGetPath;
  String? lastPostPath;
  dynamic lastPostData;
  String? lastDeletePath;

  @override
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    lastGetPath = path;

    if (path == '/trips') {
      return [
        {
          'id': 'trip-1',
          'owner_id': 'user-owner',
          'title': 'Kyoto Autumn',
          'destination_country': 'JP',
          'trip_type': 'leisure',
          'planning_mode': 'diy',
          'status': 'planned',
          'version': 1,
          'role': 'owner',
        },
      ];
    }

    if (path.endsWith('/members')) {
      if (throwForbiddenOnMembers) {
        throw const ApiException(
          code: 'forbidden',
          message: 'Removed from circle',
          statusCode: 403,
        );
      }
      return [
        {
          'id': 'mem-1',
          'trip_id': 'trip-1',
          'user_id': 'user-owner',
          'display_name': 'Alice Organizer',
          'role': 'owner',
          'invitation_status': 'accepted',
        },
        {
          'id': 'mem-2',
          'trip_id': 'trip-1',
          'user_id': 'user-viewer',
          'display_name': 'Bob Viewer',
          'role': 'viewer',
          'invitation_status': 'accepted',
        },
      ];
    }

    if (path.endsWith('/invitations')) {
      if (throwForbiddenOnInvitations) {
        throw const ApiException(
          code: 'forbidden',
          message: 'Owner only',
          statusCode: 403,
        );
      }
      return [
        {
          'id': 'inv-1',
          'trip_id': 'trip-1',
          'proposed_role': 'viewer',
          'status': 'active',
          'max_uses': 3,
          'use_count': 1,
          'expires_at': DateTime.now()
              .add(const Duration(days: 5))
              .toIso8601String(),
          'inviter_name': 'Alice Organizer',
        },
      ];
    }

    if (path.endsWith('/feed')) {
      return [
        {
          'id': 'evt-1',
          'trip_id': 'trip-1',
          'event_type': 'member_joined',
          'title': 'Bob Viewer joined the trip circle',
          'summary': 'Joined as viewer.',
          'occurred_at': '2026-11-10T10:00:00Z',
          'actor': {
            'id': 'user-viewer',
            'name': 'Bob',
            'display_name': 'Bob Viewer',
          },
          'metadata': {'role': 'viewer'},
        },
      ];
    }

    if (path.startsWith('/invitations/')) {
      return {
        'trip_title': 'Osaka Food Trip',
        'destination_country': 'JP',
        'proposed_role': 'editor',
        'inviter_name': 'Alice Organizer',
        'expires_at': DateTime.now()
            .add(const Duration(days: 6))
            .toIso8601String(),
        'status': previewStatus,
      };
    }

    return const [];
  }

  @override
  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    lastPostPath = path;
    lastPostData = data;

    if (path.endsWith('/invitations')) {
      return {
        'id': 'inv-new',
        'trip_id': 'trip-1',
        'proposed_role':
            (data is Map ? data['proposed_role'] : null) ?? 'viewer',
        'status': 'active',
        'max_uses': (data is Map ? data['max_uses'] : null) ?? 1,
        'use_count': 0,
        'expires_at': DateTime.now()
            .add(const Duration(days: 7))
            .toIso8601String(),
        'inviter_name': 'Alice Organizer',
        'invite_token': 'tok_abc123',
        'share_url': 'tok_abc123',
      };
    }

    if (path.endsWith('/accept')) {
      return {
        'already_member': false,
        'trip': {
          'id': 'trip-osaka',
          'owner_id': 'user-owner',
          'title': 'Osaka Food Trip',
          'destination_country': 'JP',
          'trip_type': 'leisure',
          'planning_mode': 'diy',
          'status': 'planned',
          'version': 1,
          'role': 'editor',
        },
        'member': {
          'id': 'mem-new',
          'trip_id': 'trip-osaka',
          'user_id': 'user-viewer',
          'display_name': 'Bob Viewer',
          'role': 'editor',
          'invitation_status': 'accepted',
        },
      };
    }

    return const {};
  }

  @override
  Future<dynamic> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    lastDeletePath = path;
    return {
      'id': 'inv-1',
      'trip_id': 'trip-1',
      'proposed_role': 'viewer',
      'status': 'revoked',
      'max_uses': 3,
      'use_count': 1,
      'expires_at': DateTime.now()
          .add(const Duration(days: 5))
          .toIso8601String(),
      'inviter_name': 'Alice Organizer',
    };
  }
}

class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier(this.userId);
  final String userId;

  @override
  AuthState build() {
    return Authenticated(
      token: 'fake-token',
      user: AuthUser(
        id: userId,
        name: 'Test User',
        displayName: 'Test User',
        email: 'user@example.com',
      ),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('Trip Circle Models & Token Normalization', () {
    test('extracts token cleanly from URLs or raw codes', () {
      expect(
        TripCircleRepository.normalizeRawToken('https://host/invite/abc123def'),
        'abc123def',
      );
      expect(
        TripCircleRepository.normalizeRawToken('  raw_token_xyz  '),
        'raw_token_xyz',
      );
    });

    test('parses CircleMember, TripInvitation, and ActivityEvent models', () {
      final member = CircleMember.fromJson({
        'id': 'm1',
        'trip_id': 't1',
        'user_id': 'u1',
        'display_name': 'Alex',
        'role': 'owner',
        'invitation_status': 'accepted',
      });
      expect(member.isOwner, isTrue);
      expect(member.roleLabel, 'Organizer');

      final inv = TripInvitation.fromJson({
        'id': 'i1',
        'trip_id': 't1',
        'proposed_role': 'editor',
        'status': 'active',
        'max_uses': 5,
        'use_count': 2,
        'expires_at': '2026-12-01T00:00:00Z',
        'inviter_name': 'Alex',
      });
      expect(inv.isActive, isTrue);
      expect(inv.remainingUses, 3);
      expect(inv.proposedRoleLabel, 'Editor');

      final evt = ActivityEvent.fromJson({
        'id': 'e1',
        'trip_id': 't1',
        'event_type': 'moment_shared',
        'title': 'Golden Hour',
        'summary': 'Sunset photo.',
        'actor': {'display_name': 'Maya'},
        'metadata': {
          'photos': ['https://example.com/1.jpg'],
          'mood': 'amazed',
        },
      });
      expect(evt.eventEmoji, '📸');
      expect(evt.actorName, 'Maya');
      expect(evt.photos.length, 1);
    });
  });

  group('TripCircleRepository Caching & Revocation Cleanup', () {
    test(
      'caches members and purges local trip caches immediately on 403',
      () async {
        final api = _FakeCircleApiClient();
        const storage = FlutterSecureStorage();
        final repo = TripCircleRepository(apiClient: api, storage: storage);

        // Seed caches as if previously synced
        await storage.write(
          key: 'cached_journal_trip-1',
          value: '[{"title":"old"}]',
        );
        await storage.write(
          key: 'cached_circle_members_trip-1',
          value: jsonEncode([
            {'id': 'mem-1', 'display_name': 'Cached'},
          ]),
        );

        // Simulate member removal returning 403 Forbidden
        api.throwForbiddenOnMembers = true;

        await expectLater(
          () => repo.getMembers('trip-1'),
          throwsA(isA<ApiException>()),
        );

        expect(await storage.read(key: 'cached_circle_members_trip-1'), isNull);
        expect(await storage.read(key: 'cached_journal_trip-1'), isNull);
      },
    );
  });

  group('TripCirclePage & JoinTripSheet Widgets', () {
    testWidgets(
      'renders activity feed events and organizer invite/member management',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final api = _FakeCircleApiClient();
        const storage = FlutterSecureStorage();
        final circleRepo = TripCircleRepository(
          apiClient: api,
          storage: storage,
        );
        final tripRepo = RemoteTripRepository(api);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authProvider.overrideWith(() => _FakeAuthNotifier('user-owner')),
              tripCircleRepositoryProvider.overrideWithValue(circleRepo),
              tripRepositoryProvider.overrideWithValue(tripRepo),
            ],
            child: MaterialApp(
              theme: AppTheme.light(),
              home: const TripCirclePage(tripId: 'trip-1'),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Tab 1: Activity Feed renders events
        expect(find.text('Trip Circle & Feed'), findsOneWidget);
        expect(find.text('Bob Viewer joined the trip circle'), findsOneWidget);
        expect(find.text('Joined as viewer.'), findsOneWidget);

        // Switch to Members & Invites tab
        await tester.tap(find.text('Members & Invites'));
        await tester.pumpAndSettle();

        expect(find.text('Invite Travelers'), findsOneWidget);
        expect(find.text('Travel Circle Members (2)'), findsOneWidget);
        expect(find.text('Alice Organizer (You)'), findsOneWidget);
        expect(find.text('Bob Viewer'), findsOneWidget);
        expect(find.text('Viewer Invite • 1/3 used'), findsOneWidget);

        // Generate a new invite link as Organizer
        await tester.tap(find.text('Generate Invite Link'));
        await tester.pumpAndSettle();

        expect(api.lastPostPath, '/trips/trip-1/invitations');
        expect(find.text('Copy Invite'), findsOneWidget);
      },
    );

    testWidgets(
      'hides organizer invite card for companions and shows Leave button',
      (tester) async {
        final api = _FakeCircleApiClient()..throwForbiddenOnInvitations = true;
        const storage = FlutterSecureStorage();
        final circleRepo = TripCircleRepository(
          apiClient: api,
          storage: storage,
        );
        final tripRepo = RemoteTripRepository(api);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authProvider.overrideWith(() => _FakeAuthNotifier('user-viewer')),
              tripCircleRepositoryProvider.overrideWithValue(circleRepo),
              tripRepositoryProvider.overrideWithValue(tripRepo),
            ],
            child: MaterialApp(
              theme: AppTheme.light(),
              home: const TripCirclePage(tripId: 'trip-1'),
            ),
          ),
        );

        await tester.pumpAndSettle();
        await tester.tap(find.text('Members & Invites'));
        await tester.pumpAndSettle();

        expect(find.text('Invite Travelers'), findsNothing);
        expect(find.text('Leave Trip Circle'), findsOneWidget);
      },
    );

    testWidgets(
      'JoinTripSheet previews safe summary and accepts valid invite',
      (tester) async {
        final api = _FakeCircleApiClient();
        const storage = FlutterSecureStorage();
        final circleRepo = TripCircleRepository(
          apiClient: api,
          storage: storage,
        );
        final tripRepo = RemoteTripRepository(api);
        String? joinedTripId;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              tripCircleRepositoryProvider.overrideWithValue(circleRepo),
              tripRepositoryProvider.overrideWithValue(tripRepo),
            ],
            child: MaterialApp(
              theme: AppTheme.light(),
              home: Scaffold(
                body: Builder(
                  builder: (ctx) => Center(
                    child: ElevatedButton(
                      onPressed: () => JoinTripSheet.show(
                        ctx,
                        onJoined: (id) => joinedTripId = id,
                      ),
                      child: const Text('Open Join'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Join'));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byType(TextField),
          'https://example.com/invite/tok_abc123',
        );
        await tester.tap(find.text('Check'));
        await tester.pumpAndSettle();

        expect(api.lastGetPath, '/invitations/tok_abc123');
        expect(find.text('Osaka Food Trip'), findsOneWidget);
        expect(find.text('Invited by Alice Organizer'), findsOneWidget);
        expect(
          find.text('Access level: Editor (Can edit plan)'),
          findsOneWidget,
        );

        await tester.tap(find.text('Accept & Join Trip'));
        await tester.pumpAndSettle();

        expect(api.lastPostPath, '/invitations/tok_abc123/accept');
        expect(joinedTripId, 'trip-osaka');
      },
    );
  });
}
