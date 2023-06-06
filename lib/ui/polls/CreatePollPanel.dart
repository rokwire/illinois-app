/*
 * Copyright 2020 Board of Trustees of the University of Illinois.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/groups/GroupWidgets.dart';
import 'package:illinois/ui/widgets/AccessWidgets.dart';
import 'package:illinois/ui/widgets/UnderlinedButton.dart';
import 'package:rokwire_plugin/model/group.dart';
import 'package:rokwire_plugin/model/poll.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/log.dart';
import 'package:rokwire_plugin/service/polls.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:sprintf/sprintf.dart';

class CreatePollPanel extends StatefulWidget {
  final Group? group;

  CreatePollPanel({this.group});

  static void present(BuildContext context) {
    Future? result = AccessDialog.show(context: context, resource: 'polls');
    if (result == null) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => CreatePollPanel()));
    }
  }

  _CreatePollPanelState createState() => _CreatePollPanelState();
}

class _CreatePollPanelState extends State<CreatePollPanel> {
  final double horizontalPadding = 24;
  final int _defaultOptionsCount = 2;
  final int _maxOptionsCount = 6;

  //Data
  final TextEditingController _questionController = TextEditingController();
  List<TextEditingController>? _optionsControllers;
  bool _selectedMultichoice = false;
  bool _selectedRepeatVotes = false;
  bool _selectedHideResult = false;
  PollStatus? _progressPollStatus;
  //Groups
  List<Member>? _groupMembersSelection;
  List<Member>? _membersAllowedToPost;

  @override
  void initState() {
    _loadMembersAllowedToPost();
    _initDefaultOptionsControllers();
    super.initState();
  }

  @override
  void dispose() {
    _destroyOptionsControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: HeaderBar(
          title: Localization().getStringEx("panel.create_poll.header.title", "Create a Quick Poll"),
          leadingIconKey: 'close-circle-white',
          onLeading: _onTapCancel,
        ),
        body: SafeArea(
          child: Container(
            color: Styles().colors!.white,
            child: SingleChildScrollView(
              child: Column(children: [
                _buildDescription(),
                _buildNameLabel(),
                _buildQuestionField(),
                _buildOptionsList(),
                _buildSettingsHeader(),
                _buildSettingsList(),
                _buildGroupMembersSelection(),
                _buildButtonsTab()
              ])))));
  }

  void _initDefaultOptionsControllers() {
    _optionsControllers = [];

    if (_defaultOptionsCount > 0) {
      for (int i = 0; i < _defaultOptionsCount; i++) {
        _optionsControllers!.add(TextEditingController());
      }
    }
  }

  void _destroyOptionsControllers() {
    if (_optionsControllers != null) {
      for (TextEditingController controller in _optionsControllers!) {
        controller.dispose();
      }
    }
    _optionsControllers = null;
  }

  void _loadMembersAllowedToPost() {
    Groups().loadMembersAllowedToPost(groupId: widget.group?.id).then((members) {
      _membersAllowedToPost = members;
      if (mounted) {
        setState(() {});
      }
    });
  }

  Widget _buildDescription() {
    return Container(
        color: Styles().colors!.white,
        child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 24),
            child: Text(
              Localization().getStringEx("panel.create_poll.description","People can vote through the {{app_title}} app by asking you for the 4 Digit Poll #.").replaceAll('{{app_title}}', Localization().getStringEx('app.title', 'Illinois')),
              style: Styles().textStyles?.getTextStyle("widget.item.small.thin"),
            )));
  }

  Widget _buildNameLabel() {
    String name = Auth2().fullName ?? "Someone";
    String wantToKnowText = Localization().getStringEx("panel.create_poll.text.wants_to_know", "wants to know…");
    return
      Semantics(label: name +","+wantToKnowText , excludeSemantics: true,child:
      Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Row(
          children: <Widget>[
            Expanded(flex: 5,
              child: Text(name, style:Styles().textStyles?.getTextStyle("widget.item.medium")),
            ),
            Container(
              width: 7,
            ),
            Expanded(
              flex: 3,
              child: Text(wantToKnowText,
                style: Styles().textStyles?.getTextStyle("widget.detail.regular.fat")),
            )
          ],
        )));
  }

  Widget _buildQuestionField() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Container(
          child: PollOptionView(
        title: Localization().getStringEx("panel.create_poll.text.question", "QUESTION"),
        hint: Localization().getStringEx("panel.create_poll.hint.question", "Ask people…"),
        textController: _questionController,
        maxLength: 250,
        minLines: 3,
        enabled: (_progressPollStatus == null),
      )),
    );
  }

  Widget _buildOptionsList() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Container(
          child: Column(
        children: _constructOptionsWidgets(),
      )),
    );
  }

  List<Widget> _constructOptionsWidgets() {
    List<Widget> options = [];
    if (_optionsControllers?.isNotEmpty ?? false) {
      for (int i = 0; i < _optionsControllers!.length; i++) {
        String title = Localization().getStringEx("panel.create_poll.text.option", "OPTION") + " " + (i + 1).toString();
        options.add(PollOptionView(
          title: title,
          textController: _optionsControllers![i],
          enabled: (_progressPollStatus == null),
          onClose: (_defaultOptionsCount <= i) ? () => _onRemoveOption(i) : null,
        ));
      }

      if (_optionsControllers!.length < _maxOptionsCount)
        options.add(_constructAddOptionButton());
      else
        options.add(Container(
          height: 24,
        ));
    }

    return options;
  }

  Widget _constructAddOptionButton() {
    String label = Localization().getStringEx("panel.create_poll.button.add_option.text", "Add Option");
    String? hint = Localization().getStringEx("panel.create_poll.button.add_option.hint", "");
    return Container(padding: EdgeInsets.symmetric(vertical: 24), alignment: Alignment.centerRight, child:
      Semantics(label: label, hint: hint, button: true, excludeSemantics: true, child:
        InkWell(onTap: _onAddOption, child:
          Container(
            padding: EdgeInsets.symmetric(vertical: 5, horizontal: 15),
            decoration: BoxDecoration(
              color: Styles().colors!.white,
              border: Border.all(color: Styles().colors!.fillColorSecondary!, width: 2.0),
              borderRadius: BorderRadius.circular(24.0),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
              Text(label, style:
                Styles().textStyles?.getTextStyle("widget.button.title.medium.fat")
              ),
              Padding(padding: EdgeInsets.only(left: 5), child:
              Styles().images?.getImage('plus-circle', excludeFromSemantics: true),
              ),
            ]),
          )
        )
      ),
    );
  }

  void _onAddOption() {
    Analytics().logSelect(target: 'Add Option');
    if (_progressPollStatus == null) {
      _optionsControllers?.add(TextEditingController());
      setState(() {});
    }
  }

  void _onRemoveOption(int index) {
    Analytics().logSelect(target: 'Remove Option');
    if ((_progressPollStatus == null) && (_optionsControllers != null) & (0 <= index) && (index < _optionsControllers!.length)) {
      _optionsControllers![index].dispose();
      _optionsControllers!.removeAt(index);
      setState(() {});
    }
  }

  Widget _buildSettingsHeader() {
    String additionalSettingsText = Localization().getStringEx("panel.create_poll.text.add_option", "Additional Settings");
    return Padding(
        padding: EdgeInsets.only(top: 3),
        child: Container(
            color: Styles().colors!.background,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 26),
              child: Semantics( label: additionalSettingsText, excludeSemantics: true, child:
                Container(
                    child: Row(
                    children: <Widget>[
                      Styles().images?.getImage('settings', excludeFromSemantics: true) ?? Container(),
                      Expanded(child:
                        Padding(
                          padding: EdgeInsets.only(left: 10),
                          child: Text(additionalSettingsText, style: Styles().textStyles?.getTextStyle("widget.title.regular.fat"),
                          ),
                        )
                      )
                    ],
                  ),
                ),
            ))));
  }

  Widget _buildSettingsList() {
    return Container(
        color: Styles().colors!.background,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Container(
              child: Column(
            children: _buildSettingsButtons(),
          )),
        ));
  }

  Widget _buildGroupMembersSelection(){
    if(widget.group == null){
      return Container();
    }
    return Container(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        color: Colors.white,
        child: GroupMembersSelectionWidget(
        selectedMembers: _groupMembersSelection,
        allMembers: _membersAllowedToPost,
        groupId: widget.group?.id,
        groupPrivacy: widget.group?.privacy,
        onSelectionChanged: (members){
          setState(() {
            _groupMembersSelection = members;
          });
        },));
  }

  List<Widget> _buildSettingsButtons() {
    TextStyle? _textStyle = Styles().textStyles?.getTextStyle("widget.button.title.medium");
    BorderRadius rounding = BorderRadius.all(Radius.circular(5));
    List<Widget> widgets =  [];

    widgets.add(ToggleRibbonButton(
        label: Localization().getStringEx("panel.create_poll.setting.multy_choice", "Allow selecting more than one choice"),
        toggled: _selectedMultichoice,
        borderRadius: rounding,
        textStyle: _textStyle,
        onTap: () {
          if (_progressPollStatus == null) {
            setState(() {
              _selectedMultichoice = !_selectedMultichoice;
            });
          }
        }));
    /*widgets.add(Container(
      height: 16,
    ));
    widgets.add(ToggleRibbonButton(
      label: Localization().getStringEx("panel.create_poll.setting.repeat_vote", "Allow repeat votes"),
      toggled: _selectedRepeatVotes,
      borderRadius: rounding,
      textStyle: _textStyle,
      onTap: () {
        if (_progressPollStatus == null) {
          setState(() {
            _selectedRepeatVotes = !_selectedRepeatVotes;
          });
        }
      }));*/
    widgets.add(Container(
      height: 16,
    ));
    widgets.add(ToggleRibbonButton(
        label: Localization().getStringEx("panel.create_poll.setting.hide_result", "Hide results until poll ends"),
        toggled: _selectedHideResult,
        borderRadius: rounding,
        textStyle: _textStyle,
        onTap: () {
          if (_progressPollStatus == null) {
            setState(() {
              _selectedHideResult = !_selectedHideResult;
            });
          }
        }));
    widgets.add(Container(
      height: 24,
    ));
    return widgets;
  }

  Widget _buildButtonsTab() {
    return Container(
        child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16),
            child: Container(
                child: Column(children: [
                   RoundedButton(
                      label: Localization().getStringEx("panel.create_poll.setting.start.preview.title", "Start Poll Now"),
                       textStyle: Styles().textStyles?.getTextStyle("widget.button.title.large.fat"),
                      backgroundColor: Colors.white,
                      borderColor: Styles().colors!.fillColorSecondary,
                      progress: (_progressPollStatus == PollStatus.opened),
                      onTap: () {
                        _onCreatePoll(status: PollStatus.opened);
                      }),
                  Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: Text(
                        Localization()
                            .getStringEx("panel.create_poll.description.non_editable.text", "Once started, you can no longer edit the poll."),
                        style: Styles().textStyles?.getTextStyle("widget.item.small.thin"),
                      )),
                  UnderlinedButton(
                      title: Localization().getStringEx("panel.create_poll.setting.button.save.title", "Save poll for starting later"),//TBD localize
                      // backgroundColor: Colors.white,
                      // borderColor: Styles().colors!.fillColorPrimary,
                      // textColor: Styles().colors!.fillColorPrimary,
                      progress: (_progressPollStatus == PollStatus.created),
                      onTap: () {
                        _onCreatePoll(status: PollStatus.created);
                      },
                  ),
                  Container(height: 10)
            ]))));
  }

  void _onTapCancel() {
    if (_progressPollStatus == null) {
      showDialog(context: context, builder: (context) =>
          Dialog(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    Localization().getStringEx("panel.create_poll.cancel_dialog.title", "Illinois"),
                    style: Styles().textStyles?.getTextStyle("widget.dialog.message.dark.large"),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 26),
                    child: Text(
                      Localization().getStringEx("panel.create_poll.cancel_dialog.message", "Are you sure you want to cancel this Quick Poll?"),
                      textAlign: TextAlign.left,
                      style: Styles().textStyles?.getTextStyle("widget.dialog.message.dark.regular"),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pop(context);
                          },
                          child: Text(Localization().getStringEx("panel.create_poll.cancel_dialog.button.yes", "Yes"))),
                      TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text(Localization().getStringEx("panel.create_poll.cancel_dialog.button.no", "No")))
                    ],
                  ),
                ],
              ),
            ),
          )
      );
    }
  }

  void _onCreatePoll({PollStatus? status}) {
    if(!_isValid()) {
      AppAlert.showDialogResult(context, "Invalid poll data");
    }
    else if (_progressPollStatus == null) {
      //Options
      List<String> options = [];
      if(_optionsControllers?.isNotEmpty??false){
        for(TextEditingController optionController in _optionsControllers!){
          options.add(optionController.text);
        }
      }

      //Poll
      Poll poll = Poll(
        title: _questionController.text,
        options: options,
        settings: PollSettings(allowMultipleOptions: _selectedMultichoice, hideResultsUntilClosed: _selectedHideResult, allowRepeatOptions: _selectedRepeatVotes),
        creatorUserUuid: Auth2().accountId,
        creatorUserName: Auth2().fullName ?? 'Someone',
        pinCode: Poll.randomPin,
        status: status,
        groupId: widget.group?.id,
        toMembers: _groupMembersSelection
      );
      
      setState(() {
        _progressPollStatus = status;
      });
      Polls().create(poll).then((Poll poll){
        Navigator.of(context).pop(poll);
      }).catchError((e){
        Log.d(e.toString());
        String? errorMessage = Localization().getStringEx("panel.create_poll.message.error.default", "Failed to create poll. Please fill all fields and try again.");
        AppAlert.showDialogResult(context, errorMessage);
      }).whenComplete((){
        setState(() {
          _progressPollStatus = null;
        });
      });
    }
  }

  bool _isValid(){
    return StringUtils.isNotEmpty(_questionController.text);//Question validation: Not empty Question
//           && (_optionsControllers?.where((controller)=>AppUtils.isNotEmpty(controller?.text))?.toList()?.isNotEmpty??false); //Options validation: At least one option
  }
}

class PollOptionView extends StatefulWidget {
  final String? title;
  final String? hint;
  final TextEditingController? textController;
  final int maxLength;
  final int minLines;
  final int maxLines;
  final bool enabled;
  final void Function()? onClose;

  const PollOptionView({Key? key, this.title, this.textController, this.maxLength = 45, this.minLines = 1, this.maxLines = 10, this.hint, this.enabled = true, this.onClose}) : super(key: key);

  @override
  _PollOptionViewState createState() {
    return _PollOptionViewState();
  }
}

class _PollOptionViewState extends State<PollOptionView> {
  String counterFormat = "%d/%d";

  @override
  Widget build(BuildContext context) {
    String counterHint = Localization().getStringEx("panel.create_poll_panel.counter.hint", "maximum, %s, characters");
    String votesCount = widget.maxLength.toStringAsFixed(0);
    return Column(children: <Widget>[
        Semantics(label: widget.title, hint: sprintf(counterHint,['$votesCount']) , excludeSemantics: true, child:
          Padding(padding: EdgeInsets.only(bottom: 8, top: 24), child:
            Row(children: <Widget>[
              Expanded(child:
                Text(widget.title!, textAlign: TextAlign.left, style: Styles().textStyles?.getTextStyle("panel.poll.create.poll_option.title"),
                )
              ),
              Text(_getCounterText(), style: Styles().textStyles?.getTextStyle("panel.poll.create.poll_option.counter"), )
            ])
          )
        ),
        Stack(children: [
          Container(
            padding: EdgeInsets.only(left: 12, right: canClose ? 18 : 12),
            decoration: BoxDecoration(border: Border.all(color: Styles().colors!.fillColorPrimary!, width: 1)),
            child: Semantics(label: widget.title, hint: Localization().getStringEx("panel.create_poll_panel.hint", ""), textField: true, excludeSemantics: true, child:
              TextField(
                  controller: widget.textController,
                  onChanged: (String text) {
                    setState(() {});
                  },
                  minLines: widget.minLines,
                  maxLines: widget.maxLength,
                  decoration: InputDecoration(hintText: widget.hint, border: InputBorder.none, counterText: ""),
                  maxLength: widget.maxLength,
                  maxLengthEnforcement: MaxLengthEnforcement.enforced,
                  style: Styles().textStyles?.getTextStyle("widget.detail.regular"),
                  enabled: widget.enabled,
                  textCapitalization: TextCapitalization.sentences,
                )),
          ),
          Visibility(visible: canClose, child:
            Positioned.fill(child:
              Align(alignment: Alignment.topRight, child:
                Semantics( label: Localization().getStringEx('dialog.close.title', 'Close'), hint: Localization().getStringEx('dialog.close.hint', ''), inMutuallyExclusiveGroup: true, button: true, child:
                  InkWell(onTap : widget.onClose, child:
                    Padding(padding: EdgeInsets.only(left: 12, right: 8, top: 8, bottom: 12), child:
                        Text('X', style: Styles().textStyles?.getTextStyle("widget.title.regular")
                        ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],)
      ],
    );
  }

  _getCounterText() {
    return sprintf(counterFormat, [widget.textController?.text.length, widget.maxLength]);
  }

  bool get canClose => (widget.onClose != null);
}
