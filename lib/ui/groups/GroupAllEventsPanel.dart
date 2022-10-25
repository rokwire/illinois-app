import 'package:flutter/material.dart';
import 'package:rokwire_plugin/model/event.dart';
import 'package:rokwire_plugin/model/group.dart';
import 'package:illinois/ext/Group.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:illinois/ui/groups/GroupWidgets.dart';
import 'package:rokwire_plugin/ui/panels/modal_image_panel.dart';
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
  List<Event>?   _groupEvents;

  @override
  void initState() {
    Groups().loadEvents(widget.group).then((Map<int, List<Event>>? eventsMap) {
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
      for (Event? groupEvent in _groupEvents!) {
        content.add(GroupEventCard(groupEvent: groupEvent, group: widget.group, onImageTap: (){_showModalImage(groupEvent?.imageURL);}));
      }
    }

    return Column(
        children: content);
  }

  void _showModalImage(String? url){
    Analytics().logSelect(target: "Image");
    if (url != null) {
      Navigator.push(context, PageRouteBuilder( opaque: false, pageBuilder: (context, _, __) => ModalImagePanel(imageUrl: url, onCloseAnalytics: () => Analytics().logSelect(target: "Close Image",))));
    }
  }
}