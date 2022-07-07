
import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/Guide.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/ui/guide/GuideCategoriesPanel.dart';
import 'package:illinois/ui/guide/GuideListPanel.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:illinois/ui/widgets/FavoriteButton.dart';
import 'package:illinois/ui/widgets/LinkButton.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
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
  String? _selectedCategory;
  DateTime? _selectedCategoryTime;

  @override
  void initState() {

    NotificationService().subscribe(this, [
      Guide.notifyChanged,
      Config.notifyConfigChanged,
      AppLivecycle.notifyStateChanged,
    ]);

    if (widget.updateController != null) {
      widget.updateController!.stream.listen((String command) {
        if (command == HomePanel.notifyRefresh) {
          Guide().refresh();
        }
      });
    }

    _selectedCategory = Storage().homeCampusRemindersCategory;
    _selectedCategoryTime = (Storage().homeCampusRemindersCategoryTime != null) ? DateTime.fromMillisecondsSinceEpoch(Storage().homeCampusRemindersCategoryTime ?? 0) : null;

    _buildCategories();
    _updateSelectedCategoryIfNeeded();

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
    if (name == Guide.notifyChanged) {
      if (mounted) {
        setState(() {
          _buildCategories();
          _updateSelectedCategoryIfNeeded();
        });
      }
    }
    else if (name == Config.notifyConfigChanged) {
      if (mounted) {
        setState(() {});
      }
    }
    else if ((name == AppLivecycle.notifyStateChanged) && (param == AppLifecycleState.resumed)) {
      if (_updateSelectedCategoryIfNeeded() && mounted) {
        setState(() {});
      }
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
          HomeFavoriteButton(favorite: HomeFavorite(widget.favoriteId), style: FavoriteIconStyle.Button, prompt: true,)
        ],)
      ),
      Padding(padding: EdgeInsets.symmetric(horizontal: 16),
        child: _buildContent(),
      ),
    ],);
  }


  Widget _buildContent() {
    if ((_selectedCategory != null) && (_categorySections != null)) {
      return Column(children: <Widget>[
        _buildHeading(_selectedCategory!),
        _buildSections(_categorySections![_selectedCategory], category: _selectedCategory),
        LinkButton(
          title: Localization().getStringEx('widget.home.campus_guide.button.all.title', 'View All'),
          hint: Localization().getStringEx('widget.home.campus_guide.button.all.hint', 'Tap to view the complete Campus Guide'),
          onTap: _onTapViewAll,
        ),
      ]);
    }
    else {
      return Row(children: [
        Expanded(child:
            Padding(padding: EdgeInsets.only(top: 8, bottom: 16), child:
              Text(Localization().getStringEx('widget.home.campus_guide.content.empty', 'Campus Guide content not available.'), style: TextStyle(color: Styles().colors!.textSurface, fontSize: 16, fontFamily: Styles().fontFamilies?.medium),)
            ),
        ),
      ],);
    }
  }

  Widget _buildHeading(String category) {

    return GestureDetector(onTap: () => _onTapCategory(category), child:
      Container(decoration: BoxDecoration(color: Styles().colors!.fillColorPrimary, borderRadius: BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4))), child:
        Semantics(label: 'Heading', header: true, excludeSemantics: true, child:
          Padding(padding: EdgeInsets.only(left: 16, right: 8, top: 10, bottom: 10), child:
            Row(children: <Widget>[
              Expanded(child:
                Text(category, style: TextStyle(fontFamily: Styles().fontFamilies?.bold, color: Colors.white, fontSize: 16, letterSpacing: 1.0),),
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
      int count = min(Config().homeCampusGuideCount, sections.length);
      for (int index = 0; index < count; index++) {
        GuideSection section = sections[index];
        if (contentList.isNotEmpty) {
          contentList.add(Divider(color: Styles().colors!.surfaceAccent, height: 1,));
        }
        contentList.add(_buildEntry(section, category: category));
      }
    }
    return Container(decoration: BoxDecoration(color: Colors.white,  border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1), borderRadius: BorderRadius.only(bottomLeft: Radius.circular(4), bottomRight: Radius.circular(4))), child:
      Column(children: contentList),
    );
  }

  Widget _buildEntry(GuideSection section, { String? category }) {
    return GestureDetector(onTap: () => _onTapSection(section, category: category), child:
      
        Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12), child:
          Row(children: <Widget>[
            Expanded(child:
              Text(section.name ?? '', style: TextStyle(fontFamily: Styles().fontFamilies!.bold, color: Styles().colors!.fillColorPrimary, fontSize: 16),),
            ),
            Padding(padding: EdgeInsets.only(right: 6), child:
              Image.asset('images/chevron-right.png', excludeFromSemantics: true),
            )
          ],),
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

  bool hasCategory(String? category) {
    return _categorySections?.containsKey(category) ?? false;
  }

  bool get _isSelectedCategoryExpired {
    return (_selectedCategoryTime == null) || ( 4 < DateTime.now().difference(_selectedCategoryTime!).inHours);
  }

  bool _updateSelectedCategoryIfNeeded() {
    if ((_selectedCategory == null) || _isSelectedCategoryExpired || !hasCategory(_selectedCategory)) {
      int categoriesCount = _categories?.length ?? 0;
      int categoryIndex = (0 < categoriesCount) ? Random().nextInt(categoriesCount) : -1;
      if ((0 <= categoryIndex) && (categoryIndex < categoriesCount)) {
        Storage().homeCampusRemindersCategory = _selectedCategory = _categories![categoryIndex];
        Storage().homeCampusRemindersCategoryTime = (_selectedCategoryTime = DateTime.now()).millisecondsSinceEpoch;
        return true;
      }
    }
    return false;
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
    Analytics().logSelect(target: "HomeCampusGuideWidget View All");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GuideCategoriesPanel(guide: widget.guide,)));
  }
}