

import 'package:flutter/cupertino.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/service/app_datetime.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:illinois/service/Guide.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/ui/WebPanel.dart';
import 'package:illinois/ui/guide/GuideDetailPanel.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

class GuideEntryCard extends StatefulWidget {
  final Map<String, dynamic>? guideEntry;
  GuideEntryCard(this.guideEntry);

  _GuideEntryCardState createState() => _GuideEntryCardState();
}

class _GuideEntryCardState extends State<GuideEntryCard> implements NotificationsListener {

  late bool _isFavorite;

  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, [
      Auth2UserPrefs.notifyFavoritesChanged,
    ]);
    _isFavorite = Auth2().isFavorite(GuideFavorite(id: guideEntryId));
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
      setState(() {
        _isFavorite = Auth2().isFavorite(GuideFavorite(id: guideEntryId));
      });
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
          style: TextStyle(fontFamily: Styles().fontFamilies?.extraBold, fontSize: 18, color: Styles().colors?.fillColorPrimary, ),),),
      Container(height: 4),
      Html(data: titleHtml ?? '',
        onLinkTap: (url, context, attributes, element) => _onTapLink(url),
        style: { "body": Style(fontFamily: Styles().fontFamilies?.medium, fontSize: FontSize(16), color: Styles().colors?.fillColorPrimary, padding: EdgeInsets.zero, margin: EdgeInsets.zero), },),
    ] : <Widget>[
      Padding(padding: EdgeInsets.only(right: 17), child:
        Html(data: titleHtml ?? '',
          onLinkTap: (url, context, attributes, element) => _onTapLink(url),
          style: { "body": Style(fontFamily: Styles().fontFamilies?.extraBold, fontSize: FontSize(20), color: Styles().colors?.fillColorPrimary, padding: EdgeInsets.zero, margin: EdgeInsets.zero), },),),
      Container(height: 8),
      Html(data: descriptionHtml ?? '',
        onLinkTap: (url, context, attributes, element) => _onTapLink(url),
        style: { "body": Style(fontFamily: Styles().fontFamilies?.regular, fontSize: FontSize(16), color: Styles().colors?.textBackground, padding: EdgeInsets.zero, margin: EdgeInsets.zero), },),
    ];

    return Container(
      decoration: BoxDecoration(
          color: Styles().colors?.white,
          boxShadow: [BoxShadow(color: Styles().colors!.blackTransparent018!, spreadRadius: 1.0, blurRadius: 3.0, offset: Offset(1, 1))],
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(4)) // BorderRadius.all(Radius.circular(4))
      ),
      child: Stack(children: [
        GestureDetector(onTap: _onTapEntry, child:
          Semantics(button: true, child:
            Padding(padding: EdgeInsets.all(16), child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: contentList,),
          ),)),
        Container(color: Styles().colors?.accentColor3, height: 4),
        Visibility(visible: Auth2().canFavorite, child:
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
                Image.asset(_isFavorite ? 'images/icon-star-blue.png' : 'images/icon-star-gray-frame-thin.png', excludeFromSemantics: true,)
          ),)),),),
      ],),
    );
  }

  void _onTapLink(String? url) {
    Analytics().logSelect(target: 'Link: $url');
    if (StringUtils.isNotEmpty(url)) {
      if (UrlUtils.launchInternal(url)) {
        Navigator.push(context, CupertinoPageRoute(builder: (context) => WebPanel(url: url)));
      } else {
        launch(url!);
      }
    }
  }

  void _onTapFavorite() {
    String? title = Guide().entryTitle(widget.guideEntry, stripHtmlTags: true);
    Analytics().logSelect(target: "Favorite: $title");
    Auth2().prefs?.toggleFavorite(GuideFavorite(id: guideEntryId));
  }

  void _onTapEntry() {
    Analytics().logSelect(target: "Guide Entry: $guideEntryId");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GuideDetailPanel(guideEntryId: guideEntryId,)));
  }

  String? get guideEntryId {
    return Guide().entryId(widget.guideEntry);
  } 
}

