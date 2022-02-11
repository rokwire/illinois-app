# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased
### Added
- Added analytics packets timestamps [#1340](https://github.com/rokwire/illinois-app/issues/1340).

## [3.2.17] - 2022-02-10
### Added
- Dropdown with courses in Canvas calendar [#1274](https://github.com/rokwire/illinois-app/issues/1274).
### Changed
- RoundedButton moved to Rokwire plugin [#1325](https://github.com/rokwire/illinois-app/issues/1325).
- IDCardPanel show QRCodewith card number if magTrack2 is missing [#1338](https://github.com/rokwire/illinois-app/issues/1338).

## [3.2.16] - 2022-02-09
### Added
- Authman Groups UI improvements [#1323](https://github.com/rokwire/illinois-app/issues/1323).
- Canvas Calendar - arrows for changing week, marker for each day which has events, possibility for saving events [#1274](https://github.com/rokwire/illinois-app/issues/1274).
- Show image in group card [#1331](https://github.com/rokwire/illinois-app/issues/1331).
### Changed
- Inbox renamed to Notifications [#1326](https://github.com/rokwire/illinois-app/issues/1326).
- In Groups allow an Admin to End/Close a Poll even if they did not create it. [#1328](https://github.com/rokwire/illinois-app/issues/1328).
### Removed
- Canvas Course code from the card [#1274](https://github.com/rokwire/illinois-app/issues/1274).

## [3.2.15] - 2022-02-08
### Added
- HomeSaferWidget: add semantics label (id) for each button [#1281](https://github.com/rokwire/illinois-app/issues/1281).
- Canvas "Group" button that redirects to GroupsHomePanel [#1274](https://github.com/rokwire/illinois-app/issues/1274).
- Canvas "Feedback" button that reports an error [#1274](https://github.com/rokwire/illinois-app/issues/1274).
### Changed
- IDCardPanel: add more detailed semantics label (id) for building access image [#881](https://github.com/rokwire/illinois-app/issues/881).
- Canvas "Inbox" to "Notification history" [#1274](https://github.com/rokwire/illinois-app/issues/1274).
- Moved all items from CanvasCourseSyllabusPanel to CanvasCourseHomePanel [#1274](https://github.com/rokwire/illinois-app/issues/1274).
- HomeGies widget content update [#1316](https://github.com/rokwire/illinois-app/issues/1316).
### Fixed
- Canvas Course header is cut off [#1274](https://github.com/rokwire/illinois-app/issues/1274).
- Canvas Calendar overflowing [#1274](https://github.com/rokwire/illinois-app/issues/1274).
- Fixed missing Twitter Home widget for gies user [#1320](https://github.com/rokwire/illinois-app/issues/1320).

## [3.2.14] - 2022-02-07
### Added
- Canvas Modules data model and UI [#1274](https://github.com/rokwire/illinois-app/issues/1274).
### Changed
- Rokwire plugin moved to a separate repository [#1203](https://github.com/rokwire/illinois-app/issues/1203).

## [3.2.13] - 2022-02-04
### Added
- Canvas Notifications data model and UI [#1274](https://github.com/rokwire/illinois-app/issues/1274).
### Changed
- Improved Semantics for Gies Widgets [#1307](https://github.com/rokwire/illinois-app/issues/1307).

## [3.2.12] - 2022-02-03
### Added
- Canvas Calendar [#1274](https://github.com/rokwire/illinois-app/issues/1274).
### Changed
- Content service moved to Rokwire plugin [#1203](https://github.com/rokwire/illinois-app/issues/1203).
- Tracking authorization support moved to Rokwire plugin [#1203](https://github.com/rokwire/illinois-app/issues/1203).
- launchApp and launchAppSettings APIs to Rokwire plugin [#1203](https://github.com/rokwire/illinois-app/issues/1203).

## [3.2.11] - 2022-02-02
### Added
- Link multiple authentication types to one account [#1233](https://github.com/rokwire/illinois-app/issues/1233).
- Canvas Calendar sample UI (in progress) [#1274](https://github.com/rokwire/illinois-app/issues/1274).
### Changed
- Updated Gies Widgets: remove scroll from sub pages [#1291](https://github.com/rokwire/illinois-app/issues/1291).
- GroupDetailPanel: Allow only Admin to create Poll [#1280](https://github.com/rokwire/illinois-app/issues/1280).
- Events service moved to Rokwire plugin [#1203](https://github.com/rokwire/illinois-app/issues/1203).
- Groups service moved to Rokwire plugin [#1203](https://github.com/rokwire/illinois-app/issues/1203).
### Fixed
- Loading Canvas Syllabus html content [#1274](https://github.com/rokwire/illinois-app/issues/1274).

## [3.2.10] - 2022-02-01
### Added
- Canvas Collaborations and Calendar Events (data model only) [#1274](https://github.com/rokwire/illinois-app/issues/1274).

## [3.2.9] - 2022-01-31
### Added
- Canvas Files and Folders service calls and UI [#1274](https://github.com/rokwire/illinois-app/issues/1274).
### Changed  
- GeoFence service moved to Rokwire plugin [#1203](https://github.com/rokwire/illinois-app/issues/1203).
- Analytics and Polls services moved to Rokwire plugin [#1203](https://github.com/rokwire/illinois-app/issues/1203).
- Updated Gies Widgets [#1291](https://github.com/rokwire/illinois-app/issues/1291).
- Improve group member display name [#1294](https://github.com/rokwire/illinois-app/issues/1294).
### Fixed
- Fixed activity attachment in RokwirePlugin Android native class [#1203](https://github.com/rokwire/illinois-app/issues/1203).

## [3.2.8] - 2022-01-28
### Added
- Canvas Announcements data model and UI [#1274](https://github.com/rokwire/illinois-app/issues/1274).

## [3.2.7] - 2022-01-27
### Changed  
- Inbox and FirebaseMessaging services moved to Rokwire plugin [#1203](https://github.com/rokwire/illinois-app/issues/1203).
- Moved UIUC token and Auth Card support from rokwire plugin to application level [#1203](https://github.com/rokwire/illinois-app/issues/1203).
- FlexUI and Onbaording services moved to Rokwire plugin [#1203](https://github.com/rokwire/illinois-app/issues/1203).
- Updated Gies wizard: Improved Animation and Sliding behaviour. Fixed inner TabBar issues [#1224](https://github.com/rokwire/illinois-app/issues/1224).
### Added
- Canvas Files and Folders data model [#1274](https://github.com/rokwire/illinois-app/issues/1274).

## [3.2.6] - 2022-01-26
### Added
- Canvas Syllabus html view [#1274](https://github.com/rokwire/illinois-app/issues/1274).
### Changed  
- Localization, Assets and Styles services moved to Rokwire plugin [#1203](https://github.com/rokwire/illinois-app/issues/1203).

## [3.2.5] - 2022-01-25
### Added
- Canvas Courses initial view [#1274](https://github.com/rokwire/illinois-app/issues/1274).
### Changed  
- Auth2 service moved to Rokwire plugin [#1203](https://github.com/rokwire/illinois-app/issues/1203).
- Updated Gies wizard [#1224](https://github.com/rokwire/illinois-app/issues/1224).

## [3.2.4] - 2022-01-24
### Changed  
- Storage and Config services moved to Rokwire plugin [#1203](https://github.com/rokwire/illinois-app/issues/1203).
- Network service moved to Rokwire plugin [#1203](https://github.com/rokwire/illinois-app/issues/1203).
- Update Gies wizard [#1224](https://github.com/rokwire/illinois-app/issues/1224).

## [3.2.3] - 2022-01-18
### Changed  
- FirebaseCore and FirebaseCrashlytics moved to Rokwire plugin [#1203](https://github.com/rokwire/illinois-app/issues/1203).
- AppDateTime split to service and utils parts, service moved to Rokwire plugin [#1203](https://github.com/rokwire/illinois-app/issues/1203).
- Utils moved to Rokwire plugin [#1203](https://github.com/rokwire/illinois-app/issues/1203).
- Location Services moved to Rokwire plugin [#1203](https://github.com/rokwire/illinois-app/issues/1203).

## [3.2.2] - 2022-01-17
### Added
- Created Rokwire plugin, started services porting [#1203](https://github.com/rokwire/illinois-app/issues/1203).
### Changed  
- Update "Campus Resources": Read crisis_url from Config[#1219](https://github.com/rokwire/illinois-app/issues/1219).
- Update Browse panel layout: remove FAQs button [#1217](https://github.com/rokwire/illinois-app/issues/1217).

## [3.2.1] - 2022-01-14
### Changed
- Make Geofence monitor standalone plugin [#1208](https://github.com/rokwire/illinois-app/issues/1208).
- Improved Accessibility [#1213](https://github.com/rokwire/illinois-app/issues/1213).
- Update Browse panel layout [#1217](https://github.com/rokwire/illinois-app/issues/1217).
- Update "Campus Resources" Layout [#1219](https://github.com/rokwire/illinois-app/issues/1219).
- Remove margin from Group Post body in GroupPostDetailPanel [#1227](https://github.com/rokwire/illinois-app/issues/1227).

## [3.1.15] - 2022-01-21
### Fixed
- Crash when editing group event [#1262](https://github.com/rokwire/illinois-app/issues/1262).
- Differ checkboxes for voted and non-voted answers in polls [#1264](https://github.com/rokwire/illinois-app/issues/1264).
- Place "Leave" group button below the tabs [#1265](https://github.com/rokwire/illinois-app/issues/1265).
- Fixed UIUC token refresh.

## [3.1.14] - 2022-01-20
### Changed
- Use external browser for "Crisis Help" [#1255](https://github.com/rokwire/illinois-app/issues/1255).
- Styling of Campus Reminders [#1240](https://github.com/rokwire/illinois-app/issues/1240).
### Added
- Descriptive text for "Building access" to HomeLoginWidget [#1221](https://github.com/rokwire/illinois-app/issues/1221).
- Implemented Search for GroupMembersPanel [#1252](https://github.com/rokwire/illinois-app/issues/1252).
### Fixed
- Case insensitive sorting of groups [#1239](https://github.com/rokwire/illinois-app/issues/1239).

## [3.1.13] - 2022-01-19
### Fixed
- Improved Accessibility [#1213](https://github.com/rokwire/illinois-app/issues/1213).
- Fix tapping on a Group created Event in the Inbox [#1241](https://github.com/rokwire/illinois-app/issues/1241).
- Show common label for saved items [#1235](https://github.com/rokwire/illinois-app/issues/1235).
- Display events in Explore Panel [#1236](https://github.com/rokwire/illinois-app/issues/1236).
- Populating lat/long in CreateEventPanel [#1237](https://github.com/rokwire/illinois-app/issues/1237).
- Fixed IdCardPanel layout order [#1201](https://github.com/rokwire/illinois-app/issues/1201).
- Acknowledge reminder dates in university timezone [#1246](https://github.com/rokwire/illinois-app/issues/1246).
- Remove margin from Group Post body in GroupPostDetailPanel [#1227](https://github.com/rokwire/illinois-app/issues/1227).
- Update Browse panel layout [#1217](https://github.com/rokwire/illinois-app/issues/1217).
- Update "Campus Resources" Layout [#1219](https://github.com/rokwire/illinois-app/issues/1219).
- Make _GroupSelectionPopup to be scrollable [#1238](https://github.com/rokwire/illinois-app/issues/1238).

## [3.1.12] - 2022-01-13
### Fixed
- Wrong header bar colors [#1206](https://github.com/rokwire/illinois-app/issues/1206).
- Android: Soft keyboard does not appear in web view [#1209](https://github.com/rokwire/illinois-app/issues/1209).
- Crash in Privacy Center.
- Respect user's category interests and sort random events [#1171](https://github.com/rokwire/illinois-app/issues/1171).
### Changed
- Label from "Building Entry" to "Building Access" [#1172](https://github.com/rokwire/illinois-app/issues/1172).

## [3.1.11] - 2022-01-11
### Added
- Paging for Group Polls [#1157](https://github.com/rokwire/illinois-app/issues/1157).
### Changed
- Reworked refresh token functionality [#1168](https://github.com/rokwire/illinois-app/issues/1168).
- Optimized Sports service startup, data caching and refreshing [#1196](https://github.com/rokwire/illinois-app/issues/1196).
### Fixed
- Issues with updating status for Group Polls [#1157](https://github.com/rokwire/illinois-app/issues/1157).

## [3.1.10] - 2022-01-10
### Fixed
- Issues with Group Polls [#1157](https://github.com/rokwire/illinois-app/issues/1157).
### Changed
- Cleanup and fixes for Auth2 login and refresh token [#1168](https://github.com/rokwire/illinois-app/issues/1168).

## [3.1.9] - 2022-01-07
### Fixed
- Loading Event images [#1184](https://github.com/rokwire/illinois-app/issues/1184).
### Added
- Auth2: created extended logs for hunting refresh token problem [#1186](https://github.com/rokwire/illinois-app/issues/1186).
- Display name and email in GroupMembersPanel [#1188](https://github.com/rokwire/illinois-app/issues/1188).
### Changed
- Update disabled tracking message [#1168](https://github.com/rokwire/illinois-app/issues/1168)
- Update GroupPollCard style [#1157](https://github.com/rokwire/illinois-app/issues/1157).

## [3.1.8] - 2022-01-06
### Changed
- Authman UI work in GroupSettings and GroupCreate panels [#1179](https://github.com/rokwire/illinois-app/issues/1179).
- Show Gies roles button only in Dev builds [#1181](https://github.com/rokwire/illinois-app/issues/1181).
- Implement Quick Polls into Groups [#1157](https://github.com/rokwire/illinois-app/issues/1157).

## [3.1.7] - 2022-01-05
### Changed
- Trim Group Name when create/modify [#1174](https://github.com/rokwire/illinois-app/issues/1174).
- Remove GIES from onboarding roles in 3.1 [#1176](https://github.com/rokwire/illinois-app/issues/1176).
- Upgraded plugins and third party libraries [#1173](https://github.com/rokwire/illinois-app/issues/1173).

## [3.1.6] - 2022-01-04
### Added
- Add yellow Banner at the top of the Inbox when notifications are paused[#1169](https://github.com/rokwire/illinois-app/issues/1169).
### Changed
- Sound null safety [#1166](https://github.com/rokwire/illinois-app/issues/1166).
- Upgrade to Flutter 2.8.1 and Xcode 13.2.1 [#1167](https://github.com/rokwire/illinois-app/issues/1167).

## [3.1.5] - 2021-12-23
### Added
- Do not allow users to join / leave Authman groups [#1162](https://github.com/rokwire/illinois-app/issues/1162).

## [3.1.4] - 2021-12-22
### Fixed
- Fixed content update check in HomeCampusToolsWidget, WalletSheet and TabBarWidget.
- Crashes in Athletics Roster [#1155](https://github.com/rokwire/illinois-app/issues/1155). 
### Added
- Authman integration for Groups [#1159](https://github.com/rokwire/illinois-app/issues/1159).

## [3.1.3] - 2021-12-20
### Fixed
- Fix bad concurrent Groups login API synchronisation [#1150](https://github.com/rokwire/illinois-app/issues/1150).
### Changed
- Updated ui for add image for post and reply [1134](https://github.com/rokwire/illinois-app/issues/1134)

## [3.1.2] - 2021-12-17
### Changed
- Updated ui for add image for post and reply [1134](https://github.com/rokwire/illinois-app/issues/1134)

## [3.1.1] - 2021-12-15
### Added
- Implemented add image for Post Reply. [1134](https://github.com/rokwire/illinois-app/issues/1134).

## [3.1.0] - 2021-12-14
### Changed
- Show GIES role button again, updated GIES widget title [#1132](https://github.com/rokwire/illinois-app/issues/1132).
- Add image to group posts [#1134](https://github.com/rokwire/illinois-app/issues/1134)

## [3.0.72] - 2021-12-23
### Fixed
- Fixed content update check in HomeCampusToolsWidget, WalletSheet and TabBarWidget.
- Crashes in Athletics Roster [#1155](https://github.com/rokwire/illinois-app/issues/1155). 
### Changed
- Request tracking authorization before displaying web content [#1161](https://github.com/rokwire/illinois-app/issues/1161). 
### Added
- Added Config and Auth2 dependency in Groups service. 

## [3.0.71] - 2021-12-21
Version number increased when submitting to app store.

## [3.0.70] - 2021-12-20
### Changed
- Removed Bluetooth support for Polls [#1146](https://github.com/rokwire/illinois-app/issues/1146).
### Fixed
- Fix bad concurrent Groups login API synchronisation [#1150](https://github.com/rokwire/illinois-app/issues/1150).
- Acknowledged integer latitude/longitude when evaluating explore location distance.

## [3.0.69] - 2021-12-16
### Changed
- Request location services authorization in Onboarding2ExploreCampusPanel [#1141](https://github.com/rokwire/illinois-app/issues/1141).
### Added
- Added Bluetooth services authorization panel in onboarding flow [#1141](https://github.com/rokwire/illinois-app/issues/1141).

## [3.0.68] - 2021-12-15
### Deleted
- Removed unused iOS background modes from Info.plist [#1137](https://github.com/rokwire/illinois-app/issues/1137).

## [3.0.67] - 2021-12-14
### Changed
- Updated "Wellness / Emotional / Counseling Center / ACE IT" button action to load guide content [#1129](https://github.com/rokwire/illinois-app/issues/1129).

## [3.0.66] - 2021-12-13
### Changed
- Hide "GIES Student" role button from onboarding and settings [#1121](https://github.com/rokwire/illinois-app/issues/1121).
- Hide service initialization status in release builds [#1123](https://github.com/rokwire/illinois-app/issues/1123).
- Improved semantics [#1013](https://github.com/rokwire/illinois-app/issues/1013).
- Open My Illini in an external browser [#1100](https://github.com/rokwire/illinois-app/issues/1100).
### Fixed
- Change "location" plugin with "geolocator" plugin. Fix Android builds [#1127](https://github.com/rokwire/illinois-app/issues/1127).

## [3.0.65] - 2021-12-10
### Added
- Implement "tap" action on inbox items [#1113](https://github.com/rokwire/illinois-app/issues/1113).
### Fixed
- Android: load meridian lib from embedded aar file [#1118](https://github.com/rokwire/illinois-app/issues/1118).

## [3.0.64] - 2021-12-09
### Changed
- Hide wait times in test locations [#1099](https://github.com/rokwire/illinois-app/issues/1099).
- Store food filters in user profile [#1101](https://github.com/rokwire/illinois-app/issues/1101).
- Import stored user profile and settings on first app launch [#1103](https://github.com/rokwire/illinois-app/issues/1103).
- Make "Kognito At Risk (Counseling Center)" wellness buttons to launch "kognito" guide detail page [#1105](https://github.com/rokwire/illinois-app/issues/1105).
- Load guide detail panels on "Counseling" and "ACE IT" buttons from Mental Wellness panel [#1107](https://github.com/rokwire/illinois-app/issues/1107).

## [3.0.63] - 2021-12-08
### Added
- Show debug initialization status on startup (Android) [#1087](https://github.com/rokwire/illinois-app/issues/1087).
### Changed
- UI changes in Home Highlighted Features widget [#1090](https://github.com/rokwire/illinois-app/issues/1090).
- Use external browser in twitter widget [#1092](https://github.com/rokwire/illinois-app/issues/1092).
- Load guide detail panels for some Wellness items [#1094](https://github.com/rokwire/illinois-app/issues/1094).

## [3.0.62] - 2021-12-07
### Added
- Show debug initialization status on startup (iOS only) [#1087](https://github.com/rokwire/illinois-app/issues/1087).
### Changed
- Poll labels [#1085](https://github.com/rokwire/illinois-app/issues/1085).
- Update HomeUpcomingEventsWidget on event creation / update or awake from background [#1081](https://github.com/rokwire/illinois-app/issues/1081).

## [3.0.61] - 2021-12-06
### Fixed
- Fixed network authorization type in health_locations API call to Content BB.
- Capitalization of Sections on Home Page [#1073](https://github.com/rokwire/illinois-app/issues/1073).
### Changed
- Open McKinley portal in external browser [#1074](https://github.com/rokwire/illinois-app/issues/1074).
- Do not translate building access strings [#1077](https://github.com/rokwire/illinois-app/issues/1077).

## [3.0.60] - 2021-12-03
### Fixed
- Do not prompt user to select other group if he is an admin to just one group. [#1057](https://github.com/rokwire/illinois-app/issues/1057).
- Favorites (star) Button don't work. [#1069](https://github.com/rokwire/illinois-app/issues/1069).
- Do not present GroupDetailPanel on FCM notification when group event is created. [#1058](https://github.com/rokwire/illinois-app/issues/1058).
### Changed
- Load test locations from content service. [#1068](https://github.com/rokwire/illinois-app/issues/1068).

## [3.0.59] - 2021-12-02
### Changed
- Change Core BB account exists endpoint path [#1054](https://github.com/rokwire/illinois-app/issues/1054)
- Allow users signed in with oidc to create groups. [#1059](https://github.com/rokwire/illinois-app/issues/1059).
- Increased touch area for favorites and fixed not working tap action [#1062](https://github.com/rokwire/illinois-app/issues/1062).
- Hook Groups user stats API [#1052](https://github.com/rokwire/illinois-app/issues/1052).

## [3.0.58] - 2021-12-01
### Fixed
- Handle FCM data notifications (iOS) [#1042](https://github.com/rokwire/illinois-app/issues/1042).
- Android: release builds [#1046](https://github.com/rokwire/illinois-app/issues/1046).
### Added
- Implement Inbox group message tap action [#1048](https://github.com/rokwire/illinois-app/issues/1048).
- Hook Notifications Delete user API [#1050](https://github.com/rokwire/illinois-app/issues/1050).
- Hook Groups delete user API [#1052](https://github.com/rokwire/illinois-app/issues/1052).

## [3.0.57] - 2021-11-30
### Fixed
- Handle FCM data notifications when app is on background or killed (Android only) [#1042](https://github.com/rokwire/illinois-app/issues/1042).

## [3.0.56] - 2021-11-29
### Fixed
- Fixed Group my Home Panel widget refresh issue [#1037](https://github.com/rokwire/illinois-app/issues/1037). 
- Fixed token creation in refresh token [#1036](https://github.com/rokwire/illinois-app/issues/1036). 
- Fixed adding existing event to a group does not work if you search for the event [#981](https://github.com/rokwire/illinois-app/issues/981).
### Changed
- "Are you student or faculty member" updated to "Are you university student or employee" [#1007](https://github.com/rokwire/illinois-app/issues/1007).

## [3.0.55] - 2021-11-26
### Added
- Introduce groups BB login API [#1030](https://github.com/rokwire/illinois-app/issues/1030).
### Changed
- Personal Info pane enhancement [#1027](https://github.com/rokwire/illinois-app/issues/1027).
- Settings enhancement [#1028](https://github.com/rokwire/illinois-app/issues/1028).

## [3.0.54] - 2021-11-25
### Fixed
- My Groups widget not displaying on home page [#1021](https://github.com/rokwire/illinois-app/issues/1021).
- Disable local data backup on Android [#1019](https://github.com/rokwire/illinois-app/issues/1019).
- Use different values for storage encryption key and IV [#1016](https://github.com/rokwire/illinois-app/issues/1016).
- Improve Accessibility [#1013](https://github.com/rokwire/illinois-app/issues/1013).
### Added
- Acknowledge FCM messages to redirect user to Home panel and Inbox [#1024](https://github.com/rokwire/illinois-app/issues/1024).

## [3.0.53] - 2021-11-24
### Changed
- "Building Entry" button title in Browse panel changed to "Building Entry" [#1008](https://github.com/rokwire/illinois-app/issues/1008).
- Encrypt sensitive data stored on local storage and settings [#1016](https://github.com/rokwire/illinois-app/issues/1016).
### Fixed
- Allow user to sign in via email or phone in Settings -> Personal Information [#1015](https://github.com/rokwire/illinois-app/issues/1015).

## [3.0.52] - 2021-11-23
### Changed
- Do not use AES encryption with embedded key in the blob and zero based IV [#1009](https://github.com/rokwire/illinois-app/issues/1009).
- Show pending member badge in Group detail panel [#1011](https://github.com/rokwire/illinois-app/issues/1011).

## [3.0.51] - 2021-11-22
### Changed
- Update Inbox sender data information [#999](https://github.com/rokwire/illinois-app/issues/999).
- Inbox: Ignore missing message subject for foreground alert title [#1001](https://github.com/rokwire/illinois-app/issues/1001).
- Tuned and cleanup email login [#1003](https://github.com/rokwire/illinois-app/issues/1003).
- Tuned and cleanup notifications authorization in onboarding [#1005](https://github.com/rokwire/illinois-app/issues/1005).

## [3.0.50] - 2021-11-18
### Changed
- Display proper error message when group events failed to create [#992](https://github.com/rokwire/illinois-app/issues/992).
- Allow Guide detail pages to be presented as Wellness details [#995](https://github.com/rokwire/illinois-app/issues/995).
- Cleanup Inbox service [#986](https://github.com/rokwire/illinois-app/issues/986).

## [3.0.49] - 2021-11-17
### Added
- Create events for all selected groups that the user is admin of [#980](https://github.com/rokwire/illinois-app/issues/980).
- Add pause notifications switch to Notification settings panel [#986](https://github.com/rokwire/illinois-app/issues/986).
### Changed
- Handled initialization errors on app startup [#928](https://github.com/rokwire/illinois-app/issues/928).

## [3.0.48] - 2021-11-16
### Changed
- WalletPanel listens for IlliniCash.notifyBallanceUpdated event and updates state when received [#971](https://github.com/rokwire/illinois-app/issues/971).
- Save Reminders to Calendar when marked as favourite [#975](https://github.com/rokwire/illinois-app/issues/975).
### Fixed
- Home MyGroups widget not refreshing after user login [#977](https://github.com/rokwire/illinois-app/issues/977).
### Added
- Redirect user to news detail panel when FCM notification is tapped [#972](https://github.com/rokwire/illinois-app/issues/972).

## [3.0.47] - 2021-11-15
### Changed
- Rework content loading and processing in GroupsHomePanel [#948](https://github.com/rokwire/illinois-app/issues/948).
- Store Notification settings in the User Prefs [#961](https://github.com/rokwire/illinois-app/issues/961).
- Change Onboarding string. [#965](https://github.com/rokwire/illinois-app/issues/965)
- Validate transfer amount and other CC fields in AddIlliniCash panel [#957](https://github.com/rokwire/illinois-app/issues/957).
- Do not list rejected groups in "My Groups" tab of GroupsHomePanel [#958](https://github.com/rokwire/illinois-app/issues/958).
### Added
- Add Privacy level slider in to the Onboarding2PrivaciPanel[#963](https://github.com/rokwire/illinois-app/issues/963)

## [3.0.46] - 2021-11-12
### Changed
- "Safer Illinois" button replaced by "Building Status" button in Browse panel [#952](https://github.com/rokwire/illinois-app/issues/952).
- Reuse existing html page for deep link redirect in groups [#955](https://github.com/rokwire/illinois-app/issues/955).

## [3.0.45] - 2021-11-11
### Added
- Add Semantics label for Building Access image in IDCardPanel [#881](https://github.com/rokwire/illinois-app/issues/881).
- Created building access widget [#932](https://github.com/rokwire/illinois-app/issues/932).
### Changed
- Open MyMcKinley web app in WebPanel instead of in external browser [#938](https://github.com/rokwire/illinois-app/issues/938).
- Use device camera to read and execute group promotion QR code [#940](https://github.com/rokwire/illinois-app/issues/940).
### Fixed
- Show buss pass panel for residents [#936](https://github.com/rokwire/illinois-app/issues/936).

## [3.0.44] - 2021-11-09
### Fixed 
- Fixed Firebase subscription for Groups Update Settings [#926](https://github.com/rokwire/illinois-app/issues/926).

## [3.0.43] - 2021-11-08
### Added
- Created Analytics logs for group membership actions [#924](https://github.com/rokwire/illinois-app/issues/924).
- Add Groups Notification settings buttons [#926](https://github.com/rokwire/illinois-app/issues/926).

## [3.0.42] - 2021-11-05
### Added
- Include OnboardingAuthNotificationsPanel in Onboarding2 [#915](https://github.com/rokwire/illinois-app/issues/915).
### Fixed 
- Fix missing image in Group Event Detail Panel [#918](https://github.com/rokwire/illinois-app/issues/918).
- Hide Dining Specials [#920](https://github.com/rokwire/illinois-app/issues/920).

## [3.0.41] - 2021-11-04
### Fixed
- Fixed TextFields usage in GroupSettingsPanel and GroupCreatePanel [#906](https://github.com/rokwire/illinois-app/issues/906).
- QRCode panel improvement [#908](https://github.com/rokwire/illinois-app/issues/908).
- Large font in Athletics news article panel [#855](https://github.com/rokwire/illinois-app/issues/855).
### Added
- Athletics notifications preferences for Start, End and News [#907](https://github.com/rokwire/illinois-app/issues/907).

## [3.0.40] - 2021-11-03
### Fixed
- Broken external browser after switching to Android SDK 30 [#900](https://github.com/rokwire/illinois-app/issues/900).
- DINING/RECENTLY VIEWED doesn't show dining schedule accurately [#835](https://github.com/rokwire/illinois-app/issues/835).
### Changed
- Android: Update to API level 30 [#896](https://github.com/rokwire/illinois-app/issues/896).

## [3.0.39] - 2021-11-02
### Added
- Group promotion functionality [#884](https://github.com/rokwire/illinois-app/issues/884).
- GroupDetailPanel implement pull to refresh [#891](https://github.com/rokwire/illinois-app/issues/891).
- Handled email login case in Home/Settings/Wallet content  [#832](https://github.com/rokwire/illinois-app/issues/832).
### Removed
- Commend out Calendar debug dualog messages [#893](https://github.com/rokwire/illinois-app/issues/893).
### Fixed
- Fixed email signup/login [#832](https://github.com/rokwire/illinois-app/issues/832).

## [3.0.38] - 2021-11-01
### Fixed
- Improve semantics for Home widgets [#882](https://github.com/rokwire/illinois-app/issues/882).
- Fix wrong update time displayed for group posts [#889](https://github.com/rokwire/illinois-app/issues/889).
### Added
- Add Inbox user info as a debug panel [#887](https://github.com/rokwire/illinois-app/issues/887).
- Add ability to update Post in GroupPostDetailPanel [#885](https://github.com/rokwire/illinois-app/issues/885).

## [3.0.37] - 2021-10-28
### Added
- Added email login support [#832](https://github.com/rokwire/illinois-app/issues/832).
### Fixed
- RootPanel: fix broken Tab content when recreating the TabBarController [#879](https://github.com/rokwire/illinois-app/issues/879).

## [3.0.36] - 2021-10-27
### Changed
- Temporarly enable ROKWIRE-API-KEY authentication for logging service calls [#868](https://github.com/rokwire/illinois-app/issues/868).
- Removed ROKWIRE-API-KEY authentication in image requests [#870](https://github.com/rokwire/illinois-app/issues/870).
- Switch twitter user account for GIES users [#872](https://github.com/rokwire/illinois-app/issues/872).
- Update GIES notes [#874](https://github.com/rokwire/illinois-app/issues/874).
- Rename "Student Guide" to "Campus Guide" [#875](https://github.com/rokwire/illinois-app/issues/875).

## [3.0.35] - 2021-10-26
### Changed
- Cleaned up network auth types, use old Shibboleth's access token in IlliniCash and iCard requests [#864](https://github.com/rokwire/illinois-app/issues/864).
- GIES home widget updates [#866](https://github.com/rokwire/illinois-app/issues/866).

## [3.0.34] - 2021-10-25
### Changed
- Open groups detail panel on FCM group notification is received [#839](https://github.com/rokwire/illinois-app/issues/839).
- Make the edit controls in phone login in Personal Info panel with white background to indicate that they are editable [#842](https://github.com/rokwire/illinois-app/issues/842).
- Updated Home panel display for GIES only student [#860](https://github.com/rokwire/illinois-app/issues/860).
- Updated styling for Home panel widgets [#861](https://github.com/rokwire/illinois-app/issues/861).
### Fixed
- Display all games in Athletics schedule [#857](https://github.com/rokwire/illinois-app/issues/857).

## [3.0.33] - 2021-10-22
### Fixed
- Broken FCM messaging in iOS [#839](https://github.com/rokwire/illinois-app/issues/839).

## [3.0.32] - 2021-10-22
### Added
- Introduce HomeMyGroupsWidget [#852](https://github.com/rokwire/illinois-app/issues/852).
- Display sport name for games in explore card [#844](https://github.com/rokwire/illinois-app/issues/844).
- Introduce HomeHighlightedFeatures widget [#850](https://github.com/rokwire/illinois-app/issues/850).
### Changed 
- Change Home panel content order so twitter goes on top. [#848](https://github.com/rokwire/illinois-app/issues/848).

## [3.0.31] - 2021-10-21
### Fixed
- GroupDetailPanel: Do not reverse group posts when filling the content   [#829](https://github.com/rokwire/illinois-app/issues/829).
### Changed
- Groups: update strings [#836](https://github.com/rokwire/illinois-app/issues/836).
- GroupDetailPanel: place "show older" button at the end of the posts list [#829](https://github.com/rokwire/illinois-app/issues/829).
### Added
- Add image to GroupEventCard [#840](https://github.com/rokwire/illinois-app/issues/840).

## [3.0.28] - 2021-10-20
### Fixed
- Fixed spelling in Wallet  [#830](https://github.com/rokwire/illinois-app/issues/830).
- Improve Accessibility for GIES widgets  [#833](https://github.com/rokwire/illinois-app/issues/833).

## [3.0.27] - 2021-10-19
### Changed
- Updated GIES progress behavior to remember what is passes and what not [#826](https://github.com/rokwire/illinois-app/issues/826).

## [3.0.26] - 2021-10-18
### Deleted
- Possibility for creating notification message [#817](https://github.com/rokwire/illinois-app/issues/817).
### Changed
- Updated again layout of ID Card panel [#819](https://github.com/rokwire/illinois-app/issues/819).
- GIES Home widget updates [#822](https://github.com/rokwire/illinois-app/issues/822).

## [3.0.25] - 2021-10-15
### Changed
- Updated layout of ID Card panel [#810](https://github.com/rokwire/illinois-app/issues/810).
### Added
- Added progress to GIES Home wizard [#815](https://github.com/rokwire/illinois-app/issues/815).
- Added missing pages to GIES Home wizard [#815](https://github.com/rokwire/illinois-app/issues/815).

## [3.0.24] - 2021-10-14
### Added
- Added athletics game detail handling as deep link and FCM notification [#803](https://github.com/rokwire/illinois-app/issues/803).
- Added building access status in ID Card panel [#806](https://github.com/rokwire/illinois-app/issues/806).
- Merged Athletics game entries in Events list [#804](https://github.com/rokwire/illinois-app/issues/804).
- DeviceCalendar support Athletic events [#801](https://github.com/rokwire/illinois-app/issues/801).

## [3.0.23] - 2021-10-13
### Changed
- Cleanup refresh token in Auth2, logout if number of retries fail [#798](https://github.com/rokwire/illinois-app/issues/798).
- Switch groups to Core BB [#795](https://github.com/rokwire/illinois-app/issues/795).
### Added
- Added initial GIES support [#796](https://github.com/rokwire/illinois-app/issues/796).
- DeviceCalendar support Athletic events [#801](https://github.com/rokwire/illinois-app/issues/801).

## [3.0.22] - 2021-10-11
### Changed
- Merged integration/core2-bb branch in develop, Core BB integration is now official in main workbranch.

## [3.0.21] - 2021-10-08
### Changed
- Update calendar dialog so support refresh in calendar chooser [#751](https://github.com/rokwire/illinois-app/issues/751).

## [3.0.20] - 2021-10-07
### Changed
- Update calendar dialog [#751](https://github.com/rokwire/illinois-app/issues/751).

## [3.0.19] - 2021-10-05
### Added
- Added calendar choser dialog [#751](https://github.com/rokwire/illinois-app/issues/751).

## [3.0.18] - 2021-10-04
### Fixed
- Fix loading Athletics games [#790](https://github.com/rokwire/illinois-app/issues/790).

## [3.0.17] - 2021-10-01
### Changed
- Acknowledged new APIs from Sports BB [#750](https://github.com/rokwire/illinois-app/issues/750).
- Updated debug messages for Device Calendar [#751](https://github.com/rokwire/illinois-app/issues/751).

## [3.0.16] - 2021-09-30
### Added
- SECURITY.md file [#785](https://github.com/rokwire/illinois-app/issues/785).
### Changed 
-  Update Calendar event deep link to use redirect url as workaround for broken Android links. [#751](https://github.com/rokwire/illinois-app/issues/751).

## [3.0.15] - 2021-09-28
### Fixed
- Deeplink url for calendar events [#751](https://github.com/rokwire/illinois-app/issues/751).

## [3.0.14] - 2021-09-27
### Changed
- Athletics: do not show "Free admission" when there is no value for "tickets" url [#777](https://github.com/rokwire/illinois-app/issues/777).
## Added
- Implemented event detail from DeepLink [#773](https://github.com/rokwire/illinois-app/issues/773).

## [3.0.13] - 2021-09-24
## Added
- Save Calendar prompt [#751](https://github.com/rokwire/illinois-app/issues/751).

## [3.0.12] - 2021-09-23
### Deleted
- Removed UPACE activity button from Wellness content [#768](https://github.com/rokwire/illinois-app/issues/768).

## [3.0.11] - 2021-09-21
## Added
- More debug logs for DeviceCalendar [#751](https://github.com/rokwire/illinois-app/issues/751).

## [3.0.10] - 2021-09-17
### Changed
- Upload images using Content BB. [#763](https://github.com/rokwire/illinois-app/issues/763).

## [3.0.9] - 2021-09-16
### Changed
- Implemented Twitter widget paging, removed caching from Twitter service [#759](https://github.com/rokwire/illinois-app/issues/759).

## [3.0.8] - 2021-09-15
### Fixed
- Removed wrong "buss" spelling everywhere (display strings, internal names, resource names) [#752](https://github.com/rokwire/illinois-app/issues/752).
### Added
- Created Twitter widget and service [#749](https://github.com/rokwire/illinois-app/issues/749).

## [3.0.7] - 2021-09-10
### Added
- Acknowledge new field "displayOnlyWithSuperEvent" in events [#744](https://github.com/rokwire/illinois-app/issues/744).
- Implement Pull to refresh for InboxHomePanel [#746](https://github.com/rokwire/illinois-app/issues/746).

## [3.0.6] - 2021-09-09
### Changed
- Improved Accessibility for Inbox panels [#742](https://github.com/rokwire/illinois-app/issues/742).
- ExplorePanel: remove horizontal scrolling for tabs and filters. [#511](https://github.com/rokwire/illinois-app/issues/511).
- Acknowledged FCM stuff from Notifications BB [#740](https://github.com/rokwire/illinois-app/issues/740).

## [3.0.5] - 2021-09-01
### Added
- Contacts information in event detail panel [#713](https://github.com/rokwire/illinois-app/issues/713).
- Debug create Inbox message functionality [#735](https://github.com/rokwire/illinois-app/issues/735).
- Group attributes in "Request to join" select analytics event [#737](https://github.com/rokwire/illinois-app/issues/737).

## [3.0.4] - 2021-08-31
### Changed
- Updated date headers style in Inbox panel [#728](https://github.com/rokwire/illinois-app/issues/728).
- Acknowledge latest updates from Notification BB [#732](https://github.com/rokwire/illinois-app/issues/732).
### Added
- Implement Delete functionality in Inbox panel [#730](https://github.com/rokwire/illinois-app/issues/730).

## [3.0.3] - 2021-08-30
### Changed
- Remove Converge url action [#292](https://github.com/rokwire/illinois-app/issues/292).
- Hide the "Categories" drop down in Inbox panel [#721](https://github.com/rokwire/illinois-app/issues/721).
- Replace "Today and Yesterday" with only "Yesterday" in time dropdown in Inbox panel [#723](https://github.com/rokwire/illinois-app/issues/723).
- Group inbox messages by date [#725](https://github.com/rokwire/illinois-app/issues/725).

## [3.0.2] - 2021-08-27
### Fixed
- AthleticsHomePanel update semantics label for image [#510](https://github.com/rokwire/illinois-app/issues/510).
- BrowsePanel: improve Large Text support [#511](https://github.com/rokwire/illinois-app/issues/511).
### Added
- Created initial Inbox functionality and UI [#714](https://github.com/rokwire/illinois-app/issues/714).

## [3.0.1] - 2021-08-25
### Fixed
- Dining Plan Balance Not Refreshing [#698](https://github.com/rokwire/illinois-app/issues/698).
- Forgetting user information [#705](https://github.com/rokwire/illinois-app/issues/705).
- Unwanted display of test emergency widget [#710](https://github.com/rokwire/illinois-app/issues/710).
### Changed
- Delay creating MapWidget in ExplorePanel until needed [#701](https://github.com/rokwire/illinois-app/issues/701).
- Delay creating MapWidget  until needed in Laundry Home, Laundry Detail and Event Schedule panels [#706](https://github.com/rokwire/illinois-app/issues/706).
### Added
- Added sample wellness panels in embedded student guide content [#715](https://github.com/rokwire/illinois-app/issues/715).

## [3.0.0] - 2021-08-19
### Fixed
- Do not allow editing events for non-group events [#658](https://github.com/rokwire/illinois-app/issues/658).
- Allow only users with granted permissions to create a group [#663](https://github.com/rokwire/illinois-app/issues/663).
- Additional fix which prevents UI blocking if the user cancels the login process[#357](https://github.com/rokwire/illinois-app/issues/357).
- Display start time for events from Athletics category [#636](https://github.com/rokwire/illinois-app/issues/636).
- Display options menu in GroupAllEventsPanel for group admins [#637](https://github.com/rokwire/illinois-app/issues/637).
- Remove check if user is employee when creating group and change permissions error message [#663](https://github.com/rokwire/illinois-app/issues/663).
- Display group website link for members and admins as well [#681](https://github.com/rokwire/illinois-app/issues/681).
- Fixed action for StudentGuide library-card feature [#684](https://github.com/rokwire/illinois-app/issues/684).
- Check in FlexUI whether relevant StudentGuide feature are available before displaying it [#684](https://github.com/rokwire/illinois-app/issues/684).
- Defined separate section in Flex UI for Student Guide features [#684](https://github.com/rokwire/illinois-app/issues/684).
- Parsing group membership questions to json [#417](https://github.com/rokwire/illinois-app/issues/417).
- Fixed onboarding screens that used ScaleableScrollView [#679](https://github.com/rokwire/illinois-app/issues/679).
- Handle new line symbols in the html widget [#692](https://github.com/rokwire/illinois-app/issues/692).
### Added
- Add three new buttons to mental wellness [#674](https://github.com/rokwire/illinois-app/issues/674).
### Changed
- Updated Dining Dollars icon [#669](https://github.com/rokwire/illinois-app/issues/669).
- Updated Dining Dollars icon [#682](https://github.com/rokwire/illinois-app/issues/682).
- Do not notify for null uri in DeepLink service.
- Cache canonical app id in Config service.
- Update MTD logo [#694](https://github.com/rokwire/illinois-app/issues/694).
- FlexUI does not use talent chooser service any more, it loads content & rules from app assets [#696](https://github.com/rokwire/illinois-app/issues/696).

### Added
- Force onboarding from app config [#661](https://github.com/rokwire/illinois-app/issues/661).

### Changed
- Removed refreshToken parameter from Network calls (not really needed).
- Repeat 401 failed request only if refreshToken succeeded.

## [2.8.1] - 2021-11-15
### Changed
- Rework content loading and processing in GroupsHomePanel [#948](https://github.com/rokwire/illinois-app/issues/948).
- Validate transfer amount and other CC fields in AddIlliniCash panel [#957](https://github.com/rokwire/illinois-app/issues/957).
- Do not list rejected groups in "My Groups" tab of GroupsHomePanel [#958](https://github.com/rokwire/illinois-app/issues/958).

## [2.8.0] - 2021-11-12
### Changed
- Allow MTD BussPass for residents [#936](https://github.com/rokwire/illinois-app/issues/936).
- "Safer Illinois" button replaced by "Building Status" button in Browse panel [#952](https://github.com/rokwire/illinois-app/issues/952).
### Deleted
- Removed UPACE activity button from Wellness content [#947](https://github.com/rokwire/illinois-app/issues/947).

## [2.7.8] - 2021-11-11
### Changed
- Open MyMcKinley web app in WebPanel instead of in external browser [#938](https://github.com/rokwire/illinois-app/issues/938).
### Added
- Add Semantics label for Building Access image in IDCardPanel [#881](https://github.com/rokwire/illinois-app/issues/881).

## [2.7.7] - 2021-11-10
### Added
- Created building access widget [#932](https://github.com/rokwire/illinois-app/issues/932).

## [2.7.6] - 2021-11-05
### Fixed
- Fix wrong update time displayed for group posts [#889](https://github.com/rokwire/illinois-app/issues/889).
- Fix missing image in Group Event Detail Panel [#918](https://github.com/rokwire/illinois-app/issues/918).
- Hide Dining Specials [#920](https://github.com/rokwire/illinois-app/issues/920).

## [2.7.5] - 2021-11-04
### Fixed
- Broken external browser after switching to Android SDK 30 [#900](https://github.com/rokwire/illinois-app/issues/900).
- Fix large font in Athletics News [#855](https://github.com/rokwire/illinois-app/issues/855).

## [2.7.4] - 2021-11-03
### Changed
- Make the edit controls in phone login in Personal Info panel with white background to indicate that they are editable [#842](https://github.com/rokwire/illinois-app/issues/842).
- Rename "Student Guide" to "Campus Guide" [#875](https://github.com/rokwire/illinois-app/issues/875).
- Android: Update to API level 30 [#896](https://github.com/rokwire/illinois-app/issues/896).
### Fixed
- RootPanel: fix broken Tab content when recreating the TabBarController [#879](https://github.com/rokwire/illinois-app/issues/879).
- DINING/RECENTLY VIEWED doesn't show dining schedule accurately [#835](https://github.com/rokwire/illinois-app/issues/835).

## [2.7.3] - 2021-10-22
### Fixed
- Fixed spelling in Wallet  [#830](https://github.com/rokwire/illinois-app/issues/830).
- GroupDetailPanel: Do not reverse group posts when filling the content   [#829](https://github.com/rokwire/illinois-app/issues/829).
### Changed
- Groups: update strings [#836](https://github.com/rokwire/illinois-app/issues/836).
- GroupDetailPanel: place "show older" button at the end of the posts list [#829](https://github.com/rokwire/illinois-app/issues/829).
### Added
- Add image to GroupEventCard [#840](https://github.com/rokwire/illinois-app/issues/840).

## [2.7.2] - 2021-10-18
### Changed
- Updated again layout of ID Card panel [#819](https://github.com/rokwire/illinois-app/issues/819).

## [2.7.1] - 2021-10-15
### Changed
- Updated layout of ID Card panel [#810](https://github.com/rokwire/illinois-app/issues/810).

## [2.7.0] - 2021-10-14
### Added
- Added building access status in ID Card panel [#806](https://github.com/rokwire/illinois-app/issues/806).

## [2.6.28] - 2021-09-27
### Changed
- Athletics: do not show "Free admission" when there is no value for "tickets" url [#777](https://github.com/rokwire/illinois-app/issues/777).

## [2.6.27] - 2021-09-17
### Changed
- Upload images using Content BB. [#763](https://github.com/rokwire/illinois-app/issues/763).

## [2.6.26] - 2021-09-16
### Fixed
- Removed wrong "buss" spelling everywhere (display strings, internal names, resource names) [#756](https://github.com/rokwire/illinois-app/issues/756).

## [2.6.25] - 2021-09-02
### Changed
- ExplorePanel: remove horizontal scrolling for tabs and filters. [#511](https://github.com/rokwire/illinois-app/issues/511).

## [2.6.24] - 2021-09-01
### Added
- Added contacts information in event detail panel [#713](https://github.com/rokwire/illinois-app/issues/713).
- Added group attributes ito "Request to join" select analytics event [#737](https://github.com/rokwire/illinois-app/issues/737).

## [2.6.23] - 2021-08-30
### Fixed
- Remove Converge url action [#292](https://github.com/rokwire/illinois-app/issues/292).
- AthleticsHomePanel update semantics label for image [#510](https://github.com/rokwire/illinois-app/issues/510).
- BrowsePanel: improve Large Text support [#511](https://github.com/rokwire/illinois-app/issues/511).

## [2.6.22] - 2021-08-23
### Fixed
- Forgetting user information [#705](https://github.com/rokwire/illinois-app/issues/705).
- Unwanted display of test emergency widget [#710](https://github.com/rokwire/illinois-app/issues/710).
### Changed
- Delay creating MapWidget  until needed in Laundry Home, Laundry Detail and Event Schedule panels [#706](https://github.com/rokwire/illinois-app/issues/706).

## [2.6.21] - 2021-08-20
### Fixed
- Dining Plan Balance Not Refreshing [#698](https://github.com/rokwire/illinois-app/issues/698).
### Changed
- Delay creating MapWidget in ExplorePanel until needed [#701](https://github.com/rokwire/illinois-app/issues/701).

## [2.6.20] - 2021-08-18
### Changed
- Update MTD logo [#694](https://github.com/rokwire/illinois-app/issues/694).

## [2.6.19] - 2021-08-16
### Fixed
- Handle new line symbols in the html widget [#692](https://github.com/rokwire/illinois-app/issues/692).

## [2.6.18] - 2021-08-12
### Changed
- Updated Dining Dollars icon [#682](https://github.com/rokwire/illinois-app/issues/682).
### Fixed
- Display group website link for members and admins as well [#681](https://github.com/rokwire/illinois-app/issues/681).
- Fixed action for StudentGuide library-card feature [#684](https://github.com/rokwire/illinois-app/issues/684).
- Check in FlexUI whether relevant StudentGuide feature are available before displaying it [#684](https://github.com/rokwire/illinois-app/issues/684).
- Parsing group membership questions to json [#417](https://github.com/rokwire/illinois-app/issues/417).
- Fixed onboarding screens that used ScaleableScrollView [#679](https://github.com/rokwire/illinois-app/issues/679).

## [2.6.17] - 2021-08-11
### Fixed
- Additional fix which prevents UI blocking if the user cancels the login process[#357](https://github.com/rokwire/illinois-app/issues/357).
- Display start time for events from Athletics category [#636](https://github.com/rokwire/illinois-app/issues/636).
- Display options menu in GroupAllEventsPanel for group admins [#637](https://github.com/rokwire/illinois-app/issues/637).
- Remove check if user is employee when creating group and change permissions error message [#663](https://github.com/rokwire/illinois-app/issues/663).
### Added
- Add three new buttons to mental wellness [#674](https://github.com/rokwire/illinois-app/issues/674).
### Changed
- Updated Dining Dollars icon [#669](https://github.com/rokwire/illinois-app/issues/669).

## [2.6.16] - 2021-08-04
### Fixed
- Allow only users with granted permissions to create a group [#663](https://github.com/rokwire/illinois-app/issues/663).

## [2.6.15] - 2021-08-03
### Fixed
- Do not allow editing events for non-group events [#658](https://github.com/rokwire/illinois-app/issues/658).

## [2.6.14] - 2021-07-30
### Fixed
- Do not evaluate number of group replies recursively [#651](https://github.com/rokwire/illinois-app/issues/651).
- Do not show group content for members to pending members [#654](https://github.com/rokwire/illinois-app/issues/654).

## [2.6.13] - 2021-07-29
### Fixed
- Fixed miscelanious issue related to analytics logging [#638](https://github.com/rokwire/illinois-app/issues/638).
- Crash when editing group event [#643](https://github.com/rokwire/illinois-app/issues/643).
### Changed
- Show public/private event in Event detail panel [#622](https://github.com/rokwire/illinois-app/issues/622).
- Pop to Group Detail Panel when user replies on a post [#623](https://github.com/rokwire/illinois-app/issues/623).
- Add the posts bar with the + sign for members and admins even if there are no posts [#649](https://github.com/rokwire/illinois-app/issues/649).
### Added
- Add bullets in group "About" section [#645](https://github.com/rokwire/illinois-app/issues/645).
### Fixed
- Updated group privacy descriptions [#647](https://github.com/rokwire/illinois-app/issues/647).

## [2.6.12] - 2021-07-28
### Fixed
- Require user to input event end date for all day events [#627](https://github.com/rokwire/illinois-app/issues/627).
- Event display date time [#626](https://github.com/rokwire/illinois-app/issues/626).
- Do not show private events to non-members [#621](https://github.com/rokwire/illinois-app/issues/621).
- Improved Accessibility for Groups Panels [#618](https://github.com/rokwire/illinois-app/issues/618).
### Changed
- Removed inline group name validation in create group panel, extened error processing on create/update group [#630](https://github.com/rokwire/illinois-app/issues/630).
### Added
- Added missing analytics events in groups [#631](https://github.com/rokwire/illinois-app/issues/631).

## [2.6.11] - 2021-07-27
### Fixed
- Typo in Student Guide feature Bus Pass [#609](https://github.com/rokwire/illinois-app/issues/609).
### Changed
- Completely removed group's hidden attribute and all related stuff [#611](https://github.com/rokwire/illinois-app/issues/611).
- GroupsDetailPanel: refresh posts when getting back from posts detail panel [#613](https://github.com/rokwire/illinois-app/issues/613).
- Do not require user to input event end date for all day events. Calculate it based on start date [#616](https://github.com/rokwire/illinois-app/issues/616).

## [2.6.10] - 2021-07-26
### Changed
- GroupsDetailPanel: load older posts with a button [#591](https://github.com/rokwire/illinois-app/issues/591).
- Updated group posts display time [#593](https://github.com/rokwire/illinois-app/issues/593).
- Validation messages for Group Posts / Replies [#600](https://github.com/rokwire/illinois-app/issues/600).
- Update GroupPostDetailPanel [#590](https://github.com/rokwire/illinois-app/issues/590).
- Remove hidden group attribute, treat private groups as hidden [#599](https://github.com/rokwire/illinois-app/issues/599).
### Fixed
- Fixed replies count update [#595](https://github.com/rokwire/illinois-app/issues/595).
- Display the right group update time [#597](https://github.com/rokwire/illinois-app/issues/597).
- Refresh StudentGuide on pull to refresh from Campus Reminders [#605](https://github.com/rokwire/illinois-app/issues/605).

## [2.6.9] - 2021-07-23
### Changed
- GroupsDetailPanel: implement posts paging [#572](https://github.com/rokwire/illinois-app/issues/572).
- Show GroupPost reply thread [#581](https://github.com/rokwire/illinois-app/issues/581).
- Show group post dates as time interval since now [#580](https://github.com/rokwire/illinois-app/issues/580).
- Reply widget clean up [#584](https://github.com/rokwire/illinois-app/issues/584).
- Enhanced scrolling on group reply [#587](https://github.com/rokwire/illinois-app/issues/587).

## [2.6.8] - 2021-07-22
### Changed
- Scroll to edit controls when loading group post replies [#570](https://github.com/rokwire/illinois-app/issues/570).
- GroupsDetailPanel: show all posts [#572](https://github.com/rokwire/illinois-app/issues/572).
### Added
- Added post edit functionality [#566](https://github.com/rokwire/illinois-app/issues/566).
- Added options dropdown in events section header in GroupDetailPanel [#575](https://github.com/rokwire/illinois-app/issues/575).


## [2.6.7] - 2021-07-21
### Changed
- Remove "Private" checkbox for Group Posts and Replies [#549](https://github.com/rokwire/illinois-app/issues/549).
- Changes for hidden groups [#551](https://github.com/rokwire/illinois-app/issues/551).
- Only Admin or Member can see Group posts and replies [#558](https://github.com/rokwire/illinois-app/issues/558).
- Repies are opened in separate panel [#565](https://github.com/rokwire/illinois-app/issues/565).
### Fixed
- Fixed vertical overflow of GroupPostDetailPanel header [#552](https://github.com/rokwire/illinois-app/issues/552).
- Allow group members to reply [#561](https://github.com/rokwire/illinois-app/issues/561).
- Update Event Creation - Private/Public Checkbox default value [#563](https://github.com/rokwire/illinois-app/issues/563). 
### Added
- Add group privacy description in group detail panel [#554](https://github.com/rokwire/illinois-app/issues/554).
- Show group privacy status in group card [#556](https://github.com/rokwire/illinois-app/issues/556).
 
## [2.6.6] - 2021-07-20
### Added
- Possibility for changing highlighted link text in group post/reply body [#536](https://github.com/rokwire/illinois-app/issues/536).
### Fixed
- Links in Group Post/Reply do not work [#534](https://github.com/rokwire/illinois-app/issues/534).
### Changed
- "Reply" and "Delete" buttons order for post a reply [#532](https://github.com/rokwire/illinois-app/issues/532).
- Show Illini Cash button on home without Shibboleth login session [#252](https://github.com/rokwire/illinois-app/issues/252).
- Group replies UI items [#538](https://github.com/rokwire/illinois-app/issues/538).
- Groups List panel - default it to My Groups [#543](https://github.com/rokwire/illinois-app/issues/543).

## [2.6.5] - 2021-07-19
### Added
- Scroll to edit control on post reply (point 2.3) [#516](https://github.com/rokwire/illinois-app/issues/516).
- Replace symbols for new lines in Group Post [#521](https://github.com/rokwire/illinois-app/issues/521).
- Adjust Post Card UI[#524](https://github.com/rokwire/illinois-app/issues/524).
- Expand group reply card [#523](https://github.com/rokwire/illinois-app/issues/523).
- Allow Cut, Copy and Paste options in group post [#528](https://github.com/rokwire/illinois-app/issues/528).
- Sort post replies (without scrolling) [#530](https://github.com/rokwire/illinois-app/issues/530).

## [2.6.4] - 2021-07-16
### Added
- Group posts updates - part 2 (without point 2.3) [#516](https://github.com/rokwire/illinois-app/issues/516).
### Fixed
- Fixed Accessibility for Post panels [#517](https://github.com/rokwire/illinois-app/issues/517).

## [2.6.3] - 2021-07-15
### Added
- Group posts updates [#507](https://github.com/rokwire/illinois-app/issues/507).
- Emergency home widget / launch popup [#508](https://github.com/rokwire/illinois-app/issues/508).

## [2.6.2] - 2021-07-14
### Added
- Group posts and replies [#496](https://github.com/rokwire/illinois-app/issues/496).
- Groups ability to hide group [#400](https://github.com/rokwire/illinois-app/issues/499).

## [2.6.1] - 2021-07-13
### Changed
- Update campus reminders content [#500](https://github.com/rokwire/illinois-app/issues/500).

## [2.6.0] - 2021-07-12
### Changed
- Build campus reminders from Student Guide [#497](https://github.com/rokwire/illinois-app/issues/497).

## [2.5.9] - 2021-07-09
### Changed
- Show Visit website and Registration buttons underneath each other [#483](https://github.com/rokwire/illinois-app/issues/483).
- Prompt before exit without Save when creating/updating group events [#485](https://github.com/rokwire/illinois-app/issues/485).
- Rename rejected to "Denied" and show rejected status in the Group Card [#482](https://github.com/rokwire/illinois-app/issues/482).
- Pop to Group Panel after adding a public event [#478](https://github.com/rokwire/illinois-app/issues/478)
### Fixed
- Allow adding event only to admin groups[#480](https://github.com/rokwire/illinois-app/issues/480).
- Hide options button for private group events [#477](https://github.com/rokwire/illinois-app/issues/477).
- Fixed typo in "Choose a group you’re an admin" message [#479](https://github.com/rokwire/illinois-app/issues/479).
- Fixed favorite button in group event card [#476](https://github.com/rokwire/illinois-app/issues/476).
- Fixed pending members count in Group detail panel [#481](https://github.com/rokwire/illinois-app/issues/481).

## [2.5.8] - 2021-07-08
### Changed
- GroupsDetailPanel: move admin event buttons to the bottomSheet menu [#470](https://github.com/rokwire/illinois-app/issues/470).
- Cafe Credits to Dining Dollars - missed one spot [#453](https://github.com/rokwire/illinois-app/issues/453).
- Check for return value of update group event.
### Added
- Added header bar to Polls widget in Home panel [#472](https://github.com/rokwire/illinois-app/issues/472).
### Fixed
- Support both "registrationUrl" and "registrationURL" for Event.registrationUrl [#468](https://github.com/rokwire/illinois-app/issues/468).

## [2.5.7] - 2021-07-07
### Fixed
- Use zero sized containers when no left/right icons in RoundedButtons [#461](https://github.com/rokwire/illinois-app/issues/461).

## [2.5.6] - 2021-07-06
### Fixed
- Fix Android build [#442](https://github.com/rokwire/illinois-app/issues/442).
### Changed
- Selecting an image for event creation has a drop down for the type, please no drop down and I think it should just use event-tout. [#445](https://github.com/rokwire/illinois-app/issues/445).
- Inappropriate event image height on create event panel [#447](https://github.com/rokwire/illinois-app/issues/447).
### Added
- Added Registration button in Group Event Detail panel [#444](https://github.com/rokwire/illinois-app/issues/444).
- Show external link icons in Registration and Visit Website buttons in Group Event Detail panel [#444](https://github.com/rokwire/illinois-app/issues/444).

## [2.5.5] - 2021-07-05
### Fixed
- Do not show Website button in GroupDetailPanel if there is no webURL [#429](https://github.com/rokwire/illinois-app/issues/429).
### Added
- Add a pull to refresh on the Groups List panel [#431](https://github.com/rokwire/illinois-app/issues/431).
- Add Privacy Center items to Settings Home panel [#439](https://github.com/rokwire/illinois-app/issues/439).
### Changed
- Add Wellness button to Campus Resources list [#433](https://github.com/rokwire/illinois-app/issues/433).
- Additional Groups UI improvements and fixes [#413](https://github.com/rokwire/illinois-app/issues/413).
- Update Delete group event to delete only event with groupId and User is admin in this group  [#435](https://github.com/rokwire/illinois-app/issues/435).
- Improve create event form validation [#437](https://github.com/rokwire/illinois-app/issues/437).


## [2.5.4] - 2021-07-02
### Added
- Questions when creating group [#417](https://github.com/rokwire/illinois-app/issues/417).
- Group Admins in "About" section [#419](https://github.com/rokwire/illinois-app/issues/419).
- Filter groups by tags [#421](https://github.com/rokwire/illinois-app/issues/421).
### Changed
- Groups UI improvements [#413](https://github.com/rokwire/illinois-app/issues/413).
### Fixed
- Hide the add to group button if the event is a "private group event" [#427](https://github.com/rokwire/illinois-app/issues/427)
- Group events not showing [#425](https://github.com/rokwire/illinois-app/issues/425).

## [2.5.3] - 2021-07-01
### Added
- Delete group [#400](https://github.com/rokwire/illinois-app/issues/400).
- Use correct categories and tags for group [#406](https://github.com/rokwire/illinois-app/issues/406).
- Required fields for creating group event [#404](https://github.com/rokwire/illinois-app/issues/404).
- Put "Delete group" in the options menu [#409](https://github.com/rokwire/illinois-app/issues/409).
- Changed dialog messages for remove/delete event[#408](https://github.com/rokwire/illinois-app/issues/408).
### Fixed
- Display error message when creating group fails [#411](https://github.com/rokwire/illinois-app/issues/411).

## [2.5.2] - 2021-06-30
### Added
- Groups Event implement edit and delete event[#387](https://github.com/rokwire/illinois-app/issues/387)
### Changed
- UI of the "Leave" group button [#388](https://github.com/rokwire/illinois-app/issues/388).
- Do not show "See All Events" if there are no events [#390](https://github.com/rokwire/illinois-app/issues/390).
### Fixed
- Group Event - Oversized font is displayed in the field Event title [#366](https://github.com/rokwire/illinois-app/issues/366).
- Do not show "Visit Website" button if there is no "titleURL" [#392](https://github.com/rokwire/illinois-app/issues/392).
- Proper check for online status [#394](https://github.com/rokwire/illinois-app/issues/394).
- Events sorting in Group [#396](https://github.com/rokwire/illinois-app/issues/396).
- Group events count [#398](https://github.com/rokwire/illinois-app/issues/398).

## [2.5.1] - 2021-06-29
### Added
- Groups - Prompt Login button for unverified users [#357](https://github.com/rokwire/illinois-app/issues/357).
- Groups Search [#371](https://github.com/rokwire/illinois-app/issues/371).
### Changed
- Changes to Create Group Event [#345](https://github.com/rokwire/illinois-app/issues/345).
- UI adjustments for "Leave" group [#380](https://github.com/rokwire/illinois-app/issues/380).
### Fixed
- Hide "Leave" button for the only one admin in the group [#362](https://github.com/rokwire/illinois-app/issues/362).

## [2.5.00] - 2021-06-28
### Added
- New major version 2.5 - privacy center removed from browse content [#370](https://github.com/rokwire/illinois-app/issues/370).
- Possibility for adding an image when creating group [#375](https://github.com/rokwire/illinois-app/issues/375).
### Fixed
- Crashes in home panel [#373](https://github.com/rokwire/illinois-app/issues/373).

## [2.4.31] - 2021-06-25
### Added 
- Added Privacy Center button in Browse panel [#349](https://github.com/rokwire/illinois-app/issues/349).
### Fixed
- Fixes in Groups without 1.5 [#351](https://github.com/rokwire/illinois-app/issues/351).
### Changed
- Increase fonts for category headings and card titles in Student Guide content [#352](https://github.com/rokwire/illinois-app/issues/352).
- improved styling for EventsCreatePanel [#345](https://github.com/rokwire/illinois-app/issues/345).

## [2.4.30] - 2021-06-24
### Changed 
- Updated Student Guide button icon and color in Browse panel [#338](https://github.com/rokwire/illinois-app/issues/338).
- Validate link url/location in Student Guide Detail [#340](https://github.com/rokwire/illinois-app/issues/340).
- Refresh Guide content when entering Student Guide [#342](https://github.com/rokwire/illinois-app/issues/342).
- Button title for creating group [#346](https://github.com/rokwire/illinois-app/issues/346).
- Changes to Create Group Even [#345](https://github.com/rokwire/illinois-app/issues/345).

## [2.4.29] - 2021-06-23
### Fixed
- Fix registration url json key for events [#330](https://github.com/rokwire/illinois-app/issues/330).
- Improve Accessibility for Student Guide [#320](https://github.com/rokwire/illinois-app/issues/320) 
### Changed 
- Updated students.guide.json from Illinois_Student_Guide_Final.xlsx [#332](https://github.com/rokwire/illinois-app/issues/332).
- Updated Student Guide UI according to Figma review [#335](https://github.com/rokwire/illinois-app/issues/335).

## [2.4.28] - 2021-06-22
### Fixed 
- Fixed guide description in Recently Viewed [#322](https://github.com/rokwire/illinois-app/issues/322).
- Do not show favorite button in Student Guide items if privacy level does not support this.
- Strip HTML tags from guide list title & description when show them in Saved or Recently Viewed.
- Events and virtual events improvements [#321](https://github.com/rokwire/illinois-app/issues/321).
- Improve Accessibility for Student Guide [#320](https://github.com/rokwire/illinois-app/issues/320) 
- Improve Accessibility for Events [#328](https://github.com/rokwire/illinois-app/issues/328) 

## [2.4.27] - 2021-06-21
### Changed 
- Update sample student guide to refer images on rokwire-images AWS bucket.
- Upgrade to Flutter 2.2.2 [#318](https://github.com/rokwire/illinois-app/issues/318).
### Added
- Added id, list title and list description getters in Student Guide service.

## [2.4.26] - 2021-06-18
### Added
- Hook up Student Guide in recent items.
### Changed 
- Hook up Students Guide API [#313](https://github.com/rokwire/illinois-app/issues/313).
### Fixed 
- Fixed err_cleartext_not_permitted error [#308](https://github.com/rokwire/illinois-app/issues/308)

## [2.4.25] - 2021-06-17
### Added
- Hook up Student Guide in user favorites.

### Changed 
- Various updates and fixes in Students Guide [#303](https://github.com/rokwire/illinois-app/issues/303).
- Event enhancements (virtual/in person, price etc) [#300](https://github.com/rokwire/illinois-app/issues/300).

## [2.4.24] - 2021-06-16
### Fixed
- Dining Dollars payment type processing [#295](https://github.com/rokwire/illinois-app/issues/295).
### Changed 
- Various minor updates related Students Guide [#299](https://github.com/rokwire/illinois-app/issues/299).

## [2.4.23] - 2021-06-15
### Changed 
- Imported 20210614_Student Import.xlsx, interoduced number list and content references [#293](https://github.com/rokwire/illinois-app/issues/293).

## [2.4.22] - 2021-06-14
### Changed 
- Updated promotion format to use boolean expession conditions for card and role [#286](https://github.com/rokwire/illinois-app/issues/286).
- Fixed inconsistencies from the initial designs of the On boarding panels. [284](https://github.com/rokwire/illinois-app/issues/284)

## [2.4.21] - 2021-06-11
### Added
- Created promoted student guide items widget in Home panel [#282](https://github.com/rokwire/illinois-app/issues/282).

## [2.4.20] - 2021-06-10
### Added
- Introduced Student Guide service [#282](https://github.com/rokwire/illinois-app/issues/282).
### Changed 
- Updated Student Guide UI as defined in Figma. 

## [2.4.19] - 2021-06-08
### Changed 
- Improved styling for Groups CreateEvent panel [276](https://github.com/rokwire/illinois-app/issues/276).
- Improved fix for not responding Browse tab bar button [#266](https://github.com/rokwire/illinois-app/issues/266) 

## [2.4.18] - 2021-06-08
### Changed
- Removed audience, rework UI for categories and sub categories hierarchy [#273](https://github.com/rokwire/illinois-app/issues/273).

## [2.4.17] - 2021-06-07
### Changed
- Fix not responding Browse tab bar button [#266](https://github.com/rokwire/illinois-app/issues/266) 
### Added
- Added audience, categories and sub categories hierarchy [#269](https://github.com/rokwire/illinois-app/issues/269).

## [2.4.16] - 2021-06-04
### Changed
- Hide Debug/Student Guide for prod [#264](https://github.com/rokwire/illinois-app/issues/264)

## [2.4.15] - 2021-06-03
### Changed
- Added more panels to Students Guide POC, sample content moved to assets or net. [#257](https://github.com/rokwire/illinois-app/issues/257)
- Updated styling for the On Boarding panels [#258](https://github.com/rokwire/illinois-app/issues/258)

## [2.4.14] - 2021-06-02
### Changed
- Updated Students Guide POC, added involvements. [#257](https://github.com/rokwire/illinois-app/issues/257)

## [2.4.13] - 2021-06-01
### Added
- Added Students Guide POC in Debug panel [#257](https://github.com/rokwire/illinois-app/issues/257)

## [2.4.12] - 2021-05-28
### Changed
- Using Onboarding2 [#176](https://github.com/rokwire/illinois-app/issues/176)
### Fixed
- Handled location error in iOS Directions controller [#254](https://github.com/rokwire/illinois-app/issues/254).

## [2.4.11] - 2021-05-26
### Fixed
- Illini Cash isn't displaying unless logged in [#252](https://github.com/rokwire/illinois-app/issues/252).

## [2.4.10] - 2021-05-21
### Changed
- Name change - "Cafe Credits" to "Dining Dollars" [#250](https://github.com/rokwire/illinois-app/issues/250).

## [2.4.9] - 2021-05-18
### Changed
- Flutter 2.0 integration [#245](https://github.com/rokwire/illinois-app/issues/245).

## [2.4.8] - 2021-05-14
### Added
- Added capability to override Styles content from Settings Debug panel [#246](https://github.com/rokwire/illinois-app/issues/246).

## [2.4.7] - 2021-05-13
### Fixed
- Handled exceptions when system date time is much behind the current date time [#243](https://github.com/rokwire/illinois-app/issues/243).

## [2.4.6] - 2021-04-12
### Fixed
- Wellness - PDF links is not loading in web view [#240](https://github.com/rokwire/illinois-app/issues/240).

### Changed
- Athletics - All Staff tile link is displayed along with Coaching Staff tile list [#239](https://github.com/rokwire/illinois-app/issues/239).

## [2.4.5] - 2021-03-31
### Fixed
- YouTube videos plays when screen locked [#235](https://github.com/rokwire/illinois-app/issues/235).
- Android: Prevent crash when FCM is received and the app is in killed state [#236](https://github.com/rokwire/illinois-app/issues/236).

### Deleted
- Removed linkage to flutter_image_compress plugin that is unused.

## [2.4.4] - 2021-02-09

## [2.4.3] - 2021-02-08
### Changed
- Do not edit straightly roles from user data [#229](https://github.com/rokwire/illinois-app/issues/229).

## [2.4.2] - 2021-02-05
### Fixed
- iOS distribution build error related to MinimumOSVersion in ios/Flutter/AppFrameworkInfo.plist. [#226](https://github.com/rokwire/illinois-app/issues/226)
- Additional handling on refresh oauth token and logout on 400, 401 & 403 status codes [#221](https://github.com/rokwire/illinois-app/issues/221)

## [2.4.1] - 2021-02-03
- Additional handling on refresh oauth token and logout on 401,403 status codes [#221](https://github.com/rokwire/illinois-app/issues/221)

## [2.4.0] - 2021-02-01
### Changed
- Explore Shibboleth login failure due to deleted UUID [#221](https://github.com/rokwire/illinois-app/issues/221)
- Include background location usage disclosure in Onboarding / Location Services Panel [#218](https://github.com/rokwire/illinois-app/issues/218)

## [2.3.31] - 2021-01-21
### Fixed
- Crashes with FCM notifications in Android [#213](https://github.com/rokwire/illinois-app/issues/213)
- Quick Polls freeze [#174](https://github.com/rokwire/illinois-app/issues/174)

## [2.3.30] - 2021-01-18
### Changed
- Update text on Dining menu items [#171](https://github.com/rokwire/illinois-app/issues/171)

## [2.3.29] - 2021-01-15
### Changed
- Updated Campus Reminders for Spring 2021 [#206](https://github.com/rokwire/illinois-app/issues/206)

### Fixed
- Dining Payment Types Not Filtering Correctly[#205](https://github.com/rokwire/illinois-app/issues/205)

## [2.3.27] - 2020-12-23
### Changed
- Various improvements related to the new Onboarding UI [#176](https://github.com/rokwire/illinois-app/issues/176)

## [2.3.26] - 2020-12-16
### Added
- Various improvements related to the Groups UI [#134](https://github.com/rokwire/illinois-app/issues/134)
- Various improvements related to the Groups API [#143](https://github.com/rokwire/illinois-app/issues/143)
- Updated URL for moved wellness tool [#172](https://github.com/rokwire/illinois-app/issues/172)

## [2.3.26] - 2020-12-15
### Added
- Various improvements related to the Groups UI [#134](https://github.com/rokwire/illinois-app/issues/134)
- Various improvements related to the Groups API [#143](https://github.com/rokwire/illinois-app/issues/143)

## [2.3.25] - 2020-12-11
### Added
- Various improvements related to the Groups UI [#134](https://github.com/rokwire/illinois-app/issues/134)
- Various improvements related to the Groups API [#143](https://github.com/rokwire/illinois-app/issues/143)

## [2.3.24] - 2020-12-09
### Added
- Various improvements related to the Groups UI [#134](https://github.com/rokwire/illinois-app/issues/134)
- Various improvements related to the Groups API [#143](https://github.com/rokwire/illinois-app/issues/143)

## [2.3.23] - 2020-12-07
### Added
- Various improvements related to the Groups UI [#134](https://github.com/rokwire/illinois-app/issues/134)
- Various improvements related to the Groups API [#143](https://github.com/rokwire/illinois-app/issues/143)

## [2.3.22] - 2020-11-30
### Added
- Various improvements related to the Groups UI [#134](https://github.com/rokwire/illinois-app/issues/134)
- Various improvements related to the Groups API [#143](https://github.com/rokwire/illinois-app/issues/143)

## [2.3.21] - 2020-11-25
### Fixed
- Fix Crashlytics and clean old fabric plugins #164(https://github.com/rokwire/illinois-app/issues/164)
- Fix Large font issue for _EventSmallCard widget [#165](https://github.com/rokwire/illinois-app/issues/165)

## [2.3.20] - 2020-11-23
### Added
- Various improvements related to the Groups UI [#134](https://github.com/rokwire/illinois-app/issues/134)


## [2.3.19] - 2020-11-17
### Added
- Contributor guidelines (CONTRIBUTING.md). [#126](https://github.com/rokwire/illinois-app/issues/126)
- A pull request template. [#128](https://github.com/rokwire/illinois-app/issues/128)

## [2.3.18] - 2020-11-06
### Fixed
- Fix startup screen issue. [#158](https://github.com/rokwire/illinois-app/issues/158)
- Fix showing sub events for a sub event. [#161](https://github.com/rokwire/illinois-app/issues/161)

## [2.3.17] - 2020-11-05
### Added
- Pass application id as header field in FCM API calls from sports service [#154](https://github.com/rokwire/illinois-app/issues/154).

### Fixed
- Fix location permission request in Android [#153](https://github.com/rokwire/illinois-app/issues/153)

## [2.3.16] - 2020-11-03
### Added
- Improved event filters based on dates [#83](https://github.com/rokwire/illinois-app/issues/83)

### Fixed
- FlexUI Remove role rule for laundry[#130](https://github.com/rokwire/illinois-app/issues/130)

## [2.3.15] - 2020-11-02
### Fixed
- Do not ignore unknown user roles [#147](https://github.com/rokwire/illinois-app/issues/147).

## [2.3.14] - 2020-10-29
### Fixed
- Hide groups. Appropriate fix [#135](https://github.com/rokwire/illinois-app/issues/135)
- Prevent crash in Android [#144](https://github.com/rokwire/illinois-app/issues/144)

## [2.3.13] - 2020-10-28
### Changed
- Hide groups [#135](https://github.com/rokwire/illinois-app/issues/135)

### Fixed
- Remove legacy crashlytics dependency from Android [#137](https://github.com/rokwire/illinois-app/issues/137)
- Fix crash in Android [#139](https://github.com/rokwire/illinois-app/issues/139)

## [2.3.12] - 2020-10-21
### Fixed
- Unable to log in with iOS Default Browser changed [#124](https://github.com/rokwire/illinois-app/issues/124)

## [2.3.11] - 2020-10-13
### Changed
- Upgrade Flutter to v1.22.1 - Additional fixes and cleanup [#116](https://github.com/rokwire/illinois-app/issues/116)

## [2.3.10] - 2020-10-12
### Changed
- Upgrade Flutter to v1.22.1 - fix broken Android polls plugin and crashlytics[#116](https://github.com/rokwire/illinois-app/issues/116)

## [2.3.9] - 2020-10-09
### Changed
- Upgrade Flutter to v1.22.1 [#116](https://github.com/rokwire/illinois-app/issues/116)
- Support languages defined only in the backend [#114](https://github.com/rokwire/illinois-app/issues/114)

### Fixed
- Make debug button being visible as in Safer Illinois App [#112](https://github.com/rokwire/illinois-app/issues/112)

## [2.3.8] - 2020-10-02
### Fixed
- Fix typo in notifications title [#27] (https://github.com/rokwire/illinois-app/issues/27)

### Changed
- Locale strings from net just override the built-in asset strings [104](https://github.com/rokwire/illinois-app/issues/104).

## [2.3.7] - 2020-10-01
### Added
- Created "Runner-Dev" XCode build environment for dev builds.
- Enable http proxying in flutter env [#100](https://github.com/rokwire/illinois-app/issues/100)

### Changed
- "ios/Runner/GoogleService-Info-Debug/Release.plist" secret file refs updated to "ios/Runner/GoogleService-Info-Dev/Prod.plist".

## [2.3.6] - 2020-09-30
 - Improve log data [#95](https://github.com/rokwire/illinois-app/issues/95)
 - Rollback temporary flutter_html to 0.11.1 due to accessibility issue [#92](https://github.com/rokwire/illinois-app/issues/92)
 - Better phone number validation is needed [#47](https://github.com/rokwire/illinois-app/issues/47)
 - BrowsePanel: updated color for Dining button [#44](https://github.com/rokwire/illinois-app/issues/44)

## [2.3.5] - 2020-09-23
 - Add role & student_level in analytics [#87](https://github.com/rokwire/illinois-app/issues/87)
 - Improved Semantics for ExploreDetailPanel [#15](https://github.com/rokwire/illinois-app/issues/15)
 - Improve Semantics for ExploreCard [#19](https://github.com/rokwire/illinois-app/issues/19)

## [2.3.4] - 2020-09-22
### Changed
 - i-Card may not being updated if the last update time is greater than 24 hours [#86](https://github.com/rokwire/illinois-app/issues/86)


## [2.3.3] - 2020-09-21
### Changed
- Handle properly role & student_level state within the UI [#84](https://github.com/rokwire/illinois-app/issues/84)
- Upgrade Flutter to v 1.20.2 + libraries update [#25](https://github.com/rokwire/illinois-app/issues/25)

## [2.3.2] - 2020-09-17
### Changed
- Use student_level instead of role from auth card API.[#80](https://github.com/rokwire/illinois-app/issues/80)

## [2.3.1] - 2020-09-15
### Fixed
- Load ordered sub events.[#48](https://github.com/rokwire/illinois-app/issues/48)
- ImproveAccessibility large text support [#37](https://github.com/rokwire/illinois-app/issues/37)

## [2.3.0] - 2020-09-08
### Fixed
- Fix end date time appearing.[#32](https://github.com/rokwire/illinois-app/issues/32)

## [2.2.18] - 2020-09-04
### Fixed
- Fix events filtering.[#49](https://github.com/rokwire/illinois-app/issues/49)
- Make events date format consistent.[#33](https://github.com/rokwire/illinois-app/issues/33)

## [2.2.17] - 2020-09-03
### Changed
- Show debug panel only for debug managers.[#51](https://github.com/rokwire/illinois-app/issues/51)
- Update es and zh strings.[#55](https://github.com/rokwire/illinois-app/issues/55)

## [2.2.16] - 2020-09-02
### Changed
- Removed Save buttons from Profile Informations panels

## [2.2.15] - 2020-09-01
### Changed
- Exposed Strings for localisation

## [2.2.14] - 2020-08-31
### Changed
- Improved VO features [#24](https://github.com/rokwire/illinois-app/issues/24)

## [2.2.13] - 2020-08-28
### Fixed
Removed COVID references from code. [#20](https://github.com/rokwire/illinois-app/issues/20)

## [2.2.12] - 2020-08-27
### Fixed
Fix Mobile Order deep link handling [#11](https://github.com/rokwire/illinois-app/issues/11)

### Added
- Latest content from the private repository.
- GitHub Issue templates.

### Changed
- Update README and repository description.
- Clean up CHANGELOG.
