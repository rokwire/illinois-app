import 'package:rokwire_plugin/utils/utils.dart';

enum GBVResourceType {panel, external_link, directory, resource_list}

enum GBVResourceDetailType {text, address, phone, email, external_link, button}

class GBVData {
  final List<String> directoryCategories;
  final List<GBVResource> resources;
  final GBVResourceListScreens? resourceListScreens;

  GBVData({
    required this.directoryCategories,
    required this.resources,
    required this.resourceListScreens
  });

  static GBVData? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? GBVData(
      directoryCategories: JsonUtils.listValue(json["directoryCategories"]) ?? [],
      resources: GBVResource.listFromJson(JsonUtils.listValue(json['resources'])),
      resourceListScreens: GBVResourceListScreens.fromJson(JsonUtils.mapValue(json['screens'])),
    ) : null;
  }
}
class GBVResourceListScreens {
  final GBVResourceListScreen? confidentialResources;
  final GBVResourceListScreen? supportingAFriend;

  GBVResourceListScreens({
    required this.confidentialResources,
    required this.supportingAFriend
  });

  static GBVResourceListScreens? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? GBVResourceListScreens(
      confidentialResources: GBVResourceListScreen.fromJson(JsonUtils.mapValue(json['confidential_resources'])),
      supportingAFriend: GBVResourceListScreen.fromJson(JsonUtils.mapValue(json['supporting_a_friend'])),
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
  final String? label;

  GBVDetailListSection({
    required this.title,
    required this.content,
    this.label
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
      label: JsonUtils.stringValue(json['label']),
    ) : null;
  }
}

class GBVResource {
  final String id;
  final GBVResourceType type;
  final List<String> categories;
  final String title;
  final List<GBVResourceDetail> directoryContent;
  final String? description;
  final List<GBVDetailListSection>? detailsList;
  final String? resourceScreenId;

  GBVResource({
    required this.id,
    required this.type,
    required this.categories,
    required this.title,
    required this.directoryContent,
    this.description,
    this.detailsList,
    this.resourceScreenId
  });

  static GBVResource? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? GBVResource(
      id: JsonUtils.stringValue(json['id']) ?? "",
      type: GBVResourceTypeImpl.fromJson(JsonUtils.stringValue(json['type'])) ?? GBVResourceType.directory,
      categories: JsonUtils.listValue(json['categories']) ?? [],
      title: JsonUtils.stringValue(json['title']) ?? "",
      directoryContent: GBVResourceDetail.listFromJson(JsonUtils.listValue(json['directoryContent'])),
      description: JsonUtils.stringValue(json['description']),
      detailsList: GBVDetailListSection.listFromJson(JsonUtils.listValue(json['detailsList'])),
      resourceScreenId: JsonUtils.stringValue(json['resourceScreenId']),
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
  final String? title;
  final String? content;

  GBVResourceDetail({
    required this.type,
    this.title,
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
      case "button": return GBVResourceDetailType.button;
      default: return GBVResourceDetailType.text;
    }
  }

  static GBVResourceDetail? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? GBVResourceDetail(
      type: _typeFromString(JsonUtils.stringValue(json['type']) ?? "text"),
      title: JsonUtils.stringValue(json['title']),
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

extension GBVResourceTypeImpl on GBVResourceType {
  static GBVResourceType? fromJson(String? json) {
    switch (json) {
      case 'external_link': return GBVResourceType.external_link;
      case 'panel': return GBVResourceType.panel;
      case 'resource_list': return GBVResourceType.resource_list;
      case 'directory': return GBVResourceType.directory;
      default: return null;
    }
  }
}
