/*
 * Copyright 2020 Board of Trustees of the University of Illinois.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:flutter/material.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/service/events.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:illinois/ui/athletics/AthleticsTeamsWidget.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_tab.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/service/styles.dart';

enum _InterestTab { Categories, Tags, Athletics }

class SettingsInterestsContentWidget extends StatefulWidget {

  @override
  _SettingsManageInterestsState createState() => _SettingsManageInterestsState();
}

class _SettingsManageInterestsState extends State<SettingsInterestsContentWidget> implements NotificationsListener {
  //Tabs
  List<_InterestTab> _tabs = [];
  _InterestTab? _selectedTab;

  //Categories
  List<dynamic>? _categories;
  Set<String>? _preferredCategories;

  //tags
  List<String>? _tags;
  List<String>? _followingTags;
  bool _tagSearchMode = false;

//  //Athletics sports
//  List<String> _preferredSports;

  //Search
  TextEditingController _textEditingController = TextEditingController();

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Auth2UserPrefs.notifyInterestsChanged,
      Auth2UserPrefs.notifyTagsChanged,
    ]);
    _initTabs();
    _initCategories();
    _initTags();
//    _loadPreferredSports();
    //_stopProgress();
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  @override
  void onNotification(String name, dynamic param) {
    if (name == Auth2UserPrefs.notifyInterestsChanged) {
      if (mounted) {
        setState(() {
          _preferredCategories = (Auth2().prefs?.interestCategories != null) ? Set.from((Auth2().prefs!.interestCategories!)) : null;
        });
      }
    }
    else if (name == Auth2UserPrefs.notifyTagsChanged) {
      if (mounted) {
        setState(() {
          _followingTags = _buildFollowingTags(_tags);
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return _buildContent();
  }

  Widget _buildContent() {

    //TODO: adjust with textspan
    return Container(
                color: Styles().colors!.background,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                  Semantics(
                      label: Localization().getStringEx('panel.settings.manage_interests.instructions.tap', "Tap the ") +
                          Localization().getStringEx("panel.settings.manage_interests.instructions.check_mark", "check-mark") +
                          Localization().getStringEx('panel.settings.manage_interests.instructions.follow', ' to follow the tags that interest you most'),
                      excludeSemantics: true,
                      child: Container(
                          alignment: Alignment.topCenter,
                          color: Styles().colors!.fillColorPrimary,
                          child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Text(
                                    Localization().getStringEx('panel.settings.manage_interests.instructions.tap', "Tap the "),
                                    style: TextStyle(fontFamily: Styles().fontFamilies!.regular, color: Styles().colors!.white, fontSize: 16),
                                    textAlign: TextAlign.start,
                                  ),
                                  Image.asset('images/example.png'),
                                  Expanded(child: Container(
                                      child:Text(
                                        Localization()
                                            .getStringEx('panel.settings.manage_interests.instructions.follow', ' to follow the tags that interest you most'),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontFamily: Styles().fontFamilies!.regular, color: Styles().colors!.white, fontSize: 16),
                                      )))
                                ],
                              )))),
                  Padding(padding: EdgeInsets.symmetric(vertical: 16), child:
                    SingleChildScrollView(scrollDirection: Axis.horizontal, child:
                      Row(children: _buildTabWidgets(),),
                    ),
                  ),
                  _buildTabContent(),
                ]));
  }

  Widget _buildTabContent() {
    if (_selectedTab != null) {
      switch (_selectedTab!) {
        case _InterestTab.Categories:
          return _buildCategoriesContent();
        case _InterestTab.Tags:
          return _buildTagsContent();
        case _InterestTab.Athletics:
          return Padding(
            padding: EdgeInsets.all(16),
            child: AthleticsTeamsWidget(), //TBD pass _preferredSpords and tapListener if using save button
          );
      }
    }
    return Container();
  }

  //Categories
  void _initCategories() {
    Events().loadEventCategories().then((List<dynamic>? categories) {
      if (mounted) {
        setState(() {
          _categories = categories != null ? categories : [];
          _preferredCategories = (Auth2().prefs?.interestCategories != null) ? Set.from((Auth2().prefs!.interestCategories!)) : null;
        });
      }
    });
  }

  Widget _buildCategoriesContent() {
    return ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Container(
            foregroundDecoration: BoxDecoration(
              border: Border.all(
                color: Styles().colors!.surfaceAccent!,
                width: 1.0,
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: _buildCategories(),
            ),
          ),
        );
  }

  List<Widget> _buildCategories() {
    List<Widget> categoryWidgets = [];

    if (_categories != null && _preferredCategories != null) {
      for (var category in _categories!) {
        if (categoryWidgets.isNotEmpty) {
          categoryWidgets.add(Container(
            height: 1,
            color: Styles().colors!.surfaceAccent,
          ));
        }

        String? categoryName = StringUtils.isNotEmpty(category['category']) ? category['category'] : "";
        categoryWidgets.add(_SelectionItemWidget(
            label: categoryName,
            selected: _preferredCategories!.contains(categoryName),
            onTap: () {
              Analytics().logSelect(target: "Category: $categoryName");
              AppSemantics.announceCheckBoxStateChange(context, _preferredCategories!.contains(categoryName), categoryName);
              Auth2().prefs?.toggleInterestCategory(categoryName);
            }));
      }
    }
    return categoryWidgets;
  }

  /////

  //Tags
  void _initTags() {
    Events().loadEventTags().then((List<String>? tagList) {
      if (mounted) {
        setState(() {
          _tags = tagList ?? [];
          _followingTags = _buildFollowingTags(tagList);
        });
      }
    });
  }

  Widget _buildTagsContent() {
    return Column(
      children: <Widget>[
        _buildSearchField(),
        _tagSearchMode || !CollectionUtils.isNotEmpty(_followingTags)
            ? Container()
            : Text(Localization().getStringEx('panel.settings.manage_interests.list.following', "FOLLOWING")),
        _tagSearchMode ? Container() : _buildTagsList(_followingTags),
        _tagSearchMode ? Container() : Text(Localization().getStringEx('panel.settings.manage_interests.list.all_tags', "ALL TAGS")),
        _tagSearchMode ? Container() : _buildTagsList(_tags),
        !_tagSearchMode ? Container() : Text(Localization().getStringEx('panel.settings.manage_interests.list.search', "SEARCH")),
        !_tagSearchMode ? Container() : _buildTagsList(_filterTags(_textEditingController.text)),
      ],
    );
  }

  Widget _buildSearchField() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      color: Styles().colors!.surface,
      height: 48,
      child: Row(
        children: <Widget>[
          Flexible(
            child: Semantics(
                label: Localization().getStringEx("panel.settings.manage_interests.search.field.label", "Search for tags"),
                hint: Localization().getStringEx("panel.settings.manage_interests.search.field.hint", "type the tag you are looking for"),
                textField: true,
                excludeSemantics: true,
                child: TextField(
                  controller: _textEditingController,
                  onChanged: (text) => _onTextChanged(text),
                  onSubmitted: (_) => () {},
                  autofocus: true,
                  cursorColor: Styles().colors!.fillColorSecondary,
                  keyboardType: TextInputType.text,
                  style: TextStyle(fontSize: 16, fontFamily: Styles().fontFamilies!.regular, color: Styles().colors!.textBackground),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                  ),
                )),
          ),
          Semantics(
            label: Localization().getStringEx("dialog.cancel.title", "Cancel"),
            hint: Localization().getStringEx("panel.settings.manage_interests.search.cancel.hint", "clear the search filter"),
            button: true,
            excludeSemantics: true,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: GestureDetector(
                onTap: () {
                  _onCancelSearchTap();
                },
                child: Image.asset(
                  'images/icon-x-orange.png',
                  width: 25,
                  height: 25,
                ),
              ),
            ),
          ),
          Semantics(
              label: Localization().getStringEx("panel.settings.manage_interests.search.search_button.title", "Search"),
              hint: Localization().getStringEx("panel.settings.manage_interests.search.search_button.hint", "filter tags"),
              button: true,
              excludeSemantics: true,
              child: GestureDetector(
                onTap: () {
                  _onSearchTap();
                },
                child: Image.asset(
                  'images/icon-search.png',
                  color: Styles().colors!.fillColorSecondary,
                  width: 25,
                  height: 25,
                ),
              ))
        ],
      ),
    );
  }

  void _onSearchTap() async {
    Analytics().logSelect(target: "Search");
    setState(() {
      _tagSearchMode = true;
    });
  }

  void _onCancelSearchTap() async {
    Analytics().logSelect(target: "Cancel Search");
    setState(() {
      _textEditingController.text = "";
      _tagSearchMode = false;
    });
  }

  List<String>? _filterTags(String key) {
    List<String> result =  [];
    if (StringUtils.isEmpty(key)) {
      return _tags;
    } else if (CollectionUtils.isNotEmpty(_tags)) {
      result = _tags!.where((String tag) => tag.startsWith(key)).toList();
    }

    return result;
  }

  void _onTextChanged(String text) {
    setState(() {
      _tagSearchMode = StringUtils.isNotEmpty(text);
    });
  }

  Widget _buildTagsList(List<String>? tags) {
    return ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Container(
            foregroundDecoration: BoxDecoration(
              border: Border.all(
                color: Styles().colors!.surfaceAccent!,
                width: 1.0,
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: _buildTagsItems(tags),
            ),
          ),
        );
  }

  List<Widget> _buildTagsItems(List<String>? tags) {
    List<Widget> tagsWidgets = [];

    if (tags != null) {
      for (String tag in tags) {
        if (tagsWidgets.isNotEmpty) {
          tagsWidgets.add(Container(
            height: 1,
            color: Styles().colors!.surfaceAccent,
          ));
        }

        tagsWidgets.add(_SelectionItemWidget(
            label: tag,
            selected: _isTagSelected(tag),
            onTap: () {
              _onTagTaped(tag);
            }));
      }
    }
    return tagsWidgets;
  }

  static List<String> _buildFollowingTags(List<String>? tags) {
    List<String> followingTags = <String>[];
    if (tags != null) {
      for (String tag in tags) {
        if (Auth2().prefs?.hasTag(tag) ?? false) {
          followingTags.add(tag);
        }
      }
    }
    return followingTags;
  }

  bool? _isTagSelected(String tag) {
//    return _followingTags.contains(tag);
    return Auth2().prefs?.hasTag(tag);
  }

  void _onTagTaped(String tag) {
    Analytics().logSelect(target: "Tag: $tag");
    AppSemantics.announceCheckBoxStateChange(context, _isTagSelected(tag)!, tag);
    Auth2().prefs?.toggleTag(tag);
//    switchTag(tag);
  }

  //Athletics
/*  void _loadPreferredSports() {
    _preferredSports = [];
    if(User()?.getSportsInterestSubCategories()?.isNotEmpty ?? false) {
      _preferredSports.addAll(User()?.getSportsInterestSubCategories());
    }
    setState(() {});
  }

  switchSport(String sport){
    if(_preferredSports?.contains(sport)??false){
      _preferredSports.remove(sport);
    } else {
      if(_preferredSports!=null){
        _preferredSports.add(sport);
      }
    }
    setState(() {});
  }*/

  // NotificationsListener

  /////

  //Tabs
  List<Widget> _buildTabWidgets() {
    List<Widget> tabs = [];
    for (_InterestTab tab in _tabs) {
      tabs.add(Padding(padding: EdgeInsets.only(right: 8), child: RoundedTab(title: _interestTabName(tab), tabIndex: _tabs.indexOf(tab), onTap: _onTapTab, selected: (_selectedTab == tab))));
    }
    return tabs;
  }

  void _initTabs() {
    _tabs = _InterestTab.values;
    _selectTab(_tabs[0]);
  }

  void _selectTab(_InterestTab tab) {
    setState(() {
      _selectedTab = tab;
    });
  }

  void _onTapTab(RoundedTab tab) {
    if ((0 <= tab.tabIndex) && (tab.tabIndex < _tabs.length)) {
      Analytics().logSelect(target: tab.title);
      _selectTab(_tabs[tab.tabIndex]);
    }
  }

  ////

  //SaveButton
/*  Widget _buildSaveButton(){
    return
      Padding(
        padding: EdgeInsets.symmetric( vertical: 20,horizontal: 16),
        child: RoundedButton(
          label: Localization().getStringEx("panel.settings.manage_interests.button.save.title", "Save Changes"),
          hint: Localization().getStringEx("panel.settings.manage_interests.button.save.hint", ""),
          enabled: _canSave,
          fontFamily: Styles().fontFamilies.bold,
          backgroundColor: _canSave? Styles().colors.white: Styles().colors.background,
          fontSize: 16.0,
          textColor: _canSave? Styles().colors.fillColorPrimary : Styles().colors.surfaceAccent,
          borderColor: _canSave? Styles().colors.fillColorSecondary : Styles().colors.surfaceAccent,
          onTap: _onSaveChangesClicked,
        ),
      );
  }

  _onSaveChangesClicked(){
    if(_categoriesHasChanged) {
      User()?.updateCategories(_preferredCategories);
    }
    if(_sportsHasChanged) {
      User()?.updateSportsSubCategories(_preferredSports);
    }
    if(_tagsHasChanged) {
      User()?.updateTags(_followingTags);
    }
    Navigator.pop(context);
  }

  bool get _canSave{
    return _categoriesHasChanged || _tagsHasChanged ||_sportsHasChanged;
  }

  bool get _categoriesHasChanged{
    bool changed = false;
    if ((_preferredCategories?.isEmpty?? true) && (User().getInterestsCategories()?.isEmpty?? true)) {
      return changed;
    }

    return !IterableEquality().equals(_preferredCategories, User().getInterestsCategories());
  }

  bool get _tagsHasChanged{
    if ((_followingTags?.isEmpty?? true) && (User().getTags()?.isEmpty?? true)) {
      return false;
    }
    return !IterableEquality().equals(_followingTags, User().getTags());
  }

  bool get _sportsHasChanged{
    if ((_preferredSports?.isEmpty?? true) && (User().getSportsInterestSubCategories()?.isEmpty?? true)) {
      return false;
    }
    return !IterableEquality().equals(_preferredSports, User().getSportsInterestSubCategories());
  }*/

  static String? _interestTabName(_InterestTab tab) {
    switch (tab) {
      case _InterestTab.Categories:
        return Localization().getStringEx('panel.settings.manage_interests.tab.categories', "Categories");
      case _InterestTab.Tags:
        return Localization().getStringEx('panel.settings.manage_interests.tab.tags', "Tags");
      case _InterestTab.Athletics:
        return Localization().getStringEx('panel.settings.manage_interests.tab.athletics', "Athletics");
      default:
        return null;
    }
  }
}

class _SelectionItemWidget extends StatelessWidget {
  final String? label;
  final GestureTapCallback? onTap;
  final bool? selected;

  _SelectionItemWidget(
      {required this.label, this.onTap, this.selected = false});

  @override
  Widget build(BuildContext context) {
    return Semantics(
        label: label,
        value: (selected!?Localization().getStringEx("toggle_button.status.checked", "checked",) :
        Localization().getStringEx("toggle_button.status.unchecked", "unchecked")) +
            ", "+ Localization().getStringEx("toggle_button.status.checkbox", "checkbox"),
        excludeSemantics: true,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            color: Colors.white,
            child: Padding(
              padding: EdgeInsets.all(10),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Flexible(
                      child: Text(
                        label!,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontFamily: Styles().fontFamilies!.bold,
                            color: Styles().colors!.fillColorPrimary,
                            fontSize: 16),
                      )),
                  Image.asset(selected!
                      ? 'images/deselected-dark.png'
                      : 'images/deselected.png')
                ],
              ),
            ),
          ),
        ));
  }
}