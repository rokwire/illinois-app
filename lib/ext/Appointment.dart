
import 'package:illinois/model/wellness/Appointment.dart';
import 'package:illinois/service/AppDateTime.dart';
import 'package:rokwire_plugin/service/assets.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:sprintf/sprintf.dart';

///////////////////////////////
/// Appointment

extension AppointmentExt on Appointment {

  String? get displayDate =>
    AppDateTime().formatDateTime(AppDateTime().getDeviceTimeFromUtcTime(startDateTimeUtc), format: 'MMM dd, h:mm a');

  String? get displayHostName =>
    host?.displayName;

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

  String? get displayName =>
    StringUtils.fullName([firstName, lastName]);

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
