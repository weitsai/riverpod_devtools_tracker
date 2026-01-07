import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';

import '../providers/todo_provider.dart';

class TodoScreen extends ConsumerWidget {
  const TodoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final todos = ref.watch(todoListProvider);
    final completedCount = ref.watch(completedTodoCountProvider);
    final activeCount = ref.watch(activeTodoCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.todoScreenTitle),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          _buildStatistics(completedCount, activeCount),
          Expanded(
            child:
                todos.isEmpty
                    ? Center(
                      child: Text(
                        l10n.noTodosMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
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
                label: Text(l10n.clearCompleted),
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
        tooltip: l10n.addTodo,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatistics(int completedCount, int activeCount) {
    return Builder(
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(l10n.pending, activeCount, Colors.orange),
                Container(width: 1, height: 40, color: Colors.grey[300]),
                _buildStatItem(l10n.completed, completedCount, Colors.green),
              ],
            ),
          ),
        );
      },
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
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
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
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text(l10n.addTodoDialogTitle),
            content: TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                labelText: l10n.todoContent,
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  _addTodo(ref, value.trim());
                  Navigator.of(dialogContext).pop();
                }
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(l10n.cancel),
              ),
              ElevatedButton(
                onPressed: () {
                  final text = controller.text.trim();
                  if (text.isNotEmpty) {
                    _addTodo(ref, text);
                    Navigator.of(dialogContext).pop();
                  }
                },
                child: Text(l10n.add),
              ),
            ],
          ),
    );
  }

  // These methods will trigger state changes and be tracked by DevTools
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
