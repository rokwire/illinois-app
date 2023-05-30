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
  final AppointmentType? type;
  final DateTime? startTimeUtc;
  final DateTime? endTimeUtc;

  final AppointmentProvider? provider;
  final String? unitId;
  final String? personId;
  final List<AppointmentAnswer>? answers;

  final AppointmentHost? host;
  final AppointmentLocation? location;
  final AppointmentOnlineDetails? onlineDetails;
  final String? instructions;
  final bool? cancelled;

  String? cachedImageKey;

  Appointment({
    this.id, this.type, this.startTimeUtc, this.endTimeUtc,
    this.provider, this.unitId, this.personId, this.answers,
    this.host, this.location, this.onlineDetails, this.instructions, this.cancelled,
  });

  factory Appointment.fromOther(Appointment? other, {
    String? id, AppointmentType? type, DateTime? startTimeUtc, DateTime? endTimeUtc,
    AppointmentProvider? provider, String? unitId, String? personId, List<AppointmentAnswer>? answers,
    AppointmentHost? host, AppointmentLocation? location, AppointmentOnlineDetails? onlineDetails, String? instructions, bool? cancelled,
  }) {
    return Appointment(
      id: id ?? other?.id,
      type: type ?? other?.type,
      startTimeUtc: startTimeUtc ?? other?.startTimeUtc,
      endTimeUtc: startTimeUtc ?? other?.endTimeUtc,
      
      unitId: unitId ?? other?.unitId,
      personId: personId ?? other?.personId,
      provider: provider ?? other?.provider,
      answers: answers ?? other?.answers,
      
      host: host ?? other?.host,
      location: location ?? other?.location,
      onlineDetails: onlineDetails ?? other?.onlineDetails,
      instructions: instructions ?? other?.instructions,
      cancelled: cancelled ?? other?.cancelled,
    );
  }

  static Appointment? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? Appointment(
      id: JsonUtils.stringValue(json['id']),
      type: appointmentTypeFromString(JsonUtils.stringValue(json['type'])),
      startTimeUtc: DateTimeUtils.dateTimeFromString(json['date'], format: _serverDateTimeFormat, isUtc: true),
      endTimeUtc: DateTimeUtils.dateTimeFromString(json['end_date'], format: _serverDateTimeFormat, isUtc: true),

      provider: AppointmentProvider.fromJson(JsonUtils.mapValue(json['provider'])),
      unitId: JsonUtils.stringValue(json['unit_id']),
      personId: JsonUtils.stringValue(json['person_id']),
      answers: AppointmentAnswer.listFromJson(JsonUtils.listValue(json['answers'])),
      
      host: AppointmentHost.fromJson(JsonUtils.mapValue(json['host'])),
      location: AppointmentLocation.fromJson(JsonUtils.mapValue(json['location'])),
      onlineDetails: AppointmentOnlineDetails.fromJson(JsonUtils.mapValue(json['online_details'])),
      instructions: JsonUtils.stringValue(json['instructions']),
      cancelled: JsonUtils.boolValue(json['cancelled']),
    ) : null;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': appointmentTypeToString(type),
    'date': DateTimeUtils.utcDateTimeToString(startTimeUtc, format: _serverDateTimeFormat),
    'end_date': DateTimeUtils.utcDateTimeToString(endTimeUtc, format: _serverDateTimeFormat),

    'provider': provider?.toJson(),
    'unit_id': unitId,
    'person_id': personId,
    'answers': AppointmentAnswer.listToJson(answers),

    'host': host?.toJson(),
    'location': location?.toJson(),
    'online_details': onlineDetails?.toJson(),
    'instructions': instructions,
    'cancelled': cancelled,
    
  };

  @override
  bool operator==(dynamic other) =>
    (other is Appointment) &&
    (id == other.id) &&
    (type == other.type) &&
    (startTimeUtc == other.startTimeUtc) &&
    (endTimeUtc == other.endTimeUtc) &&

    (provider == other.provider) &&
    (unitId == other.unitId) &&
    (personId == other.personId) &&
    (DeepCollectionEquality().equals(answers, other.answers)) &&

    (host == other.host) &&
    (location == other.location) &&
    (onlineDetails == other.onlineDetails) &&
    (instructions == other.instructions) &&
    (cancelled == other.cancelled);


  @override
  int get hashCode =>
    (id?.hashCode ?? 0) ^
    (type?.hashCode ?? 0) ^
    (startTimeUtc?.hashCode ?? 0) ^
    (endTimeUtc?.hashCode ?? 0) ^

    (provider?.hashCode ?? 0) ^
    (unitId?.hashCode ?? 0) ^
    (personId?.hashCode ?? 0) ^
    (DeepCollectionEquality().hash(answers)) ^

    (host?.hashCode ?? 0) ^
    (location?.hashCode ?? 0) ^
    (onlineDetails?.hashCode ?? 0) ^
    (instructions?.hashCode ?? 0) ^
    (cancelled?.hashCode ?? 0);

  // Accessories

  String? get providerId => provider?.id;

  bool get isUpcoming =>
    startTimeUtc?.isAfter(DateTime.now().toUtc()) ?? false;

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
  @override String? get exploreTitle => "${provider?.name} Appointment";
  @override String? get exploreDescription => null;
  @override DateTime? get exploreDateTimeUtc => startTimeUtc;
  @override String? get exploreImageURL => null;
  @override ExploreLocation? get exploreLocation => ExploreLocation(id: location?.id, latitude: location?.latitude, longitude: location?.longitude, description: location?.title);
//@override Map<String, dynamic> toJson();
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

  factory AppointmentLocation.fromUnit(AppointmentUnit unit) {
    return AppointmentLocation(
      id: unit.id,
      title: unit.address
    );
  }

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

  factory AppointmentHost.fromPerson(AppointmentPerson person) {
    String? firstName, lastName;
    List<String>? names = person.name?.split(' ');
    if ((names != null) && (names.length > 1)) {
      firstName = names[0];
      lastName = (names.length > 2) ? names.sublist(1).join(' ') : names[1];
    }
    else {
      firstName = person.name;
    }
    return AppointmentHost(firstName: firstName, lastName: lastName);
  }

  // JSON Serialization

  static AppointmentHost? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? AppointmentHost(
      firstName: JsonUtils.stringValue(json['first_name']),
      lastName: JsonUtils.stringValue(json['last_name']),
    ) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'last_name': lastName,
    };
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

  const AppointmentProvider({
    this.id, this.name,
    this.supportsSchedule, this.supportsReschedule, this.supportsCancel
  });

  // JSON Serialization

  static AppointmentProvider? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? AppointmentProvider(
      id: JsonUtils.stringValue(json['id']),
      name: JsonUtils.stringValue(json['name']),
      supportsSchedule: JsonUtils.boolValue(json['scheduling']),
      supportsReschedule: JsonUtils.boolValue(json['rescheduling']),
      supportsCancel: JsonUtils.boolValue(json['canceling']),
    ) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'scheduling': supportsSchedule,
      'rescheduling': supportsReschedule,
      'canceling': supportsCancel,
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

  static AppointmentProvider? findInList(List<AppointmentProvider>? providers, { String? id, bool? supportsSchedule, bool? supportsReschedule, bool? supportsCancel }) {
    if (providers != null) {
      for (AppointmentProvider provider in providers) {
        if (((id == null) || (provider.id == id)) &&
            ((supportsSchedule == null) || (provider.supportsSchedule == supportsSchedule)) &&
            ((supportsReschedule == null) || (provider.supportsReschedule == supportsReschedule)) &&
            ((supportsCancel == null) || (provider.supportsCancel == supportsCancel))) {
          return provider;
        }
      }
    }
    return null;
  }

  static List<AppointmentProvider>? subList(List<AppointmentProvider>? providers, { bool? supportsSchedule, bool? supportsReschedule, bool? supportsCancel }) {
    List<AppointmentProvider>? result;
    if (providers != null) {
      result = <AppointmentProvider>[];
      for (AppointmentProvider provider in providers) {
        if (((supportsSchedule == null) || (provider.supportsSchedule == supportsSchedule)) &&
            ((supportsReschedule == null) || (provider.supportsReschedule == supportsReschedule)) &&
            ((supportsCancel == null) || (provider.supportsCancel == supportsCancel))) {
          result.add(provider);
        }
      }
    }
    return result;
  }
}

///////////////////////////////
/// AppointmentUnit

class AppointmentUnit {
  static final String dateTimeFormat = 'yyyy-MM-ddTHH:mm:ssZ';

  final String? id;
  final String? providerId;
  final String? name;
  final String? address;
  final String? collegeName;
  final String? collegeCode;
  final String? imageUrl;
  final String? notes;
  final String? hoursOfOperation;
  final int?    numberOfPersons;
  final DateTime? nextAvailableTimeUtc;

  String? cachedImageKey;

  AppointmentUnit({this.id, this.providerId,
    this.name, this.address, this.collegeName, this.collegeCode, this.imageUrl,
    this.notes, this.hoursOfOperation, this.numberOfPersons, this.nextAvailableTimeUtc
  });

  // JSON Serialization

  static AppointmentUnit? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? AppointmentUnit(
      id: JsonUtils.stringValue(json['id']),
      providerId: JsonUtils.stringValue(json['provider_id']),
      name: JsonUtils.stringValue(json['name']),
      address: JsonUtils.stringValue(json['address']),
      collegeName: JsonUtils.stringValue(json['college_name']),
      collegeCode: JsonUtils.stringValue(json['college_code']),
      imageUrl: JsonUtils.stringValue(json['image_url']),
      notes: JsonUtils.stringValue(json['notes']),
      hoursOfOperation: JsonUtils.stringValue(json['hours_of_operations']),
      numberOfPersons: JsonUtils.intValue(json['number_available_people']),
      nextAvailableTimeUtc: DateTimeUtils.dateTimeFromString(JsonUtils.stringValue(json['next_available']), format: dateTimeFormat, isUtc: true)
    ) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'provider_id': providerId,
      'name': name,
      'address': address,
      'college_name': collegeName,
      'college_code': collegeCode,
      'image_url': imageUrl,
      'notes': notes,
      'hours_of_operations': hoursOfOperation,
      'number_available_people': numberOfPersons,
      'next_available': DateTimeUtils.utcDateTimeToString(nextAvailableTimeUtc, format: dateTimeFormat),
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
    (address == other.address) &&
    (collegeName == other.collegeName) &&
    (collegeCode == other.collegeCode) &&
    (imageUrl == other.imageUrl) &&
    (notes == other.notes) &&
    (hoursOfOperation == other.hoursOfOperation) &&
    (numberOfPersons == other.numberOfPersons) &&
    (nextAvailableTimeUtc == other.nextAvailableTimeUtc);

  @override
  int get hashCode =>
    (id?.hashCode ?? 0) ^
    (providerId?.hashCode ?? 0) ^
    (name?.hashCode ?? 0) ^
    (address?.hashCode ?? 0) ^
    (collegeName?.hashCode ?? 0) ^
    (collegeCode?.hashCode ?? 0) ^
    (imageUrl?.hashCode ?? 0) ^
    (notes?.hashCode ?? 0) ^
    (hoursOfOperation?.hashCode ?? 0) ^
    (numberOfPersons?.hashCode ?? 0) ^
    (nextAvailableTimeUtc?.hashCode ?? 0);

  // Accessories

  static AppointmentUnit? findInList(List<AppointmentUnit>? units, { String? id }) {
    if (units != null) {
      for (AppointmentUnit unit in units) {
        if ((id != null) && (unit.id == id)) {
          return unit;
        }
      }
    }
    return null;
  }

  //...
}

///////////////////////////////
/// AppointmentPerson

class AppointmentPerson {
  static final String dateTimeFormat = 'yyyy-MM-ddTHH:mm:ssZ';

  final String? id;
  final String? providerId;
  final String? unitId;
  final String? name;
  final String? imageUrl;
  final String? notes;
  final int?    numberOfAvailableSlots;
  final DateTime? nextAvailableTimeUtc;

  const AppointmentPerson({this.id, this.providerId, this.unitId,
    this.name, this.imageUrl, this.notes,
    this.numberOfAvailableSlots, this.nextAvailableTimeUtc});

  // JSON Serialization

  static AppointmentPerson? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? AppointmentPerson(
      id: JsonUtils.stringValue(json['id']),
      providerId: JsonUtils.stringValue(json['provider_id']),
      unitId: JsonUtils.stringValue(json['unit_id']),
      name: JsonUtils.stringValue(json['name']),
      imageUrl: JsonUtils.stringValue(json['image_url']),
      notes: JsonUtils.stringValue(json['notes']),
      numberOfAvailableSlots: JsonUtils.intValue(json['number_available_slots']),
      nextAvailableTimeUtc: DateTimeUtils.dateTimeFromString(JsonUtils.stringValue(json['next_available']), format: dateTimeFormat, isUtc: true)
    ) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'provider_id': providerId,
      'unit_id': unitId,
      'name': name,
      'image_url': imageUrl,
      'notes': imageUrl,
      'number_available_slots': numberOfAvailableSlots,
      'next_available': DateTimeUtils.utcDateTimeToString(nextAvailableTimeUtc, format: dateTimeFormat),
    };
  }

  static List<AppointmentPerson>? listFromJson(List<dynamic>? jsonList) {
    List<AppointmentPerson>? result;
    if (jsonList != null) {
      result = <AppointmentPerson>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(result, AppointmentPerson.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return result;
  }

  static List<dynamic>? listToJson(List<AppointmentPerson>? contentList) {
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
    (other is AppointmentPerson) &&
    (id == other.id) &&
    (providerId == other.providerId) &&
    (unitId == other.unitId) &&
    (name == other.name) &&
    (imageUrl == other.imageUrl) &&
    (notes == other.notes) &&
    (numberOfAvailableSlots == other.numberOfAvailableSlots) &&
    (nextAvailableTimeUtc == other.nextAvailableTimeUtc);

  @override
  int get hashCode =>
    (id?.hashCode ?? 0) ^
    (providerId?.hashCode ?? 0) ^
    (unitId?.hashCode ?? 0) ^
    (name?.hashCode ?? 0) ^
    (imageUrl?.hashCode ?? 0) ^
    (notes?.hashCode ?? 0) ^
    (numberOfAvailableSlots?.hashCode ?? 0) ^
    (nextAvailableTimeUtc?.hashCode ?? 0);

  // Accessories

  static AppointmentPerson? findInList(List<AppointmentPerson>? persons, { String? id }) {
    if (persons != null) {
      for (AppointmentPerson person in persons) {
        if ((id != null) && (person.id == id)) {
          return person;
        }
      }
    }
    return null;
  }

  //...
}

///////////////////////////////
/// AppointmentQuestion

class AppointmentQuestion {
  final String? id;
  final String? providerId;
  final String? unitId;
  final String? hostId;

  final String? title;
  final bool? required;
  final AppointmentQuestionType? type;
  final List<String>? values;

  const AppointmentQuestion({this.id, this.providerId, this.unitId, this.hostId,
    this.title, this.required, this.type, this.values
  });

  // JSON Serialization

  static AppointmentQuestion? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? AppointmentQuestion(
      id: JsonUtils.stringValue(json['id']),
      providerId: JsonUtils.stringValue(json['provider_id']),
      unitId: JsonUtils.stringValue(json['unit_id']),
      hostId: JsonUtils.stringValue(json['person_id']),

      title: JsonUtils.stringValue(json['question']),
      required: JsonUtils.boolValue(json['required']),
      type: AppointmentQuestionType.fromJson(JsonUtils.stringValue(json['type'])),
      values: JsonUtils.listStringsValue(json['selection_values']),
    ) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'provider_id': providerId,
      'unit_id': unitId,
      'person_id': hostId,

      'question': title,
      'required': required,
      'type': type?.toJson(),
      'values': values,
    };
  }

  static List<AppointmentQuestion>? listFromJson(List<dynamic>? jsonList) {
    List<AppointmentQuestion>? result;
    if (jsonList != null) {
      result = <AppointmentQuestion>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(result, AppointmentQuestion.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return result;
  }

  static List<dynamic>? listToJson(List<AppointmentQuestion>? contentList) {
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
    (other is AppointmentQuestion) &&
    (id == other.id) &&
    (providerId == other.providerId) &&
    (unitId == other.unitId) &&
    (hostId == other.hostId) &&

    (title == other.title) &&
    (required == other.required) &&
    (type == other.type) &&
    (DeepCollectionEquality().equals(values, other.values));

  @override
  int get hashCode =>
    (id?.hashCode ?? 0) ^
    (providerId?.hashCode ?? 0) ^
    (unitId?.hashCode ?? 0) ^
    (hostId?.hashCode ?? 0) ^

    (title?.hashCode ?? 0) ^
    (required?.hashCode ?? 0) ^
    (type?.hashCode ?? 0) ^
    (DeepCollectionEquality().hash(values));

  // Accessories

  //...
}

///////////////////////////////
/// AppointmentAnswer

class AppointmentAnswer {
  final String? questionId;
  final String? providerId;
  final String? unitId;
  final String? hostId;
  final List<String>? values;

  const AppointmentAnswer({this.questionId, this.providerId, this.unitId, this.hostId, this.values});

  factory AppointmentAnswer.fromQuestion(AppointmentQuestion? question, { List<String>? values }) =>
    AppointmentAnswer(
      questionId: question?.id,
      providerId: question?.providerId,
      unitId: question?.unitId,
      hostId: question?.hostId,
      values: values,
    );

  // JSON Serialization

  static AppointmentAnswer? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? AppointmentAnswer(
      questionId: JsonUtils.stringValue(json['question_id']),
      providerId: JsonUtils.stringValue(json['provider_id']),
      unitId: JsonUtils.stringValue(json['unit_id']),
      hostId: JsonUtils.stringValue(json['person_id']),
      values: JsonUtils.stringListValue(json['values']),
    ) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'question_id': questionId,
      'provider_id': providerId,
      'unit_id': unitId,
      'person_id': hostId,
      'values': values,
    };
  }

  static List<AppointmentAnswer>? listFromJson(List<dynamic>? jsonList) {
    List<AppointmentAnswer>? result;
    if (jsonList != null) {
      result = <AppointmentAnswer>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(result, AppointmentAnswer.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return result;
  }

  static List<dynamic>? listToJson(List<AppointmentAnswer>? contentList) {
    List<dynamic>? jsonList;
    if (contentList != null) {
      jsonList = <dynamic>[];
      for (dynamic contentEntry in contentList) {
        jsonList.add(contentEntry?.toJson());
      }
    }
    return jsonList;
  }

  static AppointmentAnswer? findInList(List<AppointmentAnswer>? answers, { String? questionId}) {
    if (answers != null) {
      for (AppointmentAnswer answer in answers) {
        if ((questionId != null) && (answer.questionId == questionId)) {
          return answer;
        }
      }
    }
    return null;
  }

  // Euality

  @override
  bool operator==(dynamic other) =>
    (other is AppointmentAnswer) &&
    (questionId == other.questionId) &&
    (providerId == other.providerId) &&
    (unitId == other.unitId) &&
    (hostId == other.hostId) &&
    (DeepCollectionEquality().equals(values, other.values));

  @override
  int get hashCode =>
    (questionId?.hashCode ?? 0) ^
    (providerId?.hashCode ?? 0) ^
    (unitId?.hashCode ?? 0) ^
    (hostId?.hashCode ?? 0) ^
    (DeepCollectionEquality().hash(values));

  // Accessories

  //...
}

///////////////////////////////
/// AppointmentQuestionType

class AppointmentQuestionType {
  static const AppointmentQuestionType text = AppointmentQuestionType._internal('text');
  static const AppointmentQuestionType select = AppointmentQuestionType._internal('select');
  static const AppointmentQuestionType multiSelect = AppointmentQuestionType._internal('multi-select');
  static const AppointmentQuestionType checkbox = AppointmentQuestionType._internal('checkbox');

  final String _value;

  const AppointmentQuestionType._internal(this._value);

  static AppointmentQuestionType? fromString(String? value) =>
    (value != null) ? AppointmentQuestionType._internal(value) : null;

  static AppointmentQuestionType? fromJson(dynamic value) =>
    (value is String) ? AppointmentQuestionType._internal(value) : null;

  @override
  String toString() => _value;

  String toJson() => _value;

  @override
  bool operator==(dynamic other) =>
    (other is AppointmentQuestionType) && (other._value == _value);

  @override
  int get hashCode => _value.hashCode;
}

///////////////////////////////
/// AppointmentTimeSlot

class AppointmentTimeSlot {
  static final String dateTimeFormat = 'yyyy-MM-ddTHH:mm:ssZ';

  final String? id;
  final String? providerId;
  final String? unitId;
  final DateTime? startTimeUtc;
  final DateTime? endTimeUtc;
  final int? capacity;
  final int? filled;
  final Map<String, dynamic>? details;

  AppointmentTimeSlot({ this.id, this.providerId, this.unitId, this.startTimeUtc, this.endTimeUtc, this.capacity, this.filled, this.details});

  factory AppointmentTimeSlot.fromAppointment(Appointment? appointment) => AppointmentTimeSlot(
    startTimeUtc: appointment?.startTimeUtc,
    endTimeUtc: appointment?.endTimeUtc,
  );

  // JSON Serialization

  static AppointmentTimeSlot? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? AppointmentTimeSlot(
      id: JsonUtils.stringValue(json['id']),
      providerId: JsonUtils.stringValue(json['provider_id']),
      unitId: JsonUtils.stringValue(json['unit_id']),
      startTimeUtc: DateTimeUtils.dateTimeFromString(JsonUtils.stringValue(json['start_time']), format: dateTimeFormat, isUtc: true),
      endTimeUtc: DateTimeUtils.dateTimeFromString(JsonUtils.stringValue(json['end_time']), format: dateTimeFormat, isUtc: true),
      capacity: JsonUtils.intValue(json['capacity']),
      filled: JsonUtils.intValue(json['filled']),
      details: JsonUtils.mapValue(json['details']),
    ) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'provider_id': providerId,
      'unit_id': unitId,
      'start_time': DateTimeUtils.utcDateTimeToString(startTimeUtc, format: dateTimeFormat),
      'end_time': DateTimeUtils.utcDateTimeToString(endTimeUtc, format: dateTimeFormat),
      'capacity': capacity,
      'filled': filled,
      'details': details,
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
    (id == other.id) &&
    (providerId == other.providerId) &&
    (unitId == other.unitId) &&
    (startTimeUtc == other.startTimeUtc) &&
    (endTimeUtc == other.endTimeUtc) &&
    (capacity == other.capacity) &&
    (filled == other.filled) &&
    (DeepCollectionEquality().equals(details, other.details));

  @override
  int get hashCode =>
    (id?.hashCode ?? 0) ^
    (providerId?.hashCode ?? 0) ^
    (unitId?.hashCode ?? 0) ^
    (startTimeUtc?.hashCode ?? 0) ^
    (endTimeUtc?.hashCode ?? 0) ^
    (capacity?.hashCode ?? 0) ^
    (filled?.hashCode ?? 0) ^
    (DeepCollectionEquality().hash(details));

  // Accessories
  bool get available => ((capacity != null) && (filled != null) && (0 <= filled!) && (filled! < capacity!));
}

///////////////////////////////
/// AppointmentTimeSlotsAndQuestions

class AppointmentTimeSlotsAndQuestions {
  final List<AppointmentTimeSlot>? timeSlots;
  final List<AppointmentQuestion>? questions;
  AppointmentTimeSlotsAndQuestions({this.timeSlots, this.questions});

  static AppointmentTimeSlotsAndQuestions? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? AppointmentTimeSlotsAndQuestions(
      timeSlots: AppointmentTimeSlot.listFromJson(JsonUtils.listValue(json['time_slots'])),
      questions: AppointmentQuestion.listFromJson(JsonUtils.listValue(json['questions'])),
    ) : null;
  }
}
