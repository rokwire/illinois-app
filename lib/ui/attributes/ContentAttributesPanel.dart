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
    List<ContentAttributesCategory>? categories = widget.contentAttributes?.categories;
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

    if (StringUtils.isNotEmpty(widget.description)) {
      conentList.add(Padding(padding: EdgeInsets.only(top: 16, bottom: 8), child:
        Text(widget.description ?? '', style:
          TextStyle(fontFamily: Styles().fontFamilies!.regular, fontSize: 16, color: Styles().colors!.fillColorPrimary, )
        ),
      ));
    }

    List<ContentAttributesCategory>? categories = ListUtils.from<ContentAttributesCategory>(widget.contentAttributes?.categories);
    if ((categories != null) && categories.isNotEmpty) {
      categories.sort((ContentAttributesCategory category1, ContentAttributesCategory category2) {
        String categoryTitle1 = widget.contentAttributes?.stringValue(category1.title) ?? '';
        String categoryTitle2 = widget.contentAttributes?.stringValue(category2.title) ?? '';
        return categoryTitle1.compareTo(categoryTitle2);
      });
      for (ContentAttributesCategory category in categories) {
        Widget? categoryWidget;
        switch (category.widget) {
          case ContentAttributesCategoryWidget.dropdown: categoryWidget = _buildCategoryDropDown(category); break;
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

  Widget _buildCategoryDropDown(ContentAttributesCategory category) {
    LinkedHashSet<String>? categoryLabels = _selection[category.id];
    bool hasSelection = ((categoryLabels != null) && categoryLabels.isNotEmpty);

    List<ContentAttribute>? attributes = category.attributesFromSelection(_selection);
    bool visible = (attributes?.isNotEmpty ?? false);
    bool enabled = (attributes?.isNotEmpty ?? false) && (hasSelection || (widget.contentAttributes?.requirements?.canSelectMoreCategories(_selection) ?? true));

    String? title = _constructAttributeDropdownTitle(category, categoryLabels);
    String? hint = widget.contentAttributes?.stringValue(widget.filtersMode ? category.semanticsFilterHint : category.semanticsHint);
    TextStyle? textStyle = Styles().textStyles?.getTextStyle(hasSelection ? 'widget.group.dropdown_button.value' : 'widget.group.dropdown_button.hint');
    void Function()? onTap = enabled ? () => _onCategoryDropdownTap(category: category, attributes: attributes) : null;
    
    return Visibility(visible: visible, child:
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        GroupSectionTitle(
          title: widget.contentAttributes?.stringValue(category.title)?.toUpperCase(),
          description: widget.contentAttributes?.stringValue(category.description),
          requiredMark: !widget.filtersMode && category.isRequired,
        ),
        _CategoryRibbonButton(
          title: title, hint: hint, textStyle: textStyle, onTap: onTap,
        ),
      ]),
    );
  }

  String? _constructAttributeDropdownTitle(ContentAttributesCategory category, LinkedHashSet<String>? categoryLabels) {
    if ((categoryLabels == null) || categoryLabels.isEmpty) {
      return widget.contentAttributes?.stringValue(widget.filtersMode ? category.emptyFilterHint : category.emptyHint);
    }
    else if (categoryLabels.length == 1) {
      return widget.contentAttributes?.stringValue(categoryLabels.first);
    }
    else {
      String title = '';
      for (String attributeLabel in categoryLabels) {
        String attributeName = widget.contentAttributes?.stringValue(attributeLabel) ?? attributeLabel;
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

  void _onCategoryDropdownTap({ContentAttributesCategory? category, List<ContentAttribute>? attributes}) {
    Analytics().logSelect(target: category?.title);
    String? categoryId = category?.id;

    Navigator.push<LinkedHashSet<String>?>(context, CupertinoPageRoute(builder: (context) => ContentAttributesCategoryPanel(
      contentAttributes: widget.contentAttributes,
      category: category,
      attributes: attributes,
      selection: _selection[categoryId],
      multipleSelection: widget.filtersMode || (category?.isMultipleSelection ?? false),
      filtersMode: widget.filtersMode,
    ),)).then(((LinkedHashSet<String>? selection) {
      if ((selection != null) && (categoryId != null)) {
        setStateIfMounted(() {
          _selection[categoryId] = selection;
          widget.contentAttributes?.validateSelection(_selection);
        });
      }
    }));
  }

  Widget _buildCategoryCheckbox(ContentAttributesCategory category) {

    List<ContentAttribute>? attributes = category.attributesFromSelection(_selection);

    LinkedHashSet<String>? categoryLabels = _selection[category.id];
    ContentAttribute? selectedAttribute = ((categoryLabels != null) && categoryLabels.isNotEmpty) ?
      category.findAttribute(label: categoryLabels.first) : null;

    bool visible = (attributes?.isNotEmpty ?? false);
    bool enabled = (attributes?.isNotEmpty ?? false) && ((selectedAttribute != null) || (widget.contentAttributes?.requirements?.canSelectMoreCategories(_selection) ?? true));

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
    
    String? text = (selectedAttribute?.value != null) ? category.text : (widget.filtersMode ? category.emptyFilterHint : category.emptyHint);
    TextStyle? textStyle = Styles().textStyles?.getTextStyle((selectedAttribute?.value != null) ? 'widget.group.dropdown_button.value' : 'widget.group.dropdown_button.hint');

    return Visibility(visible: visible, child:
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        GroupSectionTitle(
          title: widget.contentAttributes?.stringValue(category.title)?.toUpperCase(),
          description: widget.contentAttributes?.stringValue(category.description),
          requiredMark: !widget.filtersMode && category.isRequired,
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
          label: Localization().getStringEx('panel.content.attributes.button.clear.title', 'Clear'),
          textColor: canClear ? Styles().colors?.fillColorPrimary : Styles().colors?.surfaceAccent,
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

class _CategoryRibbonButton extends StatelessWidget {
  final String? title;
  final String? hint;
  final TextStyle? textStyle;
  final Function()? onTap;

  _CategoryRibbonButton({Key? key, this.title, this.hint, this.textStyle, this.onTap}) : super(key: key);

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