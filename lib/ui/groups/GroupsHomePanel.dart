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

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:illinois/ext/Group.dart';
import 'package:illinois/model/Analytics.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/ui/attributes/ContentAttributesPanel.dart';
import 'package:illinois/ui/profile/ProfileHomePanel.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:illinois/ui/widgets/TextTabBar.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/content_attributes.dart';
import 'package:rokwire_plugin/model/group.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/groups.dart' as rokwire;
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:illinois/ui/groups/GroupCreatePanel.dart';
import 'package:illinois/ui/groups/GroupSearchPanel.dart';
import 'package:illinois/ui/groups/GroupWidgets.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/ui/widgets/triangle_painter.dart';
import 'package:rokwire_plugin/ui/panels/modal_image_panel.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/service/styles.dart';

class GroupsHomePanel extends StatefulWidget with AnalyticsInfo {
  static final String routeName = 'groups_home_panel';
  final rokwire.GroupsContentType? contentType;

  GroupsHomePanel({Key? key, this.contentType}) : super(key: key);
  
  _GroupsHomePanelState createState() => _GroupsHomePanelState();

  @override
  AnalyticsFeature? get analyticsFeature {
    switch (contentType) {
      case rokwire.GroupsContentType.my:  return AnalyticsFeature.GroupsMy;
      case rokwire.GroupsContentType.all: return AnalyticsFeature.GroupsAll;
      case null:                          return AnalyticsFeature.Groups;
    }
  }
}

class _GroupsHomePanelState extends State<GroupsHomePanel> with TickerProviderStateMixin, NotificationsListener {
  final Color _dimmedBackgroundColor = Color(0x99000000);

  bool _loadingProgress = false;
  Set<Completer<void>>? _reloadGroupsContentCompleters;

  String? _newGroupId;
  GlobalKey? _newGroupKey;

  rokwire.GroupsContentType? _selectedContentType;

  GestureRecognizer? _loginRecognizer;
  GestureRecognizer? _selectAllRecognizer;

  List<Group>? _allGroups;
  List<Group>? _userGroups;

  Map<String, dynamic> _contentAttributesSelection = <String, dynamic>{};

  ScrollController _scrollController = ScrollController();
  late TabController _tabController;
  int _selectedTab = 0;

  final List<String> _tabNames = [
    Localization().getStringEx("panel.groups_home.button.all_groups.title", 'All Groups'),
    Localization().getStringEx("panel.groups_home.button.my_groups.title", 'My Groups'),
  ];

  @override
  void initState() {
    if (widget.contentType == rokwire.GroupsContentType.my) {
      _selectedTab = 1;
    }
    _tabController = TabController(length: 2, initialIndex: _selectedTab, vsync: this);
    _tabController.addListener(_onTabChanged);

    super.initState();
    NotificationService().subscribe(this, [
      Groups.notifyUserMembershipUpdated,
      Groups.notifyGroupCreated,
      Groups.notifyGroupUpdated,
      Groups.notifyGroupDeleted,
      Groups.notifyUserGroupsUpdated,
      Auth2.notifyLoginChanged,
      FlexUI.notifyChanged,
      Connectivity.notifyStatusChanged,
    ]);
    _loginRecognizer = TapGestureRecognizer()..onTap = _onTapLogin;
    _selectAllRecognizer = TapGestureRecognizer()..onTap = _onSelectAllGroups;
    _selectedContentType = widget.contentType;
    _reloadGroupsContent();
    super.initState();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _scrollController.dispose();

    NotificationService().unsubscribe(this);
    _loginRecognizer?.dispose();
    _selectAllRecognizer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: RootHeaderBar(title: Localization().getStringEx("panel.groups_home.label.heading","Groups"), leading: RootHeaderBarLeading.Back,),
      body: _buildContent(),
      backgroundColor: Styles().colors.background,
      bottomNavigationBar: uiuc.TabBar(),
    );
  }

  ///////////////////////////////////
  // Data Loading

  Future<void> _reloadGroupsContent() async {
    if (!Connectivity().isOffline) {
      if (_reloadGroupsContentCompleters == null) {
        _reloadGroupsContentCompleters = <Completer<void>>{};

        _allGroups = null;
        setState(() {
          _loadingProgress = true;
        });;
        List<List<Group>?> result = await Future.wait([
          _loadUserGroups(),
          _loadAllGroups(),
        ]);
        _userGroups = (0 < result.length) ? result[0] : Groups().userGroups;
        _allGroups = (1 < result.length) ? result[1] : null;
        setStateIfMounted(() {
          _loadingProgress = false;
          _selectedContentType ??= (CollectionUtils.isNotEmpty(_userGroups) ? rokwire.GroupsContentType.my : rokwire.GroupsContentType.all);
        });

        if (_reloadGroupsContentCompleters != null) {
          Set<Completer<void>> loginCompleters = _reloadGroupsContentCompleters!;
          _reloadGroupsContentCompleters = null;
          for (Completer<void> completer in loginCompleters) {
            completer.complete();
          }
        }
      }
      else {
        Completer<void> completer = Completer<bool?>();
        _reloadGroupsContentCompleters?.add(completer);
        return completer.future;
      }
    }
  }

  Future<List<Group>?> _loadUserGroups() async =>
    Auth2().isLoggedIn ? Groups().loadGroups(contentType: rokwire.GroupsContentType.my, attributes: _contentAttributesSelection,) : null;

  Future<List<Group>?> _loadAllGroups() async =>
    Groups().loadGroups(contentType: rokwire.GroupsContentType.all, attributes: _contentAttributesSelection,);

  void _applyUserGroups() {
    _userGroups = Groups().userGroups;
    _updateState();
  }

  void _buildMyGroupsAndPending({List<Group>? myGroups, List<Group>? myPendingGroups}) {
    if (_userGroups != null) {
      for (Group group in _userGroups!) {
        Member? currentUserAsMember = group.currentMember;
        if (currentUserAsMember != null) {
          if (currentUserAsMember.isMemberOrAdmin) {
            myGroups?.add(group);
          }
          else if (currentUserAsMember.isPendingMember) {
            myPendingGroups?.add(group);
          }
        }
      }
    }
  }

  void _updateState() {
    if (mounted) {
      setState(() {});
    }
  }

  ///////////////////////////////////
  // Content Building

  Widget _buildContent(){
    List<Widget> tabs = _tabNames.map((e) => TextTabButton(title: e)).toList();
    return Column(children: <Widget>[
      TextTabBar(tabs: tabs, controller: _tabController, isScrollable: false, onTap: (index){_onTabChanged();}),
      _buildFunctionalBar(),
      _loadingProgress ? Center(child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors.fillColorSecondary), ),) : Expanded(
        child: TabBarView(
          controller: _tabController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            RefreshIndicator(
              onRefresh: _onPullToRefresh,
              child: SingleChildScrollView(
                controller: _scrollController,
                child: _buildAllGroupsContent(),
              ),
            ),
            RefreshIndicator(
              onRefresh: _onPullToRefresh,
              child: SingleChildScrollView(
                controller: _scrollController,
                child: _buildMyGroupsContent(),
              ),
            ),
          ],
        ),
      ),
    ]);
  }

  Widget _buildFunctionalBar() {
    return Padding(padding: const EdgeInsets.only(left: 16), child:
    Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Row(children: <Widget>[ Expanded(child:
        Wrap(alignment: WrapAlignment.spaceBetween, runAlignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.start, children: <Widget>[
          _buildFiltersBar(),
          _buildGroupsCountBar(),
          _buildCommandsBar(),
        ],),
      )]),
      _buildContentAttributesDescription(),
    ],)
    );
  }

  Widget _buildFiltersBar() {
    String filtersTitle = Localization().getStringEx("panel.groups_home.filter.filter.label", "Filters");
    
    return Row(mainAxisAlignment: MainAxisAlignment.start, mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.center, children: <Widget>[
      Visibility(visible: Groups().groupsContentAttributes?.isNotEmpty ?? false, child:
        Padding(padding: EdgeInsets.only(right: 6), child:
          InkWell(onTap: _onFilterAttributes, child:
            Padding(padding: EdgeInsets.only(top: 14, bottom: 8), child:
              Row(children: [
                Text(filtersTitle, style:  Styles().textStyles.getTextStyle("widget.title.variant.regular.fat")),
                Padding(padding: EdgeInsets.symmetric(horizontal: 4), child:
                  Styles().images.getImage('caret-right', width: 6, height: 10) ?? Container(),
                )
              ],),
              /*Container(
                decoration: BoxDecoration(border:
                  Border(bottom: BorderSide(color: Styles().colors.fillColorSecondary, width: 1.5, ))
                ),
                child: Text(filtersTitle, style: TextStyle(
                  fontFamily: Styles().fontFamilies.bold, fontSize: 16, color: Styles().colors.fillColorPrimary,
                ),),
              ),*/
              /*Text(filtersTitle, style: TextStyle(
                fontFamily: Styles().fontFamilies.bold, fontSize: 16, color: Styles().colors.fillColorPrimary,
                decoration: TextDecoration.underline, decorationColor: Styles().colors.fillColorSecondary, decorationStyle: TextDecorationStyle.solid, decorationThickness: 1
              ),)*/
            )
          ),
        ),
      ),
    ],);
  }

  Widget _buildContentAttributesDescription() {
    if (_selectedContentType == rokwire.GroupsContentType.all) {
      List<InlineSpan> attributesList = <InlineSpan>[];
      List<ContentAttribute>? attributes = Groups().groupsContentAttributes?.attributes;
      TextStyle? boldStyle = Styles().textStyles.getTextStyle("widget.card.detail.light.small.fat");
      TextStyle? regularStyle = Styles().textStyles.getTextStyle("widget.card.detail.light.small.regular");
      if (_contentAttributesSelection.isNotEmpty && (attributes != null)) {
        for (ContentAttribute attribute in attributes) {
          List<String>? displayAttributeValues = attribute.displaySelectedLabelsFromSelection(_contentAttributesSelection, complete: true);
          if ((displayAttributeValues != null) && displayAttributeValues.isNotEmpty) {
            displayAttributeValues = List.from(displayAttributeValues.map((String attribute) => "'$attribute'"));
            if (attributesList.isNotEmpty) {
              attributesList.add(TextSpan(text: " and " , style : regularStyle,));
            }
            attributesList.addAll(<InlineSpan>[
              TextSpan(text: "${attribute.displayTitle}" , style : boldStyle,),
              TextSpan(text: " is ${displayAttributeValues.join(' or ')}" , style : regularStyle,),
            ]);
          }
        }
      }

      return attributesList.isNotEmpty ?
        Padding(padding: EdgeInsets.only(top: 0, bottom: 4, right: 12), child:
          Row(children: [ Expanded(child:
            RichText(text: TextSpan(style: regularStyle, children: attributesList))
          ),],)
        ) : Container();
    } else {
      return Container();
    }
  }

  Widget _buildGroupsCountBar() {
    int groupsCount = 0;
    switch (_selectedContentType) {
      case rokwire.GroupsContentType.all: groupsCount = _allGroups?.length ?? 0; break;
      case rokwire.GroupsContentType.my: groupsCount = _userGroups?.length ?? 0; break;
      default: break;
    }
    String groupsLabel = (groupsCount == 1)
        ? Localization().getStringEx("panel.groups_home.groups.count.single.label", "group")
        : Localization().getStringEx("panel.groups_home.groups.count.plural.label", "groups");
    String countLabel = '$groupsCount $groupsLabel';
    return Padding(padding: EdgeInsets.symmetric(horizontal: 7, vertical: 14), child:
      Text(countLabel, style: Styles().textStyles.getTextStyle("widget.title.regular.fat"))
    );
  }

  Widget _buildCommandsBar() {
    const double defaultIconPadding = 14;
    const double innerIconPadding = 8;
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Visibility(
          visible: _hasOptions,
          child: IconButton(
              padding:
              EdgeInsets.only(left: defaultIconPadding, top: defaultIconPadding, bottom: defaultIconPadding),
              constraints: BoxConstraints(),
              style: ButtonStyle(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              icon: Styles().images.getImage('more', excludeFromSemantics: true) ?? Container(),
              onPressed: _onTapOptions),
        ),
        Visibility(
          visible: _canCreateGroup,
          child: IconButton(
              padding:
                  EdgeInsets.only(left: defaultIconPadding, top: defaultIconPadding, bottom: defaultIconPadding, right: innerIconPadding),
              constraints: BoxConstraints(),
              style: ButtonStyle(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              icon: Styles().images.getImage('plus-circle', excludeFromSemantics: true) ?? Container(),
              onPressed: _onTapCreate),
        ),
        Semantics(
          label: Localization().getStringEx("panel.groups_home.button.search.title", "Search"),
          child: IconButton(
            padding:
                EdgeInsets.only(left: innerIconPadding, top: defaultIconPadding, bottom: defaultIconPadding, right: defaultIconPadding),
            constraints: BoxConstraints(),
            style: ButtonStyle(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            icon: Styles().images.getImage('search', excludeFromSemantics: true) ?? Container(),
            onPressed: () {
              Analytics().logSelect(target: "Search");
              Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupsSearchPanel()));
            },
          ),
        )
      ],
    );
  }

  void _onFilterAttributes() {
    Analytics().logSelect(target: 'Filters');
    Navigator.push(context, CupertinoPageRoute(builder: (context) => ContentAttributesPanel(
      title: Localization().getStringEx('panel.group.attributes.filters.header.title', 'Group Filters'),
      description: Localization().getStringEx('panel.group.attributes.filters.header.description', 'Choose one or more attributes to filter the list of groups.'),
      scope: Groups.groupsContentAttributesScope,
      contentAttributes: Groups().groupsContentAttributes,
      selection: _contentAttributesSelection,
      sortType: ContentAttributesSortType.alphabetical,
      filtersMode: true,
    ))).then((selection) {
      if ((selection != null) && mounted) {
        setState(() {
          _contentAttributesSelection = selection;
        });
        _reloadGroupsContent();
      }
    });
  }

  Widget _buildMyGroupsContent(){
    if (!Auth2().isLoggedIn) {
      return _buildLoggedOutContent();
    }
    else {
      List<Group> myGroups = <Group>[], myPendingGroups = <Group>[];
      _buildMyGroupsAndPending(myGroups: myGroups, myPendingGroups: myPendingGroups);

      if (CollectionUtils.isEmpty(myGroups) && CollectionUtils.isEmpty(myPendingGroups)) {
        return _buildEmptyMyGroupsContent();
      }
      else {
        return Column(children: [
          _buildMyGroupsSection(myGroups),
          _buildMyPendingGroupsSection(myPendingGroups),
        ],);
      }
    }
  }

  Widget _buildMyGroupsSection(List<Group> myGroups) {
    List<Widget> widgets = [];
    if(CollectionUtils.isNotEmpty(myGroups)) {
      for (Group group in myGroups) {
        if (group.isVisible) {
          EdgeInsetsGeometry padding = widgets.isNotEmpty ? const EdgeInsets.symmetric(vertical: 8) : const EdgeInsets.only(top: 6, bottom: 8);
          widgets.add(Padding(padding: padding, child:
            GroupCard(
              group: group,
              displayType: GroupCardDisplayType.myGroup,
              onImageTap: () { _onTapImage(group); },
              key: _getGroupKey(group),
            ),
          ));
        }
      }
      widgets.add(Container(height: 8,));
    }
    return Column(children: widgets,);
  }

  Widget _buildMyPendingGroupsSection(List<Group> myPendingGroups) {
    if(CollectionUtils.isNotEmpty(myPendingGroups)) {
      List<Widget> widgets = [];
      widgets.add(Container(height: 8));
      widgets.add(Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
        Text(Localization().getStringEx("panel.groups_home.label.pending", "Pending"), style: Styles().textStyles.getTextStyle("widget.title.large.fat"))
        )
      );
      widgets.add(Container(height: 8,));
      for (Group group in myPendingGroups) {
        if (group.isVisible) {
          widgets.add(Padding(padding: const EdgeInsets.symmetric(vertical: 8), child:
            GroupCard(
              group: group,
              displayType: GroupCardDisplayType.myGroup,
              key: _getGroupKey(group),
            ),
          ));
        }
      }
      return Stack(children: [
          Container(height: 112, color: Styles().colors.backgroundVariant, child:
            Column(children: [
              Container(height: 80,),
              Container(height: 32, child:
                CustomPaint(painter:
                  TrianglePainter(painterColor: Styles().colors.background), child:
                    Container(),
                ),
              ),
            ],)
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: widgets,)
        ],);
    }
    return Container();
  }

  Widget _buildAllGroupsContent(){
    if(CollectionUtils.isNotEmpty(_allGroups)){
      List<Widget> widgets = [];
      for(Group group in _allGroups!) {
        if (group.isVisible) {
          EdgeInsetsGeometry padding = widgets.isNotEmpty ? const EdgeInsets.symmetric(vertical: 8) : const EdgeInsets.only(top: 6, bottom: 8);
          widgets.add(Padding(padding: padding, child:
            GroupCard(
              group: group,
              key: _getGroupKey(group),
              displayType: GroupCardDisplayType.allGroups,
            ),
          ));
        }
      }
      return Column(children: widgets,);
    }
    else{
      String text;
      if (_allGroups == null) {
        text = Localization().getStringEx("panel.groups_home.label.all_groups.failed", "Failed to load groups");
      }
      else if (_allGroups!.isEmpty) {
        text = Localization().getStringEx("panel.groups_home.label.all_groups.empty", "There are no groups matching your filters.");
      }
      else {
        text = Localization().getStringEx("panel.groups_home.label.all_groups.filtered.empty", "No groups match the selected filter");
      }
      return Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 30), child:
        Text(text, style: Styles().textStyles.getTextStyle("widget.item.regular.thin")),
      );
    }
  }

  Widget _buildLoggedOutContent() {
    final String linkLoginMacro = "{{link.login}}";
    String messageTemplate = Localization().getStringEx("panel.groups_home.label.my_groups.logged_out", "You are not logged in. To access your groups, you need to $linkLoginMacro first.");
    List<String> messages = messageTemplate.split(linkLoginMacro);
    List<InlineSpan> spanList = <InlineSpan>[];
    if (0 < messages.length)
      spanList.add(TextSpan(text: messages.first));
    for (int index = 1; index < messages.length; index++) {
      spanList.add(TextSpan(text: Localization().getStringEx("panel.groups_home.label.my_groups.logged_out.link.login", "sign in"), style : Styles().textStyles.getTextStyle("widget.link.button.title.regular"),
        recognizer: _loginRecognizer, ));
      spanList.add(TextSpan(text: messages[index]));
    }

    return Container(padding: EdgeInsets.symmetric(horizontal: 48, vertical: 32), child:
      RichText(textAlign: TextAlign.left, text:
        TextSpan(style: Styles().textStyles.getTextStyle("widget.message.light.regular"), children: spanList)
      )
    );
  }

  void _onTapLogin() {
    Analytics().logSelect(target: "sign in");
    ProfileHomePanel.present(context, content: ProfileContent.login,);
  }


  Widget _buildEmptyMyGroupsContent() {
    return Container(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 30), child:
      RichText(textAlign: TextAlign.left, text:
        TextSpan(style: Styles().textStyles.getTextStyle("widget.message.light.regular"), children:[
          TextSpan(text:Localization().getStringEx("panel.groups_home.label.my_groups.empty", "You are not a member of any group. To join or create a group, see .")),
          TextSpan(text: Localization().getStringEx("panel.groups_home.label.my_groups.empty.link.all_groups", "All Groups"), style : Styles().textStyles.getTextStyle("widget.link.button.title.regular"),
            recognizer: _selectAllRecognizer, ),
          TextSpan(text:"."),
        ])
      )
    );
  }

  Key? _getGroupKey(Group group) {
    if ((_newGroupId != null) && (_newGroupId == group.id)) {
      return _newGroupKey;
    }
    else {
      return null;
    }
  }

  void _onSelectAllGroups(){
    if(_selectedContentType != rokwire.GroupsContentType.all){
      setState(() {
        _selectedContentType = rokwire.GroupsContentType.all;
      });
    }
  }

  void _onTapCreate(){
    Analytics().logSelect(target: "Create Group");
    Navigator.push(context, MaterialPageRoute(builder: (context)=>GroupCreatePanel()));
  }

  void _onTapOptions(){
    showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        isScrollControlled: true,
        isDismissible: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (context) {
          return Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 17),
              child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
                Container(
                  height: 24,
                ),
                Visibility(
                    visible: _canSyncAuthmanGroups,
                    child: RibbonButton(
                        leftIconKey: "info",
                        label: Localization().getStringEx("", "Sync Authman Groups"),//TBD localize
                        onTap: () {
                          _syncAuthmanGroups();
                          Navigator.pop(context);
                        })),
              ]));
        });
  }

  Future<void> _onPullToRefresh() async {
    Analytics().logSelect(target: "Pull To Refresh");
    _reloadGroupsContent();
  }

  void _onTapImage(Group? group){
    Analytics().logSelect(target: "Image");
    if(group?.imageURL!=null){
      Navigator.push(context, PageRouteBuilder( opaque: false, pageBuilder: (context, _, __) => ModalImagePanel(imageUrl: group!.imageURL!, onCloseAnalytics: () => Analytics().logSelect(target: "Close Image"))));
    }
  }

  void _onTabChanged({bool manual = true}) {
    if (!_tabController.indexIsChanging && _selectedTab != _tabController.index) {
      setState(() {
        _selectedTab = _tabController.index;
        _selectedContentType = _selectedTab == 0 ? rokwire.GroupsContentType.all : rokwire.GroupsContentType.my;
      });
    }
    _scrollController.animateTo(0, duration: Duration(milliseconds: 500), curve: Curves.linear);
  }

  void _syncAuthmanGroups() {
    Analytics().logSelect(target: "Sync Authman Group");
    Groups().syncAuthmanGroupsExt().then(
          (result) => AppAlert.showDialogResult(context,
              result.successful ?
                  Localization().getStringEx("", "Successfully started groups authman sync.") : //TBD localize
                  Localization().getStringEx("", "Failed to start groups authman sync. Reason: ${result.error}")
          )
    );
  }

  bool get _canCreateGroup {
    return Auth2().isLoggedIn;
  }

  bool get _hasOptions => _canSyncAuthmanGroups;

  bool get _canSyncAuthmanGroups => Auth2().isManagedGroupAdmin;

  ///////////////////////////////////
  // NotificationsListener

  void onNotification(String name, dynamic param){
    if (name == Groups.notifyUserMembershipUpdated) {
      _updateState();
    }
    else if (name == Groups.notifyGroupCreated) {
      if (mounted) {
        _newGroupId = param;
        _newGroupKey = GlobalKey();
        _reloadGroupsContent().then((_) {
          if ((_newGroupId == param) && mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              BuildContext? newGroupContext = _newGroupKey?.currentContext;
              _newGroupId = null;
              _newGroupKey = null;
              if ((newGroupContext != null) && newGroupContext.mounted) {
                Scrollable.ensureVisible(newGroupContext, duration: Duration(milliseconds: 300));
              }
            });
          }
        });
      }
    }
    else if ((name == Groups.notifyGroupUpdated) || (name == Groups.notifyGroupDeleted)) {
      if (mounted) {
        _reloadGroupsContent();
      }
    }
    else if (name == Groups.notifyUserGroupsUpdated) {
      _applyUserGroups();
    }
    else if (name == Auth2.notifyLoginChanged) {
      // Reload content with some delay, do not unmount immidately GroupsCard that could have updated the login state.
      Future.delayed(Duration(microseconds: 300), () {
        if (mounted) {
          _reloadGroupsContent();
        }
      });
    }
    else if (name == FlexUI.notifyChanged) {
      if (mounted) {
        _reloadGroupsContent();
      }
    }
    else if (name == Connectivity.notifyStatusChanged) {
      if (Connectivity().isOnline && mounted) {
        _reloadGroupsContent();
      }
    }
  }
}
