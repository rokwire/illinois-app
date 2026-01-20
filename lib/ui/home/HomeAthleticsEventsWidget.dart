
import 'dart:async';
import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:illinois/model/Analytics.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/ui/athletics/AthleticsHomePanel.dart';
import 'package:illinois/ui/events2/Event2HomePanel.dart';
import 'package:illinois/ui/home/HomeEvent2Widget.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:illinois/ui/settings/SettingsPrivacyPanel.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';

class HomeAthliticsEventsWidget extends StatefulWidget {

  final String? favoriteId;
  final StreamController<String>? updateController;

  HomeAthliticsEventsWidget({Key? key, this.favoriteId, this.updateController}) : super(key: key);

  static Widget handle({Key? key, String? favoriteId, HomeDragAndDropHost? dragAndDropHost, int? position}) =>
    HomeHandleWidget(key: key, favoriteId: favoriteId, dragAndDropHost: dragAndDropHost, position: position,
      title: title,
    );

  String get _title => title;
  static String get title => Localization().getStringEx('widget.home.athletics_events.title', 'Big 10 Events');

  State<HomeAthliticsEventsWidget> createState() => _HomeAthleticsEventsWidgetState();
}

class _HomeAthleticsEventsWidgetState extends State<HomeAthliticsEventsWidget> {
  late FavoriteContentType _contentType;

  @override
  void initState() {
    _contentType = FavoritesContentTypeImpl.fromJson(Storage().getHomeFavoriteSelectedContent(widget.favoriteId)) ?? FavoriteContentType.all;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return HomeFavoriteWidget(favoriteId: widget.favoriteId, title: widget._title, child:
      _contentWidget,
    );
  }

  Widget get _contentWidget => Column(mainAxisSize: MainAxisSize.min, children: [
    Padding(padding: EdgeInsets.only(left: 16, right: 16, bottom: 8), child:
      _contentTypeBar,
    ),
    ..._contentTypeWidgets,
  ],);

  Widget get _contentTypeBar => Row(children:List<Widget>.from(
    FavoriteContentType.values.map((FavoriteContentType contentType) => Expanded(child:
      HomeFavTabBarBtn(contentType.athliticsEventsTitle.toUpperCase(),
        position: contentType.position,
        selected: _contentType == contentType,
        onTap: () => _onContentType(contentType),
      )
    )),
  ));

  void _onContentType(FavoriteContentType contentType) {
    if ((_contentType != contentType) && mounted) {
      setState(() {
        _contentType = contentType;
        Storage().setHomeFavoriteSelectedContent(widget.favoriteId, contentType.toJson());
      });
    }
  }

  Iterable<Widget> get _contentTypeWidgets => FavoriteContentType.values.map((FavoriteContentType contentType) =>
    Visibility(visible: (_contentType == contentType), maintainState: true, child:
      HomeEvents2ImplWidget(
        updateController: widget.updateController,
        analyticsFeature: _analyticsFeature(contentType),
        emptyContentBuilder: _emptyContentBuilder(contentType),
        onViewAll: () => _onViewAll(contentType),
        filter: _eventFilter(contentType),
        sortType: Event2SortType.dateTime,
      ),
    ));

  // Event2 Filter
  Event2FilterParam _eventFilter(FavoriteContentType contentType) => Event2FilterParam(
    timeFilter: Event2TimeFilter.upcoming, customStartTime: null, customEndTime: null,
    types: LinkedHashSet<Event2TypeFilter>.from((contentType == FavoriteContentType.my) ? [Event2TypeFilter.favorite] : []),
    attributes: Event2HomePanel.athleticsCategoryAttributes,
  );

  // Analytics Feature
  AnalyticsFeature _analyticsFeature(FavoriteContentType contentType) =>
    AnalyticsFeature.Athletics;

  // View All
  void _onViewAll(FavoriteContentType contentType) {
    Analytics().logSelect(target: "View All", source: widget.runtimeType.toString());
    Navigator.push(context, CupertinoPageRoute(builder: (context) => AthleticsHomePanel(contentType: AthleticsContentType.events, starred: (contentType == FavoriteContentType.my),)));
  }

  // Empty Content Builder
  WidgetBuilder _emptyContentBuilder(FavoriteContentType contentType) {
    switch (contentType) {
      case FavoriteContentType.my: return _myEmptyContentBuilder;
      case FavoriteContentType.all: return _allEmptyContentBuilder;
    }
  }

  Widget _allEmptyContentBuilder(BuildContext context) => HomeMessageCard(
    message: Localization().getStringEx('widget.home.athletics_events.all.empty.description', 'No Athletics Events are available right now.')
  );

  static const String localScheme = 'local';
  static const String localAthleticsEventHost = 'athletics_event';
  static const String localUrlMacro = '{{local_url}}';
  static const String privacyScheme = 'privacy';
  static const String privacyLevelHost = 'level';
  static const String privacyUrlMacro = '{{privacy_url}}';

  Widget _myEmptyContentBuilder(BuildContext context) => HomeMessageHtmlCard(
    message: Localization().getStringEx("widget.home.athletics_events.my.empty.description", "Tap the \u2606 on items in <a href='$localUrlMacro'><b>Big 10 Events</b></a> for quick access here.  (<a href='$privacyUrlMacro'>Your privacy level</a> must be at least 2.)")
      .replaceAll(localUrlMacro, '$localScheme://$localAthleticsEventHost')
      .replaceAll(privacyUrlMacro, '$privacyScheme://$privacyLevelHost'),
    linkColor: Styles().colors.eventColor,
    onTapLink : (url) {
      Uri? uri = (url != null) ? Uri.tryParse(url) : null;
      if ((uri?.scheme == localScheme) && (uri?.host == localAthleticsEventHost)) {
        Analytics().logSelect(target: 'Big 10 Events', source: runtimeType.toString());
        Navigator.push(context, CupertinoPageRoute(builder: (context) => AthleticsHomePanel(contentType: AthleticsContentType.events, starred: true,)));
        //Event2HomePanel.present(context, attributes: Event2HomePanel.athleticsCategoryAttributes, analyticsFeature: AnalyticsFeature.Athletics);
      }
      else if ((uri?.scheme == privacyScheme) && (uri?.host == privacyLevelHost)) {
        Analytics().logSelect(target: 'Privacy Level', source: runtimeType.toString());
        Navigator.push(context, CupertinoPageRoute(builder: (context) => SettingsPrivacyPanel(mode: SettingsPrivacyPanelMode.regular,)));
      }
    },
  );
}

extension _FavoriteAthliticsEventsContentType on FavoriteContentType {
  String get athliticsEventsTitle {
    switch (this) {
      case FavoriteContentType.my: return Localization().getStringEx('widget.home.athletics_events.my.button.title', 'My Big 10 Events');
      case FavoriteContentType.all: return Localization().getStringEx('widget.home.athletics_events.all.button.title', 'All Big 10 Events');
    }
  }
}


