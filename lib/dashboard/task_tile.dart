import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/supabase_service.dart';
import 'task_model.dart';

class TaskTile extends StatelessWidget {
  final Task task;
  final Function? onTaskUpdated;

  const TaskTile({
    super.key,
    required this.task,
    this.onTaskUpdated,
  });

  void _showEditTaskDialog(BuildContext context) {
    final titleController = TextEditingController(text: task.title);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Task'),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(
            labelText: 'Task Title',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (titleController.text.trim().isNotEmpty) {
                final updatedTask = task.copyWith(
                  title: titleController.text.trim(),
                );
                context.read<SupabaseService>().updateTask(updatedTask);
                Navigator.of(context).pop();
                if (onTaskUpdated != null) {
                  onTaskUpdated!();
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Task'),
            content: const Text('Are you sure you want to delete this task?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        context.read<SupabaseService>().deleteTask(task.id);
        if (onTaskUpdated != null) {
          onTaskUpdated!();
        }
      },
      child: Card(
        child: ListTile(
          leading: Checkbox(
            value: task.isCompleted,
            onChanged: (value) {
              if (value != null) {
                context.read<SupabaseService>().updateTask(
                      task.copyWith(isCompleted: value),
                    );
                if (onTaskUpdated != null) {
                  onTaskUpdated!();
                }
              }
            },
          ),
          title: Text(
            task.title,
            style: TextStyle(
              decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            ),
          ),
          subtitle: Text(
            'Created: ${task.createdAt.toString().split('.').first}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: () => _showEditTaskDialog(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
