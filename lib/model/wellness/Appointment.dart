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
  final AppointmentUnit? unit;
  final AppointmentLocation? location;
  final AppointmentHost? host;
  final List<AppointmentAnswer>? answers;
  final String? notes;

  final AppointmentOnlineDetails? onlineDetails;
  final String? instructions;
  final bool? cancelled;

  //Util fields
  String? imageUrl; // to return same random image for this instance

  Appointment({
    this.id, this.type, this.startTimeUtc, this.endTimeUtc,
    this.provider, this.unit, this.location, this.host, this.answers, this.notes,
    this.onlineDetails, this.instructions, this.cancelled,
  });

  factory Appointment.fromOther(Appointment? other, {
    String? id, AppointmentType? type, DateTime? startTimeUtc, DateTime? endTimeUtc,
    AppointmentProvider? provider, AppointmentUnit? unit, AppointmentLocation? location, AppointmentHost? host, List<AppointmentAnswer>? answers, String? notes, 
    AppointmentOnlineDetails? onlineDetails, String? instructions, bool? cancelled,
  }) {
    return Appointment(
      id: id ?? other?.id,
      type: type ?? other?.type,
      startTimeUtc: startTimeUtc ?? other?.startTimeUtc,
      endTimeUtc: startTimeUtc ?? other?.endTimeUtc,
      
      provider: provider ?? other?.provider,
      unit: unit ?? other?.unit,
      location: location ?? other?.location,
      host: host ?? other?.host,
      answers: answers ?? other?.answers,
      notes: notes ?? other?.notes,
      
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
      endTimeUtc: DateTimeUtils.dateTimeFromString(json['end_time'], format: _serverDateTimeFormat, isUtc: true),

      provider: AppointmentProvider.fromJson(JsonUtils.mapValue(json['provider'])) ,
      unit: AppointmentUnit.fromJson(JsonUtils.mapValue(json['unit'])) ,
      location: AppointmentLocation.fromJson(JsonUtils.mapValue(json['location'])),
      host: AppointmentHost.fromJson(JsonUtils.mapValue(json['host'])),
      answers: AppointmentAnswer.listFromJson(JsonUtils.listValue(json['answers'])),
      notes: JsonUtils.stringValue(json['user_notes']),
      
      onlineDetails: AppointmentOnlineDetails.fromJson(JsonUtils.mapValue(json['online_details'])),
      instructions: JsonUtils.stringValue(json['instructions']),
      cancelled: JsonUtils.boolValue(json['cancelled']),
    ) : null;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': appointmentTypeToString(type),
    'date': DateTimeUtils.utcDateTimeToString(startTimeUtc, format: _serverDateTimeFormat),
    'end_time': DateTimeUtils.utcDateTimeToString(endTimeUtc, format: _serverDateTimeFormat),

    'provider': provider?.toJson(),
    'unit': unit?.toJson(),
    'location': location?.toJson(),
    'host': host?.toJson(),
    'answers': AppointmentAnswer.listToJson(answers),
    'user_notes': notes,

    'online_details': onlineDetails?.toJson(),
    'instructions': instructions,
    'cancelled': cancelled,
    
  };

  @override
  bool operator==(dynamic other) =>
    (other is Appointment) &&
    (startTimeUtc == other.startTimeUtc) &&
    (endTimeUtc == other.endTimeUtc) &&

    (id == other.id) &&
    (type == other.type) &&

    (provider == other.provider) &&
    (unit == other.unit) &&
    (location == other.location) &&
    (host == other.host) &&
    (DeepCollectionEquality().equals(answers, other.answers)) &&
    (notes == other.notes) &&

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
    (unit?.hashCode ?? 0) ^
    (location?.hashCode ?? 0) ^
    (host?.hashCode ?? 0) ^
    (DeepCollectionEquality().hash(answers)) ^
    (notes?.hashCode ?? 0) ^

    (onlineDetails?.hashCode ?? 0) ^
    (instructions?.hashCode ?? 0) ^
    (cancelled?.hashCode ?? 0);

  // Accessories

  bool get isUpcoming =>
    startTimeUtc?.isAfter(DateTime.now().toUtc()) ?? false;

  String? get locationTitle =>
    unit?.name ?? location?.title;

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
  @override DateTime? get exploreStartDateUtc => startTimeUtc;
  @override String? get exploreSubTitle => locationTitle;
  @override String? get exploreTitle => "${provider?.name ?? 'MyMcKinley'} Appointment";
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
  final String? id;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? email;
  final String? speciality;
  final String? description;
  final String? photoUrl;

  AppointmentHost({this.id, this.firstName, this.lastName, this.phone, this.email, this.speciality, this.description, this.photoUrl});

  // JSON Serialization

  static AppointmentHost? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? AppointmentHost(
      id: JsonUtils.stringValue(json['id']),
      firstName: JsonUtils.stringValue(json['first_name']),
      lastName: JsonUtils.stringValue(json['last_name']),
      phone: JsonUtils.stringValue(json['phone']),
      email: JsonUtils.stringValue(json['email']),
      speciality: JsonUtils.stringValue(json['speciality']),
      description: JsonUtils.stringValue(json['description']),
      photoUrl: JsonUtils.stringValue(json['image_url']),
    ) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': firstName,
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'email': email,
      'speciality': speciality,
      'description': description,
      'image_url': photoUrl,
    };
  }

  @override
  bool operator==(dynamic other) =>
    (other is AppointmentHost) &&
    (id == other.id) &&
    (firstName == other.firstName) &&
    (lastName == other.lastName) &&
    (phone == other.phone) &&
    (email == other.email) &&
    (speciality == other.speciality) &&
    (description == other.description) &&
    (photoUrl == other.photoUrl);

  @override
  int get hashCode =>
    (id?.hashCode ?? 0) ^
    (firstName?.hashCode ?? 0) ^
    (lastName?.hashCode ?? 0) ^
    (phone?.hashCode ?? 0) ^
    (email?.hashCode ?? 0) ^
    (speciality?.hashCode ?? 0) ^
    (description?.hashCode ?? 0) ^
    (photoUrl?.hashCode ?? 0);
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
  static final String descriptionDetailKey = 'description';

  final String? id;
  final String? providerId;
  final String? name;
  final String? address;
  final AppointmentLocation? location;
  final String? hoursOfOperation;
  final String? imageUrl;
  final Map<String, dynamic>? details;

  AppointmentUnit({this.id, this.providerId, this.name, this.address, this.location, this.hoursOfOperation, this.imageUrl, this.details});

  // JSON Serialization

  static AppointmentUnit? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? AppointmentUnit(
      id: JsonUtils.stringValue(json['id']),
      providerId: JsonUtils.stringValue(json['provider_id']),
      name: JsonUtils.stringValue(json['name']),
      address: JsonUtils.stringValue(json['address']),
      location: AppointmentLocation.fromJson(JsonUtils.mapValue(json['location'])),
      hoursOfOperation: JsonUtils.stringValue(json['hours_of_operations']),
      imageUrl: JsonUtils.stringValue(json['image_url']),
      details: JsonUtils.mapValue(json['details']),
    ) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'provider_id': providerId,
      'name': name,
      'address': address,
      'location': location?.toJson(),
      'hours_of_operations': hoursOfOperation,
      'image_url': imageUrl,
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
    (address == other.address) &&
    (location == other.location) &&
    (hoursOfOperation == other.hoursOfOperation) &&
    (imageUrl == other.imageUrl) &&
    (DeepCollectionEquality().equals(details, other.details));

  @override
  int get hashCode =>
    (id?.hashCode ?? 0) ^
    (providerId?.hashCode ?? 0) ^
    (name?.hashCode ?? 0) ^
    (address?.hashCode ?? 0) ^
    (location?.hashCode ?? 0) ^
    (hoursOfOperation?.hashCode ?? 0) ^
    (imageUrl?.hashCode ?? 0) ^
    (DeepCollectionEquality().hash(details));

  // Accessories

  String? get desriptionDetail =>
    (details != null) ? JsonUtils.stringValue(details![descriptionDetailKey]) : null;

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

  AppointmentQuestion({this.id, this.providerId, this.unitId, this.hostId,
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
  final List<String>? answers;

  AppointmentAnswer({this.questionId, this.providerId, this.unitId, this.hostId, this.answers});

  factory AppointmentAnswer.fromQuestion(AppointmentQuestion? question, { List<String>? answers }) =>
    AppointmentAnswer(
      questionId: question?.id,
      providerId: question?.providerId,
      unitId: question?.unitId,
      hostId: question?.hostId,
      answers: answers,
    );

  // JSON Serialization

  static AppointmentAnswer? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? AppointmentAnswer(
      questionId: JsonUtils.stringValue(json['question_id']),
      providerId: JsonUtils.stringValue(json['provider_id']),
      unitId: JsonUtils.stringValue(json['unit_id']),
      hostId: JsonUtils.stringValue(json['person_id']),
      answers: JsonUtils.stringListValue(json['answer']),
    ) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'question_id': questionId,
      'provider_id': providerId,
      'unit_id': unitId,
      'person_id': hostId,
      'answers': answers,
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
    (DeepCollectionEquality().equals(answers, other.answers));

  @override
  int get hashCode =>
    (questionId?.hashCode ?? 0) ^
    (providerId?.hashCode ?? 0) ^
    (unitId?.hashCode ?? 0) ^
    (hostId?.hashCode ?? 0) ^
    (DeepCollectionEquality().hash(answers));

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

  final String? providerId;
  final String? unitId;
  final DateTime? startTimeUtc;
  final DateTime? endTimeUtc;
  final String? capacity;
  final bool? filled;
  final Map<String, dynamic>? details;

  AppointmentTimeSlot({this.providerId, this.unitId, this.startTimeUtc, this.endTimeUtc, this.capacity, this.filled, this.details});

  factory AppointmentTimeSlot.fromAppointment(Appointment? appointment) => AppointmentTimeSlot(
    startTimeUtc: appointment?.startTimeUtc,
    endTimeUtc: appointment?.endTimeUtc,
  );

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
    (DeepCollectionEquality().equals(details, other.details));

  @override
  int get hashCode =>
    (providerId?.hashCode ?? 0) ^
    (unitId?.hashCode ?? 0) ^
    (startTimeUtc?.hashCode ?? 0) ^
    (endTimeUtc?.hashCode ?? 0) ^
    (capacity?.hashCode ?? 0) ^
    (filled?.hashCode ?? 0) ^
    (DeepCollectionEquality().hash(details));

  // Accessories

  DateTime? get startTime => startTimeUtc?.toLocal();
  DateTime? get endTime => endTimeUtc?.toLocal();
}
