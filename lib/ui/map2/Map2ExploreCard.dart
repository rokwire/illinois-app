
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
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class Map2ExploreCard extends StatefulWidget {
  final Explore? explore;
  final Position? currentLocation;
  final void Function()? onTap;

  Map2ExploreCard(this.explore, { super.key,
    this.currentLocation,
    this.onTap,
  });

  Favorite? get exploreFavorite => (explore is Favorite) ? (explore as Favorite) : null;

  bool? get isExploreFavorite {
    Favorite? favorite = exploreFavorite;
    return ((favorite != null) && Auth2().canFavorite) ? Auth2().isFavorite(favorite) : null;
  }

  @override
  State<StatefulWidget> createState() => _Map2ExploreCardState();
}

class _Map2ExploreCardState extends State<Map2ExploreCard> with NotificationsListener {

  bool? _isFavorite;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Auth2UserPrefs.notifyFavoritesChanged,
    ]);
    _isFavorite = widget.isExploreFavorite;
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  @override
  void onNotification(String name, param) {
    if (name == Auth2UserPrefs.notifyFavoritesChanged) {
      bool? isFavorite = widget.isExploreFavorite;
      if ((_isFavorite != isFavorite) && mounted) {
        setState((){
          _isFavorite = isFavorite;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) =>
    Semantics(label: _semanticsLabel, button: true, child:
      InkWell(onTap: widget.onTap, child:
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
    String? imageUrl = widget.explore?.exploreImageURL;
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
          Text(widget.explore?.exploreTitle ?? '', style: Styles().textStyles.getTextStyle('widget.title.medium.fat'), overflow: TextOverflow.ellipsis)
        ),
        if (_canFavorite)
          _favoriteButton,
      ],),
    );

  bool get _canFavorite => (_isFavorite != null);

  Widget get _favoriteButton {
    Favorite? favorite = widget.exploreFavorite;
    bool isFavorite = (_isFavorite == true);
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
    String? title = widget.explore?.exploreTitle;
    String? building = widget.explore?.exploreLocation?.building;
    String? fullAddress = widget.explore?.exploreLocation?.fullAddress;
    String? dispayDistance = StringUtils.ensureEmpty(widget.currentLocation?.displayDistance(widget.explore?.exploreLocation));
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

    String? dispayCoordinates = detailTexts.isEmpty ? widget.explore?.exploreLocation?.displayCoordinates : null;
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
    Favorite? favorite = widget.exploreFavorite;
    Analytics().logSelect(target: "Favorite: ${widget.explore?.exploreTitle}", source: '${runtimeType.toString()}(${favorite?.favoriteKey})');
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

  Color? get _headingColor => widget.explore?.uiColor;

  Decoration get _colorHeadingDecoration => BoxDecoration(
    color: _headingColor,
    borderRadius: _colorHeadingBorderRadius,
  );

  static const BorderRadiusGeometry _colorHeadingBorderRadius = BorderRadius.vertical(top: _cardRadius);
  static const double _colorHeadingHeight = 8;

  String get _semanticsLabel => '$_semanticsTitle, $_semanticsLocation';
  String get _semanticsTitle => widget.explore?.exploreTitle ?? '';
  String get _semanticsLocation => ListUtils.last(_locationDetailTexts) ?? '';
}
