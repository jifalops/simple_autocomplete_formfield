library simple_autocomplete_formfield;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show TextInputFormatter;

typedef Widget SuggestionsBuilder(BuildContext context, List<Widget> items);
typedef String ItemToString<T>(T item);
typedef T ItemFromString<T>(String string);

/// Wraps a [TextFormField] and shows a list of suggestions below it.
///
/// As the user types, a list of suggestions is shown using [onSearch] and
/// [itemBuilder]. The default suggestions container has a fills the available
/// height but can be overridden by using [suggestionsHeight] or by using a
/// custom [suggestionsBuilder].
///
/// It is recommended to provide an [itemFromString] argument so that a
/// suggestion can be selected if the user types in the value instead of tapping
/// on it.
///
/// It is also recommended that the Widget tree containing a
/// SimpleAutocompleteFormField include a [ListView] or other scrolling
/// container such as a [SingleChildScrollView]. This prevents the suggestions
/// from overflowing other UI elements like the keyboard.
class SimpleAutocompleteFormField<T> extends FormField<T> {
  final Key key;

  /// Minimum search length that shows suggestions.
  final int minSearchLength;

  /// Maximum number of suggestions shown.
  final int maxSuggestions;

  /// Container for the list of suggestions. Defaults to a scrollable `Column`
  /// that fills the available space.
  final SuggestionsBuilder suggestionsBuilder;

  /// The height of the suggestions container. Has no effect if a custom
  ///  [suggestionsBuilder] is specified.
  final double suggestionsHeight;

  /// Represents an autocomplete suggestion.
  final Widget Function(BuildContext context, T item) itemBuilder;

  /// How the text field is filled in when an item is selected. If omitted, the
  /// item's `toString()` method is used.
  final ItemToString<T> itemToString;

  /// Called before `onChanged` when the input loses focus and a suggestion was
  /// not selected, for example if the user typed in an entire suggestion value
  /// without tapping on it. The default implementation simply returns `null`.
  final ItemFromString<T> itemFromString;

  /// Called to fill the autocomplete list's data.
  final Future<List<T>> Function(String search) onSearch;

  /// Called when an item is tapped or the field loses focus.
  final ValueChanged<T> onChanged;

  /// If not null, the TextField [decoration]'s suffixIcon will be
  /// overridden to reset the input using the icon defined here.
  final IconData resetIcon;

  // TextFormField properties
  final FormFieldValidator<T> validator;
  final FormFieldSetter<T> onSaved;
  final ValueChanged<T> onFieldSubmitted;
  final TextEditingController controller;
  final FocusNode focusNode;
  final InputDecoration decoration;
  final TextInputType keyboardType;
  final TextStyle style;
  final TextAlign textAlign;
  final T initialValue;
  final bool autofocus;
  final bool obscureText;
  final bool autocorrect;
  final bool maxLengthEnforced;
  final int maxLines;
  final int maxLength;
  final List<TextInputFormatter> inputFormatters;
  final bool enabled;

  SimpleAutocompleteFormField(
      {this.key,
      this.minSearchLength: 0,
      this.maxSuggestions: 3,
      @required this.itemBuilder,
      @required this.onSearch,
      SuggestionsBuilder suggestionsBuilder,
      this.suggestionsHeight,
      this.itemToString,
      this.itemFromString,
      this.onChanged,
      this.resetIcon: Icons.close,
      bool autovalidate: false,
      this.validator,
      this.onFieldSubmitted,
      this.onSaved,

      // TextFormField properties
      TextEditingController controller,
      FocusNode focusNode,
      this.initialValue,
      this.decoration: const InputDecoration(),
      this.keyboardType: TextInputType.text,
      this.style,
      this.textAlign: TextAlign.start,
      this.autofocus: false,
      this.obscureText: false,
      this.autocorrect: true,
      this.maxLengthEnforced: true,
      this.enabled,
      this.maxLines: 1,
      this.maxLength,
      this.inputFormatters})
      : controller = controller ??
            TextEditingController(
                text: _toString<T>(initialValue, itemToString)),
        focusNode = focusNode ?? FocusNode(),
        suggestionsBuilder =
            suggestionsBuilder ?? _defaultSuggestionsBuilder(suggestionsHeight),
        super(
            key: key,
            autovalidate: autovalidate,
            validator: validator,
            onSaved: onSaved,
            builder: (FormFieldState<T> field) {
              // final _SimpleAutocompleteTextFieldState<T> state = field;
            });

  @override
  _SimpleAutocompleteFormFieldState<T> createState() =>
      _SimpleAutocompleteFormFieldState<T>(this);
}

class _SimpleAutocompleteFormFieldState<T> extends FormFieldState<T> {
  final SimpleAutocompleteFormField<T> parent;
  List<T> suggestions;
  bool showSuggestions = false;
  bool showResetIcon = false;
  T tappedSuggestion;

  _SimpleAutocompleteFormFieldState(this.parent);

  @override
  void initState() {
    super.initState();
    parent.focusNode.addListener(inputChanged);
    parent.controller.addListener(inputChanged);
  }

  @override
  void dispose() {
    parent.controller.removeListener(inputChanged);
    parent.focusNode.removeListener(inputChanged);
    super.dispose();
  }

  void inputChanged() {
    if (parent.focusNode.hasFocus) {
      setState(() {
        showSuggestions =
            parent.controller.text.trim().length >= parent.minSearchLength;
        if (parent.resetIcon != null &&
            parent.controller.text.trim().isEmpty == showResetIcon) {
          showResetIcon = !showResetIcon;
        }
      });
    } else {
      setState(() => showSuggestions = false);
      setValue(_value);
    }
  }

  T get _value => _toString<T>(tappedSuggestion, parent.itemToString) ==
          parent.controller.text
      ? tappedSuggestion
      : _toObject<T>(parent.controller.text, parent.itemFromString);

  @override
  void setValue(T value) {
    super.setValue(value);
    if (parent.onChanged != null) parent.onChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      TextFormField(
        controller: parent.controller,
        focusNode: parent.focusNode,
        decoration: parent.resetIcon == null
            ? parent.decoration
            : parent.decoration.copyWith(
                suffixIcon: showResetIcon
                    ? IconButton(
                        icon: Icon(parent.resetIcon),
                        onPressed: () {
                          parent.controller.clear();
                          // parent.focusNode.unfocus();
                        },
                      )
                    : Container(width: 0.0, height: 0.0),
              ),
        keyboardType: parent.keyboardType,
        style: parent.style,
        textAlign: parent.textAlign,
        autofocus: parent.autofocus,
        obscureText: parent.obscureText,
        autocorrect: parent.autocorrect,
        maxLengthEnforced: parent.maxLengthEnforced,
        maxLines: parent.maxLines,
        maxLength: parent.maxLength,
        inputFormatters: parent.inputFormatters,
        enabled: parent.enabled,
        onFieldSubmitted: (value) {
          if (parent.onFieldSubmitted != null) {
            return parent.onFieldSubmitted(_value);
          }
        },
        validator: (value) {
          if (parent.validator != null) {
            return parent.validator(_value);
          }
        },
        onSaved: (value) {
          if (parent.onSaved != null) {
            return parent.onSaved(_value);
          }
        },
      ),
      showSuggestions
          ? FutureBuilder<List<Widget>>(
              future: _buildSuggestions(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return parent.suggestionsBuilder(context, snapshot.data);
                } else if (snapshot.hasError) {
                  return new Text('${snapshot.error}');
                }
                return Center(child: CircularProgressIndicator());
              },
            )
          : Container(height: 0.0, width: 0.0),
    ]);
  }

  Future<List<Widget>> _buildSuggestions() async {
    final list = List<Widget>();
    final suggestions = await parent.onSearch(parent.controller.text);
    suggestions
        ?.take(parent.maxSuggestions)
        ?.forEach((suggestion) => list.add(InkWell(
              child: parent.itemBuilder(context, suggestion),
              onTap: () {
                tappedSuggestion = suggestion;
                parent.controller.text =
                    _toString<T>(suggestion, parent.itemToString);
                parent.focusNode.unfocus();
              },
            )));
    return list;
  }
}

String _toString<T>(T value, ItemToString<T> fn) =>
    (fn == null ? value?.toString() : fn(value)) ?? '';

T _toObject<T>(String s, ItemFromString fn) => fn == null ? null : fn(s);

SuggestionsBuilder _defaultSuggestionsBuilder(double height) =>
    // ((context, items) => ListView(children: items));
    ((context, items) => Container(
        height: height,
        child: SingleChildScrollView(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: items))));
