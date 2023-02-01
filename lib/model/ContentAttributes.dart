
import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/utils/utils.dart';

/////////////////////////////////////
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

  ContentAttributesCategory? findCategory({String? id, String? title}) {
    if ((categories != null) && ((id != null) || (title != null))) {
      for (ContentAttributesCategory category in categories!) {
        if (((id == null) || (category.id == id)) &&
            ((title == null) || (category.title == title))) {
          return category;
        }
      }
    }
    return null;
  }

  static Map<String, LinkedHashSet<String>>? selectionFromAttributesSelection(Map<String, dynamic>? attributesSelection) {
    Map<String, LinkedHashSet<String>>? selection;
    attributesSelection?.forEach((String categoryId, dynamic value) {
      if (value is String) {
        selection ??= <String, LinkedHashSet<String>>{};
        selection![categoryId] = LinkedHashSet<String>.from(<String>[value]);
      }
      else if (value is List) {
        selection ??= <String, LinkedHashSet<String>>{};
        selection![categoryId] = LinkedHashSet<String>.from(JsonUtils.listStringsValue(value)?.reversed ?? <String>[]);
      }
    });
    return selection;
  }

  static Map<String, dynamic>? selectionToAttributesSelection(Map<String, LinkedHashSet<String>>? selection) {
    Map<String, dynamic>? categorySelection;
    selection?.forEach((String categoryId, LinkedHashSet<String> values) {
      if (values.length == 1) {
        categorySelection ??= <String, dynamic>{};
        categorySelection![categoryId] = values.first;
      }
      else if (values.length > 1) {
        categorySelection ??= <String, dynamic>{};
        categorySelection![categoryId] = List.from(List.from(values).reversed);
      }
    });
    return categorySelection;
  }

  void validateSelection(Map<String, LinkedHashSet<String>> selection) {
    bool modified;
    do {
      modified = false;
      for (String categoryId in selection.keys) {
        ContentAttributesCategory? category = findCategory(id: categoryId);
        if (category == null) {
          selection.remove(categoryId);
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
        dynamic categorySelection = selection[category.id];
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
        dynamic categorySelection = (selection != null) ? selection[category.id] : null;
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

/////////////////////////////////////
// ContentAttributesCategory

class ContentAttributesCategory {
  final String? id;
  final String? title;
  final String? description;
  final String? text;
  final String? emptyHint;
  final String? semanticsHint;
  final ContentAttributesCategoryWidget? widget;
  final int? minRequiredCount;
  final int? maxRequiredCount;
  final List<ContentAttribute>? attributes;

  ContentAttributesCategory({this.id, this.title, this.description, this.text,
    this.emptyHint, this.semanticsHint, this.widget,
    this.minRequiredCount, this.maxRequiredCount,
    this.attributes});

  // JSON serialization

  static ContentAttributesCategory? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? ContentAttributesCategory(
      id: JsonUtils.stringValue(json['id']),
      title: JsonUtils.stringValue(json['title']),
      description: JsonUtils.stringValue(json['description']),
      text: JsonUtils.stringValue(json['text']),
      emptyHint: JsonUtils.stringValue(json['empty-hint']),
      semanticsHint: JsonUtils.stringValue(json['semantics-hint']),
      widget: contentAttributesCategoryWidgetFromString(JsonUtils.stringValue(json['widget'])),
      minRequiredCount: JsonUtils.intValue(json['min-required-count']),
      maxRequiredCount: JsonUtils.intValue(json['max-required-count']),
      attributes: ContentAttribute.listFromJson(JsonUtils.listValue(json['values'])),
    ) : null;
  }

  toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'text': text,
    'empty-hint': emptyHint,
    'semantics-hint': semanticsHint,
    'widget': contentAttributesCategoryWidgetToString(widget),
    'min-required-count' : minRequiredCount,
    'max-required-count' : maxRequiredCount,
    'values': attributes,
  };

  // Equality

  @override
  bool operator==(dynamic other) =>
    (other is ContentAttributesCategory) &&
    (id == other.id) &&
    (title == other.title) &&
    (description == other.description) &&
    (text == other.text) &&
    (emptyHint == other.emptyHint) &&
    (semanticsHint == other.semanticsHint) &&
    (widget == other.widget) &&
    (minRequiredCount == other.minRequiredCount) &&
    (maxRequiredCount == other.maxRequiredCount) &&
    DeepCollectionEquality().equals(attributes, other.attributes);

  @override
  int get hashCode =>
    (id?.hashCode ?? 0) ^
    (title?.hashCode ?? 0) ^
    (description?.hashCode ?? 0) ^
    (text?.hashCode ?? 0) ^
    (emptyHint?.hashCode ?? 0) ^
    (semanticsHint?.hashCode ?? 0) ^
    (widget?.hashCode ?? 0) ^
    (minRequiredCount?.hashCode ?? 0) ^
    (maxRequiredCount?.hashCode ?? 0) ^
    (DeepCollectionEquality().hash(attributes));

  // Accessories

  bool get isRequired => (0 < (minRequiredCount ?? 0));
  bool get isMultipleSelection => (maxRequiredCount != 1);
  bool get isSingleSelection => (maxRequiredCount == 1);

  bool get isDropdownWidget => (widget == ContentAttributesCategoryWidget.dropdown);
  bool get isCheckboxWidget => (widget == ContentAttributesCategoryWidget.checkbox);

  ContentAttribute? findAttribute({String? label, dynamic value}) {
    if (attributes != null) {
      for (ContentAttribute attribute in attributes!) {
        if (((label == null) || (attribute.label == label)) &&
            ((value == null) || (attribute.value == value)))
        {
          return attribute;
        }
      }
    }
    return null;
  }

  bool validateSelection(Map<String, LinkedHashSet<String>> selection) {
    LinkedHashSet<String>? attributeLabels = selection[id];
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
    return ((minRequiredCount == null) || (minRequiredCount! <= selectedAttributesCount)) &&
           ((maxRequiredCount == null) || (selectedAttributesCount <= maxRequiredCount!));
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

/////////////////////////////////////
// ContentAttributesCategoryWidget

enum ContentAttributesCategoryWidget { dropdown, checkbox }

ContentAttributesCategoryWidget? contentAttributesCategoryWidgetFromString(String? value) {
  switch(value) {
    case 'dropdown': return ContentAttributesCategoryWidget.dropdown;
    case 'checkbox': return ContentAttributesCategoryWidget.checkbox;
    default: return null;
  }
}

String? contentAttributesCategoryWidgetToString(ContentAttributesCategoryWidget? value) {
  switch(value) {
    case ContentAttributesCategoryWidget.dropdown: return 'dropdown';
    case ContentAttributesCategoryWidget.checkbox: return 'checkbox';
    default: return null;
  }
}

/////////////////////////////////////
// ContentAttribute

class ContentAttribute {
  final String? label;
  final dynamic value;
  final Map<String, dynamic>? requirements;

  ContentAttribute({this.label, this.value, this.requirements});

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
        value: json['value'],
        requirements: JsonUtils.mapValue(json['requirements']),
      );
    }
    else {
      return null;
    }
  }

  toJson() => {
    'label': label,
    'value': value,
    'requirements': requirements,
  };

  // Equality

  @override
  bool operator==(dynamic other) =>
    (other is ContentAttribute) &&
    (label == other.label) &&
    (value == other.value) &&
    DeepCollectionEquality().equals(requirements, other.requirements);

  @override
  int get hashCode =>
    (label?.hashCode ?? 0) ^
    (value?.hashCode ?? 0) ^
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