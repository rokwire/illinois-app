import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/events2/Even2SetupSuperEvent.dart';
import 'package:illinois/ui/events2/Event2SetupNotificationsPanel.dart';
import 'package:illinois/ui/events2/Event2Widgets.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';

class Event2AdvancedSettingsPanel extends StatefulWidget{
  final Event2? event;

  const Event2AdvancedSettingsPanel({super.key, this.event});

  @override
  State<StatefulWidget> createState() => _Event2AdvancedSettingsState();
}

class _Event2AdvancedSettingsState extends State<Event2AdvancedSettingsPanel>{

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(title: Localization().getStringEx('panel.event2.settings.advanced.header.title', 'Advanced Settings')),
      body: _buildContent(),
      backgroundColor: Styles().colors.white,
    );
  }

  Widget _buildContent() =>
      SingleChildScrollView(child:
        Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24), child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Event2SettingsButton(
                title: Localization().getStringEx('panel.event2.create.button.custom_notifications.title', 'CUSTOM NOTIFICATIONS'), //TBD localize
                subTitle: Localization().getStringEx('panel.event2.create.button.custom_notifications.description', 'Create and schedule up to two custom Illinois app event notifications.'), //TBD localize
                onTap: _onCustomNotifications),
              Visibility(visible: _showSuperEvent,
                child:Event2SettingsButton(
                  title: 'SUPER EVENT',
                  subTitle: 'Manage this event as a multi-part “super event” by linking one or more of your other events as sub-events (e.g., sessions in a conference, performances in a festival, etc.). The super event will display all related events as one group of events in the Illinois app.',
                  onTap: _onSuperEvent)),
          ]),
        )
    );

  void _onCustomNotifications() {
    Analytics().logSelect(target: "Custom Notifications");

    Navigator.push<List<Event2NotificationSetting>?>(context, CupertinoPageRoute(builder: (context) => Event2SetupNotificationsPanel(
      event: _event,
      eventName: _event?.name,
      eventHasInternalRegistration: (_event?.registrationDetails?.type == Event2RegistrationType.internal),
      eventStartDateTimeUtc: _event?.startTimeUtc,
      isGroupEvent: widget.event?.isGroupEvent,
    )));
  }

  void _onSuperEvent() async {
    Analytics().logSelect(target: "Super Event");
    //We can skip passing supEvents, they will be loaded in the panel. This is designed to pass during create/edit.
    List<Event2>? subEvents; /*= (await Events2().loadEvents(
        Events2Query(grouping:  _event?.linkedEventsGroupingQuery)))?.events;*/
    Navigator.push(context,  CupertinoPageRoute(builder: (context) => Event2SetupSuperEventPanel(event: _event, subEvents: subEvents)));
  }

  Event2? get _event => widget.event;

  bool get _showSuperEvent => widget.event?.isRecurring != true;
}

