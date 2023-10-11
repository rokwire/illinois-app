import 'package:collection/collection.dart';
import 'package:geolocator/geolocator.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:rokwire_plugin/model/explore.dart';
import 'package:rokwire_plugin/utils/utils.dart';

// StudentCourse

class StudentCourse with Explore {
  final String? title;
  final String? shortName;
  final String? number;
  final String? instructionMethod;
  final StudentCourseSection? section;

  StudentCourse({this.title, this.shortName, this.number, this.instructionMethod, this.section});

  static StudentCourse? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? StudentCourse(
      title: JsonUtils.stringValue(json['coursetitle']),
      shortName: JsonUtils.stringValue(json['courseshortname']),
      number: JsonUtils.stringValue(json['coursenumber']),
      instructionMethod: JsonUtils.stringValue(json['instructionmethod']),
      section: StudentCourseSection.fromJson(JsonUtils.mapValue(json['coursesection'])),
    ) : null;
  }

  toJson() => {
    'coursetitle': title,
    'courseshortname': shortName,
    'coursenumber': number,
    'instructionmethod': instructionMethod,
    'coursesection': section?.toJson(),
  };

  bool get hasValidLocation => section?.building?.hasValidLocation ?? false;

  String get detail => '$shortName ($number) $instructionMethod';
  
  @override
  bool operator==(dynamic other) =>
    (other is StudentCourse) &&
    (title == other.title) &&
    (shortName == other.shortName) &&
    (number == other.number) &&
    (instructionMethod == other.instructionMethod) &&
    (section == other.section);

  @override
  int get hashCode =>
    (title?.hashCode ?? 0) ^
    (shortName?.hashCode ?? 0) ^
    (number?.hashCode ?? 0) ^
    (instructionMethod?.hashCode ?? 0) ^
    (section?.hashCode ?? 0);

  // Explore implementation

  @override String? get exploreId => number;
  @override String? get exploreTitle => title ?? '';
  @override String? get exploreDescription => null;
  @override DateTime? get exploreDateTimeUtc => null;
  @override String? get exploreImageURL => null;
  @override ExploreLocation? get exploreLocation => section?.building?.exploreLocation;

  // List<StudentCourse>

  static List<StudentCourse>? listFromJson(List<dynamic>? jsonList) {
    List<StudentCourse>? values;
    if (jsonList != null) {
      values = <StudentCourse>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(values, StudentCourse.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return values;
  }

  static List<dynamic>? listToJson(List<StudentCourse>? values) {
    List<dynamic>? jsonList;
    if (values != null) {
      jsonList = <dynamic>[];
      for (StudentCourse value in values) {
        ListUtils.add(jsonList, value.toJson());
      }
    }
    return jsonList;
  }
}

// StudentCourseSection

class StudentCourseSection {
  final String? buildingId;
  final String? buildingName;
  final String? room;

  final String? instructionType;
  final String? instructor;

  final String? days;
  final String? startTime;
  final String? endTime;
  final String? meetingDates;

  final Building? building;

  StudentCourseSection({
    this.buildingId, this.buildingName, this.room,
    this.instructionType, this.instructor,
    this.days, this.startTime, this.endTime, this.meetingDates,
    this.building
  });

  static StudentCourseSection? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? StudentCourseSection(
      buildingId: JsonUtils.stringValue(json['buildingid']),
      buildingName: JsonUtils.stringValue(json['buildingname']),
      room: JsonUtils.stringValue(json['room']),

      instructionType: JsonUtils.stringValue(json['instructiontype']),
      instructor: JsonUtils.stringValue(json['instructor']),

      days: JsonUtils.stringValue(json['days']),
      startTime: JsonUtils.stringValue(MapUtils.get2(json, ['starttime', 'start_time'])),
      endTime: JsonUtils.stringValue(MapUtils.get2(json, ['endtime', 'end_time'])),
      meetingDates: JsonUtils.stringValue(json['meeting_dates_or_range']),
      
      building: Building.fromJson(JsonUtils.mapValue(json['building'])),
    ) : null;
  }

  toJson() => {
    'buildingid': buildingId,
    'buildingname': buildingName,
    'room': room,

    'instructiontype': instructionType,
    'instructor': instructor,

    'days': days,
    'starttime': startTime,
    'endtime': endTime,
    'meeting_dates_or_range': meetingDates,

    'building': building?.toJson(),
  };

  @override
  bool operator==(dynamic other) =>
    (other is StudentCourseSection) &&
    
    (buildingName == other.buildingName) &&
    (room == other.room) &&

    (instructionType == other.instructionType) &&
    (instructor == other.instructor) &&

    (days == other.days) &&
    (startTime == other.startTime) &&
    (endTime == other.endTime) &&

    (building == other.building);

  @override
  int get hashCode =>
    (buildingName?.hashCode ?? 0) ^
    (room?.hashCode ?? 0) ^

    (instructionType?.hashCode ?? 0) ^
    (instructor?.hashCode ?? 0) ^

    (days?.hashCode ?? 0) ^
    (startTime?.hashCode ?? 0) ^
    (endTime?.hashCode ?? 0) ^

    (building?.hashCode ?? 0);

  static List<StudentCourseSection>? listFromJson(List<dynamic>? jsonList) {
    List<StudentCourseSection>? values;
    if (jsonList != null) {
      values = <StudentCourseSection>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(values, StudentCourseSection.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return values;
  }

  static List<dynamic>? listToJson(List<StudentCourseSection>? values) {
    List<dynamic>? jsonList;
    if (values != null) {
      jsonList = <dynamic>[];
      for (StudentCourseSection value in values) {
        ListUtils.add(jsonList, value.toJson());
      }
    }
    return jsonList;
  }
}

// Building

class Building with Explore {
  final String? id;
  final String? name;
  final String? number;
  
  final String? fullAddress;
  final String? address1;
  final String? address2;
  
  final String? city;
  final String? state;
  final String? zipCode;
  
  final String? imageURL;
  final String? mailCode;
  
  final double? latitude;
  final double? longitude;
  
  List<BuildingEntrance>? entrances;

  Building({
    this.id, this.name, this.number,
    this.fullAddress, this.address1, this.address2,
    this.city, this.state, this.zipCode,
    this.imageURL, this.mailCode,
    this.latitude, this.longitude,
    this.entrances,
  });

  static Building? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? Building(
      id: JsonUtils.stringValue(MapUtils.get2(json, ['id', 'ID'])),
      name: JsonUtils.stringValue(MapUtils.get2(json, ['name', 'Name'])),
      number: JsonUtils.stringValue(MapUtils.get2(json, ['number', 'Number'])),

      fullAddress: JsonUtils.stringValue(MapUtils.get2(json, ['fullAddress', 'FullAddress'])),
      address1: JsonUtils.stringValue(MapUtils.get2(json, ['address1', 'Address1'])),
      address2: JsonUtils.stringValue(MapUtils.get2(json, ['address2', 'Address2'])),

      city: JsonUtils.stringValue(MapUtils.get2(json, ['city', 'ZipCode'])),
      state: JsonUtils.stringValue(MapUtils.get2(json, ['state', 'State'])),
      zipCode: JsonUtils.stringValue(MapUtils.get2(json, ['zipCode', 'Address2'])),

      imageURL: JsonUtils.stringValue(MapUtils.get2(json, ['imageURL', 'ImageURL'])),
      mailCode: JsonUtils.stringValue(MapUtils.get2(json, ['mailCode', 'MailCode'])),

      latitude: JsonUtils.doubleValue(MapUtils.get2(json, ['latitude', 'Latitude'])),
      longitude: JsonUtils.doubleValue(MapUtils.get2(json, ['longitude', 'Longitude'])),

      entrances: BuildingEntrance.listFromJson(JsonUtils.listValue(MapUtils.get2(json, ['entrances', 'Entrances']))),
    ) : null;
  }

  toJson() => {
    'id': id,
    'name': name,
    'number': number,

    'fullAddress': fullAddress,
    'address1': address1,
    'address2': address2,

    'city': city,
    'state': state,
    'zipCode': zipCode,

    'imageURL': imageURL,
    'mailCode': mailCode,

    'latitude': latitude,
    'longitude': longitude,

    'entrances': BuildingEntrance.listToJson(entrances),
  };

  bool get hasValidLocation => (latitude != null) && (latitude != 0) && (longitude != null) && (longitude != 0);

  @override
  bool operator==(dynamic other) =>
    (other is Building) &&
    
    (id == other.id) &&
    (name == other.name) &&
    (number == other.number) &&
    
    (fullAddress == other.fullAddress) &&
    (address1 == other.address1) &&
    (address2 == other.address2) &&

    (city == other.city) &&
    (state == other.state) &&
    (mailCode == other.mailCode) &&

    (imageURL == other.imageURL) &&
    (zipCode == other.zipCode) &&
    
    (latitude == other.latitude) &&
    (longitude == other.longitude) &&
    
    DeepCollectionEquality().equals(entrances, other.entrances);

  @override
  int get hashCode =>
    (id?.hashCode ?? 0) ^
    (name?.hashCode ?? 0) ^
    (number?.hashCode ?? 0) ^

    (fullAddress?.hashCode ?? 0) ^
    (address1?.hashCode ?? 0) ^
    (address2?.hashCode ?? 0) ^

    (city?.hashCode ?? 0) ^
    (state?.hashCode ?? 0) ^
    (zipCode?.hashCode ?? 0) ^

    (imageURL?.hashCode ?? 0) ^
    (mailCode?.hashCode ?? 0) ^

    (latitude?.hashCode ?? 0) ^
    (longitude?.hashCode ?? 0) ^
    
    DeepCollectionEquality().hash(entrances);

  // Accessories
  BuildingEntrance? nearstEntrance(Position? position, {bool requireAda = false}) => 
    BuildingEntrance.nearstEntrance(entrances, position, requireAda: requireAda);

  // Explore implementation

  @override String? get exploreId => id;
  @override String? get exploreTitle => name;
  @override String? get exploreDescription => null;
  @override DateTime? get exploreDateTimeUtc => null;
  @override String? get exploreImageURL => null; //TMP: imageURL;
  @override ExploreLocation? get exploreLocation => ExploreLocation(
    building : name,
    description: fullAddress,
    address : address1,
    city : city,
    state : state,
    zip : zipCode,
    latitude : latitude,
    longitude : longitude,
  );

  // List<Building>

  static List<Building>? listFromJson(List<dynamic>? jsonList) {
    List<Building>? values;
    if (jsonList != null) {
      values = <Building>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(values, Building.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return values;
  }

  static List<dynamic>? listToJson(List<Building>? values) {
    List<dynamic>? jsonList;
    if (values != null) {
      jsonList = <dynamic>[];
      for (Building value in values) {
        ListUtils.add(jsonList, value.toJson());
      }
    }
    return jsonList;
  }

  static Building? findInList(List<Building>? values, {String? id}) {
    if (values != null) {
      for (Building value in values) {
        if ((id != null) && (value.id == id)) {
          return value;
        }
      }
    }
    return null;
  }
}

// BuildingEntrance

class BuildingEntrance {
  final String? id;
  final String? name;
  final bool? adaCompliant;
  final bool? available;
  final String? imageURL;
  final double? latitude;
  final double? longitude;
  
  BuildingEntrance({this.id, this.name, this.adaCompliant, this.available, this.imageURL, this.latitude, this.longitude});

  static BuildingEntrance? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? BuildingEntrance(
      id: JsonUtils.stringValue(MapUtils.get2(json, ['id', 'ID'])),
      name: JsonUtils.stringValue(MapUtils.get2(json, ['name', 'Name'])),
      adaCompliant: JsonUtils.boolValue(MapUtils.get2(json, ['adaCompliant', 'adacompliant', 'ADACompliant'])),
      available: JsonUtils.boolValue(MapUtils.get2(json, ['available', 'Available'])),
      imageURL: JsonUtils.stringValue(MapUtils.get2(json, ['imageURL', 'ImageURL'])),
      latitude: JsonUtils.doubleValue(MapUtils.get2(json, ['latitude', 'Latitude'])),
      longitude: JsonUtils.doubleValue(MapUtils.get2(json, ['longitude', 'Longitude'])),
    ) : null;
  }

  toJson() => {
    'id': id,
    'name': name,
    'adaCompliant': adaCompliant,
    'available': available,
    'imageURL': imageURL,
    'latitude': latitude,
    'longitude': longitude,
  };

  bool get hasValidLocation => (latitude != null) && (latitude != 0) && (longitude != null) && (longitude != 0);

  @override
  bool operator==(dynamic other) =>
    (other is BuildingEntrance) &&
    (id == other.id) &&
    (name == other.name) &&
    (adaCompliant == other.adaCompliant) &&
    (available == other.available) &&
    (imageURL == other.imageURL) &&
    (latitude == other.latitude) &&
    (longitude == other.longitude);

  @override
  int get hashCode =>
    (id?.hashCode ?? 0) ^
    (name?.hashCode ?? 0) ^
    (adaCompliant?.hashCode ?? 0) ^
    (available?.hashCode ?? 0) ^
    (imageURL?.hashCode ?? 0) ^
    (latitude?.hashCode ?? 0) ^
    (longitude?.hashCode ?? 0);

  static List<BuildingEntrance>? listFromJson(List<dynamic>? jsonList) {
    List<BuildingEntrance>? values;
    if (jsonList != null) {
      values = <BuildingEntrance>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(values, BuildingEntrance.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return values;
  }

  static List<dynamic>? listToJson(List<BuildingEntrance>? values) {
    List<dynamic>? jsonList;
    if (values != null) {
      jsonList = <dynamic>[];
      for (BuildingEntrance value in values) {
        ListUtils.add(jsonList, value.toJson());
      }
    }
    return jsonList;
  }

  // Accessories
  static BuildingEntrance? nearstEntrance(List<BuildingEntrance>?entrances, Position? position, {bool requireAda = false}) {
    if ((entrances != null) && (position != null)) {
      double? minDistance, minAdaDistance;
      BuildingEntrance? minEntrance, minAdaEntrance;
      for (BuildingEntrance entrance in entrances) {
        if (entrance.hasValidLocation) {
          double distance = GeoMapUtils.getDistance(entrance.latitude!, entrance.longitude!, position.latitude, position.longitude);
          if ((minDistance == null) || (distance < minDistance)) {
            minDistance = distance;
            minEntrance = entrance;
          }
          if (requireAda && (entrance.adaCompliant == true) && ((minAdaDistance == null) || (distance < minAdaDistance))) {
            minAdaDistance = distance;
            minAdaEntrance = entrance;
          }
        }
      }
      return (requireAda && (minAdaEntrance != null)) ? minAdaEntrance : minEntrance;
    }
    return null;    
  }
}

// StudentCourseTerm

class StudentCourseTerm {
  final String? id;
  final String? name;
  final bool? isCurrent;
  
  StudentCourseTerm({this.id, this.name, this.isCurrent});

  static StudentCourseTerm? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? StudentCourseTerm(
      id: JsonUtils.stringValue(json['termid']),
      name: JsonUtils.stringValue(json['term']),
      isCurrent: JsonUtils.boolValue(json['is_current']),
    ) : null;
  }

  toJson() => {
    'termid': id,
    'term': name,
    'is_current': isCurrent,
  };

  @override
  bool operator==(dynamic other) =>
    (other is StudentCourseTerm) &&
    (id == other.id) &&
    (name == other.name) &&
    (isCurrent == other.isCurrent);

  @override
  int get hashCode =>
    (id?.hashCode ?? 0) ^
    (name?.hashCode ?? 0) ^
    (isCurrent?.hashCode ?? 0);

  static List<StudentCourseTerm>? listFromJson(List<dynamic>? jsonList) {
    List<StudentCourseTerm>? values;
    if (jsonList != null) {
      values = <StudentCourseTerm>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(values, StudentCourseTerm.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return values;
  }

  static List<dynamic>? listToJson(List<StudentCourseTerm>? values) {
    List<dynamic>? jsonList;
    if (values != null) {
      jsonList = <dynamic>[];
      for (StudentCourseTerm value in values) {
        ListUtils.add(jsonList, value.toJson());
      }
    }
    return jsonList;
  }

  static StudentCourseTerm? findInList(List<StudentCourseTerm>? values, {bool? isCurrent, String? id}) {
    if (values != null) {
      for (StudentCourseTerm value in values) {
        if ((isCurrent != null) && (value.isCurrent == isCurrent)) {
          return value;
        }
        if ((id != null) && (value.id == id)) {
          return value;
        }
      }
    }
    return null;
  }
}