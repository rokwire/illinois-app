
import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:illinois/model/Analytics.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/ui/attributes/ContentAttributesPanel.dart';
import 'package:illinois/ui/events2/Event2Widgets.dart';
import 'package:illinois/ui/groups/GroupCreatePanel.dart';
import 'package:illinois/ui/groups/GroupWidgets.dart';
import 'package:illinois/ui/map2/Map2Widgets.dart';
import 'package:illinois/ui/profile/ProfileHomePanel.dart';
import 'package:illinois/ui/settings/SettingsPrivacyPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:illinois/utils/AppUtils.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:rokwire_plugin/model/content_attributes.dart';
import 'package:rokwire_plugin/model/group.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

enum _PanelMode { regular, search }

class GroupHome2Panel extends StatefulWidget with AnalyticsInfo {
  static final String routeName = 'edu.illinois.rokwire.group.home2';

  final _PanelMode mode;
  final String? searchText;
  final GroupsFilter? filter;

  GroupHome2Panel({ super.key, this.searchText, this.filter, this.mode = _PanelMode.regular });

  static void push(BuildContext context, { GroupsFilter? filter }) =>
    Navigator.push(context, CupertinoPageRoute(
      settings: RouteSettings(name: routeName),
      builder: (context) => GroupHome2Panel(filter: filter,)
    ));

  _GroupHome2PanelState createState() => _GroupHome2PanelState();

  @override
  AnalyticsFeature? get analyticsFeature => AnalyticsFeature.Groups;
}

class _GroupHome2PanelState extends State<GroupHome2Panel> with NotificationsListener {

  GlobalKey _filtersButtonKey = GlobalKey();
  GlobalKey _myGroupsFilterButtonKey = GlobalKey();
  GlobalKey _listViewKey = GlobalKey();

  ScrollController _scrollController = ScrollController();
  TextEditingController _searchTextController = TextEditingController();
  FocusNode _searchTextNode = FocusNode();

  LinkedHashMap<String, List<Group>>? _contentMap;
  List<_DisplayListItem>? _displayList;
  int? _totalContentLength;
  final Map<String, GlobalKey> _cardKeys = <String, GlobalKey>{};

  late Set<String> _collapsedSections;

  ContentActivity? _contentActivity;

  GroupsFilter? _filter;
  String? _searchText;

  GroupsFilter get _authValidFilter => _filter?.authValidated ?? GroupsFilter();
  bool get _myGroupsSelected => (_authValidFilter.types?.containsAll(_myGroupsFilterTypes) == true);
  static const Set<GroupsFilterType> _myGroupsFilterTypes = const <GroupsFilterType> { GroupsFilterType.admin, GroupsFilterType.member };

  bool get _searchMode => (widget.mode == _PanelMode.search);
  bool get _regularMode => (widget.mode == _PanelMode.regular);

  GroupsFilter? get _storedFilter => _regularMode ? Storage().groupsHome2Filter : null;
  set _storedFilter(GroupsFilter? value) {
    if (_regularMode) {
      Storage().groupsHome2Filter = value;
    }
  }

  Set<String>? get _storedSections => _regularMode ? Storage().groupsHome2Sections : null;
  set _storedSections(Set<String>? value) {
    if (_regularMode) {
      Storage().groupsHome2Sections = value;
    }
  }

  bool get _commandBarVisible => (_regularMode || (_searchMode && (_searchText?.isNotEmpty == true) && (_contentActivity == null)));

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Groups.notifyGroupCreated,
      Groups.notifyGroupUpdated,
      Groups.notifyGroupDeleted,
      Groups.notifyUserGroupsUpdated,
      Auth2.notifyLoginChanged,
    ]);

    _filter = widget.filter ?? _storedFilter;
    _searchText = widget.searchText;
    _searchTextController.text = _searchText ?? '';
    _collapsedSections = _storedSections ?? <String>{};

    if (_regularMode || (_searchMode && (_searchText?.isNotEmpty == true)))
      _loadInitialContent();
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    _scrollController.dispose();
    _searchTextController.dispose();
    _searchTextNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: _regularMode ? RootHeaderBar(title: widget.mode.panelTitle, leading: RootHeaderBarLeading.Back,) : HeaderBar(title: widget.mode.panelTitle),
    body: _scaffoldBody,
    backgroundColor: Styles().colors.background,
    bottomNavigationBar: uiuc.TabBar(),
  );

  Widget get _scaffoldBody => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    if (_searchMode)
      _searchBar,
    if (_commandBarVisible)
      _commandBar,
    Expanded(child:
      RefreshIndicator(onRefresh: _onRefresh, child:
        _bodyContent,
      ),
    )
  ],);

  Widget get _bodyContent {
    if (_contentActivity == ContentActivity.reload) {
      return _loadingContent;
    }
    else if (_contentActivity == ContentActivity.refresh) {
      return Container();
    }
    else if (_searchMode && (_searchText?.isNotEmpty != true)) {
      return Container();
    }
    else if (_displayList == null) {
      return _buildMessageContent(Localization().getStringEx('panel.group.home2.failed.text', 'Failed to load groups'),
        title: Localization().getStringEx('common.label.failed', 'Failed')
      );
    }
    else if (_displayList?.length == 0) {
      return _buildMessageContent(Localization().getStringEx('panel.group.home2.empty.text', 'There are no groups matching the selected filters.'));
    }
    else {
      return _listContent;
    }
  }

  Widget get _listContent =>
    ListView.builder(
      key: _listViewKey,
      controller: _scrollController,
      physics: BouncingScrollPhysics(),
      itemCount: _displayList?.length ?? 0,
      itemBuilder: _buildDisplayListItem,
      scrollDirection: Axis.vertical,
    );

  Widget? _buildDisplayListItem(BuildContext context, int index) {
    _DisplayListItem? displayListItem = ListUtils.entry(_displayList, index);
    if (displayListItem is _SectionHeadingListItem) {
      return _buildSection(displayListItem.section, collapsed: _collapsedSections.contains(displayListItem.section));
    } else if (displayListItem is _SplitterListItem) {
      return Divider(height: _dividerHeight, color: Styles().colors.surfaceAccent,);
    } else if (displayListItem is _SpacerListItem) {
      return SizedBox(height: displayListItem.height);
    } else if (displayListItem is _GroupListItem) {
      return Padding(padding: _groupCardPadding, child:
        GroupCard(displayListItem.group, displayType: GroupCardDisplayType.allGroups, key: _cardKeys[displayListItem.group.id],),
      );
    } else {
      return null;
    }
  }

  Widget _buildSection(String section, {bool? collapsed}) {
    return Row(children: [
      InkWell(onTap: () => _onToggleSection(section), child:
        Padding(padding: _sectionIconPadding, child:
          Styles().images.getImage((collapsed != true) ? 'chevron2-up' : 'chevron2-down', color: Styles().colors.fillColorSecondary, size: _sectionIconSize, excludeFromSemantics: true)
        )
      ),
      Expanded(child:
        Padding(padding: _sectionTextPadding, child:
          Text(section, style: Styles().textStyles.getTextStyle('widget.title.regular.fat'),)
        )
      )
    ],);
  }

  static const EdgeInsetsGeometry _sectionIconPadding = const EdgeInsetsGeometry.all(
    _sectionIconPaddingSize
  );
  static const double _sectionIconPaddingSize = 16;
  static const double _sectionIconSize = 16;

  static const EdgeInsetsGeometry _sectionTextPadding = const EdgeInsetsGeometry.only(
    top: _sectionTextPaddingV,
    bottom: _sectionTextPaddingV,
    right: _sectionTextPaddingH
  );
  static const double _sectionTextPaddingV = 8;
  static const double _sectionTextPaddingH = 16;

  // Group Card

  static const EdgeInsetsGeometry _groupCardPadding = const EdgeInsetsGeometry.symmetric(
    horizontal: _groupCardPaddingH,
  );
  static const double _groupCardPaddingH = 16;

  // Divider

  static const double _dividerHeight = 1;

  // Other Content Types

  Widget _buildMessageContent(String message, { String? title }) =>
    SingleChildScrollView(controller: _scrollController, physics: BouncingScrollPhysics(), child:
      Center(child:
        Padding(padding: EdgeInsets.symmetric(horizontal: 32, vertical: _screenHeight / 6), child:
          Column(children: [
            (title != null) ? Padding(padding: EdgeInsets.only(bottom: 12), child:
              Text(title, textAlign: TextAlign.center, style: Styles().textStyles.getTextStyle('widget.item.medium.fat'),)
            ) : Container(),
            Text(message, textAlign: TextAlign.center, style: Styles().textStyles.getTextStyle((title != null) ? 'widget.item.regular.thin' : 'widget.item.medium.fat'),),
          ],),
        )
      )
    );

  Widget get _loadingContent =>
    Column(children: [
      Expanded(flex: 1, child: Container()),
      SizedBox(width: 32, height: 32, child:
        CircularProgressIndicator(color: Styles().colors.fillColorSecondary,)
      ),
      Expanded(flex: 2, child: Container()),
    ],);

  double get _screenHeight => MediaQuery.of(context).size.height;

  // Command Bar

  Widget get _commandBar =>
    Container(decoration: _commandBarDecoration, child:
      Padding(padding: EdgeInsets.only(top: 8), child:
        Column(children: [
          _commandButtonsBar,
          _contentDescriptionBar,
        ],)
      ),
    );

  Decoration get _commandBarDecoration => BoxDecoration(
    color: Styles().colors.surface,
    border: Border.all(color: Styles().colors.disabledTextColor, width: 1)
  );

  Widget get _commandButtonsBar => Row(children: [
    Padding(padding: EdgeInsets.only(left: 16)),
    Expanded(flex: 6, child: Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [ //Row(mainAxisAlignment: MainAxisAlignment.start, children: [
      MergeSemantics(key: _filtersButtonKey, child:
        Semantics(/* TBD: value: _currentFilterParam.descriptionText, hint: _filtersButtonHint,*/ child:
          Map2FilterTextButton(
            title: Localization().getStringEx('panel.group.home2.bar.button.filter.title', 'Filter'),
            hint: Localization().getStringEx('panel.group.home2.bar.button.filter.hint', 'Tap to build filter'),
            leftIcon: Styles().images.getImage('filters', size: 16),
            rightIcon: Styles().images.getImage('chevron-right'),
            onTap: _onFilter,
          ),
        ),
      ),
      if (Auth2().isLoggedIn)
        MergeSemantics(key: _myGroupsFilterButtonKey, child:
          Semantics(/* TBD: value: _currentFilterParam.descriptionText, hint: _filtersButtonHint,*/ child:
            Map2FilterTextButton(
              title: Localization().getStringEx('panel.group.home2.bar.button.my_groups.title', 'My Groups'),
              hint: Localization().getStringEx('panel.group.home2.bar.button.my_groups.hint', 'Tap to toggle my groups filter'),
              leftIcon: Styles().images.getImage('groups', size: 16),
              toggled: _myGroupsSelected,
              //contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              onTap: _onMyGroups,
            ),
          ),
        ),
    ])),
    Expanded(flex: 2, child: Wrap(alignment: WrapAlignment.end, crossAxisAlignment: WrapCrossAlignment.center, verticalDirection: VerticalDirection.up, children: [
      Visibility(visible: _regularMode && Auth2().isOidcLoggedIn, child:
        Event2ImageCommandButton(Styles().images.getImage('plus-circle'),
          label: Localization().getStringEx('panel.group.home2.bar.button.create.title', 'Create'),
          hint: Localization().getStringEx('panel.group.home2.bar.button.create.hint', 'Tap to create group'),
          contentPadding: EdgeInsets.only(left: 8, right: 8, top: 12, bottom: 12),
          onTap: _onCreate
        ),
      ),
      Visibility(visible: _regularMode, child:
        Event2ImageCommandButton(Styles().images.getImage('search'),
          label: Localization().getStringEx('panel.group.home2.bar.button.search.title', 'Search'),
          hint: Localization().getStringEx('panel.group.home2.bar.button.search.hint', 'Tap to search groups'),
          contentPadding: EdgeInsets.only(left: 8, right: 16, top: 12, bottom: 12),
          onTap: _onSearch
        ),
      ),
    ])),
  ],);

  Widget get _contentDescriptionBar {
    // Build description map
    LinkedHashMap<String, List<String>>? descriptionMap = LinkedHashMap<String, List<String>>();

    if (_searchMode && (_searchText?.isNotEmpty == true)) {
      String searchTitle = Localization().getStringEx('panel.group.home2.bar.description.search.title', 'Search');
      descriptionMap[searchTitle] = <String>[_searchText ?? ''];
    }

    String filterTitle = Localization().getStringEx('panel.group.home2.bar.description.filters.title', 'Filter');
    List<String>? filterDescription = _filter?.authValidated.description;
    descriptionMap[filterTitle] = ((filterDescription != null) && filterDescription.isNotEmpty) ? filterDescription : <String>[
      Localization().getStringEx('panel.group.home2.bar.description.filters.empty.title', 'None')
    ];

    if ((_totalContentLength != null) && (_contentActivity?._hidesContent != true)) {
      String groupsTitle = Localization().getStringEx('panel.group.home2.bar.description.groups.title', 'Groups');
      descriptionMap[groupsTitle] = <String>[_totalContentLength?.toString() ?? ''];
    }

    // Build RichText spans list from desriptin map
    List<InlineSpan> descriptionSpans = <InlineSpan>[];
    TextStyle? boldStyle = Styles().textStyles.getTextStyle('widget.card.title.tiny.fat');
    TextStyle? regularStyle = Styles().textStyles.getTextStyle('widget.card.detail.small.regular');
    descriptionMap.forEach((String descriptionCategory, List<String> descriptionItems){
      if (descriptionSpans.isNotEmpty) {
        descriptionSpans.add(TextSpan(text: '; ', style: regularStyle,),);
      }
      if (descriptionItems.isEmpty) {
        descriptionSpans.add(TextSpan(text: descriptionCategory, style: boldStyle,));
      } else {
        descriptionSpans.add(TextSpan(text: "$descriptionCategory: " , style: boldStyle,));
        descriptionSpans.add(TextSpan(text: descriptionItems.join(', '), style: regularStyle,),);
      }
    });

    // Build description bar widget
    return Padding(padding: EdgeInsets.only(top: 12), child:
      Container(decoration: _contentDescriptionDecoration, child:
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Expanded(child:
            Padding(padding: EdgeInsets.only(left: 12, top: 16, bottom: 16), child:
              RichText(text: TextSpan(style: regularStyle, children: descriptionSpans)),
            ),
          ),
          Visibility(visible: _canShareFilters, child:
            Event2ImageCommandButton(Styles().images.getImage('share-nodes'),
              label: Localization().getStringEx('panel.group.home2.bar.button.share.title', 'Share'),
              hint: Localization().getStringEx('panel.group.home2.bar.button.share.hint', 'Tap to share current groups'),
              contentPadding: EdgeInsets.only(left: 16, right: _canClearFilter ? (8 + 2) : 16, top: 12, bottom: 12),
              onTap: _onShareFilters
            ),
          ),
          Visibility(visible: _canClearFilter, child:
            Event2ImageCommandButton(Styles().images.getImage('close'), // size: 14
              label: Localization().getStringEx('panel.group.home2.bar.button.clear.title', 'Clear Filters'),
              hint: Localization().getStringEx('panel.group.home2.bar.button.clear.hint', 'Tap to clear current filters'),
              contentPadding: EdgeInsets.only(left: 8 + 2, right: 16 + 2, top: 12, bottom: 12),
              onTap: _onClearFilter
            ),
          ),
        ],)
    ));
  }

  Decoration get _contentDescriptionDecoration => BoxDecoration(
    color: Styles().colors.surface,
    border: Border(top: BorderSide(color: Styles().colors.disabledTextColor, width: 1))
  );

  // Search Bar

  Widget get _searchBar =>
    Container(decoration: _searchBarDecoration, padding: EdgeInsets.only(left: 16), child:
      Row(children: <Widget>[
        Expanded(child:
          _searchTextField,
        ),
        _buildSearchImageButton('close',
          label: Localization().getStringEx('panel.search.button.clear.title', 'Clear'),
          hint: Localization().getStringEx('panel.search.button.clear.hint', ''),
          onTap: _onTapSearchClear,
        ),
        _buildSearchImageButton('search',
          label: Localization().getStringEx('panel.search.button.search.title', 'Search'),
          hint: Localization().getStringEx('panel.search.button.search.hint', ''),
          onTap: _onTapSearch,
        ),
      ],),
    );

    Decoration get _searchBarDecoration => BoxDecoration(
      color: Styles().colors.white,
      border: (_commandBarVisible != true) ? Border(bottom: BorderSide(color: Styles().colors.disabledTextColor, width: 1)) : null,
    );

    Widget get _searchTextField => Semantics(
      label: Localization().getStringEx('panel.search.field.search.title', 'Search'),
      hint: Localization().getStringEx('panel.search.field.search.hint', ''),
      textField: true,
      excludeSemantics: true,
      child: TextField(
        controller: _searchTextController,
        focusNode: _searchTextNode,
        onChanged: (text) => _onSearchTextChanged(text),
        onSubmitted: (_) => _onTapSearch(),
        autofocus: true,
        cursorColor: Styles().colors.fillColorSecondary,
        keyboardType: TextInputType.text,
        style: Styles().textStyles.getTextStyle("widget.item.regular.thin"),
        decoration: InputDecoration(
          border: InputBorder.none,
        ),
      ),
    );

    Widget _buildSearchImageButton(String image, {String? label, String? hint, void Function()? onTap}) =>
      Semantics(label: label, hint: hint, button: true, excludeSemantics: true, child:
        InkWell(onTap: onTap, child:
          Padding(padding: EdgeInsets.all(12), child:
            Styles().images.getImage(image, excludeFromSemantics: true),
          ),
        ),
      );

  // Content Fetch

  Future<void> _onRefresh() {
    Analytics().logSelect(target: 'Refresh');
    return _refreshContent();
  }

  Future<void> _loadInitialContent() => _loadContent(applyErrorContent: true);
  Future<void> _reloadContent() => _loadContent(applyErrorContent: true, expandAll: true);
  Future<void> _refreshContent() => _loadContent(contentActivity: ContentActivity.refresh);
  Future<void> _updateContent() => _loadContent(restoreScrollPosition: true);

  Future<void> _loadContent({ ContentActivity contentActivity = ContentActivity.reload,  bool applyErrorContent = false, bool expandAll = false, bool restoreScrollPosition = false }) async {
    if (contentActivity.canOverride(_contentActivity) && mounted) {
      double scrollPosition = _scrollController.hasClients ? _scrollController.offset : 0;

      setState(() {
        _contentActivity = contentActivity;
      });

      GroupsLoadResult? contentResult = await Groups().loadGroupsV3(GroupsQuery(
        searchText: _searchText,
        filter: _filter?.authValidated,
        includeHidden: false,
      ));
      if (mounted && (_contentActivity == contentActivity)) {
        List<Group>? contentList = contentResult?.groups;
        if  (contentList != null) {
          LinkedHashMap<String, List<Group>> contentMap = _buildContentMap(contentList);
          setState(() {
            _contentMap = contentMap;
            _totalContentLength = contentResult?.totalCount;
            if (expandAll) {
              _storedSections = _collapsedSections = <String>{};
            } else {
              //_collapsedSections.removeWhere((section) => (contentMap.containsKey(section) == false));
            }
            _displayList = _buildDisplayList(contentMap, collapsedSections: _collapsedSections);
            _contentActivity = null;
          });
        } else if (applyErrorContent) {
          setState(() {
            _contentMap = null;
            _totalContentLength = null;
            _displayList = null;
            _contentActivity = null;
          });
        }

        if (restoreScrollPosition) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollController.jumpTo(scrollPosition);
          });
        }
      }
    }
  }

  static LinkedHashMap<String, List<Group>> _buildContentMap(List<Group> contentList) {
    LinkedHashMap<String, List<Group>> contentMap = LinkedHashMap<String, List<Group>>();
    for (Group group in contentList) {
      String section = group.section ?? '';
      List<Group>? sectionList = contentMap[section];
      if (sectionList != null) {
        sectionList.add(group);
      } else {
        contentMap[section] = <Group>[group];
      }
    }
    return contentMap;
  }

  List<_DisplayListItem> _buildDisplayList(LinkedHashMap<String, List<Group>> contentMap, { Set<String>? collapsedSections }) {
    List<_DisplayListItem> displayList = <_DisplayListItem>[];
    for (String section in contentMap.keys) {
      List<Group>? sectionList = contentMap[section];
      displayList.add(_SectionHeadingListItem(section));
      if ((collapsedSections?.contains(section) != true) && (sectionList != null) && sectionList.isNotEmpty)  {
        for (Group group in sectionList) {
          displayList.add(_GroupListItem(group));
          displayList.add(_SpacerListItem(16));
        }
      }
      displayList.add(_SplitterListItem());
    }
    return displayList;
  }

  // Notification Handlers

  void onNotification(String name, dynamic param) {
    if (name == Groups.notifyGroupCreated) {
      String? groupId = JsonUtils.stringValue(param);
      if (mounted && (groupId != null)) {
        _onGroupCreated(groupId);
      }
    }
    else if (name == Groups.notifyGroupUpdated) {
      if (mounted) {
        _updateContent();
      }
    }
    else if (name == Groups.notifyGroupDeleted) {
      if (mounted) {
        _updateContent();
      }
    }
    else if (name == Groups.notifyUserGroupsUpdated) {
      _updateContent();
    }
    else if (name == Auth2.notifyLoginChanged) {
      _updateContent();
    }
  }

  void _onGroupCreated(String groupId) {
    if (mounted) {
      late GlobalKey groupKey;
      setState(() {
        groupKey = _cardKeys[groupId] ??= GlobalKey();
        _storedFilter = _filter = null;
      });
      _loadContent(expandAll: true).then((_){
        if (mounted) {
          if (_containsGroup(groupId)) {
            WidgetsBinding.instance.addPostFrameCallback((_){
              _ensureAvailable(groupKey, onComplete: (_){
                if (mounted) {
                  BuildContext? cardContext = groupKey.currentContext;
                  if ((cardContext != null) && cardContext.mounted /* && !_isCompletelyVisibleInHeight(groupKey, parentKey: _listViewKey) */) {
                    Scrollable.ensureVisible(cardContext, duration: Duration(milliseconds: 300), curve: Curves.easeInOut).then((_){
                      _cardKeys.remove(groupId);
                    });
                  } else {
                    _cardKeys.remove(groupId);
                  }
                }
              });
            });
          } else {
            _cardKeys.remove(groupId);
          }
        }
      });
    }
  }

  void _ensureAvailable(GlobalKey targetKey, { void Function(bool result)? onComplete }) {
    if (mounted) {
      if ((targetKey.currentContext != null) && (targetKey.currentContext?.mounted == true)) {
        onComplete?.call(true);
      } else {
        double scrollOffset = _scrollController.offset;
        if (scrollOffset < _scrollController.position.maxScrollExtent) {
          double newOffset = scrollOffset + _scrollController.position.viewportDimension;
          _scrollController.animateTo(newOffset, duration: Duration(milliseconds: 1), curve: Curves.linear).then((_){
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                if (scrollOffset < _scrollController.offset) {
                  _ensureAvailable(targetKey, onComplete: onComplete);
                } else {
                  // did not scroll
                  onComplete?.call(false);
                }
              }
            });
          });
        } else {
          // no more space tp scroll
          onComplete?.call(false);
        }
      }
    }
  }

  /* bool _isCompletelyVisibleInHeight(GlobalKey childKey, { required GlobalKey parentKey} ) {
    RenderBox? childBox =  JsonUtils.cast(childKey.currentContext?.findRenderObject());
    RenderBox? parentBox =  JsonUtils.cast(parentKey.currentContext?.findRenderObject());
    if ((childBox != null) && (parentBox != null)) {
      Offset childOffset = parentBox.globalToLocal(childBox.localToGlobal(Offset.zero));
      return (0 <= childOffset.dy) && ((childOffset.dy + childBox.size.height) < parentBox.size.height);
    } else {
      return false;
    }
  } */

  bool _containsGroup(String groupId) {
    if (_contentMap != null) {
      for (List<Group> sectionGroups in _contentMap?.values ?? []) {
        if (sectionGroups.firstWhereOrNull((group) => (group.id == groupId)) != null) {
          return true;
        }
      }
    }
    return false;
  }

  // Command Handlers

  void _onFilter() {
    Analytics().logSelect(target: 'Filter');
    _authValidFilter.edit(context).then((GroupsFilter? filter){
      if ((filter != null) && mounted) {
        setState(() {
          _storedFilter = _filter = filter;
        });

        _reloadContent().then((_) =>
          AppSemantics.triggerAccessibilityFocus(_filtersButtonKey, delay: Duration(seconds: 1))
        );
      }
    });
  }


  void _onMyGroups() {
    Analytics().logSelect(target: 'My Groups');
    Set<GroupsFilterType>? currentTypes = _filter?.types;
    GroupsFilter filter = GroupsFilter(
      types: ((currentTypes != null) && currentTypes.containsAll(_myGroupsFilterTypes)) ?
        currentTypes.difference(_myGroupsFilterTypes) : (currentTypes?.union(_myGroupsFilterTypes) ?? Set.from(_myGroupsFilterTypes)),
      attributes: _filter?.attributes
    );

    if (_filter != filter) {
      setState(() {
        _storedFilter = _filter = filter;
      });

      _reloadContent().then((_) =>
        AppSemantics.triggerAccessibilityFocus(_myGroupsFilterButtonKey, delay: Duration(seconds: 1))
      );
    }



  }

  void _onSearch() {
    Analytics().logSelect(target: 'Search');
    //Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupsSearchPanel()));
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupHome2Panel(mode: _PanelMode.search,)));
  }

  void _onCreate() {
    Analytics().logSelect(target: 'Create');
    Navigator.push(context, MaterialPageRoute(builder: (context) => GroupCreatePanel()));
  }

  bool get _canShareFilters => false; // No share feature for now
    // (_filter?.isNotEmpty == true) && (_contentActivity?._hidesContent != true);

  void _onShareFilters() {
    Analytics().logSelect(target: 'Share Filters');
    // Navigator.push(context, CupertinoPageRoute(builder: (context) => QrCodePanel.fromEventFilterParam(_currentFilterParam)));
  }

  bool get _canClearFilter =>
    (_filter?.authValidated.isNotEmpty == true) && (_contentActivity?._hidesContent != true);

  void _onClearFilter() {
    Analytics().logSelect(target: 'Clear Filter');
    setState(() {
      _storedFilter = _filter = null;
    });

    _reloadContent();
  }

  void _onToggleSection(String section) {
    Analytics().logSelect(target: section);
    if (_contentMap != null) {
      setState(() {
        if (_collapsedSections.contains(section)) {
          _collapsedSections.remove(section);
        } else {
          _collapsedSections.add(section);
        }
        _storedSections = _collapsedSections;
        _displayList = _buildDisplayList(_contentMap ?? LinkedHashMap(), collapsedSections: _collapsedSections);
      });
    }
  }

  void _onSearchTextChanged(String text) {
    if ((text.trim() != _searchText) && mounted) {
      setState(() {
        _searchText = null;
        _filter = null;
        _contentMap = null;
        _totalContentLength = null;
        _displayList = null;
        _collapsedSections.clear();
      });
    }
  }

  void _onTapSearchClear() {
    Analytics().logSelect(target: "Clear");
    if (StringUtils.isEmpty(_searchTextController.text.trim())) {
      Navigator.of(context).pop();
    }
    else if (mounted) {
      _searchTextController.text = '';
      _searchTextNode.requestFocus();
      setState(() {
        _searchText = null;
        _filter = null;
        _contentMap = null;
        _totalContentLength = null;
        _displayList = null;
        _collapsedSections.clear();
      });
    }
  }

  void _onTapSearch() {
    Analytics().logSelect(target: "Search");

    String searchText = _searchTextController.text.trim();
    if (searchText.isNotEmpty) {
      FocusScope.of(context).requestFocus(FocusNode());
      Analytics().logSearch(searchText);
      setState(() {
        _searchText = searchText;
      });
      _reloadContent();
    }
  }
}

extension _GroupsFilterContentAttributes on GroupsFilter {

  static const String _detailsContentAttributeId = 'group-details';
  static const String _limitsContentAttributeId = 'group-limits';

  Future<GroupsFilter?> edit(BuildContext context) async {
    ContentAttributes? contentAttributes = _contentAttributes;
    if (contentAttributes != null) {
      Map<String, dynamic> inputSelection = MapUtils.from(attributes) ?? <String, dynamic>{};
      inputSelection[_detailsContentAttributeId] = _detailsContentAttributes;
      inputSelection[_limitsContentAttributeId] = _limitsContentAttributes;

      Map<String, GestureRecognizer> recognizers = <String, GestureRecognizer>{};

      dynamic result = await Navigator.push(context, CupertinoPageRoute(builder: (context) => ContentAttributesPanel(
        title: Localization().getStringEx('model.group.attributes.filters.header.title', 'Group Filters'),
        descriptionBuilder: (context) => _descriptionBuilder(context, recognizers: recognizers),
        contentAttributes: contentAttributes,
        selection: inputSelection,

        scope: Groups.groupsContentAttributesScope,
        sortType: ContentAttributesSortType.native,
        filtersMode: true,
        countAttributeValues: _countAttributeValues,
      )));

      recognizers.values.forEach((recognizer) => recognizer.dispose);
      Map<String, dynamic>? outputSelection = JsonUtils.mapValue(result);
      return (outputSelection != null) ? _fromAttributesSelection(outputSelection) : null;
    } else {
      return null;
    }
  }

  static Future<Map<dynamic, int?>?> _countAttributeValues({
    required ContentAttribute attribute,
    required List<ContentAttributeValue> attributeValues,
    Map<String, dynamic>? attributesSelection,
    ContentAttributes? contentAttributes,
  }) async {
    String? attributeId = attribute.id;
    if (attributeId != null) {
      GroupsFilter baseFilter = _fromAttributesSelection(attributesSelection ?? {});

      Map<String, dynamic> valueIds = <String, dynamic>{};
      Map<String, GroupsFilter> countFilters = <String, GroupsFilter>{};
      for (ContentAttributeValue attributeValue in attributeValues) {
        String? valueId = attributeValue.valueId;
        if (valueId != null) {
          valueIds[valueId] = attributeValue.value;
          countFilters[valueId] = _fromAttributesSelection({
            attributeId: attributeValue.value,
          });
        }
      }

      Map<String, int?>? counts = await Groups().countDisplayGroupsV3(countFilters, baseFilter: baseFilter, );
      return counts?.map<dynamic, int?>((String valueId, int? count) => MapEntry(valueIds[valueId], count));
    }
    return null;
  }

  static GroupsFilter _fromAttributesSelection(Map<String, dynamic> selection) {
    Set<GroupsFilterType> types = <GroupsFilterType>{
      ..._GroupsFilterTypeContentAttribute.setFromAttributesSelection(selection[_detailsContentAttributeId]) ?? <GroupsFilterType>{},
      ..._GroupsFilterTypeContentAttribute.setFromAttributesSelection(selection[_limitsContentAttributeId]) ?? <GroupsFilterType>{},
    };

    Map<String, dynamic> attributes = Map<String, dynamic>.from(selection);
    attributes.remove(_detailsContentAttributeId);
    attributes.remove(_limitsContentAttributeId);

    return GroupsFilter(
      attributes: attributes.isNotEmpty ? attributes : null,
      types: types.isNotEmpty ? types : null,
    );
  }

  List<GroupsFilterType> get _detailsContentAttributes => List<GroupsFilterType>.from(GroupsFilterGroup.details.types.where((GroupsFilterType type) => (types?.contains(type) == true)));
  List<GroupsFilterType> get _limitsContentAttributes => List<GroupsFilterType>.from(GroupsFilterGroup.limits.types.where((GroupsFilterType type) => (types?.contains(type) == true)));

  static ContentAttributes? get _contentAttributes {
    ContentAttributes? contentAttributes = ContentAttributes.fromOther(Groups().groupsContentAttributes);

    contentAttributes?.attributes?.insert(0, _detailsContentAttribute);
    contentAttributes?.attributes?.add(_limitsContentAttribute);

    return contentAttributes;
  }

  static ContentAttribute get _detailsContentAttribute => ContentAttribute(
    id: _detailsContentAttributeId,
    title: Localization().getStringEx('model.group.attributes.details.title', 'Group Details'),
    emptyHint: Localization().getStringEx('model.group.attributes.details.hint.empty', 'Select group details'),
    semanticsHint: Localization().getStringEx('model.group.attributes.details.hint.semantics', 'Double type to show group details.'),
    widget: ContentAttributeWidget.dropdown,
    scope: <String>{ Groups.groupsContentAttributesScope },
    values: List<ContentAttributeValue>.from(GroupsFilterGroup.details.types.map((GroupsFilterType value) => ContentAttributeValue(
      value: value,
      label: value.displayTitle,
      selectLabel: value.displaySelectTitle,
      enabled: value.authValid,
      group: Localization().getStringEx('model.group.attributes.details.group.visibility', 'Visibility'),
    ))),
  );

  static ContentAttribute get _limitsContentAttribute => ContentAttribute(
    id: _limitsContentAttributeId,
    title: Localization().getStringEx('model.group.attributes.limits.title', 'Limit Results To'),
    emptyHint: Localization().getStringEx('model.group.attributes.limits.hint.empty', 'Choose limits'),
    semanticsHint: Localization().getStringEx('model.group.attributes.limits.hint.semantics', 'Double tap to choose group limits.'),
    widget: ContentAttributeWidget.dropdown,
    scope: <String>{ Groups.groupsContentAttributesScope },
    values: List<ContentAttributeValue>.from(GroupsFilterGroup.limits.types.map((GroupsFilterType value) => ContentAttributeValue(
      value: value,
      label: value.displayTitle,
      selectLabel: value.displaySelectTitle,
      enabled: value.authValid,
    ))),
  );
  
  List<String> get description {
    List<String> descriptionList = <String>[];

    for (GroupsFilterType type in GroupsFilterGroup.details.types) {
      if (types?.contains(type) == true) {
        descriptionList.add(type.displayTitle);
      }
    }

    ContentAttributes? contentAttributes = Groups().groupsContentAttributes;
    List<ContentAttribute>? attributesList = contentAttributes?.attributes;
    if ((attributes?.isNotEmpty == true) && (contentAttributes != null) && (attributesList != null)) {
      for (ContentAttribute attribute in attributesList) {
        List<String>? displayAttributeValues = attribute.displaySelectedLabelsFromSelection(attributes, complete: true);
        if ((displayAttributeValues != null) && displayAttributeValues.isNotEmpty) {
          for (String attributeValue in displayAttributeValues) {
            descriptionList.add(attributeValue);
          }
        }
      }
    }

    for (GroupsFilterType type in GroupsFilterGroup.limits.types) {
      if (types?.contains(type) == true) {
        descriptionList.add(type.displayTitle);
      }
    }

    return descriptionList;
  }

  Widget _descriptionBuilder(BuildContext context, { Map<String, GestureRecognizer>? recognizers }) =>
    Padding(padding: _desciptionPadding, child: Auth2().isLoggedIn ?
      _loggedInDescriptionBuilder(context) : _loggedOutDescriptionBuilder(context, recognizers: recognizers),
    );

  Widget _loggedInDescriptionBuilder(BuildContext context) =>
    Text(_descriptionRegularTitle, style: _descriptionRegularTitleTextStyle);

  Widget _loggedOutDescriptionBuilder(BuildContext context, { Map<String, GestureRecognizer>? recognizers }) {
    final String asteriskMacro = "{{asterisk}}";
    final String linkLoginMacro = "{{link.login}}";
    final String linkPrivacyMacro = "{{link.privacy}}";

    String titleTemplate = Localization().getStringEx('model.group.attributes.filters.header.description.special', 'Choose at least one attribute to filter the groups and tap Apply to save.$asteriskMacro Some attributes are not available when you are not logged in. To enable them, $linkLoginMacro');
    List<InlineSpan> titleSpanList = StringUtils.split<InlineSpan>(titleTemplate, macros: [asteriskMacro], builder: (String entry) {
      if (entry == asteriskMacro) {
        String title = Localization().getStringEx('model.group.attributes.filters.header.description.special.asterisk', '\u20f0');
        return TextSpan(text: title, style: _descriptionSpecialTitleAsteriskTextStyle,);
      }
      else {
        return TextSpan(text: entry);
      }
    });

    String infoTemplate = Localization().getStringEx('model.group.attributes.filters.header.description.special.info', '$asteriskMacro Some attributes are not available when you are not logged in. To enable them, $linkLoginMacro with your NetID and set your linkPrivacyMacro to 4 or 5.');
    List<InlineSpan> infoSpanList = StringUtils.split<InlineSpan>(infoTemplate, macros: [linkLoginMacro, linkPrivacyMacro, asteriskMacro], builder: (String entry) {
      if (entry == linkLoginMacro) {
        String title = Localization().getStringEx('model.group.attributes.filters.header.description2.link.login', 'sign in');
        GestureRecognizer? signInRecognizer = (recognizers != null) ? (recognizers[linkLoginMacro] ??= TapGestureRecognizer()..onTap = () => _onTapSignIn(context)) : null;
        return TextSpan(text: title, recognizer: signInRecognizer, style: _descriptionSpecialInfoLinkTextStyle,);
      }
      else if (entry == linkPrivacyMacro) {
        String title = Localization().getStringEx('model.group.attributes.filters.header.description2.link.privacy', 'privacy level');
        GestureRecognizer? privacyRecognizer = (recognizers != null) ? (recognizers[linkPrivacyMacro] ??= TapGestureRecognizer()..onTap = () => _onTapProfile(context)) : null;
        return TextSpan(text: title, recognizer: privacyRecognizer, style: _descriptionSpecialInfoLinkTextStyle,);
      }
      else if (entry == asteriskMacro) {
        String title = Localization().getStringEx('model.group.attributes.filters.header.description.special.asterisk', '\u20f0');
        return TextSpan(text: title, style: _descriptionSpecialInfoAsteriskTextStyle,);
      }
      else {
        return TextSpan(text: entry);
      }
    });

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      RichText(textAlign: TextAlign.left, text:
        TextSpan(style: _descriptionSpecialTitleTextStyle, children: titleSpanList)
      ),
      Padding(padding: EdgeInsets.only(top: 8), child:
        RichText(textAlign: TextAlign.left, text:
          TextSpan(style: _descriptionSpecialInfoTextStyle, children: infoSpanList)
        ),
      )
    ],);
  }

  void _onTapSignIn(BuildContext context) {
    Analytics().logSelect(target: 'sign in');
    NotificationService().notify(ProfileHomePanel.notifySelectContent, ProfileContentType.login);
  }

  void _onTapProfile(BuildContext context) {
    Analytics().logSelect(target: 'Privacy Level');
    Navigator.push(context, CupertinoPageRoute(builder: (context) => SettingsPrivacyPanel(mode: SettingsPrivacyPanelMode.regular,)));
  }

  EdgeInsetsGeometry get _desciptionPadding => const EdgeInsets.only(top: 16, bottom: 8);

  String get _descriptionRegularTitle => Localization().getStringEx('model.group.attributes.filters.header.description.regular', 'Choose at least one attribute to filter the groups and tap Apply to save.');

  TextStyle? get _descriptionRegularTitleTextStyle => Styles().textStyles.getTextStyle("widget.description.regular");

  TextStyle? get _descriptionSpecialTitleTextStyle => Styles().textStyles.getTextStyle("widget.description.regular");
  TextStyle? get _descriptionSpecialTitleAsteriskTextStyle => Styles().textStyles.getTextStyle("widget.description.regular.highlight2");

  TextStyle? get _descriptionSpecialInfoTextStyle => Styles().textStyles.getTextStyle("widget.item.small.thin");
  TextStyle? get _descriptionSpecialInfoLinkTextStyle => Styles().textStyles.getTextStyle("widget.item.small.thin.underline2");
  TextStyle? get _descriptionSpecialInfoAsteriskTextStyle => Styles().textStyles.getTextStyle("widget.item.small.thin.highlight2");

}

enum GroupsFilterGroup { details, limits }

extension _GroupsFilterGroupContentAttribute on GroupsFilterGroup {
  static const Map<GroupsFilterType, GroupsFilterGroup> _typeGroups = <GroupsFilterType, GroupsFilterGroup> {
    GroupsFilterType.public: GroupsFilterGroup.details,
    GroupsFilterType.private: GroupsFilterGroup.details,
    GroupsFilterType.administrative: GroupsFilterGroup.details,
    GroupsFilterType.managed: GroupsFilterGroup.details,

    GroupsFilterType.admin: GroupsFilterGroup.limits,
    GroupsFilterType.member: GroupsFilterGroup.limits,
    GroupsFilterType.candidate: GroupsFilterGroup.limits,
  };

  List<GroupsFilterType> get types {
    List<GroupsFilterType> types = <GroupsFilterType>[];
    for (GroupsFilterType type in GroupsFilterType.values) {
      if (_typeGroups[type] == this) {
        types.add(type);
      }
    }
    return types;
  }
}

extension _GroupsFilterTypeContentAttribute on GroupsFilterType {

  String get displayTitle {
    switch (this) {
      case GroupsFilterType.public: return Localization().getStringEx('model.group.attributes.detail.public.title', 'Public');
      case GroupsFilterType.private: return Localization().getStringEx('model.group.attributes.detail.private.title', 'Private');
      case GroupsFilterType.administrative: return Localization().getStringEx('model.group.attributes.detail.administrative.title', 'Event Admins');
      case GroupsFilterType.managed: return Localization().getStringEx('model.group.attributes.detail.managed.title', 'University Managed');

      case GroupsFilterType.admin: return Localization().getStringEx('model.group.attributes.limit.admin.title', 'Admin');
      case GroupsFilterType.member: return Localization().getStringEx('model.group.attributes.limit.member.title', 'Member');
      case GroupsFilterType.candidate: return Localization().getStringEx('model.group.attributes.limit.candidate.title', 'Pending or Denied');
    }
  }

  String get displaySelectTitle {
    switch (this) {
      case GroupsFilterType.public: return Localization().getStringEx('model.group.attributes.detail.public.title.select', 'Public');
      case GroupsFilterType.private: return Localization().getStringEx('model.group.attributes.detail.private.title.select', 'Private');
      case GroupsFilterType.administrative: return Localization().getStringEx('model.group.attributes.detail.administrative.title.select', 'Event Admins');
      case GroupsFilterType.managed: return Localization().getStringEx('model.group.attributes.detail.managed.title.select', 'University Managed');

      case GroupsFilterType.admin: return Localization().getStringEx('model.group.attributes.limit.admin.title.select', 'Groups I administer');
      case GroupsFilterType.member: return Localization().getStringEx('model.group.attributes.limit.member.title.select', 'Groups I am member of');
      case GroupsFilterType.candidate: return Localization().getStringEx('model.group.attributes.limit.candidate.title.select', 'Groups I\'ve requested to join (pending or denied)');
    }
  }

  bool get authValid => (Auth2().isLoggedIn || (GroupsFilterAuthTypes.isAuthType(this) != true));

  static Set<GroupsFilterType>? setFromAttributesSelection(dynamic attributeSelection) {
    if (attributeSelection is List) {
      return SetUtils.from(JsonUtils.listCastValue<GroupsFilterType>(attributeSelection));
    }
    else if (attributeSelection is GroupsFilterType) {
      return <GroupsFilterType>{attributeSelection};
    }
    else {
      return null;
    }
  }
}

extension _ContentAttributeValueImpl on ContentAttributeValue {
  String? get valueId {
    dynamic v = value;
    if (v is String) {
      return v;
    }
    else if (v is GroupsFilterType) {
      return v.toCode();
    }
    else {
      return null;
    }
  }
}

extension _ContentActivityImpl on ContentActivity {
  bool get _hidesContent => ((this == ContentActivity.reload) || (this == ContentActivity.refresh));
}

extension GroupsFilterAuthTypes on Set<GroupsFilterType> {
  static const Set<GroupsFilterType> _authTypes = <GroupsFilterType> {
    GroupsFilterType.admin, GroupsFilterType.member, GroupsFilterType.candidate,
  };

  static bool isAuthType(GroupsFilterType filterType) => _authTypes.contains(filterType);

  Set<GroupsFilterType> get noAuthTypes => this.difference(_authTypes);
}

extension _GroupsFilterAuthImpl on GroupsFilter {

  GroupsFilter get authValidated => Auth2().isLoggedIn ? this : GroupsFilter(
    types: types?.noAuthTypes,
    attributes: attributes
  );
}

extension _GroupsSectionsImpl on Group {
  String? get section {
    if (title != null) {
      if (title?.isNotEmpty == true) {
        return title?[0].toUpperCase();
      } else {
        return '';
      }
    } else {
      return null;
    }
  }
}

abstract class _DisplayListItem {}

class _SectionHeadingListItem extends _DisplayListItem {
  final String section;
  _SectionHeadingListItem(this.section);
}

class _SplitterListItem extends _DisplayListItem {
  _SplitterListItem();
}

class _GroupListItem extends _DisplayListItem {
  final Group group;
  _GroupListItem(this.group);
}

class _SpacerListItem extends _DisplayListItem {
  final double height;
  _SpacerListItem(this.height);
}

extension _PanelModeImpl on _PanelMode {
  String get panelTitle {
    switch (this) {
      case _PanelMode.regular: return Localization().getStringEx('panel.group.home2.label.heading', 'Groups');
      case _PanelMode.search: return Localization().getStringEx('panel.group.search.label.heading', 'Search');
    }
  }
}