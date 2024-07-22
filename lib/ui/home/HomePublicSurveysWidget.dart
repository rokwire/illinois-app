import 'dart:async';

import 'package:flutter/material.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:rokwire_plugin/service/localization.dart';

class HomePublicSurveysWidget extends StatefulWidget {
  final String? favoriteId;
  final StreamController<String>? updateController;

  const HomePublicSurveysWidget({Key? key, this.favoriteId, this.updateController}) : super(key: key);

  static Widget handle({Key? key, String? favoriteId, HomeDragAndDropHost? dragAndDropHost, int? position}) =>
    HomeHandleWidget(key: key, favoriteId: favoriteId, dragAndDropHost: dragAndDropHost, position: position,
      title: title,
    );

  static String get title => Localization().getStringEx('widget.home.public_surveys.label.header.title', 'Public Surveys');

  @override
  State<StatefulWidget> createState() => _HomePublicSurveysWidgetState();
}

class _HomePublicSurveysWidgetState extends State<HomePublicSurveysWidget>  {

  PageController? _pageController;

  @override
  void initState() {
    super.initState();

    if (widget.updateController != null) {
      widget.updateController!.stream.listen((String command) {
        if (command == HomePanel.notifyRefresh) {
          _refresh();
        }
      });
    }
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HomeSlantWidget(favoriteId: widget.favoriteId,
      title: HomePublicSurveysWidget.title,
      titleIconKey: 'campus-tools',
      child: _widgetContent,
    );
  }

  Widget get _widgetContent => Container();

  Future<void> _refresh() async {}
}