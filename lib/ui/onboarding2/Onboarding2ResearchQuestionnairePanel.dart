
import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:illinois/model/Questionnaire.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Questionnaire.dart';
import 'package:illinois/ui/onboarding/OnboardingBackButton.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';

class Onboarding2ResearchQuestionnairePanel extends StatefulWidget {

  final Map<String, dynamic>? onboardingContext;
  Onboarding2ResearchQuestionnairePanel({this.onboardingContext});

  @override
  State<Onboarding2ResearchQuestionnairePanel> createState() =>
    _Onboarding2ResearchQuestionnairePanelState();

  static Future<bool?> prompt(BuildContext context) async {
    String promptEn = 'Do you want to participate in Research Questionnaire?';
    return await AppAlert.showCustomDialog(context: context,
      contentWidget:
        Text(Localization().getStringEx('panel.onboarding2.research.questionnaire.prompt', promptEn),
          style: TextStyle(fontFamily: Styles().fontFamilies?.regular, fontSize: 16, color: Styles().colors?.fillColorPrimary,),
        ),
      actions: [
        TextButton(
          child: Text(Localization().getStringEx('dialog.yex.title', 'Yes')),
          onPressed: () { Analytics().logAlert(text: promptEn, selection: 'Yes'); Navigator.of(context).pop(true); }
        ),
        TextButton(
          child: Text(Localization().getStringEx('dialog.no.title', 'No')),
          onPressed: () { Analytics().logAlert(text: promptEn, selection: 'No'); Navigator.of(context).pop(false); }
        )
      ]);
  }
}

class _Onboarding2ResearchQuestionnairePanelState extends State<Onboarding2ResearchQuestionnairePanel> {

  bool _loading = false;
  Questionnaire? _questionnaire;
  Map<String, LinkedHashSet<String>> _selection = <String, LinkedHashSet<String>>{};

  final double _hPadding = 24;

  @override
  void initState() {
    _loading = true;

    Questionnaires().loadDemographic().then((Questionnaire? questionnaire) {
      if (mounted) {
        setState(() {
          _loading = false;
          _questionnaire = questionnaire;
          Map<String, LinkedHashSet<String>>? answers = Auth2().prefs?.getQuestionnaireAnswers(questionnaire?.id);
          if (answers != null) {
            _selection.addAll(answers);
          }
        });
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Styles().colors?.background,
      body: SafeArea(child:
        Stack(children: [
          OnboardingBackButton(padding: const EdgeInsets.only(left: 10, top: 30, right: 20, bottom: 20), onTap: () {
            Analytics().logSelect(target: "Back");
            Navigator.pop(context);
          }),
          _buildContent(),
        ],)
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
    String title = questionnaire.stringValue(questionnaire.title)  ?? '';
    String description = questionnaire.stringValue(questionnaire.description) ?? '';
    bool submitEnabled = (_failSubmitQuestion < 0);

    if (description.isNotEmpty) {
      contentList.add(Padding(padding: EdgeInsets.only(left: _hPadding, right: _hPadding, bottom: 20), child:
        Semantics(label: description, hint: '', excludeSemantics: true, child:
          Row(children: [
            Expanded(child:
              Text(description, style: TextStyle(fontFamily: Styles().fontFamilies?.medium, fontSize: 16, color: Styles().colors?.textBackground), textAlign: TextAlign.left,),
            )
          ],)
        ),
      ),);
    }

    List<Widget> questions = _buildQuestions(questionnaire.questions);
    if (questions.isNotEmpty) {
      contentList.addAll(questions);
    }

    return Padding(padding: EdgeInsets.only(top: 20), child:
      Column(children: <Widget>[
        Padding(padding: EdgeInsets.only(left: 48, right: 48, bottom: 12), child:
          Semantics(label: title, hint: '', excludeSemantics: true, child:
            Row(children: [
              Expanded(child:
                Text(title, style: TextStyle(fontFamily: Styles().fontFamilies?.extraBold, fontSize: 24, color: Styles().colors?.fillColorPrimary), textAlign: TextAlign.center,),
              )
            ],)
          ),
        ),
        Expanded(child:
          SingleChildScrollView(child:
            Column(children: contentList,),
          ),
        ),
        Padding(padding: EdgeInsets.only(left: _hPadding, right: _hPadding, top: 12, bottom: 12,), child:
          RoundedButton(
            label: Localization().getStringEx('panel.onboarding2.research.questionnaire.button.submit.title', 'Submit'),
            hint: Localization().getStringEx('panel.onboarding2.research.questionnaire.button.submit.hint', ''),
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            borderColor: submitEnabled ? Styles().colors?.fillColorSecondary : Styles().colors?.surfaceAccent,
            backgroundColor: Styles().colors!.white,
            textColor: submitEnabled ? Styles().colors?.fillColorPrimary : Styles().colors?.surfaceAccent,
            fontSize: 16,
            onTap: () => _onSubmit(),
          ),
        ),
      ])
    );
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
      contentList.add(Padding(padding: EdgeInsets.symmetric(horizontal: _hPadding), child:
        Row(children: [
          Expanded(child:
            Text(title, style: TextStyle(fontFamily: Styles().fontFamilies?.bold, fontSize: 20, color: Styles().colors?.fillColorPrimary), textAlign: TextAlign.left,),
          )
        ])      
      ));
    }

    String descriptionPrefix = _questionnaireString(question.descriptionPrefix);
    if (descriptionPrefix.isNotEmpty) {
      contentList.add(Padding(padding: EdgeInsets.only(left: _hPadding, right: _hPadding, top: 2), child:
        Row(children: [
          Expanded(child:
            Text(descriptionPrefix, style: TextStyle(fontFamily: Styles().fontFamilies?.regular, fontSize: 16, color: Styles().colors?.textBackground), textAlign: TextAlign.left,),
          )
        ])
      ));
    }

    List<Widget> answers = _buildAnswers(question);
    if (answers.isNotEmpty) {
      contentList.add(Padding(padding: EdgeInsets.only(top: 8), child:
        Column(children: answers,),
      ));
    }

    String descriptionSuffix = _questionnaireString(question.descriptionSuffix);
    if (descriptionSuffix.isNotEmpty) {
      contentList.add(Padding(padding: EdgeInsets.only(left: _hPadding, right: _hPadding, bottom: 16), child:
        Row(children: [
          Expanded(child:
            Text(descriptionSuffix, style: TextStyle(fontFamily: Styles().fontFamilies?.regular, fontSize: 16, color: Styles().colors?.textBackground), textAlign: TextAlign.left,),
          )
        ])
      ));
    }
    else {
      contentList.add(Padding(padding: EdgeInsets.only(bottom: 16), child:
        Container()
      ));
    }

    return Column(children: contentList,);
  }

  List<Widget> _buildAnswers(Question question) {
    List<Widget> answersList = <Widget>[];
    List<Answer>? answers = question.answers;
    if (answers != null) {
      for (Answer answer in answers) {
        answersList.add(_buildAnswer(answer, question: question));
      }
    }
    return answersList;
  }

  Widget _buildAnswer(Answer answer, { required Question question }) {
    LinkedHashSet<String>? selectedAnswers = _selection[question.id];
    bool selected = selectedAnswers?.contains(answer.id) ?? false;
    String title = _questionnaireString(answer.title);
    return Padding(padding: EdgeInsets.only(left: _hPadding - 12, right: _hPadding), child:
      Row(children: [
        InkWell(onTap: () => _onAnswer(answer, question: question), child:
          Padding(padding: EdgeInsets.only(left: 12, right: 12, top: 8, bottom: 8, ), child:
            Image.asset(selected ? "images/selected-checkbox.png" : "images/deselected-checkbox.png"),
          ),
        ),
        Expanded(child:
          Padding(padding: EdgeInsets.only(top: 8, bottom: 8,), child:
            Text(title, style: TextStyle(fontFamily: Styles().fontFamilies?.regular, fontSize: 16, color: Styles().colors?.fillColorPrimary), textAlign: TextAlign.left,)
          ),
        ),
      ]),
    );
  }

  void _onAnswer(Answer answer, { required Question question }) {

    String answerTitle = _questionnaireString(answer.title, languageCode: 'en');
    String? questionTitle = _questionnaireString(question.title, languageCode: 'en');
    Analytics().logSelect(target: '$questionTitle => $answerTitle');

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
        Auth2().prefs?.setQuestionnaireAnswers(_questionnaire?.id, _selection);

        String questionaireTitle = _questionnaireString(_questionnaire?.title);
        String promptFormat = Localization().getStringEx('panel.onboarding2.research.questionnaire.acknowledgement', 'Thank you for participating in the {{QuestionnaireName}}.');
        String displayPrompt = promptFormat.replaceAll('{{QuestionnaireName}}', questionaireTitle);
        AppAlert.showDialogResult(context, displayPrompt).then((_) {
          Function? onContinue = (widget.onboardingContext != null) ? widget.onboardingContext!["onContinueAction"] : null;
          if (onContinue != null) {
            onContinue();
          }
          else {
            Navigator.of(context).pop();
          }
        });
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
                    Text('Failed to load demographics questionnaire.', style: TextStyle(fontFamily: Styles().fontFamilies?.medium, fontSize: 20, color: Styles().colors?.fillColorPrimary), textAlign: TextAlign.center,),
                  ),
                ],)
              )
            ),
          ),
        ],))
    ]);
  }

}