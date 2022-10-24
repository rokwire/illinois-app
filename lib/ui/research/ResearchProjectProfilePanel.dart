
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:illinois/model/Questionnaire.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Questionnaire.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';

class ResearchProjectProfilePanel extends StatefulWidget  {
  final Map<String, LinkedHashSet<String>>? profile;
  
  ResearchProjectProfilePanel({this.profile});

  @override
  State<ResearchProjectProfilePanel> createState() =>
      _ResearchProjectProfilePanelState();
}

class _ResearchProjectProfilePanelState extends State<ResearchProjectProfilePanel> {

  bool _loading = false;
  Questionnaire? _questionnaire;
  Map<String, LinkedHashSet<String>> _selection = <String, LinkedHashSet<String>>{};

  final double _hPadding = 24;

  @override
  void initState() {

    if (widget.profile != null) {
      _selection.addAll(widget.profile!);
    }

    _loading = true;

    Questionnaires().loadResearch().then((Questionnaire? questionnaire) {
      if (mounted) {
        setState(() {
          _loading = false;
          _questionnaire = questionnaire;
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
      appBar: HeaderBar(
        title: 'Target Audience',
        leadingAsset: 'images/icon-circle-close.png',
      ),
      body: _buildContent(),
      backgroundColor: Styles().colors?.background,
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

    List<Widget> questions = _buildQuestions(questionnaire.questions);
    if (questions.isNotEmpty) {
      contentList.addAll(questions);
    }

    return Column(children: <Widget>[
      Container(color: Styles().colors?.white, child:
        Padding(padding: EdgeInsets.all(_hPadding), child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children:<Widget>[
            Row(children: <Widget>[
              Expanded(child:
                Text('Select Answers',
                  style: TextStyle(fontFamily: Styles().fontFamilies?.bold, fontSize: 16, color: Styles().colors?.fillColorPrimary),),
              ),
            ],),
            Padding(padding: EdgeInsets.only(top: 8), child:
              Text('Create project target audience by selecting the answers that these users have chosen.',
                style: TextStyle(fontFamily: Styles().fontFamilies?.regular, fontSize: 16, color: Styles().colors?.textSurfaceAccent)),
            ),
          ]),
        ),
      ),
      Container(height: 1, color: Styles().colors?.surfaceAccent,),

      Expanded(child:
        SingleChildScrollView(child:
          Padding(padding: EdgeInsets.symmetric(vertical: 12), child:
            Column(children: contentList,),
          )
        ),
      ),
      
      Container(height: 1, color: Styles().colors?.surfaceAccent,),
      Container(color: Styles().colors?.white, child:
        Padding(padding: EdgeInsets.only(left: _hPadding, right: _hPadding, top: 24, bottom: 12,), child:
          SafeArea(child: 
          RoundedButton(
            label: 'Submit',
            hint: '',
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            borderColor: Styles().colors?.fillColorSecondary,
            backgroundColor: Styles().colors!.white,
            textColor: Styles().colors?.fillColorPrimary,
            fontSize: 16,
            onTap: () => _onSubmit(),
          ),
          ),
        ),
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
      contentList.add(Padding(padding: EdgeInsets.symmetric(horizontal: _hPadding), child:
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
      contentList.add(Padding(padding: EdgeInsets.only(top: 8), child:
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
            Text(title, style: Styles().textStyles?.getTextStyle("widget.detail.regular"), textAlign: TextAlign.left,)
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
      });
    }
  }

  void _onSubmit() {
    Analytics().logSelect(target: 'Submit');
    Navigator.of(context).pop(_selection);
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
                    Text('Failed to load research questionnaire.', style:
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