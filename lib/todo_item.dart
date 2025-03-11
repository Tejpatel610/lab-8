import 'package:floor/floor.dart';

@Entity(tableName: 'todo_item')
class TodoItem {
  @PrimaryKey(autoGenerate: true)
  final int? id;

  final String item;
  final String quantity;

  const TodoItem({this.id, required this.item, required this.quantity});
}