
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:illinois/ext/Explore.dart';
import 'package:illinois/ext/Favorite.dart';
import 'package:illinois/ext/Position.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Config.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/model/explore.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class ExploreLocationCard extends StatelessWidget {
  final Explore? explore;
  final Position? currentLocation;
  final void Function()? onTap;
  ExploreLocationCard(this.explore, { super.key,
    this.currentLocation,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) =>
    Semantics(label: _semanticsLabel, button: true, child:
      InkWell(onTap: onTap, child:
        Semantics(excludeSemantics: true, child:
          _cardWidget
        )
      )
    );

  Widget get _cardWidget =>
    Container(decoration: _cardDecoration, child:
      ClipRRect(borderRadius: _cardBorderRadius, child:
        Column(mainAxisSize: MainAxisSize.min, children: [
          _imageHeadingWidget ?? _colorHeadingWidget ?? Container(),
          Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            _titleWidget,
            _detailsWidget,
          ]),
        ],),
      ),
    );

  Widget? get _imageHeadingWidget {
    String? imageUrl = explore?.exploreImageURL;
    return ((imageUrl != null) && imageUrl.isNotEmpty) ?
      Container(decoration: _imageHeadingDecoration, child:
        AspectRatio(aspectRatio: 2.5, child:
          Image.network(imageUrl, fit: BoxFit.cover, headers: Config().networkAuthHeaders, excludeFromSemantics: true)
        ),
      ) : null;
  }

  Widget? get _colorHeadingWidget =>
    (_headingColor != null) ? Container(decoration: _colorHeadingDecoration, height: _colorHeadingHeight,) : null;

  Widget get _titleWidget =>
    Padding(padding: _canFavorite ? EdgeInsets.only(left: 16) : EdgeInsets.only(left: 16, right: 16, top: 16), child:
      Row(children: [
        Expanded(child:
          Text(explore?.exploreTitle ?? '', style: Styles().textStyles.getTextStyle('widget.title.medium.fat'), overflow: TextOverflow.ellipsis)
        ),
        if (_canFavorite)
          _favoriteButton,
      ],),
    );

  bool get _canFavorite => (explore is Favorite) && Auth2().canFavorite;

  Widget get _favoriteButton {
    Favorite? favorite = (explore is Favorite) ? (explore as Favorite) : null;
    bool isFavorite = Auth2().isFavorite(favorite);
    Widget? favoriteStarIcon = favorite?.favoriteStarIcon(selected: isFavorite);
    String semanticLabel = isFavorite ? Localization().getStringEx('widget.card.button.favorite.off.title', 'Remove From Favorites') : Localization().getStringEx('widget.card.button.favorite.on.title', 'Add To Favorites');
    String semanticHint = isFavorite ? Localization().getStringEx('widget.card.button.favorite.off.hint', '') : Localization().getStringEx('widget.card.button.favorite.on.hint', '');
    return InkWell(onTap: () => _onTapFavorite(), child:
      Semantics(container: true, label: semanticLabel, hint: semanticHint, button: true, excludeSemantics: true, child:
        Padding(padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16), child:
          favoriteStarIcon
        )
      )
    );
  }

  Widget get _detailsWidget {
    List<Widget> detailWidgets = ListUtils.stripNull(<Widget?>[
      _locationDetailsWidget,
    ]);

    return detailWidgets.isNotEmpty ? Padding(padding: EdgeInsets.only(left: 16, right: 16, bottom: 16), child:
      Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: detailWidgets,)
    ) : Container();
  }

  Widget? get _locationDetailsWidget =>
    _buildDetailWidget('location', _locationDetailTexts.map<Widget>((String text) => _locationDetailTextWidget(text)), contentPadding: EdgeInsets.zero);

  List<String> get _locationDetailTexts {
    String? title = explore?.exploreTitle;
    String? building = explore?.exploreLocation?.building;
    String? fullAddress = explore?.exploreLocation?.fullAddress;
    String? dispayDistance = StringUtils.ensureEmpty(currentLocation?.displayDistance(explore?.exploreLocation));
    List<String> detailTexts = <String>[];

    if ((building != null) && building.isNotEmpty &&
        ((title == null) || title.isEmpty || (!building.contains(title) && title.contains(building))) &&
        ((fullAddress == null) || fullAddress.isEmpty || (!fullAddress.contains(building) && !building.contains(fullAddress)))
       )
    {
      detailTexts.add(building);
    }

    if ((fullAddress != null) && fullAddress.isNotEmpty) {
      detailTexts.add(fullAddress);
    }

    String? dispayCoordinates = detailTexts.isEmpty ? explore?.exploreLocation?.displayCoordinates : null;
    if ((dispayCoordinates != null) && dispayCoordinates.isNotEmpty) {
      detailTexts.add(dispayCoordinates);
    }

    if ((dispayDistance != null) && dispayDistance.isNotEmpty) {
      detailTexts.add(dispayDistance);
    }

    return detailTexts;
  }

  Widget _locationDetailTextWidget(String? text) =>
    Text(text ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: Styles().textStyles.getTextStyle('common.body'),);

  Widget? _buildDetailWidget(String iconKey, Iterable<Widget> contentWidgets, {
    EdgeInsetsGeometry contentPadding = const EdgeInsets.only(top: 4),
    EdgeInsetsGeometry iconPadding = const EdgeInsets.only(right: 6),
  }) {
    List<Widget> contentRows = <Widget>[];
    Widget? iconWidget = Styles().images.getImage(iconKey, excludeFromSemantics: true);
    for (Widget contentWidget in contentWidgets) {
      contentRows.add(Row(children: <Widget>[
        if (iconWidget != null)
          Padding(padding: iconPadding, child:
            Opacity(opacity: contentRows.isEmpty ? 1 : 0, child:
              iconWidget,
            )
          ),
        Expanded(child:
          contentWidget
        )
      ]));
    }
    return contentRows.isNotEmpty ? Padding(padding: contentPadding, child:
      Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children:
        contentRows
      )
    ) : null;
  }

  void _onTapFavorite() {
    Favorite? favorite = (explore is Favorite) ? (explore as Favorite) : null;
    Analytics().logSelect(target: "Favorite: ${explore?.exploreTitle}", source: '${runtimeType.toString()}(${favorite?.favoriteKey})');
    Auth2().prefs?.toggleFavorite(favorite);
  }

  static Decoration get _cardDecoration => BoxDecoration(
    color: Styles().colors.surface,
    borderRadius: _cardBorderRadius,
    border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
    boxShadow: [BoxShadow(color: Color.fromRGBO(19, 41, 75, 0.3), spreadRadius: 1.0, blurRadius: 1.0, offset: Offset(0, 2))]
  );

  static const BorderRadiusGeometry _cardBorderRadius = BorderRadius.all(_cardRadius);
  static const Radius _cardRadius = Radius.circular(8);

  static Decoration get _imageHeadingDecoration => BoxDecoration(
    border: Border(bottom: BorderSide(color: Styles().colors.surfaceAccent, width: 1)),
  );

  Color? get _headingColor => explore?.uiColor;

  Decoration get _colorHeadingDecoration => BoxDecoration(
    color: _headingColor,
    borderRadius: _colorHeadingBorderRadius,
  );

  static const BorderRadiusGeometry _colorHeadingBorderRadius = BorderRadius.vertical(top: _cardRadius);
  static const double _colorHeadingHeight = 8;

  String get _semanticsLabel => '$_semanticsTitle, $_semanticsLocation';
  String get _semanticsTitle => explore?.exploreTitle ?? '';
  String get _semanticsLocation => ListUtils.last(_locationDetailTexts) ?? '';
}
