import 'package:flutter/cupertino.dart';

import 'package:illinois/ext/Event.dart';
import 'package:illinois/ext/Explore.dart';
import 'package:illinois/model/Dining.dart';
import 'package:illinois/model/Laundry.dart';
import 'package:illinois/model/News.dart';
import 'package:illinois/model/sport/Game.dart';
import 'package:illinois/service/Guide.dart';
import 'package:illinois/ui/athletics/AthleticsGameDetailPanel.dart';
import 'package:illinois/ui/athletics/AthleticsNewsArticlePanel.dart';
import 'package:illinois/ui/explore/ExploreDiningDetailPanel.dart';
import 'package:illinois/ui/explore/ExploreEventDetailPanel.dart';
import 'package:illinois/ui/guide/GuideDetailPanel.dart';
import 'package:illinois/ui/laundry/LaundryRoomDetailPanel.dart';
import 'package:illinois/ui/settings/SettingsNotificationsContentPanel.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/model/event.dart';
import 'package:rokwire_plugin/model/explore.dart';
import 'package:rokwire_plugin/model/inbox.dart';
import 'package:rokwire_plugin/service/styles.dart';

extension FavoriteExt on Favorite {
  
  String? get favoriteTitle {
    if (this is Explore) {
      return (this as Explore).exploreTitle;
    }
    else if (this is Game) {
      return (this as Game).title;
    }
    else if (this is News) {
      return (this as News).title;
    }
    else if (this is LaundryRoom) {
      return (this as LaundryRoom).name;
    }
    else if (this is GuideFavorite) {
      return Guide().entryListTitle(Guide().entryById((this as GuideFavorite).id), stripHtmlTags: true);
    }
    else if (this is InboxMessage) {
      return (this as InboxMessage).subject;
    }
    else {
      return null;
    }
  }
  
  String? get favoriteDetailText {
    if (this is Event) {
      return (this as Event).displayDateTime;
    }
    else if (this is Dining) {
      return (this as Dining).displayWorkTime;
    }
    else if (this is Game) {
      return (this as Game).displayTime;
    }
    else if (this is News) {
      return (this as News).displayTime;
    }
    else if (this is LaundryRoom) {
      return (this as LaundryRoom).displayStatus;
    }
    else if (this is GuideFavorite) {
      return Guide().entryListDescription(Guide().entryById((this as GuideFavorite).id), stripHtmlTags: true);
    }
    else if (this is InboxMessage) {
      return (this as InboxMessage).body;
    }
    else {
      return null;
    }
  }
  
  Image? get favoriteDetailIcon {
    if (this is Event) {
      return Image.asset('images/icon-calendar.png', excludeFromSemantics: true);
    }
    else if (this is Dining) {
      return Image.asset('images/icon-time.png', excludeFromSemantics: true);
    }
    else if (this is Game) {
      return Image.asset('images/icon-calendar.png', excludeFromSemantics: true);
    }
    else if (this is News) {
      return Image.asset('images/icon-calendar.png', excludeFromSemantics: true);
    }
    else {
      return null;
    }
  }

  Color? get favoriteHeaderColor {
    if (this is Explore) {
      return (this as Explore).uiColor;
    }
    else if (this is Game) {
      return Styles().colors?.fillColorPrimary;
    }
    else if (this is News) {
      return Styles().colors?.fillColorPrimary;
    }
    else if (this is LaundryRoom) {
      return Styles().colors?.accentColor2;
    }
    else if (this is GuideFavorite) {
      return Styles().colors?.accentColor3;
    }
    else if (this is InboxMessage) {
      return Styles().colors?.fillColorSecondary;
    }
    else {
      return Styles().colors?.fillColorSecondary;
    }
  }

  void favoriteLaunchDetail(BuildContext context) {
    if (this is Event) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => ExploreEventDetailPanel(event: this as Event,)));
    }
    else if (this is Dining) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => ExploreDiningDetailPanel(dining: this as Dining,)));
    }
    else if (this is Game) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => AthleticsGameDetailPanel(game: this as Game,)));
    }
    else if (this is News) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => AthleticsNewsArticlePanel(article: this as News,)));
    }
    else if (this is LaundryRoom) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => LaundryRoomDetailPanel(room: this as LaundryRoom,)));
    }
    else if (this is GuideFavorite) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => GuideDetailPanel(guideEntryId: (this as GuideFavorite).id,)));
    }
    else if (this is InboxMessage) {
      SettingsNotificationsContentPanel.launchMessageDetail(this as InboxMessage);
    }
  }
  
}