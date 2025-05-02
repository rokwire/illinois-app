import 'dart:async';
import 'package:illinois/model/Analytics.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:universal_io/io.dart';
import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/DeepLink.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/ui/SavedPanel.dart';
import 'package:illinois/ui/appointments/AppointmentsContentWidget.dart';
import 'package:illinois/ui/academics/AcademicsHomePanel.dart';
import 'package:illinois/ui/academics/StudentCourses.dart';
import 'package:illinois/ui/athletics/AthleticsContentPanel.dart';
import 'package:illinois/ui/canvas/CanvasCoursesListPanel.dart';
import 'package:illinois/ui/canvas/GiesCanvasCoursesListPanel.dart';
import 'package:illinois/ui/directory/DirectoryAccountsList.dart';
import 'package:illinois/ui/directory/DirectoryAccountsPanel.dart';
import 'package:illinois/ui/events2/Event2HomePanel.dart';
import 'package:illinois/ui/groups/GroupsHomePanel.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/home/HomeRecentItemsWidget.dart';
import 'package:illinois/ui/home/HomeTwitterWidget.dart';
import 'package:illinois/ui/messages/MessagesHomePanel.dart';
import 'package:illinois/ui/polls/PollsHomePanel.dart';
import 'package:illinois/ui/surveys/PublicSurveysPanel.dart';
import 'package:illinois/ui/wallet/WalletHomePanel.dart';
import 'package:illinois/ui/notifications/NotificationsHomePanel.dart';
import 'package:illinois/ui/wellness/WellnessHomePanel.dart';
import 'package:illinois/ui/widgets/FavoriteButton.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/app_lifecycle.dart';
import 'package:rokwire_plugin/service/content.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/panels/modal_image_holder.dart';
import 'package:rokwire_plugin/ui/widgets/triangle_painter.dart';
import 'package:rokwire_plugin/utils/utils.dart';

///////////////////////////
// BrowsePanel

class BrowsePanel extends StatefulWidget {
  static const String notifyRefresh      = "edu.illinois.rokwire.browse.refresh";
  static const String notifySelect       = "edu.illinois.rokwire.browse.select";

  BrowsePanel();

  @override
  _BrowsePanelState createState() => _BrowsePanelState();
}

class _BrowsePanelState extends State<BrowsePanel> with AutomaticKeepAliveClientMixin<BrowsePanel> {
  StreamController<String> _updateController = StreamController.broadcast();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _updateController.close();
    super.dispose();
  }

  // AutomaticKeepAliveClientMixin
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: RootHeaderBar(title: Localization().getStringEx('panel.browse.label.title', 'More')),
      body: RefreshIndicator(onRefresh: _onPullToRefresh, child:
        Column(children: <Widget>[
          Expanded(child:
            SingleChildScrollView(child:
              Column(children: <Widget>[
                _BrowseToutWidget(updateController: _updateController,),
                BrowseContentWidget(),
              ],)
            )
          ),
        ]),
      ),
      backgroundColor: Styles().colors.background,
      bottomNavigationBar: null,
    );
  }

  Future<void> _onPullToRefresh() async {
    _updateController.add(BrowsePanel.notifyRefresh);
    if (mounted) {
      setState(() {});
    }
  }
}


///////////////////////////
// BrowseContentWidget

class BrowseContentWidget extends StatefulWidget with AnalyticsInfo {
  BrowseContentWidget({super.key});

  @override
  State<StatefulWidget> createState() => _BrowseContentWidgetState();

  @override
  AnalyticsFeature? get analyticsFeature => AnalyticsFeature.Browse;
}

class _BrowseContentWidgetState extends State<BrowseContentWidget> with NotificationsListener {

  List<String>? _contentCodes;
  List<String>? _browseListContentCodes;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      FlexUI.notifyChanged,
      Auth2UserPrefs.notifyFavoritesChanged,
      Localization.notifyStringsUpdated,
      Styles.notifyChanged,
    ]);

    _contentCodes = buildContentCodes();
    _browseListContentCodes = buildBrowseListContentCodes();

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
    if (name == FlexUI.notifyChanged) {
      _updateContentCodes();
      if (mounted) {
        setState(() { });
      }
    }
    else if((name == Auth2UserPrefs.notifyFavoritesChanged) ||
      (name == Localization.notifyStringsUpdated) ||
      (name == Styles.notifyChanged))
    {
      if (mounted) {
        setState(() { });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> contentList = <Widget>[];

    Widget? sectionsGrid;
    if (_contentCodes != null) {
      sectionsGrid = _BrowseSection.buildSectionGrid(context, codes: _contentCodes!);
    }

    if (sectionsGrid != null) {
      contentList.add(
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 32),
          child: sectionsGrid,
        )
      );
    }

    contentList.add(_BrowseSection.buildBrowseList(codes: _browseListContentCodes!));

    return Column(children: contentList,);
  }

  void _updateContentCodes() {
    List<String>?  contentCodes = buildContentCodes();
    if ((contentCodes != null) && !DeepCollectionEquality().equals(_contentCodes, contentCodes)) {
      if (mounted) {
        setState(() {
          _contentCodes = contentCodes;
        });
      }
      else {
        _contentCodes = contentCodes;
      }
    }
  }

  static List<String>? buildContentCodes() {
    return JsonUtils.listStringsValue(FlexUI()['browse']);
  }

  static List<String>? buildBrowseListContentCodes() {
    return JsonUtils.listStringsValue(FlexUI()['browse.list']);
  }
}

///////////////////////////
// BrowseSection

enum _BrowseSectionLayout { grid, list }

class _BrowseSection extends StatelessWidget {

  final String sectionId;
  final Set<String>? _homeRootEntriesCodes;
  final _BrowseSectionLayout layout;

  _BrowseSection({Key? key, required this.sectionId,
    this.layout = _BrowseSectionLayout.grid}) :
    _homeRootEntriesCodes = JsonUtils.setStringsValue(FlexUI()['home']),
    super(key: key);

  HomeFavorite? _favorite(String code) {
    if (_homeRootEntriesCodes?.contains(code) ?? false) {
      return HomeFavorite(code);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return _getLayout(context);
  }

  Widget _getLayout(BuildContext context) {
    switch (layout) {
      case _BrowseSectionLayout.grid:
        return _circularLayout(context);
      case _BrowseSectionLayout.list:
        return _listItemLayout(context);
    }
  }

  Widget _listItemLayout(BuildContext context) {
    Widget? icon = _listItemIcon();
    return GestureDetector(
      onTap: () => _onTap(context),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: <Widget>[
            if (icon != null)
              icon,
            Expanded(
              child: Text(_title,
                  textAlign: TextAlign.center,
                  style: Styles().textStyles.getTextStyle("widget.title.regular.fat")),
            ),
            Visibility(visible: _hasFavoriteContent, child:
              Semantics(label: 'Favorite' /* TBD: Localization */, button: true, child:
                GestureDetector(onTap: () => _onTapSectionFavorite(context), child:
                FavoriteStarIcon(selected: _isSectionFavorite,
                  padding: EdgeInsets.zero,
                  style: FavoriteIconStyle.Button,
                  color: Styles().colors.fillColorSecondaryVariant,)
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circularLayout(BuildContext context) {
    List<Widget> contentList = <Widget>[];
    contentList.add(_buildHeading(context));
    return Column(children: contentList,);
  }

  Widget _buildHeading(BuildContext context) {
    return Padding(padding: EdgeInsets.all(8.0), child:
      GestureDetector(onTap: () => _onTap(context), child:
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Stack(alignment: Alignment.center, children: [
              Styles().images.getImage('more-$sectionId') ?? Container(),
              Text(_title, style: Styles().textStyles.getTextStyle("widget.title.large.extra_fat")),
              // Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              //   Expanded(child:
              //     Padding(padding: EdgeInsets.only(bottom: 16), child:
              //       Text(_description, style: Styles().textStyles.getTextStyle("widget.info.regular.thin"))
              //     )
              //   ),
              // ],)
            ],),
            Visibility(visible: _hasFavoriteContent, child:
              Semantics(label: 'Favorite' /* TBD: Localization */, button: true, child:
                GestureDetector(onTap: () => _onTapSectionFavorite(context), child:
                  Container(
                    decoration: BoxDecoration(
                        color: Styles().colors.fillColorPrimary,
                        border: Border.all(color: Styles().colors.fillColorSecondaryVariant),
                        borderRadius: BorderRadius.circular(24.0)
                    ),
                    child: FavoriteStarIcon(selected: _isSectionFavorite,
                      // TODO: update icon size
                      style: FavoriteIconStyle.Button,
                      color: Styles().colors.fillColorSecondaryVariant,)
                  ),
                ),
              ),
            ),
          ]
        ),
      ),
    );
  }

  Widget? _listItemIcon({bool excludeFromSemantics = true, double size = 21}) {
    switch(sectionId) {
      case 'polls':
        return Styles().images.getImage('browse-poll',
            excludeFromSemantics: excludeFromSemantics, size: size);
      case 'surveys':
        return Styles().images.getImage('browse-survey',
            excludeFromSemantics: excludeFromSemantics, size: size);
      default:
        return null;
    }
  }

  String get _title => title(sectionId: sectionId);
  // String get _description => description(sectionId: sectionId);

  // static String get appTitle => Localization().getStringEx('app.title', 'NEOM U');
  // static String get _appTitleMacro => '{{app_title}}';

  static String title({required String sectionId}) =>
      AppTextUtils.appBrandString('panel.browse.section.$sectionId.title', defaultTitle(sectionId: sectionId));

  static String defaultTitle({required String sectionId}) =>
      StringUtils.capitalize(sectionId, allWords: true, splitDelimiter: '_', joinDelimiter: ' ');

  // static String description({required String sectionId}) =>
  //     AppTextUtils.appBrandString('panel.browse.section.$sectionId.description', '');

  List<String>? get _favoriteCodes => JsonUtils.listStringsValue(FlexUI()['browse']);

  bool get _hasFavoriteContent {
    return _favorite(sectionId) != null;
  }

  bool get _isSectionFavorite {
    return Auth2().prefs?.isFavorite(HomeFavorite(sectionId)) ?? false;
  }


  void _onTapSectionFavorite(BuildContext context) {
    Analytics().logSelect(target: "Favorite: {${HomeFavorite.favoriteKeyName(category: sectionId)}}");

    bool? isSectionFavorite = _isSectionFavorite;
    if (kReleaseMode) {
      promptSectionFavorite(context, isSectionFavorite: isSectionFavorite).then((bool? result) {
        if (result == true) {
          _toggleSectionFavorite(isSectionFavorite: isSectionFavorite);
        }
      });
    }
    else {
      _toggleSectionFavorite(isSectionFavorite: isSectionFavorite);
    }
  }

  void _toggleSectionFavorite({bool? isSectionFavorite}) {
    List<Favorite> favorites = _sectionFavorites;
    Auth2().prefs?.setListFavorite(favorites, isSectionFavorite != true);
    HomeFavorite.log(favorites, isSectionFavorite != true);
  }

  List<Favorite> get _sectionFavorites {
    if (_homeRootEntriesCodes?.contains(sectionId) ?? false) {
      return [HomeFavorite(sectionId)];
    }
    return [];
  }

  Future<bool?> promptSectionFavorite(BuildContext context, {bool? isSectionFavorite}) async {
    String message = (isSectionFavorite != true) ?
      Localization().getStringEx('panel.browse.prompt.add.all.favorites', 'Are you sure you want to ADD these items to your favorites?') :
      Localization().getStringEx('panel.browse.prompt.remove.all.favorites', 'Are you sure you want to REMOVE these items from your favorites?');
    return await showDialog(context: context, builder: (BuildContext context) {
      return AlertDialog(
        content: Text(message),
        actions: <Widget>[
          TextButton(child: Text(Localization().getStringEx("dialog.yes.title", "Yes")),
            onPressed:(){
              Analytics().logAlert(text: message, selection: "Yes");
              Navigator.pop(context, true);
            }),
          TextButton(child: Text(Localization().getStringEx("dialog.no.title", "No")),
            onPressed:(){
              Analytics().logAlert(text: message, selection: "No");
              Navigator.pop(context, false);
            }),
        ]
      );
    });
  }

  void _onTap(BuildContext context) {
    switch(sectionId) {
      case "events":              _onTapEvents(context); break;

      case "directory":           _onTapUserDirectory(context); break;

      case "music_and_news.twitter":       _onTapTwitter(context); break;
      case "music_and_news.daily_illini":  _onTapDailyIllini(context); break;

      case "groups":              _onTapGroups(context); break;

      case "inbox":               _onTapNotifications(context); break;

      case "polls":               _onTapViewPolls(context); break;

      case "recent.recent_items": _onTapRecentItems(context); break;

      case "surveys":             _onTapPublicSurveys(context); break;

      case "messages":            _onTapMessages(context); break;

      case "wallet":              _onTapWallet(context); break;

      case "wellness":            _onTapWellness(context); break;
    }
  }

  void _onTapNotifications(BuildContext context) {
    Analytics().logSelect(target: "Notifications");
    NotificationsHomePanel.present(context);
  }

  void _onTapEvents(BuildContext context) {
    Analytics().logSelect(target: "Events Feed");
    Event2HomePanel.present(context,
      analyticsFeature: AnalyticsFeature.EventsAll,
    );
  }

  void _onTapTwitter(BuildContext context) {
    Analytics().logSelect(target: "Twitter");
    Navigator.push(context, CupertinoPageRoute(builder: (context) { return TwitterPanel(); } ));
  }

  void _onTapDailyIllini(BuildContext context) {
    Analytics().logSelect(target: "Daily Illini");
    _launchUrl(context, Config().dailyIlliniHomepageUrl);
  }

  void _onTapGroups(BuildContext context) {
    Analytics().logSelect(target: "All Groups");
    Navigator.push(context, CupertinoPageRoute(settings: RouteSettings(name: GroupsHomePanel.routeName), builder: (context) => GroupsHomePanel()));
  }

  void _onTapViewPolls(BuildContext context) {
    Analytics().logSelect(target: "View Polls");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => PollsHomePanel()));
  }

  void _onTapRecentItems(BuildContext context) {
    Analytics().logSelect(target: "Recent Items");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => HomeRecentItemsPanel()));
  }

  void _onTapPublicSurveys(BuildContext context) {
    Analytics().logSelect(target: "Public Surveys");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => PublicSurveysPanel()));
  }

  void _onTapUserDirectory(BuildContext context) {
    Analytics().logSelect(target: "User Directory");
    Navigator.push(context, CupertinoPageRoute(builder: (context) { return DirectoryAccountsPanel(DirectoryAccounts.directory); } ));
  }

  void _onTapMessages(BuildContext context) {
    Analytics().logSelect(target: "Messages");
    MessagesHomePanel.present(context);
  }

  void _onTapWallet(BuildContext context) {
    Analytics().logSelect(target: "Wallet");
    WalletHomePanel.present(context);
  }

  void _onTapWellness(BuildContext context) {
    Analytics().logSelect(target: "Wellness");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => WellnessHomePanel()));
  }

  // ignore: unused_element
  static void _notImplemented(BuildContext context) {
    AppAlert.showDialogResult(context, "Not implemented yet.");
  }

  static void _launchUrl(BuildContext context, String? url, {bool launchInternal = false}) {
    if (StringUtils.isNotEmpty(url)) {
      if (DeepLink().isAppUrl(url)) {
        DeepLink().launchUrl(url);
      }
      else {
        bool tryInternal = launchInternal && UrlUtils.canLaunchInternal(url);
        AppLaunchUrl.launch(context: context, url: url, tryInternal: tryInternal);
      }
    }
  }

  static Widget buildSectionGrid(BuildContext context, { required List<String> codes, double gridSpacing = 5 }) {
    ScreenType screenType = ScreenUtils.getType(context);
    int numColumns = 2;
    if (screenType == ScreenType.tablet) {
      numColumns = 4;
    } else if (screenType == ScreenType.desktop) {
      numColumns = 6;
    }
    List<List<Widget>> buttonColumns = List.generate(numColumns, (index) => <Widget>[]);
    int index = 0;
    for (String code in codes) {

      int columnIndex = index % numColumns;
      _BrowseSection button = _BrowseSection(sectionId: code,);

      List<Widget> buttons = buttonColumns[columnIndex];
      if (buttons.isNotEmpty) {
        buttons.add(Container(height: gridSpacing,));
      }
      buttons.add(button);
      index++;
    }

    List<Widget> gridColumns = [
      Expanded(child: Column(children: buttonColumns[0]))
    ];
    for (int i = 1; i < buttonColumns.length; i++) {
      List<Widget> column = buttonColumns[i];
      gridColumns.add(Container(width: gridSpacing,));
      gridColumns.add(Expanded(child: Column(children: column,),));
    }
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: gridColumns,);
  }

  static Widget buildBrowseList({required List<String> codes}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 48),
      child: Column(
        children: List.generate(codes.length, (index) =>
          Column(
            children: [
              Divider(height: 1, color: Styles().colors.iconPrimary,),
              _BrowseSection(sectionId: codes[index],
                layout: _BrowseSectionLayout.list,),
              if (index == codes.length - 1)
                Divider(height: 1, color: Styles().colors.iconPrimary,),
            ],
          )
        ),
      ),
    );
  }
}

///////////////////////////
// BrowseToutWidget

class _BrowseToutWidget extends StatefulWidget {

  final StreamController<String>? updateController;

  _BrowseToutWidget({Key? key, this.updateController}) : super(key: key);

  @override
  State<_BrowseToutWidget> createState() => _BrowseToutWidgetState();
}

class _BrowseToutWidgetState extends State<_BrowseToutWidget> with NotificationsListener {

  String? _imageUrl;
  DateTime? _imageDateTime;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      AppLifecycle.notifyStateChanged,
      Content.notifyContentImagesChanged,
    ]);

    widget.updateController?.stream.listen((String command) {
      if (command == BrowsePanel.notifyRefresh) {
        _refresh();
      }
    });

    _imageUrl = Storage().browseToutImageUrl;
    _imageDateTime = DateTime.fromMillisecondsSinceEpoch(Storage().browseToutImageTime ?? 0);
    if (_shouldUpdateImage) {
      _updateImage();
    }

    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return (_imageUrl != null) ? Stack(children: [
      ModalImageHolder(child: Image.network(_imageUrl!, semanticLabel: 'tout', loadingBuilder:(  BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
        double imageWidth = MediaQuery.of(context).size.width;
        double imageHeight = imageWidth * 810 / 1080;
        return (loadingProgress != null) ?
          Container(color: Styles().colors.fillColorPrimary, width: imageWidth, height: imageHeight, child:
            Center(child:
              CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors.surface), )
            ),
          ) :
          AspectRatio(aspectRatio: (1080.0 / 810.0), child:
            Container(color: Styles().colors.fillColorPrimary, child: child)
          );
      })),
      Positioned.fill(child:
        Align(alignment: Alignment.bottomCenter, child:
          Column(mainAxisSize: MainAxisSize.min, children: [
            CustomPaint(painter: TrianglePainter(painterColor: Styles().colors.fillColorSecondary, horzDir: TriangleHorzDirection.rightToLeft, vertDir: TriangleVertDirection.topToBottom), child:
              Container(height: 40)
            ),
            Container(height: 20, color: Styles().colors.fillColorSecondary),
          ],),
        ),
      ),
    ],) : Container();

  }

  bool get _shouldUpdateImage {
    return (_imageUrl == null) || (_imageDateTime == null) || (DateTimeUtils.midnight(_imageDateTime)!.compareTo(DateTimeUtils.midnight(DateTime.now())!) < 0);
  }

  void _update() {
    if (_shouldUpdateImage && mounted) {
        setState(() {
          _updateImage();
        });
    }
  }

  void _refresh() {
    if (mounted) {
        setState(() {
          _updateImage();
        });
    }
  }

  void _updateImage() {
    Storage().browseToutImageUrl = _imageUrl = Content().randomImageUrl('browse.tout');
    Storage().browseToutImageTime = (_imageDateTime = DateTime.now()).millisecondsSinceEpoch;
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if ((name == AppLifecycle.notifyStateChanged) && (param == AppLifecycleState.resumed)) {
      _update();
    }
    else if (name == Content.notifyContentImagesChanged) {
      _update();
    }
  }
}
