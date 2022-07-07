import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:illinois/main.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/groups/GroupsHomePanel.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:illinois/ui/widgets/LinkButton.dart';
import 'package:rokwire_plugin/model/group.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:illinois/service/Config.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:illinois/ui/groups/GroupWidgets.dart';


class HomeMyGroupsWidget extends StatefulWidget {
  final String? favoriteId;
  final StreamController<String>? updateController;
  final GroupsContentType contentType;

  const HomeMyGroupsWidget({Key? key, required this.contentType, this.favoriteId, this.updateController}) : super(key: key);

  static Widget handle({required GroupsContentType contentType, String? favoriteId, HomeDragAndDropHost? dragAndDropHost, int? position}) =>
    HomeHandleWidget(favoriteId: favoriteId, dragAndDropHost: dragAndDropHost, position: position,
      title: titleForContentType(contentType),
    );

  String get _title => titleForContentType(contentType);
  
  static String title({required GroupsContentType contentType}) => titleForContentType(contentType);

  static String titleForContentType(GroupsContentType contentType) {
    switch(contentType) {
      case GroupsContentType.my: return Localization().getStringEx('widget.home.groups.my.label.header.title', 'My Groups');
      case GroupsContentType.all: return Localization().getStringEx('widget.home.groups.all.label.header.title', 'All Groups');
    }
  }

  @override
  State<StatefulWidget> createState() => _HomeMyGroupsState();
}

class _HomeMyGroupsState extends State<HomeMyGroupsWidget> implements NotificationsListener{
  List<Group>? _groups;
  PageController? _pageController;
  final double _pageSpacing = 16;
  DateTime? _pausedDateTime;

  @override
  void initState() {
    super.initState();

    NotificationService().subscribe(this, [
      Groups.notifyUserMembershipUpdated,
      Groups.notifyGroupCreated,
      Groups.notifyGroupUpdated,
      Groups.notifyGroupDeleted,
      Auth2.notifyLoginChanged,
      AppLivecycle.notifyStateChanged,]);

    if (widget.updateController != null) {
      widget.updateController!.stream.listen((String command) {
        if (command == HomePanel.notifyRefresh) {
          _loadGroups();
        }
      });
    }

    double screenWidth = MediaQuery.of(App.instance?.currentContext ?? context).size.width;
    double pageViewport = (screenWidth - 2 * _pageSpacing) / screenWidth;
    _pageController = PageController(viewportFraction: pageViewport);

    _loadGroups();
  }

  @override
  void dispose() {
    super.dispose();
    _pageController?.dispose();
    NotificationService().unsubscribe(this);
  }

  void _loadGroups(){
    Groups().loadGroups(contentType: widget.contentType).then((groups) {
      _sortGroups(groups);
      if(mounted){
        setState(() {
          _groups = groups;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return HomeSlantWidget(favoriteId: widget.favoriteId,
      title: widget._title,
      titleIcon: Image.asset('images/campus-tools.png', excludeFromSemantics: true,),
      childPadding: EdgeInsets.zero,
      child: _haveGroups ? _buildContent() : _buildEmpty(),
    );
  }


  Widget _buildContent() {

    List<Widget> pages = <Widget>[];
    if(_groups?.isNotEmpty ?? false) {
      for (Group? group in _groups!) {
        if (group != null) {
          pages.add(Padding(padding: EdgeInsets.only(right: _pageSpacing), child:
            GroupCard(group: group, displayType: GroupCardDisplayType.homeGroups, margin: EdgeInsets.zero,),
          ));
        }
      }
    }

    double pageHeight = 90 * 2 * MediaQuery.of(context).textScaleFactor;

    return Column(children: [
      Container(height: pageHeight, child:
        PageView(controller: _pageController, children: pages,)
      ),
      LinkButton(
        title: Localization().getStringEx('widget.home.my_groups.button.all.title', 'View All'),
        hint: Localization().getStringEx('widget.home.my_groups.button.all.hint', 'Tap to view all groups'),
        onTap: _onSeeAll,
      ),
    ],);

  }

  List<Group>? _sortGroups(List<Group>? groups){
    if(groups?.isNotEmpty ?? false){
      groups!.sort((group1, group2) {
        if (group2.dateUpdatedUtc == null) {
          return -1;
        }
        if (group1.dateUpdatedUtc == null) {
          return 1;
        }

        return group2.dateUpdatedUtc!.compareTo(group1.dateUpdatedUtc!);
      });
    }

    return groups;
  }

  Widget _buildEmpty() {
    String title, message;
    switch(widget.contentType) {
      
      case GroupsContentType.my:
        title = Localization().getStringEx('widget.home.groups.my.text.empty', 'Whoops! Nothing to see here.');
        message = Localization().getStringEx('widget.home.groups.my.text.description', 'You have not created any groups yet.');
        break;
      
      case GroupsContentType.all:
        title = Localization().getStringEx('widget.home.groups.all.text.empty', 'Whoops! Nothing to see here.');
        message = Localization().getStringEx('widget.home.groups.all.text.description', 'Failed to load groups.');
        break;
    }
    return HomeMessageCard(title: title, message: message,);
  }


  @override
  void onNotification(String name, param) {
    if (name == AppLivecycle.notifyStateChanged) {
      _onAppLivecycleStateChanged(param);
    }
    else if ((name == Groups.notifyGroupCreated) ||
      (name == Groups.notifyGroupUpdated) ||
      (name == Groups.notifyGroupDeleted) ||
      (name == Groups.notifyUserMembershipUpdated) ||
      (name == Auth2.notifyLoginChanged)) {
        _loadGroups();
    }
  }

  void _onAppLivecycleStateChanged(AppLifecycleState? state) {
    if (state == AppLifecycleState.paused) {
      _pausedDateTime = DateTime.now();
    }
    else if (state == AppLifecycleState.resumed) {
      if (_pausedDateTime != null) {
        Duration pausedDuration = DateTime.now().difference(_pausedDateTime!);
        if (Config().refreshTimeout < pausedDuration.inSeconds) {
          _loadGroups();
        }
      }
    }
  }

  bool get _haveGroups{
    return _groups?.isNotEmpty ?? false;
  }

  void _onSeeAll() {
    Analytics().logSelect(target: "HomeGroups ${widget.contentType} View All");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GroupsHomePanel(contentType: widget.contentType,)));
  }
}