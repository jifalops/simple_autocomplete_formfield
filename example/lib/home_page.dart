import 'package:example/constants/data.dart';
import 'package:example/models/person.dart';
import 'package:flutter/material.dart';
import 'package:simple_autocomplete_formfield/simple_autocomplete_formfield.dart';

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String? selectedLetter;
  Person? selectedPerson;

  final formKey = GlobalKey<FormState>();

  bool autovalidate = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        child: Form(
          key: formKey,
          autovalidateMode: autovalidate ? AutovalidateMode.always : AutovalidateMode.disabled,
          child: ListView(
            children: <Widget>[
              SizedBox(height: 16.0),
              Text('Selected person: "$selectedPerson"'),
              Text('Selected letter: "$selectedLetter"'),
              SizedBox(height: 16.0),
              SimpleAutocompleteFormField<Person>(
                decoration: InputDecoration(labelText: 'Person', border: OutlineInputBorder()),
                suggestionsHeight: 80.0,
                itemBuilder: (context, person) => Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(person!.name, style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(person.address),
                    ],
                  ),
                ),
                onSearch: (search) async => people
                    .where((person) =>
                        person.name.toLowerCase().contains(search.toLowerCase()) ||
                        person.address.toLowerCase().contains(search.toLowerCase()))
                    .toList(),
                itemFromString: (string) {
                  var matches = people.where((person) => person.name.toLowerCase() == string.toLowerCase());
                  return matches.isEmpty ? null : matches.first;
                },
                onChanged: (value) => setState(() => selectedPerson = value),
                onSaved: (value) => setState(() => selectedPerson = value),
                validator: (person) => person == null ? 'Invalid person.' : null,
              ),
              SizedBox(height: 16.0),
              SimpleAutocompleteFormField<String>(
                decoration: InputDecoration(labelText: 'Letter', border: OutlineInputBorder()),
                // suggestionsHeight: 200.0,
                maxSuggestions: 10,
                itemBuilder: (context, item) => Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(item!),
                ),
                onSearch: (String search) async => search.isEmpty
                    ? letters
                    : letters.where((letter) => search.toLowerCase().contains(letter)).toList(),
                itemFromString: (string) =>
                    letters.singleWhere((letter) => letter == string.toLowerCase(), orElse: () => ''),
                onChanged: (value) => setState(() => selectedLetter = value),
                onSaved: (value) => setState(() => selectedLetter = value),
                validator: (letter) {
                  if (letter != null && letter.length == 1) return null;
                  return 'Invalid letter.';
                },
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                child: Text('Submit'),
                onPressed: () {
                  if (!formKey.currentState!.validate()) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Fix errors to continue.'),
                      ),
                    );
                    setState(() => autovalidate = true);
                    return;
                  }
                  formKey.currentState!.save();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Fields valid!'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
