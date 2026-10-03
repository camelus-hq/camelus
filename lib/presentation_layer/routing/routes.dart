import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:ndk/shared/nips/nip19/nip19.dart';
import 'package:ndk/entities.dart' as ndk_entities;

import '../../lifecycle/app_init_shell.dart';
import '../components/app_bottom_navigation_bar/app_bottom_navigation_bar.dart';
import '../components/drawer/nostr_side_menu.dart';
import '../components/drawer/nostr_side_menu_post_button.dart';
import '../components/drawer/side_menu_logo.dart';
import '../components/relays_connectivity_widget.dart';
import '../components/right_sidebar/right_siedbar.dart';
import '../../domain_layer/entities/list_identifier.dart';
import '../routes/nostr/starter_packs/starter_pack_page.dart';
import '../routes/nostr/starter_packs/starter_pack_edit_page.dart';
import '../layouts/mobile_bottom_menu_layout.dart';
import '../layouts/responsive_layout.dart';
import '../layouts/three_colum_layout.dart';
import '../routes/deeplink_reciever_page.dart';
import '../routes/home_page_desktop.dart';
import '../routes/home_page_mobile.dart';
import '../routes/nostr/blockedUsers/blocklist_page.dart';
import '../routes/nostr/event_gallery_page.dart';
import '../routes/nostr/fullscreen_video_page.dart';
import '../routes/nostr/bookmarks/bookmarks_page.dart';
import '../routes/nostr/event_view/event_view_page.dart';
import '../routes/nostr/lists/edit_list_page.dart';
import '../routes/nostr/lists/lists_page.dart';
import '../routes/nostr/onboarding/onboarding.dart';
import '../routes/nostr/profile/edit_profile_page.dart';
import '../routes/nostr/profile/profile_resolver_page.dart';
import '../routes/nostr/relays_page.dart';
import '../routes/nostr/search_feed_page/search_feed_page.dart';
import '../routes/nostr/settings/developer/developer_settings.dart';
import '../routes/nostr/settings/relays/relays_settings.dart';
import '../routes/nostr/settings/notifications/notifications_settings.dart';
import '../routes/nostr/settings/theme/theme_settings.dart';
import '../routes/wallet/wallet_restore/wallet_restore.dart';
import '../routes/nostr/settings/wallet_settings.dart';
import '../routes/notification_page.dart';
import '../routes/search/search_page.dart';
import '../routes/nostr/settings/file_servers/settings_file_servers.dart';
import '../routes/nostr/settings/inital_route/inital_route_settings.dart';
import '../routes/nostr/settings/locale/locale_settings.dart';
import '../routes/nostr/settings/moderation/moderation_settings.dart';
import '../routes/nostr/settings/settings_page.dart';
import '../routes/messages/dm_list_page.dart';
import '../routes/messages/dm_thread_page.dart';
import '../routes/messages/new_dm_page.dart';
import '../routes/map/map_navigation_page.dart';
import '../routes/map/map_page.dart';
import '../routes/map/map_search_page.dart';
import '../routes/wallet/add_mint/add_mint_page.dart';
import '../routes/wallet/mint_info/mint_info_page.dart';
import '../routes/wallet/wallet_navigation.dart';
import '../routes/wallet/wallet_pay/wallet_pay_done/wallet_pay_done.dart';
import '../routes/wallet/wallet_pay/wallet_pay_page.dart';
import '../routes/wallet/wallet_receive/rcv_completers/wallet_rcv_ecash_completer_page.dart';
import '../routes/wallet/wallet_receive/wallet_receive_page.dart';
import '../routes/wallet/wallet_shell_page.dart';
import '../routes/wallet/wallet_transaction/wallet_transaction_detail_page.dart';

String? decodeProfileIdentifierToPubkey(String rawIdentifier) {
  final identifier = Uri.decodeComponent(rawIdentifier).trim();

  try {
    if (identifier.startsWith('nprofile')) {
      return Nip19.decodeNprofile(identifier).pubkey;
    }

    if (identifier.startsWith('npub')) {
      return Nip19.decode(identifier);
    }
  } catch (_) {
    return null;
  }

  final isHexPubkey = RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(identifier);
  if (isHexPubkey) {
    return identifier.toLowerCase();
  }

  return null;
}

Null redirects(BuildContext context, GoRouterState state) {
  return null;
}

final routes = [
  /// global shell
  ShellRoute(
    builder: (context, state, child) {
      return AppInitializationShell(child: child);
    },
    routes: [
      // Shell route for persistent layout
      ShellRoute(
        builder: (context, state, child) {
          return ResponsiveLayout(
            desktopContent: ThreeColumnLayout(
              leftSidebar: NostrSideMenu(
                trailingButtonWidget: Padding(
                  padding: const EdgeInsets.only(top: 40, left: 10, right: 10),
                  child: NostrSideMenuPostButton(),
                ),
                leadingWidget: SideMenuLogo(
                  trailingWidget: RelaysConnectivityWidget(
                    onTap: () {
                      context.push('/relays');
                    },
                  ),
                ),
              ),
              mainContent: child,
              rightSidebar: RightSiedbar(),
            ),
            mobileContent: MobileBottomMenuLayout(
              mainContent: child,
              bottomNavigationBar: const AppBottomNavigationBar(),
            ),
          );
        },
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => ResponsiveLayout(
              desktopContent: const HomePageDesktop(),
              mobileContent: const HomePageMobile(initialTab: '/'),
            ),
          ),
          GoRoute(
            path: '/posts-and-replies',
            builder: (context, state) =>
                const HomePageMobile(initialTab: '/posts-and-replies'),
          ),
          GoRoute(
            path: '/search',
            builder: (context, state) => const SearchPage(),
          ),
          GoRoute(
            path: '/map',
            builder: (context, state) => const MapPage(),
            routes: [
              GoRoute(
                path: 'search',
                pageBuilder: (context, state) => CustomTransitionPage(
                  key: state.pageKey,
                  child: const MapSearchPage(),
                  transitionDuration: const Duration(milliseconds: 200),
                  reverseTransitionDuration: const Duration(milliseconds: 150),
                  transitionsBuilder: (context, animation, _, child) =>
                      FadeTransition(opacity: animation, child: child),
                ),
              ),
              GoRoute(
                path: 'navigation',
                builder: (context, state) => const MapNavigationPage(),
              ),
            ],
          ),
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const NotificationPage(),
          ),
          GoRoute(
            path: '/messages',
            builder: (context, state) => const DmListPage(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const NewDmPage(),
              ),
              GoRoute(
                path: ':peerIdentifier',
                builder: (context, state) => DmThreadPage(
                  peerIdentifier: state.pathParameters['peerIdentifier']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsPage(),
            routes: [
              GoRoute(
                path: 'file-servers',
                builder: (context, state) => const SettingsFileServers(),
              ),
              GoRoute(
                path: 'initial-route',
                builder: (context, state) => const InitalRouteSettings(),
              ),
              GoRoute(
                path: 'locale',
                builder: (context, state) => const LocaleSettingsPage(),
              ),
              GoRoute(
                path: 'moderation',
                builder: (context, state) => const ModerationSettingsPage(),
              ),
              GoRoute(
                path: 'theme',
                builder: (context, state) => const ThemeSettingsPage(),
              ),

              GoRoute(
                path: 'relays',
                builder: (context, state) => const Nip65RelaysSettings(),
              ),
              GoRoute(
                path: 'wallet',
                builder: (context, state) => const WalletSettingsPage(),
                routes: [
                  GoRoute(
                    path: 'restore',
                    builder: (context, state) => const WalletRestorePage(),
                  ),
                ],
              ),
              GoRoute(
                path: 'notifications',
                builder: (context, state) => const NotificationsSettingsPage(),
              ),
              GoRoute(
                path: 'developer',
                builder: (context, state) => const DeveloperSettingsPage(),
              ),
            ],
          ),
          GoRoute(
            path: '/relays',
            builder: (context, state) {
              return RelaysPage();
            },
          ),
          GoRoute(
            path: '/profile/:profileIdentifier',
            //redirect: _redirectProfileToCanonicalNip05,
            builder: (context, state) => ProfileResolverPage(
              identifier: state.pathParameters['profileIdentifier']!,
            ),
            routes: [
              GoRoute(
                path: 'edit',
                //redirect: _redirectProfileToCanonicalNip05,
                builder: (context, state) {
                  final profileIdentifier =
                      state.pathParameters['profileIdentifier']!;
                  final pubkey =
                      decodeProfileIdentifierToPubkey(profileIdentifier) ??
                      Uri.decodeComponent(profileIdentifier);

                  return EditProfilePage(pubkey: pubkey);
                },
              ),
              GoRoute(
                path: 'status/:eventId',
                //redirect: _redirectProfileToCanonicalNip05,
                builder: (context, state) => EventViewPage(
                  rootNoteId: state.pathParameters['eventId']!,
                  openNoteId: state.uri.queryParameters['scrollIntoView'],
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/search/feed',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: SearchFeedPage(
                query: state.uri.queryParameters['q'] ?? '',
              ),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) => child,
            ),
          ),
          GoRoute(
            path: '/bookmarks',
            builder: (context, state) => const BookmarksPage(),
          ),
          GoRoute(
            path: '/blocked-users',
            builder: (context, state) => const BlocklistPage(),
          ),
          GoRoute(
            path: '/lists',
            builder: (context, state) => const ListsPage(),
          ),
          GoRoute(
            path: '/lists/:kind/:name/edit',
            builder: (context, state) {
              final kind = int.parse(state.pathParameters['kind']!);
              final name = Uri.decodeComponent(state.pathParameters['name']!);
              final isNew = state.uri.queryParameters['new'] == 'true';
              final isPrivate = state.uri.queryParameters['private'] == 'true';
              final defaultTitle =
                  state.uri.queryParameters['defaultTitle'] != null
                  ? Uri.decodeQueryComponent(
                      state.uri.queryParameters['defaultTitle']!,
                    )
                  : null;
              return EditListPage(
                identifier: ListIdentifier(
                  name: name,
                  kind: kind,
                  defaultTitle: defaultTitle,
                  isPrivate: isPrivate,
                ),
                isNewList: isNew,
              );
            },
          ),
          GoRoute(
            path: '/starter/:pubkey/:name',
            builder: (context, state) {
              final pubkeyRaw = state.pathParameters['pubkey']!;
              final pubkey =
                  decodeProfileIdentifierToPubkey(pubkeyRaw) ?? pubkeyRaw;
              final name = Uri.decodeComponent(state.pathParameters['name']!);
              return StarterPackPage(pubkey: pubkey, name: name);
            },
            routes: [
              GoRoute(
                path: 'edit',
                builder: (context, state) {
                  final pubkeyRaw = state.pathParameters['pubkey']!;
                  final pubkey =
                      decodeProfileIdentifierToPubkey(pubkeyRaw) ?? pubkeyRaw;
                  final name = Uri.decodeComponent(
                    state.pathParameters['name']!,
                  );
                  final isNew = state.uri.queryParameters['new'] == 'true';
                  return StarterPackEditPage(
                    pubkey: pubkey,
                    name: name,
                    isNew: isNew,
                  );
                },
              ),
            ],
          ),
          ShellRoute(
            builder: (context, state, child) => WalletShellPage(child: child),
            routes: [
              GoRoute(
                path: '/wallet',
                redirect: (context, state) {
                  if (state.uri.path == '/wallet') {
                    return '/wallet/dashboard';
                  }
                  return null;
                },
                routes: [
                  GoRoute(
                    path: 'dashboard',
                    builder: (context, state) => WalletNavigation(title: 'a'),
                  ),
                  GoRoute(
                    path: 'receive',
                    builder: (context, state) => WalletReceivePage(),
                    routes: [
                      GoRoute(
                        path: 'ecash',
                        builder: (context, state) =>
                            WalletReceiveEcashCompleterPage(),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'mints',
                    builder: (context, state) => WalletNavigation(title: 'a'),
                  ),
                  GoRoute(
                    path: 'pay',
                    builder: (context, state) {
                      final extra = state.extra as Map<String, dynamic>?;
                      final initialPage = (extra?['initialPage'] as int?) ?? 0;
                      return WalletPayPage(initialPage: initialPage);
                    },
                    routes: [
                      GoRoute(
                        path: 'done',
                        builder: (context, state) => WalletPayDone(),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'add_mint',
                    builder: (context, state) => const AddMintPage(),
                  ),
                  GoRoute(
                    path: 'mint_details',
                    builder: (context, state) =>
                        MintInfoPage(mintUrl: state.extra as String?),
                  ),
                  GoRoute(
                    path: 'transactions/:transactionId',
                    builder: (context, state) => WalletTransactionDetailPage(
                      transaction:
                          state.extra as ndk_entities.WalletTransaction,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      // Routes outside the shell (no persistent layout)
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const NostrOnboarding(),
      ),

      GoRoute(
        path: '/:id',
        builder: (context, state) =>
            DeeplinkRecieverPage(userParam: state.pathParameters['id']!),
      ),

      GoRoute(
        path: '/profile/:profileIdentifier/status/:eventId/gallery',
        builder: (context, state) {
          final eventId = state.pathParameters['eventId']!;
          final start =
              int.tryParse(state.uri.queryParameters['start'] ?? '0') ?? 0;
          return EventGalleryPage(eventId: eventId, startIndex: start);
        },
      ),
      GoRoute(
        path: '/profile/:profileIdentifier/status/:eventId/video',
        builder: (context, state) {
          final eventId = state.pathParameters['eventId']!;
          final selectedVideoId = state.uri.queryParameters['video'];
          final videoLink = state.uri.queryParameters['src'];

          return FullScreenVideoPage(
            eventId: eventId,
            videoId: selectedVideoId,
            videoLink: videoLink,
          );
        },
      ),
    ],
  ),

  /// needed to support old installations
  GoRoute(
    path: '/',
    redirect: (context, state) {
      return '/home';
    },
  ),
];
