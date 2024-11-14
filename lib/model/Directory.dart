
import 'package:rokwire_plugin/utils/utils.dart';

class DirectoryMember {
  final String? id;
  final String? netId;

  final String? firstName;
  final String? middleName;
  final String? lastName;
  final String? pronoun;
  final String? title;

  final String? photoUrl;
  final String? pronunciationUrl;

  final String? college;
  final String? department;
  final String? major;

  final String? email;
  final String? email2;
  final String? phone;
  final String? website;

  DirectoryMember({
    this.id, this.netId,
    this.firstName, this.middleName, this.lastName, this.pronoun, this.title,
    this.photoUrl, this.pronunciationUrl,
    this.college, this.department, this.major,
    this.email, this.email2, this.phone, this.website,
  });

  static DirectoryMember? fromJson(Map<String, dynamic>? json) =>
    (json != null) ? DirectoryMember(
      id: JsonUtils.stringValue(json['id']),
      netId: JsonUtils.stringValue(json['net_id']),

      firstName: JsonUtils.stringValue(json['first_name']),
      middleName: JsonUtils.stringValue(json['middle_name']),
      lastName: JsonUtils.stringValue(json['last_name']),
      pronoun: JsonUtils.stringValue(json['pronoun']),
      title: JsonUtils.stringValue(json['title']),

      photoUrl: JsonUtils.stringValue(json['photo_ur']),
      pronunciationUrl: JsonUtils.stringValue(json['pronunciation_url']),

      college: JsonUtils.stringValue(json['college']),
      department: JsonUtils.stringValue(json['department']),
      major: JsonUtils.stringValue(json['major']),

      email: JsonUtils.stringValue(json['email']),
      email2: JsonUtils.stringValue(json['email2']),
      phone: JsonUtils.stringValue(json['phone']),
      website: JsonUtils.stringValue(json['website']),
    ) : null;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'net_id': netId,

      'first_name': firstName,
      'middle_name': middleName,
      'last_name': lastName,
      'pronoun': pronoun,
      'title': title,

      'photo_ur': photoUrl,
      'pronunciation_url': pronunciationUrl,

      'college': college,
      'department': department,
      'major': major,

      'email': email,
      'email2': email2,
      'phone': phone,
      'website': website,
    };
  }

  // Equality

  @override
  bool operator==(Object other) =>
    (other is DirectoryMember) &&
    (id == other.id) &&
    (netId == other.netId) &&

    (firstName == other.firstName) &&
    (middleName == other.middleName) &&
    (lastName == other.lastName) &&
    (pronoun == other.pronoun) &&
    (title == other.title) &&

    (photoUrl == other.photoUrl) &&
    (pronunciationUrl == other.pronunciationUrl) &&

    (college == other.college) &&
    (department == other.department) &&
    (major == other.major) &&

    (email == other.email) &&
    (email2 == other.email2) &&
    (phone == other.phone) &&
    (website == other.website);

  @override
  int get hashCode =>
    (id?.hashCode ?? 0) ^
    (netId?.hashCode ?? 0) ^

    (firstName?.hashCode ?? 0) ^
    (middleName?.hashCode ?? 0) ^
    (lastName?.hashCode ?? 0) ^
    (pronoun?.hashCode ?? 0) ^
    (title?.hashCode ?? 0) ^

    (photoUrl?.hashCode ?? 0) ^
    (pronunciationUrl?.hashCode ?? 0) ^

    (college?.hashCode ?? 0) ^
    (department?.hashCode ?? 0) ^
    (major?.hashCode ?? 0) ^

    (email?.hashCode ?? 0) ^
    (email2?.hashCode ?? 0) ^
    (phone?.hashCode ?? 0) ^
    (website?.hashCode ?? 0);

  // JSON List Serialization

  static List<DirectoryMember>? listFromJson(List<dynamic>? json) {
    List<DirectoryMember>? values;
    if (json != null) {
      values = <DirectoryMember>[];
      for (dynamic entry in json) {
        ListUtils.add(values, DirectoryMember.fromJson(JsonUtils.mapValue(entry)));
      }
    }
    return values;
  }

  static List<dynamic>? listToJson(List<DirectoryMember>? values) {
    List<dynamic>? json;
    if (values != null) {
      json = [];
      for (DirectoryMember value in values) {
        json.add(value.toJson());
      }
    }
    return json;
  }
}