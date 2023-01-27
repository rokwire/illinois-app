
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

  ContentFilter? findFilter({String? title}) {
    if (filters != null) {
      for (ContentFilter filter in filters!) {
        if (((title != null) && (filter.title == title))) {
          return filter;
        }
      }
    }
    return null;
  }

  static Map<String, LinkedHashSet<String>>? selectionFromFilterSelection(Map<String, dynamic>? filterSelection) {
    Map<String, LinkedHashSet<String>>? selection;
    filterSelection?.forEach((String filterTitle, dynamic value) {
      if (value is String) {
        selection ??= <String, LinkedHashSet<String>>{};
        selection![filterTitle] = LinkedHashSet<String>.from(<String>[value]);
      }
      else if (value is List) {
        selection ??= <String, LinkedHashSet<String>>{};
        selection![filterTitle] = LinkedHashSet<String>.from(JsonUtils.listStringsValue(value)?.reversed ?? <String>[]);
      }
    });
    return selection;
  }

  static Map<String, dynamic>? selectionToFilterSelection(Map<String, LinkedHashSet<String>>? selection) {
    Map<String, dynamic>? filterSelection;
    selection?.forEach((String filterTitle, LinkedHashSet<String> values) {
      if (values.length == 1) {
        filterSelection ??= <String, dynamic>{};
        filterSelection![filterTitle] = values.first;
      }
      else if (values.length > 1) {
        filterSelection ??= <String, dynamic>{};
        filterSelection![filterTitle] = List.from(List.from(values).reversed);
      }
    });
    return filterSelection;
  }

  void validateSelection(Map<String, LinkedHashSet<String>> selection) {
    bool modified;
    do {
      modified = false;
      for (String filterTitle in selection.keys) {
        ContentFilter? filter = findFilter(title: filterTitle);
        if (filter == null) {
          selection.remove(filterTitle);
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

  String selectionDescription(Map<String, dynamic>? selection, { String filtersSeparator = ', ', String entriesSeparator = '/', String titleDelimiter = ': '}) {
    String filtersDescr = '';
    if ((filters != null) && (selection != null)) {
      for (ContentFilter filter in filters!) {
        String? filterTitle = stringValue(filter.title);
        dynamic filterSelection = selection[filter.title];
        List<ContentFilterEntry>? filterEntries = filter.entries;
        if ((filterTitle != null) && filterTitle.isNotEmpty &&
            ((filterSelection is String) || ((filterSelection is List) && filterSelection.isNotEmpty)) &&
            (filterEntries != null) && filterEntries.isNotEmpty) {

          String filterOptions = '';
          for (ContentFilterEntry entry in filterEntries) {
            if (((filterSelection is String) && (filterSelection == entry.label)) ||
                ((filterSelection is List) && filterSelection.contains(entry.label)))
            {
              String? entryTitle = stringValue(entry.label);
              if ((entryTitle != null) && entryTitle.isNotEmpty) {
                if (filterOptions.isNotEmpty) {
                  filterOptions += entriesSeparator;
                }
                filterOptions += entryTitle;
              }
            }
          }

          if (filterOptions.isNotEmpty) {
            if (filtersDescr.isNotEmpty) {
              filtersDescr += filtersSeparator;
            }
            filtersDescr += "$filterTitle$titleDelimiter$filterOptions";
          }
        }
      }
    }
    return filtersDescr;
  }

  ContentFilter? unsatisfiedFilterFromSelection(Map<String, dynamic>? selection) {
    if (filters != null) {
      for (ContentFilter filter in filters!) {
        dynamic filterSelection = (selection != null) ? selection[filter.title] : null;
        if (!filter.isSatisfiedFilterFromSelection(filterSelection)) {
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
  final String? title;
  final String? description;
  final String? emptyLabel;
  final String? hint;
  final int? minSelectCount;
  final int? maxSelectCount;
  final List<ContentFilterEntry>? entries;

  ContentFilter({this.title, this.description, this.emptyLabel, this.hint, this.minSelectCount, this.maxSelectCount, this.entries});

  // JSON serialization

  static ContentFilter? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? ContentFilter(
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
    (title == other.title) &&
    (description == other.description) &&
    (emptyLabel == other.emptyLabel) &&
    (hint == other.hint) &&
    (minSelectCount == other.minSelectCount) &&
    (maxSelectCount == other.maxSelectCount) &&
    DeepCollectionEquality().equals(entries, other.entries);

  @override
  int get hashCode =>
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

  ContentFilterEntry? findEntry({String? label}) {
    if (entries != null) {
      for (ContentFilterEntry entry in entries!) {
        if ((label != null) && (entry.label == label)) {
          return entry;
        }
      }
    }
    return null;
  }

  bool validateSelection(Map<String, LinkedHashSet<String>> selection) {
    LinkedHashSet<String>? entryLabels = selection[title];
    if (entryLabels != null) {
      for (String entryLabel in entryLabels) {
        ContentFilterEntry? filterEntry = findEntry(label: entryLabel);
        if ((filterEntry == null) || !filterEntry.fulfillsSelection(selection)) {
          entryLabels.remove(entryLabel);
          return false;
        }
      }
    }
    return true;
  }

  bool isSatisfiedFilterFromSelection(dynamic selection) {
    int selectedAnsersCount; 
    if (selection is String) {
      selectedAnsersCount = 1;
    }
    else if (selection is Iterable) {
      selectedAnsersCount = selection.length;
    }
    else {
      selectedAnsersCount = 0;
    }
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
  final String? label;
  final Map<String, dynamic>? requirements;

  ContentFilterEntry({this.label, this.requirements});

  // JSON serialization

  static ContentFilterEntry? fromJson(dynamic json) {
    if (json is String) {
      return ContentFilterEntry(
        label: json,
      );
    }
    else if (json is Map) {
      return ContentFilterEntry(
        label: JsonUtils.stringValue(json['label']),
        requirements: JsonUtils.mapValue(json['requirements']),
      );
    }
    else {
      return null;
    }
  }

  toJson() => {
    'label': label,
    'requirements': requirements,
  };

  // Equality

  @override
  bool operator==(dynamic other) =>
    (other is ContentFilterEntry) &&
    (label == other.label) &&
    DeepCollectionEquality().equals(requirements, other.requirements);

  @override
  int get hashCode =>
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
        ListUtils.add(values, ContentFilterEntry.fromJson(jsonEntry));
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