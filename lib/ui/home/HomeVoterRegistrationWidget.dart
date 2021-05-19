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
import 'package:illinois/model/GeoFence.dart';
import 'package:illinois/model/Voter.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/AppLivecycle.dart';
import 'package:illinois/service/Assets.dart';
import 'package:illinois/service/GeoFence.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/NotificationService.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/service/User.dart';
import 'package:illinois/service/Voter.dart';
import 'package:illinois/ui/WebPanel.dart';
import 'package:illinois/ui/widgets/RoundedButton.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:illinois/service/Styles.dart';
import 'package:sprintf/sprintf.dart';

class HomeVoterRegistrationWidget extends StatefulWidget {
  @override
  _HomeVoterRegistrationWidgetState createState() => _HomeVoterRegistrationWidgetState();
}

class _HomeVoterRegistrationWidgetState extends State<HomeVoterRegistrationWidget> implements NotificationsListener {
  bool _hiddenByUser = false;
  VoterRule _voterRule;
  bool _nrvPlaceVisible = false;
  Map<String, dynamic> _stringsContent;

  @override
  void initState() {
    NotificationService().subscribe(this, [AppLivecycle.notifyStateChanged, User.notifyVoterUpdated, GeoFence.notifyCurrentRegionsUpdated, Assets.notifyChanged]);
    _loadAssetsStrings();
    _loadVoterRule();
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool voterWidgetVisible = _isVoterWidgetVisible();
    String voterTitle = _getVoterTitle(voterWidgetVisible);
    String voterText = _getVoterText(voterWidgetVisible);
    String vbmKey = AppString.getDefaultEmptyString(value: _voterRule?.vbmText);
    String vbmText = Localization().getStringFromKeyMapping(vbmKey, _stringsContent);
    bool vbmVisible = User().isVoterRegistered && (User().isVoterByMail == null) && AppString.isStringNotEmpty(vbmKey);
    bool closeBtnVisible = !(_voterRule?.electionPeriod ?? false);
    String vbmButtonTitleKey = AppString.getDefaultEmptyString(value: _voterRule?.vbmButtonTitle);
    String vbmButtonTitle = Localization().getStringFromKeyMapping(vbmButtonTitleKey, _stringsContent);
    return Visibility(
      visible: voterWidgetVisible,
      child: Container(
        color: Styles().colors.background,
        padding: EdgeInsets.only(left: 16, top: 12, right: 12, bottom: 24),
        child: Semantics(container: true,child:Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: 4, top: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      voterTitle,
                      style: TextStyle(color: Styles().colors.fillColorPrimary, fontFamily: Styles().fontFamilies.extraBold, fontSize: 20, ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 8, bottom: 16),
                      child: Visibility(visible: AppString.isStringNotEmpty(voterText), child: Text(
                        voterText,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 10,
                        style: TextStyle(color: Color(0xff494949), fontFamily: Styles().fontFamilies.medium, fontSize: 16,),
                      ),),
                    )
                  ],
                ),
              ),
            ),
            // 'Close' button is visible by default unless specified other in the json
            Visibility(visible: closeBtnVisible, child: Semantics(
              label: Localization().getStringFromKeyMapping('widget.voter.button.close.label', _stringsContent, defaults: 'Close'),
              excludeSemantics: true,
              button: true,
              child: GestureDetector(
                child: Image.asset('images/close-orange.png'),
                onTap: _hideByUser,
              ),
            ),)
          ],
        ),
          Wrap(runSpacing: 8, spacing: 16, children: _getButtonOptions(voterWidgetVisible),),
          Visibility(visible: vbmVisible, child: Padding(padding: EdgeInsets.only(left: 4), child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Semantics(label: vbmText, child: Padding(
                padding: EdgeInsets.only(top: 32, bottom: 16),
                child: Text(
                  vbmText,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 10,
                  style: TextStyle(fontSize: 16, color: Styles().colors.textBackground, fontFamily: Styles().fontFamilies.regular),
                ),
              )),
              Row(children: <Widget>[RoundedButton(
                label: vbmButtonTitle,
                padding: EdgeInsets.symmetric(horizontal: 16),
                textColor: Styles().colors.fillColorPrimary,
                borderColor: Styles().colors.fillColorSecondary,
                backgroundColor: Styles().colors.white,
                onTap: () => _onTapVbmButton(vbmButtonTitle),
              )
              ],)
            ],
          ),),)
        ],)),
      ),
    );
  }

  void _loadVoterRule() {
    _voterRule = Voter().getVoterRuleForToday();
  }

  void _reloadVoterRule() {
    setState(() {
      _loadVoterRule();
    });
  }

  void _loadAssetsStrings() {
    _stringsContent = Assets()['voter.strings'];
  }

  void _reloadAssetsStrings() {
    setState(() {
      _loadAssetsStrings();
    });
  }

  void _hideByUser() {
    Analytics.instance.logSelect(target: "Voter Registration: Close");
    if (_voterRule?.hideForPeriod ?? false) {
      Storage().voterHiddenForPeriod = true;
    }
    setState(() {
      _hiddenByUser = true;
    });
  }

  bool _isVoterWidgetVisible() {
    if (_hiddenByUser) {
      return false;
    }
    if (AppString.isStringEmpty(_voterRule?.nrvText) && AppString.isStringEmpty(_voterRule?.rvText)) {
      return false;
    }
    if ((_voterRule?.hideForPeriod ?? false) && Storage().voterHiddenForPeriod) {
      return false;
    }
    bool isElectionPeriod = (_voterRule?.electionPeriod ?? false);
    if (isElectionPeriod && User().didVote) {
      return false;
    }
    if (!isElectionPeriod && (User().isVoterRegistered && (User().votePlace == _getPlaceToString(_VotePlace.Elsewhere)))) {
      return false;
    }
    if (!isElectionPeriod && (User().isVoterRegistered && (User().isVoterByMail == true || User().isVoterByMail == false))) {
      return false;
    }
    return true;
  }

  String _getVoterTitle(bool voterWidgetVisible) {
    if (!voterWidgetVisible) {
      return '';
    }
    if (_nrvPlaceVisible) {
      return Localization().getStringFromKeyMapping(_voterRule.nrvPlaceTitle, _stringsContent, defaults: 'Where do you want to vote?');
    }
    if (!User().isVoterRegistered) {
      return Localization().getStringFromKeyMapping(_voterRule.nrvTitle, _stringsContent, defaults: 'Are you registered to vote?');
    }
    if (User().isVoterRegistered && (User().votePlace == null)) {
      return Localization().getStringFromKeyMapping(_voterRule.rvPlaceTitle, _stringsContent, defaults: 'Where are you registered to vote?');
    }
    if (User().isVoterByMail == null) {
      return Localization().getStringFromKeyMapping(_voterRule.rvTitle, _stringsContent);
    }
    if ((_voterRule?.electionPeriod ?? false) && !User().didVote) {
      return Localization().getStringFromKeyMapping(_voterRule.rvTitle, _stringsContent);
    }
    return '';
  }

  String _getVoterText(bool voterWidgetVisible) {
    if (!voterWidgetVisible) {
      return "";
    }
    if (_nrvPlaceVisible) {
      return "";
    }
    if (!User().isVoterRegistered) {
      return Localization().getStringFromKeyMapping(_voterRule.nrvText, _stringsContent, defaults: 'Register online to vote for the 2020 General Primary Election on Tuesday, March 17th!');
    }
    if (User().isVoterRegistered && (User().votePlace == null)) {
      return "";
    }
    if (User().isVoterByMail == null) {
      return Localization().getStringFromKeyMapping(_voterRule.rvText, _stringsContent);
    }
    if ((_voterRule?.electionPeriod ?? false) && !User().didVote) {
      return Localization().getStringFromKeyMapping(_voterRule.rvText, _stringsContent);
    }
    return "";
  }

  List<Widget> _getButtonOptions(bool voterWidgetVisible) {
    List<Widget> optionWidgets = [];
    if (voterWidgetVisible) {
      List<RuleOption> voterOptions;
      if (_nrvPlaceVisible) {
        voterOptions = _voterRule.nrvPlaceOptions;
      } else if (!User().isVoterRegistered) {
        voterOptions = _voterRule.nrvOptions;
      } else if (User().isVoterRegistered && (User().votePlace == null)) {
        voterOptions = _voterRule.rvPlaceOptions;
      } else if (User().isVoterByMail == null) {
        voterOptions = _voterRule.rvOptions;
      } else if ((_voterRule?.electionPeriod ?? false) && !User().didVote) {
        voterOptions = _voterRule.rvOptions;
      }
      if (AppCollection.isCollectionNotEmpty(voterOptions)) {
        for (RuleOption ruleOption in voterOptions) {
          if (ruleOption.value == 'vbm_no') { // Special case for showing two widgets
            optionWidgets.add(Row(mainAxisSize: MainAxisSize.max, mainAxisAlignment: MainAxisAlignment.start, children: <Widget>[RoundedButton(
              label: Localization().getStringFromKeyMapping(ruleOption.label, _stringsContent),
              padding: EdgeInsets.symmetric(horizontal: 14),
              textColor: Styles().colors.fillColorPrimary,
              borderColor: Styles().colors.fillColorSecondary,
              backgroundColor: Styles().colors.white,
              onTap: () => _onTapButtonOption(ruleOption),
            ), Expanded(child: Padding(padding: EdgeInsets.only(left: 8),
              child: Text(Localization().getStringFromKeyMapping('widget.voter.option.descr.vote_in_person', _stringsContent, defaults: 'I want to vote in person'), overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                  style: TextStyle(fontSize: 16, color: Styles().colors.textBackground, fontFamily: Styles().fontFamilies.regular)),),)
            ],));
          } else {
            optionWidgets.add(Row(mainAxisSize: MainAxisSize.min, children: <Widget>[RoundedButton(
              label: Localization().getStringFromKeyMapping(ruleOption.label, _stringsContent),
              padding: EdgeInsets.symmetric(horizontal: 14),
              textColor: Styles().colors.fillColorPrimary,
              borderColor: Styles().colors.fillColorSecondary,
              backgroundColor: Styles().colors.white,
              onTap: () => _onTapButtonOption(ruleOption),
            ),
            ],));
          }
        }
      }
    }
    return optionWidgets;
  }

  void _onTapButtonOption(RuleOption ruleOption) {
    if (ruleOption == null) {
      return;
    }
    Analytics.instance.logSelect(target: "Voter Registration: ${Localization().getStringFromKeyMapping(ruleOption.label, _stringsContent)}");
    switch (ruleOption.value) {
      case 'rv_yes':
        User().updateVoterRegistration(registeredVoter: true);
        break;
      case 'nrv_place':
        _showNrvPlaces(true);
        break;
      case 'vbm_yes':
        User().updateVoterByMail(voterByMail: true);
        break;
      case 'vbm_no':
        User().updateVoterByMail(voterByMail: false);
        break;
      case 'rv_url':
        Navigator.push(context, CupertinoPageRoute(builder: (context) => WebPanel(url: _voterRule.rvUrl)));
        break;
      case 'v_yes':
        User().updateVoted(voted: true);
        break;
      case 'champaign':
        User().updateVotePlace(votePlace: _getPlaceToString(_VotePlace.Champaign));
        break;
      case 'elsewhere':
        User().updateVotePlace(votePlace: _getPlaceToString(_VotePlace.Elsewhere));
        break;
      default:
        if (AppString.isStringNotEmpty(ruleOption.value)) {
          Navigator.push(context, CupertinoPageRoute(builder: (context) => WebPanel(url: ruleOption.value))).then((_) {
            _showNrvPlaces(false);
          });
        }
        break;
    }
  }

  void _onTapVbmButton(String vbmButtonTitle) {
    Analytics.instance.logSelect(target: "Vote By Mail: ${AppString.getDefaultEmptyString(value: vbmButtonTitle)}");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => WebPanel(url: _voterRule?.vbmUrl)));
  }

  void _showRegionAlertIfNeeded() {
    if (_voterRule == null) {
      return;
    }
    Set<String> currentRegionIds = GeoFence().currentRegionIds;
    if (AppCollection.isCollectionEmpty(currentRegionIds)) {
      return;
    }
    List<GeoFenceRegion> voterRegions = GeoFence().regionsList(type: 'voter', enabled: true);
    if (AppCollection.isCollectionEmpty(voterRegions)) {
      return;
    }
    String currentVoterRegionName;
    for (GeoFenceRegion region in voterRegions) {
      if (currentRegionIds.contains(region.id)) {
        currentVoterRegionName = region.name;
        break;
      }
    }
    if (AppString.isStringEmpty(currentVoterRegionName)) {
      return;
    }
    String alertFormat;
    if (!User().isVoterRegistered) {
      alertFormat = Localization().getStringFromKeyMapping(_voterRule.nrvAlert, _stringsContent);
    } else if (!User().didVote) {
      alertFormat = Localization().getStringFromKeyMapping(_voterRule.rvAlert, _stringsContent);
    }
    if (AppString.isStringEmpty(alertFormat)) {
      return;
    }
    String enteredRegionMsg = sprintf(alertFormat, [currentVoterRegionName]);
    AppAlert.showDialogResult(context, enteredRegionMsg);
  }

  void _showNrvPlaces(bool show) {
    setState(() {
      _nrvPlaceVisible = show;
    });
  }

  static String _getPlaceToString(_VotePlace place) {
    if (place == _VotePlace.Champaign) {
      return 'champaign';
    } else if (place == _VotePlace.Elsewhere) {
      return 'elsewhere';
    } else {
      return null;
    }
  }

  // NotificationsListener

  @override
  void onNotification(String name, param) {
    if (name == User.notifyVoterUpdated) {
      _reloadVoterRule();
    } else if (name == AppLivecycle.notifyStateChanged && AppLifecycleState.resumed == param) {
      _reloadVoterRule();
    } else if (name == Assets.notifyChanged) {
      _reloadAssetsStrings();
      _reloadVoterRule();
    } else if(name == GeoFence.notifyCurrentRegionsUpdated) {
      _showRegionAlertIfNeeded();
    }
  }
}

enum _VotePlace { Champaign, Elsewhere }

