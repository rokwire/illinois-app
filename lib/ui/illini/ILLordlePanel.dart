

import 'package:flutter/material.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';

class ILLordlePanel extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _ILLordlePanelState();
}

class _ILLordlePanelState extends State<ILLordlePanel> {

  //bool _progress = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: HeaderBar(title: Localization().getStringEx('panel.illordle.header.title', 'ILLordle'),),
    body: _scaffoldContent,
    backgroundColor: Styles().colors.background,
  );

  Widget get _scaffoldContent =>
    SingleChildScrollView(child:
      Padding (padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16), child:
        Column(children: [
          Row(children: [
            Expanded(flex: 1, child: Container()),
            Expanded(flex: 2, child: Styles().images.getImage('illordle-logo') ?? Container()),
            Expanded(flex: 1, child: Container()),
          ],),
          Padding(padding: EdgeInsets.symmetric(vertical: 6), child:
            Text(Localization().getStringEx('panel.illordle.heading.info.text', 'Presented by The Daily Illini'), style: Styles().textStyles.getTextStyleEx('widget.message.light.small'), textAlign: TextAlign.center,)
          ),
          Padding (padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16), child:
            ILLordleWidget(),
          )
        ],)
    )
  );

}

class ILLordleWidget extends StatefulWidget {

  @override
  State<StatefulWidget> createState() => _ILLordleWidgetState();

}

class _ILLordleWidgetState extends State<ILLordleWidget> {

  static const int wordLength = 5;
  static const int numberOfWords = 5;

  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFocusNode = FocusNode();

  @override
  void initState() {
    _textController.addListener(_textListener);
    super.initState();
  }

  @override
  void dispose() {
    _textController.removeListener(_textListener);
    _textController.dispose();
    _textFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
    Stack(children: [
      Positioned.fill(child: _textFieldWidget),
      GestureDetector(onTap: _onTapWordle, child:
        _wordleWidget,
      )
    ],);

  Widget get _wordleWidget =>
    AspectRatio(aspectRatio: 1, child:
      _buildWords()
    );

  Widget _buildWords() {
    List<Widget> words = <Widget>[];
    for (int i = 0; i < numberOfWords; i++) {
      if (words.isNotEmpty) {
        words.add(Expanded(flex: _gutterFlex, child: Container()));
      }
      words.add(Expanded(flex: _cellFlex, child: _buildWord()));
    }
    return Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: words);
  }

  Widget _buildWord() {
    List<Widget> letters = <Widget>[];
    for (int i = 0; i < wordLength; i++) {
      if (letters.isNotEmpty) {
        letters.add(Expanded(flex: _gutterFlex, child: Container()));
      }
      letters.add(Expanded(flex: _cellFlex, child: _buildCell()));
    }
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: letters);
  }

  Widget _buildCell({ String letter = '' }) =>
      AspectRatio(aspectRatio: 1, child:
        Container(decoration: _cellDecoration(), padding: EdgeInsets.all(8), child:
          Center(child:
            Text(letter, style: Styles().textStyles.getTextStyle('widget.message.extra_large.fat'),)
          )
        ),
      );

  Decoration _cellDecoration() => BoxDecoration(
    color: Styles().colors.surface,
    border: Border.all(color: Styles().colors.surfaceAccent)
  );

  static const double gutter = 0.075;
  static const double gutterPrec = 1000;
  int get _gutterFlex => (gutter * gutterPrec).toInt();
  int get _cellFlex => ((1 - gutter) * gutterPrec).toInt();

  // Keyboard Listener

  Widget get _textFieldWidget => TextField(
    style: Styles().textStyles.getTextStyle('widget.heading.extra_small'),
    decoration: InputDecoration(border: InputBorder.none),
    controller: _textController,
    focusNode: _textFocusNode,
    keyboardType: TextInputType.text,
    textInputAction: TextInputAction.go,
    textCapitalization: TextCapitalization.none,
    maxLines: null,
    expands: true,
    showCursor: false,
    autocorrect: false,
    autofocus: true,
    onSubmitted: _onTextSubmit,
  );

  void _textListener() {
    if (_textController.text.isNotEmpty) {
      _onKeyCharacter(_textController.text.substring(0, 1).toUpperCase());
      _textController.text = '';
    }
  }

  void _onTextSubmit(String text) {
    _onSubmitWord();
  }

  void _onTapWordle() {
    if (_textFocusNode.hasFocus) {
      _textFocusNode.unfocus();
    }
    else {
      _textFocusNode.requestFocus();
    }
  }

  void _onKeyCharacter(String character) {
    debugPrint('Key: $character');
  }

  void _onSubmitWord() {
    debugPrint('Submit');
    _textFocusNode.requestFocus(); // show again
  }
}


