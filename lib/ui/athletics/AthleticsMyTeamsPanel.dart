/*
 * Copyright 2024 Board of Trustees of the University of Illinois.
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
import 'package:illinois/model/sport/SportDetails.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/service/Sports.dart';
import 'package:illinois/ui/widgets/LinkButton.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class AthleticsMyTeamsPanel extends StatefulWidget {

  AthleticsMyTeamsPanel._();

  @override
  _AthleticsMyTeamsPanelState createState() => _AthleticsMyTeamsPanelState();

  static void present(BuildContext context) {
    MediaQueryData mediaQuery = MediaQueryData.fromView(View.of(context));
    double height = mediaQuery.size.height - mediaQuery.viewPadding.top - mediaQuery.viewInsets.top - 16;
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        isDismissible: true,
        useRootNavigator: true,
        clipBehavior: Clip.antiAlias,
        backgroundColor: Styles().colors.background,
        constraints: BoxConstraints(maxHeight: height, minHeight: height),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
        builder: (context) {
          return AthleticsMyTeamsPanel._();
        });
  }
}

class _AthleticsMyTeamsPanelState extends State<AthleticsMyTeamsPanel> with NotificationsListener {
  List<SportDefinition>? _sports;
  Set<String>? _preferredSports;

  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, [Auth2UserPrefs.notifyInterestsChanged, FlexUI.notifyChanged]);
    _sports = Sports().sports;
    _preferredSports = Auth2().prefs?.sportsInterests ?? Set<String>();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
          color: Styles().colors.surface,
          child: Row(children: [
            Expanded(
                child: Padding(
                    padding: EdgeInsets.only(left: 16, top: 16, bottom: 16),
                    child: Text(Localization().getStringEx('panel.athletics.content.my_teams.header.title', 'My Big 10 Teams'),
                        style: Styles().textStyles.getTextStyle('widget.sheet.title.regular')))),
            Semantics(
                label: Localization().getStringEx('dialog.close.title', 'Close'),
                hint: Localization().getStringEx('dialog.close.hint', ''),
                inMutuallyExclusiveGroup: true,
                button: true,
                child: InkWell(
                    onTap: _onTapClose,
                    child: Container(
                        padding: EdgeInsets.only(left: 8, right: 16, top: 16, bottom: 16),
                        child: Styles().images.getImage('close-circle', excludeFromSemantics: true))))
          ])),
      Container(color: Styles().colors.surfaceAccent, height: 1),
      _buildGlobalSelectionContent(),
      Expanded(child: Padding(padding: EdgeInsets.all(16), child: _buildTeamsContent()))
    ]);
  }

  Widget _buildGlobalSelectionContent() {
    String label = CollectionUtils.isEmpty(_preferredSports)
        ? Localization().getStringEx('panel.athletics.content.my_teams.all.select.label', 'Select All')
        : Localization().getStringEx('panel.athletics.content.my_teams.all.clear.label', 'Clear All');
    return Row(children: [
      Expanded(child: Container()),
      LinkButton(onTap: _onTapAll, title: label, padding: EdgeInsets.only(left: 16, top: 16, right: 16))
    ]);
  }

  Widget _buildTeamsContent() {
    return ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Container(
            foregroundDecoration: BoxDecoration(
                border: Border.all(color: Styles().colors.surfaceAccent, width: 1.0), borderRadius: BorderRadius.circular(15)),
            child: SingleChildScrollView(child: Column(children: _buildTeams()))));
  }

  List<Widget> _buildTeams() {
    List<Widget> teamWidgets = [];

    if (_sports != null && _preferredSports != null) {
      for (SportDefinition team in _sports!) {
        if (CollectionUtils.isNotEmpty(teamWidgets)) {
          teamWidgets.add(Container(height: 1, color: Styles().colors.surfaceAccent));
        }

        String? teamShortName = StringUtils.ensureNotEmpty(team.shortName);
        String? teamName = StringUtils.ensureNotEmpty(team.name);
        teamWidgets.add(_SelectionItemWidget(
            label: teamName,
            selected: _preferredSports!.contains(teamShortName),
            onTap: () {
              Analytics().logSelect(target: 'Team: $teamShortName');
              AppSemantics.announceCheckBoxStateChange(context, _preferredSports!.contains(teamShortName), teamName);
              Auth2().prefs?.toggleSportInterest(team.shortName);
            }));
      }
    }
    return teamWidgets;
  }

  void _onTapClose() {
    Analytics().logSelect(target: 'Close', source: widget.runtimeType.toString());
    Navigator.of(context).pop();
  }

  void _onTapAll() {
    bool selectAll = CollectionUtils.isEmpty(_preferredSports);
    String analyticsTarget = selectAll
        ? Localization().getStringEx('panel.athletics.content.my_teams.all.select.label', 'Select All')
        : Localization().getStringEx('panel.athletics.content.my_teams.all.clear.label', 'Clear All');
    Analytics().logSelect(target: analyticsTarget, source: widget.runtimeType.toString());
    Iterable<String>? toggleSportNames;
    if (selectAll) {
      toggleSportNames = _sports?.map((sport) => sport.shortName!);
    } else {
      toggleSportNames = Set.from(_preferredSports!);
    }
    setStateIfMounted(() {
      Auth2().prefs?.toggleSportInterests(toggleSportNames);
    });
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == Auth2UserPrefs.notifyInterestsChanged) {
      setStateIfMounted(() {
        _preferredSports = Auth2().prefs?.sportsInterests ?? Set<String>();
      });
    } else if (name == FlexUI.notifyChanged) {
      setStateIfMounted(() {});
    }
  }
}

class _SelectionItemWidget extends StatelessWidget {
  final String? label;
  final GestureTapCallback? onTap;
  final bool? selected;

  _SelectionItemWidget({required this.label, this.onTap, this.selected = false});

  @override
  Widget build(BuildContext context) {
    return Semantics(
        label: label,
        value: (selected!
                ? Localization().getStringEx('toggle_button.status.checked', 'checked')
                : Localization().getStringEx('toggle_button.status.unchecked', 'unchecked')) +
            ", " +
            Localization().getStringEx('toggle_button.status.checkbox', 'checkbox'),
        excludeSemantics: true,
        child: GestureDetector(
            onTap: onTap,
            child: Container(
                color: Colors.white,
                child: Padding(
                    padding: EdgeInsets.all(10),
                    child: Row(mainAxisSize: MainAxisSize.max, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: <Widget>[
                      Flexible(
                          child: Text(StringUtils.ensureNotEmpty(label),
                              overflow: TextOverflow.ellipsis, style: Styles().textStyles.getTextStyle("widget.title.regular.fat"))),
                      Styles().images.getImage(selected! ? 'check-circle-filled' : 'check-circle-outline-gray') ?? Container()
                    ])))));
  }
}
