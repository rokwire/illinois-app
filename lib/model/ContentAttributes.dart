
import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/utils/utils.dart';

/////////////////////////////
// ContentAttributes

class ContentAttributes {
  final List<ContentAttributesCategory>? categories;
  final Map<String, dynamic>? strings;

  ContentAttributes({this.categories, this.strings});

  // JSON serialization

  static ContentAttributes? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? ContentAttributes(
      categories: ContentAttributesCategory.listFromJson(JsonUtils.listValue(json['content'])) ,
      strings: JsonUtils.mapValue(json['strings']),
    ) : null;
  }

  toJson() => {
    'content': categories,
    'strings': strings,
  };

  // Equality

  @override
  bool operator==(dynamic other) =>
    (other is ContentAttributes) &&
    DeepCollectionEquality().equals(categories, other.categories) &&
    DeepCollectionEquality().equals(strings, other.strings);

  @override
  int get hashCode =>
    (DeepCollectionEquality().hash(categories)) ^
    (DeepCollectionEquality().hash(strings));

  // Accessories

  bool get isEmpty => categories?.isEmpty ?? true;
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

  ContentAttributesCategory? findCategory({String? title}) {
    if (categories != null) {
      for (ContentAttributesCategory category in categories!) {
        if (category.title == title) {
          return category;
        }
      }
    }
    return null;
  }

  static Map<String, LinkedHashSet<String>>? selectionFromAttributesSelection(Map<String, dynamic>? attributesSelection) {
    Map<String, LinkedHashSet<String>>? selection;
    attributesSelection?.forEach((String categoryTitle, dynamic value) {
      if (value is String) {
        selection ??= <String, LinkedHashSet<String>>{};
        selection![categoryTitle] = LinkedHashSet<String>.from(<String>[value]);
      }
      else if (value is List) {
        selection ??= <String, LinkedHashSet<String>>{};
        selection![categoryTitle] = LinkedHashSet<String>.from(JsonUtils.listStringsValue(value)?.reversed ?? <String>[]);
      }
    });
    return selection;
  }

  static Map<String, dynamic>? selectionToAttributesSelection(Map<String, LinkedHashSet<String>>? selection) {
    Map<String, dynamic>? categorySelection;
    selection?.forEach((String categoryTitle, LinkedHashSet<String> values) {
      if (values.length == 1) {
        categorySelection ??= <String, dynamic>{};
        categorySelection![categoryTitle] = values.first;
      }
      else if (values.length > 1) {
        categorySelection ??= <String, dynamic>{};
        categorySelection![categoryTitle] = List.from(List.from(values).reversed);
      }
    });
    return categorySelection;
  }

  void validateSelection(Map<String, LinkedHashSet<String>> selection) {
    bool modified;
    do {
      modified = false;
      for (String categoryTitle in selection.keys) {
        ContentAttributesCategory? category = findCategory(title: categoryTitle);
        if (category == null) {
          selection.remove(categoryTitle);
          modified = true;
          break;
        }
        else if (!category.validateSelection(selection)) {
          modified = true;
          break;
        }
      }
    }
    while (modified);
  }

  String selectionDescription(Map<String, dynamic>? selection, {
    String categorySeparator = '; ',
    String attributeSeparator = ', ',
    String titleDelimiter = ': '
  }) {
    String descr = '';
    if ((categories != null) && (selection != null)) {
      for (ContentAttributesCategory category in categories!) {
        String? categoryTitle = stringValue(category.title);
        dynamic categorySelection = selection[category.title];
        List<ContentAttribute>? categoryAttributes = category.attributes;
        if ((categoryTitle != null) && categoryTitle.isNotEmpty &&
            ((categorySelection is String) || ((categorySelection is List) && categorySelection.isNotEmpty)) &&
            (categoryAttributes != null) && categoryAttributes.isNotEmpty) {

          String attributesSelection = '';
          for (ContentAttribute attribute in categoryAttributes) {
            if (((categorySelection is String) && (categorySelection == attribute.label)) ||
                ((categorySelection is List) && categorySelection.contains(attribute.label)))
            {
              String? valueTitle = stringValue(attribute.label);
              if ((valueTitle != null) && valueTitle.isNotEmpty) {
                if (attributesSelection.isNotEmpty) {
                  attributesSelection += attributeSeparator;
                }
                attributesSelection += valueTitle;
              }
            }
          }

          if (attributesSelection.isNotEmpty) {
            if (descr.isNotEmpty) {
              descr += categorySeparator;
            }
            descr += "$categoryTitle$titleDelimiter$attributesSelection";
          }
        }
      }
    }
    return descr;
  }

  ContentAttributesCategory? unsatisfiedCategoryFromSelection(Map<String, dynamic>? selection) {
    if (categories != null) {
      for (ContentAttributesCategory category in categories!) {
        dynamic categorySelection = (selection != null) ? selection[category.title] : null;
        if (!category.isSatisfiedFromSelection(categorySelection)) {
          return category;
        }
      }
    }
    return null;
  }

  bool get hasRequired {
    if (categories != null) {
      for (ContentAttributesCategory category in categories!) {
        if (category.isRequired) {
          return true;
        }
      }
    }
    return false;
  }
}

/////////////////////////////
// ContentAttributesCategory

class ContentAttributesCategory {
  final String? title;
  final String? description;
  final String? emptyLabel;
  final String? hint;
  final int? minSelectCount;
  final int? maxSelectCount;
  final List<ContentAttribute>? attributes;

  ContentAttributesCategory({this.title, this.description, this.emptyLabel, this.hint, this.minSelectCount, this.maxSelectCount, this.attributes});

  // JSON serialization

  static ContentAttributesCategory? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? ContentAttributesCategory(
      title: JsonUtils.stringValue(json['title']),
      description: JsonUtils.stringValue(json['description']),
      emptyLabel: JsonUtils.stringValue(json['empty-label']),
      hint: JsonUtils.stringValue(json['hint']),
      minSelectCount: JsonUtils.intValue(json['min-select-count']),
      maxSelectCount: JsonUtils.intValue(json['max-select-count']),
      attributes: ContentAttribute.listFromJson(JsonUtils.listValue(json['values'])),
    ) : null;
  }

  toJson() => {
    'title': title,
    'description': description,
    'empty-label': emptyLabel,
    'hint': hint,
    'min-select-count' : minSelectCount,
    'max-select-count' : maxSelectCount,
    'values': attributes,
  };

  // Equality

  @override
  bool operator==(dynamic other) =>
    (other is ContentAttributesCategory) &&
    (title == other.title) &&
    (description == other.description) &&
    (emptyLabel == other.emptyLabel) &&
    (hint == other.hint) &&
    (minSelectCount == other.minSelectCount) &&
    (maxSelectCount == other.maxSelectCount) &&
    DeepCollectionEquality().equals(attributes, other.attributes);

  @override
  int get hashCode =>
    (title?.hashCode ?? 0) ^
    (description?.hashCode ?? 0) ^
    (emptyLabel?.hashCode ?? 0) ^
    (hint?.hashCode ?? 0) ^
    (minSelectCount?.hashCode ?? 0) ^
    (maxSelectCount?.hashCode ?? 0) ^
    (DeepCollectionEquality().hash(attributes));

  // Accessories

  bool get isRequired => (0 < (minSelectCount ?? 0));
  bool get isMultipleSelection => (maxSelectCount != 1);

  ContentAttribute? findAttribute({String? label}) {
    if (attributes != null) {
      for (ContentAttribute attribute in attributes!) {
        if ((label != null) && (attribute.label == label)) {
          return attribute;
        }
      }
    }
    return null;
  }

  bool validateSelection(Map<String, LinkedHashSet<String>> selection) {
    LinkedHashSet<String>? attributeLabels = selection[title];
    if (attributeLabels != null) {
      for (String attributeLabel in attributeLabels) {
        ContentAttribute? attribute = findAttribute(label: attributeLabel);
        if ((attribute == null) || !attribute.fulfillsSelection(selection)) {
          attributeLabels.remove(attributeLabel);
          return false;
        }
      }
    }
    return true;
  }

  bool isSatisfiedFromSelection(dynamic selection) {
    int selectedAttributesCount; 
    if (selection is String) {
      selectedAttributesCount = 1;
    }
    else if (selection is Iterable) {
      selectedAttributesCount = selection.length;
    }
    else {
      selectedAttributesCount = 0;
    }
    return ((minSelectCount == null) || (minSelectCount! <= selectedAttributesCount)) &&
           ((maxSelectCount == null) || (selectedAttributesCount <= maxSelectCount!));
  }

  List<ContentAttribute>? attributesFromSelection(Map<String, LinkedHashSet<String>> selection) {
    List<ContentAttribute>? filteredAttributes;
    if (attributes != null) {
      for (ContentAttribute attribute in attributes!) {
        if (attribute.fulfillsSelection(selection)) {
          filteredAttributes ??= <ContentAttribute>[];
          filteredAttributes.add(attribute);
        }
      }
    }
    return filteredAttributes;
  }

  // List<ContentAttributesCategory> JSON Serialization

  static List<ContentAttributesCategory>? listFromJson(List<dynamic>? jsonList) {
    List<ContentAttributesCategory>? values;
    if (jsonList != null) {
      values = <ContentAttributesCategory>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(values, ContentAttributesCategory.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return values;
  }

  static List<dynamic>? listToJson(List<ContentAttributesCategory>? values) {
    List<dynamic>? jsonList;
    if (values != null) {
      jsonList = <dynamic>[];
      for (ContentAttributesCategory value in values) {
        ListUtils.add(jsonList, value.toJson());
      }
    }
    return jsonList;
  }
}

/////////////////////////////
// ContentAttribute

class ContentAttribute {
  final String? label;
  final Map<String, dynamic>? requirements;

  ContentAttribute({this.label, this.requirements});

  // JSON serialization

  static ContentAttribute? fromJson(dynamic json) {
    if (json is String) {
      return ContentAttribute(
        label: json,
      );
    }
    else if (json is Map) {
      return ContentAttribute(
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
    (other is ContentAttribute) &&
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

  // List<ContentAttribute> JSON Serialization

  static List<ContentAttribute>? listFromJson(List<dynamic>? jsonList) {
    List<ContentAttribute>? values;
    if (jsonList != null) {
      values = <ContentAttribute>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(values, ContentAttribute.fromJson(jsonEntry));
      }
    }
    return values;
  }

  static List<dynamic>? listToJson(List<ContentAttribute>? values) {
    List<dynamic>? jsonList;
    if (values != null) {
      jsonList = <dynamic>[];
      for (ContentAttribute value in values) {
        ListUtils.add(jsonList, value.toJson());
      }
    }
    return jsonList;
  }
}