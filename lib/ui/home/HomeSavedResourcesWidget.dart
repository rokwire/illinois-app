
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:illinois/ui/widgets/FavoriteButton.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';

class HomeSavedResourcesWidget extends StatelessWidget {
  final String? favoriteId;
  final StreamController<String>? updateController;

  HomeSavedResourcesWidget({super.key, this.favoriteId, this.updateController});

  static Widget handle({Key? key, String? favoriteId, HomeDragAndDropHost? dragAndDropHost, int? position}) =>
    HomeHandleWidget(key: key, favoriteId: favoriteId, dragAndDropHost: dragAndDropHost, position: position,
      title: title,
    );

  static String get title => Localization().getStringEx('widget.home.saved_resources.title', 'Saved Resources2');

  @override
  Widget build(BuildContext context) {
    return HomeFavoriteWidget(favoriteId: favoriteId, updateController: updateController,
      title: title,
      buttonBuilder: _favoriteButton,
      child: _contentWidget(context),
    );
  }

  Widget _contentWidget(BuildContext context) =>
    Padding(padding: HomeCard.defaultChildMargin, child:
      Center(child:
          Text('TBD', style: Styles().textStyles.getTextStyle("widget.message.regular"),)
      )
    );

  // TBD
  Widget _favoriteButton() => _HomeSavedResourcesFavoriteButton(
    favorite: HomeFavorite(favoriteId),
    style: FavoriteIconStyle.Button,
    padding: HomeFavoriteWidget.favoriteButtonPadding,
    prompt: true
  );
}

class _HomeSavedResourcesFavoriteButton extends HomeFavoriteButton {
  _HomeSavedResourcesFavoriteButton({ super.favorite, required super.style, super.padding = FavoriteStarIcon.defaultPadding, super.prompt = false});

  @override
  bool? get isFavorite => (super.isFavorite != false);
}



