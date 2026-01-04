import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_provider.g.dart';

/// 使用者資料模型
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

/// 使用者 Notifier - 展示複雜物件的狀態變化
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

/// 是否已登入 Provider
@riverpod
bool isLoggedIn(ref) {
  final user = ref.watch(userDataProvider);
  return user != null;
}
