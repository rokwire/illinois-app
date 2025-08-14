
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/ext/Explore.dart';
import 'package:illinois/model/Analytics.dart';
import 'package:illinois/model/StudentCourse.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Gateway.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/QrCodePanel.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:illinois/ui/explore/DisplayFloorPlanPanel.dart';

class ExploreBuildingDetailPanel extends StatefulWidget with AnalyticsInfo {
  final Building? building;
  final String? buildingNumber;
  final ExploreSelectLocationBuilder? selectLocationBuilder;
  final AnalyticsFeature? analyticsFeature; //This overrides AnalyticsInfo.analyticsFeature getter

  ExploreBuildingDetailPanel({super.key, this.building, this.buildingNumber, this.analyticsFeature, this.selectLocationBuilder });

  @override
  State<StatefulWidget> createState() => _ExploreBuildingDetailPanelState();
}

class _ExploreBuildingDetailPanelState extends State<ExploreBuildingDetailPanel> {

  Building? _building;
  bool _loadingBuilding = false;

  @override
  void initState() {
    if (widget.building != null) {
      _building = widget.building;
    }
    else if (widget.buildingNumber != null) {
      _loadingBuilding = true;
      Gateway().loadBuilding(buildingNumber: widget.buildingNumber).then((Building? building){
        if (mounted) {
          setState(() {
            _loadingBuilding = false;
            _building = building;
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
          flexImageUrl: (_building != null) ? _building?.imageURL : null,
          flexWidget: (_building == null) ? Container(color: Styles().colors.background,) : null,
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
    if (_building != null) {
      return _buildBuildingContent();
    }
    else if (_loadingBuilding == true) {
      return _buildLoadingContent();
    }
    else {
      return _buildErrorContent();
    }
  }

  Widget _buildBuildingContent() =>
    Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildTitle(),
      _buildLocation(),
      _buildShare(),
      if (_building?.floors?.isNotEmpty == true)
        _buildFloorPlansAndAmenities(),
      _buildSelectLocation(),
      if (_building?.features?.isNotEmpty == true)
        _buildFeatureList(),
    ]);

  Widget _buildTitle() =>
    Padding(padding: EdgeInsets.symmetric(vertical: 10), child:
      Row(crossAxisAlignment: CrossAxisAlignment.center, mainAxisAlignment: MainAxisAlignment.start, children: <Widget>[
        Expanded(child:
          Text(_building?.name ?? "", style: Styles().textStyles.getTextStyle("widget.title.large.fat")),
        ),
      ],),
    );

  Widget _buildLocation() =>
    Visibility(visible: _canLocation(), child:
      InkWell(onTap: _onLocation, child:
        Padding(padding: EdgeInsets.symmetric(vertical: 10, ), child:
          Row(children: [
            Padding(padding: EdgeInsets.only(right: 6), child:
              Styles().images.getImage('location', excludeFromSemantics: true),
            ),
            Expanded(child:
              Text(_building?.fullAddress ?? '', style:
                Styles().textStyles.getTextStyle("widget.button.light.title.medium.underline")
              ),
            )
          ],),
        ),
      ),
    );

  Widget _buildShare() =>
    InkWell(onTap: _onShare, child:
      Padding(padding: EdgeInsets.symmetric(vertical: 10, ), child:
        Row(children: [
          Padding(padding: EdgeInsets.only(right: 6), child:
            Styles().images.getImage('share-nodes', excludeFromSemantics: true),
          ),
          Expanded(child:
            Text(Localization().getStringEx('panel.explore_building_detail.detail.share', 'Share This Location'), style:
              Styles().textStyles.getTextStyle("widget.button.light.title.medium.underline")
            ),
          )
        ],),
      ),
    );

  Widget _buildFloorPlansAndAmenities() =>
    Visibility(visible: _canFloorPlansAndAmenities(), child:
      InkWell(onTap: _onFloorPlansAndAmenities, child:
        Padding(padding: EdgeInsets.symmetric(vertical: 10, ), child:
          Row(children: [
            Padding(padding: EdgeInsets.only(right: 6), child:
              Styles().images.getImage('floorplan', excludeFromSemantics: true),
            ),
            Expanded(child:
              Text(Localization().getStringEx('panel.explore_building_detail.detail.fllor_plan_and_amenities', 'Floor Plans & Amenities'), style:
                Styles().textStyles.getTextStyle("widget.button.light.title.medium.underline")
              ),
            )
          ],),
        ),
      ),
    );

  Widget _buildSelectLocation() {
    Widget? selectorWidget = widget.selectLocationBuilder?.call(context, ExploreSelectLocationContext.detail, explore: _building);
    return (selectorWidget != null) ? Padding(padding: EdgeInsets.only(top: 32), child: selectorWidget) : Container();
  }

  Widget _buildFeatureList() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: EdgeInsets.symmetric(vertical: 10), child:
        Text(Localization().getStringEx('panel.explore_building_detail.detail.heading.amenities', 'Amenities include:'), style: Styles().textStyles.getTextStyle("widget.button.light.title.medium"))
      ),
      Padding(padding: EdgeInsets.only(left: 16.0), child:
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: _building?.features?.map((feature) =>
          (feature.value?.name?.isNotEmpty == true) ? Text(feature.detailText, style: Styles().textStyles.getTextStyle("widget.button.light.title.medium"),) : Container()
        ).toList() ?? [],)
      )
    ]);
  }

  Widget _buildLoadingContent() => Center(child:
    Padding(padding: EdgeInsets.zero, child:
      SizedBox(width: 32, height: 32, child: _loadingBuilding ?
        CircularProgressIndicator(color: Styles().colors.fillColorSecondary, strokeWidth: 3, ) : null
      )
    ),
  );

  Widget _buildErrorContent() => Center(child:
    Padding(padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 64), child:
        Text(Localization().getStringEx('panel.explore_building_detail.message.failed', 'Failed to load location details'), style: Styles().textStyles.getTextStyle("widget.message.large"), textAlign: TextAlign.center,)
    ),
  );

  bool _canLocation() =>
    StringUtils.isNotEmpty(_building?.fullAddress);

  void _onLocation() {
    Analytics().logSelect(target: "Location Directions");
    _building?.launchDirections();
  }

  void _onShare() {
    Analytics().logSelect(target: "Share This Location");
    if (_building != null) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) =>
        QrCodePanel.fromBuilding(_building, analyticsFeature: AnalyticsFeature.Map,)
      ));
    }
  }

  bool _canFloorPlansAndAmenities() =>
    true; // TODO: control when detail item should be viisble

  void _onFloorPlansAndAmenities() {
    Analytics().logSelect(target: "Floor Plans & Amenities");
    // TODO: present the relevant UI
    Navigator.push(context, CupertinoPageRoute(builder: (context) => DisplayFloorPlanPanel(building: _building)));
  }
}

extension _BuildingFeatureExt on BuildingFeature {

  String get detailText {
    String resourcePatern;
    final String nameMacro = '{{name}}';
    final String floorsMacro = '{{floors}}';
    int floorsCount = value?.floors?.length ?? 0;
    if (floorsCount > 1) {
      resourcePatern = Localization().getStringEx('panel.explore_building_detail.detail.entry.amenity.floors', '• $nameMacro: Floors $floorsMacro');
    } else if (floorsCount == 1) {
      resourcePatern = Localization().getStringEx('panel.explore_building_detail.detail.entry.amenity.floor', '• $nameMacro: Floor $floorsMacro');
    } else {
      resourcePatern = Localization().getStringEx('panel.explore_building_detail.detail.entry.amenity', '• $nameMacro');
    }
    return resourcePatern
      .replaceAll(nameMacro, value?.name ?? '')
      .replaceAll(floorsMacro, value?.floors?.join(", ") ?? '');
  }

}
