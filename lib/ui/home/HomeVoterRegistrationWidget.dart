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

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/AppDateTime.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/model/geo_fence.dart';
import 'package:illinois/model/Voter.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/content.dart';
import 'package:rokwire_plugin/service/geo_fence.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/ui/WebPanel.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:sprintf/sprintf.dart';

class HomeVoterRegistrationWidget extends StatefulWidget {
  final String? favoriteId;
  final StreamController<String>? updateController;

  HomeVoterRegistrationWidget({Key? key, this.favoriteId, this.updateController}) : super(key: key);

  @override
  _HomeVoterRegistrationWidgetState createState() => _HomeVoterRegistrationWidgetState();
}

class _HomeVoterRegistrationWidgetState extends State<HomeVoterRegistrationWidget> implements NotificationsListener {
  bool _hiddenByUser = false;
  VoterRule? _voterRule;
  bool _nrvPlaceVisible = false;
  bool _loading = false;
  List<VoterRule>? _voterRules;
  Map<String, dynamic>? _stringsContent;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      AppLivecycle.notifyStateChanged,
      Auth2UserPrefs.notifyVoterChanged,
      GeoFence.notifyCurrentRegionsUpdated
    ]);
    
    _loading = true;
    Content().loadContentItem('voter').then((dynamic value) {
      setStateIfMounted(() {
        Map<String, dynamic>? voterJson = JsonUtils.mapValue(value);
        _voterRules = (voterJson != null) ? VoterRule.listFromJson(JsonUtils.listValue(voterJson['rules'])) : null;
        _stringsContent = (voterJson != null) ? JsonUtils.mapValue(voterJson['strings']) : null;
        _voterRule = VoterRule.getVoterRuleForToday(_voterRules, _uniLocalTime);
        _loading = false;
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _loading ? _buildLoadingContent() : _buildVoterContent();

  Widget _buildVoterContent() {
    bool voterWidgetVisible = _isVoterWidgetVisible();
    String voterTitle = _getVoterTitle(voterWidgetVisible)!;
    String voterText = _getVoterText(voterWidgetVisible)!;
    String? vbmKey = StringUtils.ensureNotEmpty(_voterRule?.vbmText);
    String vbmText = Localization().getStringFromKeyMapping(vbmKey, _stringsContent)!;
    bool vbmVisible = Auth2().isVoterRegistered && (Auth2().isVoterByMail == null) && StringUtils.isNotEmpty(vbmKey);
    bool closeBtnVisible = !(_voterRule?.electionPeriod ?? false);
    String? vbmButtonTitleKey = StringUtils.ensureNotEmpty(_voterRule?.vbmButtonTitle);
    String? vbmButtonTitle = Localization().getStringFromKeyMapping(vbmButtonTitleKey, _stringsContent);
    return Visibility(
      visible: voterWidgetVisible,
      child: Container(
        color: Styles().colors!.background,
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
                      style: Styles().textStyles?.getTextStyle("widget.title.large.extra_fat"),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 8, bottom: 16),
                      child: Visibility(visible: StringUtils.isNotEmpty(voterText), child: Text(
                        voterText,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 10,
                        style: Styles().textStyles?.getTextStyle("widget.detail.variant.regular"),
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
                child: Styles().images?.getImage('close', excludeFromSemantics: true),
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
                  style: Styles().textStyles?.getTextStyle("widget.item.regular.thin"),
                ),
              )),
              Row(children: <Widget>[RoundedButton(
                label: vbmButtonTitle ?? '',
                textStyle: Styles().textStyles?.getTextStyle("widget.button.title.large.fat"),
                borderColor: Styles().colors!.fillColorSecondary,
                backgroundColor: Styles().colors!.white,
                contentWeight: 0.0,
                onTap: () => _onTapVbmButton(vbmButtonTitle),
              )
              ],)
            ],
          ),),)
        ],)),
      ),
    );
  }

  Widget _buildLoadingContent() => Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 32), child:
    Center(child:
      SizedBox(width: 32, height: 32, child:
        CircularProgressIndicator(color: Styles().colors?.fillColorSecondary, strokeWidth: 3,),
      ),
    ),
  );

  void _reloadVoterRule() {
    setStateIfMounted(() {
      _voterRule = VoterRule.getVoterRuleForToday(_voterRules, _uniLocalTime);
    });
  }

  void _hideByUser() {
    Analytics().logSelect(target: "Close", source: widget.runtimeType.toString());
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
    if (StringUtils.isEmpty(_voterRule?.nrvText) && StringUtils.isEmpty(_voterRule?.rvText)) {
      return false;
    }
    if ((_voterRule?.hideForPeriod ?? false) && (Storage().voterHiddenForPeriod == true)) {
      return false;
    }
    bool isElectionPeriod = (_voterRule?.electionPeriod ?? false);
    if (isElectionPeriod && Auth2().didVote) {
      return false;
    }
    if (!isElectionPeriod && (Auth2().isVoterRegistered && (Auth2().votePlace == _getPlaceToString(_VotePlace.Elsewhere)))) {
      return false;
    }
    if (!isElectionPeriod && (Auth2().isVoterRegistered && (Auth2().isVoterByMail == true || Auth2().isVoterByMail == false))) {
      return false;
    }
    return true;
  }

  String? _getVoterTitle(bool voterWidgetVisible) {
    if (!voterWidgetVisible) {
      return '';
    }
    if (_nrvPlaceVisible) {
      return Localization().getStringFromKeyMapping(_voterRule!.nrvPlaceTitle, _stringsContent, defaults: 'Where do you want to vote?');
    }
    if (!Auth2().isVoterRegistered) {
      return Localization().getStringFromKeyMapping(_voterRule!.nrvTitle, _stringsContent, defaults: 'Are you registered to vote?');
    }
    if (Auth2().isVoterRegistered && (Auth2().votePlace == null)) {
      return Localization().getStringFromKeyMapping(_voterRule!.rvPlaceTitle, _stringsContent, defaults: 'Where are you registered to vote?');
    }
    if (Auth2().isVoterByMail == null) {
      return Localization().getStringFromKeyMapping(_voterRule!.rvTitle, _stringsContent);
    }
    if ((_voterRule?.electionPeriod ?? false) && !Auth2().didVote) {
      return Localization().getStringFromKeyMapping(_voterRule!.rvTitle, _stringsContent);
    }
    return '';
  }

  String? _getVoterText(bool voterWidgetVisible) {
    if (!voterWidgetVisible) {
      return "";
    }
    if (_nrvPlaceVisible) {
      return "";
    }
    if (!Auth2().isVoterRegistered) {
      return Localization().getStringFromKeyMapping(_voterRule!.nrvText, _stringsContent, defaults: 'Register online to vote for the 2020 General Primary Election on Tuesday, March 17th!');
    }
    if (Auth2().isVoterRegistered && (Auth2().votePlace == null)) {
      return "";
    }
    if (Auth2().isVoterByMail == null) {
      return Localization().getStringFromKeyMapping(_voterRule!.rvText, _stringsContent);
    }
    if ((_voterRule?.electionPeriod ?? false) && !Auth2().didVote) {
      return Localization().getStringFromKeyMapping(_voterRule!.rvText, _stringsContent);
    }
    return "";
  }

  List<Widget> _getButtonOptions(bool voterWidgetVisible) {
    List<Widget> optionWidgets = [];
    if (voterWidgetVisible) {
      List<RuleOption>? voterOptions;
      if (_nrvPlaceVisible) {
        voterOptions = _voterRule!.nrvPlaceOptions;
      } else if (!Auth2().isVoterRegistered) {
        voterOptions = _voterRule!.nrvOptions;
      } else if (Auth2().isVoterRegistered && (Auth2().votePlace == null)) {
        voterOptions = _voterRule!.rvPlaceOptions;
      } else if (Auth2().isVoterByMail == null) {
        voterOptions = _voterRule!.rvOptions;
      } else if ((_voterRule?.electionPeriod ?? false) && !Auth2().didVote) {
        voterOptions = _voterRule!.rvOptions;
      }
      if (CollectionUtils.isNotEmpty(voterOptions)) {
        for (RuleOption ruleOption in voterOptions!) {
          if (ruleOption.value == 'vbm_no') { // Special case for showing two widgets
            optionWidgets.add(Row(mainAxisSize: MainAxisSize.max, mainAxisAlignment: MainAxisAlignment.start, children: <Widget>[RoundedButton(
              label: Localization().getStringFromKeyMapping(ruleOption.label, _stringsContent) ?? '',
              textStyle: Styles().textStyles?.getTextStyle("widget.button.title.large.fat"),
              borderColor: Styles().colors!.fillColorSecondary,
              backgroundColor: Styles().colors!.white,
              contentWeight: 0.0,
              onTap: () => _onTapButtonOption(ruleOption),
            ), Expanded(child: Padding(padding: EdgeInsets.only(left: 8),
              child: Text(Localization().getStringFromKeyMapping('widget.voter.option.descr.vote_in_person', _stringsContent, defaults: 'I want to vote in person')!, overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                  style: Styles().textStyles?.getTextStyle("widget.item.regular.thin")),),)
            ],));
          } else {
            optionWidgets.add(Row(mainAxisSize: MainAxisSize.min, children: <Widget>[RoundedButton(
              label: Localization().getStringFromKeyMapping(ruleOption.label, _stringsContent) ?? '',
              textStyle: Styles().textStyles?.getTextStyle("widget.button.title.large.fat"),
              borderColor: Styles().colors!.fillColorSecondary,
              backgroundColor: Styles().colors!.white,
              contentWeight: 0.0,
              onTap: () => _onTapButtonOption(ruleOption),
            ),
            ],));
          }
        }
      }
    }
    return optionWidgets;
  }

  void _onTapButtonOption(RuleOption? ruleOption) {
    if (ruleOption == null) {
      return;
    }
    Analytics().logSelect(target: "${Localization().getStringFromKeyMapping(ruleOption.label, _stringsContent)}", source: widget.runtimeType.toString());
    switch (ruleOption.value) {
      case 'rv_yes':
        Auth2().prefs?.voter?.registeredVoter = true;
        break;
      case 'nrv_place':
        _showNrvPlaces(true);
        break;
      case 'vbm_yes':
        Auth2().prefs?.voter?.voterByMail = true;
        break;
      case 'vbm_no':
        Auth2().prefs?.voter?.voterByMail = false;
        break;
      case 'rv_url':
        Navigator.push(context, CupertinoPageRoute(builder: (context) => WebPanel(url: _voterRule!.rvUrl)));
        break;
      case 'v_yes':
        Auth2().prefs?.voter?.voted = true;
        break;
      case 'champaign':
        Auth2().prefs?.voter?.votePlace = _getPlaceToString(_VotePlace.Champaign);
        break;
      case 'elsewhere':
        Auth2().prefs?.voter?.votePlace = _getPlaceToString(_VotePlace.Elsewhere);
        break;
      default:
        if (StringUtils.isNotEmpty(ruleOption.value)) {
          Navigator.push(context, CupertinoPageRoute(builder: (context) => WebPanel(url: ruleOption.value))).then((_) {
            _showNrvPlaces(false);
          });
        }
        break;
    }
  }

  void _onTapVbmButton(String? vbmButtonTitle) {
    Analytics().logSelect(target: "Vote By Mail: ${StringUtils.ensureNotEmpty(vbmButtonTitle)}", source: widget.runtimeType.toString());
    Navigator.push(context, CupertinoPageRoute(builder: (context) => WebPanel(url: _voterRule?.vbmUrl)));
  }

  void _showRegionAlertIfNeeded() {
    if (_voterRule == null) {
      return;
    }
    Set<String> currentRegionIds = GeoFence().currentRegionIds;
    if (CollectionUtils.isEmpty(currentRegionIds)) {
      return;
    }
    List<GeoFenceRegion> voterRegions = GeoFence().regionsList(type: 'voter', enabled: true);
    if (CollectionUtils.isEmpty(voterRegions)) {
      return;
    }
    String? currentVoterRegionName;
    for (GeoFenceRegion region in voterRegions) {
      if (currentRegionIds.contains(region.id)) {
        currentVoterRegionName = region.name;
        break;
      }
    }
    if (StringUtils.isEmpty(currentVoterRegionName)) {
      return;
    }
    String? alertFormat;
    if (!Auth2().isVoterRegistered) {
      alertFormat = Localization().getStringFromKeyMapping(_voterRule!.nrvAlert, _stringsContent);
    } else if (!Auth2().didVote) {
      alertFormat = Localization().getStringFromKeyMapping(_voterRule!.rvAlert, _stringsContent);
    }
    if (StringUtils.isEmpty(alertFormat)) {
      return;
    }
    String? enteredRegionMsg = sprintf(alertFormat!, [currentVoterRegionName]);
    AppAlert.showDialogResult(context, enteredRegionMsg);
  }

  void _showNrvPlaces(bool show) {
    setState(() {
      _nrvPlaceVisible = show;
    });
  }

  static String? _getPlaceToString(_VotePlace place) {
    if (place == _VotePlace.Champaign) {
      return 'champaign';
    } else if (place == _VotePlace.Elsewhere) {
      return 'elsewhere';
    } else {
      return null;
    }
  }

  DateTime? get _uniLocalTime => AppDateTime().getUniLocalTimeFromUtcTime(AppDateTime().now.toUtc());

  // NotificationsListener

  @override
  void onNotification(String name, param) {
    if (name == Auth2UserPrefs.notifyVoterChanged) {
      _reloadVoterRule();
    } else if (name == AppLivecycle.notifyStateChanged && AppLifecycleState.resumed == param) {
      _reloadVoterRule();
    } else if(name == GeoFence.notifyCurrentRegionsUpdated) {
      _showRegionAlertIfNeeded();
    }
  }
}

enum _VotePlace { Champaign, Elsewhere }

