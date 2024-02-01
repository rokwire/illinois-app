import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:illinois/model/CustomCourses.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:http/http.dart' as http;
import 'package:rokwire_plugin/service/content.dart' as con;
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';


import 'PDFScreen.dart';
import 'VideoPlayer.dart';

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
  String urlPDFPath = "";
  bool _isExpanded = false;
  late VideoPlayerController _controller;
  late Future<void> _initializeVideoPlayerFuture;

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

    // _loadDataContentItem( key: 'resource_text');

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

    return Column(
      children: [
        Container(
          width: double.infinity,
          child: ListView.builder(
              padding: const EdgeInsets.all(4),
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: filteredContentItems.length,
              itemBuilder: (BuildContext context, int index) {


                if(filteredContentItems[index].reference?.type == "text"){
                  return Center(
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      child: ExpansionTile(
                        leading: Styles().images.getImage((filteredContentItems[index].reference?.type ?? "item") + "-icon") ?? Container(),
                        title: Text(filteredContentItems[index].name ?? "", style: Styles().textStyles.getTextStyle("widget.message.large.fat"),),
                        subtitle: Text(filteredContentItems[index].details ?? ""),
                        children: [
                         Padding(
                           padding: const EdgeInsets.all(8.0),
                           child: Center(
                             child: Text("Soften", style: Styles().textStyles.getTextStyle("widget.message.large"),),
                           ),
                         ),
                          Padding(
                            padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
                            child: Center(
                              child: Text("(smile, open posture, forward lean, touch, eye contact, nod)", style: Styles().textStyles.getTextStyle("widget.message.regular"),),
                            ),
                          ),
                        ],
                        onExpansionChanged: (bool expanded){
                          setState(() {
                            _isExpanded = expanded;
                          });
                        },
                      ),
                    ),
                  );
                }else{
                  return Center(
                    child: Card(
                      clipBehavior: Clip.hardEdge,
                      child: InkWell(
                        onTap: (){
                          if(filteredContentItems[index].reference?.type == "video"){
                            con.Content.internal().getFileContentItem(filteredContentItems[index].reference?.referenceKey ?? "", "test" ).then((
                                value) => {
                              setState(() {
                                if (value != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          VideoPlayerScreen(file: value, color: _color,),
                                    ),
                                  );
                                }
                              })
                            });
                          }else if(filteredContentItems[index].reference?.type == "link"){
                            Uri uri = Uri.parse(filteredContentItems[index].reference?.referenceKey ?? " ");
                            _launchUrl(uri);
                          } else{
                            con.Content.internal().getFileContentItem(filteredContentItems[index].reference?.referenceKey ?? "", "test" ).then((
                                value) => {
                              setState(() {
                                if (value != null) {
                                  urlPDFPath = value.path;
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          PDFScreen(path: urlPDFPath, color: _color,),
                                    ),
                                  );
                                }
                              })
                            });
                          }
                        },
                        child: ListTile(
                          leading: Styles().images.getImage((filteredContentItems[index].reference?.type ?? "item") + "-icon") ?? Container(),
                          title: Text(filteredContentItems[index].name ?? "", style: Styles().textStyles.getTextStyle("widget.message.large.fat"),),
                          subtitle: Text(filteredContentItems[index].details ?? ""),
                          trailing: Icon(
                            Icons.chevron_right_rounded,
                            size: 25.0,
                          ),
                        ),
                      ),
                    ),
                  );
                }
              }
          ),
        ),
      ],
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

  Future<void> _launchUrl(Uri url) async {
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  void onNotification(String name, param) {
    // TODO: implement onNotification
  }

  List<Content> _filterContentItems(String filter){
    List<Content> filteredContentItems =  _contentItems.where((i) => i.reference?.type == filter).toList();
    return filteredContentItems;
  }

  // //TODO fix data parsing
  // void _loadDataContentItem({required String key}) async{
  //   Map<String, dynamic>? response = await con.Content.internal().getDataContentItem(key);
  //
  // }

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