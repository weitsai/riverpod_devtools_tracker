import 'package:flutter/material.dart';

import 'counter_screen.dart';
import 'user_screen.dart';
import 'async_data_screen.dart';
import 'todo_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riverpod DevTools Tracker 範例'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildExampleCard(
            context,
            title: '計數器範例',
            description: '展示基本的狀態變化追蹤\n包含計數器及其衍生狀態',
            icon: Icons.add_circle_outline,
            color: Colors.blue,
            onTap: () => _navigateTo(context, const CounterScreen()),
          ),
          const SizedBox(height: 16),
          _buildExampleCard(
            context,
            title: '使用者資料範例',
            description: '展示複雜物件的狀態變化\n追蹤登入狀態和個人資料更新',
            icon: Icons.person_outline,
            color: Colors.green,
            onTap: () => _navigateTo(context, const UserScreen()),
          ),
          const SizedBox(height: 16),
          _buildExampleCard(
            context,
            title: '非同步資料範例',
            description: '展示 AsyncValue 的狀態追蹤\n包含載入、成功、錯誤狀態',
            icon: Icons.cloud_download_outlined,
            color: Colors.orange,
            onTap: () => _navigateTo(context, const AsyncDataScreen()),
          ),
          const SizedBox(height: 16),
          _buildExampleCard(
            context,
            title: '待辦事項範例',
            description: '展示列表的增刪改操作追蹤\n完整的 CRUD 操作示範',
            icon: Icons.checklist_outlined,
            color: Colors.purple,
            onTap: () => _navigateTo(context, const TodoScreen()),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🔍 使用說明',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildInstruction(
              '1. 點擊下方的範例卡片進入各個示範頁面',
            ),
            _buildInstruction(
              '2. 操作 UI 元件觸發狀態變化',
            ),
            _buildInstruction(
              '3. 打開 DevTools 擴展查看詳細的狀態變化追蹤',
            ),
            _buildInstruction(
              '4. 可以看到觸發變化的確切代碼位置和調用堆疊',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstruction(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExampleCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => screen),
    );
  }
}
