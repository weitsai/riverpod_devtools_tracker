import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/todo_provider.dart';

class TodoScreen extends ConsumerWidget {
  const TodoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todos = ref.watch(todoListProvider);
    final completedCount = ref.watch(completedTodoCountProvider);
    final activeCount = ref.watch(activeTodoCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('待辦事項範例'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          _buildStatistics(completedCount, activeCount),
          Expanded(
            child: todos.isEmpty
                ? const Center(
                    child: Text(
                      '目前沒有待辦事項\n點擊下方按鈕新增',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: todos.length,
                    itemBuilder: (context, index) {
                      final todo = todos[index];
                      return _buildTodoItem(context, ref, todo);
                    },
                  ),
          ),
          if (completedCount > 0)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton.icon(
                onPressed: () => _clearCompleted(ref),
                icon: const Icon(Icons.clear_all),
                label: const Text('清除已完成'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTodoDialog(context, ref),
        tooltip: '新增待辦事項',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatistics(int completedCount, int activeCount) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('待完成', activeCount, Colors.orange),
            Container(
              width: 1,
              height: 40,
              color: Colors.grey[300],
            ),
            _buildStatItem('已完成', completedCount, Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          '$count',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildTodoItem(BuildContext context, WidgetRef ref, Todo todo) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Checkbox(
          value: todo.completed,
          onChanged: (_) => _toggleTodo(ref, todo.id),
        ),
        title: Text(
          todo.title,
          style: TextStyle(
            decoration: todo.completed ? TextDecoration.lineThrough : null,
            color: todo.completed ? Colors.grey : null,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _removeTodo(ref, todo.id),
        ),
      ),
    );
  }

  void _showAddTodoDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新增待辦事項'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: '事項內容',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              _addTodo(ref, value.trim());
              Navigator.of(context).pop();
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                _addTodo(ref, text);
                Navigator.of(context).pop();
              }
            },
            child: const Text('新增'),
          ),
        ],
      ),
    );
  }

  // 這些方法會觸發狀態變化，並被 DevTools 追蹤
  void _addTodo(WidgetRef ref, String title) {
    ref.read(todoListProvider.notifier).addTodo(title);
  }

  void _toggleTodo(WidgetRef ref, String id) {
    ref.read(todoListProvider.notifier).toggleTodo(id);
  }

  void _removeTodo(WidgetRef ref, String id) {
    ref.read(todoListProvider.notifier).removeTodo(id);
  }

  void _clearCompleted(WidgetRef ref) {
    ref.read(todoListProvider.notifier).clearCompleted();
  }
}
