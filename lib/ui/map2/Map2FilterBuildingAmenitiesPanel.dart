
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:illinois/ext/Building.dart';
import 'package:illinois/model/Building.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/PopScopeFix.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';

class Map2FilterBuildingAmenitiesPanel extends StatefulWidget {
  final Map<String, BuildingFeature> amenitiesMap; // Map<Key, Name> of Building Amenities
  final Set<String> selectedKeys;

  Map2FilterBuildingAmenitiesPanel({ super.key, required this.amenitiesMap, required this.selectedKeys });

  @override
  State<StatefulWidget> createState() => _Map2FilterBuildingAmenitiesPanelState();

}

class _Map2FilterBuildingAmenitiesPanelState extends State<Map2FilterBuildingAmenitiesPanel> {

  late List<String> _displayKeys;
  late Set<String> _selectedKeys;

  @override
  void initState() {
    _displayKeys = _buildDisplayAmenities();
    _selectedKeys = Set.from(widget.selectedKeys);
    super.initState();
  }

  @override
  Widget build(BuildContext context) =>
    PopScopeFix(onBack: _onHeaderBack, child:
      Scaffold(appBar: _headerBar, backgroundColor: Styles().colors.background,
        body: Column(children: [
          Expanded(child:
            Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
              SingleChildScrollView(child:
                Column(children: [
                  Padding(padding: EdgeInsets.symmetric(vertical: 16), child:
                    Row(children: [
                      Expanded(child:
                        Text(_infoText, style: Styles().textStyles.getTextStyle('widget.detail.small'),)
                      )
                    ],),
                  ),
                  Container(decoration: _contentDecoration, child:
                    Column(children: _contentList)
                  ),
                  ],)
              )
            ),
          ),
        ]),
      )
    );

  PreferredSizeWidget get _headerBar =>
    HeaderBar(title: _headerBarTitle, onLeading: _onHeaderBack, actions: _headerBarActions,);

  String get _headerBarTitle =>
    Localization().getStringEx('panel.map2.filter.amenities.title', 'Amenities');

  List<Widget>? get _headerBarActions =>
    (_selectedKeys.isNotEmpty) ? <Widget>[
      HeaderBarActionTextButton(
        title:  Localization().getStringEx('panel.map2.filter.amenities.clear.title', 'Clear'),
        onTap: _onTapClear,
      )] : null;

  String get _infoText =>
    Localization().getStringEx('panel.map2.filter.amenities.info', 'To view buildings with specific amenities, choose one or more of the options below and tap the back button.');

  BoxDecoration get _contentDecoration => BoxDecoration(
    color: Styles().colors.surface,
    border: Border.all(color: _borderColor, width: 1),
    borderRadius: BorderRadius.all(Radius.circular(8))
  );

  Color get _borderColor => Styles().colors.surfaceAccent;

  List<Widget> get _contentList {
    String? lastAmenityCategory = null;
    List<Widget> contentList = <Widget>[];
    for (String amenityKey in _displayKeys) {
      BuildingFeature? amenityFeature = widget.amenitiesMap[amenityKey];
      String? amenityCategory = amenityFeature?.filterCategory;

      if (contentList.isNotEmpty) {
        contentList.add(((lastAmenityCategory == null) || (lastAmenityCategory != amenityCategory)) ? _contentSectionSplitter : _contentFeatureSplitter);
      }
      contentList.add(_contentEntry(amenityKey));
      lastAmenityCategory = amenityCategory;
    }
    return contentList;
  }

  Widget _contentEntry(String amenityKey) {
    BuildingFeature? amenityFeature = widget.amenitiesMap[amenityKey];
    String amenityName = amenityFeature?.value?.name ?? '';
    bool isSelected = _selectedKeys.contains(amenityKey);
    TextStyle? titleStyle = Styles().textStyles.getTextStyle(isSelected ? "widget.group.dropdown_button.item.selected" : "widget.group.dropdown_button.item.not_selected");
    String? imageAsset = isSelected ? "check-box-filled" : "box-outline-gray";
    String? semanticsValue = isSelected ?  Localization().getStringEx("toggle_button.status.checked", "checked",) : Localization().getStringEx("toggle_button.status.unchecked", "unchecked");

    return Semantics(button: true, inMutuallyExclusiveGroup: false, value: semanticsValue,  child:
      InkWell(onTap: () => _onTapAmenity(amenityKey), child:
        Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16), child:
          Row(children: <Widget>[
            Expanded(child:
              Padding(padding: const EdgeInsets.only(right: 8), child:
                Text(amenityName, style: titleStyle,)
              )
            ),

            Styles().images.getImage(imageAsset, excludeFromSemantics: true) ?? Container()
          ]),
        )
    ));
  }

  Widget get _contentSectionSplitter =>
    Container(color: Styles().colors.mediumGray2, margin: EdgeInsets.symmetric(horizontal: 16), height: 1,);

  Widget get _contentFeatureSplitter =>
    Container(color: Styles().colors.surfaceAccent, margin: EdgeInsets.only(left: 16, right: 16+24+8), height: 1,);

  List<String> _buildDisplayAmenities() {
    List<String> amenityKeysList = List.from(widget.amenitiesMap.keys);

    amenityKeysList.sort((String key1, String key2) {
      String name1 = widget.amenitiesMap[key1]?.value?.name ?? '';
      String name2 = widget.amenitiesMap[key2]?.value?.name ?? '';
      return name1.compareTo(name2);
    });

    LinkedHashMap<String, List<String>> categoriesMap = LinkedHashMap<String, List<String>>();
    for (String amenityKey in amenityKeysList) {
      BuildingFeature? amenityFeature = widget.amenitiesMap[amenityKey];
      String amenityCategory = amenityFeature?.filterCategory ?? categoriesMap.length.toString();
      List<String>? categoryKeys = categoriesMap[amenityCategory];
      if (categoryKeys != null) {
        categoryKeys.add(amenityKey);
      }
      else {
        categoriesMap[amenityCategory] = <String>[amenityKey];
      }
    }

    List<String> displayAmenityKeys = <String>[];
    for (List<String> categoryKeys in categoriesMap.values) {
      displayAmenityKeys.addAll(categoryKeys);
    }
    return displayAmenityKeys;
  }

  void _onTapAmenity(String anemityKey) {
    setState(() {
      if (_selectedKeys.contains(anemityKey)) {
        _selectedKeys.remove(anemityKey);
      } else {
        _selectedKeys.add(anemityKey);
      }
    });
  }


  void _onTapClear() {
    Analytics().logSelect(target: 'Clear');
    setState(() {
      _selectedKeys.clear();
    });
  }

  void _onHeaderBack() {
    Analytics().logSelect(target: 'Back');
    Navigator.of(context).pop(_selectedKeys);
  }
}