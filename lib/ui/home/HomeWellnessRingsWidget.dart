import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/model/wellness/WellnessRing.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/WellnessRings.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:illinois/ui/wellness/WellnessHomePanel.dart';
import 'package:illinois/ui/wellness/rings/WellnessRingSelectPredefinedPanel.dart';
import 'package:illinois/ui/wellness/rings/WellnessRingWidgets.dart';
import 'package:illinois/ui/widgets/LinkButton.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';

class HomeWellnessRingsWidget extends StatefulWidget {
  
  final String? favoriteId;
  final StreamController<String>? updateController;

  HomeWellnessRingsWidget({Key? key, this.favoriteId, this.updateController}) : super(key: key);

  static Widget handle({Key? key, String? favoriteId, HomeDragAndDropHost? dragAndDropHost, int? position}) =>
    HomeHandleWidget(key: key, favoriteId: favoriteId, dragAndDropHost: dragAndDropHost, position: position,
      title: title,
    );

  static String get title => Localization().getStringEx('widget.home.wellness.rings.title', 'Daily Wellness Rings');

  @override
  State<HomeWellnessRingsWidget> createState() => _HomeWellnessRingsWidgetState();
}

class _HomeWellnessRingsWidgetState extends State<HomeWellnessRingsWidget> implements NotificationsListener {
  @override
  void initState() {
    NotificationService().subscribe(this, [
      WellnessRings.notifyUserRingsUpdated
    ]);
    WellnessRings().loadWellnessRings();
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HomeSlantWidget(favoriteId: widget.favoriteId,
      title: HomeWellnessRingsWidget.title,
      titleIconKey: 'wellness',
      childPadding: HomeSlantWidget.defaultChildPadding,
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    return 
      Container(decoration: BoxDecoration(boxShadow: [BoxShadow(color: Color.fromRGBO(19, 41, 75, 0.3), spreadRadius: 2.0, blurRadius: 8.0, offset: Offset(0, 2))]), child:
        ClipRRect(borderRadius: BorderRadius.all(Radius.circular(6)), child:
          Row(children: <Widget>[
            Expanded(child:
              Column(children: <Widget>[
                Container(color: Styles().colors!.white, child:
                  Padding(padding: EdgeInsets.only(top: 20, right: 13, bottom: 0, left: 2), child:
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          Expanded(child:
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                            // Expanded( child:
                            Container(width: 13,),
                            Container(
                              child: WellnessRing(backgroundColor: Colors.white, size: 130, strokeSize: 15, borderWidth: 2,accomplishmentDialogEnabled: false,),
                            ),
                            // ),
                            Container(width: 18,),
                            Expanded(
                                child: Container(
                                    child: _buildButtons()
                                )
                            )
                          ],)
                          ),
                        ]),
                        LinkButton(
                          title: Localization().getStringEx('widget.home.wellness.rings.view_all.label', 'View All'),
                          hint: Localization().getStringEx('widget.home.wellness.rings.view_all.hint', 'Tap to view all rings'),
                          textStyle: Styles().textStyles?.getTextStyle("widget.button.title.small.semi_fat.underline"),
                          onTap: _onTapViewAll,
                        ),
                      ],
                    )
                  ),
                ),
              ]),
            ),
          ]),
        ),
      );
  }

  Widget _buildButtons(){
    List<Widget> content = [];
    List<WellnessRingDefinition>? activeRings = WellnessRings().wellnessRings;
    if(activeRings?.isNotEmpty ?? false){
      for(WellnessRingDefinition data in activeRings!) {
        content.add(SmallWellnessRingButton(
            label: data.name!,
            description: "${WellnessRings().getRingDailyValue(data.id).toInt()}/${data.goal.toInt()}",
            color: data.color,
            onTapWidget: (context)  =>  _onTapIncrease(data)
        ));
        content.add(Container(height: 5,));
      }
    }

      content.add(_buildCreateRingButton());

    return Container(child:Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: content,
    ));
  }

  Widget _buildCreateRingButton(){
    bool enabled = WellnessRings().canAddRing;
    final Color disabledTextColor = Styles().colors?.textColorDisabled ?? Colors.white;
    final Color disabledBackgroundColor = Styles().colors?.textBackgroundVariant2 ?? Colors.white;
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
                  Padding(padding: EdgeInsets.only(left: 8 /*+10 from icon*/, top: 10, bottom: 10, right: 3/*+10 form icon*/), child:
                  Row( crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        padding: EdgeInsets.only(right: 8),
                        child: Styles().images?.getImage('plus-circle', excludeFromSemantics: true, color: enabled? Colors.black : disabledTextColor,),
                      ),
                      Expanded(
                          flex: 5,
                          child: Container(
                            child: Text(label , style: enabled? Styles().textStyles?.getTextStyle("panel.wellness.ring.home_widget.button.title.enabled") : Styles().textStyles?.getTextStyle("panel.wellness.ring.home_widget.button.title.disabled"), textAlign: TextAlign.start,),)),
                    ],),
                  ),
                  )
                  ),
                ],)),
          ),
        ));
  }

  void _onTapCreate() {
    Analytics().logSelect(target: 'Create New Ring', source: widget.runtimeType.toString());
    if(WellnessRings().canAddRing) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => WellnessRingSelectPredefinedPanel()));
    }
  }

  void _onTapViewAll(){
    Analytics().logSelect(target: "View All", source: widget.runtimeType.toString());
    Navigator.push(context, CupertinoPageRoute(builder: (context) => WellnessHomePanel(content: WellnessContent.rings)));
  }

  Future<void> _onTapIncrease(WellnessRingDefinition data) async{
    Analytics().logWellnessRing(
      action: Analytics.LogWellnessActionComplete,
      source: widget.runtimeType.toString(),
      item: data,
    );
    await WellnessRings().addRecord(WellnessRingRecord(value: 1, dateCreatedUtc: DateTime.now(), wellnessRingId: data.id));
  }
  // NotificationsListener

  void onNotification(String name, dynamic param) {
    if(name == WellnessRings.notifyUserRingsUpdated){
      if(mounted){
        setState(() {});
      }
    }
  }
}

