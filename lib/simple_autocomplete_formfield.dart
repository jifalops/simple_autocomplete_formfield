library simple_autocomplete_formfield;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show TextInputFormatter;
import 'package:textfield_state/textfield_state.dart';

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
      this.focusNode,
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
      _SimpleAutocompleteFormFieldState<T>();
}

class _SimpleAutocompleteFormFieldState<T> extends FormFieldState<T> {
  @override
  SimpleAutocompleteFormField<T> get widget => super.widget;
  List<T> suggestions;
  bool showSuggestions = false;
  bool showResetIcon = false;
  T tappedSuggestion;
  TextFieldState state;

  bool get hasFocus => state.focusNode.hasFocus;
  bool get hasText => state.controller.text.isNotEmpty;

  String get initialText =>
      widget.itemToString?.call(widget.initialValue) ??
      widget.initialValue?.toString() ??
      '';

  void textChanged(String text) {
    focusChanged(state.focusNode.hasFocus);
  }

  void focusChanged(bool focused) {
    if (focused) {
      setState(() {
        showSuggestions =
            state.controller.text.trim().length >= widget.minSearchLength;
        if (widget.resetIcon != null &&
            state.controller.text.trim().isEmpty == showResetIcon) {
          showResetIcon = !showResetIcon;
        }
      });
    } else {
      setState(() => showSuggestions = false);
      setValue(_value);
    }
  }

  @override
  void initState() {
    super.initState();
    state = TextFieldState(
      textChanged: textChanged,
      focusChanged: focusChanged,
      text: initialText,
      controller: widget.controller,
      focusNode: widget.focusNode,
    );
  }

  @override
  void didUpdateWidget(FormField<T> oldWidget) {
    state.update(
        controller: widget.controller,
        focusNode: widget.focusNode,
        text: initialText);
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    state.dispose();
    super.dispose();
  }

  T get _value => _toString<T>(tappedSuggestion, widget.itemToString) ==
          state.controller.text
      ? tappedSuggestion
      : _toObject<T>(state.controller.text, widget.itemFromString);

  @override
  void setValue(T value) {
    super.setValue(value);
    if (widget.onChanged != null) widget.onChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      TextFormField(
        controller: state.controller,
        focusNode: state.focusNode,
        decoration: widget.resetIcon == null
            ? widget.decoration
            : widget.decoration.copyWith(
                suffixIcon: showResetIcon
                    ? IconButton(
                        icon: Icon(widget.resetIcon),
                        onPressed: clear,
                      )
                    : Container(width: 0.0, height: 0.0),
              ),
        keyboardType: widget.keyboardType,
        style: widget.style,
        textAlign: widget.textAlign,
        autofocus: widget.autofocus,
        obscureText: widget.obscureText,
        autocorrect: widget.autocorrect,
        maxLengthEnforced: widget.maxLengthEnforced,
        maxLines: widget.maxLines,
        maxLength: widget.maxLength,
        inputFormatters: widget.inputFormatters,
        enabled: widget.enabled,
        onFieldSubmitted: (value) {
          if (widget.onFieldSubmitted != null) {
            return widget.onFieldSubmitted(_value);
          }
        },
        validator: (value) {
          if (widget.validator != null) {
            return widget.validator(_value);
          }
        },
        onSaved: (value) {
          if (widget.onSaved != null) {
            return widget.onSaved(_value);
          }
        },
      ),
      showSuggestions
          ? FutureBuilder<List<Widget>>(
              future: _buildSuggestions(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return widget.suggestionsBuilder(context, snapshot.data);
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
    final suggestions = await widget.onSearch(state.controller.text);
    suggestions
        ?.take(widget.maxSuggestions)
        ?.forEach((suggestion) => list.add(InkWell(
              child: widget.itemBuilder(context, suggestion),
              onTap: () {
                tappedSuggestion = suggestion;
                state.controller.text =
                    _toString<T>(suggestion, widget.itemToString);
                state.focusNode.unfocus();
              },
            )));
    return list;
  }

  void _hideKeyboard() {
    Future.microtask(() => FocusScope.of(context).requestFocus(FocusNode()));
  }

  void clear() async {
    _hideKeyboard();
    // Fix for ripple effect throwing exception
    // and the field staying gray.
    // https://github.com/flutter/flutter/issues/36324
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() => state.controller.clear());
    });
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
