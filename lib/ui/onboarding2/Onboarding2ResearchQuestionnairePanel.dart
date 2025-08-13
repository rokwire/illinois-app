
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:illinois/model/Questionnaire.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Onboarding2.dart';
import 'package:illinois/service/Questionnaire.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:intl/intl.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/ui/widgets/triangle_painter.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class Onboarding2ResearchQuestionnairePanel extends StatefulWidget with Onboarding2Panel {
  final String onboardingCode;
  final Onboarding2Context? onboardingContext;
  final void Function()? onContinue;
  Onboarding2ResearchQuestionnairePanel({ super.key, this.onboardingCode = '', this.onboardingContext, this.onContinue });

  _Onboarding2ResearchQuestionnairePanelState? get _currentState => JsonUtils.cast(globalKey?.currentState);

  @override
  bool get onboardingProgress => (_currentState?.onboardingProgress == true);
  @override
  set onboardingProgress(bool value) => _currentState?.onboardingProgress = value;

  @override
  Future<bool> isOnboardingEnabled() async {
    if (Questionnaires().participateInResearch == true) {
      dynamic contextParam = onboardingContext?["questionanire"];
      Questionnaire? questionnaire = (contextParam is Questionnaire) ? contextParam : null;
      if (questionnaire == null) {
        onboardingContext?["questionanire"] = (questionnaire = await Questionnaires().loadResearch());
      }
      Map<String, LinkedHashSet<String>>? questionnaireAnswers = Auth2().profile?.getResearchQuestionnaireAnswers(questionnaire?.id);
      return (questionnaireAnswers?.isNotEmpty != true);
    } else {
      return false;
    }
  }

  @override
  State<StatefulWidget> createState() => _Onboarding2ResearchQuestionnairePanelState();
}

class _Onboarding2ResearchQuestionnairePanelState extends State<Onboarding2ResearchQuestionnairePanel> {

  bool _loading = false;
  bool _onboardingProgress = false;
  Questionnaire? _questionnaire;
  Map<String, LinkedHashSet<String>> _selection = <String, LinkedHashSet<String>>{};

  @override
  void initState() {
    dynamic contextParam = widget.onboardingContext?["questionanire"];
    if (contextParam is Questionnaire) {
      _questionnaire = contextParam;
      _selection.addAll(Auth2().profile?.getResearchQuestionnaireAnswers(_questionnaire?.id) ?? <String, LinkedHashSet<String>>{});
    }
    else {
      _loading = true;
      Questionnaires().loadResearch().then((Questionnaire? questionnaire) {
        if (mounted) {
          setState(() {
            _loading = false;
            _questionnaire = questionnaire;
            _selection.addAll(Auth2().profile?.getResearchQuestionnaireAnswers(questionnaire?.id) ?? <String, LinkedHashSet<String>>{});
          });
        }
      });
    }


    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(title: _questionnaire?.title ?? ''),
      backgroundColor: Styles().colors.background,
      body: SafeArea(child:
        _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return _buildLoading();
    }
    else if (_questionnaire == null) {
      return _buildError();
    }
    else {
      return _buildQuestionnaire(_questionnaire!);
    }
  }
    
  Widget _buildQuestionnaire(Questionnaire questionnaire) {

    List<Widget> contentList = <Widget>[];
    String description = questionnaire.stringValue(questionnaire.description) ?? '';
    bool submitEnabled = (_failSubmitQuestion < 0);

    if (description.isNotEmpty) {
      contentList.add(
        Container(color: Styles().colors.white, child:
          Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24), child:
            Semantics(label: description, hint: '', excludeSemantics: true, child:
              Row(children: [
                Expanded(child:
                  Text(description, style: Styles().textStyles.getTextStyle("widget.item.regular"), textAlign: TextAlign.center,),
                )
              ],)
            ),
          ),
        ),
      );
    }

    List<Widget> questions = _buildQuestions(questionnaire.questions);
    if (questions.isNotEmpty) {
      contentList.addAll(questions);
    }

    return Column(children: <Widget>[
      Expanded(child:
        SingleChildScrollView(child:
          Column(children: contentList,),
        ),
      ),
      Container(height: 1, color: Styles().colors.surfaceAccent),
      Padding(padding: EdgeInsets.only(left: _hPadding, right: _hPadding, top: 12, bottom: 12,), child:
        Row(children: [
          Expanded(child:
            RoundedButton(
              label: Localization().getStringEx('panel.onboarding2.research.questionnaire.button.cancel.title', 'Cancel'),
              hint: Localization().getStringEx('panel.onboarding2.research.questionnaire.button.cancel.hint', ''),
              textStyle: Styles().textStyles.getTextStyle("widget.button.title.medium"),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              borderColor: Styles().colors.fillColorPrimary,
              backgroundColor: Styles().colors.white,
              onTap: () => _onCancel(),
            ),
          ),
          Container(width: 12,),
          Expanded(child:
            RoundedButton(
              label: Localization().getStringEx('panel.onboarding2.research.questionnaire.button.submit.title', 'Submit'),
              hint: Localization().getStringEx('panel.onboarding2.research.questionnaire.button.submit.hint', ''),
              textStyle: submitEnabled ? Styles().textStyles.getTextStyle("widget.button.title.enabled") : Styles().textStyles.getTextStyle("widget.button.title.disabled"),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              borderColor: submitEnabled ? Styles().colors.fillColorSecondary : Styles().colors.surfaceAccent,
              backgroundColor: Styles().colors.white,
              onTap: () => _onSubmit(),
            ),
          ),
        ],),
      ),
    ]);
  }

  List<Widget> _buildQuestions(List<Question>? questions) {
    List<Widget> questionsList = <Widget>[];
    if (questions != null) {
      for (int index = 0; index < questions.length; index++) {
        questionsList.add(_buildQuestion(questions[index], index: index + 1));
      }
    }
    return questionsList;
  }

  Widget _buildQuestion(Question question, { int? index }) {
    List<Widget> contentList = <Widget>[];

    String title = _displayQuestionTitle(question, index: index);
    if (title.isNotEmpty) {
      contentList.add(Padding(padding: EdgeInsets.symmetric(horizontal: _hPadding, vertical: _hPadding), child:
        Row(children: [
          Expanded(child:
            Text(title, style: Styles().textStyles.getTextStyle("widget.title.large.fat"), textAlign: TextAlign.left,),
          )
        ])      
      ));
    }

    String descriptionPrefix = _questionnaireString(question.descriptionPrefix);
    if (descriptionPrefix.isNotEmpty) {
      contentList.add(Padding(padding: EdgeInsets.only(left: _hPadding, right: _hPadding, top: 2), child:
        Row(children: [
          Expanded(child:
            Text(descriptionPrefix, style: Styles().textStyles.getTextStyle("widget.item.regular.thin"), textAlign: TextAlign.left,),
          )
        ])
      ));
    }

    List<Widget> answers = _buildAnswers(question);
    if (answers.isNotEmpty) {
      contentList.add(Padding(padding: EdgeInsets.only(top: 0), child:
        Column(children: answers,),
      ));
    }

    String descriptionSuffix = _questionnaireString(question.descriptionSuffix);
    if (descriptionSuffix.isNotEmpty) {
      contentList.add(Padding(padding: EdgeInsets.only(left: _hPadding, right: _hPadding, bottom: 16), child:
        Row(children: [
          Expanded(child:
            Text(descriptionSuffix, style: Styles().textStyles.getTextStyle("widget.item.regular.thin"), textAlign: TextAlign.left,),
          )
        ])
      ));
    }
    else {
      contentList.add(Padding(padding: EdgeInsets.only(bottom: 16), child:
        Container()
      ));
    }

    return Stack(children: [
      Column(children: [
        Column(children: [
          Container(color: Styles().colors.backgroundVariant, height: 100,),
          CustomPaint(painter: TrianglePainter(painterColor: Styles().colors.backgroundVariant, vertDir: TriangleVertDirection.bottomToTop, horzDir: TriangleHorzDirection.leftToRight), child:
            Container(height: 40,),
          ),
          Container(height: 10,),
        ],),
      ],),
      Column(children: contentList,),
    ],
    );
  }

  List<Widget> _buildAnswers(Question question) {
    switch (question.type) {
      case QuestionType.dateOfBirth: return _buildDateOfBirthAnswers(question);
      case QuestionType.schoolYear: return _buildSchoolYearAnswers(question);
      default: return _buildCheckListAnswers(question);
    }
  }

  // Check List

  List<Widget> _buildCheckListAnswers(Question question) {
    List<Widget> answersList = <Widget>[];
    List<Answer>? answers = question.answers;
    if (answers != null) {
      for (Answer answer in answers) {
        answersList.add(Padding(padding: EdgeInsets.only(top: answersList.isNotEmpty ? 5 : 0), child:
          _buildCheckListAnswer(answer, question: question)
        ));
      }
    }
    return answersList;
  }

  Widget _buildCheckListAnswer(Answer answer, { required Question question }) {
    LinkedHashSet<String>? selectedAnswers = _selection[question.id];
    bool selected = selectedAnswers?.contains(answer.id) ?? false;
    String title = _questionnaireString(answer.title);
    String imageAsset = (question.maxAnswers == 1) ?
      (selected ? "radio-button-on" : "radio-button-off") :
      (selected ? "check-box-filled" : "box-outline-gray");
    return
      Semantics(
        label: title, button: true,
        value: selected ?  Localization().getStringEx("toggle_button.status.checked", "checked",) : Localization().getStringEx("toggle_button.status.unchecked", "unchecked"),
        child: Padding(padding: _controlMargin, child:
        InkWell(onTap: () => _onCheckListAnswer(answer, question: question), child:
          Container(decoration: _controlDecoration(selected: selected), padding: _controlPadding, child:
            Row(children: [
              Padding(padding: EdgeInsets.only(right: 12), child:
                Styles().images.getImage(imageAsset, excludeFromSemantics: true),
              ),
              Expanded(child:
                Text(title, style: Styles().textStyles.getTextStyle("widget.detail.regular"), textAlign: TextAlign.left, semanticsLabel: "",)
              ),
            ]),
          ),
       ),
      )
    );
  }

  void _onCheckListAnswer(Answer answer, { required Question question }) {

    //String answerTitle = _questionnaireString(answer.title, languageCode: 'en');
    //String? questionTitle = _questionnaireString(question.title, languageCode: 'en');
    //Analytics().logSelect(target: '$questionTitle => $answerTitle');

    String? answerId = answer.id;
    String? questionId = question.id;
    if ((questionId != null) && (answerId != null)) {
      LinkedHashSet<String> selectedAnswers = _selection[questionId] ?? (_selection[questionId] = LinkedHashSet<String>());
      setState(() {
        if (selectedAnswers.contains(answerId)) {
          selectedAnswers.remove(answerId);
        }
        else {
          selectedAnswers.add(answerId);
        }

        if (question.maxAnswers != null) {
          while (question.maxAnswers! < selectedAnswers.length) {
            selectedAnswers.remove(selectedAnswers.first);
          }
        }
      });
      AppSemantics.announceCheckBoxStateChange(context, selectedAnswers.contains(answer.id) != true, _questionnaireString(answer.title));
    }
  }

  // Date Of Birth

  List<Widget> _buildDateOfBirthAnswers(Question question) => <Widget>[
    _buildDateOfBirthAnswer(question)
  ];

  Widget _buildDateOfBirthAnswer(Question question) {
    LinkedHashSet<String>? selectedAnswers = _selection[question.id];
    String? selectedAnswer = (selectedAnswers?.isNotEmpty == true) ? selectedAnswers?.first : null;
    DateTime? selectedDate = DateOfBirthQuestion.fromDOBString(selectedAnswer);
    String? label = (selectedDate != null) ? DateFormat('MM-dd-yyyy').format(selectedDate) : null;

    return Padding(padding: _controlMargin, child:
      InkWell(onTap: () => _onDateOfBirthAnswer(question), child:
        Container(decoration: _controlDecoration(selected: (selectedDate != null)), padding: _controlPadding, child:
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: <Widget>[
            Text(label ??  '-', style: Styles().textStyles.getTextStyle('widget.title.regular'),),
            Styles().images.getImage('chevron-down') ?? Container()
          ],),
        ),
      )
    );
  }

  void _onDateOfBirthAnswer(Question question) {
    LinkedHashSet<String>? selectedAnswers = _selection[question.id];
    String? selectedAnswer = (selectedAnswers?.isNotEmpty == true) ? selectedAnswers?.first : null;
    DateTime? selectedDate = DateOfBirthQuestion.fromDOBString(selectedAnswer);
    DateTime now = DateUtils.dateOnly(DateTime.now());

    showDatePicker(context: context,
      initialDate: selectedDate,
      initialDatePickerMode: DatePickerMode.year,
      initialEntryMode: DatePickerEntryMode.calendar,
      firstDate: DateOfBirthQuestion.dobOrgDate,
      lastDate: now,
      builder: (context, child) => _datePickerTransitionBuilder(context, child!),
    ).then((DateTime? result) => _didDateOfBirthAnswer(question, result));
  }

  void _didDateOfBirthAnswer(Question question, DateTime? value) {
    String? questionId = question.id;
    if (questionId != null) {
      if (value != null) {
        setState(() {
          _selection[questionId] = LinkedHashSet<String>.from(<String>[
            DateOfBirthQuestion.toDOBString(value)
          ]);
        });
      }
      // On Cancel value is null
      /*else {
        setState(() {
          _selection.remove(questionId);
        });
      }*/
    }
  }

  Widget _datePickerTransitionBuilder(BuildContext context, Widget child) => Theme(
    data: Theme.of(context).copyWith(datePickerTheme: DatePickerThemeData(backgroundColor: Styles().colors.white)),
    child: child
  );

  // Check List

  List<Widget> _buildSchoolYearAnswers(Question question) {
    List<Widget> answersList = <Widget>[];
    List<Answer>? answers = question.answers;
    if (answers != null) {
      for (Answer answer in answers) {
        answersList.add(Padding(padding: EdgeInsets.only(top: answersList.isNotEmpty ? 5 : 0), child:
          _buildSchoolYearAnswer(answer, question: question)
        ));
      }
    }
    return answersList;
  }

  Widget _buildSchoolYearAnswer(Answer answer, { required Question question }) {
    LinkedHashSet<String>? selectedAnswers = _selection[question.id];

    bool selected = false;
    if (answer.interval != null) {
      selected = (answer.interval?.matchSchoolYearSelection(selectedAnswers) != null);
    }
    else {
      selected = (selectedAnswers?.contains(answer.id) == true);
    }

    String title = _questionnaireString(answer.title);
    String imageAsset = (question.maxAnswers == 1) ?
      (selected ? "radio-button-on" : "radio-button-off") :
      (selected ? "check-box-filled" : "box-outline-gray");
    return
      Semantics(
        label: title, button: true,
        value: selected ?  Localization().getStringEx("toggle_button.status.checked", "checked",) : Localization().getStringEx("toggle_button.status.unchecked", "unchecked"),
        child: Padding(padding: _controlMargin, child:
        InkWell(onTap: () => _onSchoolYearAnswer(answer, question: question), child:
          Container(decoration: _controlDecoration(selected: selected), padding: _controlPadding, child:
            Row(children: [
              Padding(padding: EdgeInsets.only(right: 12), child:
                Styles().images.getImage(imageAsset, excludeFromSemantics: true),
              ),
              Expanded(child:
                Text(title, style: Styles().textStyles.getTextStyle("widget.detail.regular"), textAlign: TextAlign.left, semanticsLabel: "",)
              ),
            ]),
          ),
       ),
      )
    );
  }

  void _onSchoolYearAnswer(Answer answer, { required Question question }) {

    //String answerTitle = _questionnaireString(answer.title, languageCode: 'en');
    //String? questionTitle = _questionnaireString(question.title, languageCode: 'en');
    //Analytics().logSelect(target: '$questionTitle => $answerTitle');

    String? questionId = question.id;
    if (questionId != null) {
      LinkedHashSet<String> selectedAnswers = _selection[questionId] ??= LinkedHashSet<String>();
      setState(() {
        if (answer.interval != null) {
          String? selectedAnswer = answer.interval?.matchSchoolYearSelection(selectedAnswers);
          if (selectedAnswers.contains(selectedAnswer)) {
            selectedAnswers.remove(selectedAnswer);
          }
          else {
            selectedAnswer = answer.interval?.schoolYearValue;
            if (selectedAnswer != null) {
              selectedAnswers.add(selectedAnswer);
            }
          }
        }
        else {
          String? answerId = answer.id;
          if (selectedAnswers.contains(answerId)) {
            selectedAnswers.remove(answerId);
          }
          else if (answerId != null) {
            selectedAnswers.add(answerId);
          }
        }

        if (question.maxAnswers != null) {
          while (question.maxAnswers! < selectedAnswers.length) {
            selectedAnswers.remove(selectedAnswers.first);
          }
        }

      });

      AppSemantics.announceCheckBoxStateChange(context, selectedAnswers.contains(answer.id) != true, _questionnaireString(answer.title));
    }
  }

  // Shared UI

  EdgeInsetsGeometry get _controlMargin => EdgeInsets.symmetric(horizontal: _hPadding);
  EdgeInsetsGeometry get _controlPadding => EdgeInsets.symmetric(horizontal: _hPadding, vertical: _vPadding);
  static const double _hPadding = 24;
  static const double _vPadding = 16;

  BoxDecoration _controlDecoration({bool selected = false}) => selected ? _selectedControlDecoration : _regularControlDecoration;

  BoxDecoration get _regularControlDecoration => BoxDecoration(color: _controlDecorationColor, border: _regularControlBorder);
  BoxBorder get _regularControlBorder => Border.all(color: _regularControlBorderColor, width: _controlBorderWidth);
  Color get _regularControlBorderColor => Styles().colors.surfaceAccent;

  BoxDecoration get _selectedControlDecoration => BoxDecoration(color: _controlDecorationColor, border: _selectedControlBorder);
  BoxBorder get _selectedControlBorder => Border.all(color: _selectedControlBorderColor, width: _controlBorderWidth);
  Color get _selectedControlBorderColor => Styles().colors.fillColorPrimary;

  Color get _controlDecorationColor => Styles().colors.surface;
  static const double _controlBorderWidth = 1.0;


  // General Flow

  void _onCancel() {
    Analytics().logSelect(target: "Cancel");
    Navigator.pop(context);
  }

  void _onSubmit() {

    Analytics().logSelect(target: 'Submit');

    List<Question>? questions = _questionnaire?.questions;
    if (questions != null) {
      int index = this._failSubmitQuestion;
      Question? failQuestion = ((0 <= index) && (index < questions.length)) ? questions[index] : null;
      if (failQuestion != null) {
        AppAlert.showDialogResult(context, _failSubmitPrompt(failQuestion, index: index));
      }
      else {
        Analytics().logResearchQuestionnaiire(answers: _analyticsAnswers);
        Auth2().profile?.setResearchQuestionnaireAnswers(_questionnaire?.id, _selection);
        _onboardingNext();
        
      }
    }
  }

  int get _failSubmitQuestion {
    List<Question>? questions = _questionnaire?.questions;
    if (questions != null) {
      for (int index = 0; index < questions.length; index++) {
        Question question = questions[index];
        int? minQuestionAnswers = question.minAnswers;
        if (minQuestionAnswers != null) {
          LinkedHashSet<String>? selectedAnswers = _selection[question.id];
          int selectedAnswersCount = selectedAnswers?.length ?? 0;
          if (selectedAnswersCount < minQuestionAnswers) {
            return index;
          }
        }
      }
    }
    return -1;
  }

  String _failSubmitPrompt(Question question, { int? index }) {
    final String titleMacro = "{{QuestionTitle}}";
    final String minAnswersMacro = "{{MinQuestionAnswers}}";
    int minQuestionAnswers = question.minAnswers ?? 0;
    String questionTitle = _displayQuestionTitle(question, index: (index != null) ? (index + 1) : null);
    String promptFormat;
    if (question.type == QuestionType.dateOfBirth) {
      promptFormat = Localization().getStringEx('panel.onboarding2.research.questionnaire.error.enter.value', 'Please enter a value for "$titleMacro".');
    }
    else {
      promptFormat = (1 < minQuestionAnswers) ?
        Localization().getStringEx('panel.onboarding2.research.questionnaire.error.select.multi', 'Please choose at least $minAnswersMacro aswers of "$titleMacro".') :
        Localization().getStringEx('panel.onboarding2.research.questionnaire.error.select.single', 'Please choose at least $minAnswersMacro aswer of "$titleMacro".');
    }
    return promptFormat.
      replaceAll(minAnswersMacro, '$minQuestionAnswers').
      replaceAll(titleMacro, '$questionTitle');
  }

  List<dynamic>? get _analyticsAnswers {
    List<dynamic>? answers;
    List<Question>? questions = _questionnaire?.questions;
    if (questions != null) {
      answers = [];
      for (int index = 0; index < questions.length; index++) {
        Question question = questions[index];
        answers.add({ (question.title ?? '') : _isAnalyticsQuestionAnswered(question) });
      }
    }
    return answers;
  }

  bool _isAnalyticsQuestionAnswered(Question question) {
    LinkedHashSet<String>? selectedAnswers = _selection[question.id];
    if (selectedAnswers != null) {
      for (String answerId in selectedAnswers) {
        Answer? answer = Answer.answerInList(question.answers, answerId: answerId);
        if ((answer != null) && !answer.isAnalyticsSkipAnswer) {
          return true;
        }
      }
    }
    return false;
  }

  String _questionnaireString(String? key, { String? languageCode }) => _questionnaire?.stringValue(key, languageCode: languageCode) ?? key ?? '';

  String _displayQuestionTitle(Question question, { int? index, String? languageCode }) {
    String title = _questionnaireString(question.title, languageCode: languageCode);
    return ((index != null) && title.isNotEmpty) ? "$index. $title" : title;
  }

  Widget _buildLoading() {
    return Row(children: [
      Expanded(child:
        Column(children: [
          Expanded(child:
            Align(alignment: Alignment.center, child:
              CircularProgressIndicator(color: Styles().colors.fillColorSecondary, strokeWidth: 3, )
            ),
          ),
        ],))
    ]);
  }

  Widget _buildError() {
    return Row(children: [
      Expanded(child:
        Column(children: [
          Expanded(child:
            Align(alignment: Alignment.center, child:
              Padding(padding: EdgeInsets.only(left: 32, right: 32, top: 24, bottom: 24), child:
                Row(children: [
                  Expanded(child:
                    Text(Localization().getStringEx('panel.onboarding2.research.questionnaire.error.load', 'Failed to load research questionnaire.'), style:
              Styles().textStyles.getTextStyle("widget.message.large"), textAlign: TextAlign.center,),
                  ),
                ],)
              )
            ),
          ),
        ],))
    ]);
  }

  // Onboarding

  bool get onboardingProgress => _onboardingProgress;
  set onboardingProgress(bool value) {
    setStateIfMounted(() {
      _onboardingProgress = value;
    });
  }

  //void _onboardingBack() => Navigator.of(context).pop();
  void _onboardingNext() {
    if (widget.onContinue != null) {
      widget.onContinue?.call();
    } else {
      Onboarding2().next(context, widget);
    }
  }
}