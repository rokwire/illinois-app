import 'package:flutter/material.dart';
import 'package:illinois/model/Analytics.dart';
import 'package:illinois/ui/explore/ExploreStoriedSightsBottomSheet.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/model/places.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/places.dart';
import 'package:rokwire_plugin/service/styles.dart';

class ExplorePlaceDetailPanel extends StatefulWidget with AnalyticsInfo {
  final Place? place;
  final String? placeId;
  final AnalyticsFeature? analyticsFeature; //This overrides AnalyticsInfo.analyticsFeature getter

  ExplorePlaceDetailPanel({super.key, this.place, this.placeId, this.analyticsFeature});

  @override
  State<StatefulWidget> createState() => _ExplorePlaceDetailPanelState();
}

class _ExplorePlaceDetailPanelState extends State<ExplorePlaceDetailPanel> {
  Place? _place;
  bool _loadingPlace = false;

  String? get _placeImageUrl =>
    (_place?.images?.isNotEmpty == true) ? _place!.images!.first.imageUrl : null;

  @override
  void initState() {
    if (widget.place != null) {
      _place = widget.place;
    }
    else if (widget.placeId != null) {
      _loadingPlace = true;
      Places().getAllPlaces(ids:<String>{ widget.placeId! }).then((List<Place>? places){
        if (mounted) {
          setState(() {
            _loadingPlace = false;
            if ((places != null) && places.isNotEmpty) {
              _place = places.first;
            }
          });
        }
      });
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) =>
    Scaffold(
      body: _buildScaffoldContent(),
      backgroundColor: Styles().colors.background,
      bottomNavigationBar: uiuc.TabBar()
    );

  Widget _buildScaffoldContent() => Column(children: <Widget>[
    Expanded(child:
      CustomScrollView(slivers: <Widget>[
        SliverToutHeaderBar(
          flexImageUrl: _placeImageUrl,
          flexWidget: (_place == null) ? Container(color: Styles().colors.background,) : ((_placeImageUrl == null) ? Styles().images.getImage('missing-building-photo', fit: BoxFit.cover) : null),
          flexRightToLeftTriangleColor: Styles().colors.background,
          flexLeftToRightTriangleColor: Styles().colors.fillColorSecondaryTransparent05,
        ),
        SliverList(delegate:
          SliverChildListDelegate([
            Padding(padding: EdgeInsets.all(16), child:
              _buildPanelContent()
            ),
          ], addSemanticIndexes:false)
        ),
      ]),
    ),
  ]);

  Widget _buildPanelContent() {
    if (_place != null) {
      return _buildPlaceContent();
    }
    else if (_loadingPlace == true) {
      return _buildLoadingContent();
    }
    else {
      return _buildErrorContent();
    }
  }

  Widget _buildPlaceContent() => ExploreStoriedSightWidget(place: _place!, showDetailImage: false, onTapBack: null,);

  Widget _buildLoadingContent() => Center(child:
    Padding(padding: EdgeInsets.zero, child:
      SizedBox(width: 32, height: 32, child: _loadingPlace ?
        CircularProgressIndicator(color: Styles().colors.fillColorSecondary, strokeWidth: 3, ) : null
      )
    ),
  );

  Widget _buildErrorContent() => Center(child:
    Padding(padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 64), child:
        Text(Localization().getStringEx('panel.explore.storied_sites.load.error', 'Failed to load stored site details'), style: Styles().textStyles.getTextStyle("widget.message.large"), textAlign: TextAlign.center,)
    ),
  );
}