import 'package:flutter/material.dart';
import 'database.dart';
import 'todo_item.dart';
import 'todo_dao.dart';

//main function and database initialization
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = await $FloorAppDatabase.databaseBuilder('app_database.db').build();
  runApp(MyApp(database: database));
}
//MyApp widget(root widget)
class MyApp extends StatelessWidget {
  final AppDatabase database;

  const MyApp({Key? key, required this.database}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'To-Do List',
      theme: ThemeData(primarySwatch: Colors.purple),
      home: ShoppingListPage(database: database),
    );
  }
}

//shopping list page (stateful widget ) initialization
class ShoppingListPage extends StatefulWidget {
  final AppDatabase database;

  //takes database instance as parameter
  const ShoppingListPage({Key? key, required this.database}) : super(key: key);

  @override
  _ShoppingListPageState createState() => _ShoppingListPageState();
}
//Data Access Object(DAO)handles database queries
class _ShoppingListPageState extends State<ShoppingListPage> {
  late TodoDao myDAO;
  final List<TodoItem> _items = [];
  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();

// overide
  @override
  //initState() initializes the database when the widget loads.
  void initState() {
    super.initState();
    //_initDatabase() assigns the DAO and loads stored items.
    _initDatabase();
  }

  Future<void> _initDatabase() async {
    myDAO = widget.database.todoDao;
    _loadItems();
  }

  Future<void> _loadItems() async {
    final items = await myDAO.getAllItems(); // Fetches all items from the database
    setState(() {
      _items.clear();
      _items.addAll(items);
    });
  }
  //Gets input from text fields and trims whitespace.
  //Creates a TodoItem object.
  //Inserts the item into the database
  //Clears the text fields and reloads the updated list.
  Future<void> _addItem() async {
    String item = _itemController.text.trim();
    String quantity = _quantityController.text.trim();
    if (item.isNotEmpty && quantity.isNotEmpty) {
      final newItem = TodoItem(item: item, quantity: quantity);
      await myDAO.insertItem(newItem);
      _itemController.clear();
      _quantityController.clear();
      _loadItems(); // Reload items
    }
  }
  //Shows a confirmation dialog before deleting an item
  //If "Yes" is clicked, the item is deleted from the database.
  //Reloads the updated list.
  Future<void> _removeItem(int index) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Delete Item"),
          content: const Text("Are you sure you want to delete this item?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("No"),
            ),
            TextButton(
              onPressed: () async {
                await myDAO.deleteItem(_items[index]);
                _loadItems(); // Refresh list
                Navigator.of(context).pop();
              },
              child: const Text("Yes"),
            ),
          ],
        );
      },
    );
  }
//Creates a Scaffold with an AppBar having a purple background.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("To-Do List"),
        backgroundColor: Colors.purple[200],
        centerTitle: true,
      ),
      //Uses Padding to give space around elements.
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _itemController,
                    decoration: const InputDecoration(hintText: "Enter item", border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _quantityController,
                    decoration: const InputDecoration(hintText: "Enter quantity", border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _addItem,
                  child: const Text("ADD"),
                ),
              ],
              //week8
            ),
            //Displays "There are no items in the list." if _items is empty.
            const SizedBox(height: 20),
            Expanded(
              child: Center( // Centers the content
                child: _items.isEmpty
                    ? const Text("There are no items in the list.")
                    : Column(
                  mainAxisAlignment: MainAxisAlignment.center, // Centers list vertically
                  children: [
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true, // Prevents extra scrolling issues
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onLongPress: () => _removeItem(index),
                            child: ListTile(
                              title: Center( // Center the text in ListTile
                                child: Text("${index + 1}: ${_items[index].item} - Quantity: ${_items[index].quantity}"),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}