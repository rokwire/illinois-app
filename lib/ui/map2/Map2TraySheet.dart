
import 'package:flutter/material.dart';
import 'package:illinois/ext/Explore.dart';
import 'package:illinois/model/Analytics.dart';
import 'package:rokwire_plugin/model/explore.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class Map2TraySheet extends StatefulWidget {
  final int? totalExploresCount;
  final List<Explore>? visibleExplores;
  final ScrollController? scrollController;
  final AnalyticsFeature? analyticsFeature;

  Map2TraySheet({super.key, this.visibleExplores, this.scrollController, this.totalExploresCount, this.analyticsFeature});

  @override
  State<StatefulWidget> createState() => _Map2TraySheetState();
}

class _Map2TraySheetState extends State<Map2TraySheet> {

  final GlobalKey _traySheetKey = GlobalKey();

  static const double _traySheetTopRadius = 24.0;
  static const Size _traySheetPadding = const Size(16, 20);
  static const double _traySheetDragHandleHeight = 3.0;
  static const double _traySheetDragHandleWidthFactor = 0.25;

  @override
  Widget build(BuildContext context) =>
    Container(key: _traySheetKey, decoration: _traySheetDecoration, child:
      ClipRRect(borderRadius: _traySheetBorderRadius, child:
        CustomScrollView(controller: widget.scrollController, slivers: [
          SliverAppBar(
            pinned: true,
            toolbarHeight: _traySheetDragHandleHeight + _traySheetPadding.height,
            backgroundColor: Colors.transparent,
            title: _traySheetDebugDragHandle,
          ),
          //SliverPadding(padding: EdgeInsets.only(top: 42), sliver:
          SliverList(
            delegate: SliverChildListDelegate(_traySheetListContent),
          ),
        ],),
      ),
    );

  BoxDecoration get _traySheetDecoration => BoxDecoration(
    color: Styles().colors.white,
    borderRadius: _traySheetBorderRadius,
    boxShadow: [_traySheetBoxShadow],
  );
  BorderRadius get _traySheetBorderRadius => BorderRadius.vertical(top: Radius.circular(_traySheetTopRadius));
  BoxShadow get _traySheetBoxShadow => BoxShadow(color: Styles().colors.blackTransparent018 /* Colors.black26 */, blurRadius: 12.0,);

  Widget get _traySheetDebugDragHandle => Row(children: [
    Expanded(child: Container()),
    _traySheetDragHandle,
    Expanded(child: Align(alignment: Alignment.centerRight, child: _traySheetDebugDragInfo))
  ],);

  Widget get _traySheetDebugDragInfo =>
    Text('${widget.visibleExplores?.length} / ${widget.totalExploresCount}', style: Styles().textStyles.getTextStyle('widget.message.tiny'),);

  Widget get _traySheetDragHandle => Container(
    width: _traySheetWidth * _traySheetDragHandleWidthFactor, height: _traySheetDragHandleHeight,
    decoration: BoxDecoration(color: Styles().colors.lightGray, borderRadius: BorderRadius.circular(2.0),),
  );

  double get _traySheetWidth => _traySheetKey.renderBoxSize?.width ?? _screenWidth;
  double get _screenWidth => context.mounted ? MediaQuery.of(context).size.width : 0;

  List<Widget> get _traySheetListContent {
    List<Widget> items = <Widget>[];
    if (widget.visibleExplores != null) {
      for (Explore explore in widget.visibleExplores!) {
        if (items.isNotEmpty) {
          items.add(SizedBox(height: 8,));
        }
        items.add(_traySheetDebugListCard(explore));
      }
      items.add(SizedBox(height: _traySheetPadding.height / 2,));
    }
    return items;
  }

  Widget _traySheetDebugListCard(Explore explore) =>
    InkWell(onTap: () => _onTapListCard(explore), child:
      Container(
        decoration: BoxDecoration(
          color: explore.uiColor ?? Styles().colors.disabledTextColor,
          borderRadius: BorderRadius.all(Radius.circular(6.0)),
        ),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        margin: EdgeInsets.symmetric(horizontal: _traySheetPadding.width),
        child: Row(children: [
          Expanded(child:
            Text("${explore.exploreTitle ?? ''}", style: Styles().textStyles.getTextStyle('widget.dialog.message.medium'),),
          ),
          Padding(padding: EdgeInsets.only(left: 8), child:
            Styles().images.getImage('chevron-right', color: Styles().colors.white)
          )
        ],)
      )
    );

  void _onTapListCard(Explore explore) {
    explore.exploreLaunchDetail(context, analyticsFeature: widget.analyticsFeature);
  }

}