import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'task.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(dir.path);
  print('Hive base path: ${dir.path}');

  Hive.registerAdapter(TaskAdapter());

  await Hive.openBox<Task>('tasks_box_2');

  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'To-Do Hive',
      theme: ThemeData.light(useMaterial3: true),
      home: const TodoPage(),
    );
  }
}

class TodoPage extends StatefulWidget {
  const TodoPage({super.key});
  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  late final Box<Task> box;
  final c = TextEditingController();

  @override
  void initState() {
    super.initState();
    box = Hive.box<Task>('tasks_box_2');
  }

  Future<void> _add() async {
    final text = c.text.trim();
    if (text.isEmpty) return;
    await box.add(Task(title: text, done: false));
    c.clear();
  }

  Future<void> _toggle(int i) async {
    final t = box.getAt(i);
    if (t == null) return;
    await box.putAt(i, t.copyWith(done: !t.done));
  }

  Future<void> _delete(int i) async {
    await box.deleteAt(i);
  }

  Future<void> _clear() async {
    await box.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('To-Do'),
        actions: [
          IconButton(onPressed: _clear, icon: const Icon(Icons.delete_sweep)),
        ],
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
                    decoration: const InputDecoration(
                      labelText: 'Add a task',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _add(),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(onPressed: _add, child: const Text('Add')),
              ],
            ),
          ),
          Expanded(
            child: ValueListenableBuilder<Box<Task>>(
              valueListenable: box.listenable(),
              builder: (context, b, _) {
                final tasks = b.values.toList(growable: false);
                if (tasks.isEmpty) {
                  return const Center(child: Text('No tasks'));
                }
                return ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, i) {
                    final t = tasks[i];
                    return ListTile(
                      leading: Checkbox(
                        value: t.done,
                        onChanged: (_) => _toggle(i),
                      ),
                      title: Text(
                        t.title,
                        style: TextStyle(
                          decoration: t.done
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _delete(i),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
