
import 'package:illinois/model/Appointment.dart';
import 'package:intl/intl.dart';
import 'package:rokwire_plugin/service/assets.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:sprintf/sprintf.dart';

///////////////////////////////
/// Appointment

extension AppointmentExt on Appointment {

  String? get displayScheduleTime =>
    AppointmentTimeSlotExt.getDisplayScheduleTime(startTimeUtc, endTimeUtc);

  int? get startMinutesSinceMidnightUtc =>
    AppointmentTimeSlotExt.getStartMinutesSinceMidnightUtc(startTimeUtc);

  String get displayProviderName =>
    this.provider?.name ?? Localization().getStringEx('model.wellness.appointment.default.provider.label', 'MyMcKinley');

  String? get category =>
    sprintf(Localization().getStringEx('model.wellness.appointment.category.label.format', '%s Appointments'), [displayProviderName]).toUpperCase();

  String? get title =>
    sprintf(Localization().getStringEx('model.wellness.appointment.title.label.format', '%s Appointment'), [displayProviderName]);

  String? get imageKeyBasedOnCategory => //Keep consistent images
    (type != null) ? appointmentTypeImageKey(type!) : (imageUrl ??= Assets().randomStringFromListWithKey('images.random.events.Other'));
}

///////////////////////////////
/// AppointmentHost

extension AppointmentHostExt on AppointmentHost {
  String? get displayName => StringUtils.fullName([firstName, lastName]);
}

///////////////////////////////
/// AppointmentTimeSlot

extension AppointmentTimeSlotExt on AppointmentTimeSlot {

  String? get displayScheduleTime =>
    getDisplayScheduleTime(startTimeUtc, endTimeUtc);

  static String? getDisplayScheduleTime(DateTime? startTimeUtc, DateTime? endTimeUtc) {
    if (startTimeUtc != null) {
      if (endTimeUtc != null) {
        //AppDateTime().getDeviceTimeFromUtcTime(startTime)
        String startTimeStr = DateFormat('EEEE, MMMM d, yyyy hh:mm').format(startTimeUtc.toLocal());
        String endTimeStr = DateFormat('hh:mm aaa').format(endTimeUtc.toLocal());
        return "$startTimeStr - $endTimeStr";
      }
      else {
        return DateFormat('EEEE, MMMM d, yyyy hh:mm aaa').format(startTimeUtc.toLocal());
      }
    }
    return null;
  }

  int? get startMinutesSinceMidnightUtc =>
    getStartMinutesSinceMidnightUtc(startTimeUtc);

  static int? getStartMinutesSinceMidnightUtc(DateTime? startTimeUtc) =>
    (startTimeUtc != null) ? (startTimeUtc.hour * 60 + startTimeUtc.minute) : null;
}

///////////////////////////////
/// AppointmentType

String appointmentTypeImageKey(AppointmentType appointmentType) {
  switch (appointmentType) {
    case AppointmentType.in_person: return 'photo-building';
    case AppointmentType.online: return 'photo-online';
  }
}

String? appointmentTypeToDisplayString(AppointmentType? type) {
  switch (type) {
    case AppointmentType.in_person:
      return Localization().getStringEx('model.wellness.appointment.type.in_person.label', 'In Person');
    case AppointmentType.online:
      return Localization().getStringEx('model.wellness.appointment.type.online.label', 'Telehealth');
    default:
      return null;
  }
}

String appointment2TypeDisplayString(AppointmentType _appointmentType) {
  switch (_appointmentType) {
    case AppointmentType.in_person: return Localization().getStringEx('model.wellness.appointment2.type.in_person.label', 'In Person');
    case AppointmentType.online: return Localization().getStringEx('model.wellness.appointment2.type.online.label', 'Online');
  }
}
