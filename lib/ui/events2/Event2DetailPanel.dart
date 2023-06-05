import 'package:flutter/material.dart';
import 'package:illinois/ext/Event2.dart';
import 'package:illinois/ext/Explore.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:intl/intl.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/model/content_attributes.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/service/app_datetime.dart';
import 'package:rokwire_plugin/service/events2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:timezone/timezone.dart';

class Event2DetailPanel extends StatefulWidget implements AnalyticsPageAttributes {
  final Event2? event;
  Event2DetailPanel({this.event});
  
  @override
  State<StatefulWidget> createState() => _Event2DetailPanelState();

  // AnalyticsPageAttributes

  @override
  Map<String, dynamic>? get analyticsPageAttributes => event?.analyticsAttributes;
}

class _Event2DetailPanelState extends State<Event2DetailPanel> implements NotificationsListener {

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Auth2UserPrefs.notifyFavoritesChanged,
    ]);

    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }


  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == Auth2UserPrefs.notifyFavoritesChanged) {
      setStateIfMounted(() { });
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(body:
      Column(children: <Widget>[
        Expanded(child:
          CustomScrollView(slivers: <Widget>[
            SliverToutHeaderBar(
              flexImageUrl: widget.event?.imageUrl,
              flexRightToLeftTriangleColor: Colors.white,
            ),
            SliverList(delegate:
              SliverChildListDelegate([
                _categoriesWidget,
                Padding(padding: EdgeInsets.only(left: 16, right: 16, bottom: 16), child:
                  Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _titleWidget,
                    _sponsorWidget,
                    _detailsWidget,
                  ]),
                ),

              ], addSemanticIndexes:false)
            ),
          ])
        ),
      ])
    );
  }

  Widget get _categoriesWidget => 
    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child:
        Padding(padding: EdgeInsets.only(left: 16, top: 16, bottom: 8), child:
          Text(_displayCategories?.join(', ') ?? '', overflow: TextOverflow.ellipsis, maxLines: 2, style: Styles().textStyles?.getTextStyle("widget.card.title.small.fat"))
        ),
      ),
      _favoriteButton
    ]);

  List<String>? get _displayCategories =>
    Events2().contentAttributes?.displayAttributeValuesListFromSelection(widget.event?.attributes, usage: ContentAttributeUsage.category);

  Widget get _favoriteButton {
    bool isFavorite = Auth2().isFavorite(widget.event);
    return Opacity(opacity: Auth2().canFavorite ? 1 : 0, child:
      Semantics(container: true,
        child: Semantics(
          label: isFavorite ?
            Localization().getStringEx('widget.card.button.favorite.off.title', 'Remove From Favorites') :
            Localization().getStringEx('widget.card.button.favorite.on.title', 'Add To Favorites'),
          hint: isFavorite ?
            Localization().getStringEx('widget.card.button.favorite.off.hint', '') :
            Localization().getStringEx('widget.card.button.favorite.on.hint', ''),
          button: true,
          child: InkWell(onTap: _onFavorite,
            child: Padding(padding: EdgeInsets.all(16),
              child: Styles().images?.getImage(isFavorite ? 'star-filled' : 'star-outline-gray', excludeFromSemantics: true,)
            )
          ),
        ),
      )
    );
  }

  Widget get _titleWidget => Row(children: [
    Expanded(child: 
      Text(widget.event?.name ?? '', style: Styles().textStyles?.getTextStyle('widget.title.extra_large'), maxLines: 2,)
    ),
  ],);

  Widget get _sponsorWidget => StringUtils.isNotEmpty(widget.event?.sponsor) ? Padding(padding: EdgeInsets.only(top: 8), child:
    Row(children: [
      Expanded(child: 
        Text(widget.event?.sponsor ?? '', style: Styles().textStyles?.getTextStyle('widget.item.regular.fat'), maxLines: 2,)
      ),
    ],),
   ) : Container();

  Widget get _detailsWidget {
    List<Widget> detailWidgets = <Widget>[
      ...?_dateDetailWidget,
      ...?_onlineDetailWidget,
      ...?_locationDetailWidget,
    ];

    return detailWidgets.isNotEmpty ? Padding(padding: EdgeInsets.only(top: 16), child:
      Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: detailWidgets,)
    ) : Container();
    
  }

  List<Widget>? get _dateDetailWidget {
    TZDateTime? dateTimeUni = widget.event?.startTimeUtc?.toUniOrLocal();
    return (dateTimeUni != null) ? <Widget>[_buildTextDetailWidget(DateFormat('MMM d, ha').format(dateTimeUni), 'calendar')] : null;
  }

  List<Widget>? get _onlineDetailWidget {
    if (widget.event?.online == true) {
      bool canLaunch = StringUtils.isNotEmpty(widget.event?.onlineDetails?.url);
      List<Widget> details = <Widget>[
        InkWell(onTap: canLaunch ? _onOnline : null, child:
          _buildTextDetailWidget('Online', 'laptop'),
        ),
      ];

      Widget onlineWidget = canLaunch ?
        Text(widget.event?.onlineDetails?.url ?? '', style: Styles().textStyles?.getTextStyle('widget.button.title.small.semi_bold.underline'),) :
        Text(widget.event?.onlineDetails?.url ?? '', style: Styles().textStyles?.getTextStyle('widget.explore.card.detail.regular'),);
      details.add(
        InkWell(onTap: canLaunch ? _onOnline : null, child:
          _buildDetailWidget(onlineWidget, 'laptop', iconVisible: false, contentPadding: EdgeInsets.zero)
        )
      );

      return details;
    }
    return null;
  }

  List<Widget>? get _locationDetailWidget {
    if (widget.event?.online != true) {

      bool canLocation = widget.event?.location?.isLocationCoordinateValid ?? false;
      
      List<Widget> details = <Widget>[
        InkWell(onTap: canLocation ? _onLocation : null, child:
          _buildTextDetailWidget('In Person', 'location'),
        ),
      ];

      String? locationText = (
        widget.event?.location?.displayName ??
        widget.event?.location?.displayAddress ??
        widget.event?.location?.displayCoordinates
      );
      if (locationText != null) {
        Widget locationWidget = canLocation ?
          Text(locationText, maxLines: 1, style: Styles().textStyles?.getTextStyle('widget.button.title.small.semi_bold.underline'),) :
          Text(locationText, maxLines: 1, style: Styles().textStyles?.getTextStyle('widget.explore.card.detail.regular'),);
        details.add(
          InkWell(onTap: canLocation ? _onLocation : null, child:
            _buildDetailWidget(locationWidget, 'location', iconVisible: false, contentPadding: EdgeInsets.zero)
          )
        );
      }
      return details;
    }
    return null;
  }

  Widget _buildTextDetailWidget(String text, String iconKey, {
    EdgeInsetsGeometry contentPadding = const EdgeInsets.only(top: 4),
    EdgeInsetsGeometry iconPadding = const EdgeInsets.only(right: 6),
    bool iconVisible = true
  }) =>
    _buildDetailWidget(
      Text(text, maxLines: 1, style: Styles().textStyles?.getTextStyle('widget.explore.card.detail.regular'),),
      iconKey,
      contentPadding: contentPadding,
      iconPadding: iconPadding,
      iconVisible: iconVisible
    );

  Widget _buildDetailWidget(Widget contentWidget, String iconKey, {
    EdgeInsetsGeometry contentPadding = const EdgeInsets.only(top: 4),
    EdgeInsetsGeometry iconPadding = const EdgeInsets.only(right: 6),
    bool iconVisible = true
  }) {
    List<Widget> contentList = <Widget>[];
    Widget? iconWidget = Styles().images?.getImage(iconKey, excludeFromSemantics: true);
    if (iconWidget != null) {
      contentList.add(Padding(padding: iconPadding, child:
        Opacity(opacity: iconVisible ? 1 : 0, child:
          iconWidget,
        )
      ));
    }
    contentList.add(Expanded(child:
      contentWidget
    ),);
    return Padding(padding: contentPadding, child:
      Row(children: contentList)
    );
  }

  void _onLocation() {
    Analytics().logSelect(target: "Location Directions: ${widget.event?.name}");
    widget.event?.launchDirections();
  }

  void _onOnline() {
    Analytics().logSelect(target: "Online Url: ${widget.event?.name}");
  }

  void _onFavorite() {
    Analytics().logSelect(target: "Favorite: ${widget.event?.name}");
    Auth2().prefs?.toggleFavorite(widget.event);
  }
}
