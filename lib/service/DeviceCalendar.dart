
import 'package:flutter/material.dart';
import 'package:illinois/model/DeviceCalendar.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/device_calendar.dart' as rokwire;
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:device_calendar/device_calendar.dart';

class DeviceCalendar extends rokwire.DeviceCalendar implements NotificationsListener {

  static String get notifyPromptPopup            => rokwire.DeviceCalendar.notifyPromptPopup;

  // Singletone Factory

  @protected
  DeviceCalendar.internal() : super.internal();

  factory DeviceCalendar() => ((rokwire.DeviceCalendar.instance is DeviceCalendar) ? (rokwire.DeviceCalendar.instance as DeviceCalendar) : (rokwire.DeviceCalendar.instance = DeviceCalendar.internal()));

  // Service

  @override
  void createService() {
    NotificationService().subscribe(this, [
      Auth2UserPrefs.notifyFavoriteChanged
    ]);
  }

  @override
  void destroyService() {
    NotificationService().unsubscribe(this);
  }

  // NotificationsListener

  @override
  void onNotification(String name, param) {
    if(name == Auth2UserPrefs.notifyFavoriteChanged){
      _processFavorite(param);
    }
  }

  Future<bool> addToCalendar(dynamic event) async {
    DeviceCalendarEvent? deviceCalendarEvent = DeviceCalendarEvent.from(event);
    return deviceCalendarEvent != null ?  await super.addEvent(deviceCalendarEvent) : false;
  }

  void _processFavorite(dynamic event) {
    DeviceCalendarEvent? deviceCalendarEvent = Storage().calendarEnabledToAutoSave == true ? DeviceCalendarEvent.from(event) : null;
    if(deviceCalendarEvent==null)
      return;

    if (Auth2().isFavorite(event)) {
      addEvent(deviceCalendarEvent);
    }
    else {
      deleteEvent(deviceCalendarEvent);
    }
  }

  @protected
  void onCreateOrUpdateEventSucceeded(Result<String>? createEventResult) {
    AppToast.show(Localization().getStringEx('logic.calendar.create_event_succeeded', 'Event added to calendar.'));
  }

  @override
  void onCreateOrUpdateEventFailed(Result<String>? createEventResult) {
    AppToast.show(createEventResult?.data ?? createEventResult?.errors.toString() ?? Localization().getStringEx('logic.calendar.create_event_failed', 'Failed to create event.'));
  }

  @override
  void onRequestPermissionFailed() {
    AppToast.show(Localization().getStringEx('logic.calendar.permission_denied', 'Unable to save event to calendar. Permissions not granted.'));
  }
}

class DeviceCalendarDialog extends StatefulWidget {
  final dynamic eventData;

  const DeviceCalendarDialog({super.key, required this.eventData});

  static void show({required BuildContext context, dynamic eventData}) => showDialog(context: context, builder: (_) => Material(type: MaterialType.transparency, child: DeviceCalendarDialog(eventData: eventData,)));

  @override
  State<StatefulWidget> createState() => _DeviceCalendarDialogState();
}

class _DeviceCalendarDialogState extends State<DeviceCalendarDialog>{

  @override
  Widget build(BuildContext context) =>
     Dialog(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
                Padding( padding: EdgeInsets.all(8),
                  child: Text(Localization().getStringEx('prompt.device_calendar.msg.add_event', 'Would you like to add this event to your device\'s calendar?'),
                    style: Styles().textStyles?.getTextStyle("widget.message.medium.thin"),
                    textAlign: TextAlign.center,
                  ),
                ),
                Container(height: 8,),
                Row(mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child:
                      Padding(padding: EdgeInsets.all(8),
                        child: RoundedButton(
                          label: Localization().getStringEx("dialog.no.title","No"),
                          textStyle: Styles().textStyles?.getTextStyle("widget.button.title.enabled"),
                          borderColor: Styles().colors!.fillColorPrimary,
                          backgroundColor: Styles().colors!.white,
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          onTap: _onDecline
                          ))),
                    Expanded(child:
                      Padding(padding: EdgeInsets.all(8),
                        child: RoundedButton(
                          label: Localization().getStringEx("dialog.yes.title","Yes"),
                          textStyle: Styles().textStyles?.getTextStyle("widget.button.title.enabled"),
                          borderColor: Styles().colors!.fillColorSecondary,
                          backgroundColor: Styles().colors!.white,
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          onTap: (){
                            Navigator.of(context).pop();
                            _onConfirm();
                          }))),
                ]),
                Container(height: 16,),
                ToggleRibbonButton(
                    label: Localization().getStringEx('panel.settings.home.calendar.settings.prompt.label', 'Prompt when saving events or appointments to calendar'),
                    border: Border.all(color: Styles().colors!.blackTransparent018!, width: 1),
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                    textStyle: Styles().textStyles?.getTextStyle("widget.button.title.medium"),
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    toggled: Storage().calendarCanPrompt == true,
                    onTap: _onPromptChange
                ),
                Container(height: 8,),
            ]),
        ));

  void _onConfirm() {
    Navigator.of(context).pop();
    DeviceCalendar().placeEvent(widget.eventData);
  }

  void _onDecline() => Navigator.of(context).pop();

  void _onPromptChange() =>
    setStateIfMounted(() {
      Storage().calendarCanPrompt = (Storage().calendarCanPrompt != true);
    });
}