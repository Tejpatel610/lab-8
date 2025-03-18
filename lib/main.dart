import 'package:flutter/material.dart';
import 'database.dart';
import 'todo_item.dart';
import 'todo_dao.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = await $FloorAppDatabase.databaseBuilder('app_database.db').build();
  runApp(MyApp(database: database));
}

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

class ShoppingListPage extends StatefulWidget {
  final AppDatabase database;

  const ShoppingListPage({Key? key, required this.database}) : super(key: key);

  @override
  _ShoppingListPageState createState() => _ShoppingListPageState();
}

class _ShoppingListPageState extends State<ShoppingListPage> {
  late TodoDao myDAO;
  final List<TodoItem> _items = [];
  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  TodoItem? _selectedItem;

  @override
  void initState() {
    super.initState();
    _initDatabase();
  }

  Future<void> _initDatabase() async {
    myDAO = widget.database.todoDao;
    _loadItems();
  }

  Future<void> _loadItems() async {
    final items = await myDAO.getAllItems();
    setState(() {
      _items.clear();
      _items.addAll(items);
    });
  }

  Future<void> _addItem() async {
    String item = _itemController.text.trim();
    String quantity = _quantityController.text.trim();
    if (item.isNotEmpty && quantity.isNotEmpty) {
      final newItem = TodoItem(item: item, quantity: quantity);
      await myDAO.insertItem(newItem);
      _itemController.clear();
      _quantityController.clear();
      _loadItems();
    }
  }

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
                _loadItems();
                Navigator.of(context).pop();
              },
              child: const Text("Yes"),
            ),
          ],
        );
      },
    );
  }

  void _showDetails(TodoItem item) {
    setState(() {
      _selectedItem = item;
    });
  }

  void _closeDetails() {
    setState(() {
      _selectedItem = null;
    });
  }

  Widget _listPage() {
    return Column(
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
            const SizedBox(width: 20),
            ElevatedButton(
              onPressed: _addItem,
              child: const Text("ADD"),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Expanded(
          child: _items.isEmpty
              ? const Center(child: Text("There are no items in the list."))
              : ListView.builder(
            itemCount: _items.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _showDetails(_items[index]),
                child: ListTile(
                  title: Center(
                    child: Text("${index + 1}: ${_items[index].item} - Quantity: ${_items[index].quantity}"),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _detailsPage() {
    if (_selectedItem == null) {
      return const Center(child: Text("No item selected."));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Item Name: ${_selectedItem!.item}", style: const TextStyle(fontSize: 15)),
        Text("Quantity: ${_selectedItem!.quantity}", style: const TextStyle(fontSize: 15)),
        Text("Database_ID: ${_selectedItem!.id}", style: const TextStyle(fontSize: 15)),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            _removeItem(_items.indexOf(_selectedItem!));
            _closeDetails();
          },

          child: const Text("Delete"),
        ),
        ElevatedButton(
          onPressed: _closeDetails,
          child: const Text("Close"),
        ),
      ],
    );
  }
//tej
  Widget _reactiveLayout(BuildContext context) {
    var size = MediaQuery.of(context).size;
    var width = size.width;
    var height = size.height;

    if ((width > height) && (width > 720)) {
      return Row(
        children: [
          Expanded(
            flex: 2,
            child: _listPage(),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: _detailsPage(),
            ),
          ),
        ],
      );
    } else {
      if (_selectedItem == null) {
        return _listPage();
      } else {
        return _detailsPage();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("To-Do List"),
        backgroundColor: Colors.purple[200],
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _reactiveLayout(context),
      ),
    );
  }
}