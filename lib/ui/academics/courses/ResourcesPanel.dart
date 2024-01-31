import 'package:flutter/material.dart';
import 'package:illinois/model/CustomCourses.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';

class ResourcesPanel extends StatefulWidget {
  final List<Content>? contentItems;
  final Color? color;
  final Color? colorAccent;
  final int unitNumber;
  final String unitName;
  const ResourcesPanel({required this.color, required this.colorAccent, required this.unitNumber, required this.contentItems, required this.unitName});

  @override
  State<ResourcesPanel> createState() => _ResourcesPanelState();
}

class _ResourcesPanelState extends State<ResourcesPanel> implements NotificationsListener {
  late Color? _color;
  late Color? _colorAccent;
  late int _unitNumber;
  late List<Content> _contentItems;
  late String _unitName;

  String? _selectedResourceType = "View All Resources";
  final List<String> _resourceTypes = ["View All Resources", "View All PDFs",
    "View All Videos", "View All External Links", "View All Information", "View All Powerpoints"];

  @override
  void initState() {
    _color = widget.color!;
    _colorAccent = widget.colorAccent!;
    _unitNumber = widget.unitNumber;
    _contentItems = widget.contentItems!;
    _unitName = widget.unitName;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(title: Localization().getStringEx('panel.essential_skills_coach.resources.header.title', 'Resources'),
        textStyle: Styles().textStyles.getTextStyle('header_bar'),),
      body: SingleChildScrollView(
        child: _buildUnitResourcesWidgets(),
      ),
      backgroundColor: _color,
    );
  }

  Widget _buildUnitResourcesWidgets(){
    List<Widget> widgets = <Widget>[];

    widgets.add(_buildResourcesHeaderWidget());
    widgets.add(_buildResourceTypeDropdown());
    widgets.add(_buildResourcesList());
    return  Column(
        children: widgets,
    );
  }

  Widget _buildResourcesList(){
    return Padding(
      padding: EdgeInsets.all(16),
      child: SingleChildScrollView(
          child: _buildResources()
      )
    );
  }

  Widget _buildResources(){
    List<Content> filteredContentItems = <Content>[];

    switch(_selectedResourceType){
      case "View All Resources":
        filteredContentItems = _contentItems;
        break;
      case "View All PDFs":
        filteredContentItems = _filterContentItems("pdf");
        break;
      case "View All Videos":
        filteredContentItems = _filterContentItems("video");
        break;
      case "View All External Links":
        filteredContentItems = _filterContentItems("link");
        break;
      case "View All Information":
        filteredContentItems = _filterContentItems("text");
        break;
      case "View All Power Points":
        filteredContentItems = _filterContentItems("powerpoint");
        break;
    }
    return ExpansionPanelList(
      expansionCallback: (int index, bool isExpanded) {
        // setState(() {
        //   filteredContentItems[index].isExpanded = !filteredContentItems[index].isExpanded;
        // });
      },
      children: filteredContentItems.map<ExpansionPanel>((Content item) {
        return ExpansionPanel(

          headerBuilder: (BuildContext context, bool isExpanded) {
            return ListTile(
                leading: Styles().images.getImage((item.reference?.stringFromType() ?? "item") + "-icon") ?? Container(),
                title: Text(item.name ?? ""),
            );
          },
          body: ListTile(
              title: Text(item.details ?? ""),
        ),
            // isExpanded: item.isExpanded
        );
      }).toList(),
    );
  }

  Widget _buildResourceTypeDropdown(){
    return Padding(padding: EdgeInsets.only(left: 16, right: 16,bottom: 16, top: 16),
        child:  Center(
          child: DropdownButton(
              value: _selectedResourceType,
              iconDisabledColor: Colors.white,
              iconEnabledColor: Colors.white,
              focusColor: Colors.white,
              dropdownColor: _color,
              isExpanded: true,
              items: DropdownBuilder.getItems(_resourceTypes, style: Styles().textStyles.getTextStyle("widget.title.light.large.fat")),
              onChanged: (String? selected) {
                setState(() {
                  _selectedResourceType = selected;
                });
              }
          ),
        )
    );
  }

  Widget _buildResourcesHeaderWidget(){
    return Container(
      color: _colorAccent,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Unit ' + (_unitNumber + 1).toString(), style: Styles().textStyles.getTextStyle("widget.title.light.huge.fat")),
                Container(
                  width: 200,
                  child: Text(_unitName, style: Styles().textStyles.getTextStyle("widget.title.light.regular.fat")),
                )
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(24),
            child: Icon(
              Icons.menu_book_rounded,
              color: Colors.white,
              size: 50.0,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void onNotification(String name, param) {
    // TODO: implement onNotification
  }

  List<Content> _filterContentItems(String filter){
    List<Content> filteredContentItems =  _contentItems.where((i) => i.reference?.type == filter).toList();
    return filteredContentItems;
  }

}

class DropdownBuilder {
  static List<DropdownMenuItem<T>> getItems<T>(List<T> options, {String? nullOption, TextStyle? style}) {
    List<DropdownMenuItem<T>> dropDownItems = <DropdownMenuItem<T>>[];
    if (nullOption != null) {
      dropDownItems.add(DropdownMenuItem(value: null, child: Text(nullOption, style: style ?? Styles().textStyles.getTextStyle("widget.detail.regular"))));
    }
    for (T option in options) {
      dropDownItems.add(DropdownMenuItem(value: option, child: Text(option.toString(), style: style ?? Styles().textStyles.getTextStyle("widget.detail.regular"))));
    }
    return dropDownItems;
  }
}