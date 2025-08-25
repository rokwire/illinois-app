import 'package:rokwire_plugin/utils/utils.dart';

enum GBVResourceType {panel, external_link}

enum GBVResourceDetailType {text, address, phone, email, external_link}

class GBV {
  final List<String> directoryCategories;
  final List<GBVResource> resources;
  final GBVResourceListScreens? resourceListScreens;

  GBV({
    required this.directoryCategories,
    required this.resources,
    required this.resourceListScreens
  });

  static GBV? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? GBV(
      directoryCategories: JsonUtils.listValue(json["directoryCategories"]) ?? [],
      resources: GBVResource.listFromJson(JsonUtils.listValue(json['resources'])),
      resourceListScreens: GBVResourceListScreens.fromJson(JsonUtils.mapValue(json['screens'])),
    ) : null;
  }
}
class GBVResourceListScreens {
  final GBVResourceListScreen? confidentialResources;

  GBVResourceListScreens({
    required this.confidentialResources
  });

  static GBVResourceListScreens? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? GBVResourceListScreens(
      confidentialResources: GBVResourceListScreen.fromJson(JsonUtils.mapValue(json['confidential_resources'])),
    ) : null;
  }
}

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
  final String title;
  final List<GBVResourceDetail> content;

  GBVDetailListSection({
    required this.title,
    required this.content
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
  final String category;
  final String title;
  final List<GBVResourceDetail> directoryContent;
  final String? description;
  final List<GBVDetailListSection>? detailsList;

  GBVResource({
    required this.id,
    required this.type,
    required this.category,
    required this.title,
    required this.directoryContent,
    this.description,
    this.detailsList
  });

  static GBVResource? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? GBVResource(
      id: JsonUtils.stringValue(json['id']) ?? "",
      type: (JsonUtils.stringValue(json['type']) == 'external_link' ? GBVResourceType.external_link : GBVResourceType.panel),
      category: JsonUtils.stringValue(json['category']) ?? "",
      title: JsonUtils.stringValue(json['title']) ?? "",
      directoryContent: GBVResourceDetail.listFromJson(JsonUtils.listValue(json['directoryContent'])),
      description: JsonUtils.stringValue(json['description']),
      detailsList: GBVDetailListSection.listFromJson(JsonUtils.listValue(json['detailsList'])),
    ) : null;
  }

  static List<GBVResource> listFromJson(List<dynamic>? jsonList) {
    List<GBVResource>? values = [];
    if (jsonList != null) {
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(values, GBVResource.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return values;
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
      type: _typeFromString(JsonUtils.stringValue(json['type']) ?? "text"),
      content: JsonUtils.stringValue(json['content'])
    ) : null;
  }
}

class GBVResourceListScreen {
  final String type;
  final String? title;
  final String? description;
  final List<GBVResourceList> content;

  GBVResourceListScreen({
    required this.type,
    this.title,
    this.description,
    required this.content
  });

  static GBVResourceListScreen? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? GBVResourceListScreen(
      type: JsonUtils.stringValue(json['type']) ?? "",
      title: JsonUtils.stringValue(json['title']),
      description: JsonUtils.stringValue(json['description']),
      content: GBVResourceList.listFromJson(JsonUtils.listValue(json['content'])),
    ) : null;
  }

  Set<String> get resourceIds {
    Set<String> resourceIds = <String>{};
    for (GBVResourceList resourceList in content) {
      resourceIds.addAll(resourceList.resourceIds);
    }
    return resourceIds;
  }
}
