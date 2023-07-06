
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:illinois/model/Questionnaire.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Questionnaire.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:sprintf/sprintf.dart';

class ResearchProjectProfilePanel extends StatefulWidget  {
  final Map<String, dynamic>? profile;
  
  ResearchProjectProfilePanel({this.profile});

  @override
  State<ResearchProjectProfilePanel> createState() => _ResearchProjectProfilePanelState();
}

class _ResearchProjectProfilePanelState extends State<ResearchProjectProfilePanel> {

  bool _loading = false;
  Questionnaire? _questionnaire;
  Map<String, LinkedHashSet<String>> _selection = <String, LinkedHashSet<String>>{};

  int? _allAudienceCount;
  int? _targetAudienceCount;
  bool _shouldUpdateTargetAudienceCount = false;
  bool _updatingTargetAudienceCount = false;

  final double _hPadding = 24;

  @override
  void initState() {

    _loading = true;

    Groups().loadResearchProjectTragetAudienceCount(<String, dynamic>{}).then((int? count) {
      if (mounted) {
        if ((count != null) && (_allAudienceCount != count)) {
          setState(() {
            _allAudienceCount = count;
          });
        }
      }
    });

    Questionnaires().loadResearch().then((Questionnaire? questionnaire) {
      if (mounted) {
        setState(() {
          _loading = false;
          _questionnaire = questionnaire;
          if ((widget.profile != null) && (_questionnaire?.id != null)) {
            Map<String, LinkedHashSet<String>>? selection = JsonUtils.mapOfStringToLinkedHashSetOfStringsValue(widget.profile![questionnaire?.id]);
            if (selection != null) {
              _selection.addAll(selection);
            }
          }
        });
        _updateTargetAudienceCount();
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
        leadingIconKey: 'close-circle-white',
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

    String headingInfo;
    if (_targetAudienceCount == null) {
      headingInfo = _updatingTargetAudienceCount ? 'Evaluating potential participants...' : 'Potential participants evaluation failed.';
    }
    else if (_targetAudienceCount == 0) {
      headingInfo = (_allAudienceCount != null) ?
        sprintf('Currently targeting 0 of %s potential participants.', [ _allAudienceCount ]) :
        'Currently targeting no potential participants.';
    }
    else if (_targetAudienceCount == 1) {
      headingInfo = (_allAudienceCount != null) ?
        sprintf('Currently targeting 1 of %s potential participants.', [ _allAudienceCount ]) :
        'Currently targeting 1 potential participant.';
    }
    else {
      headingInfo = (_allAudienceCount != null) ?
        sprintf('Currently targeting %s of %s potential participants.', [ _targetAudienceCount, _allAudienceCount ]) :
        sprintf('Currently targeting %s potential participants.', [_targetAudienceCount]);
    }

    String submitText;

    if (_targetAudienceCount == null) {
      submitText = 'Save';
    }
    else if (_targetAudienceCount == 0) {
      submitText = 'Target no potential participants';
    }
    else if (_targetAudienceCount == 1) {
      submitText = 'Target 1 potential participant';
    }
    else {
      submitText = sprintf('Target %s potential participants', [_targetAudienceCount]);
    }

    String profileDescription = _profileDescription;

    return Column(children: <Widget>[
      Stack(children: [
        Semantics(container: true, child:Container(color: Styles().colors?.white, child:
          Padding(padding: EdgeInsets.symmetric(horizontal: _hPadding, vertical: _hPadding / 2), child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children:<Widget>[
              Padding(padding: EdgeInsets.zero, child:
                Text('Select Answers', //TBD localize
                  style: Styles().textStyles?.getTextStyle("widget.title.regular.fat")),
              ),
              Padding(padding: EdgeInsets.zero, child:
                Text('Create a target audience by selecting answers that potential participants have chosen.',
                  style: Styles().textStyles?.getTextStyle("panel.research_project.profile.detail.regular")),
              ),
              Padding(padding: EdgeInsets.only(top: 4), child:
                Text(headingInfo,
                  style: Styles().textStyles?.getTextStyle("widget.title.small.fat")),
              ),
              Padding(padding: EdgeInsets.only(right: 12), child:
                Text(profileDescription, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: Styles().textStyles?.getTextStyle("panel.research_project.profile.detail.small")
                ),
              ),
            ]),
          ),
        )),
        Visibility(visible: _updatingTargetAudienceCount, child:
          Positioned.fill(child:
            Align(alignment: Alignment.topRight, child:
              Padding(padding: EdgeInsets.only(top: 16, right: 16), child:
                SizedBox(width: 16, height: 16, child:
                  CircularProgressIndicator(color: Styles().colors?.fillColorSecondary, strokeWidth: 1, )
                )
              )
            )
          ),
        ),
        Visibility(visible: profileDescription.isNotEmpty, child:
          Positioned.fill(child:
            Align(alignment: Alignment.bottomRight, child:
              InkWell(onTap: _onDescriptionInfo, child:
                Padding(padding: EdgeInsets.only(left: 8, right: 12, top: 8, bottom: 12), child:
                  Styles().images?.getImage('eye', excludeFromSemantics: true,)
                )
              ),
            ),
          ),
        ),


      ],),
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
            label: submitText,
            hint: '',
            textStyle: Styles().textStyles?.getTextStyle("widget.button.title.enabled"),
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            borderColor: Styles().colors?.fillColorSecondary,
            backgroundColor: Styles().colors!.white,
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

    String descriptionPrefix = _questionnaireStringEx(question.descriptionPrefix);
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

    String descriptionSuffix = _questionnaireStringEx(question.descriptionSuffix);
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
    String title = _questionnaireStringEx(answer.title);
    return
      Semantics(
        label: title,
        value: selected?  Localization().getStringEx("toggle_button.status.checked", "checked",) : Localization().getStringEx("toggle_button.status.unchecked", "unchecked"),
        button: true,
        child: Padding(padding: EdgeInsets.only(left: _hPadding - 12, right: _hPadding), child:
          Row(children: [
            InkWell(onTap: (){ _onAnswer(answer, question: question); AppSemantics.announceCheckBoxStateChange(context,  /*reversed value*/!(selected == true), title); }, child:
              Padding(padding: EdgeInsets.only(left: 12, right: 12, top: 8, bottom: 8, ), child:
                Styles().images?.getImage(selected ? "check-box-filled" : "box-outline-gray", excludeFromSemantics: true),
              ),
            ),
            Expanded(child:
              Padding(padding: EdgeInsets.only(top: 8, bottom: 8,), child:
                Text(title, style: Styles().textStyles?.getTextStyle("widget.detail.regular"), textAlign: TextAlign.left,)
              ),
            ),
          ]),
        ));
  }

  void _onAnswer(Answer answer, { required Question question }) {

    String answerTitle = _questionnaireStringEx(answer.title, languageCode: 'en');
    String questionTitle = _questionnaireStringEx(question.title, languageCode: 'en');
    Analytics().logSelect(target: '$questionTitle => $answerTitle');

    String? answerId = answer.id;
    String? questionId = question.id;
    if ((questionId != null) && (answerId != null)) {
      setState(() {
        LinkedHashSet<String>? selectedAnswers = _selection[questionId];
        if ((selectedAnswers != null) && selectedAnswers.contains(answerId)) {
          selectedAnswers.remove(answerId);
          if (selectedAnswers.isEmpty) {
            _selection.remove(questionId);
          }
        }
        else {
          selectedAnswers ??= (_selection[questionId] = LinkedHashSet<String>());
          selectedAnswers.add(answerId);
        }
      });
      _updateTargetAudienceCount();
    }
  }

  void _onSubmit() {
    Analytics().logSelect(target: 'Submit');
    Navigator.of(context).pop(_projectProfile);
  }

  void _onDescriptionInfo() {
    showDialog(context: context, builder: (context) {
        return AlertDialog(
          contentPadding: EdgeInsets.all(16),
          alignment: Alignment.topCenter,
          insetPadding: EdgeInsets.symmetric(horizontal: 42.0, vertical: 84.0),
          content: _profileDescriptionPopupContent,
        );
      },
    );
  }

  Map<String, dynamic> get _projectProfile => {
    (_questionnaire?.id ?? '') : JsonUtils.mapOfStringToLinkedHashSetOfStringsJsonValue(_selection)
  };

  String? _questionnaireString(String? key, { String? languageCode}) => _questionnaire?.stringValue(key, languageCode: languageCode) ?? key;
  String _questionnaireStringEx(String? key, { String? languageCode}) => _questionnaireString(key, languageCode: languageCode) ?? '';

  String _displayQuestionTitle(Question question, { int? index, String? languageCode }) {
    String title = _questionnaireStringEx(question.title, languageCode: languageCode);
    return ((index != null) && title.isNotEmpty) ? "$index. $title" : title;
  }

  String get _profileDescription {
    String description = '';
    List<Question>? questions = _questionnaire?.questions;
    if (questions != null) {
      for (Question question in questions) {
        String? questionHint = _questionnaireString(question.displayHint);
        List<Answer>? answers = question.answers;
        LinkedHashSet<String>? selectedAnswers = _selection[question.id];
        if ((questionHint != null) && questionHint.isNotEmpty && (answers != null) && answers.isNotEmpty && (selectedAnswers != null) && selectedAnswers.isNotEmpty) {
          List<String> answerHints = <String>[];
          for (Answer answer in answers) {
            String? answerHint = _questionnaireString(answer.displayHint);
            if ((answerHint != null) && selectedAnswers.contains(answer.id) && !answerHints.contains(answerHint)) {
              answerHints.add(answerHint);
            }
          }
          if (answerHints.isNotEmpty) {
            if (description.isNotEmpty) {
              description += '; ';
            }
            description += "$questionHint: ${answerHints.join(', ')}";
          }
        }
      }
    }
    return description;
  }

  Widget get _profileDescriptionPopupContent {
    List<Widget> contentList = <Widget>[];
    List<Question>? questions = _questionnaire?.questions;
    if (questions != null) {
      for (Question question in questions) {
        String? questionHint = _questionnaireString(question.displayHint);
        List<Answer>? answers = question.answers;
        LinkedHashSet<String>? selectedAnswers = _selection[question.id];
        if ((questionHint != null) && questionHint.isNotEmpty && (answers != null) && answers.isNotEmpty && (selectedAnswers != null) && selectedAnswers.isNotEmpty) {
          List<String> answerHints = <String>[];
          for (Answer answer in answers) {
            String? answerHint = _questionnaireString(answer.displayHint);
            if ((answerHint != null) && selectedAnswers.contains(answer.id) && !answerHints.contains(answerHint)) {
              answerHints.add(answerHint);
            }
          }
          if (answerHints.isNotEmpty) {
            contentList.add(RichText(text:
              TextSpan(style: Styles().textStyles?.getTextStyle("widget.description.regular"), children: <TextSpan>[
                TextSpan(text: "$questionHint: ", style: Styles().textStyles?.getTextStyle("widget.description.regular.fat")),
                TextSpan(text: answerHints.join(', '), style: Styles().textStyles?.getTextStyle("widget.description.regular")),
              ]),
            ));
          }
        }
      }
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: contentList,);
  }

  void _updateTargetAudienceCount() {
    if (_updatingTargetAudienceCount) {
      _shouldUpdateTargetAudienceCount = true;
    }
    else {
      setState(() {
        _shouldUpdateTargetAudienceCount = false;
      });
      _updatingTargetAudienceCount = true;
      Groups().loadResearchProjectTragetAudienceCount(_projectProfile).then((int? count) {
        if (mounted) {
          if ((count != null) && (_targetAudienceCount != count)) {
            setState(() {
              _targetAudienceCount = count;
            });
          }
          
          _updatingTargetAudienceCount = false;
          if (_shouldUpdateTargetAudienceCount) {
            _updateTargetAudienceCount();
          }
          else {
            setState(() {});
          }
        }

      });
    }
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