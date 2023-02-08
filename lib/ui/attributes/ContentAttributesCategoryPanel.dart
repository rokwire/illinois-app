
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

  final ContentAttributes? contentAttributes;
  final ContentAttributesCategory? category;
  final List<ContentAttribute>? attributes;
  final LinkedHashSet<String>? selection;
  final bool multipleSelection;
  final bool filtersMode;

  ContentAttributesCategoryPanel({this.contentAttributes, this.category, this.attributes, this.selection, this.multipleSelection = false, this.filtersMode = false});

  @override
  State<StatefulWidget> createState() => _ContentAttributesCategoryPanelState();
}

class _ContentAttributesCategoryPanelState extends State<ContentAttributesCategoryPanel> {

  LinkedHashMap<String, List<ContentAttribute>> _contentMap = LinkedHashMap<String, List<ContentAttribute>>();
  LinkedHashSet<String> _selection = LinkedHashSet<String>();

  @override
  void initState() {
    super.initState();

    if (widget.selection != null) {
      _selection = LinkedHashSet<String>.from(widget.selection!);
    }

    if (widget.attributes != null) {
      for (ContentAttribute attribute in widget.attributes!) {
        Iterable<dynamic>? requirementAttributes = attribute.requirements?.values;
        dynamic requirementAttribute = (requirementAttributes?.isNotEmpty ?? false) ? requirementAttributes?.first : null;
        String contentMapKey = (requirementAttribute is String) ? requirementAttribute : '';
        (_contentMap[contentMapKey] ??= <ContentAttribute>[]).add(attribute);
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String? title = widget.contentAttributes?.stringValue(widget.category?.title);

    List<Widget> actions = <Widget>[];
    
    if ((0 < (widget.attributes?.length ?? 0)) && !widget.filtersMode && (widget.category?.isSingleSelection ?? false) && _selection.isNotEmpty) {
      actions.add(_buildHeaderBarButton(
        title:  Localization().getStringEx('dialog.clear.title', 'Clear'),
        onTap: _onTapClear,
      ));
    }

    if (widget.multipleSelection && !DeepCollectionEquality().equals(widget.selection ?? LinkedHashSet<String>(), _selection)) {
      actions.add(_buildHeaderBarButton(
        title:  Localization().getStringEx('dialog.apply.title', 'Apply'),
        onTap: _onTapApply,
      ));
    }

    return Scaffold(
      appBar: HeaderBar(title: title, actions: actions,),
      backgroundColor: Styles().colors?.background,
      body: Column(children: [
        Expanded(child:
          SingleChildScrollView(child:
            Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24,), child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children:
                _buildContent(),
              )
            ),
          ),
        )
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
                  style: TextStyle(fontFamily: Styles().fontFamilies?.bold, fontSize: 16, color: Styles().colors?.white,)
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

  List<Widget> _buildContent() {
    List<Widget> contentList = <Widget>[];
    _contentMap.forEach((String section, List<ContentAttribute> sectionAttributes) {

      if (contentList.isNotEmpty) {
        contentList.add(Container(height: 24,));
      }
      
      if (section.isEmpty) {
        section = widget.category?.title ?? '';
      }
      String displaySection = widget.contentAttributes?.stringValue(section) ?? section;

      contentList.add(Container(
        decoration: BoxDecoration(
          color: Styles().colors!.fillColorPrimary,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4))
        ),
        child: Semantics(label: displaySection, button: false, child: 
          Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12), child:
            Row(children: <Widget>[
              Expanded(child:
                Text(displaySection, textAlign: TextAlign.left, style:
                  Styles().textStyles?.getTextStyle("panel.settings.food_filter.title")
                ),
              )
            ],),
          ),
        ),
      ),);
      
      List<Widget> attributesList = <Widget>[];
      for (ContentAttribute attribute in sectionAttributes) {
        if (attributesList.isNotEmpty) {
          attributesList.add(Container(color: Colors.white, child:
            Padding(padding: EdgeInsets.symmetric(horizontal: 12), child:
              Container(height: 1, color: Styles().colors!.fillColorPrimaryTransparent03,)
            ),
          ));
        }
        attributesList.add(_buildAttributeWidget(attribute));
      }
      contentList.addAll(attributesList);
    });

    return contentList;
  }

  Widget _buildAttributeWidget(ContentAttribute attribute) {
    bool isSelected = _selection.contains(attribute.label);
    String? imageAsset = StringUtils.isNotEmpty(attribute.label) ?
      (widget.multipleSelection ?
        (isSelected ? "check-box-filled" : "box-outline-gray") :
        (isSelected ? "check-circle-filled" : "circle-outline")
      ) : null;
    String? title = StringUtils.isNotEmpty(attribute.label) ?
      widget.contentAttributes?.stringValue(attribute.label) :
      Localization().getStringEx('panel.content.attributes.button.clear.title', 'Clear');
    TextStyle? textStyle = StringUtils.isNotEmpty(attribute.label) ?
      Styles().textStyles?.getTextStyle(isSelected ? "widget.group.dropdown_button.item.selected" : "widget.group.dropdown_button.item.not_selected") :
      TextStyle(fontFamily: Styles().fontFamilies?.regular, fontSize: 16, color: Styles().colors?.fillColorSecondary);
    

    return InkWell(onTap: () => _onTapAttribute(attribute), child:
      Container(color: (Colors.white), padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16), child:
        Row(mainAxisSize: MainAxisSize.max, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: <Widget>[
          Flexible(child:
            Padding(padding: const EdgeInsets.only(right: 8), child:
              Text(title ?? attribute.label ?? '', overflow: TextOverflow.ellipsis, style: textStyle,),
            )
          ),
          
          Styles().images?.getImage(imageAsset, excludeFromSemantics: true) ?? Container()
        ]),
      )
    );
  }

  void _onTapAttribute(ContentAttribute attribute) {
    Analytics().logSelect(target: attribute.label, source: widget.category?.title);

    String? attributeLabel = attribute.label;
    if (attributeLabel != null) {
      if (_selection.contains(attributeLabel)) {
        _selection.remove(attributeLabel);
      }
      else {
        _selection.add(attributeLabel);
      }
    }
    else {
      _selection.clear();
    }

    if (!widget.filtersMode) {
      widget.category?.requirements?.validateAttributesSelection(_selection);
    }

    if (widget.multipleSelection || widget.filtersMode) {
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
    _selection.clear();
    if (widget.multipleSelection) {
      setStateIfMounted(() {});
    }
    else {
      Navigator.of(context).pop(_selection);
    }
  }
}