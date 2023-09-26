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

import 'package:flutter/material.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/model/group.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/service/events2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/ui/groups/GroupFindEventPanel.dart';
import 'package:illinois/ui/groups/GroupWidgets.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/ext/Event2.dart';

class GroupMembershipStepsPanel extends StatefulWidget {
  final List<GroupMembershipStep>? steps;

  GroupMembershipStepsPanel({this.steps});

  @override
  _GroupMembershipStepsPanelState createState() =>
      _GroupMembershipStepsPanelState();
}

class _GroupMembershipStepsPanelState extends State<GroupMembershipStepsPanel> {
  late List<GroupMembershipStep> _steps;
  List<FocusNode>? _focusNodes;
  List<TextEditingController>? _controllers;
  Map<String, Event2> _events = Map<String, Event2>();

  @override
  void initState() {
    _steps = GroupMembershipStep.listFromOthers(widget.steps) ?? [];
    if (_steps.isEmpty) {
      _steps.add(GroupMembershipStep());
    }
    
    _focusNodes = [];
    _controllers = [];
    List<String> eventIds = <String>[];
    for (GroupMembershipStep? step in _steps) {
      _controllers!.add(TextEditingController(text: step!.description ?? ''));
      _focusNodes!.add(FocusNode());
      if (step.eventIds != null) {
        eventIds.addAll(step.eventIds!);
      }
    }

    if (0 < eventIds.length) {
      Events2().loadEventsByIds(eventIds: eventIds).then((List<Event2>? events) {
        if (events != null) {
          for (Event2 event in events) {
            if (event.id != null) {
              _events[event.id!] = event;
            }
          }
          if (mounted) {
            setState(() {});
          }
        }
      });
    }


    super.initState();
  }

  @override
  void dispose() {
    for (TextEditingController controller in _controllers!) {
      controller.dispose();
    }
    _controllers = null;

    for (FocusNode focusNode in _focusNodes!) {
      focusNode.dispose();
    }
    _focusNodes = null;

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(
        leadingIconKey: 'close-circle-white',
        title: Localization().getStringEx("panel.membership_request.label.title", 'Membership Steps'),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _buildHeading(),
                    _buildSteps(),
                  ],
                ),
            ),
          ),
          _buildSubmit(),
        ],
      ),
      backgroundColor: Styles().colors!.background,
      bottomNavigationBar: uiuc.TabBar(),
    );
  }

  Widget _buildHeading() {
    return Container(color:Colors.white,
      child: Padding(padding: EdgeInsets.all(32),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children:<Widget>[
            Row(children: <Widget>[
              Padding(padding: EdgeInsets.only(right: 4), child: Styles().images?.getImage('campus-tools', excludeFromSemantics: true)),
              Text(Localization().getStringEx("panel.membership_request.button.add_steps.title", 'Add Steps'), style: Styles().textStyles?.getTextStyle("widget.title.regular.fat")),
            ],),
            Padding(padding: EdgeInsets.only(top: 8), child:
              Text(Localization().getStringEx("panel.membership_request.label.steps.description", 'Share the steps someone will need to take to become a member of your group.'), style: Styles().textStyles?.getTextStyle("widget.description.variant.regular.thin")),
            ),
          ]),
      ),
    );
  }

  Widget _buildSteps() {
    List<Widget> content = [];
    for (int index = 0; index < _steps.length; index++) {
      content.add(_buildStep(index: index));
    }
    if (_steps.length == 0) {
      content.add(Row(children: <Widget>[
        Expanded(child: Container(),),
        GroupMembershipAddButton(title: Localization().getStringEx("panel.membership_request.button.add_steps.title", 'Add step'), onTap: () { _addStep();  },),
      ],),);
    }

    return Padding(padding: EdgeInsets.all(32),
      child: Column(crossAxisAlignment:CrossAxisAlignment.start, children: content),
    );
  }

  Widget _buildStep({required int index}) {
    List<Widget> stepContent = [
      Padding(padding: EdgeInsets.only(bottom: 4),
        child: Text(Localization().getStringEx("panel.membership_request.button.add_steps.step", 'STEP ') +(index+1).toString(), style: Styles().textStyles?.getTextStyle("widget.title.tiny")),
      ),
      Stack(children: <Widget>[
        Container(color: Styles().colors!.white,
          child: TextField(
            maxLines: 2,
            controller: _controllers![index],
            focusNode: _focusNodes![index],
            decoration: InputDecoration(border: OutlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 1.0))),
            style: Styles().textStyles?.getTextStyle("widget.item.regular.thin")
          ),
        ),
        Align(alignment: Alignment.topRight,
          child: GestureDetector(onTap: () { _removeStep(index: index); },
            child: Container(width: 36, height: 36,
              child: Align(alignment: Alignment.center,
                child: Text('X', style: Styles().textStyles?.getTextStyle("widget.title.regular")),
              ),
            ),
          ),
        ),
      ],),
    ];
    
    List<String>? eventIds = _steps[index].eventIds;
    int eventsCount = eventIds?.length ?? 0;
    if (0 < eventsCount) {
      for (int eventIndex = 0; eventIndex < eventsCount; eventIndex++) {
        String? eventId = eventIds![eventIndex];
        Event2? event = _events[eventId];
        if (event != null) {
          stepContent.add(_EventCard(event: event, onTapRemove:(){ _removeEvent(stepIndex:index, eventIndex: eventIndex); }));
        }
      }
    }

    List<Widget> commands = [
      GroupMembershipAddButton(height: 26 + 16*MediaQuery.of(context).textScaleFactor, title:Localization().getStringEx("panel.membership_request.label.contact_event", 'Connect event'), onTap: () { _addEvent(stepIndex: index);  },),
      Container(width: 10,)
    ];
    if ((index + 1) == _steps.length) {
      commands.add(GroupMembershipAddButton(height: 26 + 16*MediaQuery.of(context).textScaleFactor, title: Localization().getStringEx("panel.membership_request.button.add_steps.title", 'Add step'), onTap: () { _addStep();  },),);
    }

    stepContent.add(Padding(padding: EdgeInsets.only(top: 8), child: SingleChildScrollView(scrollDirection: Axis.horizontal, child:Row(children: commands,),),));

    return Padding(padding: EdgeInsets.symmetric(vertical: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: stepContent,),);
  }

  Widget _buildSubmit() {
    return Container(color: Colors.white,
      child: Padding(padding: EdgeInsets.all(16),
        child: Row(children: <Widget>[
          Expanded(child: Container(),),
          RoundedButton(label:Localization().getStringEx("panel.membership_request.button.save.title", 'Save steps'),
            textStyle: Styles().textStyles?.getTextStyle("widget.button.title.medium.fat"),
            backgroundColor: Styles().colors!.white,
            borderColor: Styles().colors!.fillColorSecondary,
            borderWidth: 2,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            contentWeight: 0.0,
            onTap:() { _onSubmit();  }
          ),
          Expanded(child: Container(),),
        ],),
      ),
    );
  }

  void _addStep() {
    Analytics().logSelect(target: 'Add step');
    setState(() {
      GroupMembershipStep step = GroupMembershipStep();
      _steps.add(step);
      _controllers!.add(TextEditingController(text: step.description ?? ''));
      _focusNodes!.add(FocusNode());
    });
    Timer(Duration(milliseconds: 100), () {
      _focusNodes!.last.requestFocus();
    });
  }

  void _removeStep({int? index}) {
    Analytics().logSelect(target: 'Remove step');
    setState(() {
      _steps.removeAt(index!);
      _controllers!.removeAt(index);
      _focusNodes!.removeAt(index);
    });
  }

  void _addEvent({required int stepIndex}) {
    Analytics().logSelect(target: 'Connect event');
    GroupMembershipStep step = _steps[stepIndex];
    if (step.eventIds == null) {
      step.eventIds = <String>[];
    }
    GroupEventsContext groupContext = GroupEventsContext(events: <Event2>[]);
    Navigator.push(context, MaterialPageRoute(builder: (context) => GroupFindEventPanel(groupContext: groupContext,))).then((_){
      for (Event2 newEvent in groupContext.events!) {
        if (newEvent.id != null) {
          if (!step.eventIds!.contains(newEvent.id)) {
            step.eventIds!.add(newEvent.id!);
          }
          if (!_events.containsKey(newEvent.id)) {
            _events[newEvent.id!] = newEvent;
          }
        }
      }
      setState(() {});
    });
  }

  void _removeEvent({int? stepIndex, int? eventIndex}) {
    Analytics().logSelect(target: 'Remove event');
    setState(() {
      GroupMembershipStep? step = (stepIndex != null) ? _steps[stepIndex] : null;
      step?.eventIds?.removeAt(eventIndex!);
    });
  }

  void _onSubmit() {
    Analytics().logSelect(target: 'Save Steps');
    for (int index = 0; index < _steps.length; index++) {
      GroupMembershipStep step = _steps[index];

      String text = _controllers![index].text;
      if ((0 < text.length)) {
        step.description = text;
      }
      else {
        AppAlert.showDialogResult(context, Localization().getStringEx("panel.membership_request.button.add_steps.alert", 'Please input step #')+(index+1).toString()).then((_){
          _focusNodes![index].requestFocus();
        });
        return;
      }
    }

    widget.steps!.replaceRange(0, widget.steps!.length, _steps);
    Navigator.pop(context);
  }
}

class _EventCard extends StatelessWidget {
  final Event2?              event;
  final GestureTapCallback? onTapRemove;
  
  _EventCard({this.event, this.onTapRemove});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Styles().colors!.white,
          boxShadow: [BoxShadow(color: Styles().colors!.blackTransparent018!, spreadRadius: 2.0, blurRadius: 6.0, offset: Offset(2, 2))],
          borderRadius: BorderRadius.all(Radius.circular(8))
        ),
        child: Stack(children: <Widget>[
          Padding(padding: EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
              Padding(padding: EdgeInsets.only(bottom: 8), child: 
                Text(event!.name!,  style: Styles().textStyles?.getTextStyle("widget.title.large.extra_fat")),
              ),
              Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Row(children: <Widget>[
                Padding(padding: EdgeInsets.only(right: 8), child: Styles().images?.getImage('calendar', excludeFromSemantics: true)),
                Text(event?.shortDisplayDate ?? '',  style: Styles().textStyles?.getTextStyle("widget.item.small.thin")),
              ],)),
            ],)
          ),
          Align(alignment: Alignment.topRight,
            child: GestureDetector(onTap: () { onTapRemove!(); },
              child: Container(width: 36, height: 36,
                child: Align(alignment: Alignment.center,
                  child: Text('X', style: Styles().textStyles?.getTextStyle("widget.title.regular")),
                ),
              ),
            ),
          ),
        ],)
      ),
    );
  }
}
