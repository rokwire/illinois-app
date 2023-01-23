
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

  Map<String, dynamic>? selectionToLabelSelection(Map<String, LinkedHashSet<String>> selection) {
    Map<String, dynamic>? labelSelection;
    for (String filterId in selection.keys) {
      ContentFilter? filter = findFilter(id: filterId);
      LinkedHashSet<String>? entryIds = selection[filterId];
      if ((filter != null) && (entryIds != null) && entryIds.isNotEmpty) {
        dynamic labelFilterSelection = filter.selectionToLabelSelection(entryIds);
        if (labelFilterSelection != null) {
          labelSelection ??= <String, dynamic>{};
          labelSelection[filterId] = labelFilterSelection;
        }
      }
    }
    return labelSelection;
  }

  void validateSelection(Map<String, LinkedHashSet<String>> selection) {
    bool modified;
    do {
      modified = false;
      for (String filterId in selection.keys) {
        ContentFilter? filter = findFilter(id: filterId);
        if (filter == null) {
          selection.remove(filterId);
          modified = true;
          break;
        }
        else if (!filter.validateSelection(selection)) {
          modified = true;
          break;
        }
      }
    }
    while (modified);
  }

  ContentFilter? unsatisfiedFilterFromSelection(Map<String, LinkedHashSet<String>> selection) {
    if (filters != null) {
      for (ContentFilter filter in filters!) {
        if (!filter.isSatisfiedFilterFromSelection(selection)) {
          return filter;
        }
      }
    }
    return null;
  }

  bool get hasRequired {
    if (filters != null) {
      for (ContentFilter filter in filters!) {
        if (filter.isRequired) {
          return true;
        }
      }
    }
    return false;
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

  bool get isRequired => (0 < (minSelectCount ?? 0));
  bool get isMultipleSelection => (maxSelectCount != 1);

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

  LinkedHashSet<String>? selectionFromLabelSelection(dynamic labelSelection, { Map<String, LinkedHashSet<String>>? selection }) {
    if (labelSelection is String) {
      ContentFilterEntry? labelEntry = findEntry(label: labelSelection);
      return ((labelEntry != null) && (labelEntry.id != null) && labelEntry.fulfillsSelection(selection)) ? LinkedHashSet<String>.from(<String>[labelEntry.id!]) : null;
    }
    else if (labelSelection is List) {
      List<String>? listSelection;
      for (dynamic entry in labelSelection) {
        LinkedHashSet<String>? entrySelection = selectionFromLabelSelection(entry, selection: selection);
        if (entrySelection != null) {
          (listSelection ??= <String>[]).addAll(entrySelection.toList());
        }
      }
      return (listSelection != null) ? LinkedHashSet<String>.from(listSelection.reversed) : null;
    }
    else {
      return null;
    }
  }

  dynamic selectionToLabelSelection(LinkedHashSet<String>? selectedEntryIds) {
    dynamic labelSelection;
    if ((selectedEntryIds != null) && selectedEntryIds.isNotEmpty) {
      for (String entryId in selectedEntryIds) {
        String? filterEntryName = findEntry(id: entryId)?.label;
        if ((filterEntryName != null) && filterEntryName.isNotEmpty) {
          if (labelSelection is List<String>) {
            labelSelection.add(filterEntryName);
          }
          else if (labelSelection is String) {
            labelSelection = <String>[labelSelection, filterEntryName];
          }
          else {
            labelSelection = filterEntryName;
          }
        }
      }
    }
    return (labelSelection is List) ? List.from(labelSelection.reversed) : labelSelection;
  }

  bool validateSelection(Map<String, LinkedHashSet<String>> selection) {
    LinkedHashSet<String>? entryIds = selection[id];
    if (entryIds != null) {
      for (String entryId in entryIds) {
        ContentFilterEntry? filterEntry = findEntry(id: entryId);
        if ((filterEntry == null) || !filterEntry.fulfillsSelection(selection)) {
          entryIds.remove(entryId);
          return false;
        }
      }
    }
    return true;
  }

  bool isSatisfiedFilterFromSelection(Map<String, LinkedHashSet<String>> selection) {
    int selectedAnsersCount = selection[id]?.length ?? 0; 
    return ((minSelectCount == null) || (minSelectCount! <= selectedAnsersCount)) &&
           ((maxSelectCount == null) || (selectedAnsersCount <= maxSelectCount!));
  }

  List<ContentFilterEntry>? entriesFromSelection(Map<String, LinkedHashSet<String>> selection) {
    List<ContentFilterEntry>? filteredItems;
    if (entries != null) {
      for (ContentFilterEntry entry in entries!) {
        if (entry.fulfillsSelection(selection)) {
          filteredItems ??= <ContentFilterEntry>[];
          filteredItems.add(entry);
        }
      }
    }
    return filteredItems;
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

  bool fulfillsSelection(Map<String, LinkedHashSet<String>>? selection) {
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

  static bool _matchRequirement({dynamic requirement, LinkedHashSet<String>? selection}) {
    if (requirement is String) {
      return selection?.contains(requirement) ?? false;
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