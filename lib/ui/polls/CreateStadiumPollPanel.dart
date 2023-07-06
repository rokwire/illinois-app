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
import 'package:illinois/service/Auth2.dart';
import 'package:rokwire_plugin/model/geo_fence.dart';
import 'package:rokwire_plugin/model/poll.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/service/geo_fence.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/log.dart';
import 'package:rokwire_plugin/service/polls.dart';
import 'package:illinois/ui/polls/CreatePollPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/service/styles.dart';


class CreateStadiumPollPanel extends StatefulWidget {
  
  static void present(BuildContext context) {
    if (!Auth2().isOidcLoggedIn) {
      AppAlert.showMessage(context, Localization().getStringEx('panel.browse.label.logged_out.create_stadium_poll', 'You need to be logged in with your NetID to create a Stadium Poll. Set your privacy level to 4 or 5 in your Profile. Then find the sign-in prompt under Settings.'));
    }
    else if (!Auth2().hasRole('stadium poll manager')) {
      AppAlert.showMessage(context, Localization().getStringEx('panel.browse.label.no_rights.create_stadium_poll', 'You have no rights to create a Stadium Poll.'));
    }
    else {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => CreateStadiumPollPanel()));
    }
  }

  _CreateStadiumPollPanelState createState() => _CreateStadiumPollPanelState();
}

class _CreateStadiumPollPanelState extends State<CreateStadiumPollPanel> {
  final double horizontalPadding = 24;
  final int _defaultOptionsCount = 2;
  final int _maxOptionsCount = 4;

  //Data
  final TextEditingController _questionController = TextEditingController();
  List<TextEditingController>? _optionsControllers;
  List<GeoFenceRegion>? _geoFenceRegions;
  bool _selectedMultichoice = false;
  bool _selectedRepeatVotes = false;
  bool _selectedHideResult = false;
  bool _selectedGeofenceResult = true;
  GeoFenceRegion? _selectedGeofence;
  PollStatus? _progressPollStatus;

  @override
  void initState() {
    _initDefaultOptionsControllers();
    _initGeoFenceValues();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: HeaderBar(
          title: Localization().getStringEx("panel.create_stadium_poll.header.title", "Create a Stadium Poll"),
          leadingIconKey: 'close-circle-white',
          onLeading: _onTapCancel,
        ),
        body: Container(
            color: Styles().colors!.white,
            child: SingleChildScrollView(
                      child: Column(children: [
                        _buildGeofenceDetails(),
                        _buildQuestionField(),
                        _buildOptionsList(),
                        _buildSettingsHeader(),
                        _buildSettingsList(),
                        _buildButtonsTab()
                      ]))),
            );
  }

  void _initGeoFenceValues() {
    _geoFenceRegions = GeoFence().regionsList(type: 'stadium');
    _selectedGeofence = !CollectionUtils.isEmpty(_geoFenceRegions)?_geoFenceRegions![0] : null; //Default value;
  }

  _initDefaultOptionsControllers() {
    _optionsControllers = [];

    if (_defaultOptionsCount > 0) {
      for (int i = 0; i < _defaultOptionsCount; i++) {
        _optionsControllers!.add(TextEditingController());
      }
    }
  }

  Widget _buildGeofenceDetails() {
    return Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding,vertical: 0),
        child: Column(
          children: <Widget>[
            Container(height: 7,),
            _buildGeofenceNamesList(),
            Container(
              height: 7,
            ),
            ToggleRibbonButton(
                label: Localization().getStringEx("panel.create_stadium_poll.setting.geofence", "Geofence poll to venue"),
                toggled: _selectedGeofenceResult,
                borderRadius:  BorderRadius.all(Radius.circular(5)),
                textStyle: Styles().textStyles?.getTextStyle("widget.button.title.medium.thin"),
                onTap: () {
                  if (_progressPollStatus == null) {
                    setState(() {
                      _selectedGeofenceResult = !_selectedGeofenceResult;
                    });
                  }
                })
          ],
        ));
  }

  Widget _buildGeofenceNamesList() {
    return Container(
        child:

        Semantics(label: _selectedGeofence?.name??"Select Geofence",
          hint: Localization().getStringEx("panel.create_stadium_poll.geofence_choser.hint","Double tap to show available regions"),
          excludeSemantics:true,child:
        DropdownButtonHideUnderline(
            child: DropdownButton(
                icon: Styles().images?.getImage('chevron-down', excludeFromSemantics: true),
                isExpanded: true,
                style:Styles().textStyles?.getTextStyle("panel.poll.create.stadium.geofence.dropdown.title"),
                hint: Text(_selectedGeofence?.name??"Select Geofence",
                    style: Styles().textStyles?.getTextStyle("widget.detail.regular")
                ),
                items: _buildDropDownItems(),
                onChanged: _onDropDownValueChanged)),
    ));

  }

  List<DropdownMenuItem<dynamic>>? _buildDropDownItems() {
    return _geoFenceRegions?.map((GeoFenceRegion geofence) {
      return DropdownMenuItem<dynamic>(
        value: geofence,
        child: BlockSemantics(blocking: true, child:
        Semantics(label:geofence.name,
          hint: Localization().getStringEx("panel.create_stadium_poll.geofence_choser_option.hint","Double tap to select region"),
          excludeSemantics: true, button:false,child:
          Text(
            geofence.name ?? '',
            style: Styles().textStyles?.getTextStyle("widget.detail.regular")
        ),
      )));
    }).toList();
  }

  _onDropDownValueChanged(dynamic value){
    Analytics().logSelect(target: "Geofence selected: $value");
    setState(() {
      _selectedGeofence = value;
    });
  }

  Widget _buildQuestionField() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Container(
          child: PollOptionView(
            title: Localization().getStringEx("panel.create_stadium_poll.text.question", "QUESTION"),
            hint: Localization().getStringEx("panel.create_stadium_poll.hint.question", "Ask people…"),
            textController: _questionController,
            maxLength: 120,
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
        TextEditingController controller = _optionsControllers![i];
        String title = Localization().getStringEx("panel.create_stadium_poll.text.option", "OPTION") + " " + (i + 1).toString();
        options.add(PollOptionView(
          title: title,
          textController: controller,
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
    String label = Localization().getStringEx("panel.create_stadium_poll.button.add_option.text", "Add Option");
    String? hint = Localization().getStringEx("panel.create_stadium_poll.button.add_option.hint", "");
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
                Styles().textStyles?.getTextStyle("widget.button.title.medium.fat"),
              ),
              Padding(padding: EdgeInsets.only(left: 5), child:
              Styles().images?.getImage('plus-circle', excludeFromSemantics: true),
              )
            ])
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
                      Padding(
                        padding: EdgeInsets.only(left: 10),
                        child: Text(additionalSettingsText, style:  Styles().textStyles?.getTextStyle("widget.title.regular.fat"),
                        ),
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

  List<Widget> _buildSettingsButtons() {
    TextStyle? _textStyle =  Styles().textStyles?.getTextStyle("widget.button.title.medium");
    BorderRadius rounding = BorderRadius.all(Radius.circular(5));
    List<Widget> widgets =  [];

    widgets.add(ToggleRibbonButton(
        label: Localization().getStringEx("panel.create_stadium_poll.setting.multy_choice", "Allow selecting more than one choice"),
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
        label: Localization().getStringEx("panel.create_stadium_poll.setting.repeat_vote", "Allow repeat votes"),
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
        label: Localization().getStringEx("panel.create_stadium_poll.setting.hide_result", "Hide results until poll ends"),
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child:
                      RoundedButton(
                        label: Localization().getStringEx("panel.create_stadium_poll.setting.button.save.title", "Save"),
                        textStyle: Styles().textStyles?.getTextStyle("widget.button.title.large.fat"),
                        backgroundColor: Colors.white,
                        borderColor: Styles().colors!.fillColorPrimary,
                        progress: (_progressPollStatus == PollStatus.created),
                        onTap: () {
                          _onCreatePoll(status: PollStatus.created);
                        },
                      ),
                  ),
                  Container(
                    width: 6,
                  ),
                  Expanded(
                    child:
                      RoundedButton(
                        label: Localization().getStringEx("panel.create_stadium_poll.setting.start.preview.title", "Start poll!"),
                        textStyle: Styles().textStyles?.getTextStyle("widget.button.title.large.fat"),
                        backgroundColor: Colors.white,
                        borderColor: Styles().colors!.fillColorSecondary,
                        progress: (_progressPollStatus == PollStatus.opened),
                        onTap: () {
                          _onCreatePoll(status: PollStatus.opened);
                        },
                      ),
                  ),
                ],
              )),
        ));
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
                    Localization().getStringEx("panel.create_stadium_poll.cancel_dialog.title", "Illinois"),
                    style: Styles().textStyles?.getTextStyle("widget.dialog.message.dark.large"),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 26),
                    child: Text(
                      Localization().getStringEx("panel.create_stadium_poll.cancel_dialog.message", "Are you sure you want to cancel this Stadium Poll"),
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
                          child: Text(Localization().getStringEx("panel.create_stadium_poll.cancel_dialog.button.yes", "Yes"))),
                      TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text(Localization().getStringEx("panel.create_stadium_poll.cancel_dialog.button.no", "No")))
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
    String? validationErrorMsg = _getValidationErrorMsg();
    if (StringUtils.isNotEmpty(validationErrorMsg)) {
      AppAlert.showDialogResult(context, validationErrorMsg);
      return;
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
        settings: PollSettings(
          allowMultipleOptions: _selectedMultichoice,
          hideResultsUntilClosed: _selectedHideResult,
          allowRepeatOptions: _selectedRepeatVotes,
          geoFence: _selectedGeofenceResult,
        ),
        creatorUserUuid: _selectedGeofence?.id,
        creatorUserName: _selectedGeofence?.name, /*Auth2().account?.authType?.uiucUser?.fullName,*/
        regionId: _selectedGeofence?.id,
        pinCode: Poll.randomPin,
        status: status,
      );

      setState(() {
        _progressPollStatus = status;
      });
      Polls().create(poll).then((_) {
        Navigator.pop(context);
      }).catchError((e) {
        Log.e('Failed to create poll:');
        Log.e(e.toString());
        AppAlert.showDialogResult(context, Localization().getStringEx('panel.create_stadium_poll.error.create_poll_failed.text', 'Failed to create stadium poll.'));
      }).whenComplete(() {
        setState(() {
          _progressPollStatus = null;
        });
      });
    }
  }

  ///Returns non-empty user friendly string when not valid, null - otherwise
  String? _getValidationErrorMsg() {
    if (_selectedGeofence == null) {
      return Localization().getStringEx('panel.create_stadium_poll.not_valid.geofence.msg', "Please, select value for Geofence!");
    }
    if (StringUtils.isEmpty(_questionController.text)) {
      return Localization().getStringEx('panel.create_stadium_poll.not_valid.question.msg', "Please, fill value for 'Question'!");
    }
    if (CollectionUtils.isNotEmpty(_optionsControllers)) {
      for (TextEditingController optionController in _optionsControllers!) {
        if (StringUtils.isEmpty(optionController.text)) {
          return Localization().getStringEx('panel.create_stadium_poll.not_valid.option.msg', "Please, provide value for each option!");
        }
      }
    }
    return null;
  }
}