

import 'package:flutter/material.dart';
import 'package:illinois/service/Content.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:intl/intl.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class ILLordlePanel extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _ILLordlePanelState();
}

class _ILLordlePanelState extends State<ILLordlePanel> {

  bool _loadProgress = false;
  _ILLordleDailyWord? _dailyWord;
  Set<String>? _dictionary;
  ILLordle? _storedGame;

  @override
  void initState() {
    _storedGame = ILLordle.fromStorageString(Storage().illordleGame);
    _loadData();
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
          _bodyContent
        ],)
    )
  );

  Widget get _bodyContent {
    if (_loadProgress) {
      return _loadingContent;
    } else if (_dailyWord == null) {
      return _errorContent;
    } else if (_storedGame?.word == _dailyWord?.word) {
      bool? gameResult = _storedGame?.result;
      if (gameResult != null) {
        return _gameStatusContent(_dailyWord!, succeeded: gameResult);
      } else {
        return _illordleContent;
      }
    } else {
      return _illordleContent;
    }
  }

  Widget get _illordleContent =>
    Padding (padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16), child:
      ILLordleWidget(_storedGame ?? ILLordle(_dailyWord?.word ?? ''),
        dictionary: _dictionary, autofocus: true,
      ),
    );

  static Widget get _loadingContent =>
    Center(child:
      Padding(padding: _messagePadding, child:
        SizedBox(width: 32, height: 32, child:
          CircularProgressIndicator(color: Styles().colors.fillColorSecondary, strokeWidth: 3,),
        )
      )
    );

  Widget get _errorContent => _messageContent(Localization().getStringEx('panel.illordle.message.error.text', 'Failed to load daily target'));

  static Widget _messageContent(String status) =>
    Padding(padding: _messagePadding, child:
      Text(status, style: Styles().textStyles.getTextStyle("widget.message.regular.fat"), textAlign: TextAlign.center,)
    );

  static const double _messageBasePadding = 32;
  static const double _messageHPadding = _messageBasePadding;
  static const double _messageVPadding = _messageBasePadding * 5;
  static EdgeInsetsGeometry _messagePadding = const EdgeInsets.symmetric(horizontal: _messageHPadding, vertical: _messageVPadding);

  Widget _gameStatusContent(_ILLordleDailyWord dailyWord, {bool succeeded = false}) {
    return Padding(padding: _gameStatusPadding, child:
      Column(mainAxisSize: MainAxisSize.min, children: [
        Text(succeeded ?
            Localization().getStringEx('panel.illordle.game.status.succeeded.title', 'You win!') :
            Localization().getStringEx('panel.illordle.game.status.failed.title', 'You lost'),
          style: _gameStatusTitleTextStyle, textAlign: TextAlign.center,
        ),

        Padding(padding: EdgeInsets.symmetric(vertical: 16), child:
          Column(mainAxisSize: MainAxisSize.min, children: [
            Text(Localization().getStringEx('panel.illordle.game.status.word.text', 'Today\'s word: {{word}}').replaceAll('{{word}}', dailyWord.word.toUpperCase()),
              style: _gameStatusSectionTextStyle, textAlign: TextAlign.center,
            ),
            Text(DateFormat(Localization().getStringEx('panel.illordle.game.status.date.text.format', 'MMMM, dd, yyyy')).format(dailyWord.dateTime ?? DateTime.now()),
              style: _gameStatusInfoTextStyle, textAlign: TextAlign.center,
            ),
            if (succeeded && (dailyWord.author?.isNotEmpty == true))
              Text(Localization().getStringEx('panel.illordle.game.status.author.text', 'Edited by {{author}}').replaceAll('{{author}}', dailyWord.author ?? ''),
                style: _gameStatusInfoTextStyle, textAlign: TextAlign.center,
              ),
            if (succeeded && (dailyWord.quote?.isNotEmpty == true))
              ...[
                Padding(padding: EdgeInsets.only(top: 16, bottom: 4), child:
                  Text(Localization().getStringEx('panel.illordle.game.status.related_to.text', 'Related to this word'),
                    style: _gameStatusSectionTextStyle, textAlign: TextAlign.center,
                  ),
                ),
                Container(decoration: _gameStatusQuoteDecoration, padding: _gameStatusQuotePadding, child:
                  Text(dailyWord.quote ?? '',
                    style: _gameStatusInfoTextStyle, textAlign: TextAlign.center,
                  ),
                )
              ]
          ]),
        ),
      ],)
    );
  }

  TextStyle? get _gameStatusTitleTextStyle => Styles().textStyles.getTextStyle('widget.message.extra_large.extra_fat');
  TextStyle? get _gameStatusSectionTextStyle => Styles().textStyles.getTextStyle('widget.message.regular.fat');
  TextStyle? get _gameStatusInfoTextStyle => Styles().textStyles.getTextStyle('widget.message.regular');

  Decoration get _gameStatusQuoteDecoration => BoxDecoration(
    color: Styles().colors.lightGray,
    border: Border.all(color: Styles().colors.surfaceAccent2),
  );
  EdgeInsetsGeometry get _gameStatusQuotePadding => EdgeInsets.symmetric(horizontal: 8, vertical: 4);

  static const double _gameStatusHPadding = _messageBasePadding;
  static const double _gameStatusVPadding = _messageBasePadding * 3;
  static EdgeInsetsGeometry _gameStatusPadding = const EdgeInsets.symmetric(horizontal: _gameStatusHPadding, vertical: _gameStatusVPadding);

  // Data

  Future<void> _loadData() async {
    setState(() {
      _loadProgress = true;
    });

    List<dynamic> results = await Future.wait([
      ILLordle.loadDailyWord(),
      ILLordle.loadDictionary(),
    ]);

    if (mounted) {
      setState(() {
        _dailyWord = JsonUtils.cast(ListUtils.entry(results, 0));
        _dictionary = JsonUtils.setStringsValue(ListUtils.entry(results, 1));
        _loadProgress = false;
      });
    }
  }
}

class ILLordleWidget extends StatefulWidget {

  final ILLordle game;
  final Set<String>? dictionary;
  final bool autofocus;

  ILLordleWidget(this.game, {super.key, this.dictionary, this.autofocus = false});

  @override
  State<StatefulWidget> createState() => _ILLordleWidgetState();

}

class _ILLordleWidgetState extends State<ILLordleWidget> {

  static const String _textFieldValue = ' ';
  final TextEditingController _textController = TextEditingController(text: _textFieldValue);
  final FocusNode _textFocusNode = FocusNode();

  @override
  void initState() {
    _textController.addListener(_onTextChanged);
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
    for (int i = 0; i < ILLordle.numberOfWords; i++) {
      if (words.isNotEmpty) {
        words.add(Expanded(flex: _gutterFlex, child: Container()));
      }
      words.add(Expanded(flex: _cellFlex, child: _buildWord()));
    }
    return Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: words);
  }

  Widget _buildWord() {
    List<Widget> letters = <Widget>[];
    for (int i = 0; i < ILLordle.wordLength; i++) {
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
    textCapitalization: TextCapitalization.characters,
    maxLines: null,
    maxLength: 2,
    expands: true,
    showCursor: false,
    autocorrect: false,
    autofocus: widget.autofocus,
    onSubmitted: _onTextSubmit,
  );

  void _onTextChanged() {
    if (_textController.text.isNotEmpty) {
      String textContent = _textController.text.trim();
      if (textContent.isNotEmpty) {
        _onKeyCharacter(textContent.substring(0, 1));
      }
    }
    else {
      _onBackward();
    }
    if (_textController.text != _textFieldValue) {
      _textController.text = _textFieldValue;
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

  void _onBackward() {
    debugPrint('Backward');
    _textFocusNode.requestFocus(); // show again
  }

  void _onSubmitWord() {
    debugPrint('Submit');
    _textFocusNode.requestFocus(); // show again
  }
}

class ILLordle {
  static const int wordLength = 5;
  static const int numberOfWords = 5;

  String word;
  List<String> moves;
  ILLordle(this.word, { this.moves = const <String>[]});

  // Accessories

  bool get isSucceeded => moves.isNotEmpty && (moves.last == word);
  bool get isFailed => (moves.length == numberOfWords) && (moves.last != word);
  bool? get result {
    if (isSucceeded) {
      return true;
    } else if (isFailed) {
      return false;
    }
    else {
      return null;
    }
  }

  // Data Access

  static const String _storageDelimiter = '\n';

  static ILLordle? fromStorageString(String? value) {
    List<String> entries = (value != null) ? value.split(_storageDelimiter) : <String>[];
    return (1 < entries.length) ? ILLordle(entries.first, moves: entries.sublist(1)) : null;
  }

  String toStorageString() => <String>[
    word,
    ...moves
  ].join(_storageDelimiter);

  // Data Access

  static const String _dictioaryContentCategory = 'illordle_dictioary';
  static const String _dictioaryContentDelimiter = '\n';

  static Future<Set<String>?> loadDictionary() async {
    dynamic content = await Content().loadContentItem(_dictioaryContentCategory);
    return SetUtils.from(JsonUtils.stringValue(content)?.split(_dictioaryContentDelimiter));
  }

  static Future<_ILLordleDailyWord?> loadDailyWord() async =>
    Future.delayed(Duration(milliseconds: 500), () => _ILLordleDailyWord(
      word: 'viral',
      date: '2025-11-14',
      author: 'Anna Ceja',
      quote: 'Viral TokTok star Joshua Block visits UI',
    ));
}

class _ILLordleDailyWord {
  final String word;

  final String? date;
  final String? author;
  final String? quote;

  _ILLordleDailyWord({
    required this.word,
    this.date, this.author, this.quote,
  });

  DateTime? get dateTime =>
    (date != null) ? DateFormat('yyyy-MM-dd').tryParse(date ?? '') : null;
}
