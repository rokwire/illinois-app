

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:illinois/ext/Wordle.dart';
import 'package:illinois/model/Wordle.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/ui/illini/WordleKeyboard.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class WordleWidget extends StatefulWidget {

  final WordleGame game;
  final WordleDailyWord dailyWord;
  final WordleKeyboardController? keyboardController;
  final WordleTapCallback? onTap;
  final Set<String>? dictionary;
  final bool autofocus;
  final bool hintMode;
  final double gutterRatio;

  WordleWidget({super.key,
    required this.game,
    required this.dailyWord,
    this.keyboardController,
    this.onTap,
    this.dictionary,
    this.autofocus = false,
    this.hintMode = false,
    this.gutterRatio = 0.075,
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

  Widget get _wordleGameContent => WordleGameWidget(
    widget.game,
    dictionary: widget.dictionary,
    keyboardController: widget.keyboardController,
    onTap: widget.onTap,
    autofocus: widget.autofocus,
    hintMode: widget.hintMode,
    gutterRatio: widget.gutterRatio
  );

  Widget get _wordlePreviewContent => WordleGameWidget(
    widget.game,
    enabled: false,
    gutterRatio: widget.gutterRatio
  );

  Widget get _wordlePreviewLayer =>
    Container(color: Styles().colors.blackTransparent018,);

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
            if (widget.dailyWord.dateUni != null)
              Text(DateFormat(Localization().getStringEx('widget.wordle.game.status.date.text.format', 'MMMM, dd, yyyy')).format(widget.dailyWord.dateUni ?? DateTime.now()),
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
    Analytics().logSelect(target: 'Story Url');
    AppLaunchUrl.launch(context: context, url: widget.dailyWord.storyUrl, tryInternal: false);
  }

  void _onStatusPopupClose() {
    Analytics().logSelect(target: 'Close');
    setState(() {
      _gameStatusContentEnabled = false;
    });
  }
}

class WordleGameWidget extends StatefulWidget {

  static const String notifyGameOver = 'edu.illinois.rokwire.illini.wordle.game.over';
  static const String notifyGameProgress = 'edu.illinois.rokwire.illini.wordle.game.progress';

  final WordleGame game;
  final Set<String>? dictionary;
  final WordleKeyboardController? keyboardController;
  final WordleTapCallback? onTap;
  final bool enabled;
  final bool autofocus;
  final bool hintMode;
  final double gutterRatio;

  WordleGameWidget(this.game, { super.key,
    this.dictionary,
    this.keyboardController,
    this.onTap,
    this.enabled = true,
    this.autofocus = false,
    this.hintMode = false,
    this.gutterRatio = 0.075,
  });

  @override
  State<StatefulWidget> createState() => _WordleGameWidgetState();

}

class _WordleGameWidgetState extends State<WordleGameWidget> {

  static const String _textFieldValue = ' ';
  TextEditingController? _textController;
  FocusNode? _textFocusNode;

  WordleKeyboardSubscription? _keyboardSubscription;

  late List<String> _moves;
  String _rack = '';


  @override
  void initState() {
    if (_manualTextInputSupported) {
      _textController = TextEditingController(text: _textFieldValue);
      _textController?.addListener(_onTextChanged);
      _textFocusNode = FocusNode();
    }

    _keyboardSubscription = widget.keyboardController?.stream.listen(_onKeyboardKey);

    _moves = List<String>.from(widget.game.moves);
    super.initState();
  }

  @override
  void dispose() {
    _keyboardSubscription?.cancel();
    _textController?.removeListener(_onTextChanged);
    _textController?.dispose();
    _textFocusNode?.dispose();
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
      if (widget.enabled && _manualTextInputSupported)
        Positioned.fill(child: _textFieldWidget),
      _wordleWidget,
    ],);

  // Wordle

  Widget get _wordleWidget =>
    GestureDetector(behavior: HitTestBehavior.opaque, onTap: _onTapWordle, onLongPress: _onLongPressWordle, child:
      AspectRatio(aspectRatio: widget.game.asectRatio, child:
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
      String move = _moves[wordIndex];
      words.add(Expanded(flex: _cellFlex, child: _buildWord(
        word: move,
        status: widget.game.wordStatus(move),
        display: _WordleLetterDisplay.move
      )));
      wordIndex++;
    }

    if (_rack.isNotEmpty) {
      if (words.isNotEmpty) {
        words.add(Expanded(flex: _gutterFlex, child: Container()));
      }
      words.add(Expanded(flex: _cellFlex, child: _buildWord(
        word: _rack,
        status: widget.game.wordStatus(_rack),
        display: _WordleLetterDisplay.rack,
      )));
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

  Widget _buildWord({
    String word = '',
    List<WordleLetterStatus> status = const <WordleLetterStatus>[],
    _WordleLetterDisplay display = _WordleLetterDisplay.rack
  }) {

    int letterIndex = 0;
    List<Widget> letters = <Widget>[];

    int wordLength = min(word.length, widget.game.wordLength);
    while (letterIndex < wordLength) {
      if (letters.isNotEmpty) {
        letters.add(Expanded(flex: _gutterFlex, child: Container()));
      }
      String letter = word.substring(letterIndex, letterIndex + 1);
      WordleLetterStatus? letterStatus = ListUtils.entry(status, letterIndex);
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

  Widget _buildCell({
    String letter = '',
    WordleLetterStatus? status,
    _WordleLetterDisplay display = _WordleLetterDisplay.rack,
    bool hintMode = false
  }) {

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

    return Container(decoration: cellDecoration, child:
      Padding(padding: EdgeInsets.all(8), child:
        Center(child:
          Text(letter.toUpperCase(), style: textStyle,)
        )
      ),
    );
  }

  static const double _gutterPrec = 1000;
  int get _gutterFlex => (widget.gutterRatio * _gutterPrec).toInt();
  int get _cellFlex => ((1 - widget.gutterRatio) * _gutterPrec).toInt();

  // Keyboard

  bool get _manualTextInputSupported => false; /* WebUtils.isMobileDeviceWeb() || (widget.keyboardController == null) */

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
    if (_textController?.text.isNotEmpty == true) {
      String textContent = _textController?.text.trim() ?? '';
      if (textContent.isNotEmpty) {
        _onKeyCharacter(textContent.substring(0, 1));
      }
    }
    else {
      _onBackward();
    }
    if (_textController?.text != _textFieldValue) {
      _textController?.text = _textFieldValue;
    }
    _textFocusNode?.requestFocus(); // show again
  }

  void _onTextSubmit(String text) {
    WordleGame? game = _onSubmitWord();
    if (game?.isFinished != true)
      _textFocusNode?.requestFocus(); // show again
  }

  Widget _onBuildTextContextMenu(BuildContext context, EditableTextState editableTextState) =>
    Container();

  void _onTapWordle() {
    if (widget.onTap != null) {
      widget.onTap?.call();
    }
    else if (_textFocusNode?.hasFocus == true) {
      _textFocusNode?.unfocus();
    }
    else {
      _textFocusNode?.requestFocus();
    }
  }

  void _onLongPressWordle() {

  }

  void _onKeyboardKey(String key) {
    if (key == WordleKeyboard.Back) {
      _onBackward();
    }
    else if (key == WordleKeyboard.Return) {
      _onSubmitWord();
    }
    else if (key.isNotEmpty) {
      _onKeyCharacter(key.substring(0, 1));
    }
  }

  // Rack

  void _onKeyCharacter(String character) {
    //debugPrint('Key: $character');
    if (character.isWordleAlpha && (_rack.length < widget.game.wordLength) && mounted) {
      setState(() {
        _rack = _rack + character.toUpperCase();
      });
    }
  }

  void _onBackward() {
    //debugPrint('Backward');
    if (_rack.isNotEmpty && mounted) {
      setState(() {
        _rack = _rack.substring(0, _rack.length - 1);
      });
    }
  }

  WordleGame? _onSubmitWord() {
    //debugPrint('Submit');
    if (_rack.length == widget.game.wordLength) {
      if ((widget.dictionary?.isNotEmpty == true) && (Storage().debugWordleIgnoreDictionary != true) && (widget.dictionary?.contains(_rack) != true)) {
        _logAnalytics(_rack, _moves.length + 1, status: AnalyticsIllordleEventStatus.notInDictionary);
        AppToast.showMessage(Localization().getStringEx('widget.wordle.move.invalid.text', 'Not in word list'), gravity: ToastGravity.CENTER, duration: Duration(milliseconds: 1000));
        _textFocusNode?.requestFocus(); // show again
      }
      else if (_moves.length < widget.game.numberOfWords) {
        setState(() {
          _moves.add(_rack);
          _rack = '';
        });

        WordleGame game = WordleGame.fromOther(widget.game, moves: _moves);
        game.saveToStorage();

        if (_moves.last == widget.game.word) {
          _logAnalytics(_moves.last, _moves.length, status: AnalyticsIllordleEventStatus.success);
          NotificationService().notify(WordleGameWidget.notifyGameOver, game);
        }
        if (_moves.length == widget.game.numberOfWords) {
          _logAnalytics(_moves.last, _moves.length, status: AnalyticsIllordleEventStatus.fail);
          NotificationService().notify(WordleGameWidget.notifyGameOver, game);
        }
        else {
          _logAnalytics(_moves.last, _moves.length);
          NotificationService().notify(WordleGameWidget.notifyGameProgress, game);
        }
        return game;
      }
    }
    return null;
  }

  void _logAnalytics(String guess, int attempt, { AnalyticsIllordleEventStatus? status }) =>
      Analytics().logIllordle(
        word: widget.game.word,
        guess: guess,
        attempt: attempt,
        status: status,
      );

}

enum _WordleLetterDisplay { move, rack, }

typedef WordleTapCallback = void Function();