
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/content_attributes.dart';
import 'package:rokwire_plugin/service/events2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class Event2FiltersPanel extends StatefulWidget {
  final Map<String, dynamic> selection;
  Event2FiltersPanel(this.selection, {Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _Event2FiltersPanelState();
}

class _Event2FiltersPanelState extends State<Event2FiltersPanel> {

  ContentAttributes? _attributes;
  String? _expandedAttributeId;
  late Map<String, LinkedHashSet<dynamic>> _selection;

  @override
  void initState() {
    _attributes = Events2().contentAttributes;
    _selection = ContentAttributes.selectionFromAttributesSelection(widget.selection) ?? <String, LinkedHashSet<dynamic>>{};
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(title: Localization().getStringEx("panel.event2.filters.header.title", "Event Filters"),),
      body: _buildPanelContent(),
      backgroundColor: Styles().colors!.background,
    );
  }

  Widget _buildPanelContent() {
    return ((_attributes != null) && _attributes!.isNotEmpty) ? Column(children: <Widget>[
      Expanded(child:
        Container(padding: EdgeInsets.only(left: 16, right: 24, top: 8), child:
          SingleChildScrollView(child:
            _buildAttributesContent(),
          ),
        ),
      ),
      // Container(height: 1, color: Styles().colors?.surfaceAccent),
    ]) : Container();
  }

  Widget _buildAttributesContent() {
    List<Widget> conentList = <Widget>[];

    conentList.add(Padding(padding: EdgeInsets.only(top: 16, bottom: 8), child:
      Text('Choose one or more attributes to filter events', style: Styles().textStyles?.getTextStyle("widget.description.regular")),
    ));

    List<ContentAttribute>? attributes = ListUtils.from<ContentAttribute>(_attributes?.attributes);
    if ((attributes != null) && attributes.isNotEmpty) {
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
    return Padding(padding: EdgeInsets.only(bottom: 8), child:
      _Event2AttributeButton(attribute,
        selection: _selection[attribute.id],
        expanded: (_expandedAttributeId == attribute.id),
        onTapAttribute: () => _onAttribute(attribute),
        onTapAttributeValue: (ContentAttributeValue value) => _onAttributeValue(attribute, value),
      )
    ) ;
  }

  void _onAttribute(ContentAttribute attribute) {
    Analytics().logSelect(target: attribute.title);
    setStateIfMounted(() {
      _expandedAttributeId = (_expandedAttributeId != attribute.id) ? attribute.id : null;
    });
  }

  void _onAttributeValue(ContentAttribute attribute, ContentAttributeValue value) {
    Analytics().logSelect(target: value.selectLabel, source: attribute.title);    

    String? attributeId = attribute.id;
    String? attributeRawValue = value.value;
    if ((attributeId != null) && (attributeRawValue != null)) {
      setStateIfMounted(() {
        LinkedHashSet<dynamic> selection = (_selection[attributeId] ??= LinkedHashSet<dynamic>());
        if (selection.contains(attributeRawValue)) {
          selection.remove(attributeRawValue);
        }
        else {
          selection.add(attributeRawValue);
        }
      });
    }
  }

  Widget _buildAttributeCheckbox(ContentAttribute attribute) {
    return Container();
  }
}

class _Event2AttributeButton extends StatelessWidget {
  final ContentAttribute attribute;
  final LinkedHashSet<dynamic>? selection;
  final bool expanded;
  final Function() onTapAttribute;
  final Function(ContentAttributeValue value) onTapAttributeValue;

  _Event2AttributeButton(this.attribute, { Key? key,
    this.selection, this.expanded = false,
    required this.onTapAttribute, required this.onTapAttributeValue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
      InkWell(onTap: onTapAttribute, child:
        Container (decoration: headingDecoration, child:
            Row(children: [
              Expanded(child:
                Padding(padding: EdgeInsets.only(left: 12, top: 18, bottom: 18), child:
                  Text(attribute.title?.toUpperCase() ?? '', style: headingTextStyle),
                ),
              ),
              Padding(padding: EdgeInsets.all(12), child:
                headingRightIcon,
              ),
            ],),
        ),
      ),
      ...?(expanded ? buildValues() : null),
    ]);
  }

  Color get borderColor => Styles().colors?.disabledTextColor ?? Color(0xFF717273);

  Decoration get headingDecoration => expanded ?
    BoxDecoration(
      color: Styles().colors?.fillColorPrimary,
      border: Border.all(color: borderColor, width: 1),
      borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
    ) :
    BoxDecoration(
      color: Styles().colors?.white,
      border: Border.all(color: borderColor, width: 1),
      borderRadius: BorderRadius.circular(8),
    );

  TextStyle? get headingTextStyle => expanded ?
    Styles().textStyles?.getTextStyle('widget.heading.regular.fat') :
    Styles().textStyles?.getTextStyle('widget.button.title.medium.fat');

  Widget? get headingRightIcon => expanded ?
    Styles().images?.getImage('chevron-up', color: Styles().colors?.white, excludeFromSemantics: true) :
    Styles().images?.getImage('chevron-down', color: Styles().colors?.fillColorSecondary, excludeFromSemantics: true);

  List<Widget> buildValues() {
    List<Widget> widgets = <Widget>[];
    if (attribute.values != null) {
      for (ContentAttributeValue value in attribute.values!) {
        widgets.add(_buildAttributeValueWidget(value, widgets.length, attribute.values!.length));
      }
    }
    return widgets;
  }

  Widget _buildAttributeValueWidget(ContentAttributeValue attributeValue, int index, int count) {
    bool isSelected = selection?.contains(attributeValue.value) ?? false;
    String? imageAsset = StringUtils.isNotEmpty(attributeValue.value) ?
      (isSelected ? "check-box-filled" : "box-outline-gray") : null;
    //(isSelected ? "check-circle-filled" : "circle-outline-gray") : null;
    String? title =  attribute.displayString(attributeValue.selectedLabel);
    TextStyle? textStyle = Styles().textStyles?.getTextStyle(isSelected ? "widget.button.title.medium.fat" : "widget.button.title.medium");
    Decoration decoration =
      ((index + 2) < count) ? BoxDecoration(
        color: Styles().colors?.white,
        border: Border(
          left: BorderSide(color: borderColor, width: 1),
          right: BorderSide(color: borderColor, width: 1),
          bottom: BorderSide(color: borderColor, width: 1),
        ),
      ) :
      ((index + 1) < count) ? BoxDecoration(
        color: Styles().colors?.white,
        border: Border(
          left: BorderSide(color: borderColor, width: 1),
          right: BorderSide(color: borderColor, width: 1),
        ),
      ) : BoxDecoration(
        color: Styles().colors?.white,
        border: Border.all(color: borderColor, width: 1),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(8),),
      );

    return InkWell(onTap: () => onTapAttributeValue(attributeValue), child:
      Container(decoration: decoration, child:
        Row(children: <Widget>[
          Expanded(child:
            Padding(padding: EdgeInsets.only(left: 12, top: 18, bottom: 18), child:
              Text(title ?? attributeValue.selectLabel ?? '', overflow: TextOverflow.ellipsis, style: textStyle,),
            )
          ),
          
          Padding(padding: EdgeInsets.symmetric(horizontal: 12), child:
            Styles().images?.getImage(imageAsset, excludeFromSemantics: true) ?? Container()
          )
        ]),
      )
    );
  }
}