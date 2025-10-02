
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:illinois/ext/Explore.dart';
import 'package:illinois/model/Analytics.dart';
import 'package:illinois/model/Appointment.dart';
import 'package:illinois/model/Building.dart';
import 'package:illinois/model/Dining.dart';
import 'package:illinois/model/Explore.dart';
import 'package:illinois/model/Laundry.dart';
import 'package:illinois/model/MTD.dart';
import 'package:illinois/model/StudentCourse.dart';
import 'package:illinois/model/wellness/WellnessBuilding.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/academics/StudentCourses.dart';
import 'package:illinois/ui/appointments/AppointmentCard.dart';
import 'package:illinois/ui/dining/DiningCard.dart';
import 'package:illinois/ui/events2/Event2Widgets.dart';
import 'package:illinois/ui/explore/ExploreCard.dart';
import 'package:illinois/ui/map2/Map2LocationCard.dart';
import 'package:illinois/ui/home/HomeLaundryWidget.dart';
import 'package:illinois/ui/mtd/MTDWidgets.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/model/explore.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class Map2TraySheet extends StatefulWidget {
  final int? totalExploresCount;
  final Position? currentLocation;
  final List<Explore>? visibleExplores;
  final ScrollController? scrollController;
  final AnalyticsFeature? analyticsFeature;

  Map2TraySheet({super.key, this.visibleExplores, this.scrollController, this.currentLocation, this.totalExploresCount, this.analyticsFeature});

  @override
  State<StatefulWidget> createState() => _Map2TraySheetState();
}

class _Map2TraySheetState extends State<Map2TraySheet> {

  final GlobalKey _traySheetKey = GlobalKey();

  static const double _traySheetTopRadius = 24.0;
  static const Size _traySheetPadding = const Size(16, 20);
  static const double _traySheetDragHandleHeight = 3.0;
  static const double _traySheetDragHandleWidthFactor = 0.25;

  Set<String> _expandedBusStops = <String>{};

  @override
  Widget build(BuildContext context) =>
    Container(key: _traySheetKey, decoration: _traySheetDecoration, child:
      ClipRRect(borderRadius: _traySheetBorderRadius, child:
        CustomScrollView(controller: widget.scrollController, slivers: [
          SliverAppBar(
            pinned: true,
            toolbarHeight: _traySheetDragHandleHeight + _traySheetPadding.height,
            backgroundColor: Colors.transparent,
            title: _traySheetHeading,
          ),
          //SliverPadding(padding: EdgeInsets.only(top: 42), sliver:
          SliverList(
            delegate: SliverChildListDelegate(_traySheetListContent),
          ),
        ],),
      ),
    );

  BoxDecoration get _traySheetDecoration => BoxDecoration(
    color: Styles().colors.background,
    borderRadius: _traySheetBorderRadius,
    boxShadow: [_traySheetBoxShadow],
  );
  BorderRadius get _traySheetBorderRadius => BorderRadius.vertical(top: Radius.circular(_traySheetTopRadius));
  BoxShadow get _traySheetBoxShadow => BoxShadow(color: Styles().colors.blackTransparent018 /* Colors.black26 */, blurRadius: 12.0,);

  Widget get _traySheetHeading =>
  Stack(children: [
    Row(children: [
      Expanded(child:
        Padding(padding: EdgeInsets.only(left: 6), child:
          _traySheetHeadingInfo,
        )
      ),
    ],),
    Positioned.fill(child:
      Center(child:
        _traySheetDragHandle,
      )
    ),

  ],);
  /*Row(children: [
    Expanded(child: Align(alignment: Alignment.centerRight, child: _traySheetDebugDragInfo)),
    _traySheetDragHandle,
    Expanded(child: Container()),
  ],);*/

  Widget get _traySheetHeadingInfo {
    TextStyle? boldStyle = Styles().textStyles.getTextStyle('widget.message.tiny.fat');
    TextStyle? regularStyle = Styles().textStyles.getTextStyle('widget.message.tiny'); // widget.message.tiny
    return RichText(text: TextSpan(style: regularStyle, children: <InlineSpan>[
      TextSpan(text: Localization().getStringEx('panel.map2.tray.header.selected.label', 'Selected: '), style: boldStyle,),
      TextSpan(text: '${widget.visibleExplores?.length}/${widget.totalExploresCount}', style: regularStyle,),
    ]));
  }

  Widget get _traySheetDragHandle => Container(
    width: _traySheetWidth * _traySheetDragHandleWidthFactor,
    height: _traySheetDragHandleHeight,
    decoration: BoxDecoration(
      color: Styles().colors.dividerLineAccent,
      borderRadius: BorderRadius.circular(2.0),
    ),
  );

  double get _traySheetWidth => _traySheetKey.renderBoxSize?.width ?? _screenWidth;
  double get _screenWidth => context.mounted ? MediaQuery.of(context).size.width : 0;

  List<Widget> get _traySheetListContent {
    List<Widget> items = <Widget>[];
    if (widget.visibleExplores != null) {
      for (Explore explore in widget.visibleExplores!) {
        if (items.isNotEmpty) {
          items.add(SizedBox(height: _traySheetListCardSpacing(explore),));
        }
        items.add(Padding(padding: EdgeInsets.symmetric(horizontal: _traySheetPadding.width), child:
          _traySheetListCard(explore),
        ));
      }
      items.add(SizedBox(height: _traySheetPadding.height / 2,));
    }
    return items;
  }

  Widget _traySheetListCard(Explore explore) {
    if (explore is Event2) {
      return Event2Card(explore,
        userLocation: widget.currentLocation,
        onTap: () => _onTapListCard(explore),
      );
    }
    else if (explore is Dining) {
      return DiningCard(explore,
        onTap: (_) => _onTapListCard(explore),
      );
    }
    else if (explore is LaundryRoom) {
      return LaundryRoomCard(room: explore,
        onTap: () => _onTapListCard(explore),
      );
    }
    else if (explore is StudentCourse) {
      return StudentCourseCard(course: explore,
        analyticsFeature: widget.analyticsFeature,
      );
    }
    else if (explore is Appointment) {
      return AppointmentCard(appointment: explore,
        analyticsFeature: widget.analyticsFeature,
        onTap: () => _onTapListCard(explore),
      );
    }
    else if (explore is MTDStop) {
      return MTDStopCard(
        stop: explore,
        expanded: _expandedBusStops,
        onDetail: (_) => _onTapListCard(explore),
        onExpand: _onExpandMTDStop,
        currentPosition: widget.currentLocation,
        padding: EdgeInsets.zero,
      );
    }
    else if (explore is ExplorePOI) {
      return Map2ExplorePOICard(explore,
        currentLocation: widget.currentLocation,
        onTap: () => _onTapListCard(explore),
      );
    }
    else if ((explore is Building) || (explore is WellnessBuilding))  {
      return Map2LocationCard(explore,
        currentLocation: widget.currentLocation,
        onTap: () => _onTapListCard(explore),
      );
    }
    else {
      return ExploreCard(explore: explore,
        locationData: widget.currentLocation,
        onTap: () => _onTapListCard(explore)
      ); /* TBD */
    }
  }

  double _traySheetListCardSpacing(Explore explore) {
    if (explore is Event2) {
      return 8;
    }
    else if (explore is Dining) {
      return 8;
    }
    else if (explore is LaundryRoom) {
      return 4;
    }
    else if (explore is StudentCourse) {
      return 4;
    }
    else if (explore is Appointment) {
      return 4;
    }
    else if (explore is MTDStop) {
      return 4;
    }
    else /* if ((explore is Building) || (explore is WellnessBuilding) || (explore is ExplorePOI)) */ {
      return 8; /* TBD */
    }
  }

  /*Widget _traySheetListCard(Explore explore) =>
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
    );*/

  void _onTapListCard(Explore explore) {
    explore.exploreLaunchDetail(context,
      initialLocationData: widget.currentLocation,
      analyticsFeature: widget.analyticsFeature
    );
  }

  void _onExpandMTDStop(MTDStop? stop) {
    Analytics().logSelect(target: "Bus Stop: ${stop?.name}" );
    if (mounted && (stop?.id != null)) {
      setState(() {
        SetUtils.toggle(_expandedBusStops, stop?.id);
      });
    }
  }

}