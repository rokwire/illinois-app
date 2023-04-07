
import 'package:illinois/model/wellness/Appointment.dart';
import 'package:illinois/service/AppDateTime.dart';
import 'package:rokwire_plugin/service/assets.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/utils/utils.dart';

///////////////////////////////
/// Appointment

extension AppointmentExt on Appointment {

  String? get displayDate {
    return AppDateTime().formatDateTime(AppDateTime().getDeviceTimeFromUtcTime(dateTimeUtc), format: 'MMM dd, h:mm a');
  }

  String? get hostDisplayName {
    String? displayName;
    if (host != null) {
      displayName = StringUtils.fullName([host!.firstName, host!.lastName]);
    }
    return displayName;
  }

  String? get category {
    return Localization().getStringEx('model.wellness.appointment.category.label', 'MYMCKINLEY APPOINTMENTS');
  }

  String? get title {
    return Localization().getStringEx('model.wellness.appointment.title.label', 'MyMcKinley Appointment');
  }

  String? get imageKeyBasedOnCategory { //Keep consistent images
    return (type != null) ?
      appointmentTypeImageKey(type!) :
      (imageUrl ??= Assets().randomStringFromListWithKey('images.random.events.Other'));
  }
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
