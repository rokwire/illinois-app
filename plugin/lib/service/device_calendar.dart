
import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/foundation.dart';
import 'package:rokwire_plugin/service/app_datetime.dart';
import 'package:rokwire_plugin/service/config.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:rokwire_plugin/service/storage.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:timezone/timezone.dart' as timezone;
import 'package:collection/collection.dart';

class DeviceCalendar with Service {
  static const String notifyPromptPopup            = "edu.illinois.rokwire.device_calendar.messaging.message.popup";
  static const String notifyCalendarSelectionPopup = "edu.illinois.rokwire.device_calendar.messaging.calendar_selection.popup";
  static const String notifyShowConsoleMessage     = "edu.illinois.rokwire.device_calendar.console.debug.message";

  Calendar? _defaultCalendar;
  List<Calendar>? _deviceCalendars;
  Calendar? _selectedCalendar;
  Map<String, String>? _calendarEventIdTable;
  final DeviceCalendarPlugin _deviceCalendarPlugin = DeviceCalendarPlugin();

  // Singletone Factory

  static DeviceCalendar? _instance;

  static DeviceCalendar? get instance => _instance;

  @protected
  static set instance(DeviceCalendar? value) => _instance = value;

  factory DeviceCalendar() => _instance ?? (_instance = DeviceCalendar.internal());

  @protected
  DeviceCalendar.internal();
  
  // Service

  @override
  Future<void> initService() async {
    _calendarEventIdTable = Storage().calendarEventsTable ?? {};
    await super.initService();
  }

  // Implementation

  Calendar? get defaultCalendar => _defaultCalendar;
  List<Calendar>? get deviceCalendars => _deviceCalendars;
  Calendar? get selectedCalendar => _selectedCalendar;
  Map<String, String>? get calendarEventIdTable => _calendarEventIdTable;
  DeviceCalendarPlugin get deviceCalendarPlugin => _deviceCalendarPlugin;

  @protected
  Future<bool> addEvent(DeviceCalendarEvent event) async {
    //User prefs
    if (!canAddToCalendar) {
      consoleMessage("Disabled");
      return false;
    }

    //init check
    bool initResult = await loadDefaultCalendarIfNeeded();
    if (!initResult) {
      consoleMessage("Unable to init plugin");
      return false;
    }
    
    if (canShowPrompt) {
      promptPermissionDialog(event);
      return true;
    }

    return placeCalendarEvent(event);
  }

  @protected
  Future<bool> placeCalendarEvent(DeviceCalendarEvent? event) async {
    if (event == null) {
      return false;
    }

    //init check
    bool initResult = await loadDefaultCalendarIfNeeded();
    if(!initResult){
      consoleMessage("Unable to init plugin");
      return false;
    }

    consoleMessage("Add to calendar- id:${calendar?.id}, name:${calendar?.name}, accountName:${calendar?.accountName}, accountType:${calendar?.accountType}, isReadOnly:${calendar?.isReadOnly}, isDefault:${calendar?.isDefault},");
    //PLACE
    if(calendar != null) {
      Result<String>? createEventResult = await _deviceCalendarPlugin.createOrUpdateEvent(event.toCalendarEvent(calendar?.id));
      if (createEventResult?.data!=null) {
        storeEventId(event.internalEventId, createEventResult?.data);
      }

      consoleMessage("result.data: ${createEventResult?.data}, result?.errors?.toString(): ${createEventResult?.errors.toString()}");

      if((createEventResult == null) || !createEventResult.isSuccess) {
        consoleMessage('failed to create/update event: ${createEventResult?.errors.toString()}');
        onCreateOrUpdateEventFailed(createEventResult);
        return false;
      }
    } else {
      consoleMessage("calendar is missing");
    }

    consoleMessage("added");
    return true;
  }

  @protected
  void onCreateOrUpdateEventFailed(Result<String>? createEventResult) {
    AppToast.show(createEventResult?.data ?? createEventResult?.errors.toString() ?? 'Failed to create event');
  }

  @protected
  Future<bool> deleteEvent(DeviceCalendarEvent? event) async {
    if (event == null) {
      return false;
    }

    //init check
    bool initResult = await loadDefaultCalendarIfNeeded();
    if (!initResult) {
      consoleMessage("Unable to init plugin");
      return false;
    }

    String? eventId = event.internalEventId != null && _calendarEventIdTable!= null ? _calendarEventIdTable![event.internalEventId] : null;
    consoleMessage("Try delete eventId: ${event.internalEventId} stored with calendarId: $eventId from calendarId ${calendar!.id}");
    if (StringUtils.isEmpty(eventId)) {
      return false;
    }

    final deleteEventResult = await _deviceCalendarPlugin.deleteEvent(calendar?.id, eventId);
    consoleMessage("delete result.data: ${deleteEventResult.data}, result.error: ${deleteEventResult.errors.toString()}");
    if (deleteEventResult.isSuccess) {
      eraseEventId(event.internalEventId);
    }
    return deleteEventResult.isSuccess;
  }

  @protected
  Future<bool> loadDefaultCalendarIfNeeded() async{
    return (calendar == null) ? await loadCalendars() : true;
  }

  @protected
  Future<bool> loadCalendars() async {
    bool hasPermissions = await requestPermissions();
    if (!hasPermissions) {
      consoleMessage("No Calendar permissions");
      return false;
    }
    
    consoleMessage("Has permissions");
    final calendarsResult = await _deviceCalendarPlugin.retrieveCalendars();
    List<Calendar>? calendars = calendarsResult.data;
    _deviceCalendars = calendars!=null && calendars.isNotEmpty? calendars.where((Calendar calendar) => calendar.isReadOnly == false).toList() : null;
    if(CollectionUtils.isNotEmpty(_deviceCalendars)) {
      _defaultCalendar = _deviceCalendars!.firstWhereOrNull((element) => (element.isDefault == true));
      return true;
    }
    consoleMessage("No Calendars");
    return false;
  }

  Future<List<Calendar>?> refreshCalendars() async {
    await loadCalendars();
    return _deviceCalendars;
  }

  
  @protected
  Future<bool> requestPermissions() async {
    var permissionsGranted = await _deviceCalendarPlugin.hasPermissions();
    if (permissionsGranted.isSuccess && !permissionsGranted.data!) {
      permissionsGranted = await _deviceCalendarPlugin.requestPermissions();
      if (!permissionsGranted.isSuccess || !permissionsGranted.data!) {
        onRequestPermisionFailed();
        return false;
      }
    }

    return true;
  }

  @protected
  void onRequestPermisionFailed() {
    AppToast.show("Unable to save event to calendar. Permissions not granted");
  }

  @protected
  void storeEventId(String? exploreId, String? calendarEventId) {
    if ((_calendarEventIdTable != null) && (exploreId != null) && (calendarEventId != null)) {
      _calendarEventIdTable![exploreId] = calendarEventId;
      Storage().calendarEventsTable = _calendarEventIdTable;
    }
  }
  
  @protected
  void eraseEventId(String? id) {
    if (_calendarEventIdTable != null) {
      _calendarEventIdTable!.remove(id);
      Storage().calendarEventsTable = _calendarEventIdTable;
    }
  }

  @protected
  void consoleMessage(String msg){
//    NotificationService().notify(DeviceCalendar.notifyShowConsoleMessage, msg); //Disable debug console messages
      debugPrint(msg);
  }

  @protected
  void promptPermissionDialog(DeviceCalendarEvent event) {
    NotificationService().notify(DeviceCalendar.notifyPromptPopup, {"event": event});
  }

  void placeEvent(dynamic data) {
    if(data!=null && data is Map){
      DeviceCalendarEvent? event = data["event"];
      Calendar? calendarSelection = data["calendar"];

      if(calendarSelection!=null){
        _selectedCalendar = calendarSelection;
      }
      placeCalendarEvent(event);
    }
  }

  bool get canAddToCalendar{
    return Storage().calendarEnabledToSave ?? false;
  }
  
  bool get canShowPrompt{
    return Storage().calendarCanPrompt ?? false;
  }
  
  Calendar? get calendar{
    return _selectedCalendar ?? _defaultCalendar;
  }

  set calendar(Calendar? calendar){
    _selectedCalendar = calendar;
  }
}

class DeviceCalendarEvent {
  String? internalEventId;
  String? title;
  String? deepLinkUrl;
  DateTime? startDate;
  DateTime? endDate;

  DeviceCalendarEvent({this.internalEventId, this.title, this.deepLinkUrl, this.startDate, this.endDate});

  Event toCalendarEvent(String? calendarId){
    Event calendarEvent = Event(calendarId);
    calendarEvent.title = title ?? "";

    if (startDate != null) {
      calendarEvent.start = timezone.TZDateTime.from(startDate!, AppDateTime().universityLocation!);
    }

    if (endDate != null) {
      calendarEvent.end = timezone.TZDateTime.from(endDate!, AppDateTime().universityLocation!);
    } else if (startDate != null) {
      calendarEvent.end = timezone.TZDateTime(AppDateTime().universityLocation!, startDate!.year, startDate!.month, startDate!.day, 24);
    }

    String? redirectUrl = Config().deepLinkRedirectUrl(deepLinkUrl);
    calendarEvent.description = StringUtils.isNotEmpty(redirectUrl) ? "$redirectUrl?target=$deepLinkUrl" : deepLinkUrl;

    return calendarEvent;
  }
}