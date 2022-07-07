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
import 'package:illinois/model/wellness/WellnessReing.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/service/WellnessRings.dart';
import 'package:illinois/ui/wellness/rings/WellnessRingCreatePane.dart';
import 'package:illinois/ui/wellness/rings/WellnessRingWidgets.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/wellness/rings/WellnessRingSelectPredefinedPanel.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class WellnessRingsHomeContentWidget extends StatefulWidget {
  WellnessRingsHomeContentWidget();

  @override
  State<WellnessRingsHomeContentWidget> createState() => _WellnessRingsHomeContentWidgetState();
}

class _WellnessRingsHomeContentWidgetState extends State<WellnessRingsHomeContentWidget> implements NotificationsListener{

  late _WellnessRingsTab _selectedTab;
  List<WellnessRingDefinition>? _ringsData;

  @override
  void initState() {
    super.initState();
    _selectedTab = _WellnessRingsTab.today;
    NotificationService().subscribe(this, [
      WellnessRings.notifyUserRingsUpdated,
    ]);
    WellnessRings().loadWellnessRings().then((rings){
      _ringsData = rings;
      if(mounted) setState(() {});
    });
    if (Storage().isUserAccessedWellnessRings != true) {
      Storage().userAccessedWellnessRings = true;
      WidgetsBinding.instance!.addPostFrameCallback((_) {
        _showWelcomePopup();
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
    NotificationService().unsubscribe(this);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Container(height: 8,),
          WellnessWidgetHelper.buildWellnessHeader(),
          Container(height: 12,),
          _buildTabButtonRow(),
          _buildContent()
        ]));

  }

  Widget _buildTabButtonRow() {
    return Row(children: [
      Expanded(
          child: _TabButton(
              position: _TabButtonPosition.first,
              selected: (_selectedTab == _WellnessRingsTab.today),
              label: Localization().getStringEx('panel.wellness.rings.tab.daily.label', "Today's Rings"),
              hint: Localization().getStringEx('panel.wellness.rings.tab.daily.hint', ''),
              onTap: () => _onTabChanged(tab: _WellnessRingsTab.today))),
      Expanded(
          child: _TabButton(
              position: _TabButtonPosition.last,
              selected: (_selectedTab == _WellnessRingsTab.history),
              label: Localization().getStringEx('panel.wellness.rings.tab.history.label', 'Accomplishments'),
              hint: Localization().getStringEx('panel.wellness.rings.tab.history.hint', ''),
              onTap: () => _onTabChanged(tab: _WellnessRingsTab.history)))
    ]);
  }

  Widget _buildContent(){
    switch(_selectedTab){
      case _WellnessRingsTab.today : return _buildTodaysRingsContent();
      case _WellnessRingsTab.history : return _buildHistoryContent();
    }
  }

  Widget _buildHistoryContent(){
    return Container(
      child: Column(
        children: [
          Container(height: 20,),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Text(Localization().getStringEx('panel.wellness.rings.description.label', "See your recent progress in one place by checking your log for the lat 14 days."),
              style :TextStyle(color: Styles().colors!.textSurface!, fontFamily: Styles().fontFamilies!.regular, fontSize: 16),
          )),
          Container(height: 15,),
          _buildHistoryList(),
        ],
      )

    );
  }

  Widget _buildTodaysRingsContent(){
    return Container(
      child:
      Stack(children:[
        Column(
          children: [
            Container(height: 32,),
            WellnessRing(),
            Container(height: 28,),
            _buildButtons(),
            _buildCreateRingButton(),
            Container(height: 16,),
        ],
      ),
      ])
    );
  }

  Widget _buildHistoryList(){
    var historyData = WellnessRings().getAccomplishmentsHistory();
    List<Widget> content = [];
    if(historyData!=null && historyData.isNotEmpty){
      for(var accomplishmentsPerDay in historyData.entries) {
        content.add(AccomplishmentCard(date: accomplishmentsPerDay.key, accomplishments: accomplishmentsPerDay.value));
        content.add(Container(height: 15,));
      }
    }
    return Container(
      child: Column(
        children: content,
      ),
    );
  }

  Widget _buildButtons(){
    List<Widget> content = [];
    if(_ringsData != null && _ringsData!.isNotEmpty) {
      for (WellnessRingDefinition? definition  in _ringsData!) {
        if (definition != null) {
          content.add(WellnessRingButton(
              label: definition.name ?? "",
              color: definition.color,
              description: "${WellnessRings()
                  .getRingDailyValue(definition.id)
                  .toInt()}/${definition.goal.toInt()} ${definition.unit}s",
              onTapIncrease: (context) {
                WellnessRings().addRecord(
                    WellnessRingRecord(value: 1, dateCreatedUtc: DateTime.now(), wellnessRingId: definition.id));
              },
            onTapDecrease: (context) {
              WellnessRings().addRecord(
                  WellnessRingRecord(value: -1, dateCreatedUtc: DateTime.now(), wellnessRingId: definition.id));
            },
              onTapEdit: (context){
                Navigator.push(context, CupertinoPageRoute(builder: (context) => WellnessRingCreatePanel(data: definition, initialCreation: false,)));
              },
          ));
          content.add(Container(height: 15,));
        }
      }
    }

    return Container(
      child: Column(children: content,),
    );
  }

  Widget _buildCreateRingButton(){
    bool enabled = WellnessRings().canAddRing;
    final Color disabledTextColor = ColorUtils.fromHex("5c5c5c") ?? Colors.white; //TODO move to colors
    final Color disabledBackgroundColor = ColorUtils.fromHex("e7e7e7") ?? Colors.white; //TODO move to colors
    String label = "Create New Ring";
    String description = "Maximum of 4 total";
    return Visibility(
        visible: WellnessRings().canAddRing,
        child: Semantics(label: label, hint: description, button: true, excludeSemantics: true,
          child: GestureDetector(onTap: (){
            if(enabled) {
              Analytics().logSelect(target: "Create new ring");
              Navigator.push(context, CupertinoPageRoute(
                  builder: (context) => WellnessRingSelectPredefinedPanel()));
            }
          },
          child: Container(
          // padding: EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
              Expanded(child:
              Container(decoration: BoxDecoration(color: enabled? Colors.white : disabledBackgroundColor, borderRadius: BorderRadius.all(Radius.circular(4)), border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1)), child:
              Padding(padding: EdgeInsets.only(left: 18, top: 16, bottom: 16, right: 16), child:
              Row( crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Container(
                    padding: EdgeInsets.only(right: 14),
                      child: Image.asset('images/icons-control-add-blue.png', excludeFromSemantics: true, color: enabled? Colors.black : disabledTextColor,),
                  ),
                  Expanded(
                      flex: 5,
                      child: Container(
                        child: Text(label ,
                              style: TextStyle(color: enabled? Colors.black : disabledTextColor,
                                  fontFamily: Styles().fontFamilies!.bold, fontSize: 14), textAlign: TextAlign.start,),)),
                  Expanded(
                      flex: 5,
                      child: Container(
                        child: Text(description ,
                              style: TextStyle(color: enabled? Colors.black : disabledTextColor,
                                  fontFamily: Styles().fontFamilies!.regular, fontSize: 12), textAlign: TextAlign.end,),)),
                ],),
              ),
              )
              ),
            ],)),
      ),
    ));
  }

  void _showWelcomePopup() {
    AppAlert.showCustomDialog(
        context: context,
        contentPadding: EdgeInsets.all(0),
        contentWidget: Container(
            height: 300,
            decoration: BoxDecoration(color: Styles().colors!.white, borderRadius: BorderRadius.circular(10.0)),
            child: Stack(alignment: Alignment.center, fit: StackFit.loose, children: [
              Padding(
                  padding: EdgeInsets.all(19),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
                    Padding(
                        padding: EdgeInsets.symmetric(horizontal: 15),
                        child: Text(Localization().getStringEx('panel.wellness.rings.welcome.label', 'Welcome to Your Daily Wellness Rings!'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Styles().colors!.fillColorSecondary, fontSize: 20, fontFamily: Styles().fontFamilies!.bold))),
                    Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                            Localization().getStringEx('panel.wellness.rings.welcome.description.label',
                                'Use this tool to motivate you to start healthy habits, even if they are small!\n\nProgress is more important than perfection. For example: your “best” one day could be a full workout at the gym or it could be a five-minute walk—both count as an accomplishment!'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Styles().colors!.fillColorPrimary, fontSize: 14, fontFamily: Styles().fontFamilies!.regular)))
                  ])),
              Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                      onTap: () => {Navigator.of(context).pop()},
                      child: Padding(padding: EdgeInsets.all(11), child: Image.asset('images/icon-x-orange.png'))))
            ])));
  }

  void _onTabChanged({required _WellnessRingsTab tab}) {
    if (_selectedTab != tab) {
      _selectedTab = tab;
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  void onNotification(String name, param) {
    if(name == WellnessRings.notifyUserRingsUpdated){
      _ringsData = WellnessRings().wellnessRings;
      if(mounted) {
        setState(() {});
      }
    }
  }

}

//Common Widgets //Probably will use shared widgets with TODOLIst
enum _WellnessRingsTab { today, history}

enum _TabButtonPosition { first, middle, last }

class _TabButton extends StatelessWidget {
  final String? label;
  final String? hint;
  final _TabButtonPosition position;
  final bool? selected;
  final GestureTapCallback? onTap;

  _TabButton({this.label, this.hint, required this.position, this.selected, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Semantics(
            label: label,
            hint: hint,
            button: true,
            excludeSemantics: true,
            child: Container(
                height: 24 + 16 * MediaQuery.of(context).textScaleFactor,
                decoration: BoxDecoration(
                    color: selected! ? Colors.white : Styles().colors!.lightGray, border: _border, borderRadius: _borderRadius),
                child: Center(
                    child: Text(label!,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontFamily: selected! ? Styles().fontFamilies!.extraBold : Styles().fontFamilies!.medium,
                            fontSize: 16,
                            color: Styles().colors!.fillColorPrimary))))));
  }

  BorderRadiusGeometry? get _borderRadius {
    switch (position) {
      case _TabButtonPosition.first:
        return BorderRadius.horizontal(left: Radius.circular(100.0));
      case _TabButtonPosition.middle:
        return null;
      case _TabButtonPosition.last:
        return BorderRadius.horizontal(right: Radius.circular(100.0));
    }
  }

  BoxBorder? get _border {
    BorderSide borderSide = BorderSide(color: Styles().colors!.surfaceAccent!, width: 2, style: BorderStyle.solid);
    switch (position) {
      case _TabButtonPosition.first:
        return Border.fromBorderSide(borderSide);
      case _TabButtonPosition.middle:
        return Border(top: borderSide, bottom: borderSide);
      case _TabButtonPosition.last:
        return Border.fromBorderSide(borderSide);
    }
  }
}