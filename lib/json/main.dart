import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(dir.path);
  //print('Hive base path: ${dir.path}');
  await Hive.openBox<List>('tasks_box');

  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(theme: ThemeData.light(useMaterial3: true), home: const TodoPage());
  }
}

class Task {
  final String title;
  final bool done;
  const Task({required this.title, required this.done});

  Task copyWith({String? title, bool? done}) => Task(title: title ?? this.title, done: done ?? this.done);

  Map<String, dynamic> toMap() => {"title": title, "done": done};

  static Task fromMap(Map<String, dynamic> m) => Task(title: m["title"] as String, done: m["done"] as bool);
}

class TodoPage extends StatefulWidget {
  const TodoPage({super.key});
  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  static const storageKey = 'tasks_dual_v1';
  final c = TextEditingController();

  late final Box<List> box;
  List<Task> tasks = [];
  bool ready = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    box = Hive.box<List>('tasks_box');
    await _load();
    setState(() => ready = true);
  }

  Future<void> _load() async {
    final raw = box.get(storageKey);
    tasks = raw == null ? [] : raw.map((e) => Task.fromMap(Map<String, dynamic>.from(e as Map))).toList();
    setState(() {});
  }

  Future<void> _save() async {
    await box.put(storageKey, tasks.map((t) => t.toMap()).toList());
  }

  Future<void> _add() async {
    final text = c.text.trim();
    if (text.isEmpty) return;
    setState(() {
      tasks.insert(0, Task(title: text, done: false));
      c.clear();
    });
    await _save();
  }

  Future<void> _toggle(int i) async {
    setState(() => tasks[i] = tasks[i].copyWith(done: !tasks[i].done));
    await _save();
  }

  Future<void> _delete(int i) async {
    setState(() => tasks.removeAt(i));
    await _save();
  }

  Future<void> _clear() async {
    setState(() => tasks.clear());
    await _save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('To-Do'),
        actions: [IconButton(onPressed: _clear, icon: const Icon(Icons.delete_sweep))],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: c,
                    decoration: const InputDecoration(labelText: 'Add a task', border: OutlineInputBorder()),
                    onSubmitted: (_) => _add(),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(onPressed: _add, child: const Text('Add')),
              ],
            ),
          ),
          Expanded(
            child: ready
                ? tasks.isEmpty
                      ? const Center(child: Text('No tasks'))
                      : ListView.builder(
                          itemCount: tasks.length,
                          itemBuilder: (context, i) {
                            final t = tasks[i];
                            return ListTile(
                              leading: Checkbox(value: t.done, onChanged: (_) => _toggle(i)),
                              title: Text(
                                t.title,
                                style: TextStyle(decoration: t.done ? TextDecoration.lineThrough : null),
                              ),
                              trailing: IconButton(icon: const Icon(Icons.delete), onPressed: () => _delete(i)),
                            );
                          },
                        )
                : const Center(child: CircularProgressIndicator()),
          ),
        ],
      ),
    );
  }
}
