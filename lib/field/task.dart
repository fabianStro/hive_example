import 'package:hive/hive.dart';

part 'task.g.dart'; // generated adapter will be here

@HiveType(typeId: 1) // must be unique & stable across your app
class Task {
  @HiveField(0)
  final String title;

  @HiveField(1)
  final bool done;

  const Task({required this.title, required this.done});

  Task copyWith({String? title, bool? done, String? Jan}) =>
      Task(title: title ?? this.title, done: done ?? this.done);
}
