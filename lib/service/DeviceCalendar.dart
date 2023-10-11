
import 'package:flutter/material.dart';
import 'package:illinois/ext/Appointment.dart';
import 'package:illinois/model/Appointment.dart';
import 'package:illinois/service/Appointments.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/service/app_datetime.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/events2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/device_calendar.dart' as rokwire;
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:illinois/model/sport/Game.dart';
import 'package:rokwire_plugin/model/event.dart' as ExploreEvent;
import 'package:illinois/service/Sports.dart';
import 'package:illinois/service/Guide.dart';
import 'package:illinois/model/Canvas.dart';
import 'package:illinois/service/Canvas.dart';
import 'package:rokwire_plugin/service/events.dart';
import 'package:device_calendar/device_calendar.dart';

class DeviceCalendar extends rokwire.DeviceCalendar implements NotificationsListener {

  static String get notifyPromptPopup            => rokwire.DeviceCalendar.notifyPromptPopup;
  static String get notifyCalendarSelectionPopup => rokwire.DeviceCalendar.notifyCalendarSelectionPopup;
  static String get notifyShowConsoleMessage     => rokwire.DeviceCalendar.notifyShowConsoleMessage;

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
    _DeviceCalendarEvent? deviceCalendarEvent = _DeviceCalendarEvent.from(event);
    return deviceCalendarEvent != null ?  await super.addEvent(deviceCalendarEvent) : false;
  }

  void _processFavorite(dynamic event) {
    _DeviceCalendarEvent? deviceCalendarEvent = Storage().calendarEnabledToAutoSave == true ? _DeviceCalendarEvent.from(event) : null;
    if(deviceCalendarEvent==null)
      return;

    if (Auth2().isFavorite(event)) {
      addEvent(deviceCalendarEvent);
    }
    else {
      deleteEvent(deviceCalendarEvent);
    }
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

class _DeviceCalendarEvent extends rokwire.DeviceCalendarEvent {
  //String? internalEventId;
  //String? title;
  //String? deepLinkUrl;
  //DateTime? startDate;
  //DateTime? endDate;

  _DeviceCalendarEvent({String? internalEventId, String? title, String? deepLinkUrl, DateTime? startDate, DateTime? endDate}) :
    super(internalEventId: internalEventId, title: title, deepLinkUrl: deepLinkUrl, startDate: startDate, endDate: endDate);

  static _DeviceCalendarEvent? from(dynamic data){
    if (data is ExploreEvent.Event) {
      return _DeviceCalendarEvent.fromEvent(data);
    }
    if (data is Event2) {
      return _DeviceCalendarEvent.fromEvent2(data);
    }
    else if (data is Game){
      return _DeviceCalendarEvent.fromGame(data);
    }
    else if (data is GuideFavorite){
      return _DeviceCalendarEvent.fromGuide(data);
    }
    else if (data is Appointment) {
      return _DeviceCalendarEvent.fromAppointment(data);
    }
    else if (data is CanvasCalendarEvent) {
      return _DeviceCalendarEvent.fromCanvasCalendarEvent(data);
    }

    return null;
  }

  static _DeviceCalendarEvent? fromEvent(ExploreEvent.Event? event){
    return (event != null) ? _DeviceCalendarEvent(
      title: event.title,
      internalEventId: event.id,
      startDate: event.startDateLocal,
      endDate: event.endDateLocal,
      deepLinkUrl: "${Events().eventDetailUrl}?event_id=${event.id}"
    ) : null;
  }

  static _DeviceCalendarEvent? fromEvent2(Event2? event){
    return (event != null) ? _DeviceCalendarEvent(
        title: event.exploreTitle,
        internalEventId: event.id,
        startDate: AppDateTime().getUniLocalTimeFromUtcTime(event.startTimeUtc),
        endDate: AppDateTime().getUniLocalTimeFromUtcTime(event.endTimeUtc),
        deepLinkUrl: "${Events2().eventDetailUrl}?event_id=${event.id}"
    ) : null;
  }

  static _DeviceCalendarEvent? fromGame(Game? game){
    return (game != null) ? _DeviceCalendarEvent(
      title: game.title,
      internalEventId: game.id,
      startDate: game.dateTimeUniLocal,
      endDate:  AppDateTime().getUniLocalTimeFromUtcTime(game.endDateTimeUtc),
      deepLinkUrl: "${Sports().gameDetailUrl}?game_id=${game.id}%26sport=${game.sport?.shortName}"
    ) : null;
  }

  static _DeviceCalendarEvent? fromGuide(GuideFavorite? guide){
    Map<String, dynamic>? guideEntryData = (guide != null) ? Guide().entryById(guide.id) : null;
    //Only reminders are allowed to save
    return (Guide().isEntryReminder(guideEntryData)) ? _DeviceCalendarEvent(
        title: Guide().entryListTitle(guideEntryData, stripHtmlTags: true),
        internalEventId: guide?.id,
        startDate: Guide().reminderDate(guideEntryData),
        deepLinkUrl: "${Guide().guideDetailUrl}?guide_id=${guide?.id}"
      ) : null;
  }

  static _DeviceCalendarEvent? fromAppointment(Appointment? appointment) {
    if (appointment == null) {
      return null;
    }
    DateTime? calendarEventStartDateTime = AppDateTime().getUniLocalTimeFromUtcTime(appointment.startTimeUtc);
    DateTime? calendarEventEndDateTime = calendarEventStartDateTime?.add(Duration(hours: 1));
    return _DeviceCalendarEvent(
      title: appointment.title,
      internalEventId: appointment.id,
      startDate: calendarEventStartDateTime,
      endDate: calendarEventEndDateTime,
      deepLinkUrl: "${Appointments().appointmentDetailUrl}?appointment_id=${appointment.id}"
    );
  }

  static _DeviceCalendarEvent? fromCanvasCalendarEvent(CanvasCalendarEvent? event) {
    return (event != null)
        ? _DeviceCalendarEvent(
            title: event.title,
            internalEventId: event.id?.toString(),
            startDate: event.startAtLocal,
            endDate: event.endAtLocal,
            deepLinkUrl: "${Canvas().canvasEventDetailUrl}?event_id=${event.id}")
        : null;
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