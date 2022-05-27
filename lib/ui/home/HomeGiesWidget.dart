
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Gies.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/service/Storage.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/ui/gies/GiesPanel.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class HomeGiesWidget extends StatefulWidget{

  final String? favoriteId;
  final StreamController<void>? refreshController;
  final HomeScrollableDragging? scrollableDragging;

  const HomeGiesWidget({Key? key, this.favoriteId, this.refreshController, this.scrollableDragging}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _HomeGiesWidgetState();

}

class _HomeGiesWidgetState extends State<HomeGiesWidget> implements NotificationsListener{
  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, [Gies.notifyPageChanged, Gies.notifyPageCompleted, Gies.notifyContentChanged]);
  }

  @override
  void dispose() {
    super.dispose();
    NotificationService().unsubscribe(this);
  }

  @override
  Widget build(BuildContext context) {
    return Visibility(visible: true, child:
    
      HomeDropTargetWidget(favoriteId: widget.favoriteId, child:
        HomeSlantWidget(favoriteId: widget.favoriteId, scrollableDragging: widget.scrollableDragging,
          title: Localization().getStringEx( 'widget.gies.title', 'iDegrees New Student Checklist'),
          child: _buildContent(),
          headerAxisAlignment: CrossAxisAlignment.start,
        ),
      ),

    );
  }

  Widget _buildContent() {
    if(Gies().isLoading){
      return _buildLoadingContent();
    }
    if (!_isStarted) {
      return _buildStartContent();
    }

    if (_isEnded) {
      return _buildEndedContent();
    }

    return _buildProgressContent();
  }

  Widget _buildLoadingContent(){
    return 
        Container(
          constraints: BoxConstraints(maxHeight: 100),
          padding: EdgeInsets.all(16),
            decoration: BoxDecoration(color: Styles().colors!.white,
                borderRadius: BorderRadius.circular(5)),
            child: Column(children: <Widget>[
              Expanded(
                child: Center(
                  child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors!.fillColorSecondary), ),
                ),
              ),
            ]),
    );
  }

  Widget _buildStartContent() {
    return 
        Container(padding: EdgeInsets.all(16),
            decoration: BoxDecoration(color: Styles().colors!.white,
                borderRadius: BorderRadius.circular(5)),
            child: Column(
              children: [
                Row(children: [
                  Expanded(child:
                  Semantics(
                    container: true,
                    child:Text(Localization().getStringEx(
                        'widget.gies.message.start', 'Ready to get started?'),
                      style: TextStyle(color: Styles().colors!.fillColorPrimary,
                        fontFamily: Styles().fontFamilies!.extraBold,
                        fontSize: 32,),),)),
                  ],),
                Container(height: 24,),
                RoundedButton(
                  label: Localization().getStringEx('widget.gies.button.title.begin', "Begin Checklist"),
                  backgroundColor: Styles().colors?.white!,
                  borderColor: Styles().colors?.fillColorSecondary!,
                  textColor: Styles().colors!.fillColorPrimary,
                  onTap: _onTapContinue,
                ),
                Container(height: 16,),
              ],
            ));
  }

  Widget _buildEndedContent() {
    return 
        Container(padding: EdgeInsets.all(16),
            decoration: BoxDecoration(color: Styles().colors!.white,
                borderRadius: BorderRadius.circular(5)),
            child: Column(
              children: [
                Row(children: [
                  Expanded(child:
                    Semantics(
                      container: true,
                      child:
                      Text(Localization().getStringEx(
                          'widget.gies.message.finished', 'You’ve completed the checklist.'),
                        style: TextStyle(color: Styles().colors!.fillColorPrimary,
                          fontFamily: Styles().fontFamilies!.extraBold,
                          fontSize: 32,),),)),
                ],),
                Container(height: 24,),
                RoundedButton(
                  label: Localization().getStringEx('widget.gies.button.title.review', "Review Checklist"),
                  backgroundColor: Styles().colors?.white!,
                  borderColor: Styles().colors?.fillColorSecondary!,
                  textColor: Styles().colors!.fillColorPrimary,
                  onTap: _onTapContinue,
                ),
                !Gies().supportNotes ? Container() :
                Column(children: [
                  Container(height: 12,),
                  RoundedButton(
                    label: Localization().getStringEx('widget.gies.button.title.view_notes', "View My Notes"),
                    backgroundColor: Styles().colors?.white!,
                    borderColor: Styles().colors?.fillColorSecondary!,
                    textColor: Styles().colors!.fillColorPrimary,
                    onTap: _onTapViewNotes,
                  ),
                ],),
                Container(height: 16,),
              ],
            )
    );
  }

  Widget _buildProgressContent() {
    return 
        Container(padding: EdgeInsets.all(16),
            decoration: BoxDecoration(color: Styles().colors!.white,
                borderRadius: BorderRadius.circular(5)),
            child: Column(
              children: [
                Row(children: [
                  Expanded(child:
                    Semantics(
                      container: true,
                      child: Text(_progressText,
                        style: TextStyle(color: Styles().colors!.fillColorPrimary,
                          fontFamily: Styles().fontFamilies!.extraBold,
                          fontSize: 24,),),)),
                    ],),
                Container(height: 24,),
                RoundedButton(
                  label: Localization().getStringEx('widget.gies.button.title.continue', "Continue"),
                  backgroundColor: Styles().colors?.white!,
                  borderColor: Styles().colors?.fillColorSecondary!,
                  textColor: Styles().colors!.fillColorPrimary,
                  onTap: _onTapContinue,
                ),
                Container(height: 16,),
              ],
            )
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

  String get _progressText {
    List<String> completed = [];
    List<String> notCompleted = [];
    String completedNames = "";
    String notCompletedNames = "";
    for(int stepId in Gies().progressSteps??[]){
      if(Gies().isProgressStepCompleted(stepId)){
        completed.add(stepId.toString());
        completedNames+= StringUtils.isNotEmpty(completedNames)? ", " : "";
        completedNames+= stepId.toString();
      } else {
        notCompleted.add(stepId.toString());
      }
    }
    String completedText = "Step${completed.length>1 ? "s" : ""} $completedNames completed${notCompleted.length>0?"," : ""}";

    for(String stepName in notCompleted){
      notCompletedNames+= StringUtils.isNotEmpty(notCompletedNames)?
        "${notCompleted.last == stepName ? " and" : ","} " :
        "";
      notCompletedNames+= stepName.toString();
    }
    String notCompletedText = notCompletedNames.length>0? "$notCompletedNames ${notCompleted.length>1 ? "are" : "is"} incomplete." :"";
    return "$completedText $notCompletedText";
  }

  bool get _isStarted {
    return _completedStpsCount > 0;
  }

  bool get _isEnded {
    return _completedStpsCount >= _stepsCount;
  }

  int get _completedStpsCount {
    return Gies().completedStepsCount;
  }

  int get _stepsCount {
    return Gies().progressSteps?.length ?? 0;
  }

  @override
  void onNotification(String name, param) {
    if(name == Gies.notifyPageChanged ||
        name == Gies.notifyPageCompleted ||
        name ==Gies.notifyContentChanged){
      setState(() {});
    }
  }

}