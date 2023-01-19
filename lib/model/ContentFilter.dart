
import 'package:collection/collection.dart';
import 'package:rokwire_plugin/utils/utils.dart';

/////////////////////////////
// ContentFilterSet

class ContentFilterSet {
  final List<ContentFilter>? filters;
  final Map<String, dynamic>? strings;

  ContentFilterSet({this.filters, this.strings});

  // JSON serialization

  static ContentFilterSet? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? ContentFilterSet(
      filters: ContentFilter.listFromJson(JsonUtils.listValue(json['content'])) ,
      strings: JsonUtils.mapValue(json['strings']),
    ) : null;
  }

  toJson() => {
    'filters': filters,
    'strings': strings,
  };

  // Equality

  @override
  bool operator==(dynamic other) =>
    (other is ContentFilterSet) &&
    DeepCollectionEquality().equals(filters, other.filters) &&
    DeepCollectionEquality().equals(strings, other.strings);

  @override
  int get hashCode =>
    (DeepCollectionEquality().hash(filters)) ^
    (DeepCollectionEquality().hash(strings));
}

/////////////////////////////
// ContentFilter

class ContentFilter {
  final String? id;
  final String? label;
  final int? minSelectCount;
  final int? maxSelectCount;
  final List<ContentFilterEntry>? entries;

  ContentFilter({this.id, this.label, this.minSelectCount, this.maxSelectCount, this.entries});

  // JSON serialization

  static ContentFilter? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? ContentFilter(
      id: JsonUtils.stringValue(json['id']),
      label: JsonUtils.stringValue(json['label']),
      minSelectCount: JsonUtils.intValue(json['min-select-count']),
      maxSelectCount: JsonUtils.intValue(json['max-select-count']),
      entries: ContentFilterEntry.listFromJson(JsonUtils.listValue(json['values'])),
    ) : null;
  }

  toJson() => {
    'id': id,
    'label': label,
    'min-select-count' : minSelectCount,
    'max-select-count' : maxSelectCount,
    'values': entries,
  };

  // Equality

  @override
  bool operator==(dynamic other) =>
    (other is ContentFilter) &&
    (id == other.id) &&
    (label == other.label) &&
    (minSelectCount == other.minSelectCount) &&
    (maxSelectCount == other.maxSelectCount) &&
    DeepCollectionEquality().equals(entries, other.entries);

  @override
  int get hashCode =>
    (id?.hashCode ?? 0) ^
    (label?.hashCode ?? 0) ^
    (minSelectCount?.hashCode ?? 0) ^
    (maxSelectCount?.hashCode ?? 0) ^
    (DeepCollectionEquality().hash(entries));

  // List<ContentFilter> JSON Serialization

  static List<ContentFilter>? listFromJson(List<dynamic>? jsonList) {
    List<ContentFilter>? values;
    if (jsonList != null) {
      values = <ContentFilter>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(values, ContentFilter.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return values;
  }

  static List<dynamic>? listToJson(List<ContentFilter>? values) {
    List<dynamic>? jsonList;
    if (values != null) {
      jsonList = <dynamic>[];
      for (ContentFilter value in values) {
        ListUtils.add(jsonList, value.toJson());
      }
    }
    return jsonList;
  }
}

/////////////////////////////
// ContentFilterEntry

class ContentFilterEntry {
  final String? id;
  final String? label;
  final Map<String, dynamic>? requirements;

  ContentFilterEntry({this.id, this.label, this.requirements});

  // JSON serialization

  static ContentFilterEntry? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? ContentFilterEntry(
      id: JsonUtils.stringValue(json['id']),
      label: JsonUtils.stringValue(json['label']),
      requirements: JsonUtils.mapValue(json['requirements']),
    ) : null;
  }

  toJson() => {
    'id': id,
    'label': label,
    'requirements': requirements,
  };

  // Equality

  @override
  bool operator==(dynamic other) =>
    (other is ContentFilterEntry) &&
    (id == other.id) &&
    (label == other.label) &&
    DeepCollectionEquality().equals(requirements, other.requirements);

  @override
  int get hashCode =>
    (id?.hashCode ?? 0) ^
    (label?.hashCode ?? 0) ^
    (DeepCollectionEquality().hash(requirements));

  // List<ContentFilterEntry> JSON Serialization

  static List<ContentFilterEntry>? listFromJson(List<dynamic>? jsonList) {
    List<ContentFilterEntry>? values;
    if (jsonList != null) {
      values = <ContentFilterEntry>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(values, ContentFilterEntry.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return values;
  }

  static List<dynamic>? listToJson(List<ContentFilterEntry>? values) {
    List<dynamic>? jsonList;
    if (values != null) {
      jsonList = <dynamic>[];
      for (ContentFilterEntry value in values) {
        ListUtils.add(jsonList, value.toJson());
      }
    }
    return jsonList;
  }
}