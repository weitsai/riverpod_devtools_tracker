import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'todo_provider.g.dart';

/// 待辦事項模型
class Todo {
  final String id;
  final String title;
  final bool completed;

  const Todo({
    required this.id,
    required this.title,
    this.completed = false,
  });

  Todo copyWith({
    String? id,
    String? title,
    bool? completed,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      completed: completed ?? this.completed,
    );
  }

  @override
  String toString() => 'Todo(id: $id, title: $title, completed: $completed)';
}

/// 待辦事項列表 Notifier - 展示列表的增刪改
@riverpod
class TodoList extends _$TodoList {
  @override
  List<Todo> build() {
    return [];
  }

  void addTodo(String title) {
    final newTodo = Todo(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
    );
    state = [...state, newTodo];
  }

  void toggleTodo(String id) {
    state = [
      for (final todo in state)
        if (todo.id == id)
          todo.copyWith(completed: !todo.completed)
        else
          todo,
    ];
  }

  void removeTodo(String id) {
    state = state.where((todo) => todo.id != id).toList();
  }

  void clearCompleted() {
    state = state.where((todo) => !todo.completed).toList();
  }
}

/// 已完成的待辦事項數量
@riverpod
int completedTodoCount(Ref ref) {
  final todos = ref.watch(todoListProvider);
  return todos.where((todo) => todo.completed).length;
}

/// 未完成的待辦事項數量
@riverpod
int activeTodoCount(Ref ref) {
  final todos = ref.watch(todoListProvider);
  return todos.where((todo) => !todo.completed).length;
}
