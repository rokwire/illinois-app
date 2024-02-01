import 'dart:io';

import 'package:flutter/material.dart';
import 'package:illinois/model/CustomCourses.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/ui/academics/courses/PDFScreen.dart';
import 'package:illinois/ui/academics/courses/VideoPlayer.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/service/content.dart' as con;
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';


class ResourcesPanel extends StatefulWidget {
  final List<Content> contentItems;
  final Color? color;
  final Color? colorAccent;
  final int unitNumber;
  final String unitName;
  const ResourcesPanel({required this.color, required this.colorAccent, required this.unitNumber, required this.contentItems, required this.unitName});

  @override
  State<ResourcesPanel> createState() => _ResourcesPanelState();
}

class _ResourcesPanelState extends State<ResourcesPanel> implements NotificationsListener {
  Color? _color;
  Color? _colorAccent;
  late List<Content> _contentItems;
  Set<String> _loadingReferenceKeys = {};
  Map<String, File?> _fileCache = {};
  ReferenceType? _selectedResourceType = null;

  @override
  void initState() {
    _color = widget.color;
    _colorAccent = widget.colorAccent;
    _contentItems = widget.contentItems;
    super.initState();

    // _loadDataContentItem( key: 'resource_text');
    //TODO: load and cache all content files on init?
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(title: Localization().getStringEx('panel.essential_skills_coach.resources.header.title', 'Resources'),
        textStyle: Styles().textStyles.getTextStyle('header_bar'),),
      body: SingleChildScrollView(
        child: Column(children: [
          _buildResourcesHeaderWidget(),
          _buildResourceTypeDropdown(),
          Padding(
            padding: EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: _buildResources()
            )
          ),
        ],),
      ),
      backgroundColor: _color,
    );
  }

  Widget _buildResources(){
    List<Content> filteredContentItems = _filterContentItems();
    return ListView.builder(
        padding: const EdgeInsets.all(4),
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: filteredContentItems.length,
        itemBuilder: (BuildContext context, int index) {
          Content contentItem = filteredContentItems[index];
          Reference? reference = contentItem.reference;
          if(reference?.type == ReferenceType.text){
            return Center(
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: ExpansionTile(
                  leading: Styles().images.getImage("${reference?.stringFromType()}-icon") ?? Container(),
                  title: Text(contentItem.name ?? "", style: Styles().textStyles.getTextStyle("widget.message.large.fat"),),
                  subtitle: Text(contentItem.details ?? ""),
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
                ),
              ),
            );
          }else{
            return Center(
              child: Card(
                clipBehavior: Clip.hardEdge,
                child: InkWell(
                  onTap: (){
                    if(reference?.type == ReferenceType.video){
                      if (_fileCache[reference?.referenceKey] != null) {
                        _openVideo(context, reference?.name, _fileCache[reference?.referenceKey]!);
                      } else {
                        _setLoadingReferenceKey(reference?.referenceKey, true);
                        _loadContentForKey(reference?.referenceKey, onResult: (value) {
                          _openVideo(context, reference?.name, value);
                        });
                      }
                    } else if(reference?.type == ReferenceType.uri){
                      Uri uri = Uri.parse(reference?.referenceKey ?? "");
                      _launchUrl(uri);
                    } else{
                      _setLoadingReferenceKey(reference?.referenceKey, true);
                      if (_fileCache[reference?.referenceKey] != null) {
                        _openPdf(context, reference?.name, _fileCache[reference?.referenceKey]!.path);
                      } else {
                        _loadContentForKey(reference?.referenceKey, onResult: (value) {
                          _openPdf(context, reference?.name, value.path);
                        });
                      }
                    }
                  },
                  child: ListTile(
                    leading: Styles().images.getImage("${reference?.stringFromType()}-icon") ?? Container(),
                    title: Text(contentItem.name ?? "", style: Styles().textStyles.getTextStyle("widget.message.large.fat"),),
                    subtitle: Text(contentItem.details ?? ""),
                    trailing: _loadingReferenceKeys.contains(reference?.referenceKey) ? CircularProgressIndicator() : Icon(
                      Icons.chevron_right_rounded,
                      size: 25.0,
                    ),
                  ),
                ),
              ),
            );
          }
        }
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
              items: _buildDropdownItems(),
              onChanged: (ReferenceType? selected) {
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
                Text('Unit ${widget.unitNumber}', style: Styles().textStyles.getTextStyle("widget.title.light.huge.fat")),
                Container(
                  width: 200,
                  child: Text(widget.unitName, style: Styles().textStyles.getTextStyle("widget.title.light.regular.fat")),
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

  List<DropdownMenuItem<ReferenceType>> _buildDropdownItems() {
    List<DropdownMenuItem<ReferenceType>> dropDownItems = [
      DropdownMenuItem(value: null, child: Text(Localization().getStringEx('panel.essential_skills_coach.resources.select.all.label', "View All Resources"), style: Styles().textStyles.getTextStyle("widget.title.light.large.fat")))
    ];

    for (ReferenceType type in ReferenceType.values) {
      switch (type) {
        case ReferenceType.pdf:
          dropDownItems.add(DropdownMenuItem(value: type, child: Text(
            Localization().getStringEx('panel.essential_skills_coach.resources.select.pdf.label', 'View All PDFs'),
            style: Styles().textStyles.getTextStyle("widget.title.light.large.fat")
          )));
          break;
        case ReferenceType.video:
          dropDownItems.add(DropdownMenuItem(value: type, child: Text(
            Localization().getStringEx('panel.essential_skills_coach.resources.select.video.label', 'View All Videos'),
            style: Styles().textStyles.getTextStyle("widget.title.light.large.fat")
          )));
          break;
        case ReferenceType.uri:
          dropDownItems.add(DropdownMenuItem(value: type, child: Text(
            Localization().getStringEx('panel.essential_skills_coach.resources.select.uri.label', 'View All External Links'),
            style: Styles().textStyles.getTextStyle("widget.title.light.large.fat")
          )));
          break;
        case ReferenceType.text:
          dropDownItems.add(DropdownMenuItem(value: type, child: Text(
            Localization().getStringEx('panel.essential_skills_coach.resources.select.text.label', 'View All Information'),
            style: Styles().textStyles.getTextStyle("widget.title.light.large.fat")
          )));
          break;
        case ReferenceType.powerpoint:
          dropDownItems.add(DropdownMenuItem(value: type, child: Text(
            Localization().getStringEx('panel.essential_skills_coach.resources.select.powerpoint.label', 'View All Powerpoints'),
            style: Styles().textStyles.getTextStyle("widget.title.light.large.fat")
          )));
          break;
        default:
          continue;
      }
    }
    return dropDownItems;
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

  List<Content> _filterContentItems() {
    if (_selectedResourceType != null) {
      List<Content> filteredContentItems =  _contentItems.where((i) => i.reference?.type == _selectedResourceType).toList();
      return filteredContentItems;
    }
    return _contentItems;
  }

  // //TODO fix data parsing
  // void _loadDataContentItem({required String key}) async{
  //   Map<String, dynamic>? response = await con.Content().getDataContentItem(key);
  //
  // }

  void _loadContentForKey(String? key, {Function(File)? onResult}) {
    if (StringUtils.isNotEmpty(key)) {
      _setLoadingReferenceKey(key, true);
      con.Content().getFileContentItem(key!, Config().essentialSkillsCoachKey ?? "").then((value) => {
        setState(() {
          _loadingReferenceKeys.remove(key);
          if (value != null) {
            _fileCache[key] = value;
            onResult?.call(value);
          }
        })
      });
    }
  }

  void _openPdf(BuildContext context, String? resourceName, String? path) {
    Navigator.push(context, MaterialPageRoute(
      builder: (context) => PDFScreen(resourceName: resourceName, path: path, color: _color,),
    ),);
  }

  void _openVideo(BuildContext context, String? resourceName, File file) {
    Navigator.push(context, MaterialPageRoute(
      builder: (context) => VideoPlayerScreen(resourceName: resourceName, file: file, color: _color,),
    ),);
  }

  void _setLoadingReferenceKey(String? key, bool value) {
    if (key != null) {
      setStateIfMounted(() {
        if (value) {
          _loadingReferenceKeys.add(key);
        } else {
          _loadingReferenceKeys.remove(key);
        }
      });
    }
  }
}
