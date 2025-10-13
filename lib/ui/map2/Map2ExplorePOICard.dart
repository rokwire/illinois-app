
import 'package:flutter/material.dart';
import 'package:illinois/ext/Explore.dart';
import 'package:illinois/ext/Favorite.dart';
import 'package:illinois/model/Explore.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class Map2ExplorePOICard extends StatefulWidget {
  static const String notifyPOIUpdated = "edu.illinois.rokwire.explore.poi.updated";

  final ExplorePOI explorePOI;

  Map2ExplorePOICard(this.explorePOI, { super.key,});

  @override
  State<StatefulWidget> createState() => _Map2ExplorePOICardState();
}

class _Map2ExplorePOICardState extends State<Map2ExplorePOICard> with NotificationsListener {

  late ExplorePOI _explorePOI;
  late bool _isFavorite;

  bool _isEditingTitle = false;
  bool _canSubmitTitle = false;
  final TextEditingController _titleTextController = TextEditingController();
  final FocusNode _titleTextNode = FocusNode();

  static Decoration get _cardDecoration => BoxDecoration(
    color: Styles().colors.surface,
    borderRadius: _cardBorderRadius,
    border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
    boxShadow: [BoxShadow(color: Color.fromRGBO(19, 41, 75, 0.3), spreadRadius: 1.0, blurRadius: 1.0, offset: Offset(0, 2))]
  );

  static const BorderRadiusGeometry _cardBorderRadius = BorderRadius.all(_cardRadius);
  static const Radius _cardRadius = Radius.circular(8);

  static EdgeInsetsGeometry _titleActionButtonPadding = EdgeInsets.symmetric(horizontal: 8, vertical: 16);
  static EdgeInsetsGeometry _favoriteButtonPadding = EdgeInsets.only(left: 8, right: 16, top: 16, bottom: 16);

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Auth2UserPrefs.notifyFavoritesChanged,
    ]);
    _explorePOI = widget.explorePOI;
    _isFavorite = _isPOIFavorite();
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    _titleTextController.dispose();
    _titleTextNode.dispose();
    super.dispose();
  }

  @override
  void onNotification(String name, param) {
    if (name == Auth2UserPrefs.notifyFavoritesChanged) {
      bool? isFavorite = _isPOIFavorite();
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
      InkWell(onTap: _onEditTitleCancel, child:
        _cardWidget
      )
    );

  Widget get _cardWidget =>
    Container(decoration: _cardDecoration, child:
      ClipRRect(borderRadius: _cardBorderRadius, child:
        Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          _titleWidget,
          _detailsWidget,
        ]),
      ),
    );

  Widget get _titleWidget =>
    Padding(padding: EdgeInsets.only(left: 16), child:
      Row(children: [
        Expanded(child:
          _isEditingTitle ? _titleTextFieldWidget : _titleTextWidget
        ),
        ... _titleActionButtons,
        _favoriteButton,
      ],),
    );

  Widget get _titleTextWidget => InkWell(onTap: _onEditTitle, child:
    Text(_titleText, overflow: TextOverflow.ellipsis, style: _titleTextStyle),
  );
  TextStyle? get _titleTextStyle => Styles().textStyles.getTextStyle('widget.title.medium.fat');
  String get _titleText => _explorePOI.exploreTitle ?? '';

  Widget get _titleTextFieldWidget => Semantics(
    label: Localization().getStringEx('panel.search.field.search.title', 'Search'),
    hint: Localization().getStringEx('panel.search.field.search.hint', ''),
    textField: true,
    excludeSemantics: true,
    child: TextField(
      controller: _titleTextController,
      focusNode: _titleTextNode,
      onChanged: (_) => _onEditTitleChanged(),
      onSubmitted: (_) => _onEditTitleDone(),
      autofocus: true,
      cursorColor: Styles().colors.fillColorPrimary,
      keyboardType: TextInputType.text,
      style: _titleTextStyle,
      decoration: InputDecoration(
        border: InputBorder.none,
      ),
    ),
  );

  List<Widget> get _titleActionButtons => _isEditingTitle ? <Widget>[
    if (_canSubmitTitle)
      _titleEditDoneButton,
    _titleEditCancelButton,
  ] : <Widget>[
    _titleEditButton,
  ];

  Widget get _titleEditButton {
    String semanticLabel = Localization().getStringEx('widget.card.button.title.edit.title', 'Edit Title');
    String semanticHint = Localization().getStringEx('widget.card.button.title.edit.hint', '');
    return InkWell(onTap: () => _onEditTitle(), child:
      Semantics(container: true, label: semanticLabel, hint: semanticHint, button: true, excludeSemantics: true, child:
        Padding(padding: _titleActionButtonPadding, child:
          Styles().images.getImage('edit')
        )
      )
    );
  }

  Widget get _titleEditDoneButton {
    String semanticLabel = Localization().getStringEx('panel.search.button.search.title', 'Search');
    String semanticHint = Localization().getStringEx('panel.search.button.search.hint', '');
    return InkWell(onTap: () => _onEditTitleDone(), child:
      Semantics(container: true, label: semanticLabel, hint: semanticHint, button: true, excludeSemantics: true, child:
        Padding(padding: _titleActionButtonPadding, child:
          Styles().images.getImage('check-accent', size: 22)
        )
      )
    );
  }

  Widget get _titleEditCancelButton {
    String semanticLabel = Localization().getStringEx('panel.search.button.clear.title', 'Clear');
    String semanticHint = Localization().getStringEx('panel.search.button.clear.hint', '');
    return InkWell(onTap: () => _onEditTitleClear(), child:
      Semantics(container: true, label: semanticLabel, hint: semanticHint, button: true, excludeSemantics: true, child:
        Padding(padding: _titleActionButtonPadding, child:
          Styles().images.getImage('times', size: 22)
        )
      )
    );
  }

  Widget get _favoriteButton {
    Widget? favoriteStarIcon = _explorePOI.favoriteStarIcon(selected: _isFavorite);
    String semanticLabel = _isFavorite ? Localization().getStringEx('widget.card.button.favorite.off.title', 'Remove From Favorites') : Localization().getStringEx('widget.card.button.favorite.on.title', 'Add To Favorites');
    String semanticHint = _isFavorite ? Localization().getStringEx('widget.card.button.favorite.off.hint', '') : Localization().getStringEx('widget.card.button.favorite.on.hint', '');
    return InkWell(onTap: () => _onTapFavorite(), child:
      Semantics(container: true, label: semanticLabel, hint: semanticHint, button: true, excludeSemantics: true, child:
        Padding(padding: _favoriteButtonPadding, child:
          favoriteStarIcon
        )
      )
    );
  }

  Widget get _detailsWidget =>
    Padding(padding: EdgeInsets.only(left: 16, right: 16, bottom: 16), child:
      Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        _positionDetailWidget,
        Padding(padding: EdgeInsets.only(top: 16), child:
          _directionsDetailWidget,
        ),
      ],)
    );

  Widget get _positionDetailWidget => Row(children: [
    Expanded(child:
      Text(_positionDetailText, maxLines: 1, overflow: TextOverflow.ellipsis, style:
        Styles().textStyles.getTextStyle('common.body'),
      )
    )
  ],);

  String get _positionDetailText =>
    _explorePOI.exploreLocation?.displayCoordinates ?? '';

  Widget get _directionsDetailWidget => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _directionsDetailTitle,
    if (_explorePOI.location?.isLocationCoordinateValid == true)
      Padding(padding: EdgeInsets.only(top: 8), child:
        _directionsDetailCommands,
      ),
  ],);

  Widget get _directionsDetailTitle => Row(children: [
    Expanded(child:
      RichText(text:
        TextSpan(style: _directionsDetailTitleTextStyle, children: <InlineSpan>[
          TextSpan(text: Localization().getStringEx('card.map2.explore_poi.label.directions.text', 'Directions')),
          TextSpan(text: ' '),
          WidgetSpan(alignment: PlaceholderAlignment.middle, child:
            Styles().images.getImage('external-link-dark', size: 14) ?? Container()
          )
        ]),
      )
    )
  ],);

  TextStyle? get _directionsDetailTitleTextStyle => Styles().textStyles.getTextStyle('widget.title.regular.fat');

  Widget get _directionsDetailCommands => Row(children: [
    Expanded(child:
      Wrap(spacing: 8, runSpacing: 8, children: [
        _DirectionsButton('person-walking', onTap: () => _onTapDirections(GeoMapUtils.traveModeWalking)),
        _DirectionsButton('bicycle', onTap: () => _onTapDirections(GeoMapUtils.traveModeBycycling)),
        _DirectionsButton('car', onTap: () => _onTapDirections(GeoMapUtils.traveModeDriving)),
        _DirectionsButton('bus', onTap: () => _onTapDirections(GeoMapUtils.traveModeTransit)),
      ],),
    )
  ],);

  bool _isPOIFavorite() => Auth2().canFavorite && Auth2().isFavorite(_explorePOI);

  void _onTapFavorite() {
    Analytics().logSelect(target: "Favorite: ${_explorePOI.exploreTitle}", source: '${runtimeType.toString()}(${_explorePOI.favoriteKey})');
    Auth2().prefs?.toggleFavorite(_explorePOI);
  }

  void _onTapDirections(String travelMode) {
    Analytics().logSelect(target: "Directions: $travelMode", source: '${runtimeType.toString()}(${_explorePOI.favoriteKey})');
    GeoMapUtils.launchDirections(destination: _explorePOI.location?.exploreLocationMapCoordinate, travelMode: travelMode);
  }

  void _onEditTitle() {
    if (_isEditingTitle != true) {
      setState(() {
        _isEditingTitle = true;
        _titleTextController.text = _titleText;
        _canSubmitTitle = _titleText.isNotEmpty;
      });
      WidgetsBinding.instance.addPostFrameCallback((_){
        _titleTextNode.requestFocus();
      });
    }
  }

  void _onEditTitleClear() {
    if (_isEditingTitle == true) {
      if (_titleTextController.text.isNotEmpty) {
        setState(() {
          _titleTextController.text = '';
          _canSubmitTitle = false;
        });
      }
      else {
        setState(() {
          _isEditingTitle = false;
          _canSubmitTitle = false;
        });
      }
    }
  }

  void _onEditTitleCancel() {
    if (_isEditingTitle == true) {
      setState(() {
        _isEditingTitle = false;
        _canSubmitTitle = false;
      });
    }
  }

  void _onEditTitleDone() {
    if ((_isEditingTitle == true) && _canSubmitTitle && (_titleTextController.text != _titleText)) {
      ExplorePOI oldExplorePOI = _explorePOI;
      ExplorePOI newExplorePOI = ExplorePOI.fromOther(_explorePOI,
        name: _titleTextController.text
      );
      setState(() {
        _explorePOI = newExplorePOI;
        _isEditingTitle = false;
        _canSubmitTitle = false;
      });
      if (Auth2().canFavorite && Auth2().isFavorite(oldExplorePOI)) {
        Auth2().prefs?.replaceFavorite(oldExplorePOI, newExplorePOI);
      }
      else {
        NotificationService().notify(Map2ExplorePOICard.notifyPOIUpdated, Pair(oldExplorePOI, newExplorePOI));
      }
    }
  }

  void _onEditTitleChanged() {
    bool canSubmitTitle = _titleTextController.text.isNotEmpty;
    if (_canSubmitTitle != canSubmitTitle) {
      setState(() {
        _canSubmitTitle = canSubmitTitle;
      });
    }
  }

  String get _semanticsLabel => '$_semanticsTitle, $_semanticsLocation';
  String get _semanticsTitle => _explorePOI.exploreTitle ?? '';
  String get _semanticsLocation => _positionDetailText;
}

class _DirectionsButton extends StatelessWidget {
  final String imageKey;
  final void Function()? onTap;

  // ignore: unused_element_parameter
  _DirectionsButton(this.imageKey, {super.key, this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(onTap: onTap, child:
    Container(decoration: _buttonDecoration, child:
      Padding(padding: EdgeInsets.all(12), child:
        SizedBox(width: _iconSize, height: _iconSize, child:
          Center(child:
            Styles().images.getImage(imageKey, size: _iconSize, color: Styles().colors.fillColorPrimary),
          ),
        )
      )
    )
  );

  static Decoration get _buttonDecoration => BoxDecoration(
    color: Styles().colors.surface,
    borderRadius: _buttonBorderRadius,
    border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
  );

  static const BorderRadiusGeometry _buttonBorderRadius = BorderRadius.all(_buttonRadius);
  static const Radius _buttonRadius = Radius.circular(8);
  static const double _iconSize = 18;
}