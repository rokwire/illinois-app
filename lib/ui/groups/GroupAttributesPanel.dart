import 'dart:collection';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/groups/GroupWidgets.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/content_attributes.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:sprintf/sprintf.dart';


class GroupAttributesPanel extends StatefulWidget {
  final bool filtersMode;
  final Map<String, dynamic>? selection;

  GroupAttributesPanel({Key? key, this.selection, this.filtersMode = false }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _GroupAttributesPanelState();
}

class _GroupAttributesPanelState extends State<GroupAttributesPanel> {

  final Map<String, GlobalKey> dropdownKeys = <String, GlobalKey>{};
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
    String headerTitle = widget.filtersMode ?
      Localization().getStringEx('panel.group.attributes.filters.header.title', 'Group Filters') : 
      Localization().getStringEx('panel.group.attributes.attributes.header.title', 'Group Attributes');
    return Scaffold(
      appBar: HeaderBar(title: headerTitle),
      backgroundColor: Styles().colors?.background,
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    List<ContentAttributesCategory>? categories = Groups().contentAttributes?.categories;
    return ((categories != null) && categories.isNotEmpty) ? Column(children: <Widget>[
      Expanded(child:
        Container(padding: EdgeInsets.only(left: 16, right: 24, top: 8), child:
          SingleChildScrollView(child:
            _buildCategoriesContent(),
          ),
        ),
      ),
      // Container(height: 1, color: Styles().colors?.surfaceAccent),
      _buildCommands(),
    ]) : Container();
  }

  Widget _buildCategoriesContent() {
    List<Widget> conentList = <Widget>[];
    ContentAttributes? contentAttributes = Groups().contentAttributes;
    List<ContentAttributesCategory>? categories = ListUtils.from<ContentAttributesCategory>(contentAttributes?.categories);
    if ((categories != null) && categories.isNotEmpty) {
      categories.sort((ContentAttributesCategory category1, ContentAttributesCategory category2) {
        String categoryTitle1 = contentAttributes?.stringValue(category1.title) ?? '';
        String categoryTitle2 = contentAttributes?.stringValue(category2.title) ?? '';
        return categoryTitle1.compareTo(categoryTitle2);
      });
      for (ContentAttributesCategory category in categories) {
        Widget? categoryWidget;
        switch (category.widget) {
          case ContentAttributesCategoryWidget.dropdown: categoryWidget = _buildCatgoryDropDown(category); break;
          case ContentAttributesCategoryWidget.checkbox: categoryWidget = _buildCategoryCheckbox(category); break;
          default: break;
        }
        if (categoryWidget != null) {
          conentList.add(categoryWidget);
        }
      }
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: conentList,); 
  }

  Widget _buildCatgoryDropDown(ContentAttributesCategory category) {
    ContentAttributes? contentAttributes = Groups().contentAttributes;

    List<ContentAttribute>? attributes = category.attributesFromSelection(_selection);
    if ((attributes != null) && (0 < attributes.length) && !widget.filtersMode && category.isSingleSelection /* && !category.isRequired*/) {
      attributes.insert(0, _ContentNullAttribute());
    }

    LinkedHashSet<String>? categoryLabels = _selection[category.id];
    ContentAttribute? selectedAttribute = ((categoryLabels != null) && categoryLabels.isNotEmpty) ?
      ((1 < categoryLabels.length) ? _ContentMultipleAttributes(categoryLabels) : category.findAttribute(label: categoryLabels.first)) : null;

    bool visible = (attributes?.isNotEmpty ?? false);
    bool enabled = (attributes?.isNotEmpty ?? false) && (contentAttributes != null) && ((selectedAttribute != null) || (contentAttributes.requirements?.canSelectMore(_selection) ?? true));
    
    return Visibility(visible: visible, child:
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        GroupSectionTitle(
          title: contentAttributes?.stringValue(category.title)?.toUpperCase(),
          description: contentAttributes?.stringValue(category.description),
          requiredMark: !widget.filtersMode && (0 < (category.minRequiredCount ?? 0)),
        ),
        GroupDropDownButton<ContentAttribute>(
          key: dropdownKeys[category.id ?? ''] ??= GlobalKey(),
          emptySelectionText: contentAttributes?.stringValue(category.emptyHint),
          buttonHint: contentAttributes?.stringValue(category.semanticsHint),
          items: attributes,
          initialSelectedValue: selectedAttribute,
          multipleSelection: widget.filtersMode || category.isMultipleSelection,
          enabled: enabled,
          itemHeight: null,
          constructTitle: (ContentAttribute attribute) => _constructAttributeTitle(category, attribute),
          isItemSelected: (ContentAttribute attribute) => _isAttributeSelected(category, attribute),
          isItemEnabled: (ContentAttribute attribute) => (attribute is! _ContentNullAttribute),
          onItemSelected: (ContentAttribute attribute) => _onAttributeSelected(category, attribute),
          onValueChanged: (ContentAttribute attribute) => _onAttributeChanged(category, attribute),
        ),
      ]),
    );
  }

  String? _constructAttributeTitle(ContentAttributesCategory category, ContentAttribute attribute) {
    if (attribute is _ContentMultipleAttributes) {
      return attribute.toString(contentAttributes: Groups().contentAttributes);
    }
    else if (attribute is _ContentNullAttribute) {
      return attribute.toString(contentAttributes: Groups().contentAttributes, category: category);
    }
    else {
      return Groups().contentAttributes?.stringValue(attribute.label);
    }
  }

  bool _isAttributeSelected(ContentAttributesCategory category, ContentAttribute attribute) {
    LinkedHashSet<String>? categoryLabels = _selection[category.id];
    if (attribute is _ContentMultipleAttributes) {
      return categoryLabels?.containsAll(attribute.labels) ?? false;
    }
    else if (attribute is _ContentNullAttribute) {
      return false;
    }
    else {
      return categoryLabels?.contains(attribute.label) ?? false;
    }
  }

  void _onAttributeSelected(ContentAttributesCategory category, ContentAttribute attribute) {
  }

  void _onAttributeChanged(ContentAttributesCategory category, ContentAttribute attribute) {
    Analytics().logSelect(target: attribute.label, source: category.title);

    String? categoryId = category.id;
    if (categoryId != null) {
      LinkedHashSet<String> categoryLabels = (_selection[categoryId] ??= LinkedHashSet<String>());
      setStateIfMounted(() {

        if (attribute is _ContentMultipleAttributes) {
          if (categoryLabels.containsAll(attribute.labels)) {
            categoryLabels.removeAll(attribute.labels);
          }
          else {
            categoryLabels.addAll(attribute.labels);
          }
        }
        else if (attribute is _ContentNullAttribute) {
          categoryLabels.clear();
        }
        else {
          String? attributeLabel = attribute.label;
          if (attributeLabel != null) {
            if (categoryLabels.contains(attributeLabel)) {
              categoryLabels.remove(attributeLabel);
            }
            else {
              categoryLabels.add(attributeLabel);
            }
          }
        }

        if (!widget.filtersMode && (category.maxRequiredCount != null)) {
          while (category.maxRequiredCount! < categoryLabels.length) {
            categoryLabels.remove(categoryLabels.first);
          }
        }

        Groups().contentAttributes?.validateSelection(_selection);
      });
    }

    if (widget.filtersMode || category.isMultipleSelection) {
      // Ugly workaround: show again dropdown popup if category supports multiple select.
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        final RenderObject? renderBox = dropdownKeys[category.id]?.currentContext?.findRenderObject();
        if (renderBox is RenderBox) {
          Offset globalOffset = renderBox.localToGlobal(Offset(renderBox.size.width / 2, renderBox.size.height / 2));
          GestureBinding.instance.handlePointerEvent(PointerDownEvent(position: globalOffset,));
          //Future.delayed(Duration(milliseconds: 100)).then((_) =>);
          GestureBinding.instance.handlePointerEvent(PointerUpEvent(position: globalOffset,));
        }
      });
    }
  }

  Widget _buildCategoryCheckbox(ContentAttributesCategory category) {
    ContentAttributes? contentAttributes = Groups().contentAttributes;

    List<ContentAttribute>? attributes = category.attributesFromSelection(_selection);

    LinkedHashSet<String>? categoryLabels = _selection[category.id];
    ContentAttribute? selectedAttribute = ((categoryLabels != null) && categoryLabels.isNotEmpty) ?
      category.findAttribute(label: categoryLabels.first) : null;

    bool visible = (attributes?.isNotEmpty ?? false);
    bool enabled = (attributes?.isNotEmpty ?? false) && (contentAttributes != null) && ((selectedAttribute != null) || (contentAttributes.requirements?.canSelectMore(_selection) ?? true));

    String imageAsset;
    if (enabled) {
      switch (selectedAttribute?.value) {
        case true:  imageAsset = "check-box-filled"; break;
        case false: imageAsset = "box-outline-gray"; break;
        default:    imageAsset = "box-inside-light-gray"; break;
      }
    }
    else {
      imageAsset = "box-inside-gray";
    }
    
    String? text = (selectedAttribute?.value != null) ? category.text : category.emptyHint;
    TextStyle? textStyle = Styles().textStyles?.getTextStyle((selectedAttribute?.value != null) ? 'widget.group.dropdown_button.value' : 'widget.group.dropdown_button.hint');

    return Visibility(visible: visible, child:
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        GroupSectionTitle(
          title: contentAttributes?.stringValue(category.title)?.toUpperCase(),
          description: contentAttributes?.stringValue(category.description),
          requiredMark: !widget.filtersMode && (0 < (category.minRequiredCount ?? 0)),
        ),
        Container (
          decoration: BoxDecoration(
            color: Styles().colors!.white,
            border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1),
            borderRadius: BorderRadius.all(Radius.circular(4))
          ),
          //padding: const EdgeInsets.only(left: 12, right: 8),
          child: InkWell(onTap: () => enabled ? _onCategoryCheckbox(category) : null,
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

  void _onCategoryCheckbox(ContentAttributesCategory category) {
    String? categoryId = category.id;
    if (categoryId != null) {
      LinkedHashSet<String> categoryLabels = _selection[categoryId] ??= LinkedHashSet<String>();
      ContentAttribute? selectedAttribute = categoryLabels.isNotEmpty ?
        category.findAttribute(label: categoryLabels.first) : null;

      switch (selectedAttribute?.value) {
        case true:  selectedAttribute = category.findAttribute(value: false); break;
        case false: selectedAttribute = null; break;
        default:    selectedAttribute = category.findAttribute(value: true); break;
      }

      String? selectedLabel = selectedAttribute?.label;
      Analytics().logSelect(target: selectedAttribute?.label, source: category.title);
      setStateIfMounted(() {
        categoryLabels.clear();
        if (selectedLabel != null) {
          categoryLabels.add(selectedLabel);
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
          label: Localization().getStringEx('panel.group.attributes.button.clear.title', 'Clear'),
          textColor: canClear ? Styles().colors?.fillColorPrimary : Styles().colors?.surfaceAccent,
          borderColor: canClear ? Styles().colors?.fillColorSecondary : Styles().colors?.surfaceAccent ,
          backgroundColor: Styles().colors?.white,
          enabled: canClear,
          onTap: _onTapClear
        )
      )]);
    }

    bool canApply = (widget.filtersMode && _isSelectionNotEmpty) || (!widget.filtersMode && (Groups().contentAttributes?.isSelectionValid(_selection) ?? false));
    String applyTitle = widget.filtersMode ? 
      Localization().getStringEx('panel.group.attributes.button.filter.title', 'Filter') :
      Localization().getStringEx('panel.group.attributes.button.apply.title', 'Apply Attributes');
    buttons.add(Expanded(child:
      RoundedButton(
        label: applyTitle,
        textColor: canApply ? Styles().colors?.fillColorPrimary : Styles().colors?.surfaceAccent,
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

class _ContentMultipleAttributes extends ContentAttribute {
  final LinkedHashSet<String> labels;
  _ContentMultipleAttributes(this.labels);

  String toString({ContentAttributes? contentAttributes}) {
    String title = '';
    for (String attributeLabel in labels) {
      String attributeName = contentAttributes?.stringValue(attributeLabel) ?? attributeLabel;
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

class _ContentNullAttribute extends ContentAttribute {
  String toString({ContentAttributes? contentAttributes, ContentAttributesCategory? category}) {
    String? categoryTitle = category?.title;
    if ((categoryTitle != null) && categoryTitle.isNotEmpty) {
      return sprintf(Localization().getStringEx('panel.group.attributes.label.no_selection.title.format', 'No %s'), [
        contentAttributes?.stringValue(categoryTitle) ?? categoryTitle
      ]);
    }
    else {
      return Localization().getStringEx('panel.group.attributes.label.no_selection.title', 'None');
    }
  }
}

