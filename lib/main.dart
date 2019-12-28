import 'dart:convert';

import 'package:flutter/material.dart';

import 'dart:io';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MaterialApp(
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List _groceryList = [];
  Map<String, dynamic> _lastRemoved;
  int _lastRemovedPosition;

  @override
  void initState() {
    super.initState();
    _readData().then((data) {
      setState(() {
        _groceryList = json.decode(data);
      });
    });
  }

  final _newItemController = TextEditingController();

  void _addItemToList() {
    setState(() {
      Map<String, dynamic> newItem = Map();
      newItem['title'] = _newItemController.text;
      newItem['ok'] = false;
      _newItemController.text = '';
      _groceryList.add(newItem);
      _saveData();
    });
  }

  Future<Null> _refresh() async {
    await Future.delayed(Duration(seconds: 1));

    setState(() {
      _groceryList.sort((a, b) {
        if (a['ok'] && !b['ok']) {
          return 1;
        } else if (!a['ok'] && b['ok']) {
          return -1;
        } else {
          return 0;
        }
      });

      _saveData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Grocery List'),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _newItemController,
                    decoration: InputDecoration(
                        labelText: 'New',
                        labelStyle: TextStyle(
                          color: Colors.blueAccent,
                        )),
                  ),
                ),
                RaisedButton(
                  color: Colors.blueAccent,
                  child: Text('ADD'),
                  textColor: Colors.white,
                  onPressed: _addItemToList,
                )
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.builder(
                  padding: EdgeInsets.only(top: 10.0),
                  itemCount: _groceryList.length,
                  itemBuilder: _buildItem),
            ),
          )
        ],
      ),
    );
  }

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/groceryList.json');
  }

  Future<File> _saveData() async {
    String data = json.encode(_groceryList);
    final file = await _getFile();
    return file.writeAsString(data);
  }

  Widget _buildItem(context, index) {
    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      background: Container(
          color: Colors.red,
          child: Align(
            alignment: Alignment(-0.9, 0.0),
            child: Icon(
              Icons.delete,
              color: Colors.white,
            ),
          )),
      direction: DismissDirection.startToEnd,
      child: CheckboxListTile(
        title: Text(_groceryList[index]['title']),
        value: _groceryList[index]['ok'],
        secondary: CircleAvatar(
          child: Icon(_groceryList[index]['ok'] ? Icons.check : Icons.error),
        ),
        onChanged: (checked) {
          setState(() {
            _groceryList[index]['ok'] = checked;
            _saveData();
          });
        },
      ),
      onDismissed: (direction) {
        setState(() {
          _lastRemoved = Map.from(_groceryList[index]);
          _lastRemovedPosition = index;
          _groceryList.removeAt(index);

          _saveData();

          final snack = SnackBar(
            content: Text('${_lastRemoved['title']} was removed!'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                setState(() {
                  _groceryList.insert(_lastRemovedPosition, _lastRemoved);
                  _saveData();
                });
              },
            ),
            duration: Duration(seconds: 2),
          );

          Scaffold.of(context).removeCurrentSnackBar();
          Scaffold.of(context).showSnackBar(snack);
        });
      },
    );
  }

  Future<String> _readData() async {
    try {
      final file = await _getFile();
      return file.readAsString();
    } catch (e) {
      return null;
    }
  }
}
