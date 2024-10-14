import 'package:illinois/ext/Appointment.dart';
import 'package:illinois/model/Appointment.dart';
import 'package:illinois/model/Canvas.dart';
import 'package:illinois/model/sport/Game.dart';
import 'package:illinois/service/Appointments.dart';
import 'package:illinois/service/Canvas.dart';
import 'package:illinois/service/Guide.dart';
import 'package:illinois/service/Sports.dart';
import 'package:rokwire_plugin/model/device_calendar.dart' as rokwire;
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/service/app_datetime.dart';
import 'package:rokwire_plugin/service/events2.dart';

class DeviceCalendarEvent extends rokwire.DeviceCalendarEvent {

  DeviceCalendarEvent({super.internalEventId, super.title, super.deepLinkUrl, super.startDate, super.endDate});

  static DeviceCalendarEvent? from(dynamic data){
    if (data is Event2) {
      return DeviceCalendarEvent.fromEvent2(data);
    }
    else if (data is Game){
      return DeviceCalendarEvent.fromGame(data);
    }
    else if (data is GuideFavorite) {
      return DeviceCalendarEvent.fromGuide(data);
    }
    else if (data is Appointment) {
      return DeviceCalendarEvent.fromAppointment(data);
    }
    else if (data is CanvasCalendarEvent) {
      return DeviceCalendarEvent.fromCanvasCalendarEvent(data);
    }
    else {
      return null;
    }
  }

  factory DeviceCalendarEvent.fromEvent2(Event2 event) => DeviceCalendarEvent(
    title: event.exploreTitle,
    internalEventId: event.id,
    startDate: AppDateTime().getUniLocalTimeFromUtcTime(event.startTimeUtc),
    endDate: AppDateTime().getUniLocalTimeFromUtcTime(event.endTimeUtc),
    deepLinkUrl: Events2.eventDetailUrl(event),
  );

  factory DeviceCalendarEvent.fromGame(Game game) => DeviceCalendarEvent(
    title: game.title,
    internalEventId: game.id,
    startDate: game.dateTimeUniLocal,
    endDate:  AppDateTime().getUniLocalTimeFromUtcTime(game.endDateTimeUtc),
    deepLinkUrl: "${Sports().gameDetailUrl}?game_id=${game.id}%26sport=${game.sport?.shortName}"
  );

  static DeviceCalendarEvent? fromGuide(GuideFavorite guide){
    Map<String, dynamic>? guideEntryData = Guide().entryById(guide.id);
    //Only reminders are allowed to save
    return (Guide().isEntryReminder(guideEntryData)) ? DeviceCalendarEvent(
        title: Guide().entryListTitle(guideEntryData, stripHtmlTags: true),
        internalEventId: guide.id,
        startDate: Guide().reminderDate(guideEntryData),
        deepLinkUrl: Guide().detailUrl(guide.id)
      ) : null;
  }

  factory DeviceCalendarEvent.fromAppointment(Appointment appointment) {
    DateTime? calendarEventStartDateTime = AppDateTime().getUniLocalTimeFromUtcTime(appointment.startTimeUtc);
    DateTime? calendarEventEndDateTime = calendarEventStartDateTime?.add(Duration(hours: 1));
    return DeviceCalendarEvent(
      title: appointment.title,
      internalEventId: appointment.id,
      startDate: calendarEventStartDateTime,
      endDate: calendarEventEndDateTime,
      deepLinkUrl: "${Appointments().appointmentDetailUrl}?appointment_id=${appointment.id}"
    );
  }

  factory DeviceCalendarEvent.fromCanvasCalendarEvent(CanvasCalendarEvent event) => DeviceCalendarEvent(
    title: event.title,
    internalEventId: event.id?.toString(),
    startDate: event.startAtLocal,
    endDate: event.endAtLocal,
    deepLinkUrl: "${Canvas().canvasEventDetailUrl}?event_id=${event.id}"
  );
}
