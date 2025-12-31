
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

enum _SpecialKey { Back, Return }

class WordleKeyboard extends StatelessWidget {

  final double gutterRatio;

  WordleKeyboard({ super.key,
    this.gutterRatio = 0.125
  });

  static List<List<String>> _letters = <List<String>>[
    <String>['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'],
    <String>['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'],
    <String>['Z', 'X', 'C', 'V', 'B', 'N', 'M'],
  ];

  static Map<int, _SpecialKeyPair> _specialKeys = <int, _SpecialKeyPair>{
    2: _SpecialKeyPair(_SpecialKey.Return, _SpecialKey.Back),
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
      cells.add(Expanded(flex: _cellFlex, child: _keyboardLetter(letter)));
    }

    int delta = _standardLettersLength - line.length;
    if (0 < delta) {
      int borderFlex = _deltaFlex(delta);
      if (specialKeys != null) {
        int specialCellFlex = borderFlex - _gutterFlex;
        cells.insertAll(0, <Widget>[
          Expanded(flex: specialCellFlex, child: _keyboardSpecialKey(specialKeys.left)),
          Expanded(flex: _gutterFlex, child: Container()),
        ]);

        cells.addAll(<Widget>[
          Expanded(flex: _gutterFlex, child: Container()),
          Expanded(flex: specialCellFlex, child: _keyboardSpecialKey(specialKeys.right)),
        ]);
      }
      else {
        cells.insert(0, Expanded(flex: borderFlex, child: Container()));
        cells.add(Expanded(flex: borderFlex, child: Container()));
      }
    }

    return Row(children: cells,);
  }

  Widget _keyboardLetter(String letter) =>
    AspectRatio(aspectRatio: _letterAspectRatio, child:
      Container(decoration: _keyDecoration, child:
        Center(child:
          Text(letter, style: _letterTextStyle,)
        )
      )
    );

  Widget _keyboardSpecialKey(_SpecialKey specialKey) =>
    AspectRatio(aspectRatio: _keyAspectRatio, child:
      Container(decoration: _keyDecoration, child:
        Center(child:
          specialKey.iconWidget ?? Container()
        )
      )
    );

  BoxDecoration get _keyboardDecoration => BoxDecoration(
    color: Styles().colors.backgroundVariant,
    border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
    borderRadius: BorderRadius.all(Radius.circular(4)),
  );

  EdgeInsetsGeometry get _keyboardPadding => EdgeInsets.symmetric(horizontal: 8, vertical: 8);
  EdgeInsetsGeometry get _keyboardSpacing => EdgeInsets.only(top: 6);

  BoxDecoration get _keyDecoration => BoxDecoration(
    color: Styles().colors.surface,
    border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
    borderRadius: BorderRadius.all(Radius.circular(4)),
  );

  TextStyle? get _letterTextStyle => Styles().textStyles.getTextStyle('widget.title.medium.fat');

  static const double _letterAspectRatio = 0.66;
  static const double _keyAspectRatio = 1.0;
  static const double _gutterPrec = 1000;

  double get _gutterRatio => gutterRatio;
  double get _cellRatio => (1 - gutterRatio);
  double _deltaRatio(int delta) => (_cellRatio * delta + _gutterRatio * max(delta - 1, 0)) / 2;

  int get _gutterFlex => (_gutterRatio * _gutterPrec).toInt();
  int get _cellFlex => (_cellRatio * _gutterPrec).toInt();
  int _deltaFlex(int delta) => (_deltaRatio(delta) * _gutterPrec).toInt();

}

typedef _SpecialKeyPair = Pair<_SpecialKey, _SpecialKey>;

extension _SpecialKeyImpl on _SpecialKey {
  Widget? get iconWidget {
    switch(this) {
      case _SpecialKey.Back: return Styles().images.getImage('delete-left');
      case _SpecialKey.Return: return Styles().images.getImage('arrow-turn-down-left');
    }
  }
}

