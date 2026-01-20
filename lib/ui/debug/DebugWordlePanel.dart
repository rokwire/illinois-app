
import 'package:flutter/material.dart';
import 'package:illinois/model/Wordle.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/service/Wordle.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class DebugWordlePanel extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _DebugWordlePanelState();
}

class _DebugWordlePanelState extends State<DebugWordlePanel>  {

  late bool _debugIgnoreDictionary;
  late bool _debugUseDailtyWord;
  WordleDailyWord? _debugDailtyWord;
  bool _loadingDailtyWord = false;
  bool _isDateValid = true;

  TextEditingController _wordController = TextEditingController();
  TextEditingController _dateController = TextEditingController();
  TextEditingController _authorController = TextEditingController();
  TextEditingController _storyTexyController = TextEditingController();
  TextEditingController _storyUrlController = TextEditingController();

  @override
  void initState() {
    _debugIgnoreDictionary = Storage().debugWordleIgnoreDictionary == true;
    _debugDailtyWord = WordleDailyWord.fromJson(JsonUtils.decodeMap(Storage().debugWordleDailyWord));
    _debugUseDailtyWord = (_debugDailtyWord != null);

    _applyDailyWord(_debugDailtyWord);


    super.initState();
  }

  @override
  void dispose() {
    _wordController.dispose();
    _dateController.dispose();
    _authorController.dispose();
    _storyTexyController.dispose();
    _storyUrlController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: HeaderBar(
      title: 'Debug ILLordle',
      actions: _canSave ? [ _saveButton ] : null,
    ),
    backgroundColor: Styles().colors.surface,
    body: SingleChildScrollView(child:
      _scaffoldContent
    ),
  );

  Widget get _scaffoldContent =>
    Padding(padding: EdgeInsets.symmetric(vertical: 24), child:
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Container(height: 1, color: Styles().colors.surfaceAccent ,),),
        ToggleRibbonButton(title: "Ignore Words Dictionary", toggled: _debugIgnoreDictionary, onTap: _onIgnoreDictionary),
        Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Container(height: 1, color: Styles().colors.surfaceAccent ,),),
        ToggleRibbonButton(title: "Use This Today's Word", toggled: _debugUseDailtyWord, onTap: _onUseDailtyWord),
        Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Container(height: 1, color: Styles().colors.surfaceAccent ,),),
        if (_debugUseDailtyWord)
          Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16), child:
            _dailtyWord
          )
      ])
    );

  Widget get _dailtyWord =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      Text('Word:', style: _captionTextStyle,),
      TextField(controller: _wordController, keyboardType: TextInputType.text, decoration: _textFieldDecoration, style: _textFieldStyle, textCapitalization: TextCapitalization.characters, onChanged: _onChangedWord,),
      Container(height: 8,),
      Text('Date:', style: _captionTextStyle,),
      TextField(controller: _dateController, keyboardType: TextInputType.text, decoration: _textFieldDecoration, style: _isDateValid ? _textFieldStyle : _textFieldInvalidStyle, onChanged: _onChangedDate),
      Container(height: 8,),
      Text('Author:', style: _captionTextStyle,),
      TextField(controller: _authorController, keyboardType: TextInputType.text, decoration: _textFieldDecoration, style: _textFieldStyle,),
      Container(height: 8,),
      Text('Story Text:', style: _captionTextStyle,),
      TextField(controller: _storyTexyController, keyboardType: TextInputType.text, decoration: _textFieldDecoration, style: _textFieldStyle,),
      Container(height: 8,),
      Text('Story Url:', style: _captionTextStyle,),
      TextField(controller: _storyUrlController, keyboardType: TextInputType.url, decoration: _textFieldDecoration, style: _textFieldStyle,),
      Container(height: 16,),
      Row(children: [
        Expanded(flex: 1, child: Container()),
        Expanded(flex: 4, child:
          RoundedButton(
            label: "Load Today's Word",
            //padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            progress: _loadingDailtyWord,
            //progressSize: 16,
            onTap: _onLoadTodaysWord,
          )
        ),
        Expanded(flex: 1, child: Container()),
      ],)
    ]);

  TextStyle? get _captionTextStyle =>
    Styles().textStyles.getTextStyle('widget.detail.regular.fat');

  TextStyle? get _textFieldStyle =>
    Styles().textStyles.getTextStyle('widget.detail.regular');

  TextStyle? get _textFieldInvalidStyle =>
    Styles().textStyles.getTextStyleEx('widget.detail.regular', color: Colors.red);

  InputDecoration get _textFieldDecoration => InputDecoration(
    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    border: OutlineInputBorder(
      borderSide: BorderSide(color: Styles().colors.surfaceAccent, width: 1)
    )
  );

  void _onIgnoreDictionary() {
    setState(() {
      _debugIgnoreDictionary = !_debugIgnoreDictionary;
    });
  }

  void _onUseDailtyWord() {
    setState(() {
      _debugUseDailtyWord = !_debugUseDailtyWord;
    });
  }

  void _onLoadTodaysWord() async {
    if (_loadingDailtyWord != true) {
      setState(() {
        _loadingDailtyWord = true;
      });
      WordleDailyWord? todaysWord = await WordleGameData.loadDailyWordFromNet();
      if (mounted) {
        setState(() {
          _loadingDailtyWord = false;
        });
        if (todaysWord != null) {
          _applyDailyWord(todaysWord);
        }
        else {
          AppAlert.showTextMessage(context, "Failed to load today's word.");
        }
      }

    }
  }

  void _applyDailyWord(WordleDailyWord? word) {
    _wordController.text = word?.word ?? '';
    _dateController.text = word?.dateUniAsString ?? '';
    _authorController.text = word?.author ?? '';
    _storyTexyController.text = word?.storyTitle ?? '';
    _storyUrlController.text = word?.storyUrl ?? '';
    setState(() {
      _isDateValid = (WordleDailyWord.dateUniFromString(_dateController.text) != null);
    });
  }

  WordleDailyWord? get _appliedDailyWord => _wordController.text.isNotEmpty ? WordleDailyWord(
    word: _wordController.text,
    dateUni: WordleDailyWord.dateUniFromString(_dateController.text),
    author: StringUtils.ensureEmpty(_authorController.text),
    storyTitle: StringUtils.ensureEmpty(_storyTexyController.text),
    storyUrl: StringUtils.ensureEmpty(_storyUrlController.text),
  ) : null;

  void _onChangedWord(String value) {
    setState(() {
    });
  }

  void _onChangedDate(String value) {
    setState(() {
      _isDateValid = (WordleDailyWord.dateUniFromString(_dateController.text) != null);
    });
  }

  Widget get _saveButton =>
    InkWell(onTap: _onTapSave, child:
    Align(alignment: Alignment.center, child:
      Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12), child:
        Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Styles().colors.white, width: 1.5, ))),
            child: Text('Save',
              style: Styles().textStyles.getTextStyle("widget.heading.regular.fat")
            ),
          ),
        ],)
      ),
    ),
  );

  void _onTapSave() {
    Storage().debugWordleIgnoreDictionary = _debugIgnoreDictionary ? true : null;
    Storage().debugWordleDailyWord = _debugUseDailtyWord ? JsonUtils.encode(_appliedDailyWord?.toJson()) : null;
    Navigator.pop(context);
  }

  bool get _canSave {
    bool debugIgnoreDictionary = (Storage().debugWordleIgnoreDictionary == true);

    WordleDailyWord? debugDailtyWord = WordleDailyWord.fromJson(JsonUtils.decodeMap(Storage().debugWordleDailyWord));
    bool debugUseDailtyWord = (debugDailtyWord != null);

    return (debugIgnoreDictionary != _debugIgnoreDictionary) ||
      (_debugUseDailtyWord != debugUseDailtyWord) ||
      (_debugUseDailtyWord && (_debugDailtyWord != _appliedDailyWord) && _isDateValid);
  }
}
