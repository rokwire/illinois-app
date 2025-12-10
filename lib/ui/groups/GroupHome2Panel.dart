
import 'dart:collection';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/ext/Group.dart';
import 'package:illinois/model/Analytics.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/ui/attributes/ContentAttributesPanel.dart';
import 'package:illinois/ui/events2/Event2Widgets.dart';
import 'package:illinois/ui/groups/GroupCreatePanel.dart';
import 'package:illinois/ui/groups/GroupSearchPanel.dart';
import 'package:illinois/ui/groups/GroupWidgets.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/content_attributes.dart';
import 'package:rokwire_plugin/model/group.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class GroupHome2Panel extends StatefulWidget with AnalyticsInfo {
  static final String routeName = 'edu.illinois.rokwire.group.home2';

  final GroupsFilter? filter;

  GroupHome2Panel({super.key, this.filter});

  static void push(BuildContext context) =>
    Navigator.push(context, CupertinoPageRoute(
      settings: RouteSettings(name: routeName),
      builder: (context) => GroupHome2Panel()
    ));

  _GroupHome2PanelState createState() => _GroupHome2PanelState();

  @override
  AnalyticsFeature? get analyticsFeature => AnalyticsFeature.Groups;
}
enum _ContentActivity { reload, refresh, extend }

class _GroupHome2PanelState extends State<GroupHome2Panel> with NotificationsListener {

  GlobalKey _filtersButtonKey = GlobalKey();
  Map<String, GlobalKey> _cardKeys = <String, GlobalKey>{};
  ScrollController _scrollController = ScrollController();

  List<Group>? _contentList;
  int? _totalContentLength;
  _ContentActivity? _contentActivity;
  bool? _lastPageLoadedAll;
  GroupsFilter? _filter;
  static const int _contentPageLength = 16;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Groups.notifyGroupCreated,
      Groups.notifyGroupUpdated,
      Groups.notifyGroupDeleted,
      Groups.notifyUserGroupsUpdated,
      Auth2.notifyLoginChanged,
    ]);

    _scrollController.addListener(_scrollListener);
    _filter = widget.filter ?? Storage().lastFilter;
    _reloadContent();
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: RootHeaderBar(title: Localization().getStringEx("panel.groups_home.label.heading", "Groups"), leading: RootHeaderBarLeading.Back,),
      body: _scaffoldBody,
      backgroundColor: Styles().colors.background,
      bottomNavigationBar: uiuc.TabBar(),
    );

  Widget get _scaffoldBody => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _commandBar,
    Expanded(child:
      RefreshIndicator(onRefresh: _onRefresh, child:
        SingleChildScrollView(controller: _scrollController, physics: AlwaysScrollableScrollPhysics(), child:
          _bodyContent,
        )
      )
    )
  ],);

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
    color: Styles().colors.white,
    border: Border.all(color: Styles().colors.disabledTextColor, width: 1)
  );

  Widget get _commandButtonsBar => Row(children: [
    Padding(padding: EdgeInsets.only(left: 16)),
    Expanded(flex: 6, child: Wrap(spacing: 8, runSpacing: 8, children: [ //Row(mainAxisAlignment: MainAxisAlignment.start, children: [
      MergeSemantics(key: _filtersButtonKey, child:
        Semantics(/* TBD: value: _currentFilterParam.descriptionText, hint: _filtersButtonHint,*/ child:
          Event2FilterCommandButton(
            title: Localization().getStringEx('panel.group.home2.bar.button.filter.title', 'Filter'),
            leftIconKey: 'filters',
            rightIconKey: 'chevron-right',
            onTap: _onFilter,
          )
        )
      ),
    ])),
    Expanded(flex: 4, child: Wrap(alignment: WrapAlignment.end, crossAxisAlignment: WrapCrossAlignment.center, verticalDirection: VerticalDirection.up, children: [
      Visibility(visible: Auth2().isOidcLoggedIn, child:
        Event2ImageCommandButton(Styles().images.getImage('plus-circle'),
          label: Localization().getStringEx('panel.group.home2.bar.button.create.title', 'Create'),
          hint: Localization().getStringEx('panel.group.home2.bar.button.create.hint', 'Tap to create group'),
          contentPadding: EdgeInsets.only(left: 8, right: 8, top: 12, bottom: 12),
          onTap: _onCreate
        ),
      ),
      Event2ImageCommandButton(Styles().images.getImage('search'),
        label: Localization().getStringEx('panel.group.home2.bar.button.search.title', 'Search'),
        hint: Localization().getStringEx('panel.group.home2.bar.button.search.hint', 'Tap to search groups'),
        contentPadding: EdgeInsets.only(left: 8, right: 16, top: 12, bottom: 12),
        onTap: _onSearch
      ),
    ])),
  ],);

  Widget get _contentDescriptionBar {
    // Build description map
    LinkedHashMap<String, List<String>>? descriptionMap = LinkedHashMap<String, List<String>>();

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
    color: Styles().colors.white,
    border: Border(top: BorderSide(color: Styles().colors.disabledTextColor, width: 1))
  );

  Widget get _bodyContent {
    if (_contentActivity == _ContentActivity.reload) {
      return _loadingContent;
    }
    else if (_contentActivity == _ContentActivity.refresh) {
      return Container();
    }
    else if (_contentList == null) {
      return _buildMessageContent(Localization().getStringEx('panel.group.home2.failed.text', 'Failed to load groups'),
        title: Localization().getStringEx('common.label.failed', 'Failed')
      );
    }
    else if (_contentList?.length == 0) {
      return _buildMessageContent(Localization().getStringEx('panel.group.home2.empty.text', 'There are no groups matching the selected filters.'));
    }
    else {
      return _listContent;
    }
  }

  Widget get _listContent {
    List<Widget> cardsList = <Widget>[];
    List<Group> groups = _contentList ?? [];
    for (Group group in groups) {
      cardsList.add(Padding(padding: EdgeInsets.only(top: cardsList.isNotEmpty ? 16 : 0), child:
        GroupCard(group,
          key: _cardKeys[group.id],
          margin: EdgeInsets.zero,
          displayType: GroupCardDisplayType.allGroups,
        ),
      ),);
    }
    if (_contentActivity == _ContentActivity.extend) {
      cardsList.add(Padding(padding: EdgeInsets.only(top: cardsList.isNotEmpty ? 16 : 0), child:
        _extendingIndicator
      ));
    }
    return Padding(padding: EdgeInsets.all(16), child:
      Column(children:  cardsList,)
    );
  }

  Widget _buildMessageContent(String message, { String? title }) => Center(child:
    Padding(padding: EdgeInsets.symmetric(horizontal: 32, vertical: _screenHeight / 6), child:
      Column(children: [
        (title != null) ? Padding(padding: EdgeInsets.only(bottom: 12), child:
          Text(title, textAlign: TextAlign.center, style: Styles().textStyles.getTextStyle('widget.item.medium.fat'),)
        ) : Container(),
        Text(message, textAlign: TextAlign.center, style: Styles().textStyles.getTextStyle((title != null) ? 'widget.item.regular.thin' : 'widget.item.medium.fat'),),
      ],),
    )
  );

  Widget get _loadingContent => Column(children: [
    Padding(padding: EdgeInsets.symmetric(vertical: _screenHeight / 4), child:
      SizedBox(width: 32, height: 32, child:
        CircularProgressIndicator(color: Styles().colors.fillColorSecondary,)
      )
    ),
    Container(height: _screenHeight / 2,)
  ],);

  Widget get _extendingIndicator => Container(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 32), child:
    Align(alignment: Alignment.center, child:
      SizedBox(width: 24, height: 24, child:
        CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors.fillColorSecondary),),),),);

  double get _screenHeight => MediaQuery.of(context).size.height;

  // Content Fetch

  Future<void> _onRefresh() async {
    Analytics().logSelect(target: 'Refresh');
    return _refreshContent();
  }

  void _scrollListener() {
    if ((_scrollController.offset >= _scrollController.position.maxScrollExtent) && (_hasMoreContent != false) && (_contentActivity == null)) {
      _extendContent();
    }
  }

  bool? get _hasMoreContent => (_totalContentLength != null) ? (_listSafeContentLength < _totalSafeContentLength) : (_lastPageLoadedAll != false);
  int get _totalSafeContentLength => _totalContentLength ?? 0;
  int get _listSafeContentLength => _contentList?.length ?? 0;
  int get _refreshContentLength => max(_listSafeContentLength, _contentPageLength);

  Future<void> _reloadContent({ int limit = _contentPageLength }) async {
    if ((_contentActivity != _ContentActivity.reload) && mounted) {
      setState(() {
        _contentActivity = _ContentActivity.reload;
      });

      GroupsLoadResult? contentResult = await Groups().loadGroupsV3(GroupsQuery(
        filter: _filter?.authValidated, offset: 0, limit: limit,
      ));
      List<Group>? contentList = contentResult?.groups;
      int? totalContentLength = contentResult?.totalCount;

      if (mounted && (_contentActivity == _ContentActivity.reload)) {
        setState(() {
          _contentList = (contentList != null) ? List<Group>.from(contentList) : null;
          _totalContentLength = totalContentLength;
          _lastPageLoadedAll = (contentList != null) ? (contentList.length >= limit) : null;
          _contentActivity = null;
        });
      }
    }
  }

  Future<void> _refreshContent() async {
    if (((_contentActivity != _ContentActivity.reload) && (_contentActivity != _ContentActivity.refresh)) && mounted) {
      setState(() {
        _contentActivity = _ContentActivity.refresh;
      });

      int queryLimit = max(_contentList?.length ?? 0, _contentPageLength);
      GroupsLoadResult? contentResult = await Groups().loadGroupsV3(GroupsQuery(
        filter: _filter?.authValidated, offset: 0, limit: queryLimit,
      ));
      List<Group>? contentList = contentResult?.groups;
      int? totalContentLength = contentResult?.totalCount;

      if (mounted && (_contentActivity == _ContentActivity.refresh)) {
        setState(() {
          if (contentList != null) {
            _contentList = List<Group>.from(contentList);
            _lastPageLoadedAll = (contentList.length >= queryLimit);
          }
          if (totalContentLength != null) {
            _totalContentLength = totalContentLength;
          }
          _contentActivity = null;
        });
      }
    }
  }
  
  Future<void> _extendContent() async {
    if ((_contentActivity == null) && mounted) {
      setState(() {
        _contentActivity = _ContentActivity.extend;
      });

      int queryOffset = _contentList?.length ?? 0;
      int queryLimit = _contentPageLength;
      GroupsLoadResult? contentResult = await Groups().loadGroupsV3(GroupsQuery(
        filter: _filter?.authValidated, offset: queryOffset, limit: queryLimit,
      ));
      List<Group>? contentList = contentResult?.groups;
      int? totalContentLength = contentResult?.totalCount;

      if (mounted && (_contentActivity == _ContentActivity.extend)) {
        setState(() {
          if (contentList != null) {
            if (_contentList != null) {
              _contentList?.addAll(contentList);
            } else {
              _contentList = List<Group>.from(contentList);
            }
            _lastPageLoadedAll = (contentList.length >= queryLimit);
          }
          if (totalContentLength != null) {
            _totalContentLength = totalContentLength;
          }
          _contentActivity = null;
        });
      }
    }
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
      String? groupId = JsonUtils.stringValue(param);
      if (mounted && ((groupId == null) || (_contentList?.containsGroupId(groupId) == true))) {
        _reloadContent(limit: _refreshContentLength);
      }
    }
    else if (name == Groups.notifyGroupDeleted) {
      String? groupId = JsonUtils.stringValue(param);
      if (mounted && (groupId != null) && (_contentList?.containsGroupId(groupId) == true)) {
        _reloadContent(limit: max(_refreshContentLength - 1, _contentPageLength));
      }
    }
    else if (name == Groups.notifyUserGroupsUpdated) {
      _reloadContent(limit: _refreshContentLength);
    }
    else if (name == Auth2.notifyLoginChanged) {
      _reloadContent(limit: _refreshContentLength);
    }
  }

  void _onGroupCreated(String groupId) {
    setStateIfMounted(() {
      _cardKeys[groupId] = GlobalKey();
    });
    _reloadContent(limit: max(_totalSafeContentLength, _refreshContentLength) + 1 /* _refreshContentLength + 1 */ /* TBD: ensure groupId visibility */).then((_){
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          BuildContext? cardContext = _cardKeys[groupId]?.currentContext;
          if ((cardContext != null) && cardContext.mounted) {
            Scrollable.ensureVisible(cardContext, duration: Duration(milliseconds: 300)).then((_){
              setStateIfMounted((){
                _cardKeys.remove(groupId);
              });
            });
          }
        });
      }
    });
  }

  // Command Handlers

  void _onFilter() {
    Analytics().logSelect(target: 'Filter');
    GroupsFilter filter = _filter?.authValidated ?? GroupsFilter();
    filter.edit(context).then((GroupsFilter? filter){
      if ((filter != null) && mounted) {
        setState(() {
          _filter = filter;
        });
        Storage().lastFilter = filter;

        _reloadContent().then((_) =>
          AppSemantics.triggerAccessibilityFocus(_filtersButtonKey, delay: Duration(seconds: 1))
        );
      }
    });
  }

  void _onSearch() {
    Analytics().logSelect(target: 'Search');
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupsSearchPanel()));
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
      _filter = null;
    });
    Storage().lastFilter = null;

    _reloadContent();
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

      dynamic result = await Navigator.push(context, CupertinoPageRoute(builder: (context) => ContentAttributesPanel(
        title: Localization().getStringEx('model.group.attributes.filters.header.title', 'Group Filters'),
        description: Localization().getStringEx('model.group.attributes.filters.header.description', 'Choose at least one attribute to filter the groups and tap Apply to save.'),
        contentAttributes: contentAttributes,
        selection: inputSelection,

        scope: Groups.groupsContentAttributesScope,
        sortType: ContentAttributesSortType.native,
        filtersMode: true,
        countAttributeValues: _countAttributeValues,
      )));

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

      Map<String, int?>? counts = await Groups().countGroupsV3(countFilters, baseFilter: baseFilter, );
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
      value: value, label: value.displayTitle, group: Localization().getStringEx('model.group.attributes.details.group.visibility', 'Visibility'),
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
      value: value, label: value.displayTitle,
    ))),
  );
  
  List<String> get description {
    List<String> descriptionList = <String>[];

    for (GroupsFilterType type in GroupsFilterGroup.details.types) {
      if (types?.contains(type) == true) {
        descriptionList.add(type.displayHint);
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
        descriptionList.add(type.displayHint);
      }
    }

    return descriptionList;
  }
}

enum GroupsFilterGroup { details, limits }

extension _GroupsFilterGroupContentAttribute on GroupsFilterGroup {
  static const Map<GroupsFilterType, GroupsFilterGroup> _typeGroups = <GroupsFilterType, GroupsFilterGroup> {
    GroupsFilterType.public: GroupsFilterGroup.details,
    GroupsFilterType.private: GroupsFilterGroup.details,
    GroupsFilterType.eventAdmin: GroupsFilterGroup.details,
    GroupsFilterType.managed: GroupsFilterGroup.details,
  //GroupsFilterType.administrative:

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
      case GroupsFilterType.eventAdmin: return Localization().getStringEx('model.group.attributes.detail.event_admins.title', 'Event Admins');
      case GroupsFilterType.managed: return Localization().getStringEx('model.group.attributes.detail.managed.title', 'Univerity Managed');
      case GroupsFilterType.administrative: return Localization().getStringEx('model.group.attributes.detail.administrative.title', 'Administrative');

      case GroupsFilterType.admin: return Localization().getStringEx('model.group.attributes.limit.admin.title', 'Groups I administer');
      case GroupsFilterType.member: return Localization().getStringEx('model.group.attributes.limit.member.title', 'Groups I am member of');
      case GroupsFilterType.candidate: return Localization().getStringEx('model.group.attributes.limit.candidate.title', 'Groups I\'ve requested to join (pending or denied)');
    }
  }

  String get displayHint {
    switch (this) {
      case GroupsFilterType.public: return Localization().getStringEx('model.group.attributes.detail.public.hint', 'Public');
      case GroupsFilterType.private: return Localization().getStringEx('model.group.attributes.detail.private.hint', 'Private');
      case GroupsFilterType.eventAdmin: return Localization().getStringEx('model.group.attributes.detail.event_admins.hint', 'Event Admins');
      case GroupsFilterType.managed: return Localization().getStringEx('model.group.attributes.detail.managed.hint', 'Univerity Managed');
      case GroupsFilterType.administrative: return Localization().getStringEx('model.group.attributes.detail.administrative.hint', 'Administrative');

      case GroupsFilterType.admin: return Localization().getStringEx('model.group.attributes.limit.admin.hint', 'Admin');
      case GroupsFilterType.member: return Localization().getStringEx('model.group.attributes.limit.member.hint', 'Member');
      case GroupsFilterType.candidate: return Localization().getStringEx('model.group.attributes.limit.candidate.hint', 'Requested to Join');
    }
  }

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

extension _ContentActivityImpl on _ContentActivity {
  bool get _hidesContent => ((this == _ContentActivity.reload) || (this == _ContentActivity.refresh));
}

extension _GroupsStorageImpl on Storage {
  GroupsFilter? get lastFilter =>
    GroupsFilter.fromJson(JsonUtils.decodeMap(groupsFilter));

  set lastFilter(GroupsFilter? filter) =>
    groupsFilter = JsonUtils.encode(filter?.toJson());
}

extension GroupsFilterAuthTypes on Set<GroupsFilterType> {
  static const Set<GroupsFilterType> _authTypes = <GroupsFilterType> {
    GroupsFilterType.eventAdmin, GroupsFilterType.admin, GroupsFilterType.member, GroupsFilterType.candidate,
  };

  Set<GroupsFilterType> get noAuthTypes => this.difference(_authTypes);
}

extension _GroupsFilterAuthImpl on GroupsFilter {

  GroupsFilter get authValidated => Auth2().isLoggedIn ? this : GroupsFilter(
    types: types?.noAuthTypes,
    attributes: attributes
  );
}