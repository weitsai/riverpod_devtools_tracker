import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/user_provider.dart';

class UserScreen extends ConsumerWidget {
  const UserScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userDataProvider);
    final isLoggedIn = ref.watch(isLoggedInProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('使用者資料範例'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isLoggedIn ? Icons.check_circle : Icons.cancel,
                          color: isLoggedIn ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isLoggedIn ? '已登入' : '未登入',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (user != null) ...[
                      const Divider(height: 24),
                      _buildUserInfo('姓名', user.name),
                      const SizedBox(height: 8),
                      _buildUserInfo('年齡', '${user.age}'),
                      const SizedBox(height: 8),
                      _buildUserInfo('Email', user.email),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (!isLoggedIn) ...[
              ElevatedButton.icon(
                onPressed: () => _login(ref),
                icon: const Icon(Icons.login),
                label: const Text('登入'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ] else ...[
              ElevatedButton.icon(
                onPressed: () => _updateUserName(ref, context),
                icon: const Icon(Icons.edit),
                label: const Text('更改姓名'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => _incrementAge(ref),
                icon: const Icon(Icons.cake),
                label: const Text('增加年齡'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => _logout(ref),
                icon: const Icon(Icons.logout),
                label: const Text('登出'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfo(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // 這些方法會觸發狀態變化，並被 DevTools 追蹤
  void _login(WidgetRef ref) {
    ref.read(userDataProvider.notifier).login(
      const User(
        name: '張小明',
        age: 25,
        email: 'ming@example.com',
      ),
    );
  }

  void _logout(WidgetRef ref) {
    ref.read(userDataProvider.notifier).logout();
  }

  void _incrementAge(WidgetRef ref) {
    ref.read(userDataProvider.notifier).incrementAge();
  }

  void _updateUserName(WidgetRef ref, BuildContext context) {
    final currentUser = ref.read(userDataProvider);
    if (currentUser == null) return;

    final controller = TextEditingController(text: currentUser.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('更改姓名'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '新姓名',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(userDataProvider.notifier).updateName(controller.text);
              Navigator.of(context).pop();
            },
            child: const Text('確定'),
          ),
        ],
      ),
    );
  }
}
