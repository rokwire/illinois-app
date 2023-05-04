
import 'dart:math';

import 'package:illinois/model/Appointment.dart';
import 'package:intl/intl.dart';
import 'package:rokwire_plugin/service/app_datetime.dart';
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
    this.provider?.name ?? Localization().getStringEx('model.academics.appointment.default.provider.label', 'MyMcKinley');

  String? get category =>
    sprintf(Localization().getStringEx('model.academics.appointment.category.label.format', '%s Appointments'), [displayProviderName]).toUpperCase();

  String? get title =>
    sprintf(Localization().getStringEx('model.academics.appointment.title.label.format', '%s Appointment'), [displayProviderName]);

  String? get imageKey =>
    cachedImageKey ??= buildImageKey(type: type, provider: provider);

  static String? buildImageKey({AppointmentType? type, AppointmentUnit? unit, AppointmentProvider? provider}) {
    if (type == AppointmentType.online) {
      return 'photo-online';
    }
    else if (type == AppointmentType.in_person) {
      return (unit?.imageKey(provider: provider) ?? provider?.randomImageKey ?? AppointmentProviderExt.defaultImageKey);
    }
    else {
      return Assets().randomStringFromListWithKey('images.random.events.Other');
    }
  }
}

///////////////////////////////
/// AppointmentHost

extension AppointmentHostExt on AppointmentHost {
  String? get displayName => StringUtils.fullName([firstName, lastName]);
}

///////////////////////////////
/// AppointmentProvider

extension AppointmentProviderExt on AppointmentProvider {
  static const String mcKinleyName = 'McKinley';
  static const String graingerName = 'Grainger';
  static const String defaultImageKey = 'photo-building';

  String get randomImageKey =>
    indexedImageKey(Random().nextInt(256));

  String indexedImageKey(int index) => (name == graingerName) ?
    'photo-grainger-${(index.abs() % 2) + 1}' : defaultImageKey;
}

///////////////////////////////
/// AppointmentUnit

extension AppointmentUnitExt on AppointmentUnit {
  String? get displayNextAvailableTime => (nextAvailableTimeUtc != null) ?
    DateFormat('EEEE, MMMM d, yyyy hh:mm aaa').format(nextAvailableTimeUtc!.toUniOrLocal()) :
    Localization().getStringEx('panel.appointment.schedule.next_available_appointment.unknown.label', 'Unknown');

  String? get displayNumberOfPersons {
    int count = numberOfPersons ?? 0;
    return (1 < count) ? sprintf(Localization().getStringEx('panel.appointment.schedule.persons_count.label', '%s Advisors'), [count]) :
          ((0 < count) ?
            Localization().getStringEx('panel.appointment.schedule.person1_count.label', '1 Advisor') :
            Localization().getStringEx('panel.appointment.schedule.person0_count.label', 'No Advisors')
          );
  }

  String? imageKey({AppointmentProvider? provider, int? index}) =>
    cachedImageKey ??= ((provider != null) ?
      ((index != null) ? provider.indexedImageKey(index) : provider.randomImageKey) :
      AppointmentProviderExt.defaultImageKey
    );
}

///////////////////////////////
/// AppointmentPerson

extension AppointmentPersonExt on AppointmentPerson {
  String? get displayNextAvailableTime => (nextAvailableTimeUtc != null) ?
    DateFormat('EEEE, MMMM d, yyyy hh:mm aaa').format(nextAvailableTimeUtc!.toUniOrLocal()) :
    Localization().getStringEx('panel.appointment.schedule.next_available_appointment.unknown.label', 'Unknown');

  String? get displayNumberOfAvailableSlots {
    int count = numberOfAvailableSlots ?? 0;
    return (1 < count) ? sprintf(Localization().getStringEx('panel.appointment.schedule.slots_count.label', '%s Slots Available'), [count]) :
          ((0 < count) ?
            Localization().getStringEx('panel.appointment.schedule.slot1_count.label', '1 Slot Available') :
            Localization().getStringEx('panel.appointment.schedule.slot0_count.label', 'No Slots Available')
          );
  }
}

///////////////////////////////
/// AppointmentTimeSlot

extension AppointmentTimeSlotExt on AppointmentTimeSlot {

  DateTime? get startTime => startTimeUtc?.toUniOrLocal();
  DateTime? get endTime => endTimeUtc?.toUniOrLocal();

  String? get displayScheduleTime =>
    getDisplayScheduleTime(startTimeUtc, endTimeUtc);

  static String? getDisplayScheduleTime(DateTime? startTimeUtc, DateTime? endTimeUtc) {
    if (startTimeUtc != null) {
      if (endTimeUtc != null) {
        //AppDateTime().getDeviceTimeFromUtcTime(startTime)
        String startTimeStr = DateFormat('EEEE, MMMM d, yyyy hh:mm').format(startTimeUtc.toUniOrLocal());
        String endTimeStr = DateFormat('hh:mm aaa').format(endTimeUtc.toUniOrLocal());
        return "$startTimeStr - $endTimeStr";
      }
      else {
        return DateFormat('EEEE, MMMM d, yyyy hh:mm aaa').format(startTimeUtc.toUniOrLocal());
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

String? appointmentTypeToDisplayString(AppointmentType? type) {
  switch (type) {
    case AppointmentType.in_person:
      return Localization().getStringEx('model.academics.appointment.type.in_person.label', 'In Person');
    case AppointmentType.online:
      return Localization().getStringEx('model.academics.appointment.type.online.label', 'Telehealth');
    default:
      return null;
  }
}

String appointment2TypeDisplayString(AppointmentType _appointmentType) {
  switch (_appointmentType) {
    case AppointmentType.in_person: return Localization().getStringEx('model.academics.appointment2.type.in_person.label', 'In Person');
    case AppointmentType.online: return Localization().getStringEx('model.academics.appointment2.type.online.label', 'Online');
  }
}
