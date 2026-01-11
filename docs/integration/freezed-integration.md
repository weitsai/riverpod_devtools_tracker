# Freezed Integration Guide

This guide shows how to use Riverpod DevTools Tracker with [Freezed](https://pub.dev/packages/freezed) for immutable state management.

## Overview

Freezed generates immutable classes with `copyWith`, `==`, and `toJson` methods. The tracker automatically handles Freezed classes and displays state changes effectively.

## Installation

```yaml
dependencies:
  flutter_riverpod: ^3.1.0
  freezed_annotation: ^2.4.1
  riverpod_devtools_tracker: ^1.0.2

dev_dependencies:
  build_runner: ^2.4.6
  freezed: ^2.4.5
```

```bash
flutter pub get
```

## Complete Example

### 1. Define Freezed Model

```dart
// lib/models/user.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
class User with _$User {
  const factory User({
    required String id,
    required String name,
    required String email,
    @Default(false) bool isPremium,
    DateTime? lastLogin,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
```

### 2. Create State Model

```dart
// lib/models/user_state.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'user.dart';

part 'user_state.freezed.dart';

@freezed
class UserState with _$UserState {
  const factory UserState.initial() = _Initial;
  const factory UserState.loading() = _Loading;
  const factory UserState.loaded(User user) = _Loaded;
  const factory UserState.error(String message) = _Error;
}
```

### 3. Create Provider

```dart
// lib/providers/user_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../models/user_state.dart';
import '../services/user_service.dart';

final userProvider = StateNotifierProvider<UserNotifier, UserState>((ref) {
  return UserNotifier(ref.read(userServiceProvider));
});

class UserNotifier extends StateNotifier<UserState> {
  final UserService _userService;

  UserNotifier(this._userService) : super(const UserState.initial());

  Future<void> loadUser(String userId) async {
    state = const UserState.loading();

    try {
      final user = await _userService.getUser(userId);
      state = UserState.loaded(user);
    } catch (e) {
      state = UserState.error(e.toString());
    }
  }

  Future<void> updateUser(User updatedUser) async {
    final currentState = state;
    if (currentState is! _Loaded) return;

    state = const UserState.loading();

    try {
      final user = await _userService.updateUser(updatedUser);
      state = UserState.loaded(user);
    } catch (e) {
      state = UserState.error(e.toString());
      // Revert to previous state on error
      state = currentState;
    }
  }

  void upgradeToPremium() {
    state.whenOrNull(
      loaded: (user) {
        state = UserState.loaded(user.copyWith(isPremium: true));
      },
    );
  }
}
```

### 4. Setup Tracker

```dart
// lib/main.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_devtools_tracker/riverpod_devtools_tracker.dart';

void main() {
  runApp(
    ProviderScope(
      observers: [
        if (kDebugMode)
          RiverpodDevToolsObserver(
            config: TrackerConfig.forPackage(
              'my_app',
              // Ignore generated files
              ignoredFilePatterns: [
                '.g.dart',
                '.freezed.dart',
              ],
            ),
          ),
      ],
      child: const MyApp(),
    ),
  );
}
```

### 5. Use in UI

```dart
// lib/screens/user_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_provider.dart';

class UserScreen extends ConsumerWidget {
  final String userId;

  const UserScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(userProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('User Profile')),
      body: userState.when(
        initial: () => const Center(child: Text('No user loaded')),
        loading: () => const Center(child: CircularProgressIndicator()),
        loaded: (user) => _buildUserProfile(user, ref),
        error: (message) => Center(child: Text('Error: $message')),
      ),
    );
  }

  Widget _buildUserProfile(User user, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Name: ${user.name}', style: const TextStyle(fontSize: 18)),
          Text('Email: ${user.email}'),
          Text('Premium: ${user.isPremium ? "Yes" : "No"}'),
          if (user.lastLogin != null)
            Text('Last Login: ${user.lastLogin}'),
          const SizedBox(height: 16),
          if (!user.isPremium)
            ElevatedButton(
              onPressed: () {
                ref.read(userProvider.notifier).upgradeToPremium();
              },
              child: const Text('Upgrade to Premium'),
            ),
        ],
      ),
    );
  }
}
```

## How the Tracker Displays Freezed Objects

### State Transitions

The tracker shows clear state transitions:

```
UPDATE: userProvider
Before: UserState.initial()
After:  UserState.loading()

UPDATE: userProvider
Before: UserState.loading()
After:  UserState.loaded(User(id: '123', name: 'John', ...))

UPDATE: userProvider
Before: UserState.loaded(User(isPremium: false))
After:  UserState.loaded(User(isPremium: true))
```

### Call Chain

Shows exactly where state changes originated:

```
📍 Location: screens/user_screen.dart:45 in _buildUserProfile
📜 Call chain:
   → screens/user_screen.dart:45 in _buildUserProfile
     providers/user_provider.dart:38 in upgradeToPremium
```

## Best Practices

### 1. Filter Generated Files

Always ignore `.freezed.dart` and `.g.dart` files:

```dart
RiverpodDevToolsObserver(
  config: TrackerConfig.forPackage(
    'my_app',
    ignoredFilePatterns: ['.g.dart', '.freezed.dart'],
  ),
)
```

### 2. Use Union Types for State

Freezed union types work excellently with the tracker:

```dart
@freezed
class LoadingState<T> with _$LoadingState<T> {
  const factory LoadingState.idle() = _Idle;
  const factory LoadingState.loading() = _Loading;
  const factory LoadingState.success(T data) = _Success<T>;
  const factory LoadingState.failure(String error) = _Failure;
}
```

The tracker will show clear state transitions like:
- `LoadingState.idle()` → `LoadingState.loading()`
- `LoadingState.loading()` → `LoadingState.success(data)`

### 3. Leverage toJson for Better Display

Freezed automatically generates `toJson()` methods. The tracker uses these for better value serialization:

```dart
@freezed
class Product with _$Product {
  const factory Product({
    required String id,
    required String name,
    required double price,
    required List<String> tags,
  }) = _Product;

  factory Product.fromJson(Map<String, dynamic> json) => _$ProductFromJson(json);
}
```

In DevTools, you'll see:
```json
{
  "id": "prod-123",
  "name": "Widget",
  "price": 29.99,
  "tags": ["featured", "new"]
}
```

### 4. Use copyWith for Granular Updates

Track specific field changes:

```dart
void updateUserEmail(String newEmail) {
  state.whenOrNull(
    loaded: (user) {
      state = UserState.loaded(user.copyWith(email: newEmail));
    },
  );
}
```

The tracker shows exactly which field changed:
```
Before: User(email: 'old@example.com')
After:  User(email: 'new@example.com')
```

## Common Patterns

### Pattern 1: Async Loading States

```dart
@freezed
class DataState<T> with _$DataState<T> {
  const factory DataState.initial() = _Initial;
  const factory DataState.loading() = _Loading;
  const factory DataState.data(T value) = _Data<T>;
  const factory DataState.error(String message) = _Error;
}

class DataNotifier<T> extends StateNotifier<DataState<T>> {
  DataNotifier() : super(const DataState.initial());

  Future<void> loadData(Future<T> Function() loader) async {
    state = const DataState.loading();
    try {
      final data = await loader();
      state = DataState.data(data);
    } catch (e) {
      state = DataState.error(e.toString());
    }
  }
}
```

### Pattern 2: Form State Management

```dart
@freezed
class FormState with _$FormState {
  const factory FormState({
    @Default('') String name,
    @Default('') String email,
    @Default(false) bool isSubmitting,
    String? errorMessage,
  }) = _FormState;
}

class FormNotifier extends StateNotifier<FormState> {
  FormNotifier() : super(const FormState());

  void updateName(String name) {
    state = state.copyWith(name: name, errorMessage: null);
  }

  void updateEmail(String email) {
    state = state.copyWith(email: email, errorMessage: null);
  }

  Future<void> submit() async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    // Submit logic...
  }
}
```

### Pattern 3: Pagination State

```dart
@freezed
class PaginatedState<T> with _$PaginatedState<T> {
  const factory PaginatedState({
    @Default([]) List<T> items,
    @Default(false) bool isLoading,
    @Default(false) bool hasMore,
    int? nextPage,
    String? error,
  }) = _PaginatedState<T>;
}

class PaginationNotifier<T> extends StateNotifier<PaginatedState<T>> {
  PaginationNotifier() : super(const PaginatedState());

  Future<void> loadNextPage(Future<List<T>> Function(int) loader) async {
    if (state.isLoading || !state.hasMore) return;

    final page = state.nextPage ?? 1;
    state = state.copyWith(isLoading: true, error: null);

    try {
      final newItems = await loader(page);
      state = state.copyWith(
        items: [...state.items, ...newItems],
        isLoading: false,
        hasMore: newItems.isNotEmpty,
        nextPage: page + 1,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}
```

## Debugging Tips

### Finding the Source of State Changes

1. Open DevTools extension
2. Filter for your provider (e.g., "userProvider")
3. Click on an UPDATE event
4. Check the call chain - it shows the exact location where `state = ...` was called
5. Ignore `.freezed.dart` entries - they're just generated code

### Tracking copyWith Changes

The tracker shows before/after values, making it easy to see which fields changed:

```
Before: User(name: 'John', email: 'john@old.com', isPremium: false)
After:  User(name: 'John', email: 'john@new.com', isPremium: false)
```

You can immediately see that only `email` changed.

### Performance Considerations

Freezed classes are highly optimized, but for very large objects:

```dart
RiverpodDevToolsObserver(
  config: TrackerConfig.forPackage(
    'my_app',
    maxValueLength: 500,  // Limit string representation
    maxCallChainDepth: 5, // Reduce stack depth
  ),
)
```

## Troubleshooting

### Issue: Too many update events

**Problem**: Provider updates on every `copyWith` call

**Solution**: Enable `skipUnchangedValues`:

```dart
TrackerConfig.forPackage('my_app', skipUnchangedValues: true)
```

### Issue: Can't see field changes

**Problem**: Freezed objects show as "Instance of ..."

**Solution**: Ensure `toJson()` is implemented and generated files are up to date:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Issue: Stack traces show generated files

**Problem**: Call chain cluttered with `.freezed.dart` files

**Solution**: Filter them out:

```dart
ignoredFilePatterns: ['.g.dart', '.freezed.dart']
```

## Related Resources

- [Freezed Package](https://pub.dev/packages/freezed)
- [Riverpod StateNotifier](https://riverpod.dev/docs/providers/state_notifier_provider)
- [Quick Reference](../QUICK_REFERENCE.md)
- [Main Documentation](../../README.md)
