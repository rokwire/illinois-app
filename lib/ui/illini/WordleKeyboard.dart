
import 'dart:async';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:illinois/ext/Wordle.dart';
import 'package:illinois/model/Wordle.dart';
import 'package:illinois/service/Storage.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

typedef WordleKeyboardController = StreamController<String>;
typedef WordleKeyboardSubscription = StreamSubscription<String>;

class WordleKeyboard extends StatefulWidget {

  static const String Back = '\u0008';
  static const String Return = '\u000d';

  final double gutterRatio;
  final WordleGame? game;
  final WordleKeyboardController? controller;
  final bool autofocus;

  WordleKeyboard({ super.key,
    this.controller,
    this.game,
    this.autofocus = false,
    this.gutterRatio = 0.125
  });

  @override
  State<StatefulWidget> createState() => WordleKeyboardState();
}

class WordleKeyboardState extends State<WordleKeyboard> with NotificationsListener {

  static List<List<String>> _letters = <List<String>>[
    <String>['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'],
    <String>['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'],
    <String>['Z', 'X', 'C', 'V', 'B', 'N', 'M'],
  ];

  static Map<int, _SpecialKeyPair> _specialKeys = <int, _SpecialKeyPair>{
    2: _SpecialKeyPair(SpecialKey.Return, SpecialKey.Back),
  };

  static int _standardLettersLength = _letters.first.length;

  static const String _textFieldValue = ' ';
  TextEditingController _textController = TextEditingController(text: _textFieldValue);
  FocusNode _textFocusNode = FocusNode();

  late _LetterStatusMap _letterStatuses;
  _KeyHighlightMap _keyHighlights = <String, int>{};

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Storage.notifySettingChanged,
    ]);

    _textController.addListener(_onTextChanged);

    _letterStatuses = widget.game?.lettersStatuses ?? <String, WordleLetterStatus>{};
    super.initState();
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _textFocusNode.dispose();
    super.dispose();
  }

  @override
  void onNotification(String name, dynamic param) {
    if (name == Storage.notifySettingChanged && (param == Storage.wordleGameKey) && mounted) {
      _onWodleGameChanged();
    }
  }

  @override
  Widget build(BuildContext context) =>
    Stack(children: [
      if (_manualTextInputSupported)
        Positioned.fill(child: _textFieldWidget),
      _keyboardPanel,
    ],);

  Widget get _keyboardPanel =>
    Container(decoration: _keyboardDecoration, padding: _keyboardPadding, child:
      Column(mainAxisSize: MainAxisSize.min, children: _keyboardLines,),
    );

  List<Widget> get _keyboardLines {
    List<Widget> rows = <Widget>[];
    for(int index = 0; index < _letters.length; index++) {
      List<String> keyboardLine = _letters[index];
      if (rows.isNotEmpty) {
        rows.add(Container(padding: _keyboardSpacing,));
      }
      rows.add(_keyboardLine(keyboardLine, specialKeys: _specialKeys[index]));
    }
    return rows;
  }

  Widget _keyboardLine(List<String> line, { _SpecialKeyPair? specialKeys }) {
    List<Widget> cells = <Widget>[];

    for (String letter in line) {
      if (cells.isNotEmpty) {
        cells.add(Expanded(flex: _gutterFlex, child: Container()));
      }
      cells.add(Expanded(flex: _letterFlex, child: _keyboardLetter(letter, status: _letterStatuses[letter])));
    }

    int delta = _standardLettersLength - line.length;
    if (0 < delta) {
      if (specialKeys != null) {
        double boderRatio = _deltaRatio(delta);
        double specialCellRatio = boderRatio - _gutterRatio;
        int specialCellFlex = _ratioToFlex(specialCellRatio);
        double specialCellAspect = _letterAspectRatio * specialCellRatio / _letterRatio;
        cells.insertAll(0, <Widget>[
          Expanded(flex: specialCellFlex, child: _keyboardSpecialKey(specialKeys.left, aspectRatio: specialCellAspect)),
          Expanded(flex: _gutterFlex, child: Container()),
        ]);

        cells.addAll(<Widget>[
          Expanded(flex: _gutterFlex, child: Container()),
          Expanded(flex: specialCellFlex, child: _keyboardSpecialKey(specialKeys.right, aspectRatio: specialCellAspect)),
        ]);
      }
      else {
        int borderFlex = _deltaFlex(delta);
        cells.insert(0, Expanded(flex: borderFlex, child: Container()));
        cells.add(Expanded(flex: borderFlex, child: Container()));
      }
    }

    return Row(children: cells,);
  }

  Widget _keyboardLetter(String letter, {WordleLetterStatus? status} ) =>
    AspectRatio(aspectRatio: _letterAspectRatio, child:
      Container(decoration: _keyDecoration(status: status, highlighted: _isKeyHighlighted(letter)), child:
        ClipRRect(borderRadius: _keyBorderRadius, child:
          Material(color: status?.color ?? _defaultKeyBackColor, child:
            InkWell(onTap: () => _onKeyboardKey(letter), child:
              Center(child:
                Text(letter, style: (status != null) ? _statusLetterTextStyle : _defaultLetterTextStyle,)
              )
            )
          )
        )
      )
    );

  Widget _keyboardSpecialKey(SpecialKey specialKey, { required double aspectRatio }) =>
    AspectRatio(aspectRatio: aspectRatio, child:
      Container(decoration: _keyDecoration(highlighted: _isKeyHighlighted(specialKey.asciiCode)), child:
        ClipRRect(borderRadius: _keyBorderRadius, child:
          Material(color: _defaultKeyBackColor, child:
            InkWell(onTap: () => _onKeyboardKey(specialKey.asciiCode), child:
              Center(child:
                specialKey.iconWidget ?? Container()
              )
            )
          )
        )
      )
    );

  void _onKeyboardKey(String code) =>
    widget.controller?.add(code);

  void _onWodleGameChanged() {
    WordleGame? storedGame = WordleGame.fromStorage();
    _LetterStatusMap? letterStatuses = storedGame?.lettersStatuses;
    if ((letterStatuses != null) && !DeepCollectionEquality().equals(_letterStatuses, letterStatuses)) {
      setState(() {
        _letterStatuses = letterStatuses;
      });
    }
  }

  // Manual Input

  bool get _manualTextInputSupported =>
    false; /* WebUtils.isDesktopDeviceWeb() */

  Widget get _textFieldWidget => TextField(
    style: Styles().textStyles.getTextStyle('widget.heading.extra_small'),
    decoration: InputDecoration(border: InputBorder.none),
    controller: _textController,
    focusNode: _textFocusNode,
    keyboardType: TextInputType.text,
    textInputAction: TextInputAction.go,
    textCapitalization: TextCapitalization.characters,
    maxLines: null,
    maxLength: 2,
    expands: true,
    showCursor: false,
    autocorrect: false,
    enableSuggestions: false,
    enableInteractiveSelection: false,
    autofocus: widget.autofocus,
    onSubmitted: _onTextSubmit,
    contextMenuBuilder: _onBuildTextContextMenu,
  );

  void _onTextChanged() {
    if (_textController.text.isNotEmpty == true) {
      String textContent = _textController.text.trim();
      if (textContent.isNotEmpty) {
        String character = textContent.substring(0, 1).toUpperCase();
        if (character.isWordleAlpha) {
          _highlightKey(character);
          widget.controller?.add(character);
        }
      }
    }
    else {
      _highlightKey(WordleKeyboard.Back);
      widget.controller?.add(WordleKeyboard.Back);
    }
    if (_textController.text != _textFieldValue) {
      _textController.text = _textFieldValue;
    }
    _textFocusNode.requestFocus(); // show again
  }

  void _onTextSubmit(String text) {
    _highlightKey(WordleKeyboard.Return);
    widget.controller?.add(WordleKeyboard.Return);
    _textFocusNode.requestFocus(); // show again
  }

  Widget _onBuildTextContextMenu(BuildContext context, EditableTextState editableTextState) =>
    Container();

  void toggleFocus() {
    if (_textFocusNode.hasFocus == true) {
      _textFocusNode.unfocus();
    }
    else {
      _textFocusNode.requestFocus();
    }
  }

  // Key Highlight

  Future<void> _highlightKey(String key) async {
    if (mounted) {
      setState(() {
        _addHighlightKey(key);
      });

      await Future.delayed(_highlightKeyDuration);

      if (mounted) {
        setState(() {
          _removeHighlightKey(key);
        });
      }
    }
  }

  bool _isKeyHighlighted(String key) =>
    (0 < (_keyHighlights[key] ?? 0));

  void _addHighlightKey(String key) =>
    _keyHighlights[key] = (_keyHighlights[key] ?? 0) + 1;

  void _removeHighlightKey(String key) {
    int? count = _keyHighlights[key];
    if (count != null) {
      if (1 < count) {
        _keyHighlights[key] = (count - 1);
      }
      else {
        _keyHighlights.remove(key);
      }
    }
  }

  // Constants

  BoxDecoration get _keyboardDecoration => BoxDecoration(
    color: Styles().colors.backgroundVariant,
    border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
    borderRadius: BorderRadius.all(Radius.circular(4)),
  );

  EdgeInsetsGeometry get _keyboardPadding => EdgeInsets.symmetric(horizontal: 8, vertical: 8);
  EdgeInsetsGeometry get _keyboardSpacing => EdgeInsets.only(top: 6);

  BoxDecoration _keyDecoration({WordleLetterStatus? status, bool? highlighted}) => BoxDecoration(
    color: status?.color ?? _defaultKeyBackColor,
    border: (highlighted == true) ? _highlightKeyBorder(status) : _defaultKeyBorder,
    borderRadius: _keyBorderRadius,
  );

  Color get _defaultKeyBackColor => Styles().colors.surface;
  BoxBorder get _defaultKeyBorder => Border.all(color: Styles().colors.surfaceAccent, width: 1);
  BoxBorder _highlightKeyBorder([WordleLetterStatus? status]) => Border.all(color: status?.highlightBorderColor ?? Styles().colors.fillColorPrimary, width: 2);

  static const Duration _highlightKeyDuration = const Duration(milliseconds: 300);

  static const _keyBorderRadius = const BorderRadius.all(Radius.circular(4));

  TextStyle? get _defaultLetterTextStyle => Styles().textStyles.getTextStyle('widget.title.medium.fat');
  TextStyle? get _statusLetterTextStyle => Styles().textStyles.getTextStyle('widget.title.light.medium.fat');

  static const double _letterAspectRatio = 0.66;
  static const double _flexPrecision = 1000;

  double get _gutterRatio => widget.gutterRatio;
  double get _letterRatio => (1 - widget.gutterRatio);
  double _deltaRatio(int delta) => (_letterRatio * delta + _gutterRatio * max(delta - 1, 0)) / 2;

  int get _gutterFlex => _ratioToFlex(_gutterRatio);
  int get _letterFlex => _ratioToFlex(_letterRatio);
  int _deltaFlex(int delta) => _ratioToFlex(_deltaRatio(delta));

  static int _ratioToFlex(double ratio) => (ratio * _flexPrecision).toInt();
}

enum SpecialKey { Back, Return }

typedef _SpecialKeyPair = Pair<SpecialKey, SpecialKey>;

extension _SpecialKeyImpl on SpecialKey {

  Widget? get iconWidget {
    switch(this) {
      case SpecialKey.Back: return Styles().images.getImage('delete-left');
      case SpecialKey.Return: return Styles().images.getImage('arrow-turn-down-left');
    }
  }

  String get asciiCode {
    switch(this) {
      case SpecialKey.Back: return WordleKeyboard.Back;
      case SpecialKey.Return: return WordleKeyboard.Return;
    }
  }
}

extension _WordleKeyboardLetterStatus on WordleLetterStatus {

  int get weight {
    switch(this) {
      case WordleLetterStatus.outOfUse: return 0;
      case WordleLetterStatus.inUse:    return 1;
      case WordleLetterStatus.inPlace:  return 2;
    }
  }
}

typedef _LetterStatusMap = Map<String, WordleLetterStatus>;
typedef _KeyHighlightMap = Map<String, int>;

extension _WordleGameKeyboard on WordleGame {
  _LetterStatusMap get lettersStatuses {
    _LetterStatusMap keyboardStatus = <String, WordleLetterStatus>{};
    for (String move in moves) {
      List<WordleLetterStatus> moveStatus = wordStatus(move);
      _LetterStatusMap moveKeyboardStatus = <String, WordleLetterStatus>{};
      for (int index = 0; index < min(move.length, moveStatus.length); index++) {
        String letter = move.substring(index, index + 1);
        WordleLetterStatus letterStatus = moveStatus[index];
        WordleLetterStatus? existingLetterStatus = moveKeyboardStatus[letter];
        if ((existingLetterStatus == null) || (existingLetterStatus.weight < letterStatus.weight)) {
          moveKeyboardStatus[letter] = letterStatus;
        }
      }
      keyboardStatus.addAll(moveKeyboardStatus);
    }
    return keyboardStatus;
  }
}
