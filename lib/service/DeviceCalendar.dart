import 'package:device_calendar/device_calendar.dart';
import 'package:illinois/service/ExploreService.dart';
import 'package:illinois/service/NotificationService.dart';
import 'package:illinois/service/Service.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/service/User.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:illinois/model/Event.dart' as ExploreEvent;
import 'package:url_launcher/url_launcher.dart';

class DeviceCalendar with Service implements NotificationsListener{

  static const String notifyPromptPopupMessage    = "edu.illinois.rokwire.device_calendar.messaging.message.popup";
  static const String notifyPlaceEventMessage     = "edu.illinois.rokwire.device_calendar.messaging.place.event";

  Calendar _defaultCalendar;
  Map<String, String> _calendarEventIdTable;
  DeviceCalendarPlugin _deviceCalendarPlugin;

  bool _disableAdditionalDataLink = true;

  static final DeviceCalendar _instance = DeviceCalendar._internal();

  factory DeviceCalendar(){
    return _instance;
  }

  DeviceCalendar._internal();

  @override
  void createService() {
    NotificationService().subscribe(this, [
      User.notifyFavoritesUpdated,
      DeviceCalendar.notifyPlaceEventMessage
    ]);
  }

  @override
  void destroyService() {
    NotificationService().unsubscribe(this);
  }

  Future<bool> _addEvent(ExploreEvent.Event event) async{
    _debugToast("Add Event- iCall:${event.icalUrl}, outlook:${event.outlookUrl}, startDateLocal: ${event.startDateLocal}, endDateLocal: ${event.endDateLocal}");
    
    //User prefs
    if(!canAddToCalendar){
      _debugToast("Disabled");
      return false;
    }
    
    if(canShowPrompt){
      _promptDialog(event);
      return true;
    }
    
    //URL
    String additionalUrl = _disableAdditionalDataLink? null : _extractAdditionalDataUrl(event);
    if(AppString.isStringNotEmpty(additionalUrl)){
      _openAdditionalDataLink(additionalUrl);
      return true;
    }

    return _placeCalendarEvent(event);
  }

  Future<bool> _placeCalendarEvent(ExploreEvent.Event event) async{

    //PLUGIN
    if(_deviceCalendarPlugin == null){
      bool initResult = await _initDeviceCalendarPlugin();
      if(!initResult ?? true){
        _debugToast("Unable to init plugin");
      }
    }
    _debugToast("Add to calendar- id:${_defaultCalendar.id}, name:${_defaultCalendar.name}, accountName:${_defaultCalendar.accountName}, accountType:${_defaultCalendar.accountType}, isReadOnly:${_defaultCalendar.isReadOnly}, isDefault:${_defaultCalendar.isDefault},");
    //PERMISSIONS
    bool hasPermissions = await _requestPermissions();

    _debugToast("Has permissions: $hasPermissions");
    //PLACE
    if(hasPermissions && _defaultCalendar!=null) {
      Event calendarEvent = _convertEvent(event);
      final createEventResult = await _deviceCalendarPlugin.createOrUpdateEvent(calendarEvent);
      if(createEventResult?.data!=null){
        _storeEventId(event.id, createEventResult?.data);
      }

      _debugToast("result.data: ${createEventResult.data}, result.errorMessages: ${createEventResult.errorMessages}");

      if(!createEventResult.isSuccess) {
        AppToast.show(createEventResult?.data ?? createEventResult?.errorMessages ?? "Unable to save Event to calendar");
        print(createEventResult?.errorMessages);
        return false;
      }
    }
    
    return true;
  }

  Future<bool> _deleteEvent(ExploreEvent.Event event) async{
    if(_deviceCalendarPlugin == null){
      bool initResult = await _initDeviceCalendarPlugin();
      if(!initResult ?? true){
        _debugToast("Unable to init plugin");
      }
    }

    String eventId = event?.id != null && _calendarEventIdTable!= null ? _calendarEventIdTable[event?.id] : null;
    _debugToast("Try delete eventId: ${event.id} stored with calendarId: $eventId from calendarId ${_defaultCalendar.id}");
    if(AppString.isStringEmpty(eventId)){
      return false;
    }

    final deleteEventResult = await _deviceCalendarPlugin.deleteEvent(_defaultCalendar?.id, eventId);
    _debugToast("delete result.data: ${deleteEventResult.data}, result.error: ${deleteEventResult.errorMessages}");
    if(deleteEventResult.isSuccess){
      _eraseEventId(event?.id);
    }
    return deleteEventResult?.isSuccess;
  }

  Future<bool> _initDeviceCalendarPlugin() async{
    _deviceCalendarPlugin = new DeviceCalendarPlugin();
    dynamic storedTable = Storage().calendarEventsTable ?? Map();
    _calendarEventIdTable = storedTable!=null ? Map<String, String>.from(storedTable): Map();
    return await _loadDefaultCalendar();
  }

  Future<bool> _loadDefaultCalendar() async {
    bool hasPermissions = await _requestPermissions();
    if(!hasPermissions) {
      return false;
    }
    final calendarsResult = await _deviceCalendarPlugin.retrieveCalendars();
    List<Calendar> calendars = calendarsResult.data;
    if(AppCollection.isCollectionNotEmpty(calendars)) {
      Calendar defaultCalendar = calendars.firstWhere((element) => element.isDefault);
      if (defaultCalendar!= null){
        _defaultCalendar = defaultCalendar;
        return true;
      }
    }

    return false;
  }

  Future<bool> _requestPermissions() async {
    var permissionsGranted = await _deviceCalendarPlugin.hasPermissions();
    if (permissionsGranted.isSuccess && !permissionsGranted.data) {
      permissionsGranted = await _deviceCalendarPlugin.requestPermissions();
      if (!permissionsGranted.isSuccess || !permissionsGranted.data) {
        AppToast.show("Unable to save event to calendar. Permissions not granted");
        return false;
      }
    }

    return true;
  }

  Event _convertEvent(ExploreEvent.Event event){
    Event calendarEvent = new Event(_defaultCalendar?.id);

    calendarEvent.title = event.title ?? "";
    if(event.startDateLocal!=null) {
      calendarEvent.start = event.startDateLocal;
    }
    if(event.endDateLocal!=null){
      calendarEvent.end = event.endDateLocal;
    } else {
      calendarEvent.end = DateTime(event.startDateLocal.year, event.startDateLocal.month, event.startDateLocal.day, 23, 59,);
    }

    String eventDeepLink = "${ExploreService.EVENT_URI}?event_id=${event.id}";
    calendarEvent.description ="$eventDeepLink";
//    calendarEvent.url = Uri.dataFromString(eventDeepLink);
    return calendarEvent;
  }

  String _extractAdditionalDataUrl(ExploreEvent.Event event){
    String additionalUrl = AppString.isStringNotEmpty(event.icalUrl) ? event.icalUrl : null;
    additionalUrl = AppString.isStringNotEmpty(event.outlookUrl) ? event.outlookUrl : additionalUrl;

    return additionalUrl;
  }

  void _openAdditionalDataLink(String url) async{
      await canLaunch(url) ? await launch(url) : throw 'Could not launch $url';
  }

  void _storeEventId(String exploreId, String calendarEventId){
    _calendarEventIdTable[exploreId] = calendarEventId;
    Storage().calendarEventsTable = _calendarEventIdTable;
  }
  
  void _eraseEventId(String id){
    _calendarEventIdTable.removeWhere((key, value) => key == id);
  }

  void _debugToast(String msg){
    AppToast.show(msg); //TBD Remove before release
  }

  void _processEvents(List events){
    if(events!=null && events.isNotEmpty) {
      for (ExploreEvent.Event event in events) {
        if (event != null) {
          if (User().isFavorite(event)) {
            //Just added
            _addEvent(event);
          } else {
            _deleteEvent(event);
          }
        }
      }
    }
  }

  void _promptDialog(ExploreEvent.Event event) {
    NotificationService().notify(notifyPromptPopupMessage, event);
  }



  @override
  void onNotification(String name, param) {
    if(name == User.notifyFavoritesUpdated){
      if(param != null && param is List && param.isNotEmpty){
        _processEvents(param);
      }
    } else if(name == DeviceCalendar.notifyPlaceEventMessage){
      if(param!=null && param is ExploreEvent.Event){
        _placeCalendarEvent(param);
      }
    }
  }
  
  bool get canAddToCalendar{
    return Storage().calendarEnabledToSave ?? false;
  }
  
  bool get canShowPrompt{
    return Storage().calendarCanPrompt ?? false;
  }
}