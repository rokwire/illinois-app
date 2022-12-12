import 'package:flutter/cupertino.dart';

import 'package:illinois/ext/Event.dart';
import 'package:illinois/ext/Explore.dart';
import 'package:illinois/model/Dining.dart';
import 'package:illinois/model/Explore.dart';
import 'package:illinois/model/Laundry.dart';
import 'package:illinois/model/MTD.dart';
import 'package:illinois/model/News.dart';
import 'package:illinois/model/sport/Game.dart';
import 'package:illinois/model/wellness/Appointment.dart';
import 'package:illinois/service/Guide.dart';
import 'package:illinois/service/NativeCommunicator.dart';
import 'package:illinois/ui/athletics/AthleticsGameDetailPanel.dart';
import 'package:illinois/ui/athletics/AthleticsHomePanel.dart';
import 'package:illinois/ui/athletics/AthleticsNewsArticlePanel.dart';
import 'package:illinois/ui/athletics/AthleticsNewsListPanel.dart';
import 'package:illinois/ui/events/CompositeEventsDetailPanel.dart';
import 'package:illinois/ui/explore/ExploreDiningDetailPanel.dart';
import 'package:illinois/ui/explore/ExploreEventDetailPanel.dart';
import 'package:illinois/ui/explore/ExplorePanel.dart';
import 'package:illinois/ui/guide/CampusGuidePanel.dart';
import 'package:illinois/ui/guide/GuideDetailPanel.dart';
import 'package:illinois/ui/laundry/LaundryHomePanel.dart';
import 'package:illinois/ui/laundry/LaundryRoomDetailPanel.dart';
import 'package:illinois/ui/mtd/MTDStopDeparturesPanel.dart';
import 'package:illinois/ui/mtd/MTDStopsHomePanel.dart';
import 'package:illinois/ui/settings/SettingsNotificationsContentPanel.dart';
import 'package:illinois/ui/wellness/WellnessHomePanel.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/model/event.dart';
import 'package:rokwire_plugin/model/explore.dart';
import 'package:rokwire_plugin/model/inbox.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
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
    else if (this is MTDStop) {
      return (this as MTDStop).name;
    }
    else if (this is GuideFavorite) {
      return Guide().entryListTitle(Guide().entryById((this as GuideFavorite).id), stripHtmlTags: true);
    }
    else if (this is InboxMessage) {
      return (this as InboxMessage).subject;
    }
    else if (this is ExplorePOI) {
      return (this as ExplorePOI).exploreTitle;
    }
    else if (this is Appointment) {
      return (this as Appointment).exploreTitle;
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
    else if (this is GuideFavorite) {
      return Guide().entryListDescription(Guide().entryById((this as GuideFavorite).id), stripHtmlTags: true);
    }
    else if (this is InboxMessage) {
      return (this as InboxMessage).body;
    }
    else if (this is ExplorePOI) {
      return (this as ExplorePOI).exploreLocationDescription;
    }
    else if (this is Appointment) {
      return (this as Appointment).displayDate;
    }
    else {
      return null;
    }
  }
  
  Color? get favoriteDetailTextColor {
    if (this is LaundryRoom) {
      switch((this as LaundryRoom).status) {
        case LaundryRoomStatus.online: return Styles().colors?.fillColorPrimary;
        case LaundryRoomStatus.offline: return Styles().colors?.disabledTextColor;
        default: return null;
      }
    }
    return null;
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
    else if (this is LaundryRoom) {
      return Image.asset('images/icon-online.png', excludeFromSemantics: true, color: favoriteDetailTextColor, colorBlendMode: BlendMode.srcIn,);
    }
    else if (this is ExplorePOI) {
      return Image.asset('images/icon-location.png', excludeFromSemantics: true);
    }
    else if (this is Appointment) {
      return Image.asset('images/icon-calendar.png', excludeFromSemantics: true);
    }
    else {
      return null;
    }
  }

  Image? favoriteStarIcon({required bool selected}) {
    if ((this is Event) || (this is Dining) || (this is LaundryRoom) || (this is InboxMessage) || (this is MTDStop)|| (this is ExplorePOI)) {
      return Image.asset(selected ? 'images/icon-star-orange.png' : 'images/icon-star-white.png', excludeFromSemantics: true);
    }
    else if ((this is Game) || (this is News) || (this is GuideFavorite)) {
      return Image.asset(selected ? 'images/icon-star-blue.png' : 'images/icon-star-gray-frame-thin.png', excludeFromSemantics: true);
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
      return (this as Game).uiColor;
    }
    else if (this is News) {
      return Styles().colors?.fillColorPrimary;
    }
    else if (this is LaundryRoom) {
      return Styles().colors?.accentColor2;
    }
    else if (this is MTDStop) {
      return Styles().colors?.accentColor3;
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
      if ((this as Event).isComposite) {
        Navigator.push(context, CupertinoPageRoute(builder: (context) => CompositeEventsDetailPanel(parentEvent: this as Event)));
      }
      else {
        Navigator.push(context, CupertinoPageRoute(builder: (context) => ExploreEventDetailPanel(event: this as Event,)));
      }
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
    else if (this is MTDStop) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => MTDStopDeparturesPanel(stop: this as MTDStop,)));
    }
    else if (this is GuideFavorite) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => GuideDetailPanel(guideEntryId: (this as GuideFavorite).id,)));
    }
    else if (this is ExplorePOI) {
      NativeCommunicator().launchExploreMapDirections(target: (this as ExplorePOI), options: {
        'travelMode': 'transit'
      });
    }
    else if (this is InboxMessage) {
      SettingsNotificationsContentPanel.launchMessageDetail(this as InboxMessage);
    }
  }
  
  static void launchHome(BuildContext context, { String? key }) {
    // Work in lowercase as key can come from an URL
    String? lowerCaseKey = key?.toLowerCase();
    if (lowerCaseKey == Event.favoriteKeyName.toLowerCase()) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) { return ExplorePanel(initialItem: ExploreItem.Events); } ));
    }
    else if (lowerCaseKey == Dining.favoriteKeyName.toLowerCase()) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) { return ExplorePanel(initialItem: ExploreItem.Dining); } ));
    }
    else if (lowerCaseKey == Game.favoriteKeyName.toLowerCase()) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => AthleticsHomePanel()));
    }
    else if (lowerCaseKey == News.favoriteKeyName.toLowerCase()) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => AthleticsNewsListPanel()));
    }
    else if (lowerCaseKey == LaundryRoom.favoriteKeyName.toLowerCase()) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => LaundryHomePanel()));
    }
    else if (lowerCaseKey == MTDStop.favoriteKeyName.toLowerCase()) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => MTDStopsHomePanel(contentType: MTDStopsContentType.all)));
    }
    else if (lowerCaseKey == ExplorePOI.favoriteKeyName.toLowerCase()) {
      NotificationService().notify(ExplorePanel.notifyMapSelect, ExploreItem.MTDStops);
    }
    else if (lowerCaseKey == GuideFavorite.favoriteKeyName.toLowerCase()) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => CampusGuidePanel()));
    }
    else if (lowerCaseKey == Appointment.favoriteKeyName.toLowerCase()) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => WellnessHomePanel(content: WellnessContent.appointments)));
    }
  }
}