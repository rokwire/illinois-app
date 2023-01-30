import 'dart:collection';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:illinois/model/ContentAttributes.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/groups/GroupWidgets.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';


class GroupAttributesPanel extends StatefulWidget {
  final bool createMode;
  final ContentAttributes contentAttributes;
  final Map<String, dynamic>? selection;

  GroupAttributesPanel({Key? key, required this.contentAttributes, this.selection, this.createMode = false }) : super(key: key);

  bool get editMode => !createMode;

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
    return Scaffold(
      appBar: HeaderBar(title: Localization().getStringEx('panel.group.attributes.header.title', 'Group Attributes'),),
      backgroundColor: Styles().colors?.background,
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    List<ContentAttributesCategory>? categories = widget.contentAttributes.categories;
    return ((categories != null) && categories.isNotEmpty) ? Column(children: <Widget>[
      Expanded(child:
        Stack(children: [
          Container(padding: EdgeInsets.only(left: 16, right: 24, top: 8), child:
            SingleChildScrollView(child:
              _buildCategoriesContent(),
            ),
          ),
          Align(alignment: Alignment.topRight,
            child: GestureDetector(onTap: _onTapClear,
              child:Semantics(label: Localization().getStringEx('panel.group.attributes.button.clear.title', 'Clear'), button: true, excludeSemantics: true,
                child: Container(width: 36, height: 36,
                  child: Align(alignment: Alignment.center,
                    child: Text('X', style: TextStyle(fontFamily: Styles().fontFamilies!.regular, fontSize: 16, color: Styles().colors!.fillColorPrimary,),),
                  ),
                ),
              ),
            ),
          ),
        ],)
      ),
      // Container(height: 1, color: Styles().colors?.surfaceAccent),
      _buildCommands(),
    ]) : Container();
  }

  Widget _buildCategoriesContent() {
    List<ContentAttributesCategory>? categories = widget.contentAttributes.categories;
    List<Widget> conentList = <Widget>[];
    if ((categories != null) && categories.isNotEmpty) {
      for (ContentAttributesCategory category in categories) {
        conentList.add(_buildAttributesDropDown(category));
      }
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: conentList,); 
  }

  Widget _buildAttributesDropDown(ContentAttributesCategory category) {
    LinkedHashSet<String>? attributeLabels = _selection[category.title];
    ContentAttribute? selectedAttribute = ((attributeLabels != null) && attributeLabels.isNotEmpty) ?
      ((1 < attributeLabels.length) ? _ContentCategoryMultipleAttributes(attributeLabels) : category.findAttribute(label: attributeLabels.first)) : null;
    List<ContentAttribute>? attributes = category.attributesFromSelection(_selection);
    
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      GroupSectionTitle(
        title: widget.contentAttributes.stringValue(category.title)?.toUpperCase(),
        description: widget.contentAttributes.stringValue(category.description),
        requiredMark: widget.createMode && (0 < (category.minRequiredCount ?? 0)),
      ),
      GroupDropDownButton<ContentAttribute>(
        key: dropdownKeys[category.title ?? ''] ??= GlobalKey(),
        emptySelectionText: widget.contentAttributes.stringValue(category.emptyLabel),
        buttonHint: widget.contentAttributes.stringValue(category.hint),
        items: attributes,
        initialSelectedValue: selectedAttribute,
        multipleSelection: (widget.createMode && category.isMultipleSelection) || widget.editMode,
        enabled: attributes?.isNotEmpty ?? true,
        constructTitle: (ContentAttribute attribute) => _constructAttributeTitle(category, attribute),
        isItemSelected: (ContentAttribute attribute) => _isAttributeSelected(category, attribute),
        onItemSelected: (ContentAttribute attribute) => _onAttributeSelected(category, attribute),
        onValueChanged: (ContentAttribute attribute) => _onAttributeChanged(category, attribute),
      )
    ]);
  }

  String? _constructAttributeTitle(ContentAttributesCategory category, ContentAttribute attribute) {
    if (attribute is _ContentCategoryMultipleAttributes) {
      String title = '';
      for (String attributeLabel in attribute.attributeLabels) {
        String? attributeName = widget.contentAttributes.stringValue(attributeLabel);
        if ((attributeName != null) && attributeName.isNotEmpty) {
          if (title.isNotEmpty) {
            title += ', ';
          }
          title += attributeName;
        }
      }
      return title;
    }
    else {
      return widget.contentAttributes.stringValue(attribute.label);
    }
  }

  bool _isAttributeSelected(ContentAttributesCategory category, ContentAttribute attribute) {
    LinkedHashSet<String>? attributeLabels = _selection[category.title];
    return attributeLabels?.contains(attribute.label) ?? false;
  }

  void _onAttributeSelected(ContentAttributesCategory category, ContentAttribute attribute) {
  }

  void _onAttributeChanged(ContentAttributesCategory category, ContentAttribute attribute) {
    String? categoryTitle = category.title;
    String? attributeLabel = attribute.label;
    if ((categoryTitle != null) && (attributeLabel != null)) {
      LinkedHashSet<String> attributeLabels = (_selection[categoryTitle] ??= LinkedHashSet<String>());
      setStateIfMounted(() {
        
        if (attributeLabels.contains(attributeLabel)) {
          attributeLabels.remove(attributeLabel);
        }
        else {
          attributeLabels.add(attributeLabel);
        }
        
        if (widget.createMode && (category.maxRequiredCount != null)) {
          while (category.maxRequiredCount! < attributeLabels.length) {
            attributeLabels.remove(attributeLabels.first);
          }
        }

        widget.contentAttributes.validateSelection(_selection);
      });
    }

    if ((widget.createMode && category.isMultipleSelection) || widget.editMode) {
      // Ugly workaround: show again dropdown popup if category supports multiple select.
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        final RenderObject? renderBox = dropdownKeys[category.title]?.currentContext?.findRenderObject();
        if (renderBox is RenderBox) {
          Offset globalOffset = renderBox.localToGlobal(Offset(renderBox.size.width / 2, renderBox.size.height / 2));
          GestureBinding.instance.handlePointerEvent(PointerDownEvent(position: globalOffset,));
          //Future.delayed(Duration(milliseconds: 100)).then((_) =>);
          GestureBinding.instance.handlePointerEvent(PointerUpEvent(position: globalOffset,));
        }
      });
    }
  }

  Widget _buildCommands() {
    bool canApply = (widget.createMode && (widget.contentAttributes.unsatisfiedCategoryFromSelection(_selection) == null)) || widget.editMode;
    return SafeArea(child:
      Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16), child:
        Row(children: <Widget>[
          Expanded(child:
            RoundedButton(
              label: Localization().getStringEx('panel.group.attributes.button.apply.title', 'Apply'),
              textColor: canApply ? Styles().colors?.fillColorPrimary : Styles().colors?.surfaceAccent,
              borderColor: canApply ? Styles().colors?.fillColorSecondary : Styles().colors?.surfaceAccent ,
              backgroundColor: Styles().colors?.white,
              enabled: canApply,
              onTap: _onTapApply
            )
          )
        ],)
      )
    );
  }

  void _onTapApply() {
    Analytics().logSelect(target: 'Apply');
    Navigator.of(context).pop(ContentAttributes.selectionToAttributesSelection(_selection) ?? <String, dynamic>{});
  }

  void _onTapClear() {
    Analytics().logSelect(target: 'Clear');
    setStateIfMounted(() {
      _selection = <String, LinkedHashSet<String>>{};
    });
  }
}

class _ContentCategoryMultipleAttributes extends ContentAttribute {
  final LinkedHashSet<String> attributeLabels;
  _ContentCategoryMultipleAttributes(this.attributeLabels);
}

