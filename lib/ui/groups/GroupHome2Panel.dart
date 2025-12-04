
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/model/Analytics.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/ui/groups/GroupWidgets.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/model/group.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';

class GroupHome2Panel extends StatefulWidget with AnalyticsInfo {
  static final String routeName = 'edu.illinois.rokwire.group.home2';

  GroupHome2Panel({super.key});

  static void push(BuildContext context) =>
    Navigator.push(context, CupertinoPageRoute(
      settings: RouteSettings(name: routeName),
      builder: (context) => GroupHome2Panel()
    ));

  _GroupHome2PanelState createState() => _GroupHome2PanelState();

  @override
  AnalyticsFeature? get analyticsFeature => AnalyticsFeature.Groups;
}
enum _ContentActivity { load, refresh, extend }

class _GroupHome2PanelState extends State<GroupHome2Panel> with NotificationsListener {

  ScrollController _scrollController = ScrollController();

  List<Group>? _contentList;
  Map<String, GlobalKey> _cardKeys = <String, GlobalKey>{};
  bool? _lastPageLoadedAll;
  _ContentActivity? _contentActivity;
  static const int _contentPageLength = 16;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Groups.notifyGroupCreated,
      Groups.notifyGroupUpdated,
      Groups.notifyGroupDeleted,
      Groups.notifyUserGroupsUpdated,
      Groups.notifyUserMembershipUpdated,
      Auth2.notifyLoginChanged,
    ]);

    _scrollController.addListener(_scrollListener);
    _loadContent();
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    _scrollController.dispose();
    super.dispose();
  }

  // NotificationsListener

  void onNotification(String name, dynamic param) {
    if (name == Groups.notifyGroupCreated) {
    }
    else if ((name == Groups.notifyGroupUpdated) || (name == Groups.notifyGroupDeleted)) {
    }
    else if (name == Groups.notifyUserGroupsUpdated) {
    }
    else if (name == Groups.notifyUserMembershipUpdated) {
    }
    else if (name == Auth2.notifyLoginChanged) {
    }
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

  Widget get _commandBar => Container();

  Widget get _bodyContent {
    if (_contentActivity == _ContentActivity.load) {
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
      cardsList.add(Padding(padding: EdgeInsets.only(top: cardsList.isNotEmpty ? 8 : 0), child:
        GroupCard(group,
          key: _cardKeys[group.id],
          displayType: GroupCardDisplayType.allGroups,
        ),
      ),);
    }
    if (_contentActivity == _ContentActivity.extend) {
      cardsList.add(Padding(padding: EdgeInsets.only(top: cardsList.isNotEmpty ? 8 : 0), child:
        _extendingIndicator
      ));
    }
    return Padding(padding: EdgeInsets.all(16), child:
      Column(children:  cardsList,)
    );
  }

  Widget _buildMessageContent(String message, { String? title }) =>
    Padding(padding: EdgeInsets.symmetric(horizontal: 32, vertical: _screenHeight / 6), child:
      Column(children: [
        (title != null) ? Padding(padding: EdgeInsets.only(bottom: 12), child:
          Text(title, textAlign: TextAlign.center, style: Styles().textStyles.getTextStyle('widget.item.medium.fat'),)
        ) : Container(),
        Text(message, textAlign: TextAlign.center, style: Styles().textStyles.getTextStyle((title != null) ? 'widget.item.regular.thin' : 'widget.item.medium.fat'),),
      ],),
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

  bool? get _hasMoreContent => (_lastPageLoadedAll != false);

  Future<void> _loadContent({ int limit = _contentPageLength }) async {}
  Future<void> _refreshContent() async {}
  Future<void> _extendContent() async {}
}
