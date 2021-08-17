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

import 'package:flutter/material.dart';
import 'package:illinois/model/GeoFence.dart';
import 'package:illinois/model/Poll.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/GeoFence.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/Log.dart';
import 'package:illinois/service/Polls.dart';
import 'package:illinois/ui/polls/CreatePollPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/RoundedButton.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:illinois/service/Styles.dart';


class CreateStadiumPollPanel extends StatefulWidget {
  _CreateStadiumPollPanelState createState() => _CreateStadiumPollPanelState();
}

class _CreateStadiumPollPanelState extends State<CreateStadiumPollPanel> {
  final double horizontalPadding = 24;
  final int _defaultOptionsCount = 2;
  final int _maxOptionsCount = 4;

  //Data
  final TextEditingController _questionController = TextEditingController();
  List<TextEditingController> _optionsControllers;
  List<GeoFenceRegion> _geoFenceRegions;
  bool _selectedMultichoice = false;
  bool _selectedRepeatVotes = false;
  bool _selectedHideResult = false;
  bool _selectedGeofenceResult = true;
  GeoFenceRegion _selectedGeofence;
  PollStatus _progressPollStatus;

  @override
  void initState() {
    _initDefaultOptionsControllers();
    _initGeoFenceValues();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: SimpleHeaderBarWithBack(
          context: context,
          backIconRes: 'images/close-white.png',
          onBackPressed: _onTapCancel,
          titleWidget: Text(
            Localization().getStringEx("panel.create_stadium_poll.header.title", "Create a Stadium Poll"),
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.0),
          ),
        ),
        body: Container(
            color: Styles().colors.white,
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
    _selectedGeofence = !AppCollection.isCollectionEmpty(_geoFenceRegions)?_geoFenceRegions[0] : null; //Default value;
  }

  _initDefaultOptionsControllers() {
    _optionsControllers = [];

    if (_defaultOptionsCount > 0) {
      for (int i = 0; i < _defaultOptionsCount; i++) {
        _optionsControllers.add(TextEditingController());
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
                context: context,
                borderRadius:  BorderRadius.all(Radius.circular(5)),
                style: TextStyle(color: Styles().colors.fillColorPrimary, fontSize: 16, fontFamily: Styles().fontFamilies.regular),
                height: null,
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

                icon: Image.asset(
                    'images/icon-down-orange.png'),
                isExpanded: true,
                style: TextStyle(
                    color: Styles().colors.mediumGray,
                    fontSize: 16,
                    fontFamily:
                    Styles().fontFamilies.regular),
                hint: Text(_selectedGeofence?.name??"Select Geofence",
                    style: TextStyle(color: Styles().colors.fillColorPrimary, fontSize: 16, fontFamily: Styles().fontFamilies.regular)
                ),
                items: _buildDropDownItems(),
                onChanged: _onDropDownValueChanged)),
    ));

  }

  List<DropdownMenuItem<dynamic>> _buildDropDownItems() {
    int categoriesCount = _geoFenceRegions?.length ?? 0;
    if (categoriesCount == 0) {
      return null;
    }
    return _geoFenceRegions.map((GeoFenceRegion geofence) {
      return DropdownMenuItem<dynamic>(
        value: geofence,
        child: BlockSemantics(blocking: true, child:
        Semantics(label:geofence?.name,
          hint: Localization().getStringEx("panel.create_stadium_poll.geofence_choser_option.hint","Double tap to select region"),
          excludeSemantics: true, button:false,child:
          Text(
            geofence?.name,
            style: TextStyle(color: Styles().colors.fillColorPrimary, fontSize: 16, fontFamily: Styles().fontFamilies.regular)
        ),
      )));
    }).toList();
  }

  _onDropDownValueChanged(dynamic value){
    Analytics.instance.logSelect(target: "Geofence selected: $value");
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
            hint: Localization().getStringEx("panel.create_stadium_poll.hint.question", "Ask people near you…"),
            textController: _questionController,
            maxLength: 120,
            height: 120,
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
      for (int i = 0; i < _optionsControllers.length; i++) {
        TextEditingController controller = _optionsControllers[i];
        String title = Localization().getStringEx("panel.create_stadium_poll.text.option", "OPTION") + " " + (i + 1).toString();
        options.add(PollOptionView(title: title, textController: controller, enabled: (_progressPollStatus == null),));
      }

      if (_optionsControllers.length < _maxOptionsCount)
        options.add(_constructAddOptionButton());
      else
        options.add(Container(
          height: 24,
        ));
    }

    return options;
  }

  Widget _constructAddOptionButton() {
    String label = Localization().getStringEx("panel.create_stadium_poll.button.add_option.text", "Add option");
    String hint = Localization().getStringEx("panel.create_stadium_poll.button.add_option.hint", "");
    return Container(
      padding: EdgeInsets.symmetric(vertical: 24),
      alignment: Alignment.centerRight,
      child: Semantics(
          label: label,
          hint: hint,
          button: true,
          excludeSemantics: true,
          child: InkWell(
              onTap: () {
                if (_progressPollStatus == null) {
                  _optionsControllers.add(TextEditingController());
                  setState(() {});
                }
              },
              child: Container(
                  padding: EdgeInsets.symmetric(vertical: 5, horizontal: 15),
                  decoration: BoxDecoration(
                    color: Styles().colors.white,
                    border: Border.all(color: Styles().colors.fillColorSecondary, width: 2.0),
                    borderRadius: BorderRadius.circular(24.0),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
                    Text(
                      label,
                      style: TextStyle(
                        fontFamily: Styles().fontFamilies.bold,
                        fontSize: 16,
                        color: Styles().colors.fillColorPrimary,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: 5),
                      child: Image.asset('images/icon-add-14x14.png'),
                    )
                  ])))),
    );
  }

  Widget _buildSettingsHeader() {
    String additionalSettingsText = Localization().getStringEx("panel.create_poll.text.add_option", "Additional settings");
    return Padding(
        padding: EdgeInsets.only(top: 3),
        child: Container(
            color: Styles().colors.background,
            child: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 26),
                child: Semantics( label: additionalSettingsText, excludeSemantics: true, child:
                Container(
                  child: Row(
                    children: <Widget>[
                      Image.asset('images/icon-settings.png'),
                      Padding(
                        padding: EdgeInsets.only(left: 10),
                        child: Text(additionalSettingsText, style: TextStyle(color: Styles().colors.fillColorPrimary, fontSize: 16, fontFamily: Styles().fontFamilies.bold),
                        ),
                      )
                    ],
                  ),
                ),
                ))));
  }

  Widget _buildSettingsList() {
    return Container(
        color: Styles().colors.background,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Container(
              child: Column(
                children: _buildSettingsButtons(),
              )),
        ));
  }

  List<Widget> _buildSettingsButtons() {
    TextStyle _textStyle = TextStyle(color: Styles().colors.fillColorPrimary, fontSize: 16, fontFamily: Styles().fontFamilies.medium);
    BorderRadius rounding = BorderRadius.all(Radius.circular(5));
    List<Widget> widgets =  [];

    widgets.add(ToggleRibbonButton(
        label: Localization().getStringEx("panel.create_stadium_poll.setting.multy_choice", "Allow selecting more than one choice"),
        toggled: _selectedMultichoice,
        context: context,
        borderRadius: rounding,
        style: _textStyle,
        height: null,
        onTap: () {
          if (_progressPollStatus == null) {
            setState(() {
              _selectedMultichoice = !_selectedMultichoice;
            });
          }
        }));
    widgets.add(Container(
      height: 16,
    ));
    widgets.add(ToggleRibbonButton(
        label: Localization().getStringEx("panel.create_stadium_poll.setting.repeat_vote", "Allow repeat votes"),
        toggled: _selectedRepeatVotes,
        context: context,
        borderRadius: rounding,
        style: _textStyle,
        height: null,
        onTap: () {
          if (_progressPollStatus == null) {
            setState(() {
              _selectedRepeatVotes = !_selectedRepeatVotes;
            });
          }
        }));
    widgets.add(Container(
      height: 16,
    ));
    widgets.add(ToggleRibbonButton(
        label: Localization().getStringEx("panel.create_stadium_poll.setting.hide_result", "Hide results until poll ends"),
        toggled: _selectedHideResult,
        context: context,
        borderRadius: rounding,
        style: _textStyle,
        height: null,
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
                    child: Stack(children: <Widget>[
                      RoundedButton(
                        label: Localization().getStringEx("panel.create_stadium_poll.setting.button.save.title", "Save"),
                        backgroundColor: Colors.white,
                        borderColor: Styles().colors.fillColorPrimary,
                        textColor: Styles().colors.fillColorPrimary,
                        onTap: () {
                          _onCreatePoll(status: PollStatus.created);
                        },
                        height: 48,
                      ),
                      Visibility(visible: (_progressPollStatus == PollStatus.created),
                        child: Container(
                          height: 48,
                          child: Align(alignment: Alignment.center,
                            child: SizedBox(height: 24, width: 24,
                                child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Styles().colors.fillColorPrimary), )
                            ),
                          ),
                        ),
                      ),
                    ],),
                  ),
                  Container(
                    width: 6,
                  ),
                  Expanded(
                    child: Stack(children: <Widget>[
                      RoundedButton(
                        label: Localization().getStringEx("panel.create_stadium_poll.setting.start.preview.title", "Start poll!"),
                        backgroundColor: Colors.white,
                        borderColor: Styles().colors.fillColorSecondary,
                        textColor: Styles().colors.fillColorPrimary,
                        onTap: () {
                          _onCreatePoll(status: PollStatus.opened);
                        },
                        height: 48,
                      ),
                      Visibility(visible: (_progressPollStatus == PollStatus.opened),
                        child: Container(
                          height: 48,
                          child: Align(alignment: Alignment.center,
                            child: SizedBox(height: 24, width: 24,
                                child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Styles().colors.fillColorPrimary), )
                            ),
                          ),
                        ),
                      ),
                    ],),
                  ),
                ],
              )),
        ));
  }

  _onTapCancel() {
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
                    style: TextStyle(fontSize: 24, color: Colors.black),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 26),
                    child: Text(
                      Localization().getStringEx("panel.create_stadium_poll.cancel_dialog.message", "Are you sure you want to cancel this Stadium Poll"),
                      textAlign: TextAlign.left,
                      style: TextStyle(fontFamily: Styles().fontFamilies.medium, fontSize: 16, color: Colors.black),
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

  void _onCreatePoll({PollStatus status}) {
    String validationErrorMsg = _getValidationErrorMsg();
    if (AppString.isStringNotEmpty(validationErrorMsg)) {
      AppAlert.showDialogResult(context, validationErrorMsg);
      return;
    }
    else if (_progressPollStatus == null) {
      //Options
      List<String> options = [];
      if(_optionsControllers?.isNotEmpty??false){
        for(TextEditingController optionController in _optionsControllers){
          options.add(optionController?.text?.toString());
        }
      }

      //Poll
      Poll poll = Poll(
        title: _questionController?.text?.toString(),
        options: options,
        settings: PollSettings(
          allowMultipleOptions: _selectedMultichoice,
          hideResultsUntilClosed: _selectedHideResult,
          allowRepeatOptions: _selectedRepeatVotes,
          geoFence: _selectedGeofenceResult,
        ),
        creatorUserUuid: _selectedGeofence?.id,
        creatorUserName: _selectedGeofence?.name, /*Auth2().user?.uiucAccount?.fullName,*/
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
        Log.e(e?.toString() ?? 'Unknown error occured');
        AppAlert.showDialogResult(context, Localization().getStringEx('panel.create_stadium_poll.error.create_poll_failed.text', 'Failed to create stadium poll.'));
      }).whenComplete(() {
        setState(() {
          _progressPollStatus = null;
        });
      });
    }
  }

  ///Returns non-empty user friendly string when not valid, null - otherwise
  String _getValidationErrorMsg() {
    if (_selectedGeofence == null) {
      return Localization().getStringEx('panel.create_stadium_poll.not_valid.geofence.msg', "Please, select value for Geofence!");
    }
    if (AppString.isStringEmpty(_questionController?.text)) {
      return Localization().getStringEx('panel.create_stadium_poll.not_valid.question.msg', "Please, fill value for 'Question'!");
    }
    if (AppCollection.isCollectionNotEmpty(_optionsControllers)) {
      for (TextEditingController optionController in _optionsControllers) {
        if (AppString.isStringEmpty(optionController.text?.toString())) {
          return Localization().getStringEx('panel.create_stadium_poll.not_valid.option.msg', "Please, provide value for each option!");
        }
      }
    }
    return null;
  }
}