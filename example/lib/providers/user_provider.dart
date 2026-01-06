import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_provider.g.dart';

/// User data model
class User {
  final String name;
  final int age;
  final String email;

  const User({
    required this.name,
    required this.age,
    required this.email,
  });

  User copyWith({
    String? name,
    int? age,
    String? email,
  }) {
    return User(
      name: name ?? this.name,
      age: age ?? this.age,
      email: email ?? this.email,
    );
  }

  @override
  String toString() => 'User(name: $name, age: $age, email: $email)';
}

/// User Notifier - demonstrates complex object state changes
@riverpod
class UserData extends _$UserData {
  @override
  User? build() => null;

  void login(User user) => state = user;
  void logout() => state = null;

  void updateName(String name) {
    if (state != null) {
      state = state!.copyWith(name: name);
    }
  }

  void incrementAge() {
    if (state != null) {
      state = state!.copyWith(age: state!.age + 1);
    }
  }
}

/// Is logged in Provider
@riverpod
bool isLoggedIn(ref) {
  final user = ref.watch(userDataProvider);
  return user != null;
}
