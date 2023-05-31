import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/attributes/ContentAttributesCategoryPanel.dart';
import 'package:illinois/ui/groups/GroupWidgets.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/content_attributes.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';


class ContentAttributesPanel extends StatefulWidget {
  final String? title;
  final String? description;
  final bool filtersMode;
  final Map<String, dynamic>? selection;
  final ContentAttributes? contentAttributes;

  ContentAttributesPanel({Key? key, this.title, this.description, this.contentAttributes, this.selection, this.filtersMode = false }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ContentAttributesPanelState();
}

class _ContentAttributesPanelState extends State<ContentAttributesPanel> {

  Map<String, LinkedHashSet<String>> _selection = <String, LinkedHashSet<String>>{};

  @override
  void initState() {
    if (widget.selection != null) {
      _selection = ContentAttributes.selectionFromAttributesSelection(widget.selection) ?? Map<String, LinkedHashSet<String>>();
    }
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(title: widget.title),
      backgroundColor: Styles().colors?.background,
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    List<ContentAttribute>? attributes = widget.contentAttributes?.attributes;
    return ((attributes != null) && attributes.isNotEmpty) ? Column(children: <Widget>[
      Expanded(child:
        Container(padding: EdgeInsets.only(left: 16, right: 24, top: 8), child:
          SingleChildScrollView(child:
            _buildAttributesContent(),
          ),
        ),
      ),
      // Container(height: 1, color: Styles().colors?.surfaceAccent),
      _buildCommands(),
    ]) : Container();
  }

  Widget _buildAttributesContent() {
    List<Widget> conentList = <Widget>[];

    if (StringUtils.isNotEmpty(widget.description)) {
      conentList.add(Padding(padding: EdgeInsets.only(top: 16, bottom: 8), child:
        Text(widget.description ?? '', style: Styles().textStyles?.getTextStyle("widget.description.regular")),
      ));
    }

    List<ContentAttribute>? attributes = ListUtils.from<ContentAttribute>(widget.contentAttributes?.attributes);
    if ((attributes != null) && attributes.isNotEmpty) {
      attributes.sort((ContentAttribute attribute1, ContentAttribute attribute2) {
        String attributeTitle1 = attribute1.displayTitle ?? '';
        String attributeTitle2 = attribute2.displayTitle ?? '';
        return attributeTitle1.compareTo(attributeTitle2);
      });
      for (ContentAttribute attribute in attributes) {
        Widget? attributeWidget;
        switch (attribute.widget) {
          case ContentAttributeWidget.dropdown: attributeWidget = _buildAttributeDropDown(attribute); break;
          case ContentAttributeWidget.checkbox: attributeWidget = _buildAttributeCheckbox(attribute); break;
          default: break;
        }
        if (attributeWidget != null) {
          conentList.add(attributeWidget);
        }
      }
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: conentList,); 
  }

  Widget _buildAttributeDropDown(ContentAttribute attribute) {
    LinkedHashSet<String>? attributeLabels = _selection[attribute.id];
    bool hasSelection = ((attributeLabels != null) && attributeLabels.isNotEmpty);
    LinkedHashSet<String>? displayAttributeLabels = (CollectionUtils.isEmpty(attributeLabels) && (attribute.nullValue is String)) ?
      LinkedHashSet<String>.from([attribute.nullValue]) : attributeLabels;

    List<ContentAttributeValue>? attributeValues = attribute.attributeValuesFromSelection(_selection);
    bool visible = (attributeValues?.isNotEmpty ?? false);
    bool enabled = (attributeValues?.isNotEmpty ?? false) && (hasSelection || (widget.contentAttributes?.requirements?.canSelectMoreCategories(_selection) ?? true));

    String? title = _constructAttributeDropdownTitle(attribute, displayAttributeLabels);
    String? hint = widget.filtersMode ? (attribute.displaySemanticsFilterHint ?? attribute.displaySemanticsHint) : attribute.displaySemanticsHint;
    TextStyle? textStyle = Styles().textStyles?.getTextStyle(hasSelection ? 'widget.group.dropdown_button.value' : 'widget.group.dropdown_button.hint');
    void Function()? onTap = enabled ? () => _onAttributeDropdownTap(attribute: attribute, attributeValues: attributeValues) : null;
    
    return Visibility(visible: visible, child:
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        GroupSectionTitle(
          title: (attribute.displayLongTitle ?? attribute.displayTitle)?.toUpperCase(),
          description: attribute.displayDescription,
          requiredMark: !widget.filtersMode && attribute.isRequired,
        ),
        _AttributeRibbonButton(
          title: title, hint: hint, textStyle: textStyle, onTap: onTap,
        ),
      ]),
    );
  }

  String? _constructAttributeDropdownTitle(ContentAttribute attribute, LinkedHashSet<String>? attributeLabels) {
    if ((attributeLabels == null) || attributeLabels.isEmpty) {
      return widget.filtersMode ? (attribute.displayEmptyFilterHint ?? attribute.displayEmptyHint) : attribute.displayEmptyHint;
    }
    else if (attributeLabels.length == 1) {
      return attribute.displayString(attributeLabels.first);
    }
    else {
      String title = '';
      for (String attributeLabel in attributeLabels) {
        String attributeName = attribute.displayString(attributeLabel) ?? attributeLabel;
        if (attributeName.isNotEmpty) {
          if (title.isNotEmpty) {
            title += ', ';
          }
          title += attributeName;
        }
      }
      return title;
    }
  }

  void _onAttributeDropdownTap({ContentAttribute? attribute, List<ContentAttributeValue>? attributeValues}) {
    Analytics().logSelect(target: attribute?.title);
    String? attributeId = attribute?.id;

    LinkedHashSet<String>? attributeLabels = _selection[attribute?.id];
    LinkedHashSet<String>? displayAttributeLabels = (CollectionUtils.isEmpty(attributeLabels) && (attribute?.nullValue is String)) ?
      LinkedHashSet<String>.from([attribute?.nullValue]) : attributeLabels;

    Navigator.push<LinkedHashSet<String>?>(context, CupertinoPageRoute(builder: (context) => ContentAttributesCategoryPanel(
      attribute: attribute,
      attributeValues: attributeValues,
      selection: displayAttributeLabels,
      multipleSelection: widget.filtersMode || (attribute?.isMultipleSelection ?? false),
      filtersMode: widget.filtersMode,
    ),)).then(((LinkedHashSet<String>? selection) {
      if ((selection != null) && (attributeId != null)) {
        if ((attribute?.nullValue is String) && selection.contains(attribute?.nullValue)) {
          selection.remove(attribute?.nullValue);
        }
        setStateIfMounted(() {
          _selection[attributeId] = selection;
          widget.contentAttributes?.validateSelection(_selection);
          if (!widget.filtersMode) {
            widget.contentAttributes?.extendSelection(_selection, attributeId);
          }
        });
      }
    }));
  }

  Widget _buildAttributeCheckbox(ContentAttribute attribute) {

    List<ContentAttributeValue>? attributeValues = attribute.attributeValuesFromSelection(_selection);

    LinkedHashSet<String>? attributeLabels = _selection[attribute.id];
    ContentAttributeValue? selectedAttributeValue = ((attributeLabels != null) && attributeLabels.isNotEmpty) ?
      attribute.findValue(label: attributeLabels.first) : null;
    dynamic displayValue = selectedAttributeValue?.value ?? attribute.nullValue;

    bool visible = (attributeValues?.isNotEmpty ?? false);
    bool enabled = (attributeValues?.isNotEmpty ?? false) && ((selectedAttributeValue != null) || (widget.contentAttributes?.requirements?.canSelectMoreCategories(_selection) ?? true));

    String imageAsset;
    if (enabled) {
      switch (displayValue) {
        case true:  imageAsset = "check-box-filled"; break;
        case false: imageAsset = "box-outline-gray"; break;
        default:    imageAsset = "box-inside-light-gray"; break;
      }
    }
    else {
      imageAsset = "box-inside-gray";
    }
    
    String? text = (displayValue != null) ? attribute.text : (widget.filtersMode ? (attribute.emptyFilterHint ?? attribute.emptyHint) : attribute.emptyHint);
    TextStyle? textStyle = Styles().textStyles?.getTextStyle((selectedAttributeValue != null) ? 'widget.group.dropdown_button.value' : 'widget.group.dropdown_button.hint');

    return Visibility(visible: visible, child:
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        GroupSectionTitle(
          title: (attribute.displayLongTitle ?? attribute.displayTitle)?.toUpperCase(),
          description: attribute.displayDescription,
          requiredMark: !widget.filtersMode && attribute.isRequired,
        ),
        Container (
          decoration: BoxDecoration(
            color: Styles().colors!.white,
            border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1),
            borderRadius: BorderRadius.all(Radius.circular(4))
          ),
          //padding: const EdgeInsets.only(left: 12, right: 8),
          child: InkWell(onTap: () => enabled ? _onAttributeCheckbox(attribute) : null,
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child:
                Padding(padding: EdgeInsets.only(left: 12, top: 16, bottom: 16), child:
                  Text(text ?? '', style: textStyle,)
                ),
              ),
              Padding(padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16), child:
                Styles().images?.getImage(imageAsset, excludeFromSemantics: true,) ?? Container(),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  void _onAttributeCheckbox(ContentAttribute attribute) {
    String? attributeId = attribute.id;
    if (attributeId != null) {
      List<ContentAttributeValue>? attributeValues = attribute.attributeValuesFromSelection(_selection);
      LinkedHashSet<String> attributeLabels = _selection[attributeId] ??= LinkedHashSet<String>();
      ContentAttributeValue? selectedAttributeValue = attributeLabels.isNotEmpty ?
        ContentAttributeValue.findInList(attributeValues, label: attributeLabels.first) : null;
      
      dynamic selectedValue = selectedAttributeValue?.value;
      if (attribute.nullValue != null) {
        selectedValue ??= attribute.nullValue;
        selectedValue = (selectedValue ?? false) == false;
        selectedValue = (selectedValue != attribute.nullValue) ? selectedValue : null;
      }
      else switch(selectedValue) {
        case true:  selectedValue = false; break;
        case false: selectedValue = null; break;
        default:    selectedValue = true; break;
      }
      selectedAttributeValue = (selectedValue != null) ? ContentAttributeValue.findInList(attributeValues, value: selectedValue) : null;

      String? selectedLabel = selectedAttributeValue?.label;
      Analytics().logSelect(target: selectedAttributeValue?.label, source: attribute.title);
      setStateIfMounted(() {
        attributeLabels.clear();
        if (selectedLabel != null) {
          attributeLabels.add(selectedLabel);
        }
      });
    }


  }

  bool get _isSelectionNotEmpty {
    for (LinkedHashSet<String> attributeLabels in _selection.values) {
      if (attributeLabels.isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  bool get _isInitialSelectionNotEmpty {

    Iterable<dynamic>? selectionValues = widget.selection?.values;
    if (selectionValues != null) {
      for (dynamic attributeLabels in selectionValues) {
        if (((attributeLabels is String)) ||
            ((attributeLabels is List) && attributeLabels.isNotEmpty))
        {
          return true;
        }
      }
    }

    return false;
  }

  Widget _buildCommands() {
    List<Widget> buttons = <Widget>[];

    if (widget.filtersMode) {
      bool canClear = _isInitialSelectionNotEmpty;
      buttons.addAll(<Widget>[
        Expanded(child: RoundedButton(
          label: Localization().getStringEx('panel.content.attributes.button.clear.title', 'Clear'),
          textStyle: canClear ? Styles().textStyles?.getTextStyle("widget.button.title.large.fat") : Styles().textStyles?.getTextStyle("widget.button.disabled.title.large.fat"),
          borderColor: canClear ? Styles().colors?.fillColorSecondary : Styles().colors?.surfaceAccent ,
          backgroundColor: Styles().colors?.white,
          enabled: canClear,
          onTap: _onTapClear
        )
      )]);
    }

    bool canApply = (widget.filtersMode && _isSelectionNotEmpty) || (!widget.filtersMode && (widget.contentAttributes?.isSelectionValid(_selection) ?? false));
    String applyTitle = widget.filtersMode ? 
      Localization().getStringEx('panel.content.attributes.button.filter.title', 'Filter') :
      Localization().getStringEx('panel.content.attributes.button.apply.title', 'Apply Attributes');
    buttons.add(Expanded(child:
      RoundedButton(
        label: applyTitle,
        textStyle: canApply ? Styles().textStyles?.getTextStyle("widget.button.title.large.fat") : Styles().textStyles?.getTextStyle("widget.button.disabled.title.large.fat"),
        borderColor: canApply ? Styles().colors?.fillColorSecondary : Styles().colors?.surfaceAccent ,
        backgroundColor: Styles().colors?.white,
        enabled: canApply,
        onTap: _onTapApply
      )
    ));
    return SafeArea(child:
      Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16), child:
        Row(children: buttons,)
      )
    );
  }

  void _onTapApply() {
    Analytics().logSelect(target: 'Apply');
    Navigator.of(context).pop(ContentAttributes.selectionToAttributesSelection(_selection) ?? <String, dynamic>{});
  }

  void _onTapClear() {
    Analytics().logSelect(target: 'Clear');
    Navigator.of(context).pop(<String, dynamic>{});
  }
}

class _AttributeRibbonButton extends StatelessWidget {
  final String? title;
  final String? hint;
  final TextStyle? textStyle;
  final Function()? onTap;

  _AttributeRibbonButton({Key? key, this.title, this.hint, this.textStyle, this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(onTap: onTap, child:
      Container (
        decoration: BoxDecoration(
          color: Styles().colors!.white,
          border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1),
          borderRadius: BorderRadius.all(Radius.circular(4))
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
          Semantics(container: true, label: title, hint: hint, excludeSemantics: true, child:
            Row(children: [
              Expanded(child:
                Padding(padding: EdgeInsets.only(left: 12, top: 18, bottom: 18), child:
                  Text(title ?? '', style: textStyle),
                ),
              ),
              Padding(padding: EdgeInsets.all(12), child:
                Styles().images?.getImage('chevron-right', excludeFromSemantics: true) ?? SizedBox(width: 10, height: 6),
              ),
            ],),
          ),
        ])
      ),
    );
  }
}