import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/NotificationService.dart';
import 'package:illinois/service/Styles.dart';
import 'package:illinois/ui/home/HomeSaferTestLocationsPanel.dart';
import 'package:illinois/ui/home/HomeSaferWellnessAnswerCenterPanel.dart';
import 'package:illinois/ui/wallet/IDCardPanel.dart';
import 'package:illinois/ui/widgets/SectionTitlePrimary.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeSaferWidget extends StatefulWidget {

  final StreamController<void> refreshController;

  HomeSaferWidget({this.refreshController});

  @override
  _HomeSaferWidgetState createState() => _HomeSaferWidgetState();
}

class _HomeSaferWidgetState extends State<HomeSaferWidget> implements NotificationsListener {


  @override
  void initState() {
    super.initState();

    NotificationService().subscribe(this, [
      FlexUI.notifyChanged
    ]);

    if (widget.refreshController != null) {
      widget.refreshController.stream.listen((_) {
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
    NotificationService().unsubscribe(this);
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == FlexUI.notifyChanged) {
      setState(() {
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SectionTitlePrimary(
      title: Localization().getStringEx('widget.home.safer.label.title', 'Building Access'),
      iconPath: 'images/campus-tools.png',
      children: _buildCommandsList(),);
  }

  List<Widget> _buildCommandsList() {
    List<Widget> contentList = <Widget>[];
    List<dynamic> contentListCodes = FlexUI()['home.safer'];
    if (contentListCodes != null) {
      for (dynamic contentListCode in contentListCodes) {
        Widget contentEntry;
        if (contentListCode == 'building_access') {
          contentEntry = _buildCommandEntry(
            title: Localization().getStringEx('widget.home.safer.button.building_access.title', 'Building Access'),
            description: Localization().getStringEx('widget.home.safer.button.building_access.description', 'Check your current building access.'),
            onTap: _onBuildingAccess,
          );
        }
        else if (contentListCode == 'test_locations') {
          contentEntry = _buildCommandEntry(
            title: Localization().getStringEx('widget.home.safer.button.test_locations.title', 'Test Locations'),
            description: Localization().getStringEx('widget.home.safer.button.test_locations.description', 'Find test locations'),
            onTap: _onTestLocations,
          );
        }
        else if (contentListCode == 'my_mckinley') {
          contentEntry = _buildCommandEntry(
            title: Localization().getStringEx('widget.home.safer.button.my_mckinley.title', 'MyMcKinley'),
            description: Localization().getStringEx('widget.home.safer.button.my_mckinley.description', 'MyMcKinley Patient Health Portal'),
            onTap: _onMyMcKinley,
          );
        }
        else if (contentListCode == 'wellness_answer_center') {
          contentEntry = _buildCommandEntry(
            title: Localization().getStringEx('widget.home.safer.button.wellness_answer_center.title', 'Wellness Answer Center'),
            description: Localization().getStringEx('widget.home.safer.button.wellness_answer_center.description', 'Contact Wellness Answer Center for issues'),
            onTap: _onWellnessAnswerCenter,
          );
        }

        if (contentEntry != null) {
          if (contentList.isNotEmpty) {
            contentList.add(Container(height: 6,));
          }
          contentList.add(contentEntry);
        }
      }

    }
   return contentList;
  }

  Widget _buildCommandEntry({String title, String description, void Function() onTap}) {
    return Semantics(container: true, child: 
      InkWell(onTap: onTap, child:
        Container(
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          decoration: BoxDecoration(color: Styles().colors.surface, borderRadius: BorderRadius.all(Radius.circular(4)), boxShadow: [BoxShadow(color: Styles().colors.blackTransparent018, spreadRadius: 2.0, blurRadius: 6.0, offset: Offset(2, 2))] ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            Row(children: <Widget>[
              Expanded(child:
                Text(title, style: TextStyle(fontFamily: Styles().fontFamilies.extraBold, fontSize: 20, color: Styles().colors.fillColorPrimary),),
              ),
              Image.asset('images/chevron-right.png'),
            ],),
            AppString.isStringNotEmpty(description) ?
              Padding(padding: EdgeInsets.only(top: 5), child:
                Text(description, style: TextStyle(fontFamily: Styles().fontFamilies.regular, fontSize: 16, color: Styles().colors.textSurface),),
              ) :
              Container(),
          ],),),),
      );
  }

  void _onBuildingAccess() {
    Analytics().logSelect(target: 'Building Access');
    //Navigator.push(context, CupertinoPageRoute(
    //  builder: (context) => IDCardPanel()
    //));
    showModalBottomSheet(context: context,
        isScrollControlled: true,
        isDismissible: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.0),
        ),
        builder: (context){
          return IDCardPanel();
        }
    );
}

  void _onTestLocations() {
    Analytics().logSelect(target: 'Locations');
    Navigator.push(context, CupertinoPageRoute(
      builder: (context) => HomeSaferTestLocationsPanel()
    ));
  }

  void _onMyMcKinley() {
    Analytics().logSelect(target: 'MyMcKinley');
    if (AppString.isStringNotEmpty(Config().saferMcKinley['url'])) {
      launch(Config().saferMcKinley['url']);
    }
  }

  void _onWellnessAnswerCenter() {
    Analytics().logSelect(target: 'Wellness Answer Center');
    Navigator.push(context, CupertinoPageRoute(
      builder: (context) => HomeSaferWellnessAnswerCenterPanel()
    ));
  }
}