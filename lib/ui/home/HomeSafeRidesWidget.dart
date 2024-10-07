
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:neom/model/Analytics.dart';
import 'package:neom/service/Config.dart';
import 'package:neom/service/Guide.dart';
import 'package:neom/ui/guide/GuideEntryCard.dart';
import 'package:neom/ui/home/HomePanel.dart';
import 'package:neom/ui/home/HomeWidgets.dart';
import 'package:rokwire_plugin/service/localization.dart';

class HomeSafeRidesRequestWidget extends StatelessWidget {
  final String? favoriteId;
  final StreamController<String>? updateController;

  HomeSafeRidesRequestWidget({super.key, this.favoriteId, this.updateController});

  static Widget handle({Key? key, String? favoriteId, HomeDragAndDropHost? dragAndDropHost, int? position}) =>
    HomeHandleWidget(key: key, favoriteId: favoriteId, dragAndDropHost: dragAndDropHost, position: position,
      title: title,
    );

  static String get title => Localization().getStringEx('widget.home.safety.saferides.title', 'SafeRides');

  @override
  Widget build(BuildContext context) {
    return HomeSlantWidget(favoriteId: favoriteId,
      title: title,
      titleIconKey: 'resources',
      child: _contentWidget(context),
    );
  }

  Widget _contentWidget(BuildContext context) =>
    Padding(padding: EdgeInsets.only(left: 16, right: 16, bottom: 16), child:
      GuideEntryCard(Guide().entryById(Config().safeRidesGuideId), favoriteKey: null, analyticsFeature: AnalyticsFeature.Safety,)
    );

}

