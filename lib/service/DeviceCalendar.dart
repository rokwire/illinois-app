
import 'package:device_calendar/device_calendar.dart';
import 'package:illinois/model/Auth2.dart';
import 'package:illinois/model/sport/Game.dart';
import 'package:illinois/service/AppDateTime.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/ExploreService.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:illinois/service/Sports.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/service/Guide.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:illinois/model/Event.dart' as ExploreEvent;
import 'package:timezone/timezone.dart' as timezone;

class DeviceCalendar with Service implements NotificationsListener{
  static const String notifyPromptPopup            = "edu.illinois.rokwire.device_calendar.messaging.message.popup";
  static const String notifyCalendarSelectionPopup = "edu.illinois.rokwire.device_calendar.messaging.calendar_selection.popup";
  static const String notifyPlaceEvent             = "edu.illinois.rokwire.device_calendar.messaging.place.event";
  static const String notifyShowConsoleMessage     = "edu.illinois.rokwire.device_calendar.console.debug.message";

  Calendar? _defaultCalendar;
  List<Calendar>? _deviceCalendars;
  Calendar? _selectedCalendar;
  Map<String, String>? _calendarEventIdTable;
  DeviceCalendarPlugin _deviceCalendarPlugin = DeviceCalendarPlugin();

  static final DeviceCalendar _instance = DeviceCalendar._internal();

  factory DeviceCalendar(){
    return _instance;
  }

  DeviceCalendar._internal();

  @override
  void createService() {
    NotificationService().subscribe(this, [
      Auth2UserPrefs.notifyFavoriteChanged,
      DeviceCalendar.notifyPlaceEvent
    ]);
  }

  @override
  Future<void> initService() async {
    Map<String, String>? storedTable = Storage().calendarEventsTable;
    _calendarEventIdTable = storedTable!=null ? Map<String, String>.from(storedTable): Map();
    await super.initService();
  }

  @override
  void destroyService() {
    NotificationService().unsubscribe(this);
  }

  Future<bool> _addEvent(_DeviceCalendarEvent event) async{
    //User prefs
    if(!canAddToCalendar){
      _debugMessage("Disabled");
      return false;
    }

    //init check
    bool initResult = await _loadDefaultCalendarIfNeeded();
    if(!initResult){
      _debugMessage("Unable to init plugin");
      return false;
    }
    
    if(canShowPrompt){
      _promptPermissionDialog(event);
      return true;
    }

    return _placeCalendarEvent(event);
  }

  Future<bool> _placeCalendarEvent(_DeviceCalendarEvent? event) async{
    if(event == null)
      return false;

    //init check
    bool initResult = await _loadDefaultCalendarIfNeeded();
    if(!initResult){
      _debugMessage("Unable to init plugin");
      return false;
    }

    _debugMessage("Add to calendar- id:${calendar?.id}, name:${calendar?.name}, accountName:${calendar?.accountName}, accountType:${calendar?.accountType}, isReadOnly:${calendar?.isReadOnly}, isDefault:${calendar?.isDefault},");
    //PLACE
    if(calendar!=null) {
      Result<String>? createEventResult = await _deviceCalendarPlugin.createOrUpdateEvent(event.toCalendarEvent(calendar?.id));
      if(createEventResult?.data!=null){
        _storeEventId(event.internalEventId, createEventResult?.data);
      }

      _debugMessage("result.data: ${createEventResult?.data}, result?.errors?.toString(): ${createEventResult?.errors.toString()}");

      if((createEventResult == null) || !createEventResult.isSuccess) {
        //TBD: handle UI in caller
        AppToast.show(createEventResult?.data ?? createEventResult?.errors.toString() ?? 'Failed to create event');
        print(createEventResult?.errors.toString());
        return false;
      }
    } else {
      _debugMessage("calendar is missing");
    }

    _debugMessage("added");
    return true;
  }

  Future<bool> _deleteEvent(_DeviceCalendarEvent? event) async{
    if(event == null)
      return false;

    //init check
    bool initResult = await _loadDefaultCalendarIfNeeded();
    if(!initResult){
      _debugMessage("Unable to init plugin");
      return false;
    }

    String? eventId = event.internalEventId != null && _calendarEventIdTable!= null ? _calendarEventIdTable![event.internalEventId] : null;
    _debugMessage("Try delete eventId: ${event.internalEventId} stored with calendarId: $eventId from calendarId ${calendar!.id}");
    if(AppString.isStringEmpty(eventId)){
      return false;
    }

    final deleteEventResult = await _deviceCalendarPlugin.deleteEvent(calendar?.id, eventId);
    _debugMessage("delete result.data: ${deleteEventResult.data}, result.error: ${deleteEventResult.errors.toString()}");
    if(deleteEventResult.isSuccess){
      _eraseEventId(event.internalEventId);
    }
    return deleteEventResult.isSuccess;
  }

  Future<bool> _loadDefaultCalendarIfNeeded() async{
    if(calendar!=null)
      return true;
    
    return await _loadCalendars();
  }

  Future<bool> _loadCalendars() async {
    bool hasPermissions = await _requestPermissions();
    if(!hasPermissions) {
      _debugMessage("No Calendar permissions");
      return false;
    }
    _debugMessage("Has permissions");
    final calendarsResult = await _deviceCalendarPlugin.retrieveCalendars();
    List<Calendar>? calendars = calendarsResult.data;
    _deviceCalendars = calendars!=null && calendars.isNotEmpty? calendars.where((Calendar calendar) => calendar.isReadOnly == false).toList() : null;
    if(AppCollection.isCollectionNotEmpty(_deviceCalendars)) {
      _defaultCalendar = (_deviceCalendars as List<Calendar?>).firstWhere((element) => (element?.isDefault == true), orElse: () => null);
      return true;
    }
    _debugMessage("No Calendars");
    return false;
  }

  Future<List<Calendar>?> refreshCalendars() async {
    await _loadCalendars();
    return _deviceCalendars;
  }

  Future<bool> _requestPermissions() async {
    var permissionsGranted = await _deviceCalendarPlugin.hasPermissions();
    if (permissionsGranted.isSuccess && !permissionsGranted.data!) {
      permissionsGranted = await _deviceCalendarPlugin.requestPermissions();
      if (!permissionsGranted.isSuccess || !permissionsGranted.data!) {
        AppToast.show("Unable to save event to calendar. Permissions not granted");
        return false;
      }
    }

    return true;
  }

  void _storeEventId(String? exploreId, String? calendarEventId){
    if ((_calendarEventIdTable != null) && (exploreId != null) && (calendarEventId != null)) {
      _calendarEventIdTable![exploreId] = calendarEventId;
      Storage().calendarEventsTable = _calendarEventIdTable;
    }
  }
  
  void _eraseEventId(String? id){
    if (_calendarEventIdTable != null) {
      _calendarEventIdTable!.remove(id);
    }
  }

  void _debugMessage(String msg){
//    NotificationService().notify(DeviceCalendar.notifyShowConsoleMessage, msg); //Disable debug console messages
      print(msg);
  }

  void _processEvents(dynamic event){
    _DeviceCalendarEvent? deviceCalendarEvent = _DeviceCalendarEvent.from(event);
    if(deviceCalendarEvent==null)
      return;

    if (Auth2().isFavorite(event)) {
      _addEvent(deviceCalendarEvent);
    }
    else {
      _deleteEvent(deviceCalendarEvent);
    }
  }

  void _promptPermissionDialog(_DeviceCalendarEvent event) {
    NotificationService().notify(DeviceCalendar.notifyPromptPopup, {"event": event});
  }

  @override
  void onNotification(String name, param) {
    if(name == Auth2UserPrefs.notifyFavoriteChanged){
      _processEvents(param);
    }
    else if(name == DeviceCalendar.notifyPlaceEvent){
      if(param!=null && param is Map){
        _DeviceCalendarEvent? event = param["event"];
        Calendar? calendarSelection = param["calendar"];

        if(calendarSelection!=null){
          _selectedCalendar = calendarSelection;
        }
        _placeCalendarEvent(event);
      }
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

class _DeviceCalendarEvent {
  String? internalEventId;
  String? title;
  String? deepLinkUrl;
  DateTime? startDate;
  DateTime? endDate;

  _DeviceCalendarEvent({this.internalEventId, this.title, this.deepLinkUrl, this.startDate, this.endDate});

  static _DeviceCalendarEvent? from(dynamic data){
    if(data==null)
      return null;

    if(data is ExploreEvent.Event){
      return _DeviceCalendarEvent.fromEvent(data);
    }
    else if (data is Game){
      return _DeviceCalendarEvent.fromGame(data);
    }
    else if (data is GuideFavorite){
      return _DeviceCalendarEvent.fromGuide(data);
    }

    return null;
  }

  static _DeviceCalendarEvent? fromEvent(ExploreEvent.Event? event){
    if(event==null)
      return null;

    return _DeviceCalendarEvent(title: event.title, internalEventId: event.id, startDate: event.startDateLocal,
        endDate: event.endDateLocal,
        deepLinkUrl: "${ExploreService().eventDetailUrl}?event_id=${event.id}");
  }

  static _DeviceCalendarEvent? fromGame(Game? game){
    if(game==null)
      return null;

    return _DeviceCalendarEvent(title: game.title, internalEventId: game.id, startDate: game.dateTimeUniLocal,
        endDate:  AppDateTime().getUniLocalTimeFromUtcTime(game.endDateTimeUtc),
        deepLinkUrl: "${Sports().gameDetailUrl}?game_id=${game.id}%26sport=${game.sport?.shortName}");
  }

  static _DeviceCalendarEvent? fromGuide(GuideFavorite? guide){
    if(guide==null)
      return null;
    Map<String, dynamic>? guideEntryData = Guide().entryById(guide.id);
    //Only reminders are allowed to save
    if (Guide().isEntryReminder(guideEntryData)){
      return _DeviceCalendarEvent(
        title: guide.title,
        internalEventId: guide.id,
        startDate: Guide().reminderDate(guideEntryData),
        deepLinkUrl: "${Guide().guideDetailUrl}?guide_id=${guide.id}"
      );
    }

    return null;
  }

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

    calendarEvent.description = Config().deepLinkRedirectUrl(deepLinkUrl);

    return calendarEvent;
  }
}