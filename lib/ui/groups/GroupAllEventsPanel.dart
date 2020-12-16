import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/model/Groups.dart';
import 'package:illinois/service/Groups.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/Styles.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBarWidget.dart';
import 'package:illinois/ui/groups/GroupWidgets.dart';

class GroupAllEventsPanel extends StatefulWidget{
  final Group group;

  const GroupAllEventsPanel({Key key, this.group}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _GroupAllEventsState();
}

class _GroupAllEventsState extends State<GroupAllEventsPanel>{
  List<GroupEvent>   _groupEvents;

  //TBD Localization
  @override
  void initState() {
    Groups().loadEvents(widget.group?.id).then((List<GroupEvent> events) {
      if (mounted) {
        setState(() {
          _groupEvents = events;
        });
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SimpleHeaderBarWithBack(
        context: context,
        titleWidget: Text(Localization().getStringEx("panel.groups_all_events.label.heading","Upcoming Events" + "(${_groupEvents?.length ?? ""})"),
          style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontFamily: Styles().fontFamilies.extraBold,
              letterSpacing: 1.0),
        ),
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
      backgroundColor: Styles().colors.background,
      bottomNavigationBar: TabBarWidget(),
    );
  }

  Widget _buildEvents() {
    List<Widget> content = [];

    if (_groupEvents != null) {
      for (GroupEvent groupEvent in _groupEvents) {
        content.add(GroupEventCard(groupEvent: groupEvent, group: widget.group, isAdmin: false));
      }
    }

    return Column(
        children: content);
  }
}