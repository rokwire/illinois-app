import 'package:flutter/material.dart';
import 'package:illinois/model/Analytics.dart';
import 'package:illinois/model/CustomCourses.dart';
import 'package:illinois/ui/academics/courses/EssentialSkillsCoachWidgets.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';


class ResourcesPanel extends StatefulWidget with AnalyticsInfo {
  final List<Content> contentItems;
  final ReferenceType? initialReferenceType;
  final Color? color;
  final int unitNumber;
  final String unitName;

  final Widget? moduleIcon;
  final String moduleName;

  final AnalyticsFeature? analyticsFeature; //This overrides AnalyticsInfo.analyticsFeature getter

  const ResourcesPanel({required this.contentItems, this.initialReferenceType, required this.color, required this.unitNumber, required this.unitName, this.moduleIcon, required this.moduleName, this.analyticsFeature});

  @override
  State<ResourcesPanel> createState() => _ResourcesPanelState();
}

class _ResourcesPanelState extends State<ResourcesPanel> {
  Color? _color;
  late List<Content> _contentItems;
  Set<ReferenceType> _referenceTypes = {};
  ReferenceType? _selectedResourceType;

  @override
  void initState() {
    _color = widget.color;
    _contentItems = widget.contentItems;
    _selectedResourceType = widget.initialReferenceType;
    for (Content item in _contentItems) {
      if (item.reference?.type != null) {
        _referenceTypes.add(item.reference!.type!);
      }
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(title: Localization().getStringEx('panel.essential_skills_coach.resources.header.title', 'Unit Resources'),
        textStyle: Styles().textStyles.getTextStyle('header_bar'),),
      body: Column(children: [
        EssentialSkillsCoachModuleHeader(icon: widget.moduleIcon, moduleName: widget.moduleName, backgroundColor: _color,),
        _buildResourcesHeaderWidget(),
        _buildResourceTypeDropdown(),
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8.0),
            child: _buildResources()
          ),
        ),
      ],),
      backgroundColor: Styles().colors.background,
    );
  }

  Widget _buildResources(){
    List<Content> filteredContentItems = _filterContentItems();
    return ListView.builder(
        shrinkWrap: true,
        itemCount: filteredContentItems.length,
        itemBuilder: (BuildContext context, int index) {
          Content contentItem = filteredContentItems[index];
          Reference? reference = contentItem.reference;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Material(
              color: Styles().colors.surface,
              borderRadius: BorderRadius.all(Radius.circular(8.0)),
              clipBehavior: Clip.hardEdge,
              elevation: 1.0,
              child: InkWell(
                onTap: (){
                  if (reference?.type == ReferenceType.video) {
                    EssentialSkillsCoachWidgets.openVideoContent(context, reference?.name, reference?.referenceKey);
                  } else if (reference?.type == ReferenceType.uri) {
                    Uri? uri = Uri.tryParse(reference?.referenceKey ?? "");
                    if (uri != null) {
                      EssentialSkillsCoachWidgets.openUrlContent(uri);
                    }
                  } else if (reference?.type != ReferenceType.text) {
                    EssentialSkillsCoachWidgets.openPdfContent(context, reference?.name, reference?.referenceKey);
                  }
                },
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  leading: Styles().images.getImage("${reference?.stringFromType()}-icon"),
                  title: Text(contentItem.name ?? "", style: Styles().textStyles.getTextStyle("widget.message.large.fat"),),
                  subtitle: Text(contentItem.details ?? ""),
                  trailing: reference?.type != ReferenceType.text ? Icon(
                    Icons.chevron_right_rounded,
                    size: 25.0,
                  ) : null,
                ),
              ),
            ),
          );
        }
    );
  }

  Widget _buildResourceTypeDropdown(){
    return Padding(
      padding: EdgeInsets.only(left: 16.0, right: 16.0, top: 24.0),
      child: EssentialSkillsCoachDropdown(
          value: _selectedResourceType,
          items: _buildDropdownItems(),
          onChanged: (ReferenceType? selected) {
            setState(() {
              _selectedResourceType = selected;
            });
          }
      ),
    );
  }

  Widget _buildResourcesHeaderWidget(){
    return Container(
      color: Styles().colors.fillColorPrimary,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Unit ${widget.unitNumber}', style: Styles().textStyles.getTextStyle("widget.title.light.huge.fat")),
                  Text(widget.unitName, style: Styles().textStyles.getTextStyle("widget.title.light.regular.fat"))
                ],
              ),
            ),
            Flexible(
              flex: 1,
              child: Container(
                  decoration: BoxDecoration(
                    color: Styles().colors.surface,
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Styles().images.getImage('closed-book', size: 40.0),
                  )
              ),
            )
          ],
        ),
      ),
    );
  }

  List<DropdownMenuItem<ReferenceType>> _buildDropdownItems() {
    List<DropdownMenuItem<ReferenceType>> dropDownItems = [
      DropdownMenuItem(value: null, child: Text(Localization().getStringEx('panel.essential_skills_coach.resources.select.all.label', "View All Resources"), style: Styles().textStyles.getTextStyle("widget.detail.large")))
    ];

    for (ReferenceType type in _referenceTypes) {
      String itemText = '';
      switch (type) {
        case ReferenceType.pdf:
          itemText = Localization().getStringEx('panel.essential_skills_coach.resources.select.pdf.label', 'View All PDFs');
          break;
        case ReferenceType.video:
          itemText = Localization().getStringEx('panel.essential_skills_coach.resources.select.video.label', 'View All Videos');
          break;
        case ReferenceType.uri:
          itemText = Localization().getStringEx('panel.essential_skills_coach.resources.select.uri.label', 'View All External Links');
          break;
        case ReferenceType.text:
          itemText = Localization().getStringEx('panel.essential_skills_coach.resources.select.text.label', 'View All Terms');
          break;
        case ReferenceType.powerpoint:
          itemText = Localization().getStringEx('panel.essential_skills_coach.resources.select.powerpoint.label', 'View All Powerpoints');
          break;
        default:
          continue;
      }

      dropDownItems.add(DropdownMenuItem(value: type, child: Text(
        itemText,
        style: Styles().textStyles.getTextStyle("widget.detail.large")
      )));
    }
    return dropDownItems;
  }

  List<Content> _filterContentItems() {
    if (_selectedResourceType != null) {
      List<Content> filteredContentItems =  _contentItems.where((i) => i.reference?.type == _selectedResourceType).toList();
      return filteredContentItems;
    }
    return _contentItems;
  }
}
