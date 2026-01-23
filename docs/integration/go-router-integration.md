# Go Router Integration Guide

This guide shows how to use Riverpod DevTools Tracker with [go_router](https://pub.dev/packages/go_router) for declarative routing and navigation state tracking.

## Overview

go_router is a declarative routing package that works seamlessly with Riverpod. The tracker helps you debug navigation state, route changes, and redirect logic.

## Installation

```yaml
dependencies:
  flutter_riverpod: ^3.1.0
  go_router: ^14.0.0
  riverpod_devtools_tracker: ^1.0.2
```

```bash
flutter pub get
```

## Complete Example

### 1. Define Route State

```dart
// lib/models/app_route.dart
enum AppRoute {
  home('/'),
  login('/login'),
  profile('/profile'),
  settings('/settings'),
  productList('/products'),
  productDetail('/products/:id');

  const AppRoute(this.path);
  final String path;
}
```

### 2. Create Auth State Provider

```dart
// lib/providers/auth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthState {
  final bool isAuthenticated;
  final String? userId;

  const AuthState({
    required this.isAuthenticated,
    this.userId,
  });

  const AuthState.unauthenticated()
      : isAuthenticated = false,
        userId = null;

  const AuthState.authenticated(this.userId) : isAuthenticated = true;
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState.unauthenticated());

  Future<void> signIn(String email, String password) async {
    // Simulate authentication
    await Future.delayed(const Duration(seconds: 1));
    state = const AuthState.authenticated('user-123');
  }

  void signOut() {
    state = const AuthState.unauthenticated();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
```

### 3. Create Router Configuration Provider

```dart
// lib/providers/router_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/app_route.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/product_list_screen.dart';
import '../screens/product_detail_screen.dart';
import 'auth_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: AppRoute.home.path,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final isGoingToLogin = state.matchedLocation == AppRoute.login.path;

      // Redirect to login if not authenticated and not already going there
      if (!isAuthenticated && !isGoingToLogin) {
        return AppRoute.login.path;
      }

      // Redirect to home if authenticated and trying to access login
      if (isAuthenticated && isGoingToLogin) {
        return AppRoute.home.path;
      }

      return null; // No redirect needed
    },
    routes: [
      GoRoute(
        path: AppRoute.home.path,
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoute.login.path,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoute.profile.path,
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoute.settings.path,
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoute.productList.path,
        name: 'products',
        builder: (context, state) => const ProductListScreen(),
        routes: [
          GoRoute(
            path: ':id',
            name: 'product-detail',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return ProductDetailScreen(productId: id);
            },
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.matchedLocation}'),
      ),
    ),
  );
});
```

### 4. Setup Tracker with go_router Filtering

```dart
// lib/main.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_devtools_tracker/riverpod_devtools_tracker.dart';
import 'providers/router_provider.dart';

void main() {
  runApp(
    ProviderScope(
      observers: [
        if (kDebugMode)
          RiverpodDevToolsObserver(
            config: TrackerConfig.forPackage(
              'my_app',
              // Filter out go_router internal packages
              ignoredPackagePrefixes: [
                'package:flutter/',
                'package:flutter_riverpod/',
                'package:riverpod/',
                'package:go_router/',  // Ignore go_router internals
                'dart:',
              ],
            ),
          ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'My App',
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
```

### 5. Navigation in Screens

```dart
// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/app_route.dart';
import '../providers/auth_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authProvider.notifier).signOut();
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Welcome, ${authState.userId ?? "Guest"}!'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.push(AppRoute.profile.path),
              child: const Text('Go to Profile'),
            ),
            ElevatedButton(
              onPressed: () => context.push(AppRoute.productList.path),
              child: const Text('Browse Products'),
            ),
            ElevatedButton(
              onPressed: () => context.push(AppRoute.settings.path),
              child: const Text('Settings'),
            ),
          ],
        ),
      ),
    );
  }
}
```

## Tracking Navigation State

### What the Tracker Shows

When navigation occurs, the tracker shows:

```
UPDATE: authProvider
Location: screens/home_screen.dart:23 in build.<anonymous closure>
Before: AuthState(isAuthenticated: true, userId: 'user-123')
After:  AuthState(isAuthenticated: false, userId: null)
```

This triggered the router's redirect logic, which you can observe in the router provider updates.

### Debugging Redirects

The tracker helps debug complex redirect logic:

1. **User signs out**:
   ```
   UPDATE: authProvider
   Before: AuthState.authenticated('user-123')
   After:  AuthState.unauthenticated()
   ```

2. **Router redirects to login**:
   ```
   Router redirect triggered
   From: /profile
   To: /login
   ```

## Advanced Patterns

### Pattern 1: Navigation History Provider

Track navigation history for analytics or debugging:

```dart
// lib/providers/navigation_history_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NavigationHistoryNotifier extends StateNotifier<List<String>> {
  NavigationHistoryNotifier() : super([]);

  void push(String route) {
    state = [...state, route];
  }

  void clear() {
    state = [];
  }
}

final navigationHistoryProvider =
    StateNotifierProvider<NavigationHistoryNotifier, List<String>>((ref) {
  return NavigationHistoryNotifier();
});
```

Use with GoRouter observers:

```dart
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    // ... other config
    observers: [
      NavigationObserver(ref),
    ],
  );
});

class NavigationObserver extends NavigatorObserver {
  final Ref ref;

  NavigationObserver(this.ref);

  @override
  void didPush(Route route, Route? previousRoute) {
    ref.read(navigationHistoryProvider.notifier).push(route.settings.name ?? '');
  }
}
```

### Pattern 2: Deep Link State

Track deep link parameters:

```dart
// lib/providers/deep_link_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DeepLinkState {
  final String? productId;
  final String? referrer;

  const DeepLinkState({this.productId, this.referrer});
}

final deepLinkProvider = StateProvider<DeepLinkState>((ref) {
  return const DeepLinkState();
});
```

Use in route builder:

```dart
GoRoute(
  path: '/products/:id',
  builder: (context, state) {
    final id = state.pathParameters['id']!;
    final referrer = state.uri.queryParameters['ref'];

    // Update deep link state (tracked by DevTools)
    ref.read(deepLinkProvider.notifier).state = DeepLinkState(
      productId: id,
      referrer: referrer,
    );

    return ProductDetailScreen(productId: id);
  },
)
```

### Pattern 3: Route-Specific State

Manage state that should reset on navigation:

```dart
// lib/providers/search_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

final searchQueryProvider = StateProvider.autoDispose<String>((ref) {
  return '';
});

final searchResultsProvider = FutureProvider.autoDispose<List<Product>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.isEmpty) return [];

  // Track search queries in DevTools
  return await searchProducts(query);
});
```

The `.autoDispose` ensures state resets when leaving the route, and the tracker shows when this happens.

## Debugging Navigation Issues

### Issue 1: Infinite Redirect Loop

**Symptom**: App freezes, DevTools shows repeated redirects

**How to Debug**:
1. Open DevTools extension
2. Filter for your auth provider
3. Look for rapid UPDATE events
4. Check call chain to find redirect logic

**Example**:
```
UPDATE: authProvider (x100)
Location: providers/router_provider.dart:25 in redirect
```

**Fix**: Add proper redirect guards:
```dart
redirect: (context, state) {
  final isAuthenticated = authState.isAuthenticated;
  final isGoingToLogin = state.matchedLocation == AppRoute.login.path;

  // Prevent redirect loop
  if (!isAuthenticated && !isGoingToLogin) {
    return AppRoute.login.path;
  }

  if (isAuthenticated && isGoingToLogin) {
    return AppRoute.home.path;
  }

  return null; // Important: return null to stop redirecting
}
```

### Issue 2: State Not Persisting Across Routes

**Symptom**: Data lost when navigating

**How to Debug**:
1. Check DevTools for DISPOSE events
2. Look for `.autoDispose` providers

**Fix**: Remove `.autoDispose` or use `keepAlive`:
```dart
final userProfileProvider = FutureProvider.autoDispose<UserProfile>((ref) async {
  ref.keepAlive(); // Prevent disposal
  return fetchUserProfile();
});
```

### Issue 3: Unexpected Route Changes

**Symptom**: User navigates to wrong screen

**How to Debug**:
1. Track navigation history provider
2. Check DevTools for state changes before navigation
3. Review redirect logic in call chain

## Best Practices

### 1. Filter go_router Internals

Always filter out go_router internal calls:

```dart
ignoredPackagePrefixes: [
  'package:go_router/',
]
```

### 2. Use Meaningful Provider Names

Name providers clearly to track navigation state:

```dart
final currentRouteProvider = StateProvider<String>((ref) => '/');
final navigationStackProvider = StateProvider<List<String>>((ref) => []);
```

### 3. Track Route Parameters

Make route parameters observable:

```dart
final currentProductIdProvider = StateProvider<String?>((ref) => null);

// Update in route builder
GoRoute(
  path: '/products/:id',
  builder: (context, state) {
    final id = state.pathParameters['id'];
    ref.read(currentProductIdProvider.notifier).state = id;
    return ProductDetailScreen(productId: id!);
  },
)
```

### 4. Log Navigation Events

Create a dedicated navigation logger:

```dart
class NavigationLogger extends ProviderObserver {
  @override
  void didUpdateProvider(
    ProviderBase provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    if (provider == authProvider) {
      print('Auth state changed: $previousValue → $newValue');
    }
  }
}
```

## Performance Optimization

For apps with frequent navigation:

```dart
RiverpodDevToolsObserver(
  config: TrackerConfig.forPackage(
    'my_app',
    // Reduce overhead
    enableConsoleOutput: false,
    maxCallChainDepth: 5,

    // Filter navigation internals
    ignoredPackagePrefixes: [
      'package:go_router/',
      'package:flutter/',
    ],
  ),
)
```

## Common Use Cases

### Use Case 1: Auth-Based Routing

Track authentication state and automatic redirects:

```dart
// Watch for auth changes in DevTools
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(...);

// Router automatically redirects based on auth state
redirect: (context, state) {
  final isAuthenticated = ref.read(authProvider).isAuthenticated;
  // ... redirect logic
}
```

### Use Case 2: Analytics Tracking

Combine with analytics:

```dart
class AnalyticsObserver extends NavigatorObserver {
  final Ref ref;

  @override
  void didPush(Route route, Route? previousRoute) {
    final routeName = route.settings.name;
    ref.read(analyticsProvider).logScreenView(routeName);

    // This will show up in DevTools:
    // UPDATE: analyticsProvider
    // Location: observers/analytics_observer.dart:12
  }
}
```

### Use Case 3: Feature Flags

Control routing based on feature flags:

```dart
final featureFlagsProvider = StateProvider<Map<String, bool>>((ref) {
  return {'new_products_page': true};
});

GoRoute(
  path: '/products',
  redirect: (context, state) {
    final flags = ref.read(featureFlagsProvider);
    if (!flags['new_products_page']!) {
      return '/products-legacy';
    }
    return null;
  },
)
```

## Troubleshooting

### Router not updating on state change

**Solution**: Ensure router watches the provider:

```dart
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider); // Must watch!
  // ...
});
```

### Can't track route changes

**Solution**: Use navigation history provider or route observers

### Too many router updates

**Solution**: Use `skipUnchangedValues: true` and filter go_router packages

## Related Resources

- [go_router Documentation](https://pub.dev/packages/go_router)
- [Riverpod Routing Guide](https://riverpod.dev/docs/concepts/reading#using-ref-to-interact-with-providers)
- [Quick Reference](../QUICK_REFERENCE.md)
- [Main Documentation](../../README.md)
