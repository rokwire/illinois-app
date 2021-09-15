import 'package:device_calendar/device_calendar.dart';
import 'package:illinois/service/Service.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:illinois/model/Event.dart' as ExploreEvent;
import 'package:url_launcher/url_launcher.dart';

class DeviceCalendar with Service {
  String _defaultCalendarId;
  DeviceCalendarPlugin _deviceCalendarPlugin;

  static final DeviceCalendar _instance = DeviceCalendar._internal();

  factory DeviceCalendar(){
    return _instance;
  }

  DeviceCalendar._internal();

  @override
  Future<void>  initService() async{
    _deviceCalendarPlugin = new DeviceCalendarPlugin();
    _loadDefaultCalendar();
    super.createService();
  }

  Future<bool> addEvent(ExploreEvent.Event event) async{
    String additionalUrl = _extractAdditionalDataUrl(event);
    if(AppString.isStringNotEmpty(additionalUrl)){
      _openAdditionalDataLink(additionalUrl);
      return true;
    }

    bool hasPermissions = await _requestPermissions();
    if(hasPermissions && _defaultCalendarId!=null) {
      Event calendarEvent = _convertEvent(event);

      final createEventResult = await _deviceCalendarPlugin
          .createOrUpdateEvent(
          calendarEvent);
      AppToast.show(
          createEventResult?.data ?? createEventResult?.errorMessages ??
              "Unable to save Event to calendar");
      return false;
    }

    return true;
  }

  Future<bool> deleteEvent(event) async{
    //TBD implement Delete
    return false;
  }

  void _loadDefaultCalendar() async {
    bool hasPermissions = await _requestPermissions();
    if(!hasPermissions) {
      return;
    }
    final calendarsResult = await _deviceCalendarPlugin.retrieveCalendars();
    List<Calendar> calendars = calendarsResult.data;
    if(AppCollection.isCollectionNotEmpty(calendars)) {
      Calendar defaultCalendar = calendars.firstWhere((element) => element.isDefault);
      if (defaultCalendar!= null){
        _defaultCalendarId = defaultCalendar.id;
      }
    }
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
    Event calendarEvent = new Event(_defaultCalendarId);

//    calendarEvent.eventId = event.id;
    calendarEvent.title = event.title ?? "";
    if(event.startDateLocal!=null) {
      calendarEvent.start = event.startDateLocal;
    }
    if(event.endDateLocal!=null){ //TBD
      calendarEvent.end = event.endDateLocal;
    } else {
      calendarEvent.end = DateTime(event.startDateLocal.year, event.startDateLocal.month, event.startDateLocal.day, 23, 59,);
    }

    return calendarEvent;
  }

  String _extractAdditionalDataUrl(ExploreEvent.Event event){
//    return null; //TBD
    String additionalUrl = AppString.isStringNotEmpty(event.icalUrl) ? event.icalUrl : null;
    additionalUrl = AppString.isStringNotEmpty(event.outlookUrl) ? event.outlookUrl : additionalUrl; //TBD decide do we support both at same time

    return additionalUrl;
  }

  void _openAdditionalDataLink(String url) async{
      await canLaunch(url) ? await launch(url) : throw 'Could not launch $url';
  }
}