import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(TodoApp());
}

class TodoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'To-Do List',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        hintColor: Colors.teal,
        scaffoldBackgroundColor: Colors.grey[200],
        textTheme: TextTheme(
          bodyLarge: TextStyle(fontSize: 18.0, color: Colors.black87),
          bodyMedium: TextStyle(fontSize: 16.0, color: Colors.black54),
        ),
        appBarTheme: AppBarTheme(
          color: Colors.blueGrey[800],
          elevation: 0,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.teal,
        ),
        /*
        checkboxTheme: CheckboxThemeData(
          fillColor: MaterialStateProperty.resolveWith((states) => Colors.teal),
        ),*/
      ),
      home: TodoHomeScreen(),
    );
  }
}

class TodoHomeScreen extends StatefulWidget {
  @override
  _TodoHomeScreenState createState() => _TodoHomeScreenState();
}

class _TodoHomeScreenState extends State<TodoHomeScreen> {
  List<Task> tasks = [];
  late SharedPreferences prefs;
  bool isLoading = true; // For showing loading state

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    prefs = await SharedPreferences.getInstance();
    String? storedTasks = prefs.getString('tasks');
    setState(() {
      if (storedTasks != null) {
        tasks = (json.decode(storedTasks) as List).map((data) => Task.fromJson(data)).toList();
      }
      isLoading = false; // Stop loading once tasks are loaded
    });
  }

  void _saveTasks() {
    prefs.setString('tasks', json.encode(tasks));
  }

  void _addTask(String title, String description, String priority, DateTime dueDate) {
    setState(() {
      tasks.add(Task(
        title: title,
        description: description,
        priority: priority,
        dueDate: dueDate,
        isCompleted: false,
      ));
      _saveTasks();
    });
  }

  void _editTask(Task task, String newTitle, String newDescription, String newPriority, DateTime newDueDate) {
    setState(() {
      task.title = newTitle;
      task.description = newDescription;
      task.priority = newPriority;
      task.dueDate = newDueDate;
      _saveTasks();
    });
  }

  void _deleteTask(Task task) {
    setState(() {
      tasks.remove(task);
      _saveTasks();
    });
  }

  void _toggleTaskCompletion(Task task) {
    setState(() {
      task.isCompleted = !task.isCompleted;
      _saveTasks();
    });
  }

  void _openTaskDialog({Task? task}) {
    String title = task?.title ?? '';
    String description = task?.description ?? '';
    String priority = task?.priority ?? 'Low';
    DateTime dueDate = task?.dueDate ?? DateTime.now();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(task == null ? 'New Task' : 'Edit Task'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                onChanged: (value) => title = value,
                controller: TextEditingController(text: title),
                decoration: InputDecoration(labelText: 'Title'),
              ),
              TextField(
                onChanged: (value) => description = value,
                controller: TextEditingController(text: description),
                decoration: InputDecoration(labelText: 'Description'),
              ),
              DropdownButton<String>(
                value: priority,
                onChanged: (String? newValue) {
                  setState(() {
                    priority = newValue!;
                  });
                },
                items: <String>['Low', 'Medium', 'High'].map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              ElevatedButton(
                onPressed: () async {
                  final DateTime? selectedDate = await showDatePicker(
                    context: context,
                    initialDate: dueDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (selectedDate != null && selectedDate != dueDate) {
                    dueDate = selectedDate;
                  }
                },
                child: Text('Select Due Date'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                if (task == null) {
                  _addTask(title, description, priority, dueDate);
                } else {
                  _editTask(task, title, description, priority, dueDate);
                }
                Navigator.of(context).pop();
              },
              child: Text(task == null ? 'Add' : 'Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('To-Do List'),
      ),
      body: isLoading
          ? Center(
        child: CircularProgressIndicator(
          color: Colors.teal,
        ),
      )
          : ListView.builder(
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          return Card(
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 3,
            child: ListTile(
              title: Text(
                task.title,
                style: TextStyle(
                  decoration: task.isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'Priority: ${task.priority}, Due: ${task.dueDate.toLocal().toIso8601String().split('T').first}',
                style: TextStyle(
                  decoration: task.isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              trailing: Checkbox(
                value: task.isCompleted,
                onChanged: (_) => _toggleTaskCompletion(task),
              ),
              onTap: () => _openTaskDialog(task: task),
              onLongPress: () => _deleteTask(task),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openTaskDialog(),
        child: Icon(Icons.add),
      ),
    );
  }
}

class Task {
  String title;
  String description;
  String priority;
  DateTime dueDate;
  bool isCompleted;

  Task({
    required this.title,
    required this.description,
    required this.priority,
    required this.dueDate,
    required this.isCompleted,
  });

  factory Task.fromJson(Map<String, dynamic> jsonData) {
    return Task(
      title: jsonData['title'],
      description: jsonData['description'],
      priority: jsonData['priority'],
      dueDate: DateTime.parse(jsonData['dueDate']),
      isCompleted: jsonData['isCompleted'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'priority': priority,
      'dueDate': dueDate.toIso8601String(),
      'isCompleted': isCompleted,
    };
  }
}
