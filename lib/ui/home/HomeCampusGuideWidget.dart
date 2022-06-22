
import 'dart:async';
import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/Guide.dart';
import 'package:illinois/ui/guide/GuideListPanel.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:illinois/ui/widgets/LinkButton.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class HomeCampusGuideWidget extends StatefulWidget {

  final String? favoriteId;
  final StreamController<String>? updateController;
  final String? guide = Guide.campusGuide;

  HomeCampusGuideWidget({Key? key, this.favoriteId, this.updateController}) : super(key: key);

  static Widget handle({String? favoriteId, HomeDragAndDropHost? dragAndDropHost, int? position}) =>
    HomeHandleWidget(favoriteId: favoriteId, dragAndDropHost: dragAndDropHost, position: position,
      title: title,
    );

  static String get title => Localization().getStringEx('widget.home.campus_guide.text.title', 'Campus Guide');

  State<HomeCampusGuideWidget> createState() => _HomeCampusGuideWidgetState();
}

class _HomeCampusGuideWidgetState extends State<HomeCampusGuideWidget> implements NotificationsListener {

  List<String>? _categories;
  Map<String, List<GuideSection>>? _categorySections;

  @override
  void initState() {

    NotificationService().subscribe(this, [
      Config.notifyConfigChanged,
      Guide.notifyChanged,
    ]);

    if (widget.updateController != null) {
      widget.updateController!.stream.listen((String command) {
        if (command == HomePanel.notifyRefresh) {
          Guide().refresh();
        }
      });
    }

    _buildCategories();

    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if ((name == Guide.notifyChanged) ||
        (name == Config.notifyConfigChanged)){
      setState(() {
        _buildCategories();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: <Widget>[
      Padding(padding: EdgeInsets.only(left: 18, right: 4, top: 4, bottom: 4), child:
        Row(children: [
          Expanded(child:
            Align(alignment: Alignment.centerLeft, child:
              Text(HomeCampusGuideWidget.title, style: TextStyle(fontSize: 20, color: Styles().colors?.fillColorPrimary, fontFamily: Styles().fontFamilies?.extraBold),),
            ),
          ),
          HomeFavoriteButton(favorite: HomeFavorite(widget.favoriteId), style: HomeFavoriteStyle.Button, prompt: true,)
        ],)
      ),
      Padding(padding: EdgeInsets.symmetric(horizontal: 16),
        child: _buildContent(),
      ),
      LinkButton(
        title: Localization().getStringEx('widget.home.campus_guide.button.all.title', 'View All'),
        hint: Localization().getStringEx('widget.home.campus_guide.button.all.hint', 'Tap to view all items'),
        onTap: _onTapViewAll,
      ),
      
    ],);
  }


  Widget _buildContent() {
    if ((_categories != null) && (0 < _categories!.length)) {
      List<Widget> contentList = <Widget>[];
      for (String category in _categories!) {
        contentList.add(_buildHeading(category));
        contentList.add(_buildSections(_categorySections![category], category: category));
      }

      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: contentList);
    }
    else {
      return Padding(padding: EdgeInsets.all(32), child:
        Center(child:
          Text(Localization().getStringEx('panel.guide_categories.label.content.empty', 'Empty guide content'), style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 16, fontFamily: Styles().fontFamilies!.bold),)
        ,)
      );
    }
  }

  Widget _buildHeading(String category) {

    return GestureDetector(onTap: () => _onTapCategory(category), child:
      Container(decoration: BoxDecoration(color: Styles().colors!.fillColorPrimary, borderRadius: BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4))), child:
        Semantics(label: 'Heading', header: true, excludeSemantics: true, child:
          Padding(padding: EdgeInsets.only(left: 16, right: 8, top: 10, bottom: 10), child:
            Row(children: <Widget>[
              Expanded(child:
                Text(category, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: Styles().fontFamilies!.bold, color: Colors.white, fontSize: 14, letterSpacing: 1.0),),
              ),
           ]),
          ),
        ),
      ),
    );
  }

  Widget _buildSections(List<GuideSection>? sections, { String? category }) {
    List<Widget> contentList = <Widget>[];
    if (sections != null) {
      for (GuideSection section in sections) {
        if (contentList.isNotEmpty) {
          contentList.add(Divider(color: Styles().colors!.surfaceAccent, height: 1,));
        }
        contentList.add(_buildEntry(section, category: category));
      }
    }
    return Container(decoration: BoxDecoration(border:Border.all(color: Styles().colors!.surfaceAccent!, width: 1)), child:
      Column(children: contentList),
    );
  }

  Widget _buildEntry(GuideSection section, { String? category }) {
    return GestureDetector(onTap: () => _onTapSection(section, category: category), child:
      Container(color: Colors.white, child:
        Padding(padding: EdgeInsets.only(left: 10, top: 0, bottom: 0), child:
          Row(children: <Widget>[
            Expanded(child:
              Text(section.name ?? '', style: TextStyle(fontFamily: Styles().fontFamilies!.bold, color: Styles().colors!.fillColorPrimary, fontSize: 16),),
            ),
            Padding(padding: EdgeInsets.symmetric(horizontal: 6), child:
              Image.asset('images/chevron-right.png', excludeFromSemantics: true),
            )
          ],),
        ),
      ),
    );
  }

  void _buildCategories() {
    
    List<dynamic>? contentList = Guide().getContentList(guide: widget.guide);
    if (contentList != null) {

      LinkedHashMap<String, LinkedHashSet<GuideSection>> categoriesMap = LinkedHashMap<String, LinkedHashSet<GuideSection>>();
      
      for (dynamic contentEntry in contentList) {
        Map<String, dynamic>? guideEntry = JsonUtils.mapValue(contentEntry);
        if (guideEntry != null) {
          String? category = JsonUtils.stringValue(Guide().entryValue(guideEntry, 'category'));
          GuideSection? section = GuideSection.fromGuideEntry(guideEntry);

          if (StringUtils.isNotEmpty(category) && (section != null)) {
            LinkedHashSet<GuideSection>? categorySections = categoriesMap[category];
            if (categorySections == null) {
              categoriesMap[category!] = categorySections = LinkedHashSet<GuideSection>();
            }
            if (!categorySections.contains(section)) {
              categorySections.add(section);
            }
          }
        }
      }

      _categories = List.from(categoriesMap.keys) ;
      _categories!.sort();

      _categorySections = Map<String, List<GuideSection>>();
      categoriesMap.forEach((String category, LinkedHashSet<GuideSection> sectionsSet) {
        List<GuideSection> sections = List.from(sectionsSet);
        sections.sort((GuideSection section1, GuideSection section2) {
          return section1.compareTo(section2);
        });
        _categorySections![category] = sections;
      });
        
    }
    else {
      _categories = null;
      _categorySections = null;
    }
  }

  void _onTapCategory(String category) {
    Analytics().logSelect(target: category);
    //Navigator.push(context, CupertinoPageRoute(builder: (context) => GuideListPanel(category: category,)));
  }

  void _onTapSection(GuideSection section, {String? category}) {
    Analytics().logSelect(target: "$category / ${section.name}");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GuideListPanel(guide: widget.guide, category: category, section: section,)));
  }

  void _onTapViewAll() {
  }
}