
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';

class HomeTransportationLinksWidget extends StatelessWidget {
  final String? favoriteId;
  final StreamController<String>? updateController;

  HomeTransportationLinksWidget({super.key, this.favoriteId, this.updateController});

  static Widget handle({Key? key, String? favoriteId, HomeDragAndDropHost? dragAndDropHost, int? position}) =>
    HomeHandleWidget(key: key, favoriteId: favoriteId, dragAndDropHost: dragAndDropHost, position: position,
      title: title,
    );

  static String get title => Localization().getStringEx('widget.home.transportation_links.title', 'Transportation Links');

  @override
  Widget build(BuildContext context) {
    return HomeFavoriteWidget(favoriteId: favoriteId, updateController: updateController,
      title: title,
      child: _contentWidget(context),
    );
  }

  Widget _contentWidget(BuildContext context) =>
    Padding(padding: HomeCard.defaultChildMargin, child:
      Center(child:
          Text('TBD', style: Styles().textStyles.getTextStyle("widget.message.regular"),)
      )
    );

}





