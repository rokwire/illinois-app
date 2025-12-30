

import 'package:flutter/material.dart';
import 'package:illinois/model/Wordle.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Wordle.dart';
import 'package:illinois/ui/illini/WordleWidget.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class WordlePanel extends StatefulWidget {
  final WordleGame? game;
  final WordleDailyWord? dailyWord;
  final Set<String>? dictionary;

  WordlePanel({super.key, this.game, this.dailyWord, this.dictionary});

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
            AspectRatio(aspectRatio: _dailyWord?.asectRatio ?? 1.0, child:
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

    WordleDailyWord? dailyWord = widget.dailyWord;
    Set<String>? dictionary = widget.dictionary;

    List<Future<dynamic>> futures = <Future<dynamic>>[];

    int dailyWordIndex = (dailyWord == null) ? futures.length : -1;
    if (0 <= dailyWordIndex) {
      futures.add(WordleGameData.loadDailyWord());
    }

    int dictionaryIndex = (dictionary == null) ? futures.length : -1;
    if (0 <= dictionaryIndex) {
      futures.add(WordleGameData.loadDictionary());
    }


    if (0 < futures.length) {

      setState(() {
        _loadProgress = true;
      });

      List<dynamic> results = await Future.wait(futures);

      if (0 <= dailyWordIndex) {
        dailyWord = JsonUtils.cast(ListUtils.entry(results, dailyWordIndex));
      }

      if (0 <= dictionaryIndex) {
        dictionary = JsonUtils.setStringsValue(ListUtils.entry(results, dictionaryIndex));
      }
    }

    WordleGame? game = widget.game ??  WordleGame.fromStorage();
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

      _logFinishedAlert(game);
    }

  }

  // Analytics

  void _logFinishedAlert(WordleGame? game) {
    if ((game != null) && game.isFinished) {
      Analytics().logAlert(text: game.isSucceeded ?
        Localization().getStringEx('widget.wordle.game.status.succeeded.title', 'You win!', language: 'en') :
        Localization().getStringEx('widget.wordle.game.status.failed.title', 'You lost', language: 'en'));
    }
  }

  // Game

  void _onGameOver(WordleGame? game) {
    if ((game != null) && mounted) {
      _logFinishedAlert(game);
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


