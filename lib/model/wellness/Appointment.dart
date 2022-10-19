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
  final String? uin;
  final DateTime? dateTimeUtc;
  final AppointmentType? type;
  final AppointmentOnlineDetails? onlineDetails;
  final AppointmentLocation? location;
  final bool? cancelled;
  final String? instructions;
  final AppointmentHost? host;

  Appointment(
      {this.id, this.uin, this.dateTimeUtc, this.type, this.onlineDetails, this.location, this.cancelled, this.instructions, this.host});

  static Appointment? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return Appointment(
        id: JsonUtils.stringValue(json['id']),
        uin: JsonUtils.stringValue(json['uin']),
        dateTimeUtc: DateTimeUtils.dateTimeFromString(json['date_time'], format: _serverDateTimeFormat, isUtc: true),
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
    //TBD: Appointment - check how to retrieve the image
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
  @override String? get favoriteId => id;
  
  // Explore
  @override String? get exploreId => id;
  @override String? get exploreImageURL => imageUrl;
  @override ExploreLocation? get exploreLocation => ExploreLocation(locationId: location?.id, latitude: location?.latitude, longitude: location?.longitude);
  @override String? get exploreLongDescription => null;
  @override String? get explorePlaceId => null;
  @override String? get exploreShortDescription => null;
  @override DateTime? get exploreStartDateUtc => dateTimeUtc;
  @override String? get exploreSubTitle => null;
  @override String? get exploreTitle => title;
  @override Map<String, dynamic> toJson() {
    //TBD: Appointment - implement
    throw UnimplementedError();
  }
}

enum AppointmentType { in_person, online }

class AppointmentOnlineDetails {
  final String? url;
  final String? meetingId;
  final String? meetingPasscode;

  AppointmentOnlineDetails({this.url, this.meetingId, this.meetingPasscode});

  static AppointmentOnlineDetails? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return AppointmentOnlineDetails(
        url: JsonUtils.stringValue(json['url']),
        meetingId: JsonUtils.stringValue(json['meeting_id']),
        meetingPasscode: JsonUtils.stringValue(json['meeting_passcode']));
  }
}

class AppointmentLocation {
  final String? id;
  final double? latitude;
  final double? longitude;
  final String? title;
  final String? phone;

  AppointmentLocation({this.id, this.latitude, this.longitude, this.title, this.phone});

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
}

class AppointmentHost {
  final String? firstName;
  final String? lastName;

  AppointmentHost({this.firstName, this.lastName});

  static AppointmentHost? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return AppointmentHost(firstName: JsonUtils.stringValue(json['first_name']), lastName: JsonUtils.stringValue(json['last_name']));
  }
}
