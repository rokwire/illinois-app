import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:illinois/ext/Explore.dart';
import 'package:illinois/ext/Places.dart';
import 'package:illinois/ext/Position.dart';
import 'package:rokwire_plugin/model/places.dart' as rokwire;
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/web_network_image.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class Map2PlaceCard extends StatefulWidget {
  final rokwire.Place place;
  final Position? currentLocation;
  final void Function()? onTap;

  Map2PlaceCard(this.place, { super.key,
    this.currentLocation,
    this.onTap,
  });

  @override
  State<StatefulWidget> createState() => _Map2PlaceCardState();
}

class _Map2PlaceCardState extends State<Map2PlaceCard> {

  @override
  Widget build(BuildContext context) =>
    Semantics(label: _semanticsLabel, button: true, child:
      InkWell(onTap: widget.onTap, child:
        _cardWidget
      )
    );

  Widget get _cardWidget =>
    Container(decoration: _cardDecoration, padding: _cardPadding, child:
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child:
          _infoSection,
        ),
        Padding(padding: EdgeInsets.only(left: 8), child:
          _imageSection,
        )
      ],)
    );

  Widget get _imageSection =>
    SizedBox(width: _imageWidth, height: _imageWidth, child: (widget.place.images?.isNotEmpty == true) ?
      WebNetworkImage(imageUrl: widget.place.images?.first.imageUrl ?? '', fit: BoxFit.cover, loadingBuilder: _imageProgressBuilder, errorBuilder: _imageErrorBuilder,) :
      Styles().images.getImage('missing-building-photo', fit: BoxFit.cover)
    );

  Widget _imageProgressBuilder(BuildContext context, Widget child, ImageChunkEvent? loadingProgress) => (loadingProgress != null) ?
    Container(decoration: _imageFrameDecoration, child:
      Center(child:
        SizedBox(width: 24, height: 24, child:
          CircularProgressIndicator(strokeWidth: 2, color: Styles().colors.fillColorSecondary,),
        ),
      )
    ) : child;

  Widget _imageErrorBuilder(BuildContext context, Object error, StackTrace? stackTrace) =>
    Styles().images.getImage('missing-building-photo', fit: BoxFit.cover) ?? Container(decoration: _imageFrameDecoration);

  Widget get _infoSection =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      _typesWidget,
      _titleWidget,
      _detailsWidget,
    ],);

  Widget get _typesWidget {
    List<String> displayTypes = widget.place.displayTypes;
    return displayTypes.isNotEmpty ? Padding(padding: EdgeInsets.only(bottom: 4), child:
      Wrap(spacing: 4, runSpacing: 2, children:
        List<Widget>.from(displayTypes.map((type) => _TypeChip(type))),
      ),
    ) : Container();
  }

  Widget get _titleWidget {
    return (widget.place.name?.isNotEmpty == true) ?
      Row(children: <Widget>[
        Expanded(child:
          RichText(text:
            TextSpan(style: _titleTextstyle, children: <InlineSpan>[
              TextSpan(text: widget.place.name ?? ''),
              TextSpan(text: ' '),
              WidgetSpan(alignment: PlaceholderAlignment.middle, child:
                Styles().images.getImage('chevron-right', size: 18) ?? Container()
              )
            ]),
          )
        )
      ]) : Container();
  }

  Widget get _detailsWidget {
    List<Widget> locationDetails = _locationDetailWidgets;
    return locationDetails.isNotEmpty ? Padding(padding: EdgeInsets.only(top: 4), child:
      Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: locationDetails,)
    ) : Container();
  }

  List<Widget> get _locationDetailWidgets {
    List<Widget> detailWidgets = <Widget>[];
    List<String> detailTexts = _locationDetailTexts;
    Widget? iconWidget = Styles().images.getImage('location', excludeFromSemantics: true);
    for (String detailText in detailTexts) {
      detailWidgets.add(Row(children: <Widget>[
        if (iconWidget != null)
          Padding(padding: EdgeInsets.only(right: 6), child:
            Opacity(opacity: detailWidgets.isEmpty ? 1 : 0, child:
              iconWidget,
            )
          ),
        Expanded(child:
          Text(detailText, maxLines: 1, overflow: TextOverflow.ellipsis, style: _detailTextstyle,)
        )
      ]));
    }
    return detailWidgets;
  }

  List<String> get _locationDetailTexts {
    String? locatoinInfo = widget.place.address ?? widget.place.exploreLocation?.displayCoordinates;
    String? dispayDistance = StringUtils.ensureEmpty(widget.currentLocation?.displayDistance(widget.place.exploreLocation));
    return <String>[
      if (locatoinInfo != null)
        locatoinInfo,
      if (dispayDistance != null)
        dispayDistance
    ];
  }

  double get _imageWidth => _screenWidth / 5;
  double get _screenWidth => context.mounted ? MediaQuery.of(context).size.width : 0;

  static Decoration get _imageFrameDecoration => BoxDecoration(
    color: Styles().colors.surface,
    border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
  );

  TextStyle? get _titleTextstyle => Styles().textStyles.getTextStyle('widget.title.medium.fat');
  TextStyle? get _detailTextstyle => Styles().textStyles.getTextStyle('common.body');

  static Decoration get _cardDecoration => BoxDecoration(
    color: Styles().colors.surface,
    borderRadius: _cardBorderRadius,
    border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
    boxShadow: [BoxShadow(color: Color.fromRGBO(19, 41, 75, 0.3), spreadRadius: 1.0, blurRadius: 1.0, offset: Offset(0, 2))]
  );

  static const EdgeInsetsGeometry _cardPadding = EdgeInsets.all(16);

  static const BorderRadiusGeometry _cardBorderRadius = BorderRadius.all(_cardRadius);
  static const Radius _cardRadius = Radius.circular(8);

  String get _semanticsLabel => '$_semanticsTitle, $_semanticsLocation';
  String get _semanticsTitle => widget.place.exploreTitle ?? '';
  String get _semanticsLocation => widget.place.address ?? '';
}

class _TypeChip extends StatelessWidget {
  final String type;

  // ignore: unused_element_parameter
  _TypeChip(this.type, {super.key});

  @override
  Widget build(BuildContext context) =>
    Container(padding: _chipPadding, decoration: _chipDecoration, child:
      Text(type, style: _typeTextStyle,
      ),
    );

  TextStyle? get _typeTextStyle => Styles().textStyles.getTextStyle('widget.colourful_button.title.regular.accent');
  
  static const EdgeInsetsGeometry _chipPadding = EdgeInsets.symmetric(vertical: 2, horizontal: 4);

  static Decoration get _chipDecoration => BoxDecoration(
    color: Styles().colors.fillColorPrimary,
    borderRadius: BorderRadius.circular(2),
  );
}