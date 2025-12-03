
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/PopScopeFix.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';

class Map2FilterBuildingAmenitiesPanel extends StatefulWidget {
  final Map<String, Set<String>> amenitiesNameToIds; // Map<Key, Name> of Building Amenities
  final LinkedHashMap<String, Set<String>> selectedAmenitiesNameToIds;

  Map2FilterBuildingAmenitiesPanel({super.key, required this.amenitiesNameToIds, required this.selectedAmenitiesNameToIds });

  @override
  State<StatefulWidget> createState() => _Map2FilterBuildingAmenitiesPanelState();

}

class _Map2FilterBuildingAmenitiesPanelState extends State<Map2FilterBuildingAmenitiesPanel> {

  late List<String> _displayAmenityNames;
  late LinkedHashMap<String, Set<String>> _selectedAmenitiesNameToIds;

  @override
  void initState() {
    _displayAmenityNames = List.from(widget.amenitiesNameToIds.keys);
    _displayAmenityNames.sort();

    _selectedAmenitiesNameToIds = LinkedHashMap.from(widget.selectedAmenitiesNameToIds);

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
    (_selectedAmenitiesNameToIds.isNotEmpty) ? <Widget>[
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
    List<Widget> contentList = <Widget>[];
    for (String amenityName in _displayAmenityNames) {
      if (contentList.isNotEmpty) {
        contentList.add(_contentSplitter);
      }
      contentList.add(_contentEntry(amenityName));
    }
    return contentList;
  }

  Widget _contentEntry(String anemityName) {
    bool isSelected = _selectedAmenitiesNameToIds[anemityName]?.isNotEmpty == true;
    TextStyle? titleStyle = Styles().textStyles.getTextStyle(isSelected ? "widget.group.dropdown_button.item.selected" : "widget.group.dropdown_button.item.not_selected");
    String? imageAsset = isSelected ? "check-box-filled" : "box-outline-gray";
    String? semanticsValue = isSelected ?  Localization().getStringEx("toggle_button.status.checked", "checked",) : Localization().getStringEx("toggle_button.status.unchecked", "unchecked");

    return Semantics(button: true, inMutuallyExclusiveGroup: false, value: semanticsValue,  child:
      InkWell(onTap: () => _onTapAmenity(anemityName), child:
        Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16), child:
          Row(children: <Widget>[
            Expanded(child:
              Padding(padding: const EdgeInsets.only(right: 8), child:
                Text(anemityName, style: titleStyle,)
              )
            ),

            Styles().images.getImage(imageAsset, excludeFromSemantics: true) ?? Container()
          ]),
        )
    ));
  }

  Widget get _contentSplitter =>
    Container(color: _borderColor, margin: EdgeInsets.symmetric(horizontal: 16), height: 1,);

  void _onTapAmenity(String anemityName) {
    Set<String>? anemityIds = widget.amenitiesNameToIds[anemityName];
    if (anemityIds != null) {
      setState(() {
        if (_selectedAmenitiesNameToIds[anemityName]?.isNotEmpty == true) {
          _selectedAmenitiesNameToIds.remove(anemityName);
        }
        else {
          _selectedAmenitiesNameToIds[anemityName] = anemityIds;
        }
      });
    }
  }


  void _onTapClear() {
    Analytics().logSelect(target: 'Clear');
    setState(() {
      _selectedAmenitiesNameToIds.clear();
    });
  }

  void _onHeaderBack() {
    Analytics().logSelect(target: 'Back');
    Navigator.of(context).pop(_selectedAmenitiesNameToIds);
  }
}