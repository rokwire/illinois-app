/*
 * Copyright 2022 Board of Trustees of the University of Illinois.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:collection/collection.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/model/explore.dart';
import 'package:rokwire_plugin/utils/utils.dart';

enum AppointmentType { in_person, online }

///////////////////////////////
/// Appointment

class Appointment with Explore, Favorite {
  static final String _serverDateTimeFormat = 'yyyy-MM-ddTHH:mm:sssZ';

  final String? id;
  final AppointmentProvider? provider;
  final AppointmentUnit? unit;
  final DateTime? dateTimeUtc;
  final AppointmentType? type;
  final AppointmentOnlineDetails? onlineDetails;
  final AppointmentLocation? location;
  final bool? cancelled;
  final String? instructions;
  final String? notes;
  final AppointmentHost? host;

  //Util fields
  String? imageUrl; // to return same random image for this instance

  Appointment({
    this.id, this.provider, this.unit,
    this.dateTimeUtc, this.type, this.onlineDetails, this.location,
    this.cancelled, this.instructions, this.notes, this.host
  });

  static Appointment? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return Appointment(
      id: JsonUtils.stringValue(json['id']),
      provider: AppointmentProvider.fromJson(JsonUtils.mapValue(json['provider'])) ,
      unit: AppointmentUnit.fromJson(JsonUtils.mapValue(json['unit'])) ,
      dateTimeUtc: DateTimeUtils.dateTimeFromString(json['date'], format: _serverDateTimeFormat, isUtc: true),
      type: appointmentTypeFromString(JsonUtils.stringValue(json['type'])),
      onlineDetails: AppointmentOnlineDetails.fromJson(JsonUtils.mapValue(json['online_details'])),
      location: AppointmentLocation.fromJson(JsonUtils.mapValue(json['location'])),
      cancelled: JsonUtils.boolValue(json['cancelled']),
      instructions: JsonUtils.stringValue(json['instructions']),
      notes: JsonUtils.stringValue(json['user_notes']),
      host: AppointmentHost.fromJson(JsonUtils.mapValue(json['host']))
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'provider': provider?.toJson(),
    'unit': unit?.toJson(),
    'date': DateTimeUtils.utcDateTimeToString(dateTimeUtc, format: _serverDateTimeFormat),
    'type': appointmentTypeToString(type),
    'location': location?.toJson(),
    'online_details': onlineDetails?.toJson(),
    'cancelled': cancelled,
    'instructions': instructions,
    'user_notes': notes,
    'host': host?.toJson()
  };

  bool get isUpcoming {
    DateTime now = DateTime.now();
    return (dateTimeUtc != null) && dateTimeUtc!.isAfter(now.toUtc());
  }

  static List<Appointment>? listFromJson(List<dynamic>? jsonList) {
    List<Appointment>? items;
    if (jsonList != null) {
      items = <Appointment>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(items, Appointment.fromJson(jsonEntry));
      }
    }
    return items;
  }

  // Favorite
  static const String favoriteKeyName = "appointmentIds";
  @override String get favoriteKey => favoriteKeyName;
  @override String? get favoriteId => id;
  
  // Explore
  @override String? get exploreId => id;
  @override String? get exploreImageURL => imageUrl;
  @override ExploreLocation? get exploreLocation => ExploreLocation(locationId: location?.id, latitude: location?.latitude, longitude: location?.longitude, description: location?.title);
  @override String? get exploreLongDescription => null;
  @override String? get explorePlaceId => null;
  @override String? get exploreShortDescription => null;
  @override DateTime? get exploreStartDateUtc => dateTimeUtc;
  @override String? get exploreSubTitle => location?.title;
  @override String? get exploreTitle => "${provider?.name ?? 'MyMcKinley'} Appointment";
//@override Map<String, dynamic> toJson();

  @override
  bool operator==(dynamic other) =>
    (other is Appointment) &&
    (id == other.id) &&
    (provider == other.provider) &&
    (unit == other.unit) &&
    (dateTimeUtc == other.dateTimeUtc) &&
    (type == other.type) &&
    (onlineDetails == other.onlineDetails) &&
    (location == other.location) &&
    (cancelled == other.cancelled) &&
    (instructions == other.instructions) &&
    (host == other.host);

  @override
  int get hashCode =>
    (id?.hashCode ?? 0) ^
    (provider?.hashCode ?? 0) ^
    (unit?.hashCode ?? 0) ^
    (dateTimeUtc?.hashCode ?? 0) ^
    (type?.hashCode ?? 0) ^
    (onlineDetails?.hashCode ?? 0) ^
    (location?.hashCode ?? 0) ^
    (cancelled?.hashCode ?? 0) ^
    (instructions?.hashCode ?? 0) ^
    (host?.hashCode ?? 0);
}

///////////////////////////////
/// AppointmentType

AppointmentType? appointmentTypeFromString(String? value) {
  switch (value) {
    case 'InPerson': return AppointmentType.in_person;
    case 'Online': return AppointmentType.online;
  }
  return null;
}

String? appointmentTypeToString(AppointmentType? value) {
  switch (value) {
    case AppointmentType.in_person: return 'InPerson';
    case AppointmentType.online: return 'Online';
    default: return null;
  }
}

///////////////////////////////
/// AppointmentOnlineDetails

class AppointmentOnlineDetails {
  final String? url;
  final String? meetingId;
  final String? meetingPasscode;

  AppointmentOnlineDetails({this.url, this.meetingId, this.meetingPasscode});

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'meeting_id': meetingId,
      'meeting_passcode': meetingPasscode
    };
  }

  static AppointmentOnlineDetails? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return AppointmentOnlineDetails(
        url: JsonUtils.stringValue(json['url']),
        meetingId: JsonUtils.stringValue(json['meeting_id']),
        meetingPasscode: JsonUtils.stringValue(json['meeting_passcode']));
  }

  @override
  bool operator==(dynamic other) =>
    (other is AppointmentOnlineDetails) &&
    (url == other.url) &&
    (meetingId == other.meetingId) &&
    (meetingPasscode == other.meetingPasscode);

  @override
  int get hashCode =>
    (url?.hashCode ?? 0) ^
    (meetingId?.hashCode ?? 0) ^
    (meetingPasscode?.hashCode ?? 0);
}

///////////////////////////////
/// AppointmentLocation

class AppointmentLocation {
  final String? id;
  final double? latitude;
  final double? longitude;
  final String? title;
  final String? phone;

  AppointmentLocation({this.id, this.latitude, this.longitude, this.title, this.phone});

  String? get address => title; //TBD: ?

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'title': title,
      'phone': phone
    };
  }

  static AppointmentLocation? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return AppointmentLocation(
        id: JsonUtils.stringValue(json['id']),
        latitude: JsonUtils.doubleValue(json['latitude']),
        longitude: JsonUtils.doubleValue(json['longitude']),
        title: JsonUtils.stringValue(json['title']),
        phone: JsonUtils.stringValue(json['phone']));
  }

  @override
  bool operator==(dynamic other) =>
    (other is AppointmentLocation) &&
    (id == other.id) &&
    (latitude == other.latitude) &&
    (longitude == other.longitude) &&
    (title == other.title) &&
    (phone == other.phone);

  @override
  int get hashCode =>
    (id?.hashCode ?? 0) ^
    (latitude?.hashCode ?? 0) ^
    (longitude?.hashCode ?? 0) ^
    (title?.hashCode ?? 0) ^
    (phone?.hashCode ?? 0);
}

///////////////////////////////
/// AppointmentHost

class AppointmentHost {
  final String? firstName;
  final String? lastName;

  AppointmentHost({this.firstName, this.lastName});

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'last_name': lastName
    };
  }

  static AppointmentHost? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return AppointmentHost(firstName: JsonUtils.stringValue(json['first_name']), lastName: JsonUtils.stringValue(json['last_name']));
  }

  @override
  bool operator==(dynamic other) =>
    (other is AppointmentHost) &&
    (firstName == other.firstName) &&
    (lastName == other.lastName);

  @override
  int get hashCode =>
    (firstName?.hashCode ?? 0) ^
    (lastName?.hashCode ?? 0);
}

///////////////////////////////
/// AppointmentsAccount

class AppointmentsAccount {
  bool? notificationsAppointmentNew;
  bool? notificationsAppointmentReminderMorning;
  bool? notificationsAppointmentReminderNight;

  AppointmentsAccount(
      {this.notificationsAppointmentNew, this.notificationsAppointmentReminderMorning, this.notificationsAppointmentReminderNight});

  Map<String, dynamic> toJson() {
    return {
      'notifications_appointment_new': notificationsAppointmentNew,
      'notifications_appointment_reminder_morning': notificationsAppointmentReminderMorning,
      'notifications_appointment_reminder_night': notificationsAppointmentReminderNight
    };
  }

  static AppointmentsAccount? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return AppointmentsAccount(
        notificationsAppointmentNew: JsonUtils.boolValue(json['notifications_appointment_new']),
        notificationsAppointmentReminderMorning: JsonUtils.boolValue(json['notifications_appointment_reminder_morning']),
        notificationsAppointmentReminderNight: JsonUtils.boolValue(json['notifications_appointment_reminder_night']));
  }
}


///////////////////////////////
/// AppointmentProvider

class AppointmentProvider {
  final String? id;
  final String? name;
  final bool? supportsSchedule;
  final bool? supportsReschedule;
  final bool? supportsCancel;

  AppointmentProvider({
    this.id, this.name,
    this.supportsSchedule, this.supportsReschedule, this.supportsCancel
  });

  // JSON Serialization

  static AppointmentProvider? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? AppointmentProvider(
      id: JsonUtils.stringValue(json['id']),
      name: JsonUtils.stringValue(json['name']),
      supportsSchedule: JsonUtils.boolValue(json['supports_schedule']),
      supportsReschedule: JsonUtils.boolValue(json['supports_reschedule']),
      supportsCancel: JsonUtils.boolValue(json['supports_cancel']),
    ) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'supports_schedule': supportsSchedule,
      'supports_reschedule': supportsReschedule,
      'supports_cancel': supportsCancel,
    };
  }

  static List<AppointmentProvider>? listFromJson(List<dynamic>? jsonList) {
    List<AppointmentProvider>? result;
    if (jsonList != null) {
      result = <AppointmentProvider>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(result, AppointmentProvider.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return result;
  }

  static List<dynamic>? listToJson(List<AppointmentProvider>? contentList) {
    List<dynamic>? jsonList;
    if (contentList != null) {
      jsonList = <dynamic>[];
      for (dynamic contentEntry in contentList) {
        jsonList.add(contentEntry?.toJson());
      }
    }
    return jsonList;
  }

  // Euality

  @override
  bool operator==(dynamic other) =>
    (other is AppointmentProvider) &&
    (id == other.id) &&
    (name == other.name) &&
    (supportsSchedule == other.supportsSchedule) &&
    (supportsReschedule == other.supportsReschedule) &&
    (supportsCancel == other.supportsCancel);

  @override
  int get hashCode =>
    (id?.hashCode ?? 0) ^
    (name?.hashCode ?? 0) ^
    (supportsSchedule?.hashCode ?? 0) ^
    (supportsReschedule?.hashCode ?? 0) ^
    (supportsCancel?.hashCode ?? 0);

  // Accessories

  static AppointmentProvider? findInList(List<AppointmentProvider>? providers, { String? id }) {
    if (providers != null) {
      for (AppointmentProvider provider in providers) {
        if ((id == null) || (provider.id == id)) {
          return provider;
        }

      }
    }
    return null;
  }
}

///////////////////////////////
/// AppointmentUnit

class AppointmentUnit {
  final String? id;
  final String? providerId;
  final String? name;
  final AppointmentLocation? location;
  final String? hoursOfOperation;
  final String? details;

  AppointmentUnit({this.id, this.providerId, this.name, this.location, this.hoursOfOperation, this.details});

  // JSON Serialization

  static AppointmentUnit? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? AppointmentUnit(
      id: JsonUtils.stringValue(json['id']),
      providerId: JsonUtils.stringValue(json['provider_id']),
      name: JsonUtils.stringValue(json['name']),
      location: AppointmentLocation.fromJson(JsonUtils.mapValue(json['location'])),
      hoursOfOperation: JsonUtils.stringValue(json['hours_of_operation']),
      details: JsonUtils.stringValue(json['details']),
    ) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'provider_id': providerId,
      'name': name,
      'location': location?.toJson(),
      'hours_of_operation': hoursOfOperation,
      'details': details,
    };
  }

  static List<AppointmentUnit>? listFromJson(List<dynamic>? jsonList) {
    List<AppointmentUnit>? result;
    if (jsonList != null) {
      result = <AppointmentUnit>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(result, AppointmentUnit.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return result;
  }

  static List<dynamic>? listToJson(List<AppointmentUnit>? contentList) {
    List<dynamic>? jsonList;
    if (contentList != null) {
      jsonList = <dynamic>[];
      for (dynamic contentEntry in contentList) {
        jsonList.add(contentEntry?.toJson());
      }
    }
    return jsonList;
  }

  // Euality

  @override
  bool operator==(dynamic other) =>
    (other is AppointmentUnit) &&
    (id == other.id) &&
    (providerId == other.providerId) &&
    (name == other.name) &&
    (location == other.location) &&
    (hoursOfOperation == other.hoursOfOperation) &&
    (details == other.details);

  @override
  int get hashCode =>
    (id?.hashCode ?? 0) ^
    (providerId?.hashCode ?? 0) ^
    (name?.hashCode ?? 0) ^
    (location?.hashCode ?? 0) ^
    (hoursOfOperation?.hashCode ?? 0) ^
    (details?.hashCode ?? 0);

  // Accessories

  //...
}

///////////////////////////////
/// AppointmentTimeSlot

class AppointmentTimeSlot {
  static final String dateTimeFormat = 'yyyy-MM-ddTHH:mm:ssZ';

  final String? providerId;
  final String? unitId;
  final DateTime? startTimeUtc;
  final DateTime? endTimeUtc;
  final String? capacity;
  final bool? filled;
  final Map<String, dynamic>? details;
  final String? notes;
  final bool? notesRequired;

  AppointmentTimeSlot({this.providerId, this.unitId, this.startTimeUtc, this.endTimeUtc, this.capacity, this.filled, this.details, this.notes, this.notesRequired});

  // JSON Serialization

  static AppointmentTimeSlot? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? AppointmentTimeSlot(
      providerId: JsonUtils.stringValue(json['provider_id']),
      unitId: JsonUtils.stringValue(json['unit_id']),
      startTimeUtc: DateTimeUtils.dateTimeFromString(JsonUtils.stringValue(json['start_time']), format: dateTimeFormat, isUtc: true),
      endTimeUtc: DateTimeUtils.dateTimeFromString(JsonUtils.stringValue(json['end_time']), format: dateTimeFormat, isUtc: true),
      capacity: JsonUtils.stringValue(json['capacity']),
      filled: JsonUtils.boolValue(json['filled']),
      details: JsonUtils.mapValue(json['details']),
      notes: JsonUtils.stringValue(json['notes']),
      notesRequired: JsonUtils.boolValue(json['notes_required']),
    ) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'provider_id': providerId,
      'unit_id': unitId,
      'start_time': DateTimeUtils.utcDateTimeToString(startTimeUtc, format: dateTimeFormat),
      'end_time': DateTimeUtils.utcDateTimeToString(endTimeUtc, format: dateTimeFormat),
      'capacity': capacity,
      'filled': filled,
      'details': details,
      'notes': notes,
      'notes_required': notesRequired,
    };
  }

  static List<AppointmentTimeSlot>? listFromJson(List<dynamic>? jsonList) {
    List<AppointmentTimeSlot>? result;
    if (jsonList != null) {
      result = <AppointmentTimeSlot>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(result, AppointmentTimeSlot.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return result;
  }

  static List<dynamic>? listToJson(List<AppointmentTimeSlot>? contentList) {
    List<dynamic>? jsonList;
    if (contentList != null) {
      jsonList = <dynamic>[];
      for (dynamic contentEntry in contentList) {
        jsonList.add(contentEntry?.toJson());
      }
    }
    return jsonList;
  }

  // Euality

  @override
  bool operator==(dynamic other) =>
    (other is AppointmentTimeSlot) &&
    (providerId == other.providerId) &&
    (unitId == other.unitId) &&
    (startTimeUtc == other.startTimeUtc) &&
    (endTimeUtc == other.endTimeUtc) &&
    (capacity == other.capacity) &&
    (filled == other.filled) &&
    (DeepCollectionEquality().equals(details, other.details)) &&
    (notes == other.notes) &&
    (notesRequired == other.notesRequired);

  @override
  int get hashCode =>
    (providerId?.hashCode ?? 0) ^
    (unitId?.hashCode ?? 0) ^
    (startTimeUtc?.hashCode ?? 0) ^
    (endTimeUtc?.hashCode ?? 0) ^
    (capacity?.hashCode ?? 0) ^
    (filled?.hashCode ?? 0) ^
    (DeepCollectionEquality().hash(details)) ^
    (notes?.hashCode ?? 0) ^
    (notesRequired?.hashCode ?? 0);

  // Accessories

  DateTime? get startTime => startTimeUtc?.toLocal();
  DateTime? get endTime => endTimeUtc?.toLocal();

}
