

import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:rokwire_plugin/ext/network.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/network.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:uuid/uuid.dart';

class WordlePanel extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _WordlePanelState();
}

class _WordlePanelState extends State<WordlePanel> with NotificationsListener {

  WordleGame? _game;
  WordleDailyWord? _dailyWord;
  Set<String>? _dictionary;
  bool _loadProgress = false;
  bool _hintMode = false;

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
    appBar: HeaderBar(title: Localization().getStringEx('panel.wordle.header.title', 'ILLordle'),),
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
              GestureDetector(onLongPress: _onLongPressLogo, onDoubleTap: _onDoubleTapLogo, child:
                Styles().images.getImage('illordle-logo') ?? Container()
              )
            ),
            Expanded(flex: 1, child: Container()),
          ],),
          Padding(padding: EdgeInsets.symmetric(vertical: 6), child:
            Text(Localization().getStringEx('panel.wordle.heading.info.text', 'Presented by The Daily Illini'), style: Styles().textStyles.getTextStyleEx('widget.message.light.small'), textAlign: TextAlign.center,)
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
        game: _game ??= WordleGame(_dailyWord!.word),
        dailyWord: _dailyWord!,
        dictionary: _dictionary,
        autofocus: true,
        hintMode: _hintMode,
      );
    }
  }

  Widget get _loadingContent => Center(child:
    SizedBox(width: 32, height: 32, child:
      CircularProgressIndicator(color: Styles().colors.fillColorSecondary, strokeWidth: 3,),
    ),
  );

  Widget get _errorContent => Center(child:
    Text(Localization().getStringEx('panel.wordle.message.error.text', 'Failed to load daily target'), style: Styles().textStyles.getTextStyle("widget.message.regular.fat"), textAlign: TextAlign.center,)
  );

  // Data

  Future<void> _initData() async {
    setState(() {
      _loadProgress = true;
    });

    List<dynamic> results = await Future.wait([
      WordleGame.loadDailyWord(),
      WordleGame.loadDictionary(),
    ]);

    WordleGame? game = WordleGame.fromStorage();
    WordleDailyWord? dailyWord = JsonUtils.cast(ListUtils.entry(results, 0));
    Set<String>? dictionary = JsonUtils.setStringsValue(ListUtils.entry(results, 1));
    if ((dailyWord != null) && ((game == null) || (game.word != dailyWord.word))) {
      game = WordleGame(dailyWord.word);
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

  void _onGameOver(WordleGame? game) {
    if ((game != null) && mounted) {
      setState(() {
        _game = game;
      });
    }
  }

  void _onLongPressLogo() {
    if (_dailyWord != null) {
      setState((){
        _game = WordleGame(_dailyWord!.word);
      });
      _game?.saveToStorage();
      AppToast.showMessage('New Game', gravity: ToastGravity.CENTER, duration: Duration(milliseconds: 1000));
    }
  }

  void _onDoubleTapLogo() {
    setState(() {
      _hintMode = !_hintMode;
    });
    AppToast.showMessage('Hint Mode: ' + (_hintMode ? 'ON' : 'OFF'), gravity: ToastGravity.CENTER, duration: Duration(milliseconds: 1000));
  }
}

class WordleWidget extends StatefulWidget {

  final WordleGame game;
  final WordleDailyWord dailyWord;
  final Set<String>? dictionary;
  final bool autofocus;
  final bool hintMode;

  WordleWidget({super.key,
    required this.game,
    required this.dailyWord,
    this.dictionary,
    this.autofocus = false,
    this.hintMode = false,
  });

  @override
  State<StatefulWidget> createState() => _WordleWidgetState();
}

class _WordleWidgetState extends State<WordleWidget> {

  bool _gameStatusContentEnabled = true;

  @override
  void didUpdateWidget(covariant WordleWidget oldWidget) {
    if ((widget.game != oldWidget.game) && mounted) {
      _gameStatusContentEnabled = true;
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) => widget.game.isFinished ?
    _gameStatusContent : _wordleGameContent;

  Widget get _wordleGameContent => WordleGameWidget(widget.game, dictionary: widget.dictionary, autofocus: widget.autofocus, hintMode: widget.hintMode);
  Widget get _wordlePreviewContent => WordleGameWidget(widget.game, enabled: false,);
  Widget get _wordlePreviewLayer =>  Container(color: Styles().colors.blackTransparent018,);

  Widget get _gameStatusContent =>
    Stack(children: [
      _wordlePreviewContent,
      if (_gameStatusContentEnabled)
        ...[
          Positioned.fill(child: _wordlePreviewLayer),
          Positioned.fill(child:
            Align(alignment: Alignment.bottomCenter, child:
              Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8), child:
                _gameStatusPopup,
              )
            )
          ),
        ]
    ],);


  Widget get _gameStatusPopup =>
    Container(decoration: _gameStatusPopupDecoration, child:
      Stack(children: [
        _gameStatusPopupContent,
        Positioned.fill(child:
          Align(alignment: Alignment.topRight, child:
            _gameStatusPopupCloseButton
          )
        ),
      ],)
    );

  Widget get _gameStatusPopupContent =>
    Padding(padding: _gameStatusPopupPadding, child:
      Column(mainAxisSize: MainAxisSize.min, children: [
        Text(widget.game.isSucceeded ?
            Localization().getStringEx('widget.wordle.game.status.succeeded.title', 'You win!') :
            Localization().getStringEx('widget.wordle.game.status.failed.title', 'You lost'),
          style: _gameStatusTitleTextStyle, textAlign: TextAlign.center,
        ),

        Padding(padding: EdgeInsets.only(top: 12), child:
          Column(mainAxisSize: MainAxisSize.min, children: [
            Text(Localization().getStringEx('widget.wordle.game.status.word.text', 'Today\'s word: {{word}}').replaceAll('{{word}}', widget.dailyWord.word.toUpperCase()),
              style: _gameStatusSectionTextStyle, textAlign: TextAlign.center,
            ),
            if (widget.dailyWord.dateUtc != null)
              Text(DateFormat(Localization().getStringEx('widget.wordle.game.status.date.text.format', 'MMMM, dd, yyyy')).format(widget.dailyWord.dateUtc?.toLocal() ?? DateTime.now()),
                style: _gameStatusInfoTextStyle, textAlign: TextAlign.center,
              ),
            if (widget.game.isSucceeded && (widget.dailyWord.author?.isNotEmpty == true))
              Text(Localization().getStringEx('widget.wordle.game.status.author.text', 'Edited by {{author}}').replaceAll('{{author}}', widget.dailyWord.author ?? ''),
                style: _gameStatusInfoTextStyle, textAlign: TextAlign.center,
              ),
            if (widget.game.isSucceeded && (widget.dailyWord.storyTitle?.isNotEmpty == true))
              ...[
                Padding(padding: EdgeInsets.only(top: 12), child:
                  Text(Localization().getStringEx('widget.wordle.game.status.related_to.text', 'Related to this word'),
                    style: _gameStatusSectionTextStyle, textAlign: TextAlign.center,
                  ),
                ),
                Padding(padding: EdgeInsets.only(top: 2, bottom: 4), child:
                  _gameStatusStoryWrapper(child:
                    Container(decoration: _gameStatusStoryDecoration, padding: _gameStatusStoryPadding, child:
                      Text(widget.dailyWord.storyTitle ?? '',
                        style: _gameStatusInfoTextStyle, textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                )
              ]
          ]),
        ),
      ],)
    );

  Widget _gameStatusStoryWrapper({ required Widget child }) =>
    (widget.dailyWord.storyUrl?.isNotEmpty == true) ?
      InkWell(onTap: () => _onTapStatusStory(context), child: child,) : child;

  Widget get _gameStatusPopupCloseButton =>
    Semantics(label: Localization().getStringEx('dialog.close.title', 'Close'), button: true, excludeSemantics: true, child:
      InkWell(onTap : _onStatusPopupClose, child:
        Padding(padding: EdgeInsets.all(14), child:
          Styles().images.getImage('close-circle-small', excludeFromSemantics: true)
        ),
      ),
    );

  Decoration get _gameStatusPopupDecoration => BoxDecoration(
    color: Styles().colors.surface,
    border: Border.all(color: Styles().colors.surfaceAccent),
    borderRadius: BorderRadius.all(Radius.circular(16)),
  );

  EdgeInsetsGeometry get _gameStatusPopupPadding => EdgeInsets.symmetric(horizontal: 24, vertical: 8);

  TextStyle? get _gameStatusTitleTextStyle => Styles().textStyles.getTextStyle('widget.message.extra_large.extra_fat');
  TextStyle? get _gameStatusSectionTextStyle => Styles().textStyles.getTextStyle('widget.message.regular.fat');
  TextStyle? get _gameStatusInfoTextStyle => Styles().textStyles.getTextStyle('widget.message.regular');

  Decoration get _gameStatusStoryDecoration => BoxDecoration(
    color: Styles().colors.lightGray,
    border: Border.all(color: Styles().colors.surfaceAccent2),
  );
  EdgeInsetsGeometry get _gameStatusStoryPadding => EdgeInsets.symmetric(horizontal: 8, vertical: 4);

  void _onTapStatusStory(BuildContext context) {
    AppLaunchUrl.launch(context: context, url: widget.dailyWord.storyUrl, tryInternal: false);
  }

  void _onStatusPopupClose() {
    setState(() {
      _gameStatusContentEnabled = false;
    });
  }
}

class WordleGameWidget extends StatefulWidget {

  static const String notifyGameOver = 'edu.illinois.rokwire.illini.wordle.game.over';

  final WordleGame game;
  final Set<String>? dictionary;
  final bool enabled;
  final bool autofocus;
  final bool hintMode;

  WordleGameWidget(this.game, { super.key,
    this.dictionary,
    this.enabled = true,
    this.autofocus = false,
    this.hintMode = false,
  });

  @override
  State<StatefulWidget> createState() => _WordleGameWidgetState();

}

class _WordleGameWidgetState extends State<WordleGameWidget> {

  static const String _textFieldValue = ' ';
  final TextEditingController _textController = TextEditingController(text: _textFieldValue);
  final FocusNode _textFocusNode = FocusNode();

  late List<String> _moves;
  String _rack = '';
  
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
  void didUpdateWidget(covariant WordleGameWidget oldWidget) {
    if ((widget.game != oldWidget.game) && mounted) {
      _moves = List<String>.from(widget.game.moves);
      _rack = '';
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) =>
    Stack(children: [
      if (widget.enabled)
        Positioned.fill(child: _textFieldWidget),
      _wordleWidget,
    ],);

  // Wordle

  Widget get _wordleWidget =>
    GestureDetector(behavior: HitTestBehavior.opaque, onTap: _onTapWordle, onLongPress: _onLongPressWordle, child:
      AspectRatio(aspectRatio: 1, child:
        _buildWords()
      ),
    );

  Widget _buildWords() {

    int wordIndex = 0;
    List<Widget> words = <Widget>[];

    int movesCount = min(_moves.length, widget.game.numberOfWords);
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

    while (wordIndex < widget.game.numberOfWords) {
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

    int wordLength = min(word.length, widget.game.wordLength);
    while (letterIndex < wordLength) {
      if (letters.isNotEmpty) {
        letters.add(Expanded(flex: _gutterFlex, child: Container()));
      }
      String letter = word.substring(letterIndex, letterIndex + 1);
      _WordleLetterStatus? letterStatus = widget.game.letterStatus(letter, letterIndex);
      letters.add(Expanded(flex: _cellFlex, child: _buildCell(
        letter: letter,
        status: letterStatus,
        display: display,
        hintMode: widget.hintMode,
      )));
      letterIndex++;
    }

    while (letterIndex < widget.game.wordLength) {
      if (letters.isNotEmpty) {
        letters.add(Expanded(flex: _gutterFlex, child: Container()));
      }
      letters.add(Expanded(flex: _cellFlex, child: _buildCell()));
      letterIndex++;
    }

    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: letters);
  }

  Widget _buildCell({String letter = '', _WordleLetterStatus? status, _WordleLetterDisplay display = _WordleLetterDisplay.rack, bool hintMode = false }) {

    Color backColor = ((display == _WordleLetterDisplay.move) && (status != null)) ? status.color : Styles().colors.surface;
    TextStyle? textStyle = ((display == _WordleLetterDisplay.move) && (status != null)) ?
      Styles().textStyles.getTextStyleEx('widget.message.extra_large.fat', color: Styles().colors.textColorPrimary) :
      Styles().textStyles.getTextStyle('widget.message.extra_large.fat');

    bool previewHint = (display == _WordleLetterDisplay.rack) && (status != null) && hintMode;
    Color? borderColor = previewHint ? status.color : Styles().colors.surfaceAccent;
    double borderWidth = previewHint ? 3 : 1;
    Decoration cellDecoration = BoxDecoration(
      color: backColor,
      border: Border.all(color: borderColor, width: borderWidth)
    );


    return AspectRatio(aspectRatio: 1, child:
      Container(decoration: cellDecoration, child:
        Padding(padding: EdgeInsets.all(8), child:
          Center(child:
            Text(letter.toUpperCase(), style: textStyle,)
          )
        ),
      ),
    );
  }

  static const double _gutter = 0.075;
  static const double _gutterPrec = 1000;
  int get _gutterFlex => (_gutter * _gutterPrec).toInt();
  int get _cellFlex => ((1 - _gutter) * _gutterPrec).toInt();


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
    enableSuggestions: false,
    enableInteractiveSelection: false,
    autofocus: widget.autofocus,
    onSubmitted: _onTextSubmit,
    contextMenuBuilder: _onBuildTextContextMenu,
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

  Widget _onBuildTextContextMenu(BuildContext context, EditableTextState editableTextState) =>
    Container();

  void _onTapWordle() {
    if (_textFocusNode.hasFocus) {
      _textFocusNode.unfocus();
    }
    else {
      _textFocusNode.requestFocus();
    }
  }

  void _onLongPressWordle() {

  }
  // Rack

  void _onKeyCharacter(String character) {
    debugPrint('Key: $character');
    if (character.isAlpha && (_rack.length < widget.game.wordLength) && mounted) {
      setState(() {
        _rack = _rack + character.toUpperCase();
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
    if (_rack.length == widget.game.wordLength) {
      if ((widget.dictionary?.isNotEmpty == true) && (widget.dictionary?.contains(_rack) != true)) {
        AppToast.showMessage(Localization().getStringEx('widget.wordle.move.invalid.text', 'Not in word list'), gravity: ToastGravity.CENTER, duration: Duration(milliseconds: 1000));
        _textFocusNode.requestFocus(); // show again
      }
      else if (_moves.length < widget.game.numberOfWords) {
        setState(() {
          _moves.add(_rack);
          _rack = '';
        });

        WordleGame game = WordleGame.fromOther(widget.game, moves: _moves);
        game.saveToStorage();

        if ((_moves.last == widget.game.word) || (_moves.length == widget.game.numberOfWords)) {
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

class WordleGame {

  final String uuid;
  final String word;
  final Set<String> _wordChars;
  final List<String> moves;

  WordleGame(this.word, { String? uuid, this.moves = const <String>[] }) :
    this.uuid = uuid ?? Uuid().v1(),
    _wordChars = Set<String>.from(word.characters);

  factory WordleGame.fromOther(WordleGame other, {
    String? word,
    String? uuid,
    List<String>? moves,
  }) => WordleGame(word ?? other.word,
    uuid: uuid ?? other.uuid,
    moves: moves ?? other.moves,
  );

  // Accessories

  int get wordLength => word.length;
  int get numberOfWords => wordLength + 1;

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

  // Equality

  @override
  bool operator==(Object other) =>
    (other is WordleGame) &&
    (word == other.word) &&
    (uuid == other.uuid) &&
    DeepCollectionEquality().equals(moves, other.moves);

  @override
  int get hashCode =>
    word.hashCode ^
    uuid.hashCode ^
    DeepCollectionEquality().hash(moves);

  // Json Serialization

  static WordleGame? fromJson(Map<String, dynamic>? json) {
    String? word = JsonUtils.stringValue(json?['word']);
    String? uuid = JsonUtils.stringValue(json?['uuid']);
    List<String>? moves = JsonUtils.listStringsValue(json?['moves']);
    return ((word != null) && (uuid != null) && (moves != null)) ? WordleGame(word, uuid: uuid, moves: moves) : null;
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'word': word,
    'uuid': uuid,
    'moves': moves,
  };

  // Storage Serialization

  static WordleGame? fromStorage() =>
    WordleGame.fromJson(JsonUtils.decodeMap(Storage().illordleGame) );

  void saveToStorage() =>
    Storage().illordleGame = JsonUtils.encode(toJson());

  // Data Access

  static Future<Set<String>?> loadDictionary() async {
    String? url = Config().illordleWordsUrl;
    Response? response = (url?.isNotEmpty == true) ? await Network().get(url) : null;
    return (response?.succeeded == true) ? SetUtils.from(JsonUtils.stringValue(response?.body)?.split(RegExp(r'[\r\n]')).map((String word) => word.toUpperCase())) : null;
  }

  static Future<WordleDailyWord?> loadDailyWord() async {
    String? url = Config().illordleDailyWordUrl;
    Response? response = (url?.isNotEmpty == true) ? await Network().get(url) : null;
    return (response?.succeeded == true) ? WordleDailyWord.fromJson(JsonUtils.decodeMap(response?.body)) : null;
  }
}

class WordleDailyWord {
  final String word;
  final DateTime? dateUtc;
  final String? author;
  final String? storyTitle;
  final String? storyUrl;

  const WordleDailyWord({
    required this.word,
    this.dateUtc, this.author,
    this.storyTitle, this.storyUrl,
  });

  // Json Serialization
  static WordleDailyWord? fromJson(Map<String, dynamic>? json) =>
    _fromJsonWord(JsonUtils.stringValue(json?['word']), json: json);

  static WordleDailyWord? _fromJsonWord(String? word, { Map<String, dynamic>? json }) => ((word != null) && word.isNotEmpty) ?
    WordleDailyWord(
      word: word.toUpperCase(),
      dateUtc: DateTimeUtils.dateTimeFromString(JsonUtils.stringValue(json?['date'],), format: 'EEE, d MMM yyyy hh:mm:ss Z', isUtc: true),
      author: JsonUtils.stringValue(json?['author']),
      storyTitle: JsonUtils.stringValue(json?['story_title']),
      storyUrl: JsonUtils.stringValue(json?['story_url']),
    ) : null;

  // Equality

  @override
  bool operator==(Object other) =>
    (other is WordleDailyWord) &&
    (word == other.word) &&
    (dateUtc == other.dateUtc) &&
    (author == other.author) &&
    (storyTitle == other.storyTitle);

  @override
  int get hashCode =>
    (word.hashCode) ^
    (dateUtc?.hashCode ?? 0) ^
    (author?.hashCode ?? 0) ^
    (storyTitle?.hashCode ?? 0);
}

enum _WordleLetterStatus { inPlace, inUse, outOfUse }

extension _WordleLetterStatusUi on _WordleLetterStatus {
  Color get color {
    switch (this) {
      case _WordleLetterStatus.inPlace: return Styles().colors.getColor('illordle.green') ?? const Color(0xFF21AA57);
      case _WordleLetterStatus.inUse: return Styles().colors.getColor('illordle.yellow') ?? const Color(0xFFE5B22E);
      case _WordleLetterStatus.outOfUse: return Styles().colors.getColor('illordle.gray') ?? const Color(0xFF7A7A7A);
    }
  }
}

enum _WordleLetterDisplay { move, rack, }

extension _StringExt on String {
  bool get isAlpha => (length == 1) && (toUpperCase() != toLowerCase());
}