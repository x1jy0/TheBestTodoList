import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Todo List',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: TodoListScreen(),
    );
  }
}

class TodoListScreen extends StatefulWidget {
  @override
  _TodoListScreenState createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  List<Task> tasks = [];
  List<Task> archivedTasks = [];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  _loadTasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> taskStrings = prefs.getStringList('tasks') ?? [];
    List<String> archivedTaskStrings =
        prefs.getStringList('archivedTasks') ?? [];

    setState(() {
      tasks = taskStrings.map((task) => Task.fromJson(task)).toList();
      archivedTasks =
          archivedTaskStrings.map((task) => Task.fromJson(task)).toList();
    });
  }

  _saveTasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> taskStrings = tasks.map((task) => task.toJson()).toList();
    List<String> archivedTaskStrings =
        archivedTasks.map((task) => task.toJson()).toList();

    await prefs.setStringList('tasks', taskStrings);
    await prefs.setStringList('archivedTasks', archivedTaskStrings);
  }

  void _addTask(Task task) {
    setState(() {
      tasks.add(task);
    });
    _saveTasks();
  }

  void _archiveTask(Task task) {
    setState(() {
      tasks.remove(task);
      archivedTasks.add(task);
    });
    _saveTasks();
  }

  void _unarchiveTask(Task task) {
    setState(() {
      archivedTasks.remove(task);
      tasks.add(task);
    });
    _saveTasks();
  }

  void _deleteTask(Task task) {
    setState(() {
      tasks.remove(task);
    });
    _saveTasks();
  }

  void _deleteArchivedTask(Task task) {
    setState(() {
      archivedTasks.remove(task);
    });
    _saveTasks();
  }

  void _addSubTask(Task parentTask, Task subTask) {
    setState(() {
      parentTask.subTasks.add(subTask);
    });
    _saveTasks();
  }

  void _deleteSubTask(Task parentTask, Task subTask) {
    setState(() {
      parentTask.subTasks.remove(subTask);
    });
    _saveTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Todo List'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                return TaskWidget(
                  task: tasks[index],
                  onArchive: () => _archiveTask(tasks[index]),
                  onDelete: () => _deleteTask(tasks[index]),
                  onAddSubTask: (subTask) => _addSubTask(tasks[index], subTask),
                  onDeleteSubTask: (subTask) =>
                      _deleteSubTask(tasks[index], subTask),
                  depth: 0,
                );
              },
            ),
          ),
          Divider(),
          Text('Archived Tasks'),
          Expanded(
            child: ListView.builder(
              itemCount: archivedTasks.length,
              itemBuilder: (context, index) {
                return TaskWidget(
                  task: archivedTasks[index],
                  isArchived: true,
                  onUnarchive: () => _unarchiveTask(archivedTasks[index]),
                  onDelete: () => _deleteArchivedTask(archivedTasks[index]),
                  onAddSubTask: (subTask) =>
                      _addSubTask(archivedTasks[index], subTask),
                  onDeleteSubTask: (subTask) =>
                      _deleteSubTask(archivedTasks[index], subTask),
                  depth: 0,
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              return NewTaskDialog(
                onAddTask: _addTask,
              );
            },
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

class Task {
  String title;
  List<Task> subTasks;
  bool isCompleted;

  Task(
      {required this.title,
      this.subTasks = const [],
      this.isCompleted = false});

  Task.fromJson(String json)
      : title = json.split('|')[0],
        subTasks = json.split('|').length > 1
            ? (json
                .split('|')[1]
                .split(';')
                .map((subTask) => Task.fromJson(subTask))
                .toList())
            : [],
        isCompleted =
            json.split('|').length > 2 ? json.split('|')[2] == 'true' : false;

  String toJson() {
    return '$title|${subTasks.map((subTask) => subTask.toJson()).join(';')}|$isCompleted';
  }
}

class TaskWidget extends StatefulWidget {
  final Task task;
  final bool isArchived;
  final VoidCallback? onArchive;
  final VoidCallback? onUnarchive;
  final VoidCallback? onDelete;
  final Function(Task)? onAddSubTask;
  final Function(Task)? onDeleteSubTask;
  final int depth;

  TaskWidget({
    required this.task,
    this.isArchived = false,
    this.onArchive,
    this.onUnarchive,
    this.onDelete,
    this.onAddSubTask,
    this.onDeleteSubTask,
    required this.depth,
  });

  @override
  _TaskWidgetState createState() => _TaskWidgetState();
}

class _TaskWidgetState extends State<TaskWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.only(left: 16.0 * widget.depth),
          title: Row(
            children: [
              Text(widget.task.title),
              if (widget.task.subTasks.isNotEmpty) Icon(Icons.arrow_drop_down),
            ],
          ),
          leading: Checkbox(
            value: widget.task.isCompleted,
            onChanged: (bool? value) {
              setState(() {
                widget.task.isCompleted = value!;
              });
            },
          ),
          trailing: widget.isArchived
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.add),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return NewSubTaskDialog(
                              onAddSubTask: (subTask) {
                                widget.onAddSubTask?.call(subTask);
                                setState(() {}); // Refresh UI
                              },
                            );
                          },
                        );
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.unarchive),
                      onPressed: widget.onUnarchive,
                    ),
                    IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: widget.onDelete,
                    ),
                  ],
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.add),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return NewSubTaskDialog(
                              onAddSubTask: (subTask) {
                                widget.onAddSubTask?.call(subTask);
                                setState(() {}); // Refresh UI
                              },
                            );
                          },
                        );
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.archive),
                      onPressed: widget.onArchive,
                    ),
                    IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: widget.onDelete,
                    ),
                  ],
                ),
          onTap: () {
            if (widget.task.subTasks.isNotEmpty) {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            }
          },
        ),
        if (_isExpanded)
          Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Column(
              children: widget.task.subTasks
                  .map((subTask) => TaskWidget(
                        task: subTask,
                        isArchived: widget.isArchived,
                        onArchive: widget.onArchive,
                        onUnarchive: widget.onUnarchive,
                        onDelete: () => widget.onDeleteSubTask?.call(subTask),
                        onAddSubTask: widget.onAddSubTask,
                        onDeleteSubTask: widget.onDeleteSubTask,
                        depth: widget.depth + 1,
                      ))
                  .toList(),
            ),
          ),
      ],
    );
  }
}

class NewTaskDialog extends StatefulWidget {
  final Function(Task) onAddTask;

  NewTaskDialog({required this.onAddTask});

  @override
  _NewTaskDialogState createState() => _NewTaskDialogState();
}

class _NewTaskDialogState extends State<NewTaskDialog> {
  TextEditingController _titleController = TextEditingController();
  List<Task> _subTasks = [];

  void _addSubTask(String title) {
    setState(() {
      _subTasks.add(Task(title: title));
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('New Task'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            decoration: InputDecoration(labelText: 'Task Title'),
          ),
          ..._subTasks
              .map((subTask) => ListTile(title: Text(subTask.title)))
              .toList(),
          TextField(
            decoration: InputDecoration(labelText: 'Sub Task Title'),
            onSubmitted: _addSubTask,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            widget.onAddTask(
                Task(title: _titleController.text, subTasks: _subTasks));
            Navigator.of(context).pop();
          },
          child: Text('Add'),
        ),
      ],
    );
  }
}

class NewSubTaskDialog extends StatefulWidget {
  final Function(Task) onAddSubTask;

  NewSubTaskDialog({required this.onAddSubTask});

  @override
  _NewSubTaskDialogState createState() => _NewSubTaskDialogState();
}

class _NewSubTaskDialogState extends State<NewSubTaskDialog> {
  TextEditingController _titleController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('New Sub Task'),
      content: TextField(
        controller: _titleController,
        decoration: InputDecoration(labelText: 'Sub Task Title'),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            widget.onAddSubTask(Task(title: _titleController.text));
            Navigator.of(context).pop();
          },
          child: Text('Add'),
        ),
      ],
    );
  }
}
