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

import 'package:illinois/service/AppDateTime.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/model/explore.dart';
import 'package:rokwire_plugin/service/assets.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class Appointment with Explore, Favorite {
  static final String _serverDateTimeFormat = 'yyyy-MM-ddTHH:mm:sssZ';

  final String? id;
  final String? sourceId;//TBD
  final String? accountId;//TBD
  final DateTime? dateTimeUtc;
  final AppointmentType? type;
  final AppointmentOnlineDetails? onlineDetails;
  final AppointmentLocation? location;
  final bool? cancelled;
  final String? instructions;
  final AppointmentHost? host;

  Appointment(
      {this.id, this.sourceId, this.accountId, this.dateTimeUtc, this.type, this.onlineDetails, this.location, this.cancelled, this.instructions, this.host});

  static Appointment? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return Appointment(
        id: JsonUtils.stringValue(json['id']),
        sourceId: JsonUtils.stringValue(json['source_id']),//TBD
        accountId: JsonUtils.stringValue(json['account_id']),//TBD
        dateTimeUtc: DateTimeUtils.dateTimeFromString(json['date'], format: _serverDateTimeFormat, isUtc: true),
        type: typeFromString(JsonUtils.stringValue(json['type'])),
        onlineDetails: AppointmentOnlineDetails.fromJson(JsonUtils.mapValue(json['online_details'])),
        location: AppointmentLocation.fromJson(JsonUtils.mapValue(json['location'])),
        cancelled: JsonUtils.boolValue(json['cancelled']),
        instructions: JsonUtils.stringValue(json['instructions']),
        host: AppointmentHost.fromJson(JsonUtils.mapValue(json['host'])));
  }

  String? get displayDate {
    return AppDateTime().formatDateTime(dateTimeUtc, format: 'MMM dd, H:mma');
  }

  bool get isUpcoming {
    DateTime now = DateTime.now();
    return (dateTimeUtc != null) && dateTimeUtc!.isAfter(now.toUtc());
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

  String? get imageUrl {
    return _randomImageUrl;
  }

  String? get _randomImageUrl {
    return Assets().randomStringFromListWithKey('images.random.events.Other');
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

  static String? typeToDisplayString(AppointmentType? type) {
    switch (type) {
      case AppointmentType.in_person:
        return Localization().getStringEx('model.wellness.appointment.type.in_person.label', 'In Person');
      case AppointmentType.online:
        return Localization().getStringEx('model.wellness.appointment.type.online.label', 'Telehealth');
      default:
        return null;
    }
  }

  static String? typeToKeyString(AppointmentType? type) {
    switch (type) {
      case AppointmentType.in_person:
        return 'InPerson';
      case AppointmentType.online:
        return 'Online';
      default:
        return null;
    }
  }

  static AppointmentType? typeFromString(String? type) {
    switch (type) {
      case 'InPerson':
        return AppointmentType.in_person;
      case 'Online':
        return AppointmentType.online;
      default:
        return null;
    }
  }

  // Favorite
  static const String favoriteKeyName = "appointmentIds";
  @override String get favoriteKey => favoriteKeyName;
  @override String? get favoriteId => sourceId;
  
  // Explore
  @override String? get exploreId => sourceId;
  @override String? get exploreImageURL => imageUrl;
  @override ExploreLocation? get exploreLocation => ExploreLocation(locationId: location?.id, latitude: location?.latitude, longitude: location?.longitude, description: location?.title);
  @override String? get exploreLongDescription => null;
  @override String? get explorePlaceId => null;
  @override String? get exploreShortDescription => null;
  @override DateTime? get exploreStartDateUtc => dateTimeUtc;
  @override String? get exploreSubTitle => location?.title;
  @override String? get exploreTitle => title;
  @override Map<String, dynamic> toJson() {
    return {
      'id': id,
      'source_id': sourceId,
      'account_id': accountId,
      'title': title,
      'date_time': DateTimeUtils.utcDateTimeToString(dateTimeUtc),
      'type': typeToKeyString(type),
      'location': location?.toJson(),
      'online_details': onlineDetails?.toJson(),
      'cancelled': cancelled,
      'instructions': instructions,
      'host': host?.toJson()
    };
  }

  static bool canJson(Map<String, dynamic>? json) {
    return (json != null) &&
      (json['account_id'] != null) &&
      (json['date_time'] != null) &&
      (json['type'] != null);
  }

  @override
  bool operator==(dynamic other) =>
    (other is Appointment) &&
    (id == other.id) &&
    (sourceId == other.sourceId) &&
    (accountId == other.accountId) &&
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
    (sourceId?.hashCode ?? 0) ^
    (accountId?.hashCode ?? 0) ^
    (dateTimeUtc?.hashCode ?? 0) ^
    (type?.hashCode ?? 0) ^
    (onlineDetails?.hashCode ?? 0) ^
    (location?.hashCode ?? 0) ^
    (cancelled?.hashCode ?? 0) ^
    (instructions?.hashCode ?? 0) ^
    (host?.hashCode ?? 0);
}

enum AppointmentType { in_person, online }

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

class AppointmentLocation {
  final String? id;
  final double? latitude;
  final double? longitude;
  final String? title;
  final String? phone;

  AppointmentLocation({this.id, this.latitude, this.longitude, this.title, this.phone});

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
