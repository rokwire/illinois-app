import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:illinois/model/Groups.dart';
import 'package:illinois/service/AppLivecycle.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/Groups.dart';
import 'package:illinois/service/NotificationService.dart';
import 'package:illinois/service/Styles.dart';
import 'package:illinois/ui/groups/GroupWidgets.dart';
import 'package:illinois/ui/widgets/TrianglePainter.dart';


class HomeMyGroupsWidget extends StatefulWidget {
  final StreamController<void>? refreshController;

  const HomeMyGroupsWidget({Key? key, this.refreshController}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _HomeMyGroupsState();
}

class _HomeMyGroupsState extends State<HomeMyGroupsWidget> implements NotificationsListener{
  List<Group?>? _myGroups;
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
    if (widget.refreshController != null) {
      widget.refreshController!.stream.listen((_) {
        _loadGroups();
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
    return Visibility(
      visible: _haveGroups,
      child: Container(
        child: Column(
          children: [
            _buildHeader(),
            Stack(children:<Widget>[
              _buildSlant(),
              _buildContent(),
            ]),
          ],
        )
    ));
  }

  Widget _buildHeader() {
    return Semantics(container: true , header: true,
    child: Container(color: Styles().colors!.fillColorPrimary, child:
      Padding(padding: EdgeInsets.only(left: 20, top: 10, bottom: 10), child:
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Padding(padding: EdgeInsets.only(right: 16),
            child: Image.asset('images/campus-tools.png', excludeFromSemantics: true,)),
          Expanded(child:
            Text("My Groups", style:
              TextStyle(
                color: Styles().colors!.white,
                fontFamily: Styles().fontFamilies!.extraBold,
                fontSize: 20,),),),
    ],),),));
  }

  Widget _buildSlant() {
    return Column(children: <Widget>[
      Container(color:  Styles().colors!.fillColorPrimary, height: 45,),
      Container(color: Styles().colors!.fillColorPrimary, child:
      CustomPaint(painter: TrianglePainter(painterColor: Styles().colors!.background, left : true), child:
      Container(height: 65,),
      )),
    ],);
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

    return
      Padding(padding: EdgeInsets.only(top: 10, bottom: 20), child:
        Container(height: pageHeight, child:
          PageView(controller: _pageController, children: pages,)
        )
      );
  }

  List<Group?>? _sortGroups(List<Group?>? groups){
    if(groups?.isNotEmpty ?? false){
      groups!.sort((group1, group2) {
        if (group2!.dateUpdatedUtc == null) {
          return -1;
        }
        if (group1!.dateUpdatedUtc == null) {
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