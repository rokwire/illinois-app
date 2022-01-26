
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Gies.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/service/Storage.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/ui/gies/GiesPanel.dart';
import 'package:illinois/ui/widgets/ScalableWidgets.dart';
import 'package:illinois/ui/widgets/TrianglePainter.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class HomeGies2Widget extends StatefulWidget{

  final StreamController<void>? refreshController;

  const HomeGies2Widget({Key? key, this.refreshController}) : super(key: key);

  @override
  State<StatefulWidget> createState() => HomeGies2State();

}

class HomeGies2State extends State<HomeGies2Widget> implements NotificationsListener{

  @override
  void initState() {
    NotificationService().subscribe(this, [Gies.notifyPageChanged]);
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    NotificationService().unsubscribe(this);
  }

  @override
  Widget build(BuildContext context) {
    return Visibility(visible: true, child:
    Semantics(container: true, child:
    Column(children: <Widget>[
      _buildHeader(),
      Stack(children: <Widget>[
        _buildSlant(),
        _buildContent(),
      ]),
    ]),
    ));
  }

  Widget _buildHeader() {
    return Container(color: Styles().colors!.fillColorPrimary, child:
    Padding(padding: EdgeInsets.only(left: 16, right: 16, top: 10), child:
    Column(children: [
      Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Expanded(child:
        Text(Localization().getStringEx(
            'widget.gies.title', 'iDegrees New Student Checklist')!,
          textAlign: TextAlign.center,
          style: TextStyle(color: Styles().colors!.white,
            fontFamily: Styles().fontFamilies!.extraBold,
            fontSize: 20,),),),
      ],),
    ],),
    ),);
  }

  Widget _buildSlant() {
    return Column(children: <Widget>[
      Container(color: Styles().colors!.fillColorPrimary, height: 45,),
      Container(color: Styles().colors!.fillColorPrimary, child:
      CustomPaint(painter: TrianglePainter(
          painterColor: Styles().colors!.background, left: true), child:
      Container(height: 65,),
      )),
    ],);
  }

  Widget _buildContent() {
    if (!_isStarted) {
      return _buildStartContent();
    }

    if (_isEnded) {
      return _buildEndedContent();
    }

    return _buildProgressContent();
  }

  Widget _buildStartContent() {
    return Padding(
        padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16),
        child:
        Container(padding: EdgeInsets.all(16),
            decoration: BoxDecoration(color: Styles().colors!.white,
                borderRadius: BorderRadius.circular(5)),
            child: Column(
              children: [
                Row(children: [
                  Expanded(child:
                  Text(Localization().getStringEx(
                      'widget.gies2.message.start', 'Ready to get started?')!,
                    style: TextStyle(color: Styles().colors!.fillColorPrimary,
                      fontFamily: Styles().fontFamilies!.extraBold,
                      fontSize: 32,),),),
                ],),
                Container(height: 24,),
                ScalableRoundedButton(
                  label: Localization().getStringEx('widget.gies2.button.title.begin', "Begin Checklist"),
                  backgroundColor: Styles().colors?.white!,
                  borderColor: Styles().colors?.fillColorSecondary!,
                  textColor: Styles().colors!.fillColorPrimary,
                  onTap: _onTapContinue,
                ),
                Container(height: 16,),
              ],
            ))
    );
  }

  Widget _buildEndedContent() {
    return Padding(
        padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16),
        child:
        Container(padding: EdgeInsets.all(16),
            decoration: BoxDecoration(color: Styles().colors!.white,
                borderRadius: BorderRadius.circular(5)),
            child: Column(
              children: [
                Row(children: [
                  Expanded(child:
                  Text(Localization().getStringEx(
                      'widget.gies2.message.finished', 'You’ve completed the checklist.')!,
                    style: TextStyle(color: Styles().colors!.fillColorPrimary,
                      fontFamily: Styles().fontFamilies!.extraBold,
                      fontSize: 32,),),),
                ],),
                Container(height: 24,),
                ScalableRoundedButton(
                  label: Localization().getStringEx('widget.gies2.button.title.review', "Review Checklist"),
                  backgroundColor: Styles().colors?.white!,
                  borderColor: Styles().colors?.fillColorSecondary!,
                  textColor: Styles().colors!.fillColorPrimary,
                  onTap: _onTapContinue,
                ),
                Container(height: 12,),
                ScalableRoundedButton(
                  label: Localization().getStringEx('widget.gies2.button.title.view_notes', "View My Notes"),
                  backgroundColor: Styles().colors?.white!,
                  borderColor: Styles().colors?.fillColorSecondary!,
                  textColor: Styles().colors!.fillColorPrimary,
                  onTap: _onTapViewNotes,
                ),
                Container(height: 16,),
              ],
            ))
    );
  }

  Widget _buildProgressContent() {
    int completedCount =  _completedStpsCount;
    int pagesCount = _stepsCount;//TBD
    return Padding(
        padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16),
        child:
        Container(padding: EdgeInsets.all(16),
            decoration: BoxDecoration(color: Styles().colors!.white,
                borderRadius: BorderRadius.circular(5)),
            child: Column(
              children: [
                Row(children: [
                  Expanded(child:
                  Text(Localization().getStringEx(
                      'widget.gies2.message.progress', 'Completed steps')! + " $completedCount of $pagesCount",
                    style: TextStyle(color: Styles().colors!.fillColorPrimary,
                      fontFamily: Styles().fontFamilies!.extraBold,
                      fontSize: 32,),),),
                ],),
                Container(height: 24,),
                ScalableRoundedButton(
                  label: Localization().getStringEx('widget.gies2.button.title.continue', "Continue"),
                  backgroundColor: Styles().colors?.white!,
                  borderColor: Styles().colors?.fillColorSecondary!,
                  textColor: Styles().colors!.fillColorPrimary,
                  onTap: _onTapContinue,
                ),
                Container(height: 16,),
              ],
            ))
    );
  }

  void _onTapContinue(){
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GiesPanel()));
  }

  void _onTapViewNotes(){
    showDialog(context: context, builder: (BuildContext context) {
        return GiesNotesWidget(notes: JsonUtils.decodeList(Storage().giesNotes) ?? []);
    });
  }

  bool get _isStarted {
    return _completedStpsCount > 0;
  }

  bool get _isEnded {
    return Gies().completedStepsCount>= _stepsCount;
  }

  int get _completedStpsCount {
    return Gies().completedStepsCount;
  }

  int get _stepsCount {
    return Gies().progressSteps?.length ?? 0;
  }

  @override
  void onNotification(String name, param) {
    if(name == Gies.notifyPageChanged){
      setState(() {});
    }
  }

}