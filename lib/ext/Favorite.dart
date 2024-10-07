import 'package:flutter/cupertino.dart';

import 'package:neom/ext/Event.dart';
import 'package:neom/ext/Event2.dart';
import 'package:neom/ext/Explore.dart';
import 'package:neom/ext/Game.dart';
import 'package:neom/ext/Appointment.dart';
import 'package:neom/model/Analytics.dart';
import 'package:neom/model/Dining.dart';
import 'package:neom/model/Explore.dart';
import 'package:neom/model/Laundry.dart';
import 'package:neom/model/MTD.dart';
import 'package:neom/model/News.dart';
import 'package:neom/model/sport/Game.dart';
import 'package:neom/model/Appointment.dart';
import 'package:neom/service/Guide.dart';
import 'package:neom/ui/athletics/AthleticsContentPanel.dart';
import 'package:neom/ui/athletics/AthleticsGameDetailPanel.dart';
import 'package:neom/ui/athletics/AthleticsNewsArticlePanel.dart';
import 'package:neom/ui/events2/Event2DetailPanel.dart';
import 'package:neom/ui/events2/Event2HomePanel.dart';
import 'package:neom/ui/explore/ExploreDiningDetailPanel.dart';
import 'package:neom/ui/explore/ExploreMapPanel.dart';
import 'package:neom/ui/explore/ExplorePanel.dart';
import 'package:neom/ui/guide/CampusGuidePanel.dart';
import 'package:neom/ui/guide/GuideDetailPanel.dart';
import 'package:neom/ui/laundry/LaundryHomePanel.dart';
import 'package:neom/ui/laundry/LaundryRoomDetailPanel.dart';
import 'package:neom/ui/mtd/MTDStopDeparturesPanel.dart';
import 'package:neom/ui/mtd/MTDStopsHomePanel.dart';
import 'package:neom/ui/notifications/NotificationsHomePanel.dart';
import 'package:neom/ui/wellness/WellnessHomePanel.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/model/event.dart';
import 'package:rokwire_plugin/model/event2.dart';
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
    else if (this is Event2) {
      return (this as Event2).shortDisplayDateAndTime;
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
      return (this as ExplorePOI).location?.displayCoordinates;
    }
    else if (this is Appointment) {
      return (this as Appointment).displayShortScheduleTime;
    }
    else {
      return null;
    }
  }
  
  Color? get favoriteDetailTextColor {
    if (this is LaundryRoom) {
      switch((this as LaundryRoom).status) {
        case LaundryRoomStatus.online: return Styles().colors.fillColorPrimary;
        case LaundryRoomStatus.offline: return Styles().colors.disabledTextColor;
        default: return null;
      }
    }
    return null;
  }

  Widget? get favoriteDetailIcon {
    if (this is Event) {
      return Styles().images.getImage('events', excludeFromSemantics: true);
    }
    else if (this is Event2) {
      return Styles().images.getImage('events', excludeFromSemantics: true);
    }
    else if (this is Dining) {
      return Styles().images.getImage('dining', excludeFromSemantics: true);
    }
    else if (this is Game) {
      return Styles().images.getImage('athletics', excludeFromSemantics: true);
    }
    else if (this is News) {
      return Styles().images.getImage('calendar', excludeFromSemantics: true);
    }
    else if (this is LaundryRoom) {
      return Styles().images.getImage('laundry', excludeFromSemantics: true);
    }
    else if (this is ExplorePOI) {
      return Styles().images.getImage('location', excludeFromSemantics: true);
    }
    else if (this is Appointment) {
      return Styles().images.getImage('appointments', excludeFromSemantics: true);
    }
    else {
      return null;
    }
  }

  Widget? favoriteStarIcon({required bool selected}) {
    return Styles().images.getImage(selected ? 'star-filled' : 'star-outline-secondary', excludeFromSemantics: true);
  }

  Color? get favoriteHeaderColor {
    if (this is Explore) {
      return (this as Explore).uiColor;
    }
    else if (this is Game) {
      return (this as Game).uiColor;
    }
    else if (this is News) {
      return Styles().colors.fillColorPrimary;
    }
    else if (this is LaundryRoom) {
      return Styles().colors.accentColor2;
    }
    else if (this is MTDStop) {
      return Styles().colors.accentColor3;
    }
    else if (this is GuideFavorite) {
      return Styles().colors.accentColor3;
    }
    else if (this is InboxMessage) {
      return Styles().colors.fillColorSecondary;
    }
    else {
      return Styles().colors.fillColorSecondary;
    }
  }


  void favoriteLaunchDetail(BuildContext context) {
    if (this is Event2) {
      Event2 event2 = (this as Event2);
      if (event2.hasGame) {
        Navigator.push(context, CupertinoPageRoute(builder: (context) => AthleticsGameDetailPanel(game: event2.game, event: event2)));
      } else {
        Navigator.push(context, CupertinoPageRoute(builder: (context) => Event2DetailPanel(event: event2)));
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
      Navigator.push(context, CupertinoPageRoute(builder: (context) => GuideDetailPanel(guideEntryId: (this as GuideFavorite).id, analyticsFeature: AnalyticsFeature.Guide,)));
    }
    else if (this is ExplorePOI) {
      (this as ExplorePOI).launchDirections();
    }
    else if (this is InboxMessage) {
      NotificationsHomePanel.launchMessageDetail(this as InboxMessage);
    }
  }
  
  static void launchHome(BuildContext context, { String? key }) {
    // Work in lowercase as key can come from an URL
    String? lowerCaseKey = key?.toLowerCase();
    if (lowerCaseKey == Event.favoriteKeyName.toLowerCase()) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) { return ExplorePanel(exploreType: ExploreType.Events); } ));
    }
    else if (lowerCaseKey == Event2.favoriteKeyName.toLowerCase()) {
      Event2HomePanel.present(context);
    }
    else if (lowerCaseKey == Dining.favoriteKeyName.toLowerCase()) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) { return ExplorePanel(exploreType: ExploreType.Dining); } ));
    }
    else if (lowerCaseKey == Game.favoriteKeyName.toLowerCase()) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => AthleticsContentPanel(content: AthleticsContent.events)));
    }
    else if (lowerCaseKey == News.favoriteKeyName.toLowerCase()) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => AthleticsContentPanel(content: AthleticsContent.news)));
    }
    else if (lowerCaseKey == LaundryRoom.favoriteKeyName.toLowerCase()) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => LaundryHomePanel()));
    }
    else if (lowerCaseKey == MTDStop.favoriteKeyName.toLowerCase()) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => MTDStopsHomePanel(contentType: MTDStopsContentType.all)));
    }
    else if (lowerCaseKey == ExplorePOI.favoriteKeyName.toLowerCase()) {
      NotificationService().notify(ExploreMapPanel.notifySelect, ExploreMapType.MyLocations);
    }
    else if (lowerCaseKey == GuideFavorite.favoriteKeyName.toLowerCase()) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => CampusGuidePanel()));
    }
    else if (lowerCaseKey == Appointment.favoriteKeyName.toLowerCase()) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => WellnessHomePanel(content: WellnessContent.appointments)));
    }
  }
}