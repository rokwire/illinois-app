import 'package:collection/collection.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/utils/utils.dart';

enum GBVResourceType {panel, external_link, internal_link, directory, resource_list}

enum GBVResourceDetailType {text, address, phone, email, external_link, internal_link, button}

class GBVData {
  final List<String> directoryCategories;
  final List<GBVResource> resources;
  final GBVResourceListScreens? resourceListScreens;

  GBVData({
    required this.directoryCategories,
    required this.resources,
    required this.resourceListScreens
  });

  factory GBVData.empty() =>
    GBVData(directoryCategories:[], resources:[], resourceListScreens: null);

  static GBVData? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? GBVData(
      directoryCategories: JsonUtils.listCastValue<String>(json["directoryCategories"]) ?? [],
      resources: GBVResource.listFromJson(JsonUtils.listValue(json['resources'])),
      resourceListScreens: GBVResourceListScreens.fromJson(JsonUtils.mapValue(json['screens'])),
    ) : null;
  }

  bool operator == (o) => (o is GBVData) && o.resourceListScreens == resourceListScreens && DeepCollectionEquality().equals(o.directoryCategories, directoryCategories) && DeepCollectionEquality().equals(o.resourceListScreens, resourceListScreens);
  int get hashCode => resourceListScreens.hashCode ^ DeepCollectionEquality().hash(directoryCategories) ^ DeepCollectionEquality().hash(resourceListScreens);
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

  bool operator == (o) => (o is GBVResourceListScreens) && o.confidentialResources == confidentialResources && o.supportingAFriend == supportingAFriend;
  int get hashCode => confidentialResources.hashCode ^ supportingAFriend.hashCode;
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
      resourceIds: JsonUtils.listCastValue<String>(json['resourceIds']) ?? []
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

  bool operator == (o) => (o is GBVResourceList) && o.title == title && DeepCollectionEquality().equals(o.resourceIds, resourceIds);
  int get hashCode => title.hashCode ^ DeepCollectionEquality().hash(resourceIds);
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

  bool operator == (o) => (o is GBVDetailListSection) && o.title == title && o.label == label && DeepCollectionEquality().equals(o.content, content);
  int get hashCode => title.hashCode ^ label.hashCode ^ DeepCollectionEquality().hash(content);
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
      categories: JsonUtils.listCastValue<String>(json['categories']) ?? [],
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

  bool operator == (o) => (o is GBVResource) &&
    (o.id == id) &&
    (o.type == type) &&
    (o.title == title) &&
    (o.description == description) &&
    (o.resourceScreenId == resourceScreenId) &&
    (DeepCollectionEquality().equals(o.categories, categories)) &&
    (DeepCollectionEquality().equals(o.directoryContent, directoryContent)) &&
    (DeepCollectionEquality().equals(o.detailsList, detailsList));

  int get hashCode =>
    id.hashCode ^
    type.hashCode ^
    title.hashCode ^
    description.hashCode ^
    resourceScreenId.hashCode ^
    DeepCollectionEquality().hash(categories) ^
    DeepCollectionEquality().hash(directoryContent) ^
    DeepCollectionEquality().hash(detailsList);
}

class GBVResourceDetail {
  final GBVResourceDetailType type;
  final String? title;
  final String? content;
  final String? contentPrefix;

  GBVResourceDetail({
    required this.type,
    this.title,
    this.content,
    this.contentPrefix,
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

  static GBVResourceDetail? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? GBVResourceDetail(
      type: GBVResourceDetailTypeImpl.fromJson(JsonUtils.stringValue(json['type'])) ?? GBVResourceDetailType.text,
      title: JsonUtils.stringValue(json['title']),
      content: JsonUtils.stringValue(json['content']),
      contentPrefix: JsonUtils.stringValue(json['contentPrefix'])
    ) : null;
  }

  bool operator == (o) => (o is GBVResourceDetail) && o.type == type && o.title == title && o.content == content && o.contentPrefix == contentPrefix;
  int get hashCode => type.hashCode ^ title.hashCode ^ content.hashCode ^ contentPrefix.hashCode;
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

  bool operator == (o) => (o is GBVResourceListScreen) && o.type == type && o.title == title && o.description == description && DeepCollectionEquality().equals(content, content);
  int get hashCode => type.hashCode ^ title.hashCode ^ description.hashCode ^ DeepCollectionEquality().hash(content);
}

extension GBVResourceTypeImpl on GBVResourceType {
  static GBVResourceType? fromJson(String? json) {
    switch (json) {
      case 'external_link': return GBVResourceType.external_link;
      case 'internal_link': return GBVResourceType.internal_link;
      case 'panel': return GBVResourceType.panel;
      case 'resource_list': return GBVResourceType.resource_list;
      case 'directory': return GBVResourceType.directory;
      default: return null;
    }
  }

  bool get isExternalLink => (this == GBVResourceType.external_link);
  bool get isInternalLink => (this == GBVResourceType.internal_link);
  bool get isLink => isInternalLink || isExternalLink;
  bool get isNotLink => (isLink != true);
}

extension GBVResourceDetailTypeImpl on GBVResourceDetailType {
  static GBVResourceDetailType? fromJson(String? json) {
    switch (json) {
      case "text": return GBVResourceDetailType.text;
      case "address": return GBVResourceDetailType.address;
      case "phone": return GBVResourceDetailType.phone;
      case "external_link": return GBVResourceDetailType.external_link;
      case "internal_link": return GBVResourceDetailType.internal_link;
      case "email": return GBVResourceDetailType.email;
      case "button": return GBVResourceDetailType.button;
      default: return null;
    }
  }

  bool get isExternalLink => (this == GBVResourceDetailType.external_link);
  bool get isInternalLink => (this == GBVResourceDetailType.internal_link);
  bool get isLink => isInternalLink || isExternalLink;
  bool get isNotLink => (isLink != true);
}

class GBVResourceFavorite extends Favorite {
  final String key;
  final String? category;
  final String? id;

  GBVResourceFavorite({ required this.key, this.category, this.id });

  factory GBVResourceFavorite.fromString(String value, { required String key}) {
    List<String> items = value.split(_favoriteSeparator);
    if (items.length > 1) {
      return GBVResourceFavorite(key: key, category: items.first, id: items.second);
    } else if (items.length == 1) {
      return GBVResourceFavorite(key: key, id: items.first);
    } else {
      return GBVResourceFavorite(key: key);
    }
  }

  bool get isContentAsset {
    List<String>? pathItems = category?.split(_directorySeparator);
    if ((pathItems != null) && (pathItems.length > 1)) { // has directory & base name
      List<String> basenameItems = pathItems.last.split(_extensionSeparator);
      return (basenameItems.length > 1); // has file name & extension
    } else {
      return false;
    }
  }

  bool get isContentCategory => (category != null) && (category?.isNotEmpty == true) && (isContentAsset == false);

  bool operator == (o) => o is GBVResourceFavorite && o.id == id && o.category == category && o.key == key;
  int get hashCode => (id?.hashCode ?? 0) ^ (category?.hashCode ?? 0) ^ (key.hashCode);

  @override String get favoriteKey => key;
  @override String? get favoriteId => ((category != null) && (id != null)) ? '$category$_favoriteSeparator$id' : id;

  static const String _favoriteSeparator = ':';
  static const String _directorySeparator = '/';
  static const String _extensionSeparator = '/';
}
