import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:expandable_page_view/expandable_page_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:illinois/ext/Favorite.dart';
import 'package:illinois/model/Dining.dart';
import 'package:illinois/model/Explore.dart';
import 'package:illinois/model/Laundry.dart';
import 'package:illinois/model/MTD.dart';
import 'package:illinois/model/News.dart';
import 'package:illinois/model/sport/Game.dart';
import 'package:illinois/model/Appointment.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Appointments.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/Dinings.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/service/Guide.dart';
import 'package:illinois/service/Laundries.dart';
import 'package:illinois/service/MTD.dart';
import 'package:illinois/service/Sports.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/ui/SavedPanel.dart';
import 'package:illinois/ui/explore/ExploreCard.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:illinois/ui/mtd/MTDWidgets.dart';
import 'package:illinois/ui/appointments/AppointmentCard.dart';
import 'package:illinois/ui/widgets/LinkButton.dart';
import 'package:illinois/ui/widgets/SemanticsWidgets.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/model/event.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/events.dart';
import 'package:rokwire_plugin/service/events2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class HomeFavoritesWidget extends StatefulWidget {

  final String? favoriteId;
  final String favoriteKey;
  final StreamController<String>? updateController;

  static const String localScheme = 'local';
  static const String localUrlMacro = '{{local_url}}';

  HomeFavoritesWidget({Key? key, required this.favoriteKey, this.favoriteId, this.updateController}) : super(key: key);

  static Widget handle({required String favoriteKey, Key? key, String? favoriteId, HomeDragAndDropHost? dragAndDropHost, int? position}) =>
    HomeHandleWidget(key: key, favoriteId: favoriteId, dragAndDropHost: dragAndDropHost, position: position,
      title: titleFromKey(favoriteKey: favoriteKey),
    );
  
  static String? titleFromKey({required String favoriteKey}) {
    switch(favoriteKey) {
      case Event.favoriteKeyName: return Localization().getStringEx('widget.home.favorites.title.events', 'My Events');
      case Event2.favoriteKeyName: return Localization().getStringEx('widget.home.favorites.title.events2', 'My Events');
      case Dining.favoriteKeyName: return Localization().getStringEx('widget.home.favorites.title.dining', 'My Dining Locations');
      case Game.favoriteKeyName: return Localization().getStringEx('widget.home.favorites.title.athletics', 'My Athletics Events');
      case News.favoriteKeyName: return Localization().getStringEx('widget.home.favorites.title.news', 'My Athletics News');
      case LaundryRoom.favoriteKeyName: return Localization().getStringEx('widget.home.favorites.title.laundry', 'My Laundry');
      case MTDStop.favoriteKeyName: return Localization().getStringEx('widget.home.favorites.title.mtd_stops', 'My Bus Stops');
      case ExplorePOI.favoriteKeyName: return Localization().getStringEx('widget.home.favorites.title.mtd_destinations', 'My Destinations');
      case GuideFavorite.favoriteKeyName: return Localization().getStringEx('widget.home.favorites.title.campus_guide', 'My Campus Guide');
      case Appointment.favoriteKeyName: return Localization().getStringEx('widget.home.favorites.title.appointments', 'MyMcKinley Appointments');
    }
    return null;
  }

  @override
  _HomeFavoritesWidgetState createState() => _HomeFavoritesWidgetState();

  static String? emptyMessageHtml(String key) {
    String? message;
    switch(key) {
      case Event.favoriteKeyName: message = Localization().getStringEx("widget.home.favorites.message.empty.events", "Tap the \u2606 on items in <a href='$localUrlMacro'><b>Events</b></a> for quick access here."); break;
      case Event2.favoriteKeyName: message = Localization().getStringEx("widget.home.favorites.message.empty.events2", "Tap the \u2606 on items in <a href='$localUrlMacro'><b>Events Feed</b></a> for quick access here."); break;
      case Dining.favoriteKeyName: message = Localization().getStringEx("widget.home.favorites.message.empty.dining", "Tap the \u2606 on items in <a href='$localUrlMacro'><b>Dining</b></a> for quick access here."); break;
      case Game.favoriteKeyName: message = Localization().getStringEx("widget.home.favorites.message.empty.athletics", "Tap the \u2606 on items in <a href='$localUrlMacro'><b>Athletics Events</b></a> for quick access here."); break;
      case News.favoriteKeyName: message = Localization().getStringEx("widget.home.favorites.message.empty.news", "Tap the \u2606 on items in <a href='$localUrlMacro'><b>Athletics News</b></a> for quick access here."); break;
      case LaundryRoom.favoriteKeyName: message = Localization().getStringEx("widget.home.favorites.message.empty.laundry", "Tap the \u2606 on items in <a href='$localUrlMacro'><b>Laundry Locations</b></a> for quick access here."); break;
      case MTDStop.favoriteKeyName: message = Localization().getStringEx("widget.home.favorites.message.empty.mtd_stops", "Tap the \u2606 on items in <a href='$localUrlMacro'><b>Bus Stops</b></a> for quick access here."); break;
      case ExplorePOI.favoriteKeyName: message = Localization().getStringEx("widget.home.favorites.message.empty.mtd_destinations", "Tap the \u2606 on items in <a href='$localUrlMacro'><b>My Destinations</b></a> for quick access here."); break;
      case GuideFavorite.favoriteKeyName: message = Localization().getStringEx("widget.home.favorites.message.empty.campus_guide", "Tap the \u2606 on items in <a href='$localUrlMacro'><b>Campus Guide</b></a> for quick access here."); break;
      case Appointment.favoriteKeyName:
        message = (Storage().appointmentsCanDisplay != true) ?
          Localization().getStringEx('widget.home.favorites.message.empty.appointments.not_to_display', 'There is nothing to display as you have chosen not to display any past or future appointments.') :
          Localization().getStringEx("widget.home.favorites.message.empty.appointments", "Tap the \u2606 on items in <a href='$localUrlMacro'><b>MyMcKinley Appointments</b></a> for quick access here.");
        break;
    }
    return (message != null) ? message.replaceAll(localUrlMacro, '$localScheme://${key.toLowerCase()}') : null;
  }

  static Color? linkColor(String key) {
    switch(key) {
      case Event.favoriteKeyName: return Styles().colors?.eventColor;
      case Event2.favoriteKeyName: return Styles().colors?.eventColor;
      case Dining.favoriteKeyName: return Styles().colors?.diningColor;
      case Game.favoriteKeyName: return Styles().colors?.fillColorPrimary;
      case News.favoriteKeyName: return Styles().colors?.fillColorPrimary;
      case LaundryRoom.favoriteKeyName: return Styles().colors?.accentColor2;
      case MTDStop.favoriteKeyName: return Styles().colors?.accentColor3;
      case ExplorePOI.favoriteKeyName: return Styles().colors?.accentColor3;
      case GuideFavorite.favoriteKeyName: return Styles().colors?.accentColor3;
      case Appointment.favoriteKeyName: return Styles().colors?.accentColor3;
    }
    return null;
  }

  static void handleLocalUrl(String? url, {required BuildContext context, String? analyticsTarget, String? analyticsSource}) {
    Uri? uri = (url != null) ? Uri.tryParse(url) : null;
    if (uri?.scheme == HomeFavoritesWidget.localScheme) {
      Analytics().logSelect(target: analyticsTarget, source: analyticsSource);
      FavoriteExt.launchHome(context, key: uri?.host);
    }
  }
}

class _HomeFavoritesWidgetState extends State<HomeFavoritesWidget> implements NotificationsListener {

  List<Favorite>? _favorites;
  LinkedHashSet<String>? _favoriteIds;
  bool _loadingFavorites = false;
  
  PageController? _pageController;
  Key _pageViewKey = UniqueKey();
  Map<Favorite, GlobalKey> _contentKeys = <Favorite, GlobalKey>{};
  Favorite? _currentFavorite;
  int _currentPage = -1;
  final double _pageSpacing = 16;
  
  @override
  void initState() {
    NotificationService().subscribe(this, [
      Connectivity.notifyStatusChanged,
      Auth2UserPrefs.notifyFavoritesChanged,
      Auth2.notifyLoginChanged,
      FlexUI.notifyChanged,
      Guide.notifyChanged,
      Config.notifyConfigChanged,
      Storage.notifySettingChanged,
      Appointments.notifyUpcomingAppointmentsChanged
    ]);
    
    if (widget.updateController != null) {
      widget.updateController!.stream.listen((String command) {
        if (command == HomePanel.notifyRefresh) {
          _refreshFavorites();
        }
      });
    }

    _refreshFavorites();
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    _pageController?.dispose();
    super.dispose();
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if ((name == Config.notifyConfigChanged) ||
        (name == Connectivity.notifyStatusChanged) ||
        (name == Auth2.notifyLoginChanged) ||
        (name == FlexUI.notifyChanged)) {
      if (mounted) {
        setState(() {});
      }
    }
    else if ((name == Auth2UserPrefs.notifyFavoritesChanged) ||
            (name == Guide.notifyChanged)) {
      _refreshFavorites(showProgress: false);
    }
    else if (name == Storage.notifySettingChanged) {
      if ((widget.favoriteKey == Appointment.favoriteKeyName) && (param == Storage().appointmentsDisplayEnabledKey)) {
        _initFavorites((_favoriteIds ?? LinkedHashSet<String>()), showProgress: true);
      }
    }
    else if (name == Appointments.notifyUpcomingAppointmentsChanged) {
      if (widget.favoriteKey == Appointment.favoriteKeyName) {
        _initFavorites((_favoriteIds ?? LinkedHashSet<String>()), showProgress: false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return HomeSlantWidget(favoriteId: widget.favoriteId,
      title: headingTitle,
      titleIconKey: headingIconKey,
      child: _buildContent()
    );
  }

  Widget _buildContent() {
    if (Connectivity().isOffline) {
      return HomeMessageCard(title: Localization().getStringEx("common.message.offline", "You appear to be offline"), message: _offlineMessage,);
    }
    else if (_loadingFavorites) {
      return HomeProgressWidget();
    }
    else if ((_favorites == null) || (_favorites!.length == 0)) {
      return _buildEmpty();
    }
    else {
      return _buildFavorites();
    }
  }

  Widget _buildFavorites() {
    Widget contentWidget;
    int visibleCount = _favorites?.length ?? 0; // min(Config().homeFavoriteItemsCount, ...)
    if (1 < visibleCount) {

      List<Widget> pages = [];
      for (int index = 0; index < visibleCount; index++) {
        Favorite favorite = _favorites![index];
        pages.add(Padding(key: _contentKeys[favorite] ??= GlobalKey(), padding: EdgeInsets.only(right: _pageSpacing), child:
          _buildItemCard(favorite)),
        );
      }

      if (_pageController == null) {
        double screenWidth = MediaQuery.of(context).size.width;
        double pageViewport = (screenWidth - 2 * _pageSpacing) / screenWidth;
        _pageController = PageController(viewportFraction: pageViewport, initialPage: _currentPage);
      }

      contentWidget = Container(constraints: BoxConstraints(minHeight: _pageHeight), child:
        ExpandablePageView(
          key: _pageViewKey,
          controller: _pageController,
          estimatedPageSize: _pageHeight,
          onPageChanged: _onCurrentPageChanged,
          allowImplicitScrolling: true,
          children: pages
        ),
      );
    }
    else {
      contentWidget = Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
        _buildItemCard(_favorites!.first),
      );
    }

    return Column(children: <Widget>[
      Padding(padding: EdgeInsets.only(top: 8), child:
        contentWidget,
      ),
      AccessibleViewPagerNavigationButtons(controller: _pageController, pagesCount: () => visibleCount, centerWidget:
        LinkButton(
          title: Localization().getStringEx('panel.saved.button.all.title', 'View All'),
          hint: _viewAllHint,
          onTap: _onTapViewAll,
        )      
      ),
    ]);
  }

  Widget _buildItemCard(Favorite? item) {
    //Custom layout for super events before release
    if (item is Event && item.isComposite) {
      return ExploreCard(
        explore: item,
        showTopBorder: true,
        horizontalPadding: 0,
        border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1),
        onTap:() => _onTapItem(item)
      );
    }
    else if (item is MTDStop) {
      return MTDStopScheduleCard(
        stop: item,
        onTap: () => _onTapItem(item),
      );
    }
    else if (item is Appointment) {
      return AppointmentCard(
        appointment: item,
      );
    }

    bool isFavorite = Auth2().isFavorite(item);
    Widget? favoriteStarIcon = item?.favoriteStarIcon(selected: isFavorite);
    Color? headerColor = item?.favoriteHeaderColor;
    String? title = item?.favoriteTitle;
    String? cardDetailText = item?.favoriteDetailText;
    Color? cardDetailTextColor = item?.favoriteDetailTextColor ?? Styles().colors?.textBackground;
    Widget? cardDetailImage = StringUtils.isNotEmpty(cardDetailText) ? item?.favoriteDetailIcon : null;
    bool detailVisible = StringUtils.isNotEmpty(cardDetailText);
    return GestureDetector(onTap: () => _onTapItem(item), child:
      Semantics(label: title, child:
        Column(children: <Widget>[
          Container(height: 7, color: headerColor,),
          Container(decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1), borderRadius: BorderRadius.only(bottomLeft: Radius.circular(4), bottomRight: Radius.circular(4))), child:
            Padding(padding: EdgeInsets.all(16), child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                  Flex(direction: Axis.vertical, children: <Widget>[
                    Row(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: <Widget>[
                      Expanded(child:
                        Text(title ?? '', semanticsLabel: "", style: Styles().textStyles?.getTextStyle("widget.card.title.medium.extra_fat")),
                      ),
                      Visibility(visible: Auth2().canFavorite && (favoriteStarIcon != null), child:
                        GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => _onTapFavoriteStar(item), child:
                          Semantics(container: true,
                            label: isFavorite
                                ? Localization().getStringEx('widget.card.button.favorite.off.title', 'Remove From Favorites')
                                : Localization().getStringEx('widget.card.button.favorite.on.title', 'Add To Favorites'),
                            hint: isFavorite
                                ? Localization().getStringEx('widget.card.button.favorite.off.hint', '')
                                : Localization().getStringEx('widget.card.button.favorite.on.hint', ''),
                            button: true,
                            excludeSemantics: true,
                            child: Container(padding: EdgeInsets.only(left: 24, bottom: 24), child: favoriteStarIcon))),
                          )
                        ],
                      )
                    ],
                  ),
                  Visibility(visible: detailVisible, child:
                    Semantics(label: cardDetailText, excludeSemantics: true, child:
                      Padding(padding: EdgeInsets.only(top: 12), child:
                        (cardDetailImage != null) ? 
                        Row(children: <Widget>[
                          Padding(padding: EdgeInsets.only(right: 10), child: cardDetailImage,),
                          Expanded(child:
                            Text(cardDetailText ?? '', semanticsLabel: "", style: Styles().textStyles?.getTextStyle("widget.card.detail.medium")?.copyWith(color: cardDetailTextColor)),
                          )
                        ],) :
                        Text(cardDetailText ?? '', semanticsLabel: "", style: Styles().textStyles?.getTextStyle("widget.card.detail.medium")?.copyWith(color: cardDetailTextColor)),
                  )),)
                ]),
              ),
            )
          ],
        )),);
  }

  void _refreshFavorites({bool showProgress = true}) {
    if (Connectivity().isOnline) {
      LinkedHashSet<String> refFavoriteIds = Auth2().prefs?.getFavorites(widget.favoriteKey) ?? LinkedHashSet<String>();
      if (!DeepCollectionEquality().equals(_favoriteIds, refFavoriteIds)) {
        _initFavorites(refFavoriteIds, showProgress: showProgress);
      }
    }
  }

  void _initFavorites(LinkedHashSet<String> refFavoriteIds, {bool showProgress = true}) {
    if (showProgress && mounted) {
      setState(() {
        _loadingFavorites = true;
      });
    }
    LinkedHashSet<String> favoriteIds = LinkedHashSet<String>.from(refFavoriteIds);
    _loadFavorites(favoriteIds).then((List<Favorite>? favorites) {
      if (mounted) {
        setState(() {
          _favoriteIds = favoriteIds;
          _favorites = favorites;
          _updateCurrentPage();
        });
      }
    }).whenComplete(() {
      if (mounted) {
        setState(() {
          _loadingFavorites = false;
        });
      }
    });
  }

  double get _pageHeight {

    double? minContentHeight;
    for(GlobalKey contentKey in _contentKeys.values) {
      final RenderObject? renderBox = contentKey.currentContext?.findRenderObject();
      if ((renderBox is RenderBox) && ((minContentHeight == null) || (renderBox.size.height < minContentHeight))) {
        minContentHeight = renderBox.size.height;
      }
    }

    return minContentHeight ?? 0;
  }

  void _onCurrentPageChanged(int index) {
    _currentFavorite = ListUtils.entry(_favorites, _currentPage = index);
  }

  void _updateCurrentPage() {
    if ((_currentPage < 0) || (_currentFavorite == null)) {
      if (_favorites?.isNotEmpty ?? false) {
        _currentPage = 0;
        _currentFavorite = _favorites?.first;
      }
    }
    else {
      if (_favorites?.isNotEmpty ?? false) {
        int currentPage = (_currentFavorite != null) ? _favorites!.indexOf(_currentFavorite!) : -1;
        if (currentPage < 0) {
          currentPage = max(0, min(_currentPage, _favorites!.length - 1));
        }

        _currentFavorite = _favorites![_currentPage = currentPage];
      }
      else {
        _currentPage = -1;
        _currentFavorite = null;
      }

      _pageViewKey = UniqueKey();
      // _pageController = null; //Doing this will break the listener in the buttons, instead reset to first page
      _pageController?.jumpToPage(0);
      _contentKeys.clear();
    }
  }

  Future<List<Favorite>?> _loadFavorites(LinkedHashSet<String>? favoriteIds) async {
    if (CollectionUtils.isNotEmpty(favoriteIds)) {
      switch(widget.favoriteKey) {
        case Event.favoriteKeyName: return _loadFavoriteEvents(favoriteIds);
        case Event2.favoriteKeyName: return _loadFavoriteEvents2(favoriteIds);
        case Dining.favoriteKeyName: return _loadFavoriteDinings(favoriteIds);
        case Game.favoriteKeyName: return _loadFavoriteGames(favoriteIds);
        case News.favoriteKeyName: return _loadFavoriteNews(favoriteIds);
        case LaundryRoom.favoriteKeyName: return _loadFavoriteLaundries(favoriteIds);
        case MTDStop.favoriteKeyName: return _loadFavoriteMTDStops(favoriteIds);
        case ExplorePOI.favoriteKeyName: return _loadFavoriteMTDDestinations(favoriteIds);
        case GuideFavorite.favoriteKeyName: return _loadFavoriteGuideItems(favoriteIds);
        case Appointment.favoriteKeyName: return _loadFavoriteAppointments(favoriteIds);
      }
    }
    return null;
  }

  Future<List<Favorite>?> _loadFavoriteEvents(LinkedHashSet<String>? favoriteIds) async =>
    CollectionUtils.isNotEmpty(favoriteIds) ? _buildFavoritesList(await Events().loadEventsByIds(favoriteIds), favoriteIds) : null;

  Future<List<Favorite>?> _loadFavoriteEvents2(LinkedHashSet<String>? favoriteIds) async =>
    CollectionUtils.isNotEmpty(favoriteIds) ? _buildFavoritesList(await Events2().loadEventsList(Events2Query(ids: favoriteIds)), favoriteIds) : null;

  Future<List<Favorite>?> _loadFavoriteDinings(LinkedHashSet<String>? favoriteIds) async =>
    CollectionUtils.isNotEmpty(favoriteIds) ? _buildFavoritesList(await Dinings().loadBackendDinings(false, null, null), favoriteIds) : null;

  Future<List<Favorite>?> _loadFavoriteGames(LinkedHashSet<String>? favoriteIds) async =>
    CollectionUtils.isNotEmpty(favoriteIds) ? _buildFavoritesList(await Sports().loadGames(), favoriteIds) : null;

  Future<List<Favorite>?> _loadFavoriteNews(LinkedHashSet<String>? favoriteIds) async =>
    CollectionUtils.isNotEmpty(favoriteIds) ? _buildFavoritesList(await Sports().loadNews(null, 0), favoriteIds) : null;

  Future<List<Favorite>?> _loadFavoriteLaundries(LinkedHashSet<String>? favoriteIds) async =>
    CollectionUtils.isNotEmpty(favoriteIds) ? _buildFavoritesList((await Laundries().loadSchoolRooms())?.rooms, favoriteIds) : null;

  Future<List<Favorite>?> _loadFavoriteMTDStops(LinkedHashSet<String>? favoriteIds) async =>
    CollectionUtils.isNotEmpty(favoriteIds) ? ListUtils.reversed(MTD().stopsByIds(favoriteIds)) : null;

  Future<List<Favorite>?> _loadFavoriteMTDDestinations(LinkedHashSet<String>? favoriteIds) async =>
    CollectionUtils.isNotEmpty(favoriteIds) ? ListUtils.reversed(ExplorePOI.listFromString(favoriteIds)) : null;

  Future<List<Favorite>?> _loadFavoriteGuideItems(LinkedHashSet<String>? favoriteIds) async {
    List<Favorite>? guideItems;
    if ((favoriteIds != null) && (Guide().contentList != null)) {
      
      Map<String, Favorite> favorites = <String, Favorite>{};
      for (dynamic contentEntry in Guide().contentList!) {
        String? guideEntryId = Guide().entryId(JsonUtils.mapValue(contentEntry));
        
        if ((guideEntryId != null) && favoriteIds.contains(guideEntryId)) {
          favorites[guideEntryId] = GuideFavorite(id: guideEntryId);
        }
      }

      if (favorites.isNotEmpty) {
        List<Favorite> result = <Favorite>[];
        for (String favoriteId in favoriteIds) {
          Favorite? favorite = favorites[favoriteId];
          if (favorite != null) {
            result.add(favorite);
          }
        }
        guideItems = List.from(result.reversed);
      }
    }
    return guideItems;
  }

  Future<List<Favorite>?> _loadFavoriteAppointments(LinkedHashSet<String>? favoriteIds) async =>
      (CollectionUtils.isNotEmpty(favoriteIds) && (Storage().appointmentsCanDisplay == true))
          ? _buildFavoritesList(Appointments().getAppointments(timeSource: AppointmentsTimeSource.upcoming), favoriteIds)
          : null;

  List<Favorite>? _buildFavoritesList(List<Favorite>? sourceList, LinkedHashSet<String>? favoriteIds) {
    if ((sourceList != null) && (favoriteIds != null)) {
      Map<String, Favorite> favorites = <String, Favorite>{};
      if (sourceList.isNotEmpty && favoriteIds.isNotEmpty) {
        for (Favorite sourceItem in sourceList) {
          if ((sourceItem.favoriteId != null) && favoriteIds.contains(sourceItem.favoriteId)) {
            favorites[sourceItem.favoriteId!] = sourceItem;
          }
        }
      }

      List<Favorite>? result = <Favorite>[];
      if (favorites.isNotEmpty) {
        for (String favoriteId in favoriteIds) {
          Favorite? favorite = favorites[favoriteId];
          if (favorite != null) {
            result.add(favorite);
          }
        }
      }
      
      // show last added at top
      return List.from(result.reversed);
    }
    return null;
  }

  Widget _buildEmpty() {
    return Padding(padding: EdgeInsets.only(left: 16, right: 16, bottom: 16), child:
      Container(decoration: BoxDecoration(color: Styles().colors!.surface, borderRadius: BorderRadius.all(Radius.circular(4)), boxShadow: [BoxShadow(color: Styles().colors!.blackTransparent018!, spreadRadius: 2.0, blurRadius: 6.0, offset: Offset(2, 2))] ),
        padding: EdgeInsets.all(16),
        child:  HtmlWidget(
            HomeFavoritesWidget.emptyMessageHtml(widget.favoriteKey) ?? '',
            onTapUrl : (url) {HomeFavoritesWidget.handleLocalUrl(url, context: context, analyticsTarget: 'View Home', analyticsSource: 'HomeFavoritesWidget(${widget.favoriteKey})'); return true;},
            textStyle:  Styles().textStyles?.getTextStyle("widget.card.detail.regular"),
            customStylesBuilder: (element) => (element.localName == "a") ? {"color": ColorUtils.toHex(HomeFavoritesWidget.linkColor(widget.favoriteKey) ?? Colors.red)} : null
        )
      ),
    );
  }


  String? get headingTitle => HomeFavoritesWidget.titleFromKey(favoriteKey: widget.favoriteKey);


  String? get headingIconKey {
    switch(widget.favoriteKey) {
      case Event.favoriteKeyName: return 'calendar';
      case Event2.favoriteKeyName: return 'calendar';
      case Dining.favoriteKeyName: return 'dining';
      case Game.favoriteKeyName: return 'athletics';
      case News.favoriteKeyName: return 'news';
      case LaundryRoom.favoriteKeyName: return 'laundry';
      case MTDStop.favoriteKeyName: return 'location';
      case ExplorePOI.favoriteKeyName: return 'location';
      case GuideFavorite.favoriteKeyName: return 'guide';
      case Appointment.favoriteKeyName: return 'calendar';
    }
    return null;
  }

  String? get _offlineMessage {
    switch(widget.favoriteKey) {
      case Event.favoriteKeyName: return Localization().getStringEx('widget.home.favorites.message.offline.events', 'My Events are not available while offline.');
      case Event2.favoriteKeyName: return Localization().getStringEx('widget.home.favorites.message.offline.events2', 'My Events are not available while offline.');
      case Dining.favoriteKeyName: return Localization().getStringEx('widget.home.favorites.message.offline.dining', 'My Dining Locations are not available while offline.');
      case Game.favoriteKeyName: return Localization().getStringEx('widget.home.favorites.message.offline.athletics', 'My Athletics Events are not available while offline.');
      case News.favoriteKeyName: return Localization().getStringEx('widget.home.favorites.message.offline.news', 'My Athletics News are not available while offline.');
      case LaundryRoom.favoriteKeyName: return Localization().getStringEx('widget.home.favorites.message.offline.laundry', 'My Laundry are not available while offline.');
      case MTDStop.favoriteKeyName: return Localization().getStringEx('widget.home.favorites.message.offline.mtd_stops', 'My Bus Stops are not available while offline.');
      case ExplorePOI.favoriteKeyName: return Localization().getStringEx('widget.home.favorites.message.offline.mtd_destinations', 'My Destinations are not available while offline.');
      case GuideFavorite.favoriteKeyName: return Localization().getStringEx('widget.home.favorites.message.offline.campus_guide', 'My Campus Guide are not available while offline.');
      case Appointment.favoriteKeyName: return Localization().getStringEx('widget.home.favorites.message.offline.appointments', 'MyMcKinley Appointments are not available while offline.');
    }
    return null;
  }

  String? get _viewAllHint {
    switch(widget.favoriteKey) {
      case Event.favoriteKeyName: return Localization().getStringEx('widget.home.favorites.all.hint.events', 'Tap to view all favorite events');
      case Event2.favoriteKeyName: return Localization().getStringEx('widget.home.favorites.all.hint.events', 'Tap to view all favorite events');
      case Dining.favoriteKeyName: return Localization().getStringEx('widget.home.favorites.all.hint.dining', 'Tap to view all favorite dinings');
      case Game.favoriteKeyName: return Localization().getStringEx('widget.home.favorites.all.hint.athletics', 'Tap to view all favorite athletics events');
      case News.favoriteKeyName: return Localization().getStringEx('widget.home.favorites.all.hint.news', 'Tap to view all favorite athletics news');
      case LaundryRoom.favoriteKeyName: return Localization().getStringEx('widget.home.favorites.all.hint.laundry', 'Tap to view all favorite laundries');
      case MTDStop.favoriteKeyName: return Localization().getStringEx('widget.home.favorites.all.hint.mtd_stops', 'Tap to view all favorite bus stops');
      case ExplorePOI.favoriteKeyName: return Localization().getStringEx('widget.home.favorites.all.hint.mtd_destinations', 'Tap to view all favorite destinations');
      case GuideFavorite.favoriteKeyName: return Localization().getStringEx('widget.home.favorites.all.hint.campus_guide', 'Tap to view all favorite campus guide articles');
      case Appointment.favoriteKeyName: return Localization().getStringEx('widget.home.favorites.all.hint.appointments', 'Tap to view all favorite appointments');
    }
    return null;
  }

  void _onTapItem(Favorite? item) {
    Analytics().logSelect(target: item?.favoriteTitle, source: '${widget.runtimeType.toString()}(${widget.favoriteKey})');
    item?.favoriteLaunchDetail(context);
  }

  void _onTapFavoriteStar(Favorite? item) {
    Analytics().logSelect(target: "Favorite: ${item?.favoriteTitle}", source: '${widget.runtimeType.toString()}(${widget.favoriteKey})');
    Auth2().prefs?.toggleFavorite(item);
  }

  void _onTapViewAll() {
    Analytics().logSelect(target: 'View All', source: '${widget.runtimeType.toString()}(${widget.favoriteKey})');
    if ((widget.favoriteKey == MTDStop.favoriteKeyName) || (widget.favoriteKey == ExplorePOI.favoriteKeyName)) {
      FavoriteExt.launchHome(context, key: widget.favoriteKey);
    }
    else {
      Navigator.push(context, CupertinoPageRoute(builder: (context) { return SavedPanel(favoriteCategories: [widget.favoriteKey]); } ));
    }
  }
}

