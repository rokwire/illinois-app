
import 'dart:collection';
import 'dart:ui';

import 'package:rokwire_plugin/model/places.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

extension PlaceExt on Place {
  Color? get uiColor => Styles().colors.mtdColor;
  Color? get mapMarkerBorderColor => Styles().colors.fillColorSecondary;
  Color? get mapMarkerTextColor => Styles().colors.white;
}

extension PlaceFilter on Place {
  bool matchSearchTextLowerCase(String searchLowerCase) =>
    (searchLowerCase.isNotEmpty && (
      (name?.toLowerCase().contains(searchLowerCase) == true) ||
      (subtitle?.toLowerCase().contains(searchLowerCase) == true) ||
      (address?.toLowerCase().contains(searchLowerCase) == true) ||
      (description?.toLowerCase().contains(searchLowerCase) == true)
    ));

  bool get isVisited => userData?.visited?.isNotEmpty == true;

  bool matchTags(LinkedHashSet<String> filterTags) {
    if (tags != null) {
      for (String tag in tags!) {
        if (filterTags.contains(tag)) {
          return true;
        }
      }
    }
    return false;
  }
}

extension PlaceUI on Place {
  List<String> get displayTypes {
    List<String> displayTypes = <String>[];
    if (isVisited) {
      displayTypes.add(Localization().getStringEx('panel.map2.filter.visited.text', 'Visited'));
    }
    if (types?.isNotEmpty == true) {
      displayTypes.addAll(types ?? []);
    }
    return displayTypes;
  }
}

extension IterablePlaceTag on Iterable<Place>  {

  LinkedHashMap<String, dynamic> get tags {
    Map<String, dynamic> tags = <String, dynamic>{};
    for (Place place in this) {
      List<String>? placeTags = place.tags;
      if (placeTags != null) {
        for (String placeTag in placeTags) {
          List<String> subTags = placeTag.split('.');
          Map<String, dynamic> rawTags = tags;
          for (String subTag in subTags) {
            rawTags = (rawTags[subTag] ??= Map<String, dynamic>());
          }
        }
      }
    }
    return tags.sortTagsByKeys();
  }
}

extension MapStringSortTag on Map<String, dynamic>  {

  LinkedHashMap<String, dynamic> sortTagsByKeys() {
    LinkedHashMap<String, dynamic> tags = LinkedHashMap<String, dynamic>();
    if (this.isNotEmpty) {
      List<String> entries = List<String>.from(keys);
      entries.sort((s1, s2) => s1.trim().toLowerCase().compareTo(s2.trim().toLowerCase()));
      for (String entry in entries) {
        tags[entry] = JsonUtils.cast<Map<String, dynamic>>(this[entry])?.sortTagsByKeys() ?? this[entry];
      }
    }
    return tags;
  }
}

extension StringTag on String  {
  String? get tagHead {
    List<String> subTags = this.split('.');
    if (1 < subTags.length) {
      subTags.removeLast();
      return List<String>.from(subTags).join('.');
    }
    else {
      return null;
    }
  }
}

extension DisplayTagsUtil on LinkedHashSet<String> {
  LinkedHashMap<String, LinkedHashSet<String>> get displayTags {
    LinkedHashSet<String> simpleTags = LinkedHashSet<String>();
    LinkedHashMap<String, LinkedHashSet<String>> compoundTags = LinkedHashMap<String, LinkedHashSet<String>>();
    for (String tag in this) {
      List<String> subTags = tag.split('.');
      if (1 < subTags.length) {
        String tagCategory = subTags.removeAt(0);
        String tagValue = subTags.join('.');
        LinkedHashSet rootValues = compoundTags[tagCategory] ??= LinkedHashSet<String>();
        rootValues.add(tagValue);
      }
      else {
        simpleTags.add(tag);
      }
    }

    LinkedHashMap<String, LinkedHashSet<String>> displayTags = LinkedHashMap<String, LinkedHashSet<String>>();
    if (simpleTags.isNotEmpty) {
      displayTags[''] = simpleTags;
    }
    displayTags.addAll(compoundTags);
    return displayTags;
  }
}