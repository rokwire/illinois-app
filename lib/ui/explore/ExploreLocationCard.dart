
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:illinois/ext/Position.dart';
import 'package:illinois/model/StudentCourse.dart';
import 'package:illinois/model/wellness/WellnessBuilding.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/Guide.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class ExploreLocationCard extends StatelessWidget {
  final String? imageUrl;
  final String? title;
  final List<String>? locationDetails;
  final void Function()? onTap;
  ExploreLocationCard({ super.key, this.imageUrl, this.title, this.locationDetails, this.onTap});

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
          _imageHeadingWidget,
          Padding(padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16), child:
            Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              _titleWidget,
              _detailsWidget,
            ]),
          ),
        ],),
      ),
    );

  Widget get _imageHeadingWidget =>
    Visibility(visible: (imageUrl?.isNotEmpty == true), child:
      Container(decoration: _imageHeadingDecoration, child:
        AspectRatio(aspectRatio: 2.5, child:
          Image.network(imageUrl ?? '', fit: BoxFit.cover, headers: Config().networkAuthHeaders, excludeFromSemantics: true)
        ),
      )
    );

  Widget get _titleWidget =>
    Row(children: [
      Expanded(child:
        _titleContentWidget
      ),
    ],);

  Widget get _titleContentWidget =>
    Text(title ?? '', style: Styles().textStyles.getTextStyle('widget.title.medium.fat'), maxLines: 2, overflow: TextOverflow.ellipsis);

  Widget get _detailsWidget {
    List<Widget> detailWidgets = <Widget>[
      ...?_locationDetailsWidget,
    ];

    return detailWidgets.isNotEmpty ? Padding(padding: EdgeInsets.only(top: 4), child:
      Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: detailWidgets,)
    ) : Container();
  }

  List<Widget>? get _locationDetailsWidget => <Widget>[
    if (locationDetails?.isNotEmpty == true)
      _buildDetailWidget('location', List<Widget>.from(locationDetails?.map((String text) =>
        Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: Styles().textStyles.getTextStyle('common.body'),),
      ) ?? []), contentPadding: EdgeInsets.zero)
  ];

  Widget _buildDetailWidget(String iconKey, List<Widget> contentWidgets, {
    EdgeInsetsGeometry contentPadding = const EdgeInsets.only(top: 4),
    EdgeInsetsGeometry iconPadding = const EdgeInsets.only(right: 6),
  }) {
    List<Widget> contentRows = <Widget>[];
    Widget? iconWidget = Styles().images.getImage(iconKey, excludeFromSemantics: true);
    for (int index = 0; index < contentWidgets.length; index++) {
      contentRows.add(Row(children: <Widget>[
        if (iconWidget != null)
          Padding(padding: iconPadding, child:
            Opacity(opacity: (0 < index) ? 0 : 1, child:
              iconWidget,
            )
          ),
        Expanded(child:
          contentWidgets[index]
        )
      ]));
    }
    return contentRows.isNotEmpty ? Padding(padding: contentPadding, child:
      Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children:
        contentRows
      )
    ) : Container();
  }

  static Decoration get _cardDecoration => BoxDecoration(
    color: Styles().colors.surface,
    borderRadius: _cardBorderRadius,
    border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
    boxShadow: [BoxShadow(color: Color.fromRGBO(19, 41, 75, 0.3), spreadRadius: 1.0, blurRadius: 1.0, offset: Offset(0, 2))]
  );

  static BorderRadiusGeometry get _cardBorderRadius => BorderRadius.all(Radius.circular(8));

  Decoration get _imageHeadingDecoration => BoxDecoration(
    border: Border(bottom: BorderSide(color: Styles().colors.surfaceAccent, width: 1)),
  );

  String get _semanticsLabel => '$_semanticsTitle, $_semanticsLocation';
  String get _semanticsTitle => title ?? '';
  String get _semanticsLocation => ListUtils.last(locationDetails) ?? '';

}

class ExploreBuildingCard extends StatelessWidget {
  final Building building;
  final Position? currentLocation;
  final void Function()? onTap;
  ExploreBuildingCard(this.building, { super.key, this.currentLocation, this.onTap });

  @override
  Widget build(BuildContext context) {
    String? dispayDistance = currentLocation?.displayDistance(building.exploreLocation);
    return ExploreLocationCard(
      imageUrl: building.imageURL,
      title: building.name,
      locationDetails: [
        if (building.fullAddress?.isNotEmpty == true)
          building.fullAddress ?? '',
        if (dispayDistance?.isNotEmpty == true)
          dispayDistance ?? '',
      ],
      onTap: onTap,
    );
  }
}

class ExploreWellnessBuildingCard extends StatelessWidget {
  final WellnessBuilding wellnessBuilding;
  final Position? currentLocation;
  final void Function()? onTap;
  ExploreWellnessBuildingCard(this.wellnessBuilding, { super.key, this.currentLocation, this.onTap });

  @override
  Widget build(BuildContext context) {
    //String? guideImage = StringUtils.ensureEmpty(Guide().entryValue(wellnessBuilding.guideEntry, 'image'));
    String? guideTitle = StringUtils.ensureEmpty(Guide().entryListTitle(wellnessBuilding.guideEntry));
    String? dispayDistance = StringUtils.ensureEmpty(currentLocation?.displayDistance(wellnessBuilding.building.exploreLocation));

    return ExploreLocationCard(
      imageUrl: /*guideImage ??*/ wellnessBuilding.building.imageURL,
      title: guideTitle ?? wellnessBuilding.building.name,
      locationDetails: [
        if ((wellnessBuilding.building.name?.isNotEmpty == true) && (guideTitle?.isNotEmpty == true))
          wellnessBuilding.building.name ?? '',
        if (wellnessBuilding.building.fullAddress?.isNotEmpty == true)
          wellnessBuilding.building.fullAddress ?? '',
        if (dispayDistance?.isNotEmpty == true)
          dispayDistance ?? '',
      ],
      onTap: onTap,
    );
  }
}
