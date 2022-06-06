import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:illinois/ui/home/HomeFavorite.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:rokwire_plugin/model/group.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:illinois/service/Config.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:illinois/ui/groups/GroupWidgets.dart';


class HomeMyGroupsWidget extends StatefulWidget {
  final String? favoriteId;
  final StreamController<String>? updateController;

  const HomeMyGroupsWidget({Key? key, this.favoriteId, this.updateController}) : super(key: key);

  static Widget handle({String? favoriteId, HomeDragAndDropHost? dragAndDropHost, int? position}) =>
    HomeHandleWidget(favoriteId: favoriteId, dragAndDropHost: dragAndDropHost, position: position,
      title: 'My Groups' /*TBD: Localization */,
    );

  @override
  State<StatefulWidget> createState() => _HomeMyGroupsState();
}

class _HomeMyGroupsState extends State<HomeMyGroupsWidget> implements NotificationsListener{
  List<Group>? _myGroups;
  PageController? _pageController;
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

    _loadGroups();
  }

  @override
  void dispose() {
    super.dispose();
    NotificationService().unsubscribe(this);
  }

  void _loadGroups(){
    Groups().loadGroups(myGroups: true).then((groups) {
      _sortGroups(groups);
      if(mounted){
        setState(() {
          _myGroups = groups;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Visibility(visible: _haveGroups, child:
        HomeSlantWidget(favoriteId: widget.favoriteId,
          title: "My Groups" /*TBD: Localization */,
          titleIcon: Image.asset('images/campus-tools.png', excludeFromSemantics: true,),
          child: _buildContent(),
          childPadding: const EdgeInsets.only(top: 8, bottom: 16),
        ),
    );
  }

  Widget _buildContent() {
    List<Widget> pages = <Widget>[];
    if(_myGroups?.isNotEmpty ?? false) {
      for (Group? group in _myGroups!) {
        if (group != null) {
          pages.add(GroupCard(
            group: group, displayType: GroupCardDisplayType.homeGroups,));
        }
      }
    }

    double screenWidth = MediaQuery.of(context).size.width * 2/3;
    double pageHeight = 90 * 2 * MediaQuery.of(context).textScaleFactor;
    double pageViewport = (screenWidth - 40) / screenWidth;

    if (_pageController == null) {
      _pageController = PageController(viewportFraction: pageViewport);
    }

    return Container(height: pageHeight, child:
      PageView(controller: _pageController, children: pages,)
    );
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
    return _myGroups?.isNotEmpty ?? false;
  }
}