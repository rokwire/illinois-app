
import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:rokwire_plugin/service/localization.dart';
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

  // Accessories

  bool get isEmpty => filters?.isEmpty ?? true;
  bool get isNotEmpty => !isEmpty;

  String? stringValue(String? key, { String? languageCode }) {
    if ((strings != null) && (key != null)) {
      Map<String, dynamic>? mapping =
        JsonUtils.mapValue(strings![languageCode]) ??
        JsonUtils.mapValue(strings![Localization().currentLocale?.languageCode]) ??
        JsonUtils.mapValue(strings![Localization().defaultLocale?.languageCode]);
      String? value = (mapping != null) ? JsonUtils.stringValue(mapping[key]) : null;
      if (value != null) {
        return value;
      }
    }
    return key;
  }

  ContentFilter? findFilter({String? id}) {
    if (filters != null) {
      for (ContentFilter filter in filters!) {
        if (((id != null) && (filter.id == id))) {
          return filter;
        }
      }
    }
    return null;
  }

  Map<String, LinkedHashSet<String>> selectionFromLabelSelection(Map<String, dynamic>? labelSelection) {
    Map<String, LinkedHashSet<String>> selection = <String, LinkedHashSet<String>>{};
    if (labelSelection != null) {
      int selectionLength;
      do {
        selectionLength = selection.length;
        labelSelection.forEach((String filterId, dynamic value) {
          if (selection[filterId] == null) {
            ContentFilter? filter = findFilter(id: filterId);
            LinkedHashSet<String>? filterSelection = filter?.selectionFromLabelSelection(value, selection: selection);
            if (filterSelection != null) {
              selection[filterId] = filterSelection;
            }
          }
        });
      }
      while ((selectionLength < selection.length) && (selection.length < labelSelection.length));
    }
    return selection;
  }
}

/////////////////////////////
// ContentFilter

class ContentFilter {
  final String? id;
  final String? title;
  final String? description;
  final String? emptyLabel;
  final String? hint;
  final int? minSelectCount;
  final int? maxSelectCount;
  final List<ContentFilterEntry>? entries;

  ContentFilter({this.id, this.title, this.description, this.emptyLabel, this.hint, this.minSelectCount, this.maxSelectCount, this.entries});

  // JSON serialization

  static ContentFilter? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? ContentFilter(
      id: JsonUtils.stringValue(json['id']),
      title: JsonUtils.stringValue(json['title']),
      description: JsonUtils.stringValue(json['description']),
      emptyLabel: JsonUtils.stringValue(json['empty-label']),
      hint: JsonUtils.stringValue(json['hint']),
      minSelectCount: JsonUtils.intValue(json['min-select-count']),
      maxSelectCount: JsonUtils.intValue(json['max-select-count']),
      entries: ContentFilterEntry.listFromJson(JsonUtils.listValue(json['values'])),
    ) : null;
  }

  toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'empty-label': emptyLabel,
    'hint': hint,
    'min-select-count' : minSelectCount,
    'max-select-count' : maxSelectCount,
    'values': entries,
  };

  // Equality

  @override
  bool operator==(dynamic other) =>
    (other is ContentFilter) &&
    (id == other.id) &&
    (title == other.title) &&
    (description == other.description) &&
    (emptyLabel == other.emptyLabel) &&
    (hint == other.hint) &&
    (minSelectCount == other.minSelectCount) &&
    (maxSelectCount == other.maxSelectCount) &&
    DeepCollectionEquality().equals(entries, other.entries);

  @override
  int get hashCode =>
    (id?.hashCode ?? 0) ^
    (title?.hashCode ?? 0) ^
    (description?.hashCode ?? 0) ^
    (emptyLabel?.hashCode ?? 0) ^
    (hint?.hashCode ?? 0) ^
    (minSelectCount?.hashCode ?? 0) ^
    (maxSelectCount?.hashCode ?? 0) ^
    (DeepCollectionEquality().hash(entries));

  // Accessories

  ContentFilterEntry? findEntry({String? id, String? label}) {
    if (entries != null) {
      for (ContentFilterEntry entry in entries!) {
        if (((id != null) && (entry.id == id)) ||
            ((label != null) && (entry.label == label))) {
          return entry;
        }
      }
    }
    return null;
  }

  LinkedHashSet<String>? selectionFromLabelSelection(dynamic labelSelection, { Map<String, dynamic>? selection }) {
    if (labelSelection is String) {
      ContentFilterEntry? labelEntry = findEntry(label: labelSelection);
      return ((labelEntry != null) && (labelEntry.id != null) && labelEntry.fulfillsSelection(selection)) ? LinkedHashSet<String>.from(<String>[labelEntry.id!]) : null;
    }
    else if (labelSelection is List) {
      List<String>? listSelection;
      for (dynamic entry in labelSelection) {
        LinkedHashSet<String>? entrySelection = selectionFromLabelSelection(entry, selection: selection);
        if (entrySelection != null) {
          (listSelection ??= <String>[]).addAll(entrySelection.toList().reversed);
        }
      }
      return (listSelection != null) ? LinkedHashSet<String>.from(listSelection.reversed) : null;
    }
    else {
      return null;
    }
  }

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

  // Accessories

  bool fulfillsSelection(Map<String, dynamic>? selection) {
    if ((requirements == null) || requirements!.isEmpty) {
      return true;
    }
    else if (selection == null) {
      return false;
    }
    else {
      for (String key in requirements!.keys) {
        if (!_matchRequirement(requirement: requirements![key], selection: selection[key])) {
          return false;
        }
      }
      return true;
    }
  }

  static bool _matchRequirement({dynamic requirement, dynamic selection}) {
    if (requirement is String) {
      if (selection is String) {
        return requirement == selection;
      }
      else if (selection is List) {
        return selection.contains(requirement);
      }
      else {
        return false;
      }
    }
    else if (requirement is List) {
      for (dynamic requirementEntry in requirement) {
        if (!_matchRequirement(requirement: requirementEntry, selection: selection)) {
          return false;
        }
      }
      return true;
    }
    else {
      return (requirement == null);
    }
  }

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