import 'package:flutter/material.dart';
import 'package:rokwire_plugin/model/group.dart';
import 'package:illinois/ext/Group.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBarWidget.dart';
import 'package:illinois/ui/groups/GroupWidgets.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class GroupAllEventsPanel extends StatefulWidget implements AnalyticsPageAttributes {
  final Group? group;

  const GroupAllEventsPanel({Key? key, this.group}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _GroupAllEventsState();

  @override
  Map<String, dynamic>? get analyticsPageAttributes => group?.analyticsAttributes;
}

class _GroupAllEventsState extends State<GroupAllEventsPanel>{
  List<GroupEvent>?   _groupEvents;

  @override
  void initState() {
    Groups().loadEvents(widget.group).then((Map<int, List<GroupEvent>>? eventsMap) {
      if (mounted) {
        setState(() {
          _groupEvents = CollectionUtils.isNotEmpty(eventsMap?.values) ? eventsMap!.values.first : null;
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
        titleWidget: Text(Localization().getStringEx("panel.groups_all_events.label.heading","Upcoming Events")! + "(${_groupEvents?.length ?? ""})",
          style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontFamily: Styles().fontFamilies!.extraBold,
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
      backgroundColor: Styles().colors!.background,
      bottomNavigationBar: TabBarWidget(),
    );
  }

  Widget _buildEvents() {
    List<Widget> content = [];
    bool isCurrentUserAdmin = widget.group?.currentUserIsAdmin ?? false;

    if (_groupEvents != null) {
      for (GroupEvent? groupEvent in _groupEvents!) {
        content.add(GroupEventCard(groupEvent: groupEvent, group: widget.group, isAdmin: isCurrentUserAdmin));
      }
    }

    return Column(
        children: content);
  }
}