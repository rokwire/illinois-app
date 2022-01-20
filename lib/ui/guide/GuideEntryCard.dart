

import 'package:flutter/cupertino.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:illinois/model/Auth2.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/AppDateTime.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/NotificationService.dart';
import 'package:illinois/service/Guide.dart';
import 'package:illinois/service/Styles.dart';
import 'package:illinois/ui/WebPanel.dart';
import 'package:illinois/ui/guide/GuideDetailPanel.dart';
import 'package:illinois/utils/Utils.dart';
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
    return Container(
      decoration: BoxDecoration(
          color: Styles().colors!.white,
          boxShadow: [BoxShadow(color: Styles().colors!.blackTransparent018!, spreadRadius: 1.0, blurRadius: 3.0, offset: Offset(1, 1))],
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(4)) // BorderRadius.all(Radius.circular(4))
      ),
      clipBehavior: Clip.none,
      child: Stack(children: [
        GestureDetector(onTap: _onTapEntry, child:
          Semantics(button: true, child:
            Padding(padding: EdgeInsets.all(16), child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Padding(padding: EdgeInsets.only(right: 17), child:
                Html(data: titleHtml ?? '',
                  onLinkTap: (url, context, attributes, element) => _onTapLink(url),
                  style: { "body": Style(color: Styles().colors!.fillColorPrimary, fontFamily: Styles().fontFamilies!.extraBold, fontSize: FontSize(20), padding: EdgeInsets.zero, margin: EdgeInsets.zero), },),),
                Container(height: isReminder ? 4 : 8,),
                isReminder ?
                  Text(reminderDate ?? '',
                    style: TextStyle(color: Styles().colors!.textBackground, fontSize: 16, fontFamily: Styles().fontFamilies!.medium),) :
                  Html(data: descriptionHtml ?? '',
                    onLinkTap: (url, context, attributes, element) => _onTapLink(url),
                    style: { "body": Style(color: Styles().colors!.textBackground, fontFamily: Styles().fontFamilies!.regular, fontSize: FontSize(16), padding: EdgeInsets.zero, margin: EdgeInsets.zero), },),
              ],),
          ),)),
        Container(color: Styles().colors!.accentColor3, height: 4),
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
                Image.asset(_isFavorite ? 'images/icon-star-selected.png' : 'images/icon-star.png', excludeFromSemantics: true,)
          ),)),),),
      ],),
    );
  }

  void _onTapLink(String? url) {
    Analytics.instance.logSelect(target: 'Link: $url');
    if (AppString.isStringNotEmpty(url)) {
      if (AppUrl.launchInternal(url)) {
        Navigator.push(context, CupertinoPageRoute(builder: (context) => WebPanel(url: url)));
      } else {
        launch(url!);
      }
    }
  }

  void _onTapFavorite() {
    String? title = Guide().entryTitle(widget.guideEntry, stripHtmlTags: true);
    Analytics.instance.logSelect(target: "Favorite: $title");
    Auth2().prefs?.toggleFavorite(GuideFavorite(id: guideEntryId, title: title,));
  }

  void _onTapEntry() {
    Analytics.instance.logSelect(target: "Guide Entry: $guideEntryId");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => GuideDetailPanel(guideEntryId: guideEntryId,)));
  }

  String? get guideEntryId {
    return Guide().entryId(widget.guideEntry);
  } 
}

