
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:illinois/model/Questionnaire.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Questionnaire.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/ui/widgets/triangle_painter.dart';

class Onboarding2ResearchQuestionnairePanel extends StatefulWidget {

  final Map<String, dynamic>? onboardingContext;
  Onboarding2ResearchQuestionnairePanel({this.onboardingContext});

  @override
  State<Onboarding2ResearchQuestionnairePanel> createState() =>
    _Onboarding2ResearchQuestionnairePanelState();
}

class _Onboarding2ResearchQuestionnairePanelState extends State<Onboarding2ResearchQuestionnairePanel> {

  bool _loading = false;
  Questionnaire? _questionnaire;
  Map<String, LinkedHashSet<String>> _selection = <String, LinkedHashSet<String>>{};

  final double _hPadding = 24;

  @override
  void initState() {
    dynamic questionnaire = (widget.onboardingContext != null) ? widget.onboardingContext!['questionanire'] : null;
    if (questionnaire is Questionnaire) {
      _questionnaire = questionnaire;
      _selection.addAll(Auth2().profile?.getResearchQuestionnaireAnswers(questionnaire.id) ?? <String, LinkedHashSet<String>>{});
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
      backgroundColor: Styles().colors?.background,
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
        Container(color: Styles().colors?.white, child:
          Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24), child:
            Semantics(label: description, hint: '', excludeSemantics: true, child:
              Row(children: [
                Expanded(child:
                  Text(description, style: Styles().textStyles?.getTextStyle("widget.item.regular"), textAlign: TextAlign.center,),
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
      Container(height: 1, color: Styles().colors!.surfaceAccent),
      Padding(padding: EdgeInsets.only(left: _hPadding, right: _hPadding, top: 12, bottom: 12,), child:
        Row(children: [
          Expanded(child:
            RoundedButton(
              label: Localization().getStringEx('panel.onboarding2.research.questionnaire.button.cancel.title', 'Cancel'),
              hint: Localization().getStringEx('panel.onboarding2.research.questionnaire.button.cancel.hint', ''),
              textStyle: Styles().textStyles?.getTextStyle("widget.button.title.medium"),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              borderColor: Styles().colors?.fillColorPrimary,
              backgroundColor: Styles().colors!.white,
              onTap: () => _onCancel(),
            ),
          ),
          Container(width: 12,),
          Expanded(child:
            RoundedButton(
              label: Localization().getStringEx('panel.onboarding2.research.questionnaire.button.submit.title', 'Submit'),
              hint: Localization().getStringEx('panel.onboarding2.research.questionnaire.button.submit.hint', ''),
              textStyle: submitEnabled ? Styles().textStyles?.getTextStyle("widget.button.title.enabled") : Styles().textStyles?.getTextStyle("widget.button.title.disabled"),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              borderColor: submitEnabled ? Styles().colors?.fillColorSecondary : Styles().colors?.surfaceAccent,
              backgroundColor: Styles().colors!.white,
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
            Text(title, style: Styles().textStyles?.getTextStyle("widget.title.large.fat"), textAlign: TextAlign.left,),
          )
        ])      
      ));
    }

    String descriptionPrefix = _questionnaireString(question.descriptionPrefix);
    if (descriptionPrefix.isNotEmpty) {
      contentList.add(Padding(padding: EdgeInsets.only(left: _hPadding, right: _hPadding, top: 2), child:
        Row(children: [
          Expanded(child:
            Text(descriptionPrefix, style: Styles().textStyles?.getTextStyle("widget.item.regular.thin"), textAlign: TextAlign.left,),
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
            Text(descriptionSuffix, style: Styles().textStyles?.getTextStyle("widget.item.regular.thin"), textAlign: TextAlign.left,),
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
          Container(color: Styles().colors?.backgroundVariant, height: 100,),
          CustomPaint(painter: TrianglePainter(painterColor: Styles().colors?.backgroundVariant, vertDir: TriangleVertDirection.bottomToTop, horzDir: TriangleHorzDirection.leftToRight), child:
            Container(height: 40,),
          ),
        ],),
      ],),
      Column(children: contentList,),
    ],
    );
  }

  List<Widget> _buildAnswers(Question question) {
    List<Widget> answersList = <Widget>[];
    List<Answer>? answers = question.answers;
    if (answers != null) {
      for (Answer answer in answers) {
        answersList.add(Padding(padding: EdgeInsets.only(top: answersList.isNotEmpty ? 5 : 0), child:_buildAnswer(answer, question: question)));
      }
    }
    return answersList;
  }

  Widget _buildAnswer(Answer answer, { required Question question }) {
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
        child: InkWell(onTap: () { _onAnswer(answer, question: question); AppSemantics.announceCheckBoxStateChange(context, !selected, title);}, child:
      Padding(padding: EdgeInsets.symmetric(horizontal: _hPadding), child:
        Container(decoration: BoxDecoration(color: Styles().colors?.white, border: Border.all(color: selected ? Styles().colors!.fillColorPrimary! : Styles().colors!.white!, width: 1)), child:
          Padding(padding: EdgeInsets.symmetric(horizontal: _hPadding, vertical: _hPadding / 2), child:
            Row(children: [
              Padding(padding: EdgeInsets.only(right: 12), child:
                Styles().images?.getImage(imageAsset, excludeFromSemantics: true),
              ),
              Expanded(child:
                Padding(padding: EdgeInsets.only(top: 8, bottom: 8,), child:
                  Text(title, style: Styles().textStyles?.getTextStyle("widget.detail.regular"), textAlign: TextAlign.left, semanticsLabel: "",)
                ),
              ),
            ]),
          ),
        ),
      ),
    ));
  }

  void _onAnswer(Answer answer, { required Question question }) {

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
    }
  }

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
        int minQuestionAnswers = failQuestion.minAnswers ?? 0;
        String questionTitle = _displayQuestionTitle(failQuestion, index: index + 1);
        String promptFormat = (1 < minQuestionAnswers) ?
          Localization().getStringEx('panel.onboarding2.research.questionnaire.error.select.multi', 'Please choose at least {{MinQuestionAnswers}} aswers of "{{QuestionTitle}}".') :
          Localization().getStringEx('panel.onboarding2.research.questionnaire.error.select.single', 'Please choose at least {{MinQuestionAnswers}} aswer of "{{QuestionTitle}}".');
        String displayPrompt = promptFormat.
          replaceAll('{{MinQuestionAnswers}}', '$minQuestionAnswers').
          replaceAll('{{QuestionTitle}}', '$questionTitle');

        AppAlert.showDialogResult(context, displayPrompt);
      }
      else {
        Analytics().logResearchQuestionnaiire(answers: _analyticsAnswers);

        Auth2().profile?.setResearchQuestionnaireAnswers(_questionnaire?.id, _selection);
        
        Function? onContinue = (widget.onboardingContext != null) ? widget.onboardingContext!["onContinueAction"] : null;
        if (onContinue != null) {
          onContinue();
        }
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
              CircularProgressIndicator(color: Styles().colors?.fillColorSecondary, strokeWidth: 3, )
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
              Styles().textStyles?.getTextStyle("widget.message.large"), textAlign: TextAlign.center,),
                  ),
                ],)
              )
            ),
          ),
        ],))
    ]);
  }

}