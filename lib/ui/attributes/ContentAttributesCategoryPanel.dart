
import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/content_attributes.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class ContentAttributesCategoryPanel extends StatefulWidget {

  final ContentAttribute? attribute;
  final ContentAttributes? contentAttributes;
  final List<ContentAttributeValue>? attributeValues;
  final LinkedHashSet<dynamic>? selection;
  final bool filtersMode;

  ContentAttributesCategoryPanel({this.attribute, this.contentAttributes, this.attributeValues, this.selection, this.filtersMode = false});

  @override
  State<StatefulWidget> createState() => _ContentAttributesCategoryPanelState();

  LinkedHashSet<String> get emptySelection => (attribute?.nullValue != null) ? LinkedHashSet<String>.from([attribute?.nullValue]) : LinkedHashSet<String>();
}

class _ContentAttributesCategoryPanelState extends State<ContentAttributesCategoryPanel> {

  List<dynamic> _contentList = <dynamic>[];
  LinkedHashSet<dynamic> _selection = LinkedHashSet<dynamic>();

  int get requirementsScope => widget.filtersMode ? contentAttributeRequirementsScopeFilter : contentAttributeRequirementsScopeCreate;

  bool get singleSelection => widget.attribute?.isSingleSelection(requirementsScope) ?? true;
  bool get multipleSelection => widget.attribute?.isMultipleSelection(requirementsScope) ?? false;

  @override
  void initState() {
    super.initState();

    if (widget.selection != null) {
      _selection = LinkedHashSet<dynamic>.from(widget.selection!);
    }

    if (widget.attributeValues != null) {
      LinkedHashMap<String, List<ContentAttributeValue>> contentMap = LinkedHashMap<String, List<ContentAttributeValue>>();
      for (ContentAttributeValue attributeValue in widget.attributeValues!) {
        Map<String, dynamic>? attributeRequirements = attributeValue.requirements;
        String? requirementAttributeId = ((attributeRequirements != null) && attributeRequirements.isNotEmpty) ? attributeRequirements.keys.first : null;
        ContentAttribute? requirementAttribute = (requirementAttributeId != null) ? widget.contentAttributes?.findAttribute(id: requirementAttributeId) : null;
        dynamic requirementAttributeRawValue = ((attributeRequirements != null) && (requirementAttributeId != null)) ? attributeRequirements[requirementAttributeId] : null;
        String contentMapKey = requirementAttribute?.displayLabel(requirementAttributeRawValue) ?? '';
        (contentMap[contentMapKey] ??= <ContentAttributeValue>[]).add(attributeValue);
      }

      _contentList.add(_ContentItem.spacing);
      contentMap.forEach((String section, List<ContentAttributeValue> sectionAttributeValues) {

        // section heading
        if (section.isEmpty) {
          section = widget.attribute?.title ?? '';
        }
        section = widget.attribute?.displayString(section) ?? section;
        _contentList.add(section); 

        // section entries
        int startCount = _contentList.length;
        for (ContentAttributeValue attributeValue in sectionAttributeValues) {
          if (startCount < _contentList.length) {
            _contentList.add(_ContentItem.separator);
          }
          _contentList.add(attributeValue);
        }

        // spacing
        _contentList.add(_ContentItem.spacing);
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Widget

  @override
  Widget build(BuildContext context) {
    String? title = widget.attribute?.displayTitle;

    List<Widget> actions = <Widget>[];


    if (multipleSelection && !DeepCollectionEquality().equals(widget.selection ?? LinkedHashSet<dynamic>(), _selection)) {
      actions.add(_buildHeaderBarButton(
        title:  Localization().getStringEx('dialog.apply.title', 'Apply'),
        onTap: _onTapApply,
      ));
    }
    else if ((0 < (widget.attributeValues?.length ?? 0)) && !DeepCollectionEquality().equals(_selection, widget.emptySelection)) {
      actions.add(_buildHeaderBarButton(
        title:  Localization().getStringEx('dialog.clear.title', 'Clear'),
        onTap: _onTapClear,
      ));
    }

    return Scaffold(
      appBar: HeaderBar(title: title, actions: actions,),
      backgroundColor: Styles().colors?.background,
      body: Column(children: [
        Expanded(child:
          Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
            ListView.builder(
              itemBuilder: (BuildContext context, int index) => _buildListItem(context, index),
              itemCount: _contentList.length
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildHeaderBarButton({String? title, void Function()? onTap, double horizontalPadding = 16}) {
    return Semantics(label: title, button: true, excludeSemantics: true, child: 
      InkWell(onTap: onTap, child:
        Align(alignment: Alignment.center, child:
          Padding(padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 12), child:
            Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Styles().colors!.white!, width: 1.5, ))),
                child: Text(title ?? '',
                  style: Styles().textStyles?.getTextStyle("widget.heading.regular.fat")
                ),
              ),
            ],)
          ),
        ),
        //Padding(padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 12), child:
        //  Text(title ?? '', style: Styles().textStyles?.getTextStyle('panel.athletics.home.button.underline'))
        //),
      ),
    );
  }

  Widget _buildListItem(BuildContext context, int index) {
    dynamic sourceData = ((0 <= index) && (index < _contentList.length)) ? _contentList[index] : null;
    if (sourceData is String) {
      return _buildCaptionWidget(sourceData);
    }
    else if (sourceData is ContentAttributeValue) {
      return _buildAttributeValueWidget(sourceData);
    }
    else if (sourceData == _ContentItem.separator) {
      return Container(color: Colors.white, child:
        Padding(padding: EdgeInsets.symmetric(horizontal: 12), child:
          Container(height: 1, color: Styles().colors!.fillColorPrimaryTransparent03,)
        ),
      );
    }
    else if (sourceData == _ContentItem.spacing) {
      return Container(height: 24,);
    }
    else {
      return Container();
    }
  }

  Widget _buildCaptionWidget(String title) {
    return Container(
      decoration: BoxDecoration(
        color: Styles().colors!.fillColorPrimary,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4))
      ),
      child: Semantics(label: title, button: false, child: 
        Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12), child:
          Row(children: <Widget>[
            Expanded(child:
              Text(title, textAlign: TextAlign.left, style:
                Styles().textStyles?.getTextStyle("panel.settings.food_filter.title")
              ),
            )
          ],),
        ),
      ),
    );
  }

  Widget _buildAttributeValueWidget(ContentAttributeValue attributeValue) {
    bool isSelected = _selection.contains(attributeValue.value);
    String? imageAsset = (attributeValue.value != null) ?
      (multipleSelection ?
        (isSelected ? "check-box-filled" : "box-outline-gray") :
        (isSelected ? "check-circle-filled" : "circle-outline-gray")
      ) : null;
    
    String? title = StringUtils.isNotEmpty(attributeValue.label) ?
      widget.attribute?.displayString(attributeValue.label) :
      Localization().getStringEx('panel.content.attributes.button.clear.title', 'Clear');
    
    String? info = StringUtils.isNotEmpty(attributeValue.info) ?
      widget.attribute?.displayString(attributeValue.info) : null;

    TextStyle? textStyle = (attributeValue.value != null) ?
      Styles().textStyles?.getTextStyle(isSelected ? "widget.group.dropdown_button.item.selected" : "widget.group.dropdown_button.item.not_selected") :
      Styles().textStyles?.getTextStyle("widget.label.regular.thin");
    

    return InkWell(onTap: () => _onTapAttributeValue(attributeValue), child:
      Container(color: (Colors.white), padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16), child:
        Row(mainAxisSize: MainAxisSize.max, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: <Widget>[
          Flexible(child:
            Padding(padding: const EdgeInsets.only(right: 8), child:
              Text(title ?? attributeValue.label ?? '', overflow: TextOverflow.ellipsis, style: textStyle,),
            )
          ),

          Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
            Visibility(visible: StringUtils.isNotEmpty(info), child:
              Padding(padding: const EdgeInsets.only(right: 8), child:
                Text(info ?? attributeValue.info ?? '', overflow: TextOverflow.ellipsis, style: textStyle,),
              )
            ),
            
            Styles().images?.getImage(imageAsset, excludeFromSemantics: true) ?? Container()
          ]),
        ]),
      )
    );
  }

  void _onTapAttributeValue(ContentAttributeValue attributeValue) {
    Analytics().logSelect(target: attributeValue.label, source: widget.attribute?.title);

    dynamic attributeRawValue = attributeValue.value;
    if (attributeRawValue != null) {
      if (_selection.contains(attributeRawValue)) {
        _selection.remove(attributeRawValue);
      }
      else {
        _selection.add(attributeRawValue);
      }
    }
    else {
      _selection.clear();
    }

    if (widget.attribute?.requirements?.hasScope(requirementsScope) ?? false) {
      widget.attribute?.validateAttributeValuesSelection(_selection);
    }

    if (multipleSelection) {
      setStateIfMounted(() { });
    }
    else {
      Navigator.of(context).pop(_selection);
    }
  }

  void _onTapApply() {
    Analytics().logSelect(target: 'Close');
    Navigator.of(context).pop(_selection);
  }

  void _onTapClear() {
    _selection = widget.emptySelection;
    if (multipleSelection) {
      setStateIfMounted(() {});
    }
    else {
      Navigator.of(context).pop(_selection);
    }
  }
}

enum _ContentItem { spacing, separator }