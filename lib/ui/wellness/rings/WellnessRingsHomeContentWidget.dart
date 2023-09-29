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
import 'package:illinois/model/wellness/WellnessRing.dart';
import 'package:illinois/service/Wellness.dart';
import 'package:illinois/service/WellnessRings.dart';
import 'package:illinois/ui/wellness/rings/WellnessRingCreatePane.dart';
import 'package:illinois/ui/wellness/rings/WellnessRingWidgets.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/wellness/rings/WellnessRingSelectPredefinedPanel.dart';
import 'package:illinois/ui/widgets/SmallRoundedButton.dart';
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
    if (Wellness().isRingsAccessed != true) {
      Wellness().ringsAccessed(true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
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
          // WellnessWidgetHelper.buildWellnessHeader(),
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
            child: Text(Localization().getStringEx('panel.wellness.rings.description.label', "See your recent progress in one place by checking your log for the last 14 days."),
              style : Styles().textStyles?.getTextStyle('panel.wellness.ring.home.detail.message'),
          )),
          Container(height: 15,),
          _buildHistoryList(),
          _buildClearHistoryButton()
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
    var accomplishmentsDates = historyData?.entries.toList().reversed;
    if(accomplishmentsDates!=null && accomplishmentsDates.isNotEmpty){
      for(var accomplishmentsPerDay in accomplishmentsDates) {
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

  Widget _buildClearHistoryButton(){
    return  WellnessRings().haveHistory ?
      Container(
        padding: EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        child: SmallRoundedButton(label: 'Clear History',
          onTap: (){
            Analytics().logSelect(target: 'Clear History', source: widget.runtimeType.toString());
            WellnessRings().deleteRecords().then((success) {
              if(success == false){
                AppAlert.showDialogResult(context, "Unable to clear history");
              }
            });
          },
          textStyle: Styles().textStyles?.getTextStyle("widget.button.title.enabled"),
          backgroundColor: Colors.white,
          borderColor: Styles().colors!.fillColorSecondary,
          rightIcon: Container(),
        ),
      )
    : Container();
  }

  Widget _buildButtons(){
    List<Widget> content = [];
    if(_ringsData != null && _ringsData!.isNotEmpty) {
      for (WellnessRingDefinition definition  in _ringsData!) {
        content.add(WellnessRingButton(
            label: definition.name ?? "",
            color: definition.color,
            description: "${WellnessRings().getRingDailyValue(definition.id).toInt()}/${definition.goal.toInt()} ${definition.unit}",
            onTapIncrease: (_) => _onTapIncrease(definition),
            onTapDecrease: (_) => onTapDecrease(definition),
            onTapEdit: (_) => _onTapEdit(definition),
        ));
        content.add(Container(height: 15,));
      }
    }

    return Container(
      child: Column(children: content,),
    );
  }

  Future<void> _onTapIncrease(WellnessRingDefinition definition) async {
    Analytics().logWellnessRing(
      action: Analytics.LogWellnessActionComplete,
      source: widget.runtimeType.toString(),
      item: definition,
    );
    await WellnessRings().addRecord(WellnessRingRecord(value: 1, dateCreatedUtc: DateTime.now(), wellnessRingId: definition.id));
  }

  Future<void> onTapDecrease(WellnessRingDefinition definition) async {
    Analytics().logWellnessRing(
      action: Analytics.LogWellnessActionUncomplete,
      source: widget.runtimeType.toString(),
      item: definition,
    );
    await WellnessRings().addRecord(WellnessRingRecord(value: -1, dateCreatedUtc: DateTime.now(), wellnessRingId: definition.id));
  }

  void _onTapEdit(WellnessRingDefinition definition) {
    Analytics().logSelect(target: 'Edit', source: widget.runtimeType.toString());
    Navigator.push(context, CupertinoPageRoute(builder: (context) => WellnessRingCreatePanel(data: definition, initialCreation: false,)));
  }

  void _onTapCreate() {
    Analytics().logSelect(target: 'Create New Ring', source: widget.runtimeType.toString());
    if(WellnessRings().canAddRing) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => WellnessRingSelectPredefinedPanel()));
    }
  }

  Widget _buildCreateRingButton(){
    bool enabled = WellnessRings().canAddRing;
    final Color disabledBackgroundColor = ColorUtils.fromHex("e7e7e7") ?? Colors.white; //TODO move to colors
    String label = "Create New Ring";
    String description = "Maximum of 4 total";
    return Visibility(
        visible: WellnessRings().canAddRing,
        child: Semantics(label: label, hint: description, button: true, excludeSemantics: true,
          child: GestureDetector(onTap: _onTapCreate,
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
                      child: Styles().images?.getImage(enabled ? 'plus-dark' : 'add-gray', excludeFromSemantics: true),
                  ),
                  Expanded(
                      flex: 5,
                      child: Container(
                        child: Text(label ,
                          style: enabled? Styles().textStyles?.getTextStyle('panel.wellness.ring.home.button.create_ring.title.enabled') : Styles().textStyles?.getTextStyle('panel.wellness.ring.home.button.create_ring.title.disabled'),
                          textAlign: TextAlign.start,),)),
                  Expanded(
                      flex: 5,
                      child: Container(
                        child: Text(description ,
                          style: enabled? Styles().textStyles?.getTextStyle('panel.wellness.ring.home.button.create_ring.description.enabled') :  Styles().textStyles?.getTextStyle('panel.wellness.ring.home.button.create_ring.description.disabled'),
                          textAlign: TextAlign.end,),)),
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
                            style: Styles().textStyles?.getTextStyle('panel.wellness.ring.home.popup.heading'))),
                    Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                            Localization().getStringEx('panel.wellness.rings.welcome.description.label',
                                'Use this tool to motivate you to start healthy habits, even if they are small!\n\nProgress is more important than perfection. For example: your “best” one day could be a full workout at the gym or it could be a five-minute walk—both count as an accomplishment!'),
                            textAlign: TextAlign.center,
                            style: Styles().textStyles?.getTextStyle('widget.message.small')))
                  ])),
              Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                      onTap: _onClose,
                      child: Padding(padding: EdgeInsets.all(11), child: Styles().images?.getImage('close', excludeFromSemantics: true))))
            ])));
  }

  void _onClose() {
    Analytics().logSelect(target: 'Close', source: widget.runtimeType.toString());
    Navigator.of(context).pop();
  }

  void _onTabChanged({required _WellnessRingsTab tab}) {
    Analytics().logSelect(target: tab.toString(), source: widget.runtimeType.toString());
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
                        style: selected! ? Styles().textStyles?.getTextStyle('widget.tab.selected') : Styles().textStyles?.getTextStyle('widget.tab.not_selected') )))));
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