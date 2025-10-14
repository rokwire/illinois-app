
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/PopScopeFix.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';

class Map2FilterBuildingAmenitiesPanel extends StatefulWidget {
  final Map<String, String> amenities; // Map<Key, Name> of Building Amenities
  final LinkedHashSet<String> selectedAmenityIds;

  Map2FilterBuildingAmenitiesPanel({super.key, required this.amenities, required this.selectedAmenityIds });

  @override
  State<StatefulWidget> createState() => _Map2FilterBuildingAmenitiesPanelState();

}

class _Map2FilterBuildingAmenitiesPanelState extends State<Map2FilterBuildingAmenitiesPanel> {

  late List<String> _amenityIdsList;
  late LinkedHashSet<String> _selectedAmenityIds;

  @override
  void initState() {

    _amenityIdsList = List.from(widget.amenities.keys);
    _amenityIdsList.sort((String amenityId1, String amenityId2) {
      String amenityName1 = widget.amenities[amenityId1] ?? '';
      String amenityName2 = widget.amenities[amenityId2] ?? '';
      return amenityName1.compareTo(amenityName2);
    });

    _selectedAmenityIds = LinkedHashSet<String>.from(widget.selectedAmenityIds);

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
    (_selectedAmenityIds.isNotEmpty) ? <Widget>[
      HeaderBarActionTextButton(
        title:  Localization().getStringEx('panel.map2.filter.amenities.clear.title', 'Clear'),
        onTap: _onTapClear,
      )] : null;

  String get _infoText =>
    Localization().getStringEx('panel.map2.filter.amenities.info', 'Choose from the below amenities to view buildings with one or more of these amenities.');

  BoxDecoration get _contentDecoration => BoxDecoration(
    color: Styles().colors.surface,
    border: Border.all(color: _borderColor, width: 1),
    borderRadius: BorderRadius.all(Radius.circular(8))
  );

  Color get _borderColor => Styles().colors.surfaceAccent;

  List<Widget> get _contentList {
    List<Widget> contentList = <Widget>[];
    for (String amenityId in _amenityIdsList) {
      if (contentList.isNotEmpty) {
        contentList.add(_contentSplitter);
      }
      contentList.add(_contentEntry(amenityId));
    }
    return contentList;
  }

  Widget _contentEntry(String anemityId) {
    String title = _anemityTitle(anemityId);
    bool isSelected = _selectedAmenityIds.contains(anemityId);
    TextStyle? titleStyle = Styles().textStyles.getTextStyle(isSelected ? "widget.group.dropdown_button.item.selected" : "widget.group.dropdown_button.item.not_selected");
    String? imageAsset = isSelected ? "check-box-filled" : "box-outline-gray";
    String? semanticsValue = isSelected ?  Localization().getStringEx("toggle_button.status.checked", "checked",) : Localization().getStringEx("toggle_button.status.unchecked", "unchecked");

    return Semantics(button: true, inMutuallyExclusiveGroup: false, value: semanticsValue,  child:
      InkWell(onTap: () => _onTapAmenity(anemityId), child:
        Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16), child:
          Row(children: <Widget>[
            Expanded(child:
              Padding(padding: const EdgeInsets.only(right: 8), child:
                Text(title, style: titleStyle,)
              )
            ),

            Styles().images.getImage(imageAsset, excludeFromSemantics: true) ?? Container()
          ]),
        )
    ));
  }

  String _anemityTitle(String anemityId) {
    String? amenityName = widget.amenities[anemityId];
    return (amenityName?.isNotEmpty == true) ? "$amenityName ($anemityId)" : "($anemityId)";
  }

  Widget get _contentSplitter =>
    Container(color: _borderColor, margin: EdgeInsets.symmetric(horizontal: 16), height: 1,);

  void _onTapAmenity(String anemityId) {
    setState(() {
      if (_selectedAmenityIds.contains(anemityId)) {
        _selectedAmenityIds.remove(anemityId);
      }
      else {
        _selectedAmenityIds.add(anemityId);
      }
    });
  }


  void _onTapClear() {
    Analytics().logSelect(target: 'Clear');
    setState(() {
      _selectedAmenityIds.clear();
    });
  }

  void _onHeaderBack() {
    Analytics().logSelect(target: 'Back');
    Navigator.of(context).pop(_selectedAmenityIds);
  }
}