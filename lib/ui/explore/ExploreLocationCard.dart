
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:illinois/ext/Explore.dart';
import 'package:illinois/ext/Position.dart';
import 'package:illinois/service/Config.dart';
import 'package:rokwire_plugin/model/explore.dart';
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
          Padding(padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16), child:
            Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              _titleWidget,
              _detailsWidget,
            ]),
          ),
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
    Row(children: [
      Expanded(child:
        _titleContentWidget
      ),
    ],);

  Widget get _titleContentWidget =>
    Text(explore?.exploreTitle ?? '', style: Styles().textStyles.getTextStyle('widget.title.medium.fat'), maxLines: 2, overflow: TextOverflow.ellipsis);

  Widget get _detailsWidget {
    List<Widget> detailWidgets = ListUtils.stripNull(<Widget?>[
      _locationDetailsWidget,
    ]);

    return detailWidgets.isNotEmpty ? Padding(padding: EdgeInsets.only(top: 4), child:
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
    return <String>[
      if ((building != null) && building.isNotEmpty &&
          ((title == null) || title.isEmpty || (!building.contains(title) && title.contains(building))) &&
          ((fullAddress == null) || fullAddress.isEmpty || (!fullAddress.contains(building) && !building.contains(fullAddress)))
         )
        building,
      if ((fullAddress != null) && fullAddress.isNotEmpty)
        fullAddress,
      if ((dispayDistance != null) && dispayDistance.isNotEmpty)
        dispayDistance,
    ];
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
