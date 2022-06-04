import 'package:example/constants/data.dart';
import 'package:example/home_page.dart';
import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: title,
      home: MyHomePage(),
    );
  }
}
