# SimpleAutocompleteFormField

A Flutter widget that wraps a TextFormField and assists with autocomplete functionality.

## Example

```dart
import 'package:flutter/material.dart';
import 'package:simple_autocomplete_formfield/simple_autocomplete_formfield.dart';

class MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: <Widget>[
          SimpleAutocompleteFormField<String>(
            itemBuilder: (context, item) => Text(item),
            onSearch: (String search) async => [
                  'a $search',
                  'b $search',
                  'c $search',
                  'd $search',
                  'e $search',
                ],
          ),
        ],
      ),
    );
  }
}

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Simple AutoComplete FormField example',
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  MyHomePageState createState() {
    return new MyHomePageState();
  }
}
```