import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/ext/ContentAttributes.dart';
import 'package:illinois/model/Analytics.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/ui/attributes/ContentAttributesCategoryPanel.dart';
import 'package:illinois/ui/groups/GroupWidgets.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/content_attributes.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';

enum ContentAttributesSortType { native, explicit, alphabetical, }

class ContentAttributesPanel extends StatefulWidget with AnalyticsInfo {
  final String? title;
  final String? bgImageKey;

  final String? description;
  final TextStyle? descriptionTextStyle;
  final Widget Function(BuildContext context)? descriptionBuilder;

  final TextStyle? sectionTitleTextStyle;
  final TextStyle? sectionDescriptionTextStyle;
  final TextStyle? sectionRequiredMarkTextStyle;

  final Widget? Function(BuildContext context)? footerBuilder;

  final Widget Function(BuildContext context, bool enabled, void Function() handler)? applyBuilder;
  final Widget Function(BuildContext context, void Function() handler)? continueBuilder;

  final String? scope;
  final bool filtersMode;
  final ContentAttributesSortType sortType;
  final Map<String, dynamic>? selection;
  final ContentAttributes? contentAttributes;

  final Future<bool?> Function({
    required BuildContext context,
    required ContentAttribute attribute,
    required ContentAttributeValue value
  })? handleAttributeValue;

  ContentAttributesPanel({Key? key, this.title, this.bgImageKey,
    this.description, this.descriptionTextStyle, this.descriptionBuilder,
    this.sectionTitleTextStyle, this.sectionDescriptionTextStyle, this.sectionRequiredMarkTextStyle,
    this.footerBuilder,
    this.applyBuilder,
    this.continueBuilder,
    this.contentAttributes, this.selection,
    this.sortType = ContentAttributesSortType.native,
    this.scope, this.filtersMode = false,
    this.handleAttributeValue,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ContentAttributesPanelState();

  @override
  AnalyticsFeature? get analyticsFeature => contentAttributes?.analyticsFeature;


}

class _ContentAttributesPanelState extends State<ContentAttributesPanel> {

  Map<String, LinkedHashSet<dynamic>> _selection = <String, LinkedHashSet<dynamic>>{};
  Map<String, LinkedHashSet<dynamic>> _initialSelection = <String, LinkedHashSet<dynamic>>{};
  ContentAttributes? _initialContentAttributes;

  int get requirementsScope => widget.filtersMode ? contentAttributeRequirementsFunctionalScopeFilter : contentAttributeRequirementsFunctionalScopeCreate;

  @override
  void initState() {
    if (widget.selection != null) {
      _selection = ContentAttributes.selectionFromAttributesSelection(widget.selection) ?? Map<String, LinkedHashSet<dynamic>>();
      _initialSelection = ContentAttributes.selectionFromAttributesSelection(widget.selection) ?? Map<String, LinkedHashSet<dynamic>>();
    }
    _initialContentAttributes = widget.contentAttributes?.clone();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(title: widget.title, actions: _headerBarActions),
      backgroundColor: Styles().colors.background,
      body: _buildScaffoldContent(),
    );
  }

  Widget _buildScaffoldContent() => (widget.bgImageKey != null) ?
    Stack(children: [
      _buildImageBackground(),
      _buildPanelContent(),
    ],) :
      _buildPanelContent();

  Widget _buildPanelContent() {
    List<ContentAttribute>? attributes = widget.contentAttributes?.attributes;
    return ((attributes != null) && attributes.isNotEmpty) ? Column(children: <Widget>[
      Expanded(child:
        Container(padding: EdgeInsets.only(left: 16, right: 24, top: 8), child:
          SingleChildScrollView(child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
              ..._buildAttributesContent(),
              _buildClearAttributes(),
              _buildFooter(),
              Padding(padding: const EdgeInsets.only(top: 24)),
            ]),
          ),
        ),
      ),
      // Container(height: 1, color: Styles().colors.surfaceAccent),
      SafeArea(child:
        _buildCommands(),
      ),
    ]) : Container();
  }

  List<Widget> _buildAttributesContent() {
    List<Widget> contentList = <Widget>[];

    Widget? descriptionWidget = _buildDescriptionWidget();
    if (descriptionWidget != null) {
      contentList.add(descriptionWidget);
    }

    List<ContentAttribute>? attributes = ListUtils.from<ContentAttribute>(widget.contentAttributes?.attributes);
    if ((attributes != null) && attributes.isNotEmpty) {
      switch(widget.sortType) {
        case ContentAttributesSortType.alphabetical: attributes.sort((ContentAttribute attribute1, ContentAttribute attribute2) => attribute1.compareByTitle(attribute2)); break;
        case ContentAttributesSortType.explicit: attributes.sort((ContentAttribute attribute1, ContentAttribute attribute2) => attribute1.compareBySortOrder(attribute2)); break;
        case ContentAttributesSortType.native: break;
      }
      for (ContentAttribute attribute in attributes) {
        Widget? attributeWidget;
        if (FlexUI().isAttributeEnabled(attribute.id, scope: widget.scope)) {
          switch (attribute.widget) {
            case ContentAttributeWidget.dropdown: attributeWidget = _buildAttributeDropDown(attribute); break;
            case ContentAttributeWidget.checkbox: attributeWidget = _buildAttributeCheckbox(attribute); break;
            default: break;
          }
        }
        if (attributeWidget != null) {
          contentList.add(attributeWidget);
        }
      }
    }

    return contentList;
  }

  Widget? _buildDescriptionWidget() {
    if (widget.descriptionBuilder != null) {
      return widget.descriptionBuilder!(context);
    }
    else if (StringUtils.isNotEmpty(widget.description)) {
      return Padding(padding: EdgeInsets.only(top: 16, bottom: 8), child:
        Text(widget.description ?? '', style: widget.descriptionTextStyle ?? Styles().textStyles.getTextStyle("widget.description.regular")),
      );
    }
    else {
      return null;
    }
  }

  Widget _buildAttributeDropDown(ContentAttribute attribute) {
    LinkedHashSet<dynamic>? attributeRawValues = _selection[attribute.id];
    bool hasSelection = ((attributeRawValues != null) && attributeRawValues.isNotEmpty);

    List<ContentAttributeValue>? attributeValues = attribute.attributeValuesFromSelection(_selection);
    bool visible = (attributeValues?.isNotEmpty ?? false);
    bool enabled = (attributeValues?.isNotEmpty ?? false) && (hasSelection || (widget.contentAttributes?.requirements?.canSelectMoreCategories(_selection) ?? true));

    String? title = _constructAttributeDropdownTitle(attribute, attributeRawValues);
    String? hint = widget.filtersMode ? (attribute.displaySemanticsFilterHint ?? attribute.displaySemanticsHint) : attribute.displaySemanticsHint;
    TextStyle? textStyle = Styles().textStyles.getTextStyle(hasSelection ? 'widget.group.dropdown_button.value' : 'widget.group.dropdown_button.hint');
    void Function()? onTap = enabled ? () => _onAttributeDropdownTap(attribute: attribute, attributeValues: attributeValues) : null;
    
    return Visibility(visible: visible, child:
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        GroupSectionTitle(
          title: (attribute.displayLongTitle ?? attribute.displayTitle)?.toUpperCase(),
          titleTextStyle: widget.sectionTitleTextStyle,
          description: !widget.filtersMode ? attribute.displayDescription : null,
          descriptionTextStyle: widget.sectionDescriptionTextStyle,
          requiredMark: !widget.filtersMode && attribute.isRequired(requirementsScope),
          requiredMarkTextStyle: widget.sectionRequiredMarkTextStyle,
        ),
        _AttributeRibbonButton(
          title: title, hint: hint, textStyle: textStyle, onTap: onTap,
        ),
      ]),
    );
  }

  String? _constructAttributeDropdownTitle(ContentAttribute attribute, LinkedHashSet<dynamic>? attributeRawValues) {

    if (CollectionUtils.isEmpty(attributeRawValues) && (attribute.nullValue is String)) {
      return attribute.displayString(attribute.nullValue);
    }
    else {
      List<String>? attributeLabels = attribute.displaySelectedLabelsFromRawValue(attributeRawValues);

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

  }

  void _onAttributeDropdownTap({required ContentAttribute attribute, List<ContentAttributeValue>? attributeValues}) {
    Analytics().logSelect(target: attribute.title);

    String? attributeId = attribute.id;
    LinkedHashSet<dynamic>? attributeRawValues = _selection[attributeId];

    Navigator.push<LinkedHashSet<dynamic>?>(context, CupertinoPageRoute(builder: (context) => ContentAttributesCategoryPanel(
      attribute: attribute,
      attributeValues: attributeValues,
      contentAttributes: widget.contentAttributes,
      selection: attributeRawValues,
      filtersMode: widget.filtersMode,
      handleAttributeValue: widget.handleAttributeValue,
    ),)).then(((LinkedHashSet<dynamic>? selection) {
      if ((selection != null) && (attributeId != null)) {
        if ((attribute.nullValue is String) && selection.contains(attribute.nullValue)) {
          selection.remove(attribute.nullValue);
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

    LinkedHashSet<dynamic>? attributeRawValues = _selection[attribute.id];
    ContentAttributeValue? selectedAttributeValue = ((attributeRawValues != null) && attributeRawValues.isNotEmpty) ?
      attribute.findValue(value: attributeRawValues.first) : null;
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
    TextStyle? textStyle = Styles().textStyles.getTextStyle((selectedAttributeValue != null) ? 'widget.group.dropdown_button.value' : 'widget.group.dropdown_button.hint');

    return Visibility(visible: visible, child:
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        GroupSectionTitle(
          title: (attribute.displayLongTitle ?? attribute.displayTitle)?.toUpperCase(),
          titleTextStyle: widget.sectionTitleTextStyle,
          description: attribute.displayDescription,
          descriptionTextStyle: widget.sectionDescriptionTextStyle,
          requiredMark: !widget.filtersMode && attribute.isRequired(requirementsScope),
          requiredMarkTextStyle: widget.sectionRequiredMarkTextStyle,
        ),
        Container (
          decoration: BoxDecoration(
            color: Styles().colors.white,
            border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
            borderRadius: BorderRadius.all(Radius.circular(4))
          ),
          //padding: const EdgeInsets.only(left: 12, right: 8),
          child: Semantics(enabled: enabled, checked: displayValue?? false, child:
            InkWell(onTap: () => enabled ? _onAttributeCheckbox(attribute) : null,
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child:
                  Padding(padding: EdgeInsets.only(left: 12, top: 16, bottom: 16), child:
                    Text(text ?? '', style: textStyle,)
                  ),
                ),
                Padding(padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16), child:
                  Styles().images.getImage(imageAsset, excludeFromSemantics: true,) ?? Container(),
                ),
              ]),
            ),
          ),
        )
      ]),
    );
  }

  void _onAttributeCheckbox(ContentAttribute attribute) {
    String? attributeId = attribute.id;
    if (attributeId != null) {
      List<ContentAttributeValue>? attributeValues = attribute.attributeValuesFromSelection(_selection);
      LinkedHashSet<dynamic> attributeRawValues = _selection[attributeId] ??= LinkedHashSet<dynamic>();
      ContentAttributeValue? selectedAttributeValue = attributeRawValues.isNotEmpty ?
        ContentAttributeValue.findInList(attributeValues, value: attributeRawValues.first) : null;
      
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

      dynamic selectedRawValue = selectedAttributeValue?.value;
      Analytics().logSelect(target: selectedAttributeValue?.selectLabel, source: attribute.title);
      setStateIfMounted(() {
        attributeRawValues.clear();
        if (selectedRawValue != null) {
          attributeRawValues.add(selectedRawValue);
        }
      });
    }
  }

  bool get _isSelectionNotEmpty => _isSelectionNotEmptyA(_selection);

  bool get _isInitialSelectionNotEmpty => _isSelectionNotEmptyA(_initialSelection);

  static bool _isSelectionNotEmptyA(Map<String, LinkedHashSet<dynamic>> selection) {
    for (LinkedHashSet<dynamic> attributeLabels in selection.values) {
      if (attributeLabels.isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  bool get _isSelectionValid => widget.contentAttributes?.isSelectionValid(_selection) ?? false;

  bool get _isOnboardingMode => (widget.applyBuilder != null) || (widget.continueBuilder != null);

  bool get _canApply => (!DeepCollectionEquality().equals(_initialSelection, _selection) || (_initialContentAttributes != widget.contentAttributes)) && (widget.filtersMode || _isSelectionValid);

  bool get _canClear =>  _isInitialSelectionNotEmpty && _isSelectionNotEmpty;

  List<Widget>? get _headerBarActions {
    List<Widget> actions = <Widget>[];
    if (!_isOnboardingMode) {
      if (_canApply) {
        actions.add(HeaderBarActionTextButton(
          title:  Localization().getStringEx('dialog.apply.title', 'Apply'),
          onTap: _onTapApply,
        ));
      }
      else if (_canClear) {
        actions.add(HeaderBarActionTextButton(
          title:  Localization().getStringEx('panel.content.attributes.button.clear.title', 'Clear'),
          onTap: _onTapClear,
        ));
      }
    }
    return actions;
  }

  Widget _buildImageBackground() => Positioned.fill(child:
    Styles().images.getImage(widget.bgImageKey, excludeFromSemantics: true, fit: BoxFit.cover) ?? Container()
  );

  Widget _buildCommands() {
    List<Widget> commands = <Widget>[];

    if ((widget.applyBuilder != null)) {
      commands.add(_buildApply());
    }

    if (widget.applyBuilder != null) {
      commands.add(_buildContinue());
    }

    return commands.isNotEmpty ?
      Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16), child:
        Column(mainAxisSize: MainAxisSize.min, children: commands,)
      ) : Container();
  }

  Widget _buildClearAttributes() {
    bool canClearAttributes = _isSelectionNotEmpty;
    return Padding(padding: EdgeInsets.only(top: 16), child:
      Row(children: <Widget>[
        Expanded(flex: 1, child: Container()),
        Expanded(flex: 2, child: RoundedButton(
          label: Localization().getStringEx('panel.content.attributes.button.clear.title', 'Clear'),
            textColor: canClearAttributes ? Styles().colors.fillColorPrimary : Styles().colors.surfaceAccent,
            borderColor: canClearAttributes ? Styles().colors.fillColorSecondary : Styles().colors.surfaceAccent,
          backgroundColor: Styles().colors.white,
          textStyle: Styles().textStyles.getTextStyle('widget.button.title.medium.fat'),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          enabled: canClearAttributes,
          onTap: _onTapClearAttributes
        )),
        Expanded(flex: 1, child: Container()),
      ],),
    );
  }

  Widget _buildFooter() {
    Widget? Function(BuildContext context)? footerBuilder = widget.footerBuilder;
    Widget? footerWidget = (footerBuilder != null) ? footerBuilder(context) : null;
    return (footerWidget != null) ? Padding(padding: EdgeInsets.only(top: 24), child: footerWidget) : Container();
  }

  Widget _buildApply() {
    bool canApply = (widget.filtersMode && _isSelectionNotEmpty) || (!widget.filtersMode && (widget.contentAttributes?.isSelectionValid(_selection) ?? false));
    return  (widget.applyBuilder != null) ? widget.applyBuilder!(context, canApply, _onApply) :
      Row(children: <Widget>[
        Expanded(flex: 1, child: Container()),
        Expanded(flex: 2, child: RoundedButton(
          label: _applyTitle,
          textColor: canApply ? Styles().colors.fillColorPrimary : Styles().colors.surfaceAccent,
          borderColor: canApply ? Styles().colors.fillColorSecondary : Styles().colors.surfaceAccent,
          backgroundColor: Styles().colors.white,
          enabled: canApply,
          onTap: _onTapApply
        )),
        Expanded(flex: 1, child: Container()),
      ],);
  }

  String get _applyTitle => _applyTitleEx();

  String _applyTitleEx({String? language}) => widget.filtersMode ?
    Localization().getStringEx('panel.content.attributes.button.filter.title', 'Filter', language: language) :
    Localization().getStringEx('panel.content.attributes.button.apply.title', 'Apply Attributes', language: language);

  void _onTapApply() {
    Analytics().logSelect(target: _applyTitleEx(language: 'en'));
    _onApply();
  }

  void _onApply() {
    Navigator.of(context).pop(ContentAttributes.selectionToAttributesSelection(_selection) ?? <String, dynamic>{});
  }

  Widget _buildContinue() => widget.continueBuilder?.call(context, _onContinue) ?? Container();

  void _onContinue() =>
    Navigator.of(context).pop((widget.selection != null) ? Map<String, dynamic>.from(widget.selection!) : <String, dynamic>{});

  void _onTapClear() {
    Analytics().logSelect(target: 'Clear');
    Navigator.of(context).pop(<String, dynamic>{});
  }

  void _onTapClearAttributes() {
    Analytics().logSelect(target: 'Clear Attributes');
    setState(() {
      _selection.clear();
    });
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
          color: Styles().colors.white,
          border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
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
                Styles().images.getImage('chevron-right', excludeFromSemantics: true) ?? SizedBox(width: 10, height: 6),
              ),
            ],),
          ),
        ])
      ),
    );
  }
}
