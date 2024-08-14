
import 'package:flutter/material.dart';
import 'package:neom/ext/Explore.dart';
import 'package:neom/model/StudentCourse.dart';
import 'package:neom/service/Analytics.dart';
import 'package:neom/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:neom/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/utils/utils.dart';

class ExploreBuildingDetailPanel extends StatelessWidget {
  final Building building;

  ExploreBuildingDetailPanel({Key? key, required this.building}) : super(key: key);

  @override
  Widget build(BuildContext context) =>
    Scaffold(
      body: _buildContent(context),
      backgroundColor: Styles().colors.background,
      bottomNavigationBar: uiuc.TabBar()
    );

  Widget _buildContent(BuildContext context) => Column(children: <Widget>[
    Expanded(child:
      CustomScrollView(slivers: <Widget>[
        SliverToutHeaderBar(
          flexImageUrl:  building.imageURL,
          flexRightToLeftTriangleColor: Styles().colors.background,
          flexLeftToRightTriangleColor: Colors.transparent,
        ),
        SliverList(delegate:
          SliverChildListDelegate([
            Padding(padding: EdgeInsets.all(16), child:
              Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                _buildTitle(),
                _buildLocation(),
                // _buildFloorPlansAndAmenities(),
              ])
            ),
          ], addSemanticIndexes:false)
        ),
      ]),
    ),
  ]);

  Widget _buildTitle() =>
    Padding(padding: EdgeInsets.symmetric(vertical: 10), child:
      Row(crossAxisAlignment: CrossAxisAlignment.center, mainAxisAlignment: MainAxisAlignment.start, children: <Widget>[
        Expanded(child:
          Text(building.name ?? "", style: Styles().textStyles.getTextStyle("widget.title.large.fat")),
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
              Text(building.fullAddress ?? '', style: Styles().textStyles.getTextStyle("widget.button.light.title.medium.underline")
              ),
            )
          ],),
        ),
      ),
    );

  // ignore: unused_element
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

  bool _canLocation() =>
    StringUtils.isNotEmpty(building.fullAddress);

  void _onLocation() {
    Analytics().logSelect(target: "Location Directions");
    building.launchDirections();
  }

  bool _canFloorPlansAndAmenities() =>
    true; // TODO: control when detail item should be viisble

  void _onFloorPlansAndAmenities() {
    Analytics().logSelect(target: "Floor Plans & Amenities");
    // TODO: present the relevant UI
  }
}