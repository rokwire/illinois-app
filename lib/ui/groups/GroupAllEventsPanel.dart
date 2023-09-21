import 'package:flutter/material.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/model/group.dart';
import 'package:illinois/ext/Group.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:illinois/ui/groups/GroupWidgets.dart';

class GroupAllEventsPanel extends StatefulWidget implements AnalyticsPageAttributes {
  final Group? group;

  const GroupAllEventsPanel({Key? key, this.group}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _GroupAllEventsState();

  @override
  Map<String, dynamic>? get analyticsPageAttributes => group?.analyticsAttributes;
}

class _GroupAllEventsState extends State<GroupAllEventsPanel>{
  List<Event2>?   _groupEvents;

  @override
  void initState() {
    Groups().loadEventsV3(widget.group?.id).then((Events2ListResult? eventsResult) {
      if (mounted) {
        setState(() {
          _groupEvents = eventsResult?.events;
        });
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(
        title: Localization().getStringEx("panel.groups_all_events.label.heading","Upcoming Events") + "(${_groupEvents?.length ?? ""})",
      ),
      body:SingleChildScrollView(child:
         Column(
          children: <Widget>[
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              child: _buildEvents()
            ),
          ],
        ),
      ),
      backgroundColor: Styles().colors!.background,
      bottomNavigationBar: uiuc.TabBar(),
    );
  }

  Widget _buildEvents() {
    List<Widget> content = [];

    if (_groupEvents != null) {
      for (Event2? groupEvent in _groupEvents!) {
        content.add(GroupEventCard(groupEvent: groupEvent, group: widget.group,));
      }
    }

    return Column(
        children: content);
  }
}