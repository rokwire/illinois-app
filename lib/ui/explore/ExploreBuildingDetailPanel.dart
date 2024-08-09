import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/ext/Explore.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

import '../../model/StudentCourse.dart';

class ExploreBuildingDetailPanel extends StatefulWidget {

  final Building building;

  ExploreBuildingDetailPanel({Key? key, required this.building}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ExploreBuildingDetailPanelState();

}

class _ExploreBuildingDetailPanelState extends ExploreBuildingDetailPanelState<ExploreBuildingDetailPanel> {

  Building? _building;

  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    _building = widget.building;
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body:
    Column(children: <Widget>[
      Expanded(child: _content),
    ])
    );
  }

  Widget get _content =>
    CustomScrollView(controller: _scrollController, slivers: <Widget>[
      SliverToutHeaderBar(
        flexImageUrl: _building?.imageURL,
        flexRightToLeftTriangleColor: Colors.white,
      ),
      SliverList(delegate: SliverChildListDelegate([
        Padding(padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10), child:
          Row(crossAxisAlignment: CrossAxisAlignment.center, mainAxisAlignment: MainAxisAlignment.start, children: <Widget>[
            Expanded(child:
              Text(_building?.name ?? "", style: Styles().textStyles.getTextStyle("widget.title.large.fat")),
            ),
          ],),
        ),
        Visibility(visible: _canLocation(), child:
          InkWell(onTap: _onLocation, child:
            Padding(padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10), child:
              Row(children: [
                Padding(padding: EdgeInsets.only(right: 6), child:
                  Styles().images.getImage('location', excludeFromSemantics: true),
                  ),
                Expanded(child:
                  Text(_building?.fullAddress ?? '', style: Styles().textStyles.getTextStyle("widget.button.light.title.medium.underline")
                  ),
                )
              ],),
            ),
          ),
        ),
      ]))
    ]);

  void _onLocation() {
    Analytics().logSelect(target: "Location Directions");
    _building!.launchDirections();
  }

  bool _canLocation() =>
      StringUtils.isNotEmpty(_building?.fullAddress);
}

abstract class ExploreBuildingDetailPanelState<T extends StatefulWidget> extends State<T> {
  final Map<String, dynamic> selectorData = <String, dynamic>{};
  void setSelectorState(VoidCallback fn) => setState(fn);
}

