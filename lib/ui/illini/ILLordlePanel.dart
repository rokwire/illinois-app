

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:intl/intl.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class ILLordlePanel extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _ILLordlePanelState();
}

class _ILLordlePanelState extends State<ILLordlePanel> with NotificationsListener {

  bool _loadProgress = false;
  Wordle? _game;
  WordleDailyWord? _dailyWord;
  Set<String>? _dictionary;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      WordleGameWidget.notifyGameOver,
    ]);
    _initData();
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  @override
  void onNotification(String name, dynamic param) {
    if (name == WordleGameWidget.notifyGameOver) {
      _onGameOver(JsonUtils.cast(param));
    }
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
            Expanded(flex: 2, child:
              GestureDetector(onLongPress: _onLongPressLogo, child:
                Styles().images.getImage('illordle-logo') ?? Container()
              )
            ),
            Expanded(flex: 1, child: Container()),
          ],),
          Padding(padding: EdgeInsets.symmetric(vertical: 6), child:
            Text(Localization().getStringEx('panel.illordle.heading.info.text', 'Presented by The Daily Illini'), style: Styles().textStyles.getTextStyleEx('widget.message.light.small'), textAlign: TextAlign.center,)
          ),
          Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16), child:
            AspectRatio(aspectRatio: 1, child:
              _bodyContent
            ),
          ),
        ],)
    )
  );

  Widget get _bodyContent {
    if (_loadProgress) {
      return _loadingContent;
    } else if (_dailyWord == null) {
      return _errorContent;
    } else {
      return WordleWidget(
        game: _game ??= Wordle(_dailyWord!.word),
        dailyWord: _dailyWord!,
        dictionary: _dictionary,
        autofocus: true
      );
    }
  }

  Widget get _loadingContent => Center(child:
    SizedBox(width: 32, height: 32, child:
      CircularProgressIndicator(color: Styles().colors.fillColorSecondary, strokeWidth: 3,),
    ),
  );

  Widget get _errorContent => Center(child:
    Text(Localization().getStringEx('panel.illordle.message.error.text', 'Failed to load daily target'), style: Styles().textStyles.getTextStyle("widget.message.regular.fat"), textAlign: TextAlign.center,)
  );

  // Data

  Future<void> _initData() async {
    setState(() {
      _loadProgress = true;
    });

    List<dynamic> results = await Future.wait([
      Wordle.loadDailyWord(),
      Wordle.loadDictionary(),
    ]);

    Wordle? game = Wordle.fromStorageString(Storage().illordleGame);
    WordleDailyWord? dailyWord = JsonUtils.cast(ListUtils.entry(results, 0));
    Set<String>? dictionary = JsonUtils.setStringsValue(ListUtils.entry(results, 1));
    if ((dailyWord != null) && ((game == null) || (game.word != dailyWord.word))) {
      game = Wordle(dailyWord.word);
    }

    if (mounted) {
      setState(() {
        _game = game;
        _dailyWord = dailyWord;
        _dictionary = dictionary;
        _loadProgress = false;
      });
    }
  }

  // Game

  void _onGameOver(Wordle? game) {
    if ((game != null) && mounted) {
      setState(() {
        _game = game;
      });
    }
  }

  void _onLongPressLogo() {
    if (_dailyWord != null) {
      setState((){
        _game = Wordle(_dailyWord!.word);
      });
      Storage().illordleGame = _game?.toStorageString();
      AppToast.showMessage('New Game', duration: Duration(milliseconds: 1000));
    }
  }
}

class WordleWidget extends StatelessWidget {

  final Wordle game;
  final WordleDailyWord dailyWord;
  final Set<String>? dictionary;
  final bool autofocus;

  WordleWidget({super.key,
    required this.game,
    required this.dailyWord,
    this.dictionary,
    this.autofocus = false
  });

  @override
  Widget build(BuildContext context) => game.isFinished ?
    _gameStatusContent : _wordleGameContent;

  Widget get _wordlePreviewContent => WordleGameWidget(game, enabled: false,);
  Widget get _wordleGameContent => WordleGameWidget(game, dictionary: dictionary, autofocus: autofocus,);
  Widget get _wordleStatusLayer =>  Container(color: Styles().colors.blackTransparent018,);

  Widget get _gameStatusContent =>
    Stack(children: [
      _wordlePreviewContent,
      Positioned.fill(child: _wordleStatusLayer),
      Positioned.fill(child:
        Align(alignment: Alignment.bottomCenter, child:
          Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8), child:
            _gameStatusPopup,
          )
        )
      ),
    ],);


  Widget get _gameStatusPopup {
    return Container(decoration: _gameStatusPopupDecoration, padding: _gameStatusPopupPadding, child:
      Column(mainAxisSize: MainAxisSize.min, children: [
        Text(game.isSucceeded ?
            Localization().getStringEx('panel.illordle.game.status.succeeded.title', 'You win!') :
            Localization().getStringEx('panel.illordle.game.status.failed.title', 'You lost'),
          style: _gameStatusTitleTextStyle, textAlign: TextAlign.center,
        ),

        Padding(padding: EdgeInsets.only(top: 12), child:
          Column(mainAxisSize: MainAxisSize.min, children: [
            Text(Localization().getStringEx('panel.illordle.game.status.word.text', 'Today\'s word: {{word}}').replaceAll('{{word}}', dailyWord.word.toUpperCase()),
              style: _gameStatusSectionTextStyle, textAlign: TextAlign.center,
            ),
            Text(DateFormat(Localization().getStringEx('panel.illordle.game.status.date.text.format', 'MMMM, dd, yyyy')).format(dailyWord.dateTime ?? DateTime.now()),
              style: _gameStatusInfoTextStyle, textAlign: TextAlign.center,
            ),
            if (game.isSucceeded && (dailyWord.author?.isNotEmpty == true))
              Text(Localization().getStringEx('panel.illordle.game.status.author.text', 'Edited by {{author}}').replaceAll('{{author}}', dailyWord.author ?? ''),
                style: _gameStatusInfoTextStyle, textAlign: TextAlign.center,
              ),
            if (game.isSucceeded && (dailyWord.quote?.isNotEmpty == true))
              ...[
                Padding(padding: EdgeInsets.only(top: 12), child:
                  Text(Localization().getStringEx('panel.illordle.game.status.related_to.text', 'Related to this word'),
                    style: _gameStatusSectionTextStyle, textAlign: TextAlign.center,
                  ),
                ),
                Padding(padding: EdgeInsets.only(top: 2, bottom: 4), child:
                  Container(decoration: _gameStatusQuoteDecoration, padding: _gameStatusQuotePadding, child:
                    Text(dailyWord.quote ?? '',
                      style: _gameStatusInfoTextStyle, textAlign: TextAlign.center,
                    ),
                  )
                )
              ]
          ]),
        ),
      ],)
    );
  }

  Decoration get _gameStatusPopupDecoration => BoxDecoration(
    color: Styles().colors.surface,
    border: Border.all(color: Styles().colors.surfaceAccent),
    borderRadius: BorderRadius.all(Radius.circular(16)),
  );

  EdgeInsetsGeometry get _gameStatusPopupPadding => EdgeInsets.symmetric(horizontal: 24, vertical: 8);

  TextStyle? get _gameStatusTitleTextStyle => Styles().textStyles.getTextStyle('widget.message.extra_large.extra_fat');
  TextStyle? get _gameStatusSectionTextStyle => Styles().textStyles.getTextStyle('widget.message.regular.fat');
  TextStyle? get _gameStatusInfoTextStyle => Styles().textStyles.getTextStyle('widget.message.regular');

  Decoration get _gameStatusQuoteDecoration => BoxDecoration(
    color: Styles().colors.lightGray,
    border: Border.all(color: Styles().colors.surfaceAccent2),
  );
  EdgeInsetsGeometry get _gameStatusQuotePadding => EdgeInsets.symmetric(horizontal: 8, vertical: 4);
}

class WordleGameWidget extends StatefulWidget {

  static const String notifyGameOver = 'edu.illinois.rokwire.illini.wordle.game.over';

  final Wordle game;
  final Set<String>? dictionary;
  final bool enabled;
  final bool autofocus;

  WordleGameWidget(this.game, {super.key, this.dictionary, this.enabled = true, this.autofocus = false});

  @override
  State<StatefulWidget> createState() => _WordleGameWidgetState();

}

class _WordleGameWidgetState extends State<WordleGameWidget> {

  static const String _textFieldValue = ' ';
  final TextEditingController _textController = TextEditingController(text: _textFieldValue);
  final FocusNode _textFocusNode = FocusNode();

  late List<String> _moves;
  String _rack = '';
  
  String? _message;

  @override
  void initState() {
    _textController.addListener(_onTextChanged);

    _moves = List<String>.from(widget.game.moves);

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
      if (widget.enabled)
        Positioned.fill(child: _textFieldWidget),
      _wordleWidget,
      if (_message?.isNotEmpty == true)
        ...<Widget>[
          Positioned.fill(child: _messageBackground),
          Positioned.fill(child: Center(child: _messagePopup,)),
        ],
    ],);

  // Wordle

  Widget get _wordleWidget =>
    GestureDetector(onTap: _onTapWordle, child:
      AspectRatio(aspectRatio: 1, child:
        _buildWords()
      ),
    );

  Widget _buildWords() {

    int wordIndex = 0;
    List<Widget> words = <Widget>[];

    int movesCount = min(_moves.length, Wordle.numberOfWords);
    while (wordIndex < movesCount) {
      if (words.isNotEmpty) {
        words.add(Expanded(flex: _gutterFlex, child: Container()));
      }
      words.add(Expanded(flex: _cellFlex, child: _buildWord(_moves[wordIndex], _WordleLetterDisplay.move)));
      wordIndex++;
    }

    if (_rack.isNotEmpty) {
      if (words.isNotEmpty) {
        words.add(Expanded(flex: _gutterFlex, child: Container()));
      }
      words.add(Expanded(flex: _cellFlex, child: _buildWord(_rack, _WordleLetterDisplay.rack)));
      wordIndex++;
    }

    while (wordIndex < Wordle.numberOfWords) {
      if (words.isNotEmpty) {
        words.add(Expanded(flex: _gutterFlex, child: Container()));
      }
      words.add(Expanded(flex: _cellFlex, child: _buildWord()));
      wordIndex++;
    }

    return Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: words);
  }

  Widget _buildWord([String word = '', _WordleLetterDisplay display = _WordleLetterDisplay.rack]) {

    int letterIndex = 0;
    List<Widget> letters = <Widget>[];

    int wordLength = min(word.length, Wordle.wordLength);
    while (letterIndex < wordLength) {
      if (letters.isNotEmpty) {
        letters.add(Expanded(flex: _gutterFlex, child: Container()));
      }
      String letter = word.substring(letterIndex, letterIndex + 1);
      _WordleLetterStatus? letterStatus = (display == _WordleLetterDisplay.move) ? widget.game.letterStatus(letter, letterIndex) : null;
      letters.add(Expanded(flex: _cellFlex, child: _buildCell(letter, letterStatus)));
      letterIndex++;
    }

    while (letterIndex < Wordle.wordLength) {
      if (letters.isNotEmpty) {
        letters.add(Expanded(flex: _gutterFlex, child: Container()));
      }
      letters.add(Expanded(flex: _cellFlex, child: _buildCell()));
      letterIndex++;
    }

    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: letters);
  }

  Widget _buildCell([String letter = '', _WordleLetterStatus? status]) {

    Color? backColor = status?.color ?? Styles().colors.surface;

    TextStyle? textStyle = (status != null) ?
      Styles().textStyles.getTextStyleEx('widget.message.extra_large.fat', color: Styles().colors.textColorPrimary) :
      Styles().textStyles.getTextStyle('widget.message.extra_large.fat');

    return AspectRatio(aspectRatio: 1, child:
      Container(decoration: _cellDecoration(backColor), padding: EdgeInsets.all(8), child:
        Center(child:
          Text(letter.toUpperCase(), style: textStyle,)
        )
      ),
    );
  }

  Decoration _cellDecoration(Color? backColor) => BoxDecoration(
    color: backColor ?? Styles().colors.surface,
    border: Border.all(color: Styles().colors.surfaceAccent)
  );

  static const double gutter = 0.075;
  static const double gutterPrec = 1000;
  int get _gutterFlex => (gutter * gutterPrec).toInt();
  int get _cellFlex => ((1 - gutter) * gutterPrec).toInt();

  // Message

  Widget get _messageBackground => GestureDetector(onTap: _onTapMessagePopupBackground, child:
    Container(color: Styles().colors.surfaceAccentTransparent15,)
  );

  Widget get _messagePopup =>
    Container(decoration: _messagePopupDecoration, padding: _messagePopupPadding, child:
      Text(_message ?? '', style: _messagePopupTextStyle, textAlign: TextAlign.center,)
    );

  Decoration get _messagePopupDecoration => BoxDecoration(
    color: Styles().colors.surface,
    border: Border.all(color: Styles().colors.surfaceAccent),
    borderRadius: BorderRadius.all(Radius.circular(12)),
  );

  EdgeInsetsGeometry get _messagePopupPadding => EdgeInsets.symmetric(horizontal: 12, vertical: 6);
  TextStyle? get _messagePopupTextStyle => Styles().textStyles.getTextStyle('widget.message.regular.fat');

  Future<void> _showMessage(String message, { Duration duration = const Duration(milliseconds: 1000)}) async {
    setState(() {
      _message = message;
    });
    await Future.delayed(duration);
    if (mounted && (_message == message)) {
      setState(() {
        _message = null;
      });
    }
  }

  void _onTapMessagePopupBackground() {
    setState(() {
      _message = null;
    });
  }

  // Keyboard

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

  // Rack

  void _onKeyCharacter(String character) {
    debugPrint('Key: $character');
    if (character.isAlpha && (_rack.length < Wordle.wordLength) && mounted) {
      setState(() {
        _rack = _rack + character.toLowerCase();
      });
    }
    _textFocusNode.requestFocus(); // show again
  }

  void _onBackward() {
    debugPrint('Backward');
    if (_rack.isNotEmpty && mounted) {
      setState(() {
        _rack = _rack.substring(0, _rack.length - 1);
      });
    }
    _textFocusNode.requestFocus(); // show again
  }

  void _onSubmitWord() {
    debugPrint('Submit');
    if (_rack.length == Wordle.wordLength) {
      if ((widget.dictionary?.isNotEmpty == true) && (widget.dictionary?.contains(_rack) != true)) {
        _showMessage(Localization().getStringEx('panel.illordle.move.invalid.text', 'Not in word list')).then((_){
          _textFocusNode.requestFocus(); // show again
        });
      }
      else if (_moves.length < Wordle.numberOfWords) {
        setState(() {
          _moves.add(_rack);
          _rack = '';
        });

        Wordle game = Wordle.fromOther(widget.game, moves: _moves);
        Storage().illordleGame = game.toStorageString();

        if ((_moves.last == widget.game.word) || (_moves.length == Wordle.numberOfWords)) {
          NotificationService().notify(WordleGameWidget.notifyGameOver, game);
        }
        else {
          _textFocusNode.requestFocus(); // show again
        }
      }
      else {
        _textFocusNode.requestFocus(); // show again
      }
    }
    else {
      _textFocusNode.requestFocus(); // show again
    }
  }

}

class Wordle {
  static const int wordLength = 5;
  static const int numberOfWords = 5;

  String word;
  Set<String> _wordChars;
  List<String> moves;

  Wordle(this.word, { this.moves = const <String>[]}) :
    _wordChars = Set<String>.from(word.characters);

  factory Wordle.fromOther(Wordle other, {
    String? word,
    List<String>? moves,
  }) => Wordle(word ?? other.word,
    moves: moves ?? other.moves,
  );

  // Accessories

  bool get isSucceeded => moves.isNotEmpty && (moves.last == word);
  bool get isFailed => (moves.length == numberOfWords) && (moves.last != word);
  bool get isFinished => isSucceeded || isFailed;

  _WordleLetterStatus letterStatus(String letter, [int position = 0]) {
    if (_wordChars.contains(letter)) {
      return ((0 <= position) && (position < word.length) && (word.substring(position, position + 1) == letter)) ? _WordleLetterStatus.inPlace : _WordleLetterStatus.inUse;
    }
    else {
      return _WordleLetterStatus.outOfUse;
    }
  }

  // Data Access

  static const String _storageDelimiter = '\n';

  static Wordle? fromStorageString(String? value) {
    List<String> entries = (value != null) ? value.split(_storageDelimiter) : <String>[];
    return (1 < entries.length) ? Wordle(entries.first, moves: entries.sublist(1)) : null;
  }

  String toStorageString() => <String>[
    word,
    ...moves
  ].join(_storageDelimiter);

  // Data Access

  static Future<Set<String>?> loadDictionary() async {
    return <String>{};
    // TMP: No Dictionary check for now
    // dynamic content = await Content().loadContentItem(_dictioaryContentCategory);
    // return SetUtils.from(JsonUtils.stringValue(content)?.split(_dictioaryContentDelimiter));
  }
  //static const String _dictioaryContentCategory = 'illordle_dictioary';
  //static const String _dictioaryContentDelimiter = '\n';

  static Future<WordleDailyWord?> loadDailyWord() async =>
    _sampeDailtyWord;
    // Future.delayed(Duration(milliseconds: 500), () => _sampeDailtyWord);

  static WordleDailyWord _sampeDailtyWord = const WordleDailyWord(
    word: 'viral',
    date: '2025-11-14',
    author: 'Anna Ceja',
    quote: 'Viral TokTok star Joshua Block visits UI',
  );
}

class WordleDailyWord {
  final String word;

  final String? date;
  final String? author;
  final String? quote;

  const WordleDailyWord({
    required this.word,
    this.date, this.author, this.quote,
  });

  DateTime? get dateTime =>
    (date != null) ? DateFormat('yyyy-MM-dd').tryParse(date ?? '') : null;
}

enum _WordleLetterStatus { inPlace, inUse, outOfUse }

extension _ILLordleLetterStatusUi on _WordleLetterStatus {
  Color get color {
    switch (this) {
      case _WordleLetterStatus.inPlace: return Styles().colors.getColor('illordle.green') ?? const Color(0xFF21AA57);
      case _WordleLetterStatus.inUse: return Styles().colors.getColor('illordle.yellow') ?? const Color(0xFFE5B22E);
      case _WordleLetterStatus.outOfUse: return Styles().colors.getColor('illordle.gray') ?? const Color(0xFF7A7A7A);
    }
  }
}

enum _WordleLetterDisplay { rack, move }

extension _StringExt on String {
  bool get isAlpha => (length == 1) && (toUpperCase() != toLowerCase());
}