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
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:illinois/service/Events.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:illinois/ui/settings/SettingsManageInterestsPanel.dart';
import 'package:illinois/ui/widgets/RoundedButton.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/service/styles.dart';

class HomeInterestsSelectionWidget extends StatefulWidget {
  final StreamController<void>? refreshController;

  HomeInterestsSelectionWidget({this.refreshController});

  @override
  _HomeInterestsSelectionWidgetState createState() => _HomeInterestsSelectionWidgetState();
}

class _HomeInterestsSelectionWidgetState extends State<HomeInterestsSelectionWidget> implements NotificationsListener {
  List<String>? _randomInterests;
  List<String>? _allInterests;
  int _interestsCount = 3;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Connectivity.notifyStatusChanged,
      Auth2UserPrefs.notifyTagsChanged
    ]);

    if (widget.refreshController != null) {
      widget.refreshController!.stream.listen((_) {
        _loadAllInterests();
      });
    }

    _loadAllInterests();
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Container(
                alignment: Alignment.topLeft,
                color: Styles().colors!.white,
                child: Padding(
                    padding: EdgeInsets.only(left: 16, top: 16, right: 16, bottom: 19),
                    child: Column(children: [
                      Semantics(
                          label: Localization().getStringEx("widget.home.interest_selection.title", "What are you interested in?")! +
                              Localization().getStringEx("widget.home.interest_selection.description", "See events based on topics you chose")!,
                          header: true,
                          excludeSemantics: true,
                          child: Column(children: [
                            Container(
                              width: double.infinity,
                              child: Text(
                                Localization().getStringEx("widget.home.interest_selection.title", "What are you interested in?")!,
                                style: TextStyle(fontSize: 18, color: Styles().colors!.fillColorPrimary, fontFamily: Styles().fontFamilies!.extraBold),
                              ),
                            ),
                            Container(
                              width: double.infinity,
                              child: Text(
                                Localization().getStringEx("widget.home.interest_selection.description", "See events based on topics you chose")!,
                                style: TextStyle(fontSize: 14, color: Styles().colors!.textBackground, fontFamily: Styles().fontFamilies!.regular),
                              ),
                            ),
                          ])),
                      GridView.count(
                          physics: NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          childAspectRatio: 2.5,
                          children: _buildInterestButtons())
                    ])))));
  }

  void _reloadRandomInterests(int count) {
    if (mounted) {
      setState(() {
        _randomInterests = _loadRandomInterests(_interestsCount);
      });
    } else {
      _randomInterests = _loadRandomInterests(_interestsCount);
    }
  }

  void _loadAllInterests() async {
    if (Connectivity().isNotOffline) {
      Events().loadEventTags().then((List<String>? tagList) {
        if (mounted) {
          setState(() {
            _allInterests = tagList;
          });
        } else {
          _allInterests = tagList;
        }
        _reloadRandomInterests(_interestsCount);
      });
    }
  }

  List<String> _loadRandomInterests(int count) {
    List<String> result =  [];
    if (!CollectionUtils.isNotEmpty(_allInterests)) {
      print("loadRandomInterests allInterests empty");
      return result;
    }
    int max = _allInterests!.length - 1;
    while (result.length < count) {
      Random random = Random(DateTime.now().millisecondsSinceEpoch);
      int randomIndex = (random.nextInt(max));
      String interest = _allInterests![randomIndex];
      bool userContainsInterest = Auth2().prefs?.hasPositiveTag(interest) ?? false;
      bool resultContainsInterest = result.contains(interest);

      if (userContainsInterest || resultContainsInterest) {
        // Skip
        continue;
      }
      result.add(interest);
      continue;
    }
    return result;
  }

  List<Widget> _buildInterestButtons() {
    List<String>? interests = _randomInterests;
    List<Widget> result =  [];
    if (CollectionUtils.isNotEmpty(interests)) {
      interests!.forEach((String interest) {
        result.add(_buildInterestButton(interest));
      });
    }
    result.add(_buildInterestButton(Localization().getStringEx("widget.home.interest_selection.button.see_all", "See all"),
        borderColor: Styles().colors!.fillColorSecondary, onTap: () {
          _onSeeAllClicked();
        }));
    return result;
  }

  Widget _buildInterestButton(String? interest, {Color? borderColor, Function? onTap}) {
    return Padding(
        padding: EdgeInsets.only(top: 5, bottom: 5, right: 5),
        child: _HomeInterestButton(
          label: interest,
          borderColor: borderColor ?? Styles().colors!.surfaceAccent,
          onTap: onTap ??
                  () {
                _onInterestClicked(interest);
              },
        ));
  }

  void _onSeeAllClicked() {
    Analytics().logSelect(target: "HomeUpcomingEvents See all ");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => SettingsManageInterestsPanel()));
  }

  void _onInterestClicked(String? interest) {
    Analytics().logSelect(target: "HomeInterestsSelection interest: $interest");
    Auth2().prefs?.togglePositiveTag(interest);
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == Connectivity.notifyStatusChanged) {
      _loadAllInterests();
    } else if (name == Auth2UserPrefs.notifyInterestsChanged) {
      setState(() {
        _reloadRandomInterests(_interestsCount);
      });
    }
  }
}

class _HomeInterestButton extends RoundedButton {
  _HomeInterestButton({label, borderColor, onTap})
      : super(
      label: label,
      backgroundColor: Colors.white,
      borderColor: borderColor ?? Styles().colors!.surfaceAccent,
      textColor: Styles().colors!.fillColorPrimary,
      padding: EdgeInsets.symmetric(horizontal: 5),
      onTap: onTap);
}

