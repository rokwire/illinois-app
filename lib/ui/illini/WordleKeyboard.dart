
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

typedef WordleKeyboardController = StreamController<String>;

class WordleKeyboard extends StatelessWidget {

  final double gutterRatio;
  final WordleKeyboardController controller;

  WordleKeyboard(this.controller, { super.key,
    this.gutterRatio = 0.125
  });

  static List<List<String>> _letters = <List<String>>[
    <String>['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'],
    <String>['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'],
    <String>['Z', 'X', 'C', 'V', 'B', 'N', 'M'],
  ];

  static Map<int, _SpecialKeyPair> _specialKeys = <int, _SpecialKeyPair>{
    2: _SpecialKeyPair(SpecialKey.Return, SpecialKey.Back),
  };

  static int _standardLettersLength = _letters.first.length;

  @override
  Widget build(BuildContext context) =>
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
      cells.add(Expanded(flex: _letterFlex, child: _keyboardLetter(letter)));
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

  Widget _keyboardLetter(String letter) =>
    AspectRatio(aspectRatio: _letterAspectRatio, child:
      Container(decoration: _keyDecoration, child:
        Material(color: _keyBackColor, child:
          InkWell(onTap: () => _onKeyboardKey(letter), child:
            Center(child:
              Text(letter, style: _letterTextStyle,)
            )
          )
        )
      )
    );

  Widget _keyboardSpecialKey(SpecialKey specialKey, { required double aspectRatio }) =>
    AspectRatio(aspectRatio: aspectRatio, child:
      Container(decoration: _keyDecoration, child:
        Material(color: _keyBackColor, child:
          InkWell(onTap: () => _onKeyboardKey(specialKey.asciiCode), child:
            Center(child:
              specialKey.iconWidget ?? Container()
            )
          )
        )
      )
    );

  void _onKeyboardKey(String code) =>
    controller.add(code);

  BoxDecoration get _keyboardDecoration => BoxDecoration(
    color: Styles().colors.backgroundVariant,
    border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
    borderRadius: BorderRadius.all(Radius.circular(4)),
  );

  EdgeInsetsGeometry get _keyboardPadding => EdgeInsets.symmetric(horizontal: 8, vertical: 8);
  EdgeInsetsGeometry get _keyboardSpacing => EdgeInsets.only(top: 6);

  BoxDecoration get _keyDecoration => BoxDecoration(
    color: _keyBackColor,
    border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
    borderRadius: BorderRadius.all(Radius.circular(4)),
  );

  Color get _keyBackColor => Styles().colors.surface;

  TextStyle? get _letterTextStyle => Styles().textStyles.getTextStyle('widget.title.medium.fat');

  static const double _letterAspectRatio = 0.66;
  static const double _flexPrecision = 1000;

  double get _gutterRatio => gutterRatio;
  double get _letterRatio => (1 - gutterRatio);
  double _deltaRatio(int delta) => (_letterRatio * delta + _gutterRatio * max(delta - 1, 0)) / 2;

  int get _gutterFlex => _ratioToFlex(_gutterRatio);
  int get _letterFlex => _ratioToFlex(_letterRatio);
  int _deltaFlex(int delta) => _ratioToFlex(_deltaRatio(delta));

  int _ratioToFlex(double ratio) => (ratio * _flexPrecision).toInt();

}

enum SpecialKey { Back, Return }

typedef _SpecialKeyPair = Pair<SpecialKey, SpecialKey>;

extension SpecialKeyImpl on SpecialKey {

  Widget? get iconWidget {
    switch(this) {
      case SpecialKey.Back: return Styles().images.getImage('delete-left');
      case SpecialKey.Return: return Styles().images.getImage('arrow-turn-down-left');
    }
  }

  String get asciiCode {
    switch(this) {
      case SpecialKey.Back: return '\u0008';
      case SpecialKey.Return: return '\u000d';
    }
  }
}

