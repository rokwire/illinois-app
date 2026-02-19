
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/model/Wordle.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/service/Wordle.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:illinois/ui/illini/WordleKeyboard.dart';
import 'package:illinois/ui/illini/WordlePanel.dart';
import 'package:illinois/ui/illini/WordleWidget.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:visibility_detector/visibility_detector.dart';

class HomeWordleWidget extends StatefulWidget {

  final String? favoriteId;
  final StreamController<String>? updateController;

  const HomeWordleWidget({super.key, this.favoriteId, this.updateController});

  static Widget handle({Key? key, String? favoriteId, HomeDragAndDropHost? dragAndDropHost, int? position}) =>
    HomeHandleWidget(key: key, favoriteId: favoriteId, dragAndDropHost: dragAndDropHost, position: position,
      title: title,
    );

  String get _title => title;
  static String get title => Localization().getStringEx('widget.home.wordle.header.title', 'ILLordle');

  @override
  State<StatefulWidget> createState() => _HomeWordleWidgetState();
}

class _HomeWordleWidgetState extends State<HomeWordleWidget> with NotificationsListener {

  WordleGame? _game;
  WordleDailyWord? _dailyWord;
  Set<String>? _dictionary;
  FavoriteContentActivity _contentActivity = FavoriteContentActivity.none;
  bool _hintMode = false;

  bool _visible = false;
  Key _visibilityDetectorKey = UniqueKey();
  DateTime? _pausedDateTime;
  FavoriteContentStatus _contentStatus = FavoriteContentStatus.none;

  final WordleKeyboardController _keyboardController = WordleKeyboardController.broadcast();
  final GlobalKey<WordleKeyboardState> _keyboardKey = GlobalKey<WordleKeyboardState>();

  @override
  void initState() {
    NotificationService().subscribe(this, [
      AppLivecycle.notifyStateChanged,
      Storage.notifySettingChanged,
      WordleGameWidget.notifyGameOver,
    ]);

    if (widget.updateController != null) {
      widget.updateController!.stream.listen((String command) {
        if (command == HomePanel.notifyRefresh) {
          _refreshDataIfVisible();
        }
      });
    }

    _loadDataIfVisible();

    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    _keyboardController.close();
    super.dispose();
  }

  @override
  void onNotification(String name, dynamic param) {
    if (name == AppLivecycle.notifyStateChanged) {
      _onAppLivecycleStateChanged(param);
    }
    else if (name == Storage.notifySettingChanged) {
      if ((param == Storage.wordleGameKey) && mounted) {
        _onWodleGameChanged();
      }
      if ((param == Storage.debugWordleDailyWordKey) && mounted) {
        _refreshDataIfVisible();
      }
    }
    else if (name == WordleGameWidget.notifyGameOver) {
      _onGameOver(JsonUtils.cast(param));
    }
  }

  @override
  Widget build(BuildContext context) =>
    HomeFavoriteWidget(favoriteId: widget.favoriteId, title: widget._title, titleBuilder: _titleBuilder, child:
      Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
        VisibilityDetector(
          key: _visibilityDetectorKey,
          onVisibilityChanged: _onVisibilityChanged,
          child:  _contentWidget,
        ),
      )
    );

  Widget get _contentWidget {
    if (_contentActivity == FavoriteContentActivity.reload) {
      return _loadingContent;
    } else if (_game == null) {
      return _errorContent;
    } else {
      return Column(mainAxisSize: MainAxisSize.min, children: [
        Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
          _wordleWidget,
        ),
        if (_game?.isFinished != true)
          Padding(padding: EdgeInsets.only(top: 8), child:
            _keyboardWidget
          ),
        _viewButton,
      ],);
    }
  }

  Widget get _wordleWidget =>
    AspectRatio(aspectRatio: _dailyWord?.asectRatio ?? 1.0, child:
      WordleWidget(
        game: _theGame,
        dailyWord: _dailyWord ?? WordleDailyWord(word: _theGame.word),
        dictionary: _dictionary,
        keyboardController: _keyboardController,
        onTap: _onTapWordle,
        autofocus: false,
        hintMode: _hintMode,
        gutterRatio: 0.0875,
      ),
    );

  Widget get _keyboardWidget =>
    WordleKeyboard(
      game: _theGame,
      key: _keyboardKey,
      autofocus: false,
      controller: _keyboardController,
    );

  Widget get _loadingContent =>
    AspectRatio(aspectRatio: 1, child:
      Center(child:
        SizedBox(width: 32, height: 32, child:
          CircularProgressIndicator(color: Styles().colors.fillColorSecondary, strokeWidth: 3,),
        ),
      )
    );

  Widget get _errorContent =>
    AspectRatio(aspectRatio: 1, child:
      Center(child:
        Text(Localization().getStringEx('panel.wordle.message.error.text', 'Failed to load daily target'), style: Styles().textStyles.getTextStyle("widget.message.regular.fat"), textAlign: TextAlign.center,)
      )
    );

  Widget get _viewButton => Center(child:
    HomeBrowseLinkButton(
      title: Localization().getStringEx('widget.home.wordle.button.view.title', 'View'),
      hint: Localization().getStringEx('widget.home.wordle.button.view.hint', 'Tap to view ILLordle game'),
      onTap: _onTapView,
    ),
  );

  Widget _titleBuilder(Widget defaultContent) =>
    GestureDetector(onLongPress: _onLongPressLogo, onDoubleTap: _onDoubleTapLogo, child: defaultContent);

  // Visibiility Detection

  void _onVisibilityChanged(VisibilityInfo info) {
    _updateInternalVisibility(!info.visibleBounds.isEmpty);
  }

  void _updateInternalVisibility(bool visible) {
    if (_visible != visible) {
      _visible = visible;
      _onInternalVisibilityChanged();
    }
  }

  void _onInternalVisibilityChanged() {
    if (_visible) {
      switch(_contentStatus) {
        case FavoriteContentStatus.none: break;
        case FavoriteContentStatus.refresh: _refreshData(); break;
        case FavoriteContentStatus.reload: _loadData(); break;
      }
    }
    else {
      FocusScope.of(context).unfocus();
    }
  }

  Future<void> _loadDataIfVisible() async {
    if (_visible) {
      return _loadData();
    }
    else if (_contentStatus.canReload) {
      _contentStatus = FavoriteContentStatus.reload;
    }
  }

  Future<void> _refreshDataIfVisible() async {
    if (_visible) {
      return _refreshData();
    }
    else if (_contentStatus.canRefresh) {
      _contentStatus = FavoriteContentStatus.refresh;
    }
  }

  // Data

  WordleGame get _theGame => _game ??= WordleGame(_dailyWord?.word ?? '');

  Future<void> _loadData() async {
    if (_contentActivity.canReload && mounted) {
      setState(() {
        _contentActivity = FavoriteContentActivity.reload;
      });

      List<dynamic> results = await Future.wait([
        WordleGameData.loadDailyWord(),
        WordleGameData.loadDictionary(),
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
          _contentActivity = FavoriteContentActivity.none;
          _contentStatus = FavoriteContentStatus.none;
        });
      }
    }
  }

  Future<void> _refreshData() async {
    if (_contentActivity.canRefresh && mounted) {
      setState(() {
        _contentActivity = FavoriteContentActivity.refresh;
      });

      WordleGame? game = WordleGame.fromStorage();
      WordleDailyWord? dailyWord = await WordleGameData.loadDailyWord();
      if ((dailyWord != null) && ((game == null) || (game.word != dailyWord.word))) {
        game = WordleGame(dailyWord.word);
      }

      if (mounted && (_contentActivity == FavoriteContentActivity.refresh)) {
        setState(() {
          if ((game != null) && (_game != game)) {
            _game = game;
          }
          if ((dailyWord != null) && (_dailyWord != dailyWord)) {
            _dailyWord = dailyWord;
          }

          _contentActivity = FavoriteContentActivity.none;
          _contentStatus = FavoriteContentStatus.none;
        });
      }
    }
  }

  // Game

  void _onAppLivecycleStateChanged(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedDateTime = DateTime.now();
    }
    else if (state == AppLifecycleState.resumed) {
      if (_pausedDateTime != null) {
        Duration pausedDuration = DateTime.now().difference(_pausedDateTime!);
        if (Config().refreshTimeout < pausedDuration.inSeconds) {
          _refreshDataIfVisible();
        }
      }
    }
  }

  void _onWodleGameChanged() {
    WordleGame? storedGame = WordleGame.fromStorage();
    if ((storedGame != null) && (storedGame != _game) && mounted) {
      setState(() {
        _game = storedGame;
      });
    }
  }

  void _onGameOver(WordleGame? game) {
    if ((game != null) && mounted) {
      setState(() {
        _game = game;
      });
    }
  }

  void _onTapWordle() {
    _keyboardKey.currentState?.toggleFocus();
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

  void _onTapView() {
    Analytics().logSelect(target: 'View', source: widget.runtimeType.toString());
    Navigator.push(context, CupertinoPageRoute(builder: (context) => WordlePanel(
      dailyWord: _dailyWord,
      dictionary: _dictionary,
    )));
  }
}