import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/auth_provider.dart';
import '../providers/realtime_provider.dart';
import '../providers/terms_provider.dart';
import '../screens/login_screen.dart';
import '../screens/security_setup_screen.dart';
import '../screens/terms_screen.dart';
import '../screens/deals_list_screen.dart';
import '../screens/deal_detail_screen.dart';
import '../screens/psf_list_screen.dart';
import '../screens/funded_screen.dart';
import '../screens/updates_screen.dart';
import '../providers/update_checker_provider.dart';
import 'theme.dart';

final _rootKey = GlobalKey<NavigatorState>();
final _shellKey = GlobalKey<NavigatorState>();

class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(Ref ref) {
    ref.listen(authStateProvider, (_, __) => notifyListeners());
    ref.listen(termsAcceptedProvider, (_, __) => notifyListeners());
    ref.listen(securitySetupDoneProvider, (_, __) => notifyListeners());
    ref.listen(appLockedProvider, (_, __) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh(ref);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/deals',
    refreshListenable: refresh,
    redirect: (context, state) {
      final hasSession = Supabase.instance.client.auth.currentSession != null;
      final loc = state.matchedLocation;
      final onLogin = loc == '/login';
      final onTerms = loc == '/terms';
      final onSecurity = loc == '/security-setup';
      final lockedState = ref.read(appLockedProvider);
      final isLocked = lockedState.valueOrNull ?? false;

      // If app is locked (has saved email + security), show login for PIN/biometric
      // even if session expired — the login flow will refresh the session
      final loggedIn = hasSession || isLocked;

      // Not logged in at all → login
      if (!loggedIn && !onLogin) return '/login';

      if (loggedIn) {
        if (lockedState.isLoading) return null;

        // App is locked → show login for PIN/biometric
        if (isLocked) return onLogin ? null : '/login';

        final termsState = ref.read(termsAcceptedProvider);
        final securityState = ref.read(securitySetupDoneProvider);
        if (termsState.isLoading || securityState.isLoading) return null;

        final accepted = termsState.valueOrNull ?? false;
        final securityDone = securityState.valueOrNull ?? false;

        // Step 1: Terms
        if (!accepted && !onTerms) return '/terms';
        if (accepted && onTerms) {
          return securityDone ? '/deals' : '/security-setup';
        }

        // Step 2: Security setup
        if (accepted && !securityDone && !onSecurity) return '/security-setup';

        // All done → go to deals
        if (accepted && securityDone && (onLogin || onSecurity)) return '/deals';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/terms',
        builder: (_, __) => const TermsScreen(),
      ),
      GoRoute(
        path: '/security-setup',
        builder: (_, __) => const SecuritySetupScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellKey,
        builder: (_, __, child) => _Shell(child: child),
        routes: [
          GoRoute(
            path: '/deals',
            builder: (_, __) => const DealsListScreen(),
            routes: [
              GoRoute(
                path: ':id',
                parentNavigatorKey: _rootKey,
                builder: (_, state) => DealDetailScreen(
                  dealId: int.parse(state.pathParameters['id']!),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/psf',
            builder: (_, __) => const PsfListScreen(),
          ),
          GoRoute(
            path: '/funded',
            builder: (_, __) => const FundedScreen(),
          ),
          GoRoute(
            path: '/updates',
            builder: (_, __) => const UpdatesScreen(),
          ),
        ],
      ),
    ],
  );
});

class _Shell extends ConsumerWidget {
  final Widget child;
  const _Shell({required this.child});

  static int _indexOf(String loc) {
    if (loc.startsWith('/deals')) return 0;
    if (loc.startsWith('/psf')) return 1;
    if (loc.startsWith('/funded')) return 2;
    if (loc.startsWith('/updates')) return 3;
    return 0;
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, size: 22, color: C.declined),
            SizedBox(width: 10),
            Text('Logout', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ],
        ),
        content: const Text('Are you sure you want to logout?',
            style: TextStyle(color: C.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: C.declined,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(loginProvider.notifier).logout();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Check for updates on first build
    ref.listen(updateCheckerProvider, (_, next) {
      final update = next.valueOrNull;
      if (update != null && context.mounted) {
        showUpdateDialog(context, update);
      }
    });

    final loc = GoRouterState.of(context).matchedLocation;
    return Scaffold(
      body: child,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(height: 1, color: C.border),
          NavigationBar(
            selectedIndex: _indexOf(loc),
            onDestinationSelected: (i) {
              switch (i) {
                case 0:
                  context.go('/deals');
                case 1:
                  context.go('/psf');
                case 2:
                  context.go('/funded');
                case 3:
                  context.go('/updates');
                case 4:
                  _confirmLogout(context, ref);
              }
            },
            backgroundColor: C.surface,
            indicatorColor: C.approvedBg,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard, color: C.primary),
                label: 'Deals',
              ),
              NavigationDestination(
                icon: Icon(Icons.description_outlined),
                selectedIcon: Icon(Icons.description, color: C.primary),
                label: 'PSF',
              ),
              NavigationDestination(
                icon: Icon(Icons.paid_outlined),
                selectedIcon: Icon(Icons.paid, color: C.primary),
                label: 'Funded',
              ),
              NavigationDestination(
                icon: Icon(Icons.notifications_outlined),
                selectedIcon: Icon(Icons.notifications, color: C.primary),
                label: 'Updates',
              ),
              NavigationDestination(
                icon: Icon(Icons.logout_rounded, color: C.textTertiary),
                selectedIcon: Icon(Icons.logout_rounded, color: C.declined),
                label: 'Logout',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
