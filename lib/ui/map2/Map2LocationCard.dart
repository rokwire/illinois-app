
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:illinois/ext/Explore.dart';
import 'package:illinois/ext/Favorite.dart';
import 'package:illinois/ext/Position.dart';
import 'package:illinois/model/Explore.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Config.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/model/explore.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

// Map2LocationCard

class Map2LocationCard extends StatefulWidget {
  final Explore? explore;
  final Position? currentLocation;
  final void Function()? onTap;

  Map2LocationCard(this.explore, { super.key,
    this.currentLocation,
    this.onTap,
  });

  Favorite? get exploreFavorite => (explore is Favorite) ? (explore as Favorite) : null;

  bool? get isExploreFavorite {
    Favorite? favorite = exploreFavorite;
    return ((favorite != null) && Auth2().canFavorite) ? Auth2().isFavorite(favorite) : null;
  }

  @override
  State<StatefulWidget> createState() => _Map2LocationCardState();
}

class _Map2LocationCardState extends State<Map2LocationCard> with NotificationsListener {

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

  Widget get _titleWidget {
    List<Widget> titleActions = _titleActions;
    EdgeInsetsGeometry favoriteButtonInsets = titleActions.isNotEmpty ? _favoriteButtonCondensedInsets : _favoriteButtonStandardInsets;
    return Padding(padding: _titleWidgetInsets, child:
      Row(children: [
        Expanded(child:
          _titleWidgetImpl
        ),
        ... titleActions,
        if (_canFavorite)
          _favoriteButton(padding: favoriteButtonInsets),
      ],),
    );
  }


  static const double _titleWidgetPadding = 16;
  EdgeInsetsGeometry get _titleWidgetInsets => _canFavorite ?
    EdgeInsets.only(left: _titleWidgetPadding) :
    EdgeInsets.only(left: _titleWidgetPadding, right: _titleWidgetPadding, top: _titleWidgetPadding);

  Widget get _titleWidgetImpl =>
    Text(_titleText, style: _titleTextStyle, overflow: TextOverflow.ellipsis);

  String get _titleText =>
    widget.explore?.exploreTitle ?? '';

  TextStyle? get _titleTextStyle =>
    Styles().textStyles.getTextStyle('widget.title.medium.fat');

  List<Widget> get _titleActions => <Widget>[];

  bool get _canFavorite => (_isFavorite != null);

  Widget _favoriteButton({EdgeInsetsGeometry padding = _favoriteButtonStandardInsets }) {
    Favorite? favorite = widget.exploreFavorite;
    bool isFavorite = (_isFavorite == true);
    Widget? favoriteStarIcon = favorite?.favoriteStarIcon(selected: isFavorite);
    String semanticLabel = isFavorite ? Localization().getStringEx('widget.card.button.favorite.off.title', 'Remove From Favorites') : Localization().getStringEx('widget.card.button.favorite.on.title', 'Add To Favorites');
    String semanticHint = isFavorite ? Localization().getStringEx('widget.card.button.favorite.off.hint', '') : Localization().getStringEx('widget.card.button.favorite.on.hint', '');
    return InkWell(onTap: () => _onTapFavorite(), child:
      Semantics(container: true, label: semanticLabel, hint: semanticHint, button: true, excludeSemantics: true, child:
        Padding(padding: padding, child:
          favoriteStarIcon
        )
      )
    );
  }

  static const double _favoriteButtonStandardPadding = 16;
  static const EdgeInsetsGeometry _favoriteButtonStandardInsets = EdgeInsets.only(
    left: _favoriteButtonStandardPadding,
    right: _favoriteButtonStandardPadding,
    top: _favoriteButtonStandardPadding,
    bottom: _favoriteButtonStandardPadding
  );
  static const double _favoriteButtonCondensedPadding = _favoriteButtonStandardPadding / 2;
  static const EdgeInsetsGeometry _favoriteButtonCondensedInsets = EdgeInsets.only(
      left: _favoriteButtonCondensedPadding,
      right: _favoriteButtonStandardPadding,
      top: _favoriteButtonStandardPadding,
      bottom: _favoriteButtonStandardPadding
  );

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

class Map2ExplorePOICard extends Map2LocationCard {

  final ExplorePOI? explorePOI;

  Map2ExplorePOICard(this.explorePOI, { super.key,
    super.currentLocation,
    super.onTap,
  }) : super(explorePOI,);

  @override
  State<StatefulWidget> createState() => _Map2ExplorePOICardState();
}

class _Map2ExplorePOICardState extends _Map2LocationCardState {

  bool _isEditing = false;
  final TextEditingController _titleTextController = TextEditingController();
  final FocusNode _titleTextNode = FocusNode();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _titleTextController.dispose();
    _titleTextNode.dispose();
    super.dispose();
  }

  @override
  Widget get _titleWidgetImpl => _isEditing ? _titleTextField : super._titleWidgetImpl;

  @override
  List<Widget> get _titleActions => _isEditing ? <Widget>[
    _titleEditDoneButton,
    _titleEditCancelButton,
  ] : <Widget>[
    _titleEditButton,
  ];

  Widget get _titleTextField => Semantics(
    label: Localization().getStringEx('panel.search.field.search.title', 'Search'),
    hint: Localization().getStringEx('panel.search.field.search.hint', ''),
    textField: true,
    excludeSemantics: true,
    child: TextField(
      controller: _titleTextController,
      focusNode: _titleTextNode,
      onSubmitted: (_) => _onEditDone(),
      autofocus: true,
      cursorColor: Styles().colors.fillColorSecondary,
      keyboardType: TextInputType.text,
      style: _titleTextStyle,
      decoration: InputDecoration(
        border: InputBorder.none,
      ),
    ),
  );

  Widget get _titleEditButton {
    String semanticLabel = Localization().getStringEx('widget.card.button.title.edit.title', 'Edit Title');
    String semanticHint = Localization().getStringEx('widget.card.button.title.edit.hint', '');
    return InkWell(onTap: () => _onTapEdit(), child:
      Semantics(container: true, label: semanticLabel, hint: semanticHint, button: true, excludeSemantics: true, child:
        Padding(padding: _actionButtonCondensedPadding, child:
          Styles().images.getImage('edit')
        )
      )
    );
  }

  Widget get _titleEditDoneButton {
    String semanticLabel = Localization().getStringEx('panel.search.button.search.title', 'Search');
    String semanticHint = Localization().getStringEx('panel.search.button.search.hint', '');
    return InkWell(onTap: () => _onEditDone(), child:
      Semantics(container: true, label: semanticLabel, hint: semanticHint, button: true, excludeSemantics: true, child:
        Padding(padding: _actionButtonCondensedPadding, child:
          Styles().images.getImage('check', size: 12)
        )
      )
    );
  }

  Widget get _titleEditCancelButton {
    String semanticLabel = Localization().getStringEx('panel.search.button.clear.title', 'Clear');
    String semanticHint = Localization().getStringEx('panel.search.button.clear.hint', '');
    return InkWell(onTap: () => _onEditClear(), child:
      Semantics(container: true, label: semanticLabel, hint: semanticHint, button: true, excludeSemantics: true, child:
        Padding(padding: _actionButtonCondensedPadding, child:
          Styles().images.getImage('close', size: 12)
        )
      )
    );
  }

  static const EdgeInsetsGeometry _actionButtonCondensedPadding = EdgeInsets.only(
      left: _Map2LocationCardState._favoriteButtonCondensedPadding,
      right: _Map2LocationCardState._favoriteButtonCondensedPadding,
      top: _Map2LocationCardState._favoriteButtonStandardPadding,
      bottom: _Map2LocationCardState._favoriteButtonStandardPadding
  );

  void _onTapEdit() {
    if (_isEditing != true) {
      _titleTextController.text = _titleText;
      setState(() {
        _isEditing = true;
      });
      WidgetsBinding.instance.addPostFrameCallback((_){
        _titleTextNode.requestFocus();
      });
    }
  }

  void _onEditClear() {
    if (_isEditing == true) {
      if (_titleTextController.text.isNotEmpty) {
        _titleTextController.text = '';
      }
      else {
        setState(() {
          _isEditing = false;
        });
      }
    }
  }

  void _onEditDone() {
    if ((_isEditing == true) && _titleTextController.text.isNotEmpty) {
      //TBD: set the value
      setState(() {
        _isEditing = false;
      });
    }
  }


}