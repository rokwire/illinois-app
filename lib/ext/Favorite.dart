import 'package:flutter/cupertino.dart';

import 'package:illinois/ext/Event.dart';
import 'package:illinois/ext/Event2.dart';
import 'package:illinois/ext/Explore.dart';
import 'package:illinois/ext/Game.dart';
import 'package:illinois/ext/Appointment.dart';
import 'package:illinois/model/Dining.dart';
import 'package:illinois/model/Explore.dart';
import 'package:illinois/model/Laundry.dart';
import 'package:illinois/model/MTD.dart';
import 'package:illinois/model/News.dart';
import 'package:illinois/model/sport/Game.dart';
import 'package:illinois/model/Appointment.dart';
import 'package:illinois/service/Guide.dart';
import 'package:illinois/ui/athletics/AthleticsGameDetailPanel.dart';
import 'package:illinois/ui/athletics/AthleticsHomePanel.dart';
import 'package:illinois/ui/athletics/AthleticsNewsArticlePanel.dart';
import 'package:illinois/ui/athletics/AthleticsNewsListPanel.dart';
import 'package:illinois/ui/events/CompositeEventsDetailPanel.dart';
import 'package:illinois/ui/events2/Event2DetailPanel.dart';
import 'package:illinois/ui/events2/Event2HomePanel.dart';
import 'package:illinois/ui/explore/ExploreDiningDetailPanel.dart';
import 'package:illinois/ui/explore/ExploreEventDetailPanel.dart';
import 'package:illinois/ui/explore/ExploreMapPanel.dart';
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
        case LaundryRoomStatus.online: return Styles().colors?.fillColorPrimary;
        case LaundryRoomStatus.offline: return Styles().colors?.disabledTextColor;
        default: return null;
      }
    }
    return null;
  }

  Widget? get favoriteDetailIcon {
    if (this is Event) {
      return Styles().images?.getImage('events', excludeFromSemantics: true);
    }
    else if (this is Event2) {
      return Styles().images?.getImage('events', excludeFromSemantics: true);
    }
    else if (this is Dining) {
      return Styles().images?.getImage('dining', excludeFromSemantics: true);
    }
    else if (this is Game) {
      return Styles().images?.getImage('athletics', excludeFromSemantics: true);
    }
    else if (this is News) {
      return Styles().images?.getImage('news', excludeFromSemantics: true);
    }
    else if (this is LaundryRoom) {
      return Styles().images?.getImage('laundry', excludeFromSemantics: true);
    }
    else if (this is ExplorePOI) {
      return Styles().images?.getImage('location', excludeFromSemantics: true);
    }
    else if (this is Appointment) {
      return Styles().images?.getImage('appointments', excludeFromSemantics: true);
    }
    else {
      return null;
    }
  }

  Widget? favoriteStarIcon({required bool selected}) {
    return Styles().images?.getImage(selected ? 'star-filled' : 'star-outline-gray', excludeFromSemantics: true);
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
    else if (this is Event2) {
      Event2 event2 = (this as Event2);
      if (event2.hasGame) {
        Navigator.push(context, CupertinoPageRoute(builder: (context) => AthleticsGameDetailPanel(game: event2.game)));
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
      Navigator.push(context, CupertinoPageRoute(builder: (context) => GuideDetailPanel(guideEntryId: (this as GuideFavorite).id,)));
    }
    else if (this is ExplorePOI) {
      (this as ExplorePOI).launchDirections();
    }
    else if (this is InboxMessage) {
      SettingsNotificationsContentPanel.launchMessageDetail(this as InboxMessage);
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
      NotificationService().notify(ExploreMapPanel.notifySelect, ExploreMapType.MTDDestinations);
    }
    else if (lowerCaseKey == GuideFavorite.favoriteKeyName.toLowerCase()) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => CampusGuidePanel()));
    }
    else if (lowerCaseKey == Appointment.favoriteKeyName.toLowerCase()) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => WellnessHomePanel(content: WellnessContent.appointments)));
    }
  }
}