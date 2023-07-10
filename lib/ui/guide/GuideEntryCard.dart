

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:illinois/service/FlexUI.dart';
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
import 'package:url_launcher/url_launcher.dart';

class GuideEntryCard extends StatefulWidget {
  final String? favoriteKey;
  final Map<String, dynamic>? guideEntry;
  GuideEntryCard(this.guideEntry, { this.favoriteKey = GuideFavorite.favoriteKeyName });

  _GuideEntryCardState createState() => _GuideEntryCardState();
}

class _GuideEntryCardState extends State<GuideEntryCard> implements NotificationsListener {

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
  Widget build(BuildContext context) {
    String? titleHtml = Guide().entryListTitle(widget.guideEntry);
    String? descriptionHtml = Guide().entryListDescription(widget.guideEntry);
    bool isReminder = Guide().isEntryReminder(widget.guideEntry);
    String? reminderDate = isReminder ? AppDateTime().formatDateTime(Guide().reminderDate(widget.guideEntry), format: 'MMM dd', ignoreTimeZone: true) : null;

    List<Widget> contentList = Guide().isEntryReminder(widget.guideEntry) ? <Widget>[
      Padding(padding: EdgeInsets.only(right: 17), child:
        Text(reminderDate ?? '',
          style: Styles().textStyles?.getTextStyle("widget.title.medium.extra_fat")),),
      Container(height: 4),
      HtmlWidget(
          StringUtils.ensureNotEmpty(titleHtml),
          onTapUrl : (url) {_onTapLink(url); return true;},
          textStyle: Styles().textStyles?.getTextStyle("widget.title.regular.medium_fat"),
      )
    ] : <Widget>[
      Padding(padding: EdgeInsets.only(right: 17), child:
        HtmlWidget(
          StringUtils.ensureNotEmpty(titleHtml),
          onTapUrl : (url) {_onTapLink(url); return true;},
          textStyle: Styles().textStyles?.getTextStyle("widget.title.large.extra_fat")
        ),
      ),
      Container(height: 8),
      HtmlWidget(
        StringUtils.ensureNotEmpty(descriptionHtml),
        onTapUrl : (url) {_onTapLink(url); return true;},
        textStyle: Styles().textStyles?.getTextStyle("widget.item.regular.thin")
      ),
    ];

    return Container(
      decoration: BoxDecoration(
          color: Styles().colors?.white,
          boxShadow: [BoxShadow(color: Styles().colors!.blackTransparent018!, spreadRadius: 1.0, blurRadius: 3.0, offset: Offset(1, 1))],
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(4)) // BorderRadius.all(Radius.circular(4))
      ),
      child: Stack(children: [
        InkWell(onTap: _onTapEntry, child:
          Semantics(button: true, child:
            Padding(padding: EdgeInsets.all(16), child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: contentList,),
          ),)),
        Container(color: Styles().colors?.accentColor3, height: 4),
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
            child:
            GestureDetector(onTap: _onTapFavorite, child:
              Container(padding: EdgeInsets.only(top:16, right:16, left: 20, bottom: 20), child:
              Styles().images?.getImage(_isFavorite ? 'star-filled' : 'star-outline-gray', excludeFromSemantics: true)
          ),)),),),
      ],),
    );
  }

  bool get _canFavorite => (widget.favoriteKey != null) && Auth2().canFavorite;

  void _onTapLink(String? url) {
    Analytics().logSelect(target: 'Link: $url');
    if (StringUtils.isNotEmpty(url)) {
        Uri? uri = Uri.tryParse(url!);
        if (uri != null) {
          launchUrl(uri);
        }
    }
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
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GuideDetailPanel(guideEntryId: guideEntryId, favoriteKey: widget.favoriteKey,)));
  }

  String? get guideEntryId {
    return Guide().entryId(widget.guideEntry);
  } 
}

