import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/ext/Event2.dart';
import 'package:illinois/ui/events2/Event2CreatePanel.dart';
import 'package:illinois/ui/events2/Event2SetupNotificationsPanel.dart';
import 'package:illinois/ui/events2/Event2Widgets.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/service/events2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

import '../../service/Analytics.dart';
import '../widgets/HeaderBar.dart';

class Event2AdminSettingsPanel extends StatefulWidget{
  final Event2? event;

  const Event2AdminSettingsPanel({super.key, this.event});

  @override
  State<StatefulWidget> createState() => Event2AdminSettingsState();
}

class Event2AdminSettingsState extends State<Event2AdminSettingsPanel>{
  bool _duplicating = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(title: Localization().getStringEx('panel.event2.detail.admin_settings.header.title', 'Admin Settings')),
      body: _buildContent(),
      backgroundColor: Styles().colors.white,
    );
  }

  Widget _buildContent() =>
      SingleChildScrollView(child:
        Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24), child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _ButtonWidget(
                title: Localization().getStringEx('panel.event2.create.button.duplicate.title', 'DUPLICATE'), //TBD localize
                subTitle: Localization().getStringEx('panel.event2.create.button.duplicate.description', 'Create duplicate of this event'), //TBD localize
                progress: _duplicating,
                onTap: _onSettingDuplicateEvent,),
              _ButtonWidget(
                title: Localization().getStringEx('panel.event2.create.button.custom_notifications.title', 'CUSTOM NOTIFICATIONS'), //TBD localize
                subTitle: Localization().getStringEx('panel.event2.create.button.custom_notifications.description', 'Create and schedule up to two custom Illinois app event notifications.'), //TBD localize
                onTap: _onCustomNotifications),
              _ButtonWidget(
                title: 'SUPER EVENT',
                subTitle: 'Manage this event as a multi-part “super event” by linking one or more of your other events as sub-events (e.g., sessions in a conference, performances in a festival, etc.). The super event will display all related events as one group of events in the Illinois app.',
                onTap: _onSuperEvent),
              _ButtonWidget(
                title: 'DOWNLOAD REGISTRANTS .csv',
                onTap: _onDownloadRegistrants),
              _ButtonWidget(
                title: 'UPLOAD REGISTRANTS .csv',
                onTap: _onUploadRegistrants),
              _ButtonWidget(
                  title: 'DOWNLOAD ATTENDANCE .csv',
                  onTap: _onDownloadAttendance),
              _ButtonWidget(
                title: 'UPLOAD ATTENDANCE .csv',
                onTap: _onUploadAttendance),
              _ButtonWidget(
                title: 'DOWNLOAD SURVEY RESULTS',
                onTap: _onDownloadSurveyResults),
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

  void _onSuperEvent() {
    Analytics().logSelect(target: "Super Event");
   AppToast.showMessage("TBD");
  }

  void _onDownloadRegistrants() {
    Analytics().logSelect(target: "Download Registrants");
   AppToast.showMessage("TBD");
  }

  void _onUploadRegistrants() {
    Analytics().logSelect(target: "Upload Registrants");
   AppToast.showMessage("TBD");
  }

  void _onDownloadAttendance() {
    Analytics().logSelect(target: "Download Attendance");
    AppToast.showMessage("TBD");
  }

  void _onUploadAttendance() {
    Analytics().logSelect(target: "Upload Attendance");
    AppToast.showMessage("TBD");
  }

  void _onDownloadSurveyResults() {
    Analytics().logSelect(target: "Download Survey Results");
    AppToast.showMessage("TBD");
  }

  void _onSettingDuplicateEvent() {
    Analytics().logSelect(target: "Duplicate event");

    if (_event != null) {
      Event2Popup.showPrompt(context,
        title: Localization().getStringEx('', 'Duplicate'),
        message: Localization().getStringEx('', 'Are you sure you want to duplicate event ${_event?.name}?'),
      ).then((bool? result) {
        if (result == true) {
          setStateIfMounted(() {
            _duplicating = true;
          });
          //TBD  // 1. Acknowledge Event Admins
          Events2().createEvent(_event!.duplicate).then((event){
            setStateIfMounted((){
              _duplicating = false;
            });

            if (result == true) {
              Navigator.pop(context);
            } else {
              Event2Popup.showErrorResult(context, result);
            }
          });
        }
      });
    }
  }

  Event2? get _event => widget.event;
}

class _ButtonWidget extends StatelessWidget{
  final String? title;
  final String? subTitle;
  final bool progress;
  final Function? onTap;

  const _ButtonWidget({this.title, this.subTitle, this.onTap, this.progress = false});

  @override
  Widget build(BuildContext context) {
    return _buildWidget();
  }

  Widget _buildWidget() => Event2CreatePanel.buildButtonSectionWidget(
    heading: Event2CreatePanel.buildButtonSectionHeadingWidget(
      title: title?? "",
      subTitle: subTitle,
      onTap: () => onTap?.call()
    ),
  );
}