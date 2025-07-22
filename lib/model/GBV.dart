import 'package:rokwire_plugin/utils/utils.dart';

enum GBVResourceType {panel, external_link}

enum GBVResourceDetailType {text, address, phone, email, external_link}

class GBVResourceList {
  final String title;
  final List<String> resourceIds;

  GBVResourceList({
    required this.title,
    required this.resourceIds
  });

  static GBVResourceList? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? GBVResourceList(
      title: JsonUtils.stringValue(json['title']) ?? "",
      resourceIds: JsonUtils.listValue(json['resourceIds']) ?? []
    ) : null;
  }

  static List<GBVResourceList> listFromJson(List<dynamic>? jsonList) {
    List<GBVResourceList>? values = [];
    if (jsonList != null) {
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(values, GBVResourceList.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return values;
  }
}

class GBVDetailListSection {
  final String? title;
  final List<GBVResourceDetail>? content;

  GBVDetailListSection({
    this.title,
    this.content
  });

  static List<GBVDetailListSection> listFromJson(List<dynamic>? jsonList) {
    List<GBVDetailListSection>? values = [];
    if (jsonList != null) {
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(values, GBVDetailListSection.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return values;
  }

  static GBVDetailListSection? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? GBVDetailListSection(
      title: JsonUtils.stringValue(json['title']) ?? "",
      content: GBVResourceDetail.listFromJson(JsonUtils.listValue(json['content'])),
    ) : null;
  }
}

class GBVResource {
  final String id;
  final GBVResourceType type;
  final String title;
  final List<GBVResourceDetail> directoryContent;
  final String? description;
  final List<GBVDetailListSection>? detailsList;

  GBVResource({
    required this.id,
    required this.type,
    required this.title,
    required this.directoryContent,
    this.description,
    this.detailsList
  });

  static GBVResource? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? GBVResource(
      id: JsonUtils.stringValue(json['id']) ?? "",
      type: (JsonUtils.stringValue(json['title']) == 'external_link' ? GBVResourceType.external_link : GBVResourceType.panel),
      title: JsonUtils.stringValue(json['title']) ?? "",
      directoryContent: GBVResourceDetail.listFromJson(JsonUtils.listValue(json['directoryContent'])),
      description: JsonUtils.stringValue(json['description']),
      detailsList: GBVDetailListSection.listFromJson(JsonUtils.listValue(json['detailsList'])),
    ) : null;
  }
}

class GBVResourceDetail {
  final GBVResourceDetailType type;
  final String? content;

  GBVResourceDetail({
    required this.type,
    this.content
  });

  static List<GBVResourceDetail> listFromJson(List<dynamic>? jsonList) {
    List<GBVResourceDetail>? values = [];
    if (jsonList != null) {
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(values, GBVResourceDetail.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return values;
  }

  static GBVResourceDetailType _typeFromString(String type) {
    switch (type) {
      case "text": return GBVResourceDetailType.text;
      case "address": return GBVResourceDetailType.address;
      case "phone": return GBVResourceDetailType.phone;
      case "external_link": return GBVResourceDetailType.external_link;
      case "email": return GBVResourceDetailType.email;
      default: return GBVResourceDetailType.text;
    }
  }

  static GBVResourceDetail? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? GBVResourceDetail(
      type: _typeFromString(JsonUtils.stringValue(json['title']) ?? "text"),
      content: JsonUtils.stringValue(json['content'])
    ) : null;
  }
}

class GBVResourceListScreen {
  final String id;
  final String type;
  final String? title;
  final String? description;
  final List<GBVResourceList>? content;

  GBVResourceListScreen({
    required this.id,
    required this.type,
    this.title,
    this.description,
    this.content
  });

  static GBVResourceListScreen? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? GBVResourceListScreen(
      id: JsonUtils.stringValue(json['id']) ?? "",
      type: JsonUtils.stringValue(json['type']) ?? "",
      title: JsonUtils.stringValue(json['title']),
      description: JsonUtils.stringValue(json['description']),
      content: GBVResourceList.listFromJson(JsonUtils.listValue(json['content'])),
    ) : null;
  }
}
