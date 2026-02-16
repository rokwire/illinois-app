

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:illinois/model/Analytics.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:illinois/ui/widgets/AccentCard.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/service/app_datetime.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:illinois/service/Guide.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/ui/guide/GuideDetailPanel.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class GuideEntryCard extends StatefulWidget {
  final String? favoriteKey;
  final Map<String, dynamic>? guideEntry;
  final AnalyticsFeature? analyticsFeature;
  final CardDisplayMode displayMode;

  GuideEntryCard(this.guideEntry, { this.favoriteKey = GuideFavorite.favoriteKeyName, this.displayMode = CardDisplayMode.browse, this.analyticsFeature });

  _GuideEntryCardState createState() => _GuideEntryCardState();
}

class _GuideEntryCardState extends State<GuideEntryCard> with NotificationsListener {

  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, [
      Auth2UserPrefs.notifyFavoritesChanged,
      FlexUI.notifyChanged,
    ]);
    _isFavorite = (widget.favoriteKey != null) && Auth2().isFavorite(FavoriteItem(key: widget.favoriteKey!, id: guideEntryId));
  }

  @override
  void dispose() {
    super.dispose();
    NotificationService().unsubscribe(this);
  }
  
  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == Auth2UserPrefs.notifyFavoritesChanged) {
      setStateIfMounted(() {
        _isFavorite = (widget.favoriteKey != null) && Auth2().isFavorite(FavoriteItem(key: widget.favoriteKey!, id: guideEntryId));
      });
    }
    else if (name == FlexUI.notifyChanged) {
      setStateIfMounted(() {});
    }
  }

  @override
  Widget build(BuildContext context) =>
    InkWell(onTap: _onTapEntry, child:
      Semantics(label: Guide().entryListTitle(widget.guideEntry, stripHtmlTags: true),
        child: AccentCard(
          displayMode: widget.displayMode,
          accentColor: Styles().colors.accentColor3,
          child: _contentWidget,
        )
      ),
    );

  Widget get _contentWidget {
    String? titleHtml = Guide().entryListTitle(widget.guideEntry);
    String? descriptionHtml = Guide().entryListDescription(widget.guideEntry);
    bool isReminder = Guide().isEntryReminder(widget.guideEntry);
    String? reminderDate = isReminder ? AppDateTime().formatDateTime(Guide().reminderDate(widget.guideEntry), format: 'MMM dd', ignoreTimeZone: true) : null;

    List<Widget> contentList = Guide().isEntryReminder(widget.guideEntry) ? <Widget>[
      Padding(padding: EdgeInsets.only(right: 17), child:
        Text(reminderDate ?? '', style: _reminderDateTextStyle),
      ),
      Container(height: 4),
      HtmlWidget(
          StringUtils.ensureNotEmpty(titleHtml),
          onTapUrl : (url) {_onTapLink(url); return true;},
          textStyle: _reminderTitleTextStyle,
      )
    ] : <Widget>[
      Padding(padding: EdgeInsets.only(right: 17), child:
        HtmlWidget(
          StringUtils.ensureNotEmpty(titleHtml),
          onTapUrl : (url) {_onTapLink(url); return true;},
          textStyle: _guideTitleTextStyle
        ),
      ),
      Container(height: 8),
      HtmlWidget(
        StringUtils.ensureNotEmpty(descriptionHtml),
        onTapUrl : (url) {_onTapLink(url); return true;},
        textStyle: _guideDescriptionTextStyle
      ),
    ];

    return Stack(children: [
        Padding(padding: EdgeInsets.all(16), child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: contentList,),
        ),
        Visibility(visible: _canFavorite, child:
          Align(alignment: Alignment.topRight, child:
            Semantics(
              label: _isFavorite
                  ? Localization().getStringEx('widget.card.button.favorite.off.title', 'Remove From Favorites')
                  : Localization().getStringEx('widget.card.button.favorite.on.title', 'Add To Favorites'),
              hint: _isFavorite
                  ? Localization().getStringEx('widget.card.button.favorite.off.hint', '')
                  : Localization().getStringEx('widget.card.button.favorite.on.hint', ''),
              button: true,
              child: InkWell(onTap: _onTapFavorite, child:
                Container(padding: EdgeInsets.only(top:16, right:16, left: 20, bottom: 20), child:
                  Styles().images.getImage(_isFavorite ? 'star-filled' : 'star-outline-gray', excludeFromSemantics: true)
                ),
              )
            ),
          ),
        ),
    ],);
  }

  TextStyle? get _reminderDateTextStyle {
    switch (widget.displayMode) {
      case CardDisplayMode.home: return Styles().textStyles.getTextStyle("widget.title.medium.extra_fat");
      default: return Styles().textStyles.getTextStyle("widget.title.medium.extra_fat");
    }
  }

  TextStyle? get _reminderTitleTextStyle {
    switch (widget.displayMode) {
      case CardDisplayMode.home: return Styles().textStyles.getTextStyle("widget.title.small.medium_fat");
      default: return Styles().textStyles.getTextStyle("widget.title.regular.medium_fat");
    }
  }

  TextStyle? get _guideTitleTextStyle {
    switch (widget.displayMode) {
      case CardDisplayMode.home: return Styles().textStyles.getTextStyle("widget.title.medium.extra_fat");
      default: return Styles().textStyles.getTextStyle("widget.title.large.extra_fat");
    }
  }
  TextStyle? get _guideDescriptionTextStyle {
    switch (widget.displayMode) {
      case CardDisplayMode.home: return Styles().textStyles.getTextStyle("widget.item.small.thin");
      default: return Styles().textStyles.getTextStyle("widget.item.regular.thin");
    }
  }

  bool get _canFavorite => (widget.favoriteKey != null) && Auth2().canFavorite;

  void _onTapLink(String? url) {
    Analytics().logSelect(target: 'Link: $url');
    AppLaunchUrl.launchExternal(url: url);
  }

  void _onTapFavorite() {
    if (widget.favoriteKey != null) {
      String? title = Guide().entryTitle(widget.guideEntry, stripHtmlTags: true);
      Analytics().logSelect(target: "Favorite: $title");
      Auth2().prefs?.toggleFavorite(FavoriteItem(key: widget.favoriteKey!, id: guideEntryId));
    }
  }

  void _onTapEntry() {
    Analytics().logSelect(target: "Guide Entry: $guideEntryId");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GuideDetailPanel(
      guideEntryId: guideEntryId,
      favoriteKey: widget.favoriteKey,
      analyticsFeature: widget.analyticsFeature,
    )));
  }

  String? get guideEntryId {
    return Guide().entryId(widget.guideEntry);
  } 
}

