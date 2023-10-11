# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

## [5.1.0] - 2023-10-02
- N/A

## [5.0.78] - 2023-10-10
### Fixed
- Showing all sub-events in Events2DetailPanel [#3790](https://github.com/rokwire/illinois-app/issues/3790).

## [5.0.77] - 2023-10-09
### Changed
- Event2DetailPanel update follow up survey message [#3788](https://github.com/rokwire/illinois-app/issues/3788).
- Removed "My" section from Browse panel, "My Athletics" and "My News" moved to "Athletics" section, most of the Athletics section entries renamed [#3787](https://github.com/rokwire/illinois-app/issues/3787)
### Fixed 
- Fix DeviceCalendar add to calendar functionality [#3789](https://github.com/rokwire/illinois-app/issues/3789).

## [5.0.76] - 2023-10-06
### Fixed
- Privacy level on user sign in [#3781](https://github.com/rokwire/illinois-app/issues/3781).
- Showing correct group events count [#3790](https://github.com/rokwire/illinois-app/issues/3790).

## [5.0.75] - 2023-10-04
### Fixed
- Loading "Speakers and Seminars" events [#3780](https://github.com/rokwire/illinois-app/issues/3780).
- Fix group privacy message [#3784](https://github.com/rokwire/illinois-app/issues/3784).

## [5.0.74] - 2023-09-29
### Fixed
- Acknowledge selected and highlighted states when guest list item is disabled [#3722](https://github.com/rokwire/illinois-app/issues/3722).

## [5.0.73] - 2023-09-27
### Changed
- English strings [#3770](https://github.com/rokwire/illinois-app/issues/3770).
- Prompt if attendee candidate is not registered or if event capacity is reached [#3722](https://github.com/rokwire/illinois-app/issues/3722).

## [5.0.72] - 2023-09-26
### Changed
- Acknowledged new Groups BB's v3 APIs for events [#3733](https://github.com/rokwire/illinois-app/issues/3733).

## [5.0.71] - 2023-09-25
### Changed
- Check for attendance takers that are also registrant before applying attendance takers [#3762](https://github.com/rokwire/illinois-app/issues/3762).
### Added
- Implemented "Renew" mobile access [#3763](https://github.com/rokwire/illinois-app/issues/3763).

## [5.0.70] - 2023-09-20
### Fixed
- Fix event survey update failure handling [#3758](https://github.com/rokwire/illinois-app/issues/3758).
- Fixed notifications display time [#381](https://github.com/rokwire/app-flutter-plugin/issues/381).

## [5.0.69] - 2023-09-19
### Fixed
- Event survey settings don't save between event admins [#3723](https://github.com/rokwire/illinois-app/issues/3723).
### Changed
- Updated chinese strings [#3749](https://github.com/rokwire/illinois-app/issues/3749).

## [5.0.68] - 2023-09-18
### Fixed
- Display raw attribute value as it is if it does not persist as content attribute value [#3743](https://github.com/rokwire/illinois-app/issues/3743).
- Do not show additional attendance takers edit when creating/updating event, make it available ONLY when editing event attendance strsaightly [#3656](https://github.com/rokwire/illinois-app/issues/3656).
- Fix Sport events not being able to be add to group[#3739](https://github.com/rokwire/illinois-app/issues/3739).

## [5.0.67] - 2023-09-15
### Fixed
- Do not show Register button until we are sure that registration is available for the event [#3671](https://github.com/rokwire/illinois-app/issues/3671).
- Event additional attendance takers [#3656](https://github.com/rokwire/illinois-app/issues/3656).

## [5.0.66] - 2023-09-13
### Fixed
- Show date range for game events [#3735](https://github.com/rokwire/illinois-app/issues/3735).
- Event additional attendance takers [#3656](https://github.com/rokwire/illinois-app/issues/3656).

## [5.0.65] - 2023-09-12
### Changed
- Upgrade to connectivity_plus plugin [#45](https://github.com/rokmetro/vogue-app/issues/45).
- Android: Update HID / Origo sdk to 1.9.1 [#3725](https://github.com/rokwire/illinois-app/issues/3725).
- iOS: Update HID / Origo sdk to 1.10.0 [#3727](https://github.com/rokwire/illinois-app/issues/3727).
### Fixed
- Showing live games [#3729](https://github.com/rokwire/illinois-app/issues/3729).
### Added
- Display registration type in guest list from attendance panel [#3722](https://github.com/rokwire/illinois-app/issues/3722).
- Play sound when adding attedees to guest list [#3722](https://github.com/rokwire/illinois-app/issues/3722).

## [5.0.64] - 2023-09-08
### Changed
- Show events time in local timezone [#3718](https://github.com/rokwire/illinois-app/issues/3718).

## [5.0.63] - 2023-09-07
### Fixed
- SavedPanel: load events from events/lite (includes private events) [#3709](https://github.com/rokwire/illinois-app/issues/3709).
- Display time for game events in local timezone and show past and upcoming games based on event day/time until midnight [#3714](https://github.com/rokwire/illinois-app/issues/3714).
- Fixed DSYM upload for Firebase Crashlytics on iOS.

## [5.0.62] - 2023-09-05
### Added
- Added Guest List to Registration Setup Panel [#3678](https://github.com/rokwire/illinois-app/issues/3678).
### Changed
- Changed texts in Registration and Attendance Panels [#3678](https://github.com/rokwire/illinois-app/issues/3678).
- Acknowledged event capacity in registration and attendance taking [#3671](https://github.com/rokwire/illinois-app/issues/3671).

## [5.0.61] - 2023-09-04
### Changed
- Event2CreatePanel update attendance description [#3702](https://github.com/rokwire/illinois-app/issues/3702).
- Acknowledge location description when presenting event locations [#3510](https://github.com/rokwire/illinois-app/issues/3510).

## [5.0.60] - 2023-09-01
### Changed
- Hide Illini ID FAQs for all [#3696](https://github.com/rokwire/illinois-app/issues/3696).
- Show mobile access based on the mobile id status [#3698](https://github.com/rokwire/illinois-app/issues/3698).
### Added
- Bring back dialog for adding event to multiple groups that user is admin of [#3695](https://github.com/rokwire/illinois-app/issues/3695).
### Fixed
- Group events load private events for group members[#3674](https://github.com/rokwire/illinois-app/issues/3674).

## [5.0.59] - 2023-08-31
### Changed
- Rename "i-card" to "Illini ID" [#3685](https://github.com/rokwire/illinois-app/issues/3685).
- Do not show FAQs for users that do not have Mobile Access [#3687](https://github.com/rokwire/illinois-app/issues/3687).
- Events Feed renamed to All Events [#3690](https://github.com/rokwire/illinois-app/issues/3690).
- Removed members selection when Create/Add event to group [#3672](https://github.com/rokwire/illinois-app/issues/3672).
### Fixed
- Wording for team roster and staff [#3682](https://github.com/rokwire/illinois-app/issues/3682).
- ### Added
- Added dialog prompt to Star an event after successful registration [#3692](https://github.com/rokwire/illinois-app/issues/3692).

### Changed
## [5.0.58] - 2023-08-30
### Changed
- Update mobile access model [#3679](https://github.com/rokwire/illinois-app/issues/3679).
- To-Do item header title [#3677](https://github.com/rokwire/illinois-app/issues/3677).
### Fixed
- Content attributes min-selection requirement validation [#3631](https://github.com/rokwire/illinois-app/issues/3631).

## [5.0.57] - 2023-08-29
### Changed
- Event Admin Required to Fill Out Survey [#3581](https://github.com/rokwire/illinois-app/issues/3581).
- Updated en and zh string files [#3665](https://github.com/rokwire/illinois-app/issues/3665).
- Remove unneeded descriptions form Attendance panel [#3661](https://github.com/rokwire/illinois-app/issues/3661).
### Added
- New Mobile Access flow for requesting credentials [#3651](https://github.com/rokwire/illinois-app/issues/3651).

## [5.0.56] - 2023-08-28
### Added
- Two new locale default analytics [#3648](https://github.com/rokwire/illinois-app/issues/3648).
### Changed
- Hide Laundry location button even if it's location is valid [#1674](https://github.com/rokwire/illinois-app/issues/1674).
- Rename Attendee List to Registrants in Event2AttendanceDetailPanel [#3647](https://github.com/rokwire/illinois-app/issues/3647).
### Fixed
- Groups load upcoming events [#3645](https://github.com/rokwire/illinois-app/issues/3645).
- Fixed typo. Rename Cineese to chinese [#3646](https://github.com/rokwire/illinois-app/issues/3646).

## [5.0.55] - 2023-08-25
### Changed
- Create event panel UI polish and improvements [#3585](https://github.com/rokwire/illinois-app/issues/3585).
- Use better ratio images for Android splash screen [#3307](https://github.com/rokwire/illinois-app/issues/3307).
### Added
- Added Pinch Zoom support for ModalImagePanel [#3305](https://github.com/rokwire/illinois-app/issues/3305).
- Hook up "Request" button in Mobile access [#3641](https://github.com/rokwire/illinois-app/issues/3641).
### Fixed
- Do not show "View on map" command if laundry room has no location data [#3299](https://github.com/rokwire/illinois-app/issues/3299).

## [5.0.54] - 2023-08-24
### Changed
- Hide "Renew" button in Mobile Access [#3634](https://github.com/rokwire/illinois-app/issues/3634).
- Renamed Sponsor to Event Host [#3392](https://github.com/rokwire/illinois-app/issues/3392).
### Added
- Added filters & sort capabilities when searching events [#3633](https://github.com/rokwire/illinois-app/issues/3633).
### Fixed
- Fixed total number of events in Event2SearchPanel [#3633](https://github.com/rokwire/illinois-app/issues/3633).

## [5.0.53] - 2023-08-23
### Fixed
- Displaying sport for athletics events [#3621](https://github.com/rokwire/illinois-app/issues/3621).
- Fixed URLs parsing, validation and processing in Create Event and Event detail panels [#3580](https://github.com/rokwire/illinois-app/issues/3580).
### Added
- Added published flag in create/update event panel [#3623](https://github.com/rokwire/illinois-app/issues/3623).
- CreateEventPanel add additional description in description section [#3620](https://github.com/rokwire/illinois-app/issues/3620).
### Changed
- Do not allow building event datetime on date part only [#3585](https://github.com/rokwire/illinois-app/issues/3585).
- Twitter renamed to X/Twitter [#3610](https://github.com/rokwire/illinois-app/issues/3610).

## [5.0.52] - 2023-08-22
### Fixed
- Displaying correct date time in athletics [#3611](https://github.com/rokwire/illinois-app/issues/3611).
### Changed
- Sample appointments updated with a true McKinley location [#3604](https://github.com/rokwire/illinois-app/issues/3604).
- Use different separators to highlight attribute values groups [#3605](https://github.com/rokwire/illinois-app/issues/3605).
- Handled events search in Map [#3609](https://github.com/rokwire/illinois-app/issues/3609).

## [5.0.51] - 2023-08-21
### Added
- Added required sign for hours title in Event2SetupSurveyPanel [#3582](https://github.com/rokwire/illinois-app/issues/3582).
- Added default course detail image [#2286](https://github.com/rokwire/illinois-app/issues/2286).
- Handle sport events from Calendar BB [#3594](https://github.com/rokwire/illinois-app/issues/3594).
### Changed
- More precise processing of 'Confirm URL' command in Event2CreatePanel [#3580](https://github.com/rokwire/illinois-app/issues/3580).
- Updated content attributes master copy [#3578](https://github.com/rokwire/illinois-app/issues/3578).
- Event Feed Tweaks [#3392](https://github.com/rokwire/illinois-app/issues/3392).

## [5.0.50] - 2023-08-18
### Changed
- Rename "i-card" to "Illini ID" in Settings [#3588](https://github.com/rokwire/illinois-app/issues/3588).
- Read event attendance url from app config [#3584](https://github.com/rokwire/illinois-app/issues/3584).
### Fixed
- Show Twitter in favorites [#3590](https://github.com/rokwire/illinois-app/issues/3590).
- Use calendar events for Academics / Events [#3586](https://github.com/rokwire/illinois-app/issues/3586).
### Added
- Added language selector in Settings panel [#3587](https://github.com/rokwire/illinois-app/issues/3587).
- Added check for end time before start time in create event panel [#3585](https://github.com/rokwire/illinois-app/issues/3585).

## [5.0.49] - 2023-08-17
### Changed
- "Multi-person" calendar event filter type renamed to "Multi-event" [#3570](https://github.com/rokwire/illinois-app/issues/3570).
- Do not show "Next Available Appointment" if no slots are available [#3261](https://github.com/rokwire/illinois-app/issues/3261).
### Fixed
- Fixed Daily Illini RSS feeds parsing [#3572](https://github.com/rokwire/illinois-app/issues/3572).
- Make sure not to show State Farm Center in Favorites or Browse panels [#3298](https://github.com/rokwire/illinois-app/issues/3298).
- Fix adding super event to group [#3564](https://github.com/rokwire/illinois-app/issues/3564).
### Added
- Added background update and pull to refresh capability of MTD stop schedules panel [#3325](https://github.com/rokwire/illinois-app/issues/3325).

## [5.0.48] - 2023-08-16
### Changed
- Updated privacy strings [#3332](https://github.com/rokwire/illinois-app/issues/3332).
- Decouple Favourites from Device Calendar [#3558](https://github.com/rokwire/illinois-app/issues/3558).
- Load again content attributes JSON from content service [#3560](https://github.com/rokwire/illinois-app/issues/3560).
### Fixed
- Android: request for location permission [#3563](https://github.com/rokwire/illinois-app/issues/3563).

## [5.0.47] - 2023-08-15
### Fixed
- Cannot update survey created in admin app [#3542](https://github.com/rokwire/illinois-app/issues/3542).
- Displaying athletics events [#3544](https://github.com/rokwire/illinois-app/issues/3544).
- Fixed spelling of dietitian in Dining [#3404](https://github.com/rokwire/illinois-app/issues/3404).
- Fixed Profile Settings panel inconsistencies [#3315](https://github.com/rokwire/illinois-app/issues/3315).
### Changed
- Enable cost description for free events [#3461](https://github.com/rokwire/illinois-app/issues/3461).
- Removed periods from button titles [#3435](https://github.com/rokwire/illinois-app/issues/3435).
- Renamed "Event admin actions" to "Event admin settings" [#3431](https://github.com/rokwire/illinois-app/issues/3431).
- Do not load URLs from Event2DetailPanel in a WebPanel [#3430](https://github.com/rokwire/illinois-app/issues/3430).
- Change HomeAthleticsGameDayWidget empty message [#3341](https://github.com/rokwire/illinois-app/issues/3341).

## [5.0.46] - 2023-08-14
### Added
- Event admins cannot load all survey responses [#3524](https://github.com/rokwire/illinois-app/issues/3524).
- Added "Multi-person" event type [#3531](https://github.com/rokwire/illinois-app/issues/3531).
- Added recent items support for calendar events [#3535](https://github.com/rokwire/illinois-app/issues/3535).
### Changed
- Show mobile credential id in Mobile Access UI [#3529](https://github.com/rokwire/illinois-app/issues/3529).
- Updated app version format in welcome widget in Favorites panel [#3528](https://github.com/rokwire/illinois-app/issues/3528).
- Update groups events to use calendar BB [#3506](https://github.com/rokwire/illinois-app/issues/3506).
- Show Apply button in disabled state in Event2TimeRangePanel. Display proper message if needed [#3518](https://github.com/rokwire/illinois-app/issues/3518).
- Do not limit event title wrap to 2 lines in detail panel [#3517](https://github.com/rokwire/illinois-app/issues/3517).
- Renamed register buttons in Event2DetailPanel [#3508](https://github.com/rokwire/illinois-app/issues/3508).
- Hide old events from Map panel [#3507](https://github.com/rokwire/illinois-app/issues/3507).
### Fixed
- Fixed text style in Athletics News [#3526](https://github.com/rokwire/illinois-app/issues/3526).

## [5.0.45] - 2023-08-11
### Changed
- Updated Event2Card UI [#3520](https://github.com/rokwire/illinois-app/issues/3520).
- Updated Event2DetailPanel UI [#3522](https://github.com/rokwire/illinois-app/issues/3522).

## [5.0.44] - 2023-08-10
### Changed
- Cleaned up and polished the UI for super & recurring events [#3513](https://github.com/rokwire/illinois-app/issues/3513).

## [5.0.43] - 2023-08-09
### Changed
- Improve event survey UI [#3500](https://github.com/rokwire/illinois-app/issues/3500).
- Bring back College and Department attributes for Event2 and remove University Affiliation [#3500](https://github.com/rokwire/illinois-app/issues/3500)
- Do not require at least one attribute set when creating groups [#3500](https://github.com/rokwire/illinois-app/issues/3500).
### Added
- Added initial implementation of super & recurring events [#3513](https://github.com/rokwire/illinois-app/issues/3513).

## [5.0.42] - 2023-08-08
### Changed
- Use "Events Feed" term instead of "Event Feed" [#3486](https://github.com/rokwire/illinois-app/issues/3486).
- Do not require attributes selection for calendar events [#3502](https://github.com/rokwire/illinois-app/issues/3502).
- Reworked attributes Apply & Clear control [#3504](https://github.com/rokwire/illinois-app/issues/3504).

## [5.0.41] - 2023-08-04
### Fixed
- Event Survey panel wrongly shows Apply button when invoked from Create/Update panel [#3481](https://github.com/rokwire/illinois-app/issues/3481).
### Changed
- Illinois Assistant Wording Updates [#3462](https://github.com/rokwire/illinois-app/issues/3462)
- Survey description does not depend on registration status [#3487](https://github.com/rokwire/illinois-app/issues/3487)
- Optimized event detail initialization - do not load persons and survey if event has no survey [#3487](https://github.com/rokwire/illinois-app/issues/3487).
- Updated event content attributes [#3495](https://github.com/rokwire/illinois-app/issues/3495).
### Added
- Added manual attendee input by Net ID [#3489](https://github.com/rokwire/illinois-app/issues/3489).
- Added analytics log of map items selection [#3497](https://github.com/rokwire/illinois-app/issues/3497).

## [5.0.40] - 2023-08-03
### Added
- Event follow-up survey responses [#3452](https://github.com/rokwire/illinois-app/issues/3452).
### Changed
- Display extended information about registration, attendance and survey [#3475](https://github.com/rokwire/illinois-app/issues/3475).
- Require attendance setup if survey is specified in Create/Update Event2 panel [#3475](https://github.com/rokwire/illinois-app/issues/3475).
- Prompt before exiting modified content in Create/Update Event2 panel [#3475](https://github.com/rokwire/illinois-app/issues/3475).
### Fixed
- Fixed registration API responses and their processing [#3479](https://github.com/rokwire/illinois-app/issues/3479).
- Fixed updating survey details [#3481](https://github.com/rokwire/illinois-app/issues/3481).

## [5.0.39] - 2023-08-02
### Changed
- Updated info description for participants of events with surveys [#3463](https://github.com/rokwire/illinois-app/issues/3463).
- Handled follow-up survey notification for event attendees [#3465](https://github.com/rokwire/illinois-app/issues/3465).
### Fixed
- Make sure not to start Mobile Access service if it is not available for the particular user [#3467](https://github.com/rokwire/illinois-app/issues/3467).

## [5.0.38] - 2023-08-01
### Changed
- Attendance taker widget obeys attendance details settings [#3453](https://github.com/rokwire/illinois-app/issues/3453).
### Added
- Added info description for participants of events with surveys [#3456](https://github.com/rokwire/illinois-app/issues/3456).
### Fixed
- Get rid of completely from "Events²" title [#3459](https://github.com/rokwire/illinois-app/issues/3459).
- Accessibility improvements for Events panels [#3421](https://github.com/rokwire/illinois-app/issues/3421).

## [5.0.37] - 2023-07-31
### Added
- Event follow up survey preview and entry point [#3439](https://github.com/rokwire/illinois-app/issues/3439).
### Deleted
- Removed Events2 attributes image background [#3442](https://github.com/rokwire/illinois-app/issues/3442).
- Removed the references to the old events in Home and Browse panels [#3450](https://github.com/rokwire/illinois-app/issues/3450).
### Changed
- Updated Event2 onboarding UI [#3445](https://github.com/rokwire/illinois-app/issues/3445).
- Use extended error messaging for Events2 content [#3447](https://github.com/rokwire/illinois-app/issues/3447).
- Refresh Events2 home widget content on user login/logout [#3300](https://github.com/rokwire/illinois-app/issues/3300).

## [5.0.36] - 2023-07-27
### Added
- Query best and worst matches for the career explorer by changing the sort order and find a specific job by searching [#3415](https://github.com/rokwire/illinois-app/issues/3415).
- Handled HID Origo support for iOS [#2921](https://github.com/rokwire/illinois-app/issues/2921).

## [5.0.35] - 2023-07-25
### Changed
- Updated follow-up survey details UI [#3300](https://github.com/rokwire/illinois-app/issues/3300).
- Polish and fixing UI tweaks [#3300](https://github.com/rokwire/illinois-app/issues/3300).

## [5.0.34] - 2023-07-24
### Fixed
- Fixed register/unregister/delete in Event2DetailPanel [#3300](https://github.com/rokwire/illinois-app/issues/3300).
### Changed
- Prompt before deleting an Event2 [#3300](https://github.com/rokwire/illinois-app/issues/3300).
### Added
- Hooked up follow-up survery in Event2DetailPanel [#3300](https://github.com/rokwire/illinois-app/issues/3300).

## [5.0.33] - 2023-07-21
### Changed
- Attendance taking UI improvements [#3300](https://github.com/rokwire/illinois-app/issues/3300).

## [5.0.32] - 2023-07-20
### Changed
- Acknowledged /event/id/users API from Calendar BB. Hooked up attendace updates with dummy APIs for now [#3300](https://github.com/rokwire/illinois-app/issues/3300).

## [5.0.31] - 2023-07-19
### Changed
- Hooked up "Event Attendance" from Event2 detail admin settings [#3300](https://github.com/rokwire/illinois-app/issues/3300).

## [5.0.30] - 2023-07-18
### Changed
- Hooked up "Event Registration" from Event2 detail admin settings [#3300](https://github.com/rokwire/illinois-app/issues/3300).

## [5.0.29] - 2023-07-17
### Changed
- Transfer only affected profile prefs when login from onboarding [#3416](https://github.com/rokwire/illinois-app/issues/3416).

## [5.0.28] - 2023-07-14
### Changed
- Update context for Illinois Assistant [#3410](https://github.com/rokwire/illinois-app/issues/3410).
- Show mobile key external id instead of mobile credential id [#2921](https://github.com/rokwire/illinois-app/issues/2921).
### Fixed
- Preserve user favorites stored in Core account data [#3412](https://github.com/rokwire/calendar-building-block/issues/3412).
### Removed
- "Device is Unlocked" setting in icard [#2921](https://github.com/rokwire/illinois-app/issues/2921).
- "Notification Drawer" setting in icard [#2921](https://github.com/rokwire/illinois-app/issues/2921).

## [5.0.27] - 2023-07-13
### Changed
- Hide/Disable "All Day Event" property [#3405](https://github.com/rokwire/illinois-app/issues/3405).
- "View All" link moved between navigation controls for all Favroites widgets [#3407](https://github.com/rokwire/illinois-app/issues/3407).

## [5.0.26] - 2023-07-12
### Changed
- Renamed "i-card+" to "Illini ID" [#3399](https://github.com/rokwire/illinois-app/issues/3399).
### Added
- Created and hooked up Event2SearchPanel [#3401](https://github.com/rokwire/illinois-app/issues/3401).
### Fixed
- Fixed Events2 search by type [#160](https://github.com/rokwire/calendar-building-block/issues/160).

## [5.0.25] - 2023-07-11
### Fixed
- Opening correct academics panel from Browse [#3393](https://github.com/rokwire/illinois-app/issues/3393).
### Added
- Implemented Events2 widgets for Favorites panel [#3390](https://github.com/rokwire/illinois-app/issues/3390).
### Changed
- Handled edit event [#3396](https://github.com/rokwire/illinois-app/issues/3396).

## [5.0.24] - 2023-07-10
### Changed
- Show "Take Attendance" only to event admins and attendance takers [#3360](https://github.com/rokwire/illinois-app/issues/3360).
### Fixed
- Tap over the whole surface of the guide entry card [#3388](https://github.com/rokwire/illinois-app/issues/3388).

## [5.0.23] - 2023-07-07
### Changed
- Assistant UI improvements [#3372](https://github.com/rokwire/illinois-app/issues/3372).
- Label in Follow-Up Survey panel [#3376](https://github.com/rokwire/illinois-app/issues/3376).
- Include end time when displaying event time [#3379](https://github.com/rokwire/illinois-app/issues/3379).
### Added
- Events2 attendance detail panel - work in progress [#3360](https://github.com/rokwire/illinois-app/issues/3360).
- Display events count in Events2 home panel [#3384](https://github.com/rokwire/illinois-app/issues/3384).
### Deleted
- Remove take attendance via the app switch [#3374](https://github.com/rokwire/illinois-app/issues/3374).
- Remove sort order switch from Events2 UI [#3382](https://github.com/rokwire/illinois-app/issues/3382).

## [5.0.22] - 2023-07-06
### Added
- Added background image to Events2 filters panel [#3356](https://github.com/rokwire/illinois-app/issues/3356).
### Removed
- "Preview" survey button in Create Event panel [#3357](https://github.com/rokwire/illinois-app/issues/3357).
### Changed
- Events2 home panel text updates [#3361](https://github.com/rokwire/illinois-app/issues/3361).
- Improved custom start and end time filter validation [#3361](https://github.com/rokwire/illinois-app/issues/3361).
- Polished event date display [#3364](https://github.com/rokwire/illinois-app/issues/3364).
- Do not launch directions from event card, show distance for inperson events [#3366](https://github.com/rokwire/illinois-app/issues/3366).

## [5.0.21] - 2023-07-05
### Added
- Follow-Up survey details in Create Event panel [#3353](https://github.com/rokwire/illinois-app/issues/3353).
- Sponsorship and Contacts in Create Event panel [#3300](https://github.com/rokwire/illinois-app/issues/3300).

## [5.0.20] - 2023-07-04
### Changed
- Updated event detail panel [#3300](https://github.com/rokwire/illinois-app/issues/3300).

## [5.0.19] - 2023-07-04
### Added
- Illinois Assistant query limits and feedback integration [#3349](https://github.com/rokwire/illinois-app/issues/3349).
- Location picker utility in Create Event panel [#3300](https://github.com/rokwire/illinois-app/issues/3300).
### Changed
- Initialize simplified default content for Favorites panel [#3346](https://github.com/rokwire/illinois-app/issues/3346).
- Cleaned up registratio setup panel [#3300](https://github.com/rokwire/illinois-app/issues/3300).
- Updated event detail panel [#3300](https://github.com/rokwire/illinois-app/issues/3300).

## [5.0.18] - 2023-07-03
### Changed
- Do not initialize default content for Favorites panel [#3346](https://github.com/rokwire/illinois-app/issues/3346).
- Preserve Home and Browse tout images aspect ratio while loading.
- Update Event2DetailPanel [#3300](https://github.com/rokwire/illinois-app/issues/3300).
### Added
- Hooked up attendance details in create event panel [#3300](https://github.com/rokwire/illinois-app/issues/3300).

## [5.0.17] - 2023-06-30
### Changed
- Check for calendar admin permission to expose Create Event2 button [#3343](https://github.com/rokwire/illinois-app/issues/3343).
### Added
- Hooked up event registration in create event panel [#3300](https://github.com/rokwire/illinois-app/issues/3300).

## [5.0.16] - 2023-06-29
### Changed
- Hooked up first cut-off version of Create Event2 panel [#3300](https://github.com/rokwire/illinois-app/issues/3300).

## [5.0.15] - 2023-06-26
### Added
- Created Create Event2 panel, in progress [#3300](https://github.com/rokwire/illinois-app/issues/3300).

## [5.0.14] - 2023-06-23
### Added
- Added filters to Events2 map view and implemented list/map swtiching [#3300](https://github.com/rokwire/illinois-app/issues/3300).
- Added support for "events" fcm notification deep link [#3326](https://github.com/rokwire/illinois-app/issues/3326).
### Changed
- Expect yyyy-MM-dd date format for expiration date in student id [#2921](https://github.com/rokwire/illinois-app/issues/2921).

## [5.0.13] - 2023-06-22
### Added
- Implemented gradual page loading of Events2 home panel content [#3300](https://github.com/rokwire/illinois-app/issues/3300).
- Implemented location based filters and sort in Events2 home panel [#3300](https://github.com/rokwire/illinois-app/issues/3300).
- Created Events2 map view [#3300](https://github.com/rokwire/illinois-app/issues/3300).
- Display user's 6-digit credential id in mobile access UI [#2921](https://github.com/rokwire/illinois-app/issues/2921).

## [5.0.12] - 2023-06-20
### Changed
- Handled custom range Event Time filter in Events2 home panel [#3300](https://github.com/rokwire/illinois-app/issues/3300).
### Added
- Added sort type and sort order capabilitues in Events2 home panel [#3300](https://github.com/rokwire/illinois-app/issues/3300).

## [5.0.11] - 2023-06-19
### Added
- Added fcm notification deep link support for: Athletics/Team, Athletics/Tam/Roster and Guide/Article/Detail [#3326](https://github.com/rokwire/illinois-app/issues/3326).
### Removed
- "Twist And Go" from icard+ settings [#2921](https://github.com/rokwire/illinois-app/issues/2921).

## [5.0.10] - 2023-06-16
### Added
- Added Event Time filter and related attribute updates [#3300](https://github.com/rokwire/illinois-app/issues/3300).

## [5.0.9] - 2023-06-15
### Added
- Added Event Types filter and related attribute updates [#3300](https://github.com/rokwire/illinois-app/issues/3300).
### Changed
- Export button text styles to styles.json [#2932](https://github.com/rokwire/illinois-app/issues/2932).

## [5.0.8] - 2023-06-12
### Added
- Illinois Assistant chatbot integration [#3220](https://github.com/rokwire/illinois-app/issues/3220).
- Initial preview of new Events interface [#3300](https://github.com/rokwire/illinois-app/issues/3300).

## [5.0.7] - 2023-06-12
### Added
- Initial integration with HID / Origo sdk for mobile access [#2921](https://github.com/rokwire/illinois-app/issues/2921).
- Health Screener looks and functions similar to skills assessment [#2988](https://github.com/rokwire/illinois-app/issues/2988).

## [5.0.6] - 2023-05-29
### Added
- Add survey creation tool [#3295](https://github.com/rokwire/illinois-app/issues/3295).
### Fixed
- Upgrade dependencies for Flutter v3.10 [#3294](https://github.com/rokwire/illinois-app/issues/3294).
### Changed
- Cleaned up Explore interface [#3301](https://github.com/rokwire/illinois-app/issues/3301)

## [5.0.5] - 2023-05-23
- Created and acknowledged at different places async versions of JSON encode/decode and collection equality checks [#3292](https://github.com/rokwire/illinois-app/issues/3292).

## [5.0.4] - 2023-05-22
### Changed
- Load different JSON assets from content service [#3278](https://github.com/rokwire/illinois-app/issues/3278).
- Retire Assets service [#3278](https://github.com/rokwire/illinois-app/issues/3278).

## [5.0.3] - 2023-05-19
### Changed
- Use "content_id" as guide article identifier [#3287](https://github.com/rokwire/illinois-app/issues/3287).
- Use Styles().textStyles everywhere [#2932](https://github.com/rokwire/illinois-app/issues/2932.)

## [5.0.2] - 2023-05-17
### Added
- New video tutorial "Creating Polls" [#3285](https://github.com/rokwire/illinois-app/issues/3285).

## [5.0.1] - 2023-05-16
### Added
- Handle deep links for main panel content [#3240](https://github.com/rokwire/illinois-app/issues/3240).

## [5.0.0] - 2023-05-15
### Changed
- Load content attributes JSON from content service [#3278](https://github.com/rokwire/illinois-app/issues/3278).

## [4.3.61] - 2023-05-12
### Fixed
- Fixed favourites card title textStyle [#3273](https://github.com/rokwire/illinois-app/issues/3273).

## [4.3.60] - 2023-05-11
### Fixed
- Fixed WellnessRingWidget update mechanism that was causing infinite initialization loop when offline [#3270](https://github.com/rokwire/illinois-app/issues/3270).

## [4.3.59] - 2023-05-10
### Changed
- Changed texts for Appointments scheduling [#3266](https://github.com/rokwire/illinois-app/issues/3266).
- Change empty student courses message [#3263](https://github.com/rokwire/illinois-app/issues/3263).
### Fixed
- Remove duplicated message for Maps pop up dialog [#3260](https://github.com/rokwire/illinois-app/issues/3260).

## [4.3.58] - 2023-05-09
### Changed
- Athletics entries in Browse [#3258](https://github.com/rokwire/illinois-app/issues/3258).

## [4.3.57] - 2023-05-06
### Changed
- Hide unknown next available appointment [#3252](https://github.com/rokwire/illinois-app/issues/3252).
- Update static sample appointments data [#3254](https://github.com/rokwire/illinois-app/issues/3252).
- Display person's name in appointment schedule time panel [#3256](https://github.com/rokwire/illinois-app/issues/3256).

## [4.3.56] - 2023-05-05
### Changed
- Switch Telehealth/Online depending on provider [#3241](https://github.com/rokwire/illinois-app/issues/3241).
- Show person's name in Appointments card, clean up card's layout [#3241](https://github.com/rokwire/illinois-app/issues/3241).
- Do not show safer McKinley link in Detail panel for other providers [#3244](https://github.com/rokwire/illinois-app/issues/3244).
- Updated number of advisors text [#3246](https://github.com/rokwire/illinois-app/issues/3246).
- Rename "time slot" to "available appointment" [#3248](https://github.com/rokwire/illinois-app/issues/3248).

## [4.3.55] - 2023-05-04
### Changed
- "My College of Medicine Compliance" label [#3231](https://github.com/rokwire/illinois-app/issues/3231).
- Acknowledged new fields for appointment unit and person [#3230](https://github.com/rokwire/illinois-app/issues/3230).
- Load appointments in a standalone panel when invoked from Browse [#3234](https://github.com/rokwire/illinois-app/issues/3234).
- Updates in Groups Home Panel [#3236](https://github.com/rokwire/illinois-app/issues/3236).
- Updated logic in AppointmentTimeSchedule panel [#3238](https://github.com/rokwire/illinois-app/issues/3238).

## [4.3.54] - 2023-05-03
### Changed
- Appointments UI updates [#3225](https://github.com/rokwire/illinois-app/issues/3225).
### Fixed
- Fixed athletics games event title style [#3210](https://github.com/rokwire/illinois-app/issues/3210).

## [4.3.53] - 2023-05-02
### Changed
- Cleanup and polish Appointments UI [#3222](https://github.com/rokwire/illinois-app/issues/3222).

## [4.3.52] - 2023-05-01
### Changed
- Pass time slot id to update appointment API [#3213](https://github.com/rokwire/illinois-app/issues/3213).
- Update Appointments to work in University time [#3215](https://github.com/rokwire/illinois-app/issues/3215).
- Removed notifications UI from Saved panel [#2903](https://github.com/rokwire/illinois-app/issues/2903).
### Fixed
- Fixed "Forgot Password" link text color [#3211](https://github.com/rokwire/illinois-app/issues/3211).
- Fixed principle investigator typo [#3212](https://github.com/rokwire/illinois-app/issues/3212).

## [4.3.51] - 2023-04-28
### Fixed
- Cleanup data caching in StudentCourses service [#3200](https://github.com/rokwire/illinois-app/issues/3200).
- Cleanup Accessibility for MentalHealthResources and Appointments Scheduling [#3182](https://github.com/rokwire/illinois-app/issues/3182).
### Changed
- Pass time slot id to create appointment API [#3202](https://github.com/rokwire/illinois-app/issues/3202).
- Added nextAvailable to appointment person and unit [#3206](https://github.com/rokwire/illinois-app/issues/3206).
### Added
- Added Appointments section in Browse [#3204](https://github.com/rokwire/illinois-app/issues/3204).

## [4.3.50] - 2023-04-27
### Changed
- Rename Map > Mental Health Resources to Map > Find a Therapist [#3194](https://github.com/rokwire/illinois-app/issues/3194).
- Rename "Specials" to "Dining News" in Residence Hall Dining [#3187](https://github.com/rokwire/illinois-app/issues/3187).
- Handled Appointmnts service APIs updates [#3198](https://github.com/rokwire/illinois-app/issues/3198).
- Cleanuped UI and logic using real data feed [#3198](https://github.com/rokwire/illinois-app/issues/3198).
### Fixed
- Cleaned up directions / url launching in Event detail panel [#3193](https://github.com/rokwire/illinois-app/issues/3193).

## [4.3.49] - 2023-04-26
### Changed
- Handle appointments when user is not logged in [#3167](https://github.com/rokwire/illinois-app/issues/3167).
- Updated advanced settings defaults for new research projects [#3177](https://github.com/rokwire/illinois-app/issues/3177).
### Fixed
- Fixed passing group or project when browsing for events for them [#3175](https://github.com/rokwire/illinois-app/issues/3175).

## [4.3.48] - 2023-04-25
### Changed
- New applointments UI moved from Wellness to Academics [#3179](https://github.com/rokwire/illinois-app/issues/3179).
- Acknowledge appointment provider flags [#3181](https://github.com/rokwire/illinois-app/issues/3181).
- Pass ExternalAuthorization header to new Appointments network calls [#3167](https://github.com/rokwire/illinois-app/issues/3167).
- Acknowledged new v2/appointments API [#3167](https://github.com/rokwire/illinois-app/issues/3167).
### Fixed
- Do not display location link for student course when location is not available [#3100](https://github.com/rokwire/illinois-app/issues/3100).

## [4.3.47] - 2023-04-24
### Changed
- Display video thumb in "Mental Health Resources". Play the video in another panel with subtitles [#3164](https://github.com/rokwire/illinois-app/issues/3164).
- Hook up appointments APIs [#3167](https://github.com/rokwire/illinois-app/issues/3167).
- Launch privacy policy content when offline [#3052](https://github.com/rokwire/illinois-app/issues/3052).
### Fixed
- Fix MyCalendarSettings toggle buttons [#3083](https://github.com/rokwire/illinois-app/issues/3083).
- Improve Accessibility for HomeToutWidget [#3026](https://github.com/rokwire/illinois-app/issues/3026).
- Athletics events filter [#3077](https://github.com/rokwire/illinois-app/issues/3077).
### Added
- Show user's profile picture in Wellness Rings [#3081](https://github.com/rokwire/illinois-app/issues/3081).

## [4.3.46] - 2023-04-21
### Changed
- Appointments model synked with backend [#3149](https://github.com/rokwire/illinois-app/issues/3149).
- My Groups empty message change [#3066](https://github.com/rokwire/illinois-app/issues/3066).
### Fixed
- Fixed system widgets update in Home panel [#3111](https://github.com/rokwire/illinois-app/issues/3111).
- Handling tap action in inbox notifications [#3159](https://github.com/rokwire/illinois-app/issues/3159).
- Fixed buildings target location evaluation for maps directions [#3100](https://github.com/rokwire/illinois-app/issues/3100).

## [4.3.45] - 2023-04-20
### Added
- Added title parameters to SliverToutHeaderBar [#3149](https://github.com/rokwire/illinois-app/issues/3149).
- Embed video in Mental Health panel [#3148](https://github.com/rokwire/illinois-app/issues/3148).
### Changed
- Schedule appointments updates [#3149](https://github.com/rokwire/illinois-app/issues/3149).
### Added
- Fixed Mental Health Resources title [#3154](https://github.com/rokwire/illinois-app/issues/3154).

## [4.3.44] - 2023-04-19
### Added
- Created appointment schedule host and questions UI preview [#3136](https://github.com/rokwire/illinois-app/issues/3136).
### Changed
- GroupDetail: moved group sync/update message to GroupMembersPanel [#3135](https://github.com/rokwire/illinois-app/issues/3135).
- Some links are open in external browser [#3088](https://github.com/rokwire/illinois-app/issues/3088).
- Reworked Mental Health Resources [#3142](https://github.com/rokwire/illinois-app/issues/3142).
### Deleted
- Removed Explore.toJson definition, not used any more [#3070](https://github.com/rokwire/illinois-app/issues/3070).
### Fixed
- Fix Dining feedback dialog [#3087](https://github.com/rokwire/illinois-app/issues/3087).
- Fix HomeToDoWidget item checkmark [#3080](https://github.com/rokwire/illinois-app/issues/3080).

## [4.3.43] - 2023-04-18
### Changed
- Updated Dining description [#3110](https://github.com/rokwire/illinois-app/issues/3110).
- Increase padding for notifications badge [#2919](https://github.com/rokwire/illinois-app/issues/2919).
### Added
- Created appointment schedule host and questions UI, in progress [#3136](https://github.com/rokwire/illinois-app/issues/3136).

## [4.3.42] - 2023-04-13
### Changed
- UI updates in AppointmentTimeSlotPanel [#3125](https://github.com/rokwire/illinois-app/issues/3125).
- Removed tappable items from Appointment Unit card [#3127](https://github.com/rokwire/illinois-app/issues/3127).
- Open group post urls in an external browser [#3129](https://github.com/rokwire/illinois-app/issues/3129).
- Load mental health buildings mapping from content service [#3131](https://github.com/rokwire/illinois-app/issues/3131).
- Updated colleges and departments in content attributes [#3133](https://github.com/rokwire/illinois-app/issues/3133).

## [4.3.41] - 2023-04-12
### Added
- My College of Medicine Courses [#3118](https://github.com/rokwire/illinois-app/issues/3118).
### Changed
- Updated Mental Health Resource buildings [#3120](https://github.com/rokwire/illinois-app/issues/3120).
- In Android, open an external browser for the Optional Web Link when we see it as More Info  (like in about) [#3122](https://github.com/rokwire/illinois-app/issues/3122).

## [4.3.40] - 2023-04-11
### Changed
- Updated Research Project tweaks [#3112](https://github.com/rokwire/illinois-app/issues/3112).
### Fixed
- Fixed map type selection in ExploeMapPanel.notifySelect notification [#3060](https://github.com/rokwire/illinois-app/issues/3060).
### Added
- Auto fill Guide Highlights favorites [#3032](https://github.com/rokwire/illinois-app/issues/3032).

## [4.3.39] - 2023-04-10
### Deleted
- "My College of Medicine Courses" in Academics panel and all related stuff [#3105](https://github.com/rokwire/illinois-app/issues/3105).
### Added
- Added reschedule appointment preview [#3074](https://github.com/rokwire/illinois-app/issues/3074).
### Changed
- Hooked up appointments provicers API [#3074](https://github.com/rokwire/illinois-app/issues/3074).
### Fixed
- Do not display empty compund widgets in Home/Customize [#3078](https://github.com/rokwire/illinois-app/issues/3078).

## [4.3.38] - 2023-04-07
### Deleted
- Removed ExploreJsonHandler definition, not used any more [#3070](https://github.com/rokwire/illinois-app/issues/3070).
### Added
- Allow deep linking to app tabs via notification [#3094](https://github.com/rokwire/illinois-app/issues/3094).
- New "My College of Medicine Courses" item in Academics content [#3097](https://github.com/rokwire/illinois-app/issues/3097).
### Changed
- Schedule appointment preview progress [#3074](https://github.com/rokwire/illinois-app/issues/3074).

## [4.3.37] - 2023-04-06
### Changed
- Schedule appointment preview progress [#3074](https://github.com/rokwire/illinois-app/issues/3074).

## [4.3.36] - 2023-04-05
### Changed
- Display mental health resources grouped by sections [#3084](https://github.com/rokwire/illinois-app/issues/3084).
- Created new wellness content type for new appointments support. Load sample providers. [#3074](https://github.com/rokwire/illinois-app/issues/3074).

## [4.3.35] - 2023-04-04
### Added
- Created schedule appointment time slot selector preview [#3074](https://github.com/rokwire/illinois-app/issues/3074).

## [4.3.34] - 2023-04-03
### Deleted
- Removed native maps support [#3070](https://github.com/rokwire/illinois-app/issues/3070).

## [4.3.33] - 2023-03-31
### Changed
- Static Wellness content moved from assets.json to content service [#3064](https://github.com/rokwire/illinois-app/issues/3064).
### Added
- Added Mental Health resource content type in Maps and Maps2 [#3067](https://github.com/rokwire/illinois-app/issues/3067).

## [4.3.32] - 2023-03-29
### Changed
- Research project updates [#3055](https://github.com/rokwire/illinois-app/issues/3055).
### Added
- Create Mental Health content type in Wellness home panel and all related support [#3062](https://github.com/rokwire/illinois-app/issues/3062).

## [4.3.31] - 2023-03-28
### Added
- Canvas Courses: Show submitted date in assignments if available [#3056](https://github.com/rokwire/illinois-app/issues/3056). 

## [4.3.30] - 2023-03-27
### Changed
- Refer to google_maps_flutter plugin located in rokwire's upstream fork [#3043](https://github.com/rokwire/illinois-app/issues/3043). 
- Content attributes prepared for multiple scopes support [#3047](https://github.com/rokwire/illinois-app/issues/3047).
- Hide StateFarm parking everywhere in the app [#3053](https://github.com/rokwire/illinois-app/issues/3053).
### Fixed
- Fixed hiding user details in analytics logs [#3049](https://github.com/rokwire/illinois-app/issues/3049).

## [4.3.29] - 2023-03-20
### Changed
- Link to custom fork of google_maps_flutter where POI tap notification is handled [#3043](https://github.com/rokwire/illinois-app/issues/3043).

## [4.3.28] - 2023-03-17
### Fixed
- Fixed POI display in Maps2 [#3038](https://github.com/rokwire/illinois-app/issues/3038).
### Changed
- More careful updates in Maps2 when connectivity status changes [#3041](https://github.com/rokwire/illinois-app/issues/3041).

## [4.3.27] - 2023-03-16
### Changed
- Prompt for text message body in text and tell feature [#3036](https://github.com/rokwire/illinois-app/issues/3036)

## [4.3.26] - 2023-03-15
### Added
- Added text and tell feature to Dining location detail panel [#3034](https://github.com/rokwire/illinois-app/issues/3034).

## [4.3.25] - 2023-03-13
### Fixed
- Fixed checkbox image asset in Group Notifications panel.
- Fixed updating groups in Groups favorite widget [#2939](https://github.com/rokwire/illinois-app/issues/2939).
### Added
- Added favorite star to GameDay widgets in Home panel [#2930](https://github.com/rokwire/illinois-app/issues/2930).

## [4.3.24] - 2023-03-10
### Changed
- More sophisticated rebuild of favorite widgets when guide content gets updated [#3027](https://github.com/rokwire/illinois-app/issues/3027).

## [4.3.23] - 2023-03-08
### Changed
- Populate title field in favorite analytics event [#3021](https://github.com/rokwire/illinois-app/issues/3021).
### Added
- Added source field in WebPanel page analytics details [#3021](https://github.com/rokwire/illinois-app/issues/3021).

## [4.3.22] - 2023-03-07
### Added
- Show year in the canvas assignment due date if the year is not current [#3017](https://github.com/rokwire/illinois-app/issues/3017).
- Preload image selection if already selected [#3019](https://github.com/rokwire/illinois-app/issues/3019).

## [4.3.21] - 2023-03-06
### Changed
- Do not show "Due" date label in canvas assignments if there is no value [#3013](https://github.com/rokwire/illinois-app/issues/3013).
### Added
- Open to-do list panel on reminder notification if to-do entry id is missing [#3015](https://github.com/rokwire/illinois-app/issues/3015).
### Fixed
- Do not set to-do item as completed if the backend returns an error [#3015](https://github.com/rokwire/illinois-app/issues/3015).

## [4.3.20] - 2023-03-02
### Added
- Bring back old Canvas UI with debug switch [#3011](https://github.com/rokwire/illinois-app/issues/3011).

## [4.3.19] - 2023-02-23
### Added
- Switch of the data source for Canvas Courses [#3006](https://github.com/rokwire/illinois-app/issues/3006).

## [4.3.18] - 2023-02-22
- N/A

## [4.3.17] - 2023-02-20
- N/A

## [4.3.16] - 2023-02-14
- N/A

## [4.3.15] - 2023-02-13
### Fixed
- Fixed navigation target when requesting directions to building in embedded map plugin [#2955](https://github.com/rokwire/illinois-app/issues/2955).

## [4.3.14] - 2023-02-10
### Fixed
- Fixed group-5 image references in styles.json.
- Fixed the most obvious color issues with style images [#2979](https://github.com/rokwire/illinois-app/issues/2979).

## [4.3.13] - 2023-02-09
### Changed
- Group/Project attribute/filters updates [#2974](https://github.com/rokwire/illinois-app/issues/2974).

## [4.3.12] - 2023-02-08
### Changed
- Removed the popup panel for editing attributes dropdown content, use cupertino navigation route instead [#2954](https://github.com/rokwire/illinois-app/issues/2954).
- Updated group sub-panels to use cupertino navigation route instead of popup-like [#2967](https://github.com/rokwire/illinois-app/issues/2967).
- Created standalone HomeCustomizeFavoritesPanel for Favorites panel content customization [#2972](https://github.com/rokwire/illinois-app/issues/2972).

## [4.3.11] - 2023-02-07
### Changed
- Created popup panel for editing attributes dropdown content [#2954](https://github.com/rokwire/illinois-app/issues/2954).

## [4.3.10] - 2023-02-06
### Changed
- Updated group attributes logic [#2954](https://github.com/rokwire/illinois-app/issues/2954).

## [4.3.9] - 2023-02-02
### Changed
- Group's category and tags replaced by attributes [#2926](https://github.com/rokwire/illinois-app/issues/2926).

## [4.3.8] - 2023-01-31
### Added
- Added RSO group attribute and checkbox attribute support [#2926](https://github.com/rokwire/illinois-app/issues/2926).

## [4.3.7] - 2023-01-30
### Changed
- Content filters renamed to Content Attributes [#2926](https://github.com/rokwire/illinois-app/issues/2926).
- Use category id as category selection key [#2926](https://github.com/rokwire/illinois-app/issues/2926).
- Updated Group Attributes panel behavior [#2926](https://github.com/rokwire/illinois-app/issues/2926).

## [4.3.6] - 2023-01-27
### Added
- Edit lastAppReviewTime from SettingsDebugPanel [#2941](https://github.com/rokwire/illinois-app/issues/2941).
- Added Filters to group settings [#2926](https://github.com/rokwire/illinois-app/issues/2926).
### Changed
- Acknowledged University colleges and departments, added categories and tags filter for test purpose [#2926](https://github.com/rokwire/illinois-app/issues/2926).

## [4.3.5] - 2023-01-25
### Added
- Added Group filters to groups home panel [#2926](https://github.com/rokwire/illinois-app/issues/2926).

## [4.3.4] - 2023-01-24
### Changed
- Store filter selection in groups as {filter_id : option_id} mapping [#2926](https://github.com/rokwire/illinois-app/issues/2926).

## [4.3.3] - 2023-01-23
### Changed
- Group filters moved to standalone panel [#2926](https://github.com/rokwire/illinois-app/issues/2926).
- Preserve Group filters dropdown popup when selecting items that are multiple selected [#2926](https://github.com/rokwire/illinois-app/issues/2926).

## [4.3.2] - 2023-01-20
### Changed
- Access MTD via content service [#2922](https://github.com/rokwire/illinois-app/issues/2922).
- Removed access to shibboleth section from config secret keys (unused).
- Fixed checkbox image style in research questionnaire.
- Changed usage of HTMLWidget. Use flutter_widget_from_html for better Accessibility support. [#2912](https://github.com/rokwire/illinois-app/issues/2912).
### Added
- Acknwoledge Google Maps flutter plugin [#2904](https://github.com/rokwire/illinois-app/issues/2904).
- Added filters in create group panel [#2926](https://github.com/rokwire/illinois-app/issues/2926).

## [4.3.1] - 2023-01-12
### Changed
- Use Styles().images [#2476](https://github.com/rokwire/illinois-app/issues/2476).
- Revert upcoming release version number to 4.3 [#2915](https://github.com/rokwire/illinois-app/issues/2915).
### Added
- Display managed and membership date fields in GroupDetailPanel [#2907](https://github.com/rokwire/illinois-app/issues/2907).
- Show current year in copyright statement [#2899](https://github.com/rokwire/illinois-app/issues/2899).

## [4.3.0] - 2023-01-04
### Changed
- Switch to xCode 14.2.

## [4.2.55] - 2023-04-03
### Added
- New "Illinois Health Screener" video [#3069](https://github.com/rokwire/illinois-app/issues/3069).

## [4.2.54] - 2023-03-28
### Changed
- Updated default initial selection in Maps [#1942](https://github.com/rokwire/illinois-app/issues/1942).
- Removed To-Do List from Wellness Section [#2951](https://github.com/rokwire/illinois-app/issues/2951).
- Embed guide content in Academics and Wellness home panels [#3004](https://github.com/rokwire/illinois-app/issues/3004).
- Research project updates [#3055](https://github.com/rokwire/illinois-app/issues/3055).

## [4.2.53] - 2023-02-20
### Changed
- Update MTD text to include “Bus” [#2952](https://github.com/rokwire/illinois-app/issues/2952).
- Move To-Do List to Academics Section [#2951](https://github.com/rokwire/illinois-app/issues/2951).

## [4.2.52] - 2023-02-16
### Changed
- Launch privacy policy web content in an external web browser on iOS platforms [#2909](https://github.com/rokwire/illinois-app/issues/2909).
- Launch feedback web content in an external web browser on iOS platforms [#2909](https://github.com/rokwire/illinois-app/issues/2909).

## [4.2.51] - 2023-02-15
### Fixed
- Fixed scrolling issues in research questionnaire prompt and acknowledgement panels [#2985](https://github.com/rokwire/illinois-app/issues/2985).
- Android: Crash for foldable devices  [#2920](https://github.com/rokwire/illinois-app/issues/2920).

## [4.2.50] - 2023-02-13
### Changed
- Updated analytics log for research questionnaire answers [#2910](https://github.com/rokwire/illinois-app/issues/2910).
- Updated English strings [#2956](https://github.com/rokwire/illinois-app/issues/2956).
### Fixed
- Displaying athletics event from notifications inbox [#2874](https://github.com/rokwire/illinois-app/issues/2874).
- Handle tap action over poll and wellness todo items notification [#2645](https://github.com/rokwire/illinois-app/issues/2645).
- Load appointments only if the user is signed in [#2923](https://github.com/rokwire/illinois-app/issues/2923).
- Scrolling in wellness MyMcKinley Appointments [#2958](https://github.com/rokwire/illinois-app/issues/2958).
- Open appointments list panel on tap over appointment inbox message if appointment id does not exist [#2969](https://github.com/rokwire/illinois-app/issues/2969).
- Open appointment detail panel on tap over appointment inbox message [#2969](https://github.com/rokwire/illinois-app/issues/2969).
- Fixed navigation target when requesting directions to building [#2955](https://github.com/rokwire/illinois-app/issues/2955).
- Retrieve sorted appointments from the backend [#2971](https://github.com/rokwire/illinois-app/issues/2971).
### Added
- Cache appointments account [#2905](https://github.com/rokwire/illinois-app/issues/2905).

## [4.2.49] - 2023-01-05
### Fixed
- Fixed delete poll notification processing [#2173](https://github.com/rokwire/illinois-app/issues/2173).
- Fixed dropdown menu needs extending in Groups Manage Members [#2407](https://github.com/rokwire/illinois-app/issues/2407).
- Fixed empty iCard expiration date processing for retired faculty/staff [#2892](https://github.com/rokwire/illinois-app/issues/2892).
- Fixed update privacy dialog scrolling (+ some other nonsense items) [#2891](https://github.com/rokwire/illinois-app/issues/2891).
- Formatting date times in events [#2719](https://github.com/rokwire/illinois-app/issues/2719).
### Changed
- Show user profile picture for personal info button in root header bar [#2157](https://github.com/rokwire/illinois-app/issues/2157).
- Text update: Settings - Sign In/Sign Out [#2457](https://github.com/rokwire/illinois-app/issues/2457).

## [4.2.48] - 2023-01-03
### Fixed
- Refresh issue with appointments [#2843](https://github.com/rokwire/illinois-app/issues/2843).
- Added appointments default end date time [#2842](https://github.com/rokwire/illinois-app/issues/2842).
- Remove dimmed foreground decoration from video tutorial thumbnails [#2823](https://github.com/rokwire/illinois-app/issues/2823).
- Fixed "Add Cover Image" button background color [#2868](https://github.com/rokwire/illinois-app/issues/2868).
### Added
- Added muted indicator to inbox message card [#2877](https://github.com/rokwire/illinois-app/issues/2877).
- Show not logged in message in Illini Cash and MTD Buss Wallet cards [#2867](https://github.com/rokwire/illinois-app/issues/2877).
### Deleted
- Removed explanation message "View current studies that match ..." from questionnaire acknowledgement panel [#2873](https://github.com/rokwire/illinois-app/issues/2873).
### Changed
- Always use orange favorite icon, removed all references to the blue favorite icon [#2165](https://github.com/rokwire/illinois-app/issues/2165).

## [4.2.47] - 2022-12-22
### Changed
- Polls :: not-signed-in error - needs better message [#2777](https://github.com/rokwire/illinois-app/issues/2777).
- Updated favorite star behavior of compound MTD stops [#2822](https://github.com/rokwire/illinois-app/issues/2822).
- Updated research questionnaire prompt message [#2849](https://github.com/rokwire/illinois-app/issues/2849).
- Updated no research projects message text in favorite widget [#2845](https://github.com/rokwire/illinois-app/issues/2845).
- Updated View Email Address setting entry text [#2830](https://github.com/rokwire/illinois-app/issues/2830).
- Updated "Event" to "Events" in group notification settings [#2829](https://github.com/rokwire/illinois-app/issues/2829).
- "Search Stop" is updated to "Search Stops" in MTD home panel dropdown [#2821](https://github.com/rokwire/illinois-app/issues/2821).
- Updated checkbox images in PollCard [#2802](https://github.com/rokwire/illinois-app/issues/2802).
### Fixed
- Remove loading card from home inbox widget [#2846](https://github.com/rokwire/illinois-app/issues/2846).
- Fixed expanding compund MTD bus stops [#2851](https://github.com/rokwire/illinois-app/issues/2851).
- Fixed detail open from single MTD Stop [#2851](https://github.com/rokwire/illinois-app/issues/2851).
- Fixed Illinois Health Screener in Browse / Wellness section [#2848](https://github.com/rokwire/illinois-app/issues/2848).
- Fixed NetID and Sign-in prompted at Privacy Level 3 during onboarding [#2826](https://github.com/rokwire/illinois-app/issues/2826).
- Fixed Dining Locations loading in Maps [#2841](https://github.com/rokwire/illinois-app/issues/2841).
- Fixed never ending progress indicator in Maps [#2841](https://github.com/rokwire/illinois-app/issues/2841).
- Implement appointments notifications and reminders [#2621](https://github.com/rokwire/illinois-app/issues/2621).
- Fixed error and empty status in All/Unread Notifications favorite card [#2847](https://github.com/rokwire/illinois-app/issues/2847).

## [4.2.46] - 2022-12-21
### Fixed
- Fix BESSI content items response handling [#2820](https://github.com/rokwire/illinois-app/issues/2820).
- Remove title from welcome video [#2831](https://github.com/rokwire/illinois-app/issues/2831).
- Fixed various problems in Maps [#2834](https://github.com/rokwire/illinois-app/issues/2834).
### Added
- Various Notification updates [#2833](https://github.com/rokwire/illinois-app/issues/2833).

## [4.2.45] - 2022-12-20
### Fixed
- Android: show bus stops on the map when zooming [#2807](https://github.com/rokwire/illinois-app/issues/2807).
- Android: hide marker info view for bus stops [#2809](https://github.com/rokwire/illinois-app/issues/2809).
### Changed
- iOS: show activity indicator while processing markers [#2811](https://github.com/rokwire/illinois-app/issues/2811).
- Allow marking POIs or Locations in Map only in MTD Destinations content type [#2813](https://github.com/rokwire/illinois-app/issues/2813).
- View All on favorite MTD Stops & Destinations launches relevant home panel instead of Saved [#2815](https://github.com/rokwire/illinois-app/issues/2815).

## [4.2.44] - 2022-12-19
### Fixed
- Improve accessibility for Health Screener and BESSI [#2788](https://github.com/rokwire/illinois-app/issues/2788).
- External website 2FA login loop for McKinley portal [#2578](https://github.com/rokwire/illinois-app/issues/2578).
- Update resources for "Who Are You?" icons [#2577](https://github.com/rokwire/illinois-app/issues/2577).
- Fixed tweaks on Favorite MTD items details [#2597](https://github.com/rokwire/illinois-app/issues/2597).
- Fixed video rotation on iOS 16 [#2587](https://github.com/rokwire/illinois-app/issues/2587).
### Changed
- Present research questionnaire on startup after upgrade [#2793](https://github.com/rokwire/illinois-app/issues/2793).

## [4.2.43] - 2022-12-16
### Fixed
- MTD Bus Stop favorites issues [#2775](https://github.com/rokwire/illinois-app/issues/2775).
- Fixed alert for insufficient privacy level when attempting to open group detail panel [#2756](https://github.com/rokwire/illinois-app/issues/2756).
- Hide "Vote" button after user selectes all options in a poll [#2776](https://github.com/rokwire/illinois-app/issues/2776).
- Fixed text styles in ExploreCard and ProfileInfo content widget [#2757](https://github.com/rokwire/illinois-app/issues/2757).
### Added
- Added switch to allow/disable sending post to additional groups [#2765](https://github.com/rokwire/illinois-app/issues/2765).
- Issues related to inbox notifications [#2778](https://github.com/rokwire/illinois-app/issues/2778).
### Changed
- Refresh Map tab content when the Map tab is selcted or the app is awaken from background [#2734](https://github.com/rokwire/illinois-app/issues/2734).

## [4.2.42] - 2022-12-15
### Changed
- Added Skills Self-Evaluation entry in Academics section in Browse panel [#2746](https://github.com/rokwire/illinois-app/issues/2746).
### Changed
- Updated GroupAdvancedSettingsPanel [#2744](https://github.com/rokwire/illinois-app/issues/2744).
- Updated privacy content statements [#2763](https://github.com/rokwire/illinois-app/issues/2763).
### Fixed
- Fixed privacy content statement strings [#2763](https://github.com/rokwire/illinois-app/issues/2763).
- Unread notifications issues [#2761](https://github.com/rokwire/illinois-app/issues/2761).
- Cleaned up Create Group / Research Project button processing [#2740](https://github.com/rokwire/illinois-app/issues/2740).
- Fixed Campus Guide Highlights home widget [#2785](https://github.com/rokwire/illinois-app/issues/2785).
- Fix access widget strings and BESSI clear scores [#2770](https://github.com/rokwire/illinois-app/issues/2770).

## [4.2.41] - 2022-12-14
### Fixed
- Android: app bundle builds [#2741](https://github.com/rokwire/illinois-app/issues/2741).
- Fixed empty Illini Cash and Meal Plan Wallet widgets content after login [#2736](https://github.com/rokwire/illinois-app/issues/2736).
- Skills Self- Evaluation - "Clear all Scores" is not clearing the scores [#2731](https://github.com/rokwire/illinois-app/issues/2731).
### Changed
- Removed debug label in native iOS MapView.
- Use specific item cards, where possible, in ExploreListPanel [#2664](https://github.com/rokwire/illinois-app/issues/2664).
- Ensure visible the newly created groups [#2683](https://github.com/rokwire/illinois-app/issues/2683).
- Updated Research Projects section description in Browse panel [#2729](https://github.com/rokwire/illinois-app/issues/2729).
- Removed "Enable attendance checking" from Create Group / Group Settings panels [#2685](https://github.com/rokwire/illinois-app/issues/2685).
- Removed "Take Attendance" from admin view in Group [#2685](https://github.com/rokwire/illinois-app/issues/2685).
- "My Favorites" dropdown item in Settings renamed to "Customize Favorites" [#2735](https://github.com/rokwire/illinois-app/issues/2735).
- Rename Group setting switch [#2753](https://github.com/rokwire/illinois-app/issues/2753).
### Added
- Android: handle MTD stops on the Google map [#2711](https://github.com/rokwire/illinois-app/issues/2711).

## [4.2.40] - 2022-12-13
### Changed
- Updated privacy descriptions [#2720](https://github.com/rokwire/illinois-app/issues/2720).
- MTD Map strings updates [#2722](https://github.com/rokwire/illinois-app/issues/2722).
- GroupMemberNotificationsPanel: update override switches to get global settings values if main override switch is of [#2713](https://github.com/rokwire/illinois-app/issues/2713).
### Fixed
- Fixed HomeGroupWidget vertical overflow.
- Fixed initial camera zoom and position when presenting empty explores list in iOS [#2727](https://github.com/rokwire/illinois-app/issues/2727).
### Added
- Implemented MTD Stops search [#2724](https://github.com/rokwire/illinois-app/issues/2724).
- Standardize logged out widget [#2668](https://github.com/rokwire/illinois-app/issues/2668).

## [4.2.39] - 2022-12-12
### Changed
- Introduce Surveys BB [#2703](https://github.com/rokwire/illinois-app/issues/2703).
- Hide "Allow repeat votes" from Create Poll panels [#2686](https://github.com/rokwire/illinois-app/issues/2686).
- Update Group Member Selection Panel [#2708](https://github.com/rokwire/illinois-app/issues/2708).
- Renamed "Posts" section to "Posts and Direct Messages" in Group Detail Panel [#2252](https://github.com/rokwire/illinois-app/issues/2252).
- Update Group Member Notifications Panel [#2713](https://github.com/rokwire/illinois-app/issues/2713).
### Fixed
- Style definition for wellness to-do item card [#2702](https://github.com/rokwire/illinois-app/issues/2702).
- Show MyMcKinley appointments in home panel based on the user favorites [#2702](https://github.com/rokwire/illinois-app/issues/2702).
- Check for login status before presenting create poll panel [#2705](https://github.com/rokwire/illinois-app/issues/2705).
- Fixed groups sort order inconsistency [#2716](https://github.com/rokwire/illinois-app/issues/2716).
### Added
- Added delete functionality for poll options in create poll panel [#2085](https://github.com/rokwire/illinois-app/issues/2085).

## [4.2.38] - 2022-12-09
### Fixed
- Privacy level is not getting saved property [#2666](https://github.com/rokwire/illinois-app/issues/2666).
### Added
- Sort items and sections in Browse panel [#2699](https://github.com/rokwire/illinois-app/issues/2699).

## [4.2.37] - 2022-12-09
### Added
- Show "Cancelled" label for Appointments [#2692](https://github.com/rokwire/illinois-app/issues/2692).
### Fixed
- Fixed Teams Coach and Roaster list panels open full size image url[#2694](https://github.com/rokwire/illinois-app/issues/2694).
- McKinley link and phone number handling[#2659](https://github.com/rokwire/illinois-app/issues/2659).
### Changed
- MTD Stops and Desinations map view updates [#2633](https://github.com/rokwire/illinois-app/issues/2633).

## [4.2.36] - 2022-12-08
### Changed
- Updated research projects questionnaire [#2669](https://github.com/rokwire/illinois-app/issues/2669).
- Texts for MyMcKinley appointments [#2662](https://github.com/rokwire/illinois-app/issues/2662).
- GroupNotifications Panel changed override switch styling [#2648](https://github.com/rokwire/illinois-app/issues/2648).
- GroupDetailPanel change Notifications button label to "Notification Preferences" [#2649](https://github.com/rokwire/illinois-app/issues/2649).
### Added
- Added user friendly alerts when native directions controller fails to build a route [#2615](https://github.com/rokwire/illinois-app/issues/2615).
- Show departures in My MTD Buss items [#2633](https://github.com/rokwire/illinois-app/issues/2633).
- Handle multiple BESSI score profiles [#2647](https://github.com/rokwire/illinois-app/issues/2647)
### Fixed
- Fix Appointments Image behaviour [#2660](https://github.com/rokwire/illinois-app/issues/2660).
- Show appointment instructions in detail panel [#2653](https://github.com/rokwire/illinois-app/issues/2653).
- Fixed navigation from Browse / My / My Research Projects [#2656](https://github.com/rokwire/illinois-app/issues/2656).
- Fixed appointment detection in app native sides [#2664](https://github.com/rokwire/illinois-app/issues/2664).
- Show appointment location detail in underlined link style [#2665](https://github.com/rokwire/illinois-app/issues/2665).
- Make appointment display time in 12-hour format [#2663](https://github.com/rokwire/illinois-app/issues/2663).
- Issues in HomeStudentCoursesWidget [#2654](https://github.com/rokwire/illinois-app/issues/2654).
- Fix Create Group Panel: can auto join switch is not working [#2642](https://github.com/rokwire/illinois-app/issues/2642).
- Fixed map notifications from Android native side [#2633](https://github.com/rokwire/illinois-app/issues/2633).

## [4.2.35] - 2022-12-07
### Added
- Implemented MTD Destinations [#2633](https://github.com/rokwire/illinois-app/issues/2633).
- Log events when user plays video [#2650](https://github.com/rokwire/illinois-app/issues/2650).
### Fixed
- Fixed Test build configurations for iOS.

## [4.2.34] - 2022-12-06
### Added
- Updates for plugin survey action and UI changes [#2638](https://github.com/rokwire/illinois-app/issues/2638).
- Added favorite button to Map target popup & MTD bus schedule panel [#2633](https://github.com/rokwire/illinois-app/issues/2633).
### Changed
- Cleaned up processing MTD bus stops in Explore Panel / Map display type [#2633](https://github.com/rokwire/illinois-app/issues/2633).

## [4.2.33] - 2022-12-05
### Fixed
- Blank screen on tapping Daily Illini item [#2627](https://github.com/rokwire/illinois-app/issues/2627).
- GMSMarker creation in iOS Map view [#2516](https://github.com/rokwire/illinois-app/issues/2516).
### Changed
- Research Projects updates [#2626](https://github.com/rokwire/illinois-app/issues/2626).
- Optimize video tutorial entry UI [#2635](https://github.com/rokwire/illinois-app/issues/2635).
- MTDStopDeparturesPanel reworked [#2633](https://github.com/rokwire/illinois-app/issues/2633).
- Updated thresoldDistanceByZoom map in iOS, show debug label with current zoom and threshold distance [#2633](https://github.com/rokwire/illinois-app/issues/2633).
### Added
- New video tutorial "Creating a New Group" [#2631](https://github.com/rokwire/illinois-app/issues/2631).

## [4.2.32] - 2022-12-02
### Fixed
- Make proper check for missing appointments url [#2614](https://github.com/rokwire/illinois-app/issues/2614).
- Standardize favorite widget text styles [#2584](https://github.com/rokwire/illinois-app/issues/2584)
- BESSI cleanup [#2612](https://github.com/rokwire/illinois-app/issues/2612)
### Changed
- Implemented Campus Safety Resources [#2618](https://github.com/rokwire/illinois-app/issues/2618).

## [4.2.31] - 2022-12-01
### Added
- Add BESSI Survey [#2491](https://github.com/rokwire/illinois-app/issues/2491).
- Switch on/off displaying appointments [#2606](https://github.com/rokwire/illinois-app/issues/2606).
### Fixed
- Remove ModalImageDialog from Video widgets[#2608](https://github.com/rokwire/illinois-app/issues/2608).
### Changed
- Display Profile, Notifications and Settings panels as modal bottom sheet [#2607](https://github.com/rokwire/illinois-app/issues/2607).
- Update My Research Participation empty message depending on user privilege [#2588](https://github.com/rokwire/illinois-app/issues/2588).

## [4.2.30] - 2022-11-30
### Changed
- Show video in favorites welcome widget [#2590](https://github.com/rokwire/illinois-app/issues/2590).
- Update delete account message [#2593](https://github.com/rokwire/illinois-app/issues/2593).
- Show online details url in Appointment Detail Panel [#2592](https://github.com/rokwire/illinois-app/issues/2592).
- Show relevant tout image in Appointment Detail Panel [#2596](https://github.com/rokwire/illinois-app/issues/2596).
- Always show "Recent Past Appointments" label [#2600](https://github.com/rokwire/illinois-app/issues/2600).
### Added
- Add appointments settings [#2598](https://github.com/rokwire/illinois-app/issues/2598).
- Added MTD in Home & Browse panel, created MTDStopsHonePanel. In progress. [#2516](https://github.com/rokwire/illinois-app/issues/2516).

## [4.2.29] - 2022-11-29
### Added
- Added "MTD Bus" category in Map [#2516](https://github.com/rokwire/illinois-app/issues/2516).
- Add new video "Favorites Tutorial" [#2581] (https://github.com/rokwire/illinois-app/issues/2581).
### Changed
- Remember last selected category in Map [#2583](https://github.com/rokwire/illinois-app/issues/2583).

## [4.2.28] - 2022-11-28
### Fixed
- Do not send iCard analytics data when processing logout [#2519](https://github.com/rokwire/illinois-app/issues/2519).
- Group members search buttons request focus [#2561](https://github.com/rokwire/illinois-app/issues/2561).

## [4.2.27] - 2022-11-25
### Added
- Implement "Mark all as read" [#2570](https://github.com/rokwire/illinois-app/issues/2570).
- Add Delete group button in Settings panel [#2572](https://github.com/rokwire/illinois-app/issues/2572).

## [4.2.26] - 2022-11-24
### Changed
- Group Notification Settings panel: update styling [#2538](https://github.com/rokwire/illinois-app/issues/2538).
### Added
- Android: implement map POIs appearance to be like in iOS [#2554](https://github.com/rokwire/illinois-app/issues/2554).
### Fixed
- Show proper error message when WPGU radio failed to initialize [#2568](https://github.com/rokwire/illinois-app/issues/2568).

## [4.2.25] - 2022-11-23
### Changed
- Research Project updates [#2563](https://github.com/rokwire/illinois-app/issues/2563).

## [4.2.24] - 2022-11-22
### Changed
- The default in research groups for the consent checkbox in researh projects should be true [#2550](https://github.com/rokwire/illinois-app/issues/2550).
- Group auto join checkbox available for all groups (except research) [#2558](https://github.com/rokwire/illinois-app/issues/2558).
### Fixed
- Fixed language assets JSON [#2552](https://github.com/rokwire/illinois-app/issues/2552).
- RoleGridButton: set min height for Icon and Title [#2555](https://github.com/rokwire/illinois-app/issues/2555).

## [4.2.23] - 2022-11-21
### Changed
- UI updates in "Customize" view of Favorites panel [#2546](https://github.com/rokwire/illinois-app/issues/2546).
- Updated User Roles panel [#2547](https://github.com/rokwire/illinois-app/issues/2547).

## [4.2.22] - 2022-11-18
### Changed
- Research Project updates [#2544](https://github.com/rokwire/illinois-app/issues/2544).
- Load research questionnaire from content service.

## [4.2.21] - 2022-11-17
### Changed
- Research Project updates [#2540](https://github.com/rokwire/illinois-app/issues/2540).
- Check card's expiration date [#2542](https://github.com/rokwire/illinois-app/issues/2542).

## [4.2.20] - 2022-11-16
### Changed
- Research Project updates [#2533](https://github.com/rokwire/illinois-app/issues/2533).
- Make the MTD route lines thicker [#2536](https://github.com/rokwire/illinois-app/issues/2536).

###Added
- Show global group notification setting in Group by Group panel [#2538](https://github.com/rokwire/illinois-app/issues/2538).

## [4.2.19] - 2022-11-15
### Added
- Initialize research confirmation flag in Group Create/Settings panels, require user consent before requesting to join research project that requires confirmation [#2531](https://github.com/rokwire/illinois-app/issues/2531).

## [4.2.18] - 2022-11-14
### Added
- Implement "Group by Group notifications" - override member's default notification preferences per group [#2525](https://github.com/rokwire/illinois-app/issues/2525).
### Changed
- Research Project updates [#2526](https://github.com/rokwire/illinois-app/issues/2526).

## [4.2.17] - 2022-11-11
### Fixed
- Fixed tap handling on bus markers [#2516](https://github.com/rokwire/illinois-app/issues/2516).
- Implemented bus schedule times panel [#2516](https://github.com/rokwire/illinois-app/issues/2516).
- Implemented appointments semantics [#2520](https://github.com/rokwire/illinois-app/issues/2520).

## [4.2.16] - 2022-11-09
### Added
- Created initial MTD handling in Maps [#2516](https://github.com/rokwire/illinois-app/issues/2516).

## [4.2.15] - 2022-11-07
## Added
- Handle plugin local notifications [#2506](https://github.com/rokwire/illinois-app/issues/2506).
- Updated display strings for research projects in GroupDetailPanel [#2473](https://github.com/rokwire/illinois-app/issues/2473).
- Hook Appointments API (in progress) [#2511](https://github.com/rokwire/illinois-app/issues/2511).
### Changed
- Do not show / apply filters for My Research Projects content [#2473](https://github.com/rokwire/illinois-app/issues/2473).
- Do not filter all groups content "manually" in Groups home panel [#2473](https://github.com/rokwire/illinois-app/issues/2473).

## [4.2.14] - 2022-11-04
### Changed
- Campus View Maps updates [#2503](https://github.com/rokwire/illinois-app/issues/2503).

## [4.2.13] - 2022-11-03
### Changed
- Research UI updates [#2499](https://github.com/rokwire/illinois-app/issues/2499).
- Profile Image enhancements [#2501](https://github.com/rokwire/illinois-app/issues/2501).

## [4.2.12] - 2022-11-02
### Fixed
- Fixed analytics logs from Settings panels [#2492](https://github.com/rokwire/illinois-app/issues/2492).
### Changed
- Updated Questionnaire onboarding panels UI [#2495](https://github.com/rokwire/illinois-app/issues/2495).
- Updated marksers processing in iOS Maps [#2448](https://github.com/rokwire/illinois-app/issues/2448).
### Added
- Initial work on Research Projects [#2473](https://github.com/rokwire/illinois-app/issues/2473).

## [4.2.11] - 2022-10-31
### Added
- Add health screener surveys [#2480](https://github.com/rokwire/illinois-app/issues/2480).
- Introduce ModalImageHolder widget  [#2474](https://github.com/rokwire/illinois-app/issues/2474)
### Changed
- "Campus Guide Highlights" renamed to "Campus Safety Resources" [#2488](https://github.com/rokwire/illinois-app/issues/2488).

## [4.2.10] - 2022-10-28
### Added
- Prelimiary work on Research Projects [#2473](https://github.com/rokwire/illinois-app/issues/2473).
### Changed
- Text, layout and navigation updates for Research Questionnaire [#2484](https://github.com/rokwire/illinois-app/issues/2484).

## [4.2.9] - 2022-10-27
### Changed
- Store research questionnaire answers in account profile [#2477](https://github.com/rokwire/illinois-app/issues/2477).
### Added
- Show Appointments in Browse and Favorites. Read appointments default url and phone from app config [#2464](https://github.com/rokwire/illinois-app/issues/2464).

## [4.2.8] - 2022-10-26
### Changed
- HomeMyGroupsWidget renamed to HomeGroupsWidget.
- Make group images expandable [#2474](https://github.com/rokwire/illinois-app/issues/2474).
### Added
- Introduce the UI for "muted" and "unread" notifications [#2472](https://github.com/rokwire/illinois-app/issues/2472).
- Store appointment in device calendar [#2464](https://github.com/rokwire/illinois-app/issues/2464).

## [4.2.7] - 2022-10-21
### Changed
- Minor updates in Research Questinnaire content [#2465](https://github.com/rokwire/illinois-app/issues/2465).
### Added
- Intermediate work on Appointments UI [#2464](https://github.com/rokwire/illinois-app/issues/2464).

## [4.2.6] - 2022-10-20
### Added
- Intermediate work on Appointments UI [#2464](https://github.com/rokwire/illinois-app/issues/2464).
### Changed
- Demographics Questionnaire renamed to Research, various UX updates applied [#2465](https://github.com/rokwire/illinois-app/issues/2465).

## [4.2.5] - 2022-10-19
### Added
- Added Demographics Questionnaire to Onboarding and Profile [#2465](https://github.com/rokwire/illinois-app/issues/2465).

## [4.2.4] - 2022-10-17
### Changed
- Sort group post replies descending by date [#2462](https://github.com/rokwire/illinois-app/issues/2462).

## [4.2.3] - 2022-10-14
### Added
- Show play button in video tutorials favourite widget [#2458](https://github.com/rokwire/illinois-app/issues/2458).
### Fixed
- Fixed member entry duplication in GroupMembersPanel [#2413](https://github.com/rokwire/illinois-app/issues/2413).

## [4.2.2] - 2022-10-13
### Fixed
- Android: improper marker view [#2453](https://github.com/rokwire/illinois-app/issues/2453).
### Added
- Show thumbnail in favourite widget for video tutorials [#2455](https://github.com/rokwire/illinois-app/issues/2455).

## [4.2.1] - 2022-10-12
### Changed
- Upgrade project to build with flutter 3.3.2 [#2410](https://github.com/rokwire/illinois-app/issues/2410).
- Move unused assets in "extra" subfolder, do not embed them in application bundle [#2353](https://github.com/rokwire/illinois-app/issues/2353).
- Updated NSCameraUsageDescription, NSPhotoLibraryUsageDescription and NSPhotoLibraryAddUsageDescription in Info.plist file [#2427](https://github.com/rokwire/illinois-app/issues/2427).
- Applied preliminary work on multiple brands support [#2353](https://github.com/rokwire/illinois-app/issues/2353).
- Android: update dependencies to their latest possible versions [#2437](https://github.com/rokwire/illinois-app/issues/2437).
- Allow links with nullable urls in Campus Guides [#2441](https://github.com/rokwire/illinois-app/issues/2441).
- Allow opening urls in internal web panel for Campus Guides [#2443](https://github.com/rokwire/illinois-app/issues/2443).
- Removed hardcoded deep link URL schemes [#2353](https://github.com/rokwire/illinois-app/issues/2353).
### Fixed
- Fixed GoogleServices.json ifor iOS targets [#2353](https://github.com/rokwire/illinois-app/issues/2353).
### Added
- Handle notifications permission for Android 13 (API level 33) [#2446](https://github.com/rokwire/illinois-app/issues/2446).
- Added Campus View on Maps [#2448](https://github.com/rokwire/illinois-app/issues/2448).
- Favourite widget for video tutorials [#2451](https://github.com/rokwire/illinois-app/issues/2451).

## [4.2.0] - 2022-09-23
### Changed
- Optimized Groups /user/login API call [#2316](https://github.com/rokwire/illinois-app/issues/2316).
- Improved scheduling of app review prompt [#2321](https://github.com/rokwire/illinois-app/issues/2321).
- Removed direct privacy level checks from app code, use FlexUI features instead [#2325](https://github.com/rokwire/illinois-app/issues/2325).
- TextStyles exposed to Assets/styles.json (in progress) [#2311](https://github.com/rokwire/illinois-app/issues/2311).
- Android: upgrade compileSdkVersion and targetSdkVersion [#2308](https://github.com/rokwire/illinois-app/issues/2308).
### Added
- Do not show Uin and Email in the members list if the group is public [#2414](https://github.com/rokwire/illinois-app/issues/2414).

## [4.1.36] - 2022-09-30
### Added
- Allow only managed group admin to create and update managed groups [#2429](https://github.com/rokwire/illinois-app/issues/2429).

## [4.1.35] - 2022-09-28
### Fixed
- Fixed "illegible" spell error [#2378](https://github.com/rokwire/illinois-app/issues/2378).
### Changed
- Do not show UIN and Email in group members list when the group is public [#2421](https://github.com/rokwire/illinois-app/issues/2421).
- Show hidden groups only for admins - hide for all others [#2423](https://github.com/rokwire/illinois-app/issues/2423).

## [4.1.34] - 2022-09-19
### Fixed
- Fixed Notifications handling for AppReview service [#2380](https://github.com/rokwire/illinois-app/issues/2380).

## [4.1.33] - 2022-09-16
### Fixed
- Reload Wellness ToDo items when category is changed or deleted [#2401](https://github.com/rokwire/illinois-app/issues/2401).
- Fix Gies checklist group request [#2403](https://github.com/rokwire/illinois-app/issues/2403).

## [4.1.32] - 2022-09-15
### Changed
- "Custom" group post template to "None" [#2396](https://github.com/rokwire/illinois-app/issues/2396).
### Fixed
- Try to prevent black screen after onboarding (Revert improving AppReview after onboarding) [#2395](https://github.com/rokwire/illinois-app/issues/2395).

## [4.1.31] - 2022-09-14
### Added
- Display when member had attended if the group is attendance group [#2392](https://github.com/rokwire/illinois-app/issues/2392).

## [4.1.30] - 2022-09-13
### Added
- Add reactions to group posts [#2354](https://github.com/rokwire/illinois-app/issues/2354).
### Fixed
- Compound widget style for favorites [#2373](https://github.com/rokwire/illinois-app/issues/2373).
- Fix Semantics for Wellness drop down button [#2327](https://github.com/rokwire/illinois-app/issues/2327).
- Show pending members by default if exist [#2289](https://github.com/rokwire/illinois-app/issues/2289).
- Fix Group Reply Card issues [#2374](https://github.com/rokwire/illinois-app/issues/2374).

## [4.1.29] - 2022-09-12
### Fixed
- Missing my groups in the home widget [#2254](https://github.com/rokwire/illinois-app/issues/2254).

## [4.1.28] - 2022-09-09
### Changed
- Texts in Promote Group [#2372](https://github.com/rokwire/illinois-app/issues/2372).
- Display account status in case the user is not eligible for Illini Cash / Meal Plan [#2378](https://github.com/rokwire/illinois-app/issues/2378).
- Improved AppReview session timeout handling [#2380](https://github.com/rokwire/illinois-app/issues/2380).
### Fixed
- Set Identity min level to 4 in Privacy -> Wallet [#2331](https://github.com/rokwire/illinois-app/issues/2331).
- Fixed AppReview processing after onboarding [#2380](https://github.com/rokwire/illinois-app/issues/2380).
- Reload user groups when service notification is received [#2329](https://github.com/rokwire/illinois-app/issues/2329).

## [4.1.27] - 2022-09-08
### Added
- Improve manual nudge interaction to include polls [#2365](https://github.com/rokwire/illinois-app/issues/2365).
### Removed
- Removed external link icon from Due Date Catalog in Academics panel [#2356](https://github.com/rokwire/illinois-app/issues/2356).
### Changed
- Groups panel navigation [#2368](https://github.com/rokwire/illinois-app/issues/2368).

## [4.1.26] - 2022-09-07
### Added
- Wellness overview tutorial video [#2357](https://github.com/rokwire/illinois-app/issues/2357).
- Allow sharing group qr code value [#2362](https://github.com/rokwire/illinois-app/issues/2362).
### Removed
- Allow admins to add members to group [#2359](https://github.com/rokwire/illinois-app/issues/2359).
### Changed
- Improved scheduling of app review prompt [#2321](https://github.com/rokwire/illinois-app/issues/2321).

## [4.1.25] - 2022-09-02
### Fixed
- Crash in Android [#2341](https://github.com/rokwire/illinois-app/issues/2341).
- Fixed handling taps on GroupEventCard [#2328](https://github.com/rokwire/illinois-app/issues/2328).
- Fixed add Illini Cash when the user is not logged in [#2324](https://github.com/rokwire/illinois-app/issues/2324).
### Added
- Redirect to GroupPostDetailPanel when group post notification is received [#2344](https://github.com/rokwire/illinois-app/issues/2344).
- Show bigger image in an alert dialog when image is tapped [#2347](https://github.com/rokwire/illinois-app/issues/2347).
- Group post send to multiple groups  [#2343](https://github.com/rokwire/illinois-app/issues/2343).

## [4.1.24] - 2022-09-01
### Added
- New tutorial videos [#2334](https://github.com/rokwire/illinois-app/issues/2334).
- Implemented Student Courses content overriding from Debug [#2336](https://github.com/rokwire/illinois-app/issues/2336).
- Allow group admins to add new members [#2337](https://github.com/rokwire/illinois-app/issues/2337).
### Changed
- Launch all non-internal URLs from Wellness Resources in external browser [#2333](https://github.com/rokwire/illinois-app/issues/2333).

## [4.1.23] - 2022-08-31
### Changed
- Remove IndoorMaps from Map Navigation Directions [#2306](https://github.com/rokwire/illinois-app/issues/2306).

## [4.1.22] - 2022-08-25
- Removed any references to PassKit.framework [#1851](https://github.com/rokwire/illinois-app/issues/1851).
### Fixed
- Fixed am/pm indicator evaluation in StudentCourseSecrtion [#2310](https://github.com/rokwire/illinois-app/issues/2310).
- Fixed opening tel and mail protocol links from Student Guide pages [#2315](https://github.com/rokwire/illinois-app/issues/2315).

## [4.2.0] - 2022-08-18
### Fixed
- Move "getContentString" method to Localization service [#2291](https://github.com/rokwire/illinois-app/issues/2291).
### Added
- Cache Canvas Courses [#2294](https://github.com/rokwire/illinois-app/issues/2294).
- Added courses caching in Student Courses service [#2303](https://github.com/rokwire/illinois-app/issues/2303).

## [4.1.21] - 2022-08-17
### Changed
- The text for logged out messages [#2290](https://github.com/rokwire/illinois-app/issues/2290).
- Messages when there are no group members [#2299](https://github.com/rokwire/illinois-app/issues/2299).
- Removed MapsIndoors from Map Widget and launchMap native handler [#2298](https://github.com/rokwire/illinois-app/issues/2298).

## [4.1.20] - 2022-08-15
### Changed
- Version number for resubmission [#2295](https://github.com/rokwire/illinois-app/issues/2295).

## [4.1.19] - 2022-08-15
### Changed
- Updated My Courses load fail message [#2277](https://github.com/rokwire/illinois-app/issues/2277).
- Updated Favorites: App Help / Submit Review entry description [#2279](https://github.com/rokwire/illinois-app/issues/2279).
- Make "My Courses" availble only for the users with "student" role selected [#2281](https://github.com/rokwire/illinois-app/issues/2281).

## [4.1.18] - 2022-08-15
### Fixed
- Member count is only displayed for some groups [#2250](https://github.com/rokwire/illinois-app/issues/2250).
- Android: set the proper text for snippet view in mapview markers. Show/hide snippet view based on the zoom level [#2268](https://github.com/rokwire/illinois-app/issues/2268).
- Fixed MTD Bus Pass availability for target group members [#2273](https://github.com/rokwire/illinois-app/issues/2273).
### Added
- "Due Date Catalog" to Academics panel drop-down [#2260](https://github.com/rokwire/illinois-app/issues/2260).
- Bring back FAQs entry in App Help [#2267](https://github.com/rokwire/illinois-app/issues/2267).
- Implemented StudentCourseDetailPanel [#2262](https://github.com/rokwire/illinois-app/issues/2262).
### Changed
- Default Daily Illini image placeholder [#2264](https://github.com/rokwire/illinois-app/issues/2264).
- Show building name and room in map popup [#2263](https://github.com/rokwire/illinois-app/issues/2263)

## [4.1.17] - 2022-08-12
### Added
- Placeholder when there is no image for Daily Illini item [#2241](https://github.com/rokwire/illinois-app/issues/2241).
### Fixed
- Fixed initial camera update when displaying single marker, fixed explore location retrieval in iOS [#2216](https://github.com/rokwire/illinois-app/issues/2216).
### Changed
- Updates for Video Tutorials [#2243](https://github.com/rokwire/illinois-app/issues/2243).
- Do not init default favorites order on pull to refresh in Favorites / Customize in production releasr builds [#2245](https://github.com/rokwire/illinois-app/issues/2245).
- Link group event to other groups when created only if members_selection is empty [#2232](https://github.com/rokwire/illinois-app/issues/2232).
- Updated ADA setting wording in Profile panel [#2240](https://github.com/rokwire/illinois-app/issues/2240).

## [4.1.16] - 2022-08-11
### Changed
- Do not show zero lat/long coordinates on maps [#2218](https://github.com/rokwire/illinois-app/issues/2218).
- Provide user friendly description of Notification section in Browse panel [#1972](https://github.com/rokwire/illinois-app/issues/1972).
- Event List event type dropdown updates [#2226](https://github.com/rokwire/illinois-app/issues/2226).
- Settings panel's title changed to just "Settings" [#2202](https://github.com/rokwire/illinois-app/issues/2202).
### Added
- Added Due Date Catalog to Academics section [#2220](https://github.com/rokwire/illinois-app/issues/2220).
- Added ability to delete polls in PollsHomePanel [#2153](https://github.com/rokwire/illinois-app/issues/2153).
- Daily Illini feed with images [#2208](https://github.com/rokwire/illinois-app/issues/2208).
- Handle more than one video tutorials - defined in app assets [#2230](https://github.com/rokwire/illinois-app/issues/2230).
### Deleted
- Removed Athletics/Teams entry in Browse panel [#2102](https://github.com/rokwire/illinois-app/issues/2102).
### Fixed
- Fixed GroupDetailPanel when initialized with groupIdentifier [#2223](https://github.com/rokwire/illinois-app/issues/2223).
- Fixed Add Illini Cash availability when the user is not logged in [#2175](https://github.com/rokwire/illinois-app/issues/2175).
- Make sure to handle all entries from Browse panel [#2112](https://github.com/rokwire/illinois-app/issues/2112).
- Fixed dropdown height of Settings content selector [#2174](https://github.com/rokwire/illinois-app/issues/2174).

## [4.1.15] - 2022-08-10
### Changed
- Apply empty set of POIs when nothing has loaded in ExplorePanel / Map view [#2203](https://github.com/rokwire/illinois-app/issues/2203).
- Do not show map levels by default [#2205](https://github.com/rokwire/illinois-app/issues/2205).
- Do not prompt the same user for review requests on multiple devices [#2207](https://github.com/rokwire/illinois-app/issues/2207).
- Hide canvas_courses and student_courses if user is not logged in [#2210](https://github.com/rokwire/illinois-app/issues/2210).
- Enable "student_courses" in FlexUI from app config [#2210](https://github.com/rokwire/illinois-app/issues/2210).
### Added
- Introduce HomeDailyIlliniWidget - display illini feed (Task in progress). [#2208](https://github.com/rokwire/illinois-app/issues/2208).
- Added COVID-19 section to wellness resources. [#2179](https://github.com/rokwire/illinois-app/issues/2179).

## [4.1.14] - 2022-08-09
### Changed
- Acknowledged "analytics_processed_date" flag from user account for app review requests [#2190](https://github.com/rokwire/illinois-app/issues/2190).
- Updated Student Course display data format [#2192](https://github.com/rokwire/illinois-app/issues/2192)
- Guides open links in external browser  [#2155](https://github.com/rokwire/illinois-app/issues/2155).
- Do not load groups on portions (paging) [#2150](https://github.com/rokwire/illinois-app/issues/2150).
- Remove reference to "Building Access" in "Connect to Illinois" widget. [#2168](https://github.com/rokwire/illinois-app/issues/2168).
- Remove word "Card" from expiration on Illini ID and bus pass [#2181](https://github.com/rokwire/illinois-app/issues/2181).
- Acknowledged user locaton and ADA setting when requesting student courses. Build directions route to the firstentrance when navigating to student course. [#2194](https://github.com/rokwire/illinois-app/issues/2194).
- Editing events with long title and description [#657](https://github.com/rokwire/illinois-app/issues/657).
### Added
- Drop down in members panel for filtering by member status [#2150](https://github.com/rokwire/illinois-app/issues/2150).
### Fixed 
- Fixed Create Event for multiple groups duplicates the event [#2232](https://github.com/rokwire/illinois-app/issues/2232).

## [4.1.13] - 2022-08-08
### Changed
- Course renamed to StudentCourse [#2169](https://github.com/rokwire/illinois-app/issues/2169).
- Format Student course schedule time [#2183](https://github.com/rokwire/illinois-app/issues/2183).
### Added
- Added My Courses and My Gies Canvas Courses to My section in Browse panel [#2185](https://github.com/rokwire/illinois-app/issues/2185).
- Load groups and members on portions (paging) - task in progress [#2150](https://github.com/rokwire/illinois-app/issues/2150).
- My Courses added to Map Panel [#2169](https://github.com/rokwire/illinois-app/issues/2169).

## [4.1.12] - 2022-08-05
### Fixed
- Fixed termid parameter to 'studentcourses' API call [#2169](https://github.com/rokwire/illinois-app/issues/2169).

## [4.1.11] - 2022-08-05
### Added
- Created My Courses content in Academics / Browse / Favorites panels [#2169](https://github.com/rokwire/illinois-app/issues/2169).
### Changed
- Updated Create poll panel to accept 6 options and 250 question limit [#1591](https://github.com/rokwire/illinois-app/issues/1591).

## [4.1.10] - 2022-08-04
### Added
- Display year in event date time if the start year is different than the end year [#2170](https://github.com/rokwire/illinois-app/issues/2170).

## [4.1.9] - 2022-08-03
### Changed
- Show events that last more than one day in "Multiple Events" [#2158](https://github.com/rokwire/illinois-app/issues/2158).
- Updated "No MTD Buss Pass" text [#2160](https://github.com/rokwire/illinois-app/issues/2160).
### Added
- Added app rating & review support [#2162](https://github.com/rokwire/illinois-app/issues/2162).

## [4.1.8] - 2022-08-02
### Fixed
- Fix 2FA issue with MyMcKinley. Open in external browser [#2148](https://github.com/rokwire/illinois-app/issues/2148).
- Fixed Notifications favorite icon [#1972](https://github.com/rokwire/illinois-app/issues/1972).
### Added
- Created Recent Notifications home widget and Notifications section in Browse panel [#1972](https://github.com/rokwire/illinois-app/issues/1972).
- Introduce Gies checklist custom widget: student_courses_list [#2152](https://github.com/rokwire/illinois-app/issues/2152).

## [4.1.7] - 2022-08-01
### Changed
- Show multiple (composite) events as single event (super event) with horizontal scroll of sub events [#2140](https://github.com/rokwire/illinois-app/issues/2140).
- Texts for App Feedback in Settings [#1933](https://github.com/rokwire/illinois-app/issues/1933).
- Show logo and right status text in MTD Bus Pass panel only if the user is member of "MTD Bus Pass" group [#2143].
### Added
- Add Semantics label for Onboarding2ViedeoTutorialPanel. Used as accessibility id.[#1660](https://github.com/rokwire/illinois-app/issues/1660).
### Fixed 
- WellnessRingCreatePanel fixed goal input validation. [#2163](https://github.com/rokwire/illinois-app/issues/2163).
## [4.1.6] - 2022-07-29
### Added
- In-App Review test in DebugHomePanel [#2131](https://github.com/rokwire/illinois-app/issues/2131).
### Changed
- Updated "To-Do List" and "Daily Tip" entries from "Wellness" section in Browse panel [#2107](https://github.com/rokwire/illinois-app/issues/2107).
### Added
- Fixed audio playback when video tutorial is skipped [#2136](https://github.com/rokwire/illinois-app/issues/2136).

## [4.1.5] - 2022-07-28
### Added
- Display types "All", "Multiple" and "Single" for events [#2124](https://github.com/rokwire/illinois-app/issues/2124).
### Changed
- Updated some section descriptions in Browse panel [#2126](https://github.com/rokwire/illinois-app/issues/2126).
### Removed
- Removed "Wellness Resources" header from wellness resources content widget [#2128](https://github.com/rokwire/illinois-app/issues/2128).
- ### Fixed
- Fix Horizontal scrolling is not accessible [#2093](https://github.com/rokwire/illinois-app/issues/2093).

## [4.1.4] - 2022-07-27
### Removed
- Label "Online / Offline" from Laundry [#2094](https://github.com/rokwire/illinois-app/issues/2094).
- External link icon from "I'm Struglling" in Wellness [#2099](https://github.com/rokwire/illinois-app/issues/2099).
- Athletics Teams widget from Favorites panel [#2102](https://github.com/rokwire/illinois-app/issues/2102).
- Campus Guide widget from Favorites panel [#2104](https://github.com/rokwire/illinois-app/issues/2104).
- "Building Access" references in privacy settings [#2082](https://github.com/rokwire/illinois-app/issues/2082).
### Added
- Info icon that shows descriptive message in Wellness ToDo list calendar [#2096](https://github.com/rokwire/illinois-app/issues/2096).
- Add a "MyMcKinley Patient Health Portal" link to “Wellness Resources” [#2098](https://github.com/rokwire/illinois-app/issues/2098).
- Add link to Wellness Resources Home when favorites widget is empty [#2098](https://github.com/rokwire/illinois-app/issues/2098).
- Add the external website icon to "other selected services" link in Illini Cash [#2113](https://github.com/rokwire/illinois-app/issues/2113).
- Add “My Favorites” to Settings dropdown options [#2118](https://github.com/rokwire/illinois-app/issues/2118).
### Changed
- Make Wellness widget components stand alone [#2107](https://github.com/rokwire/illinois-app/issues/2107).
- Duplicate entries from My section to their logical sections in Browse panel [#2112](https://github.com/rokwire/illinois-app/issues/2112).
- Texts in HomePanel [#1905](https://github.com/rokwire/illinois-app/issues/1905).
- Texts for Residence Hall Dining [#1948](https://github.com/rokwire/illinois-app/issues/1948).
- "ID Card" to "Illini ID" in Browse [#2120](https://github.com/rokwire/illinois-app/issues/2120).
### Fixed
- Fix Horizontal scrolling is not accessible [#2093](https://github.com/rokwire/illinois-app/issues/2093).

## [4.1.3] - 2022-07-26
### Changed
- Rename "Reminders" tab to "Weekly" in Wellness ToDo list [#1967](https://github.com/rokwire/illinois-app/issues/1967).
- Icon for editing todo categories in Wellness [#1969](https://github.com/rokwire/illinois-app/issues/1969).
- Add times to options in Wellness ToDo reminder drop-down [#1974](https://github.com/rokwire/illinois-app/issues/1974).
- Redirect user to edit wellness todo item when tapping on calendar item with reminder [#1976](https://github.com/rokwire/illinois-app/issues/1976).
- Acknowledged new parameters of 'report/abuse' API of Groups BB [#2083](https://github.com/rokwire/illinois-app/issues/2083).
- Improve Semantics for WellnessRings widgets [#2023](https://github.com/rokwire/illinois-app/issues/2023).
- Improve Semantics for 8 dimensions of wellness diagram widgets [#2027](https://github.com/rokwire/illinois-app/issues/2027).

## [4.1.2] - 2022-07-25
### Added
- Added Report to Group Administrators option in Group post panel [#2083](https://github.com/rokwire/illinois-app/issues/2083).

## [4.1.1] - 2022-07-21
### Fixed
- Show popups in Wellness ToDo and Rings just once [#2071](https://github.com/rokwire/illinois-app/issues/2071).
- Fix blue color in Wellness ToDo categories [#2040](https://github.com/rokwire/illinois-app/issues/2040).
### Changed
- Create default order of Favorites panel widgets from extended FlexUI content [#2076](https://github.com/rokwire/illinois-app/issues/2076).

## [4.1.0] - 2022-07-20
### Changed
- Do not override default TabBar background color any more [#2067](https://github.com/rokwire/illinois-app/issues/2067).
- Read group names from app config in FlexUI [#118](https://github.com/rokwire/illinois-app/issues/118).
### Fixed
- Construct redirect url with deep link target for group promotion [#2065](https://github.com/rokwire/illinois-app/issues/2065).
- Fixed adding/removing compound widgets from Favorites/Customize panel [#2073](https://github.com/rokwire/illinois-app/issues/2073).
- Fixed Semantics for WellnessToDo checkbox [#2044](https://github.com/rokwire/illinois-app/issues/2044).
### Added
- Handle LMS push notifications with deep links to Canvas app [#2066](https://github.com/rokwire/illinois-app/issues/2066).

## [4.0.55] - 2022-07-19
### Removed
- Removed OnCampus section from Calendar settings [#2045](https://github.com/rokwire/illinois-app/issues/2045).
### Added
- Added default attributes from student classification to Analytics events [#2047](https://github.com/rokwire/illinois-app/issues/2047).
- Added Analytics events to the new content [#2052](https://github.com/rokwire/illinois-app/issues/2052).
- Implement pull-to-refresh with authman sync in GroupMembersPanel. Check if this is available in the config [#2059](https://github.com/rokwire/illinois-app/issues/2059).
- Add create ring button to HomeWellnessRingWidget [#2026](https://github.com/rokwire/illinois-app/issues/2026).
- Added Analytics log for home panel favorite updates [#2058](https://github.com/rokwire/illinois-app/issues/2058).
### Changed
- Label to "My Gies Canvas Courses" [#2048](https://github.com/rokwire/illinois-app/issues/2048).
- Update wording in group privacy sentence [#2041](https://github.com/rokwire/illinois-app/issues/2041).
- Update wording in Notifications HomeFavoritesWidget [#2022](https://github.com/rokwire/illinois-app/issues/2022).
- Optimized content update in HomeFavoriteWidget.
### Fixed
- Fixed WellnessRings refresh issues [#2055](https://github.com/rokwire/illinois-app/issues/2055).

## [4.0.54] - 2022-07-18
### Added
- Added On Campus settings in Personal Info child widget [#2027](https://github.com/rokwire/illinois-app/issues/2027).
- Check Post Nudges for list of group names or group name with wild card [#2032](https://github.com/rokwire/illinois-app/issues/2032).
### Removed
- Special handling for "cost" field in Student Guide. It is now part of the "links" section [#2029](https://github.com/rokwire/illinois-app/issues/2029).
### Fixed
- Create Polls strings updates [#1713](https://github.com/rokwire/illinois-app/issues/1713).
- Fixed content update in page view in home widgets [#2020](https://github.com/rokwire/illinois-app/issues/2020).
### Changed
- HomeTweeterWidget: move navigation buttons below main Image [#1455](https://github.com/rokwire/illinois-app/issues/1455).
- Remove custom color and add a new one in Wellness ToDo [#2036](https://github.com/rokwire/illinois-app/issues/2036).

## [4.0.53] - 2022-07-15
### Changed
- Display hidden status in Group card, cleaned up header layout [#2013](https://github.com/rokwire/illinois-app/issues/2013).
- Allow delete option in Group polls [#1954](https://github.com/rokwire/illinois-app/issues/1954).
### Fixed
- Fixed and cleaned up Select Group popup from Create Event Panel [#1952](https://github.com/rokwire/illinois-app/issues/1952).
### Added
- Access ExploreSearchPanel from ExploreHomePanel [#1885](https://github.com/rokwire/illinois-app/issues/1885).
- Implement hybrid events [#2018](https://github.com/rokwire/illinois-app/issues/2018)

## [4.0.52] - 2022-07-14
### Changed
- Update Canvas Error text [#2002](https://github.com/rokwire/illinois-app/issues/2002).
- Update CheckList scrolling [#2001](https://github.com/rokwire/illinois-app/issues/2001).
- Allow navigation to relevant home panel from HomeFavroitesWidget and SavedPanel [#1896](https://github.com/rokwire/illinois-app/issues/1896).
- Change link color in _InfoDialog from HomeToutWidget to white [#1973](https://github.com/rokwire/illinois-app/issues/1973).
### Fixed
- Fixed "Prompt when saving events to calendar" enable [#1980](https://github.com/rokwire/illinois-app/issues/1980).

## [4.0.51] - 2022-07-13
### Changed
- Show Laundry only to students in residence [#1984](https://github.com/rokwire/illinois-app/issues/1984).
- Remove "My Illini" from the Browse screen [#1903](https://github.com/rokwire/illinois-app/issues/1903).
- Updated Wellness Resources links [#1887](https://github.com/rokwire/illinois-app/issues/1887).
### Fixed
- Apply authorization header to StudentSummary API call [#1895](https://github.com/rokwire/illinois-app/issues/1895).
- CreatePollPanel: show members selection only for group polls [#1945](https://github.com/rokwire/illinois-app/issues/1945).
- CreateGroup dialog text change [#1949](https://github.com/rokwire/illinois-app/issues/1949).
- Do not display explore location with missing latitude or longitude in iOS Map View [#1942](https://github.com/rokwire/illinois-app/issues/1942).
### Added
- Added favorite button in AthleticsNewsArticlePanel [#1990](https://github.com/rokwire/illinois-app/issues/1990).

## [4.0.50] - 2022-07-12
### Added
- Handled "viewPoi" command in iOS MapView [#1699](https://github.com/rokwire/illinois-app/issues/1699).
- Handled Laundry in Favorites and Browse panels [#1916](https://github.com/rokwire/illinois-app/issues/1916).
### Changed
- Updated strings for phone / email sign up [#1931](https://github.com/rokwire/illinois-app/issues/1931).
- Multiple updates for Laundry favorite / detail UI [#1916](https://github.com/rokwire/illinois-app/issues/1916).
- Updated some wellness resource URLs [#1888](https://github.com/rokwire/illinois-app/issues/1888).
- Wellness Rings updates [#1692](https://github.com/rokwire/illinois-app/issues/1692).
### Fixed
- Do not apply any logic whether to show laundry favorites in Saved panel [#1917](https://github.com/rokwire/illinois-app/issues/1917).
- Set keys to all Home panel widgets so that their content does not get mixed [#1961](https://github.com/rokwire/illinois-app/issues/1961).

## [4.0.49] - 2022-07-11
### Changed
- Updated description texy in HomeAthliticsTeamsWidget [#1936](https://github.com/rokwire/illinois-app/issues/1936).
### Fixed
- Fixed content updating of Wallet favorite widget [#1935](https://github.com/rokwire/illinois-app/issues/1935).
- Fixed navigation after phone confirmation panel [#1931](https://github.com/rokwire/illinois-app/issues/1931).
- Fixed some Android launch images [#1928](https://github.com/rokwire/illinois-app/issues/1928).

## [4.0.48] - 2022-07-08
### Changed
- Acknowledge the new APIs from LMS BB [#1927](https://github.com/rokwire/illinois-app/issues/1927).

## [4.0.47] - 2022-07-08
### Changed
- Hide Create Stadium Poll [#1918](https://github.com/rokwire/illinois-app/issues/1918).
- Text changes in Favorite & Browse panels, string transaltions [#1920](https://github.com/rokwire/illinois-app/issues/1920).
- Rework Athletics Teams widget from Favorites panel [#1922](https://github.com/rokwire/illinois-app/issues/1922).
### Fixed
- Various fixes in the UI [#1910](https://github.com/rokwire/illinois-app/issues/1910).

## [4.0.46] - 2022-07-07
### Changed
- Replace Lorem Ipsum strings for Dinings and Groups sections in Browse panel [#1906](https://github.com/rokwire/illinois-app/issues/1906).
- Make Suggested Events, Recent Items, Recent Polls and Campus Highlights widgets horizontally scrollable [#1874](https://github.com/rokwire/illinois-app/issues/1874).
- Standardize compound widgets in Favorites panel [#1874](https://github.com/rokwire/illinois-app/issues/1874).
### Fixed
- Do not push the same panel on top when tapping on the root header bar [#1909](https://github.com/rokwire/illinois-app/issues/1909).
- Various fixes in the UI [#1910](https://github.com/rokwire/illinois-app/issues/1910).

## [4.0.45] - 2022-07-06
### Changed
- Show checkmark for current CheckList step if completed [#1889](https://github.com/rokwire/illinois-app/issues/1889).
- Show 3 state favorite status in HomeFavoriteButton [#1891](https://github.com/rokwire/illinois-app/issues/1891).
- Wellness Rings updates [#1692](https://github.com/rokwire/illinois-app/issues/1692).
- Make Athletics News and Events widgets horizontally scrollable [#1874](https://github.com/rokwire/illinois-app/issues/1874).
### Fixed
- Fixed content update in HomeWalletWidget [#1874](https://github.com/rokwire/illinois-app/issues/1874).

## [4.0.44] - 2022-07-05
### Changed
- "Healthy Podcast" renamed to "Healthy Illini Podcast" [#1878](https://github.com/rokwire/illinois-app/issues/1878).
- Default date picker to today in Wellness To-Do list [#1881](https://github.com/rokwire/illinois-app/issues/1881).
- Make Favorites and Wallet widgets horizontally scrollable [#1874](https://github.com/rokwire/illinois-app/issues/1874).
- Updated Twitter, Canvas Courses and Groups widgets to match standard UI [#1874](https://github.com/rokwire/illinois-app/issues/1874).
### Added
- Display predefined group post templates for group admins when creating post [#1877](https://github.com/rokwire/illinois-app/issues/1877).

## [4.0.43] - 2022-07-04
### Changed
- Various UI changes in Wellness To-Do list [#1865](https://github.com/rokwire/illinois-app/issues/1865).
- Updated launch images [#1869](https://github.com/rokwire/illinois-app/issues/1869).
- Hide State Farm Wayfinding from Explore / Map [#1872](https://github.com/rokwire/illinois-app/issues/1872).
- Make Wellness Resources widget horizontally scrollable [#1874](https://github.com/rokwire/illinois-app/issues/1874).
- Wellness Rings updates [#1692](https://github.com/rokwire/illinois-app/issues/1692).

## [4.0.42] - 2022-07-01
### Added
- Added Policy Info popup in Group detail panel [#1861](https://github.com/rokwire/illinois-app/issues/1861).
### Changed
- "My Wellness Resources" renamed to "Wellness Resources" in Browse / Wellness section, updated content code either [#1863](https://github.com/rokwire/illinois-app/issues/1863).
- Acknowledged new API for student classification, added FlexUI rules for first year student [#1860](https://github.com/rokwire/illinois-app/issues/1860).
- Various UI changes in Wellness To-Do list [#1865](https://github.com/rokwire/illinois-app/issues/1865).

## [4.0.41] - 2022-06-30
### Changed
- Use white background color for TabBar in dev builds [#1852](https://github.com/rokwire/illinois-app/issues/1852).
- "Wellness Resources" Home panel widget renamed to ""My Wellness Resources"" [#1852](https://github.com/rokwire/illinois-app/issues/1852).
### Added
- Added "My Wellness Resources" entry in "Wellness" section of Browse panel [#1852](https://github.com/rokwire/illinois-app/issues/1852).
- Created GroupPostReportAbuse panel for posting abuse reports [#1854](https://github.com/rokwire/illinois-app/issues/1854).
- Show "cost" field in campus guide if exists [#1856](https://github.com/rokwire/illinois-app/issues/1856).
- Load gies and new student checklist content from backend [#1857](https://github.com/rokwire/illinois-app/issues/1857).

## [4.0.40] - 2022-06-29
### Changed
- Small updates in Favorites/Browse content [#1843](https://github.com/rokwire/illinois-app/issues/1843).
- Canvas Course Card UI changes [#1842](https://github.com/rokwire/illinois-app/issues/1842).
- Updated Wellness Tips, added HTML content support [#1833](https://github.com/rokwire/illinois-app/issues/1833).
### Added
- Added report abuse for group posts [#1847](https://github.com/rokwire/illinois-app/issues/1847).

## [4.0.39] - 2022-06-28
### Added
- Wellness ToDo List - hook the backend APIs [#1689](https://github.com/rokwire/illinois-app/issues/1689).
- Wellness Tips loaded from backend [#1833](https://github.com/rokwire/illinois-app/issues/1833).
- Added some wellness resource items to Wellness Home content selector [#1836](https://github.com/rokwire/illinois-app/issues/1836).
- Added 8 Dimensions of wellness popup image [#1838](https://github.com/rokwire/illinois-app/issues/1838).
### Changed
- Wellness Rings updates [#1692](https://github.com/rokwire/illinois-app/issues/1692).

## [4.0.38] - 2022-06-27
### Fixed
- Resolved the conflict between start/unstarr and select/deselect all in compund widgets in Browse panel [#1827](https://github.com/rokwire/illinois-app/issues/1827).
### Added
- Wellness To-Do home/favorite widget [#1828](https://github.com/rokwire/illinois-app/issues/1828).
- Created Recent Polls home/favorite widget [#1792](https://github.com/rokwire/illinois-app/issues/1792).
- Wellness Rings updates [#1692](https://github.com/rokwire/illinois-app/issues/1692).

## [4.0.37] - 2022-06-24
### Changed
- Updated wellness resources [#1820](https://github.com/rokwire/illinois-app/issues/1820).
- Updated GIES content [#1749](https://github.com/rokwire/illinois-app/issues/1749).
- Updated home and browse tout images [#1822](https://github.com/rokwire/illinois-app/issues/1822).
### Added
- Wellness ToDo List - possibility for overriding item reminder and caegory color picker [#1689](https://github.com/rokwire/illinois-app/issues/1689).

## [4.0.36] - 2022-06-23
### Added
- Created Campus Guide home widget [#1808](https://github.com/rokwire/illinois-app/issues/1808).
- Created Dining home widget [#1814](https://github.com/rokwire/illinois-app/issues/1814).
- Updated GIES content [#1749](https://github.com/rokwire/illinois-app/issues/1749).
- Wellness ToDo List - Add/remove category, add/update/remove item (Task in progress) [#1689](https://github.com/rokwire/illinois-app/issues/1689).
### Changed
- Wellness updates [#1816](https://github.com/rokwire/illinois-app/issues/1816).

## [4.0.35] - 2022-06-22
### Fixed
- Fixed section toggle from Browse panel [#1798](https://github.com/rokwire/illinois-app/issues/1798).
- Fixed typo in "iDegrees New Student Checklist" from Browse / Academics [#1800](https://github.com/rokwire/illinois-app/issues/1800).
- Acknowledge favorites content when building HomeWalletWidget content.
- Do not build command list twice in compound widgets in HomePanel.
### Changed
- Removed FlexUI rules for filtering Favorites panel content [#1802](https://github.com/rokwire/illinois-app/issues/1802).
- Hide Building access from Favorites and Browse [#1804](https://github.com/rokwire/illinois-app/issues/1804).
- Hide the building access status and image from IDCardPanel [#1806](https://github.com/rokwire/illinois-app/issues/1806).
- Updated WellnessRingContent [#1749](https://github.com/rokwire/illinois-app/issues/1749).
### Added
- Wellness ToDo List - UI updates (Task in progress) [#1689](https://github.com/rokwire/illinois-app/issues/1689).

## [4.0.34] - 2022-06-21
### Added
- Update GIES Step 2 [#1749](https://github.com/rokwire/illinois-app/issues/1749).
- Created All Groups widget [#1786](https://github.com/rokwire/illinois-app/issues/1786).
- Load wellness tip color from the new day color API [#1788](https://github.com/rokwire/illinois-app/issues/1788).
- Wellness ToDo List - UI updates (Task in progress) [#1689](https://github.com/rokwire/illinois-app/issues/1689).
### Changed
- Disable wayfinding in State Farm Center [#1790](https://github.com/rokwire/illinois-app/issues/1790).

## [4.0.33] - 2022-06-20
### Changed
- Do not change header bar title based on the drop down selection in Wellness [#1776](https://github.com/rokwire/illinois-app/issues/1776).
- Header bar title from "Maps" to "Map" [#1778](https://github.com/rokwire/illinois-app/issues/1778).
- Rename from "Setting Sections" to "Sign In/Sign Out" [#1780](https://github.com/rokwire/illinois-app/issues/1780).
- Text and behavior updates in Favorites and Browse panels [#1782](https://github.com/rokwire/illinois-app/issues/1782).
### Added
- Wellness ToDo List - UI updates (Task in progress) [#1689](https://github.com/rokwire/illinois-app/issues/1689).

## [4.0.32] - 2022-06-17
### Fixed
- Color of the current selected drop down item in Notifications [#1760](https://github.com/rokwire/illinois-app/issues/1760).
### Changed
- Do not change header bar title based on the drop down selection [#1762](https://github.com/rokwire/illinois-app/issues/1762).
- Text updates in Browse / Athletics [#1765](https://github.com/rokwire/illinois-app/issues/1765).
- Text updates in Favorites panel [#1767](https://github.com/rokwire/illinois-app/issues/1767).
- Text updates in Favorites and Browse panels [#1770](https://github.com/rokwire/illinois-app/issues/1770).
- Text updates in Reorder/Customize panel [#1774](https://github.com/rokwire/illinois-app/issues/1774).
- Renamed Maps tabbar button to Map [#1772](https://github.com/rokwire/illinois-app/issues/1772).
- Make Wellness 8 Dimensions part of the drop down items [#1764](https://github.com/rokwire/illinois-app/issues/1764).

## [4.0.31] - 2022-06-16
### Added
- Created HomeAthleticsNewsWidget [#1752](https://github.com/rokwire/illinois-app/issues/1752).
- Created HomeAthliticsEventsWidget [#1754](https://github.com/rokwire/illinois-app/issues/1754).
- Created HomeAthliticsTeamsWidget [#1757](https://github.com/rokwire/illinois-app/issues/1757).
- Wellness ToDo List - UI updates (Task in progress) [#1689](https://github.com/rokwire/illinois-app/issues/1689).

## [4.0.30] - 2022-06-15
### Changed
- Gies content updated  [#1749](https://github.com/rokwire/illinois-app/issues/1749).
- Cleaned up FlexUI rules [#1742](https://github.com/rokwire/illinois-app/issues/1742).
- Updated icnos from Zeplin desgin [#1748](https://github.com/rokwire/illinois-app/issues/1748).
### Added
- Wellness Resources drop down item [#1741](https://github.com/rokwire/illinois-app/issues/1741).
- Wellness tip background color is color of the day [#1746](https://github.com/rokwire/illinois-app/issues/1746).

## [4.0.29] - 2022-06-14
### Changed
- Default drop down selection in Academics panel [#1726](https://github.com/rokwire/illinois-app/issues/1726).
- Favorites panel UI changes [#1729](https://github.com/rokwire/illinois-app/issues/1729).
- Updated tab icons [#1737](https://github.com/rokwire/illinois-app/issues/1737).
- Texts in Favorites panel [#1736](https://github.com/rokwire/illinois-app/issues/1736).
### Added
- Added "See All" to all home list widgets, openes the corresponding content panel [#1727](https://github.com/rokwire/illinois-app/issues/1727).
- Added "WPGU FM Radio" button to header bar title if radio is playing [#1731](https://github.com/rokwire/illinois-app/issues/1731).
- Added more entries to different browse sections [#1733](https://github.com/rokwire/illinois-app/issues/1733).

## [4.0.28] - 2022-06-13
### Added
- Created Recent Items panel, linked to Browse panel [#1701](https://github.com/rokwire/illinois-app/issues/1701).
- Created HomeWelcomeWidget [#1718](https://github.com/rokwire/illinois-app/issues/1718).
- Added Favorite buttons to HomeWalletWidget items [#1718](https://github.com/rokwire/illinois-app/issues/1718).
### Changed
- Cleaned up recent items handling [#1708](https://github.com/rokwire/illinois-app/issues/1708).
- Better processing of Home editing headers as drop targets [#1718](https://github.com/rokwire/illinois-app/issues/1718).
- Updated Wellness health rings (Work in progress)  [#1692](https://github.com/rokwire/illinois-app/issues/1692).
- Academics Panel UI [#1714](https://github.com/rokwire/illinois-app/issues/1714).
### Fixed
- Fixed HomeFavoritesWidget titles for Notifications and Guide Items [#1718](https://github.com/rokwire/illinois-app/issues/1718).
- Store user's drop down selection in each panel [#1721](https://github.com/rokwire/illinois-app/issues/1721).

## [4.0.27] - 2022-06-10
### Added
- Content for Academics Panel [#1701](https://github.com/rokwire/illinois-app/issues/1701).
- Store user selection for Settings, Profile, Notifications and Wellness [#1706](https://github.com/rokwire/illinois-app/issues/1706).
### Changed
- Handled properly different "My ___" types from Browse panel [#1705](https://github.com/rokwire/illinois-app/issues/1705).
- Handled Twitter and WPGU FM Radio entries from Browse panel, linked Canvas Courses, Sport Prefs, Wellness Rings and ToDo [#1708](https://github.com/rokwire/illinois-app/issues/1708).
- Place RootHeaderBar in Settings, Profile and Notifications content panels [#1710](https://github.com/rokwire/illinois-app/issues/1710).

## [4.0.26] - 2022-06-09
### Added
- Various updates in Maps, Events and Dinings [#1699](https://github.com/rokwire/illinois-app/issues/1699).
### Changed
- Implemnted new Browse panel [#1629](https://github.com/rokwire/illinois-app/issues/1629).

## [4.0.25] - 2022-06-08
### Changed
- Use LongPressDraggable instead of Draggable in HomeHandleWidget [#1696](https://github.com/rokwire/illinois-app/issues/1696).
- Rename "Navigate" tab to "Maps" [#1695](https://github.com/rokwire/illinois-app/issues/1695).
- Explore tabs in ExplorePanel to dropdown items [#1695](https://github.com/rokwire/illinois-app/issues/1695).
### Added
- Show Explore panel on "Maps" tab [#1695](https://github.com/rokwire/illinois-app/issues/1695).

## [4.0.24] - 2022-06-07
### Added
- Show Wellness ToDo items in a plain list (Task in progress) [#1689](https://github.com/rokwire/illinois-app/issues/1689).
- Show Wellness Ring prototype (Task in progress) [#1692](https://github.com/rokwire/illinois-app/issues/1692).

## [4.0.23] - 2022-06-06
### Added
- New Wellness home panel (Task in progress) [#1689](https://github.com/rokwire/illinois-app/issues/1689).

## [4.0.22] - 2022-06-03
### Changed
- Various updates in HomePanel and HomeTout [#1629](https://github.com/rokwire/illinois-app/issues/1629).

## [4.0.21] - 2022-06-02
### Added
- Settings Content - Calendar settings and My Notifications (Done) [#1670](https://github.com/rokwire/illinois-app/issues/1670).
- HomeToutWidget [#1629](https://github.com/rokwire/illinois-app/issues/1629).
### Changed
- Cleaned up Drag & Drop in Home panel [#1629](https://github.com/rokwire/illinois-app/issues/1629).
- Removed Group polls hook methods [#1679](https://github.com/rokwire/illinois-app/issues/1679).

## [4.0.20] - 2022-06-01
### Added
- Load and display user's grade for each canvas course [#1681](https://github.com/rokwire/illinois-app/issues/1681).
- Implemented edit mode in Home panel [#1629](https://github.com/rokwire/illinois-app/issues/1629).
- Settings Content - Interests, Food Filters and Sports. (Task in progress) [#1670](https://github.com/rokwire/illinois-app/issues/1670).

## [4.0.19] - 2022-05-31
### Added
- Settings Content for Profile and Notifications. (Task in progress) [#1670](https://github.com/rokwire/illinois-app/issues/1670).
### Fixed
- Fixed scrolling in Home panel after drag and drop operation [#1629](https://github.com/rokwire/illinois-app/issues/1629).
### Changed
- Prompt before unfavorite home widget [#1629](https://github.com/rokwire/illinois-app/issues/1629).

## [4.0.18] - 2022-05-30
### Added
- Store HomePanel widgets order in user favorites, handled Favorite start on Home panel widgets [#1629](https://github.com/rokwire/illinois-app/issues/1629).
- New UI for Settings - Home and My Profile. (Task in progress) [#1670](https://github.com/rokwire/illinois-app/issues/1670).

## [4.0.17] - 2022-05-27
### Changed
- Buttons for "On Campus" [#1664](https://github.com/rokwire/illinois-app/issues/1664).
- Fix typo in HomeRadioWidget [#1666](https://github.com/rokwire/illinois-app/issues/1666).
- Change comply message when creating a Group [#1668](https://github.com/rokwire/illinois-app/issues/1668).
- Implemented drag and drop capability in HomePanel [#1629](https://github.com/rokwire/illinois-app/issues/1629).
### Added
- Regular Student onboarding checklist (in progress) [#1671](https://github.com/rokwire/illinois-app/issues/1671).

## [4.0.16] - 2022-05-25
### Changed
- Cash data in Gies service, various improvements added.
### Added
- Launch "Canvas Student" app - deep link to specific assignment [#1661](https://github.com/rokwire/illinois-app/issues/1661).

## [4.0.15] - 2022-05-23
### Changed
- HomeIlliniCashWidget, HomeMealPlanWidget, HomeBusPassWidget, HomeIlliniIdWidget and HomeLibraryCardWidget moved inside the new HomeWalletWidget [#1629](https://github.com/rokwire/illinois-app/issues/1629).
- Rename "Attendance Group" to "Enable attendance checking" [#1643](https://github.com/rokwire/illinois-app/issues/1643).
### Added
- Cache attended group members when offline [#1643](https://github.com/rokwire/illinois-app/issues/1643).

## [4.0.14] - 2022-05-20
### Added
- Audio and images for Home Radio widget [#1652](https://github.com/rokwire/illinois-app/issues/1652).
- Group Attendance [#1643](https://github.com/rokwire/illinois-app/issues/1643).
### Changed
- Updated delete account data strings and availability [#1655](https://github.com/rokwire/illinois-app/issues/1655).

## [4.0.13] - 2022-05-19
### Added
- Ui for Home Radio widget [#1652](https://github.com/rokwire/illinois-app/issues/1652).
### Changed
- Prompt before creating a group [#1650](https://github.com/rokwire/illinois-app/issues/1650).

## [4.0.12] - 2022-05-18
### Fixed
- Fixed Gies Home Widget status [#1646](https://github.com/rokwire/illinois-app/issues/1646).
- Do not try to display courses that are restricted by date [#1641](https://github.com/rokwire/illinois-app/issues/1641).
### Added
- Created HomeBusPassWidget, HomeIlliniIdWidget and HomeLibraryCardWidget [#1629](https://github.com/rokwire/illinois-app/issues/1629).
### Changed
- Acknowledged new navigation tabbar content [#1645](https://github.com/rokwire/illinois-app/issues/1645).

## [4.0.11] - 2022-05-17
### Added
- Created HomeIlliniCashWidget and HomeMealPlanWidget [#1629](https://github.com/rokwire/illinois-app/issues/1629).
- Created HomeFavoritesWidget [#1629](https://github.com/rokwire/illinois-app/issues/1629).

## [4.0.10] - 2022-05-16
### Changed
- Cleaned up app, root panels and tab bar, prepare for UIUC 4 features [#1629](https://github.com/rokwire/illinois-app/issues/1629).
- Acknowledged order of Favorite items [#1629](https://github.com/rokwire/illinois-app/issues/1629).
- Various fixes in Favotires root panel [#1629](https://github.com/rokwire/illinois-app/issues/1629).
### Added
- Created Favorites root panel [#1629](https://github.com/rokwire/illinois-app/issues/1629).
- Added API call for content items. Load Gies from network [#1636](https://github.com/rokwire/illinois-app/issues/1636).

## [4.0.9] - 2022-05-13
### Changed
- Cleaned up Favorites, prepare for UIUC 4 features [#1629](https://github.com/rokwire/illinois-app/issues/1629).
### Fixed
- Display Laundry rooms on the native map [#1530](https://github.com/rokwire/illinois-app/issues/1530).

## [4.0.8] - 2022-05-12
### Added
- Submit issue request for laundry machines [#1530](https://github.com/rokwire/illinois-app/issues/1530).
### Changed
- Gies Panel navigation with navigation_buttons for all pages [#1605](https://github.com/rokwire/illinois-app/issues/1605).
- Hide "On Campus" related stuff for GIES students [#1623](https://github.com/rokwire/illinois-app/issues/1623).

## [4.0.7] - 2022-05-11
### Fixed
- Gies updates: Gies step completion depends only on page verification[#1605](https://github.com/rokwire/illinois-app/issues/1605).
### Added
- UI for loading possible issue codes for laundry machines [#1530](https://github.com/rokwire/illinois-app/issues/1530).

## [4.0.6] - 2022-05-10
### Added
- Update Group API to hook polls  [#1617](https://github.com/rokwire/illinois-app/issues/1617).
### Changed
- Use Gateway BB for loading laundries [#1530](https://github.com/rokwire/illinois-app/issues/1530).

## [4.0.5] - 2022-05-09
### Fixed
- Crash in GroupDetailPanel [#1611](https://github.com/rokwire/illinois-app/issues/1611).
### Changed
- Laundry - remove location info and update icons [#1530](https://github.com/rokwire/illinois-app/issues/1530).

## [4.0.4] - 2022-05-05
### Added
- Added Settings Notifications button for Group polls [#1608](https://github.com/rokwire/illinois-app/issues/1608).

## [4.0.3] - 2022-05-04
### Added
- "CC" button in video panels [#1602](https://github.com/rokwire/illinois-app/issues/1602).
- Gies onboarding updates [#1605](https://github.com/rokwire/illinois-app/issues/1605).

## [4.0.2] - 2022-05-03
### Changed
- "Health Illini Podcast" renamed to "Healthy Illini Podcast" [#1485](https://github.com/rokwire/illinois-app/issues/1485).
### Added
- "Play" button in video panels [#1602](https://github.com/rokwire/illinois-app/issues/1602).

## [4.0.1] - 2022-04-29
### Added
- Added links to app and plugin Wiki documentation in README [#1597](https://github.com/rokwire/illinois-app/issues/1597).
### Changed
- Wording for hidden group [#1598](https://github.com/rokwire/illinois-app/issues/1598).

## [4.0.0] - 2022-04-28
### Changed
- Cleaned up laundry handling [#1530](https://github.com/rokwire/illinois-app/issues/1530).
### Added
- Added OnCampus service for campus location control [#1567](https://github.com/rokwire/illinois-app/issues/1567).
- Integrate new Polls BB [#1565](https://github.com/rokwire/illinois-app/issues/1565).
- Allow private groups to be hidden from search [#1592](https://github.com/rokwire/illinois-app/issues/1592).

## [3.3.22] - 2022-04-28
### Changed
- Remove "play/pause" button from video panels. Bring back auto play [#1594](https://github.com/rokwire/illinois-app/issues/1594).

## [3.3.21] - 2022-04-27
### Changed
- Updated Privacy description strings [#1578](https://github.com/rokwire/illinois-app/issues/1578).
- Always use the new privacy setting panel [#1588](https://github.com/rokwire/illinois-app/issues/1588).

## [3.3.20] - 2022-04-26
### Changed
- Updated Privacy description strings [#1578](https://github.com/rokwire/illinois-app/issues/1578).
- Bring back the old Polls BB [#1579](https://github.com/rokwire/illinois-app/issues/1579).
- Show privacy sign in message for Meal Plan, Quick Polls and Illini Cash panels [#1508](https://github.com/rokwire/illinois-app/issues/1508).
- Add Play/Pause button in video panels. Do not autoplay video [#1569](https://github.com/rokwire/illinois-app/issues/1569).

## [3.3.19] - 2022-04-21
### Added
- Integrate new Polls BB [#1565](https://github.com/rokwire/illinois-app/issues/1565).

## [3.3.18] - 2022-04-18
### Changed
- Update favorite icon availability for privacy level 4+ [#1548](https://github.com/rokwire/illinois-app/issues/1548).
### Fixed
- Extent the tap area in privacy panel for data usage [#1563](https://github.com/rokwire/illinois-app/issues/1563).

## [3.3.17] - 2022-04-15
### Fixed
- Properly handle UI changes when privacy level is changed [#1546](https://github.com/rokwire/illinois-app/issues/1546).
- Remove 3 broken external links [#1555](https://github.com/rokwire/illinois-app/issues/1555).
### Changed
- Update strings related to privacy level [#1553](https://github.com/rokwire/illinois-app/issues/1553).

## [3.3.16] - 2022-04-14
### Changed
- Updated strings in "privacy_new" section from assets.json [#1540](https://github.com/rokwire/illinois-app/issues/1540).
- Updated privacy descriptions again in "privacy_new" section from assets.json [#1540](https://github.com/rokwire/illinois-app/issues/1540).
- UI improvements [#1550](https://github.com/rokwire/illinois-app/issues/1550).
- Acknwoledged user privacy level and authentication status in Groups [#1548](https://github.com/rokwire/illinois-app/issues/1548).

## [3.3.15] - 2022-04-12
### Added
- Added more sections in "privacy_new" section from assets.json [#1540](https://github.com/rokwire/illinois-app/issues/1540).
### Changed
- Privacy alert content and fixed delay after user's selection [#1536](https://github.com/rokwire/illinois-app/issues/1536).
- Gies cleanup [#1543](https://github.com/rokwire/illinois-app/issues/1543).
### Fixed
- Show "Game Day Guide" button only for men's basketball and football [#1531](https://github.com/rokwire/illinois-app/issues/1531).

## [3.3.14] - 2022-04-11
### Added
- User's profile picture in group listing panel [#1534](https://github.com/rokwire/illinois-app/issues/1534).
### Changed
- Show Edit Image panel for editing user's profile picture [#1538](https://github.com/rokwire/illinois-app/issues/1538).
- Buttons for editing user's profile picture [#1532](https://github.com/rokwire/illinois-app/issues/1532).
- App behavior when "Building Access" is tapped [#1536](https://github.com/rokwire/illinois-app/issues/1536).

## [3.3.13] - 2022-04-07
### Fixed
- User profile picture rotation before upload [#1528](https://github.com/rokwire/illinois-app/issues/1528).

## [3.3.12] - 2022-04-06
### Fixed
- User profile picture improvements [#1526](https://github.com/rokwire/illinois-app/issues/1526).

## [3.3.11] - 2022-04-05
### Fixed
- Fixed missing Group Input box for Search field of select member [#1513](https://github.com/rokwire/illinois-app/issues/1513).

## [3.3.10] - 2022-04-04
### Fixed
- Change "log in" to "sign in" [#1514](https://github.com/rokwire/illinois-app/issues/1514).
- Fixed Group event update members selection [#1519](https://github.com/rokwire/illinois-app/issues/1519).

## [3.3.9] - 2022-04-01
### Changed
- Semantics improvements: WalletPanel added hint for "View" buttons [#503](https://github.com/rokwire/illinois-app/issues/503).
- Semantics improvements: HomeSaferWidget try fixing semantics id by replacing InkWell with GestureDetector [#1281](https://github.com/rokwire/illinois-app/issues/1281).
### Fixed
- Trim user's fullname retrieved from auth card [#1504](https://github.com/rokwire/illinois-app/issues/1504).
- Change button title from "Skip" to "Continue" when the video has ended [#1511](https://github.com/rokwire/illinois-app/issues/1511).

## [3.3.8] - 2022-03-30
### Added
- User Profile Picture [#1500](https://github.com/rokwire/illinois-app/issues/1500).
### Changed
- Semantics improvements: PollBubblePromptPanel - Announce when voting was successful [#1496](https://github.com/rokwire/illinois-app/issues/1496).
- Semantics improvements: Announce when poll was closed successfully [#1494](https://github.com/rokwire/illinois-app/issues/1494).
- Semantics improvements: add semantics for Athletics images (game/roster/coach/etc.) [#510](https://github.com/rokwire/illinois-app/issues/510).

## [3.3.7] - 2022-03-28
### Changed
- Place "video_tutorial_url" in "otherUniversityServices" config section [#1498](https://github.com/rokwire/illinois-app/issues/1498).

## [3.3.6] - 2022-03-25
### Changed
- Added "Health Illini Podcast" interactive activity to all Interactive Activities across the wellness panels [#1485](https://github.com/rokwire/illinois-app/issues/1485).
- Updated GroupsMembersSelectionWidget [#1487](https://github.com/rokwire/illinois-app/issues/1487).

## [3.3.5] - 2022-03-24
### Added
- Added "Health Illini Podcast" interactive activity in Wellness home panel [#1485](https://github.com/rokwire/illinois-app/issues/1485).
- Added Member selection widget into the Group Event Add/Create panels [#1487](https://github.com/rokwire/illinois-app/issues/1487). 
### Changed
- The way group member goes to member list [#1484](https://github.com/rokwire/illinois-app/issues/1484).
- Reordered buttons in DebugHomePanel.

## [3.3.4] - 2022-03-23
### Added
- Allow group members to see members list [#1482](https://github.com/rokwire/illinois-app/issues/1482).
### Fixed
- Make the "Skip" button in Onboarding2VideoTutorialPanel smaller [#1479](https://github.com/rokwire/illinois-app/issues/1479).

## [3.3.3] - 2022-03-22
### Changed
- Android: rotate device screen to desired orientation if it's supported and accelerometer rotation is allowed [#1470](https://github.com/rokwire/illinois-app/issues/1470).

## [3.3.2] - 2022-03-21
### Added
- SettingsideoTutorialPanel with playing video [#1470](https://github.com/rokwire/illinois-app/issues/1470).
### Changed
- Update Group post for selected members [#1450](https://github.com/rokwire/illinois-app/issues/1450).

## [3.3.1] - 2022-03-17
### Added
- Onboarding2VideoTutorialPanel with playing video [#1470](https://github.com/rokwire/illinois-app/issues/1470).
- Implement Group post for selected members [#1450](https://github.com/rokwire/illinois-app/issues/1450).
### Changed
- Link to plugin 1.0.0.
- Various controls moved to plugin [#1325](https://github.com/rokwire/illinois-app/issues/1325).

## [3.2.38] - 2022-04-25
### Changed
- Increased version number to generate a Zenodo citation.

## [3.2.37] - 2022-03-17
### Fixed
- Await complete initialization after OIDC login before displaying IDCardPanel from Building Access home widget [#1467](https://github.com/rokwire/illinois-app/issues/1467).
### Changed
- Link to rokwire plugin version 0.0.3.

## [3.2.36] - 2022-03-16
### Fixed
- PollBubblePinPanel: improve Accessibility [#1446](https://github.com/rokwire/illinois-app/issues/1446).
- Wrong game dates [#1451](https://github.com/rokwire/illinois-app/issues/1451).
- Always show "Building Access" widgets on the home screen [#1460](https://github.com/rokwire/illinois-app/issues/1460).
- Handle tap action on "Building Access" widget [#1462](https://github.com/rokwire/illinois-app/issues/1462).
- Saving Privacy level [#1463](https://github.com/rokwire/illinois-app/issues/1463).
- Fix crash in onboarding [#1448](https://github.com/rokwire/illinois-app/issues/1448).


## [3.2.35] - 2022-03-10
### Fixed
- GroupEditImagePanel: fix cancel button functionality [#1441](https://github.com/rokwire/illinois-app/issues/1441).

## [3.2.34] - 2022-03-09
### Changed
- Label in SettingsPersonalInfoPanel from 'NetID' to 'UIN' [#1334](https://github.com/rokwire/illinois-app/issues/1334).
- Updated display of campus reminder card [#1401](https://github.com/rokwire/illinois-app/issues/1401).
### Fixed
- Groups - App is hanging when user selects an option in Image source [#1431](https://github.com/rokwire/illinois-app/issues/1431).
- Groups - App results in a black screen when the user selects an image in the gallery [#1432](https://github.com/rokwire/illinois-app/issues/1432).

## [3.2.33] - 2022-03-07
### Fixed
- Wrap confirmation buttons in Expanded widget when building a prompt in Group detail panel [#1426](https://github.com/rokwire/illinois-app/issues/1426).

## [3.2.32] - 2022-03-04
### Fixed
- Center header bar in Wellness panels [#1417](https://github.com/rokwire/illinois-app/issues/1417).
- Require relogin when linking NetID account [#1420](https://github.com/rokwire/illinois-app/issues/1420).

## [3.2.31] - 2022-03-02
### Changed
- Alternate Login Changes [#1407](https://github.com/rokwire/illinois-app/issues/1407).

## [3.2.30] - 2022-03-02
### Changed
- Alternate Login Changes [#1407](https://github.com/rokwire/illinois-app/issues/1407).

## [3.2.29] - 2022-03-01
### Changed
- Gies group name updated to "Gies Online Programs" to match production name [#1408](https://github.com/rokwire/illinois-app/issues/1408).
- Alternate Login Changes (not finished) - Settings and Add panels [#1407](https://github.com/rokwire/illinois-app/issues/1407).

## [3.2.28] - 2022-02-28
### Changed
- Reorder Home panel widgets [#1402](https://github.com/rokwire/illinois-app/issues/1402).
### Fixed
- Android: plugin initialization [#1405](https://github.com/rokwire/illinois-app/issues/1405).
### Added
- Added pull to refresh in Explore panel [#1404](https://github.com/rokwire/illinois-app/issues/1404).

## [3.2.27] - 2022-02-25
### Added
- Account linking verbiage updates [#1393](https://github.com/rokwire/illinois-app/issues/1393)
### Changed
- Text capitalization in various screens [#1386](https://github.com/rokwire/illinois-app/issues/1386).
- Reorder home panel widgets [#1397](https://github.com/rokwire/illinois-app/issues/1397).
### Fixed
- Crash on "Forget My Information" [#1392](https://github.com/rokwire/illinois-app/issues/1392).
- Fixed privacy acknowledgement in diffent (but not all) places [#1357](https://github.com/rokwire/illinois-app/issues/1357).

## [3.2.26] - 2022-02-24
### Fixed
- Account linking UI improvements [#1378](https://github.com/rokwire/illinois-app/issues/1378)
- Fix issues with account linking [#1356](https://github.com/rokwire/illinois-app/issues/1356)
### Changed
- Modify Wellness Answer Center button [#1364](https://github.com/rokwire/illinois-app/issues/1364).
### Removed
- Retrieve group by canvas course [#1274](https://github.com/rokwire/illinois-app/issues/1274).
### Added
- Added account switch dropdown in Home Twitter widget [#1389](https://github.com/rokwire/illinois-app/issues/1389).

## [3.2.25] - 2022-02-23
### Added
- Display Gies, Twitter and Canvas home widgets based on user group membership [#1377](https://github.com/rokwire/illinois-app/issues/1377).
- Use LMS BB for Canvas requests [#1381](https://github.com/rokwire/illinois-app/issues/1381).
- Added "Due Date Catalog" button in Browse panel [#1371](https://github.com/rokwire/illinois-app/issues/1371).
### Changed
- Update GIES wizard [#1379](https://github.com/rokwire/illinois-app/issues/1379).

## [3.2.24] - 2022-02-21
### Added
- Time in Rewards history debug panel [#1372](https://github.com/rokwire/illinois-app/issues/1372).
- Implement crop/rotate when adding image [#1375](https://github.com/rokwire/illinois-app/issues/1375)

## [3.2.23] - 2022-02-18
### Added
- SectionTitlePrimary and LinkTileButtons moved to Rokwire plugin [#1325](https://github.com/rokwire/illinois-app/issues/1325).
- FlexContentWidget moved to Rokwire plugin [#1325](https://github.com/rokwire/illinois-app/issues/1325).
- Redirect user to external web page when Canvas "Zoom Meeting" is tapped [#1274](https://github.com/rokwire/illinois-app/issues/1274).
- Possibility for loading collaborations, modules and assignments for all Canvas courses [#1274](https://github.com/rokwire/illinois-app/issues/1274).
- Canvas user info in the Debug panel [#1274](https://github.com/rokwire/illinois-app/issues/1274).

## [3.2.22] - 2022-02-17
### Added
- Rewards model and service. Show balance and history in the debug panel [#1363](https://github.com/rokwire/illinois-app/issues/1363).

## [3.2.21] - 2022-02-16
### Added
- TweeterPage widget: add next/previous buttons [#1353](https://github.com/rokwire/illinois-app/issues/1353).
- TabBar widget moved to Rokwire plugin [#1325](https://github.com/rokwire/illinois-app/issues/1325).
- WebPanel moved to Rokwire plugin [#1325](https://github.com/rokwire/illinois-app/issues/1325).
- Possibility for loading both events and assignments in Canvas calendar [#1274](https://github.com/rokwire/illinois-app/issues/1274).
- Possibility for loading announcements for all Canvas courses [#1274](https://github.com/rokwire/illinois-app/issues/1274).
### Fixed
- Messages for events and assignments in Canvas Calendar [#1274](https://github.com/rokwire/illinois-app/issues/1274).
### Removed
- Canvas Feedback [#1274](https://github.com/rokwire/illinois-app/issues/1274).

## [3.2.20] - 2022-02-15
### Added
- Header bars moved to Rokwire plugin UI section [#1325](https://github.com/rokwire/illinois-app/issues/1325).
- Ribbon buttons moved to Rokwire plugin [#1325](https://github.com/rokwire/illinois-app/issues/1325).
- Masquerade a user when requesting Canvas API [#1274](https://github.com/rokwire/illinois-app/issues/1274).
- Canvas Assignments in the calendar [#1274](https://github.com/rokwire/illinois-app/issues/1274).
### Removed
- Canvas Course completion / result percentage [#1274](https://github.com/rokwire/illinois-app/issues/1274).
- Canvas 'Grades' [#1274](https://github.com/rokwire/illinois-app/issues/1274).
### Changed
- Remove Scroll from twitter page and workaround setState exception [#1353](https://github.com/rokwire/illinois-app/issues/1353).

## [3.2.19] - 2022-02-14
### Added
- Canvas Assignments [#1274](https://github.com/rokwire/illinois-app/issues/1274).

## [3.2.18] - 2022-02-11
### Added
- Added analytics packets timestamps [#1340](https://github.com/rokwire/illinois-app/issues/1340).
- Gies wizard support navigation buttons [#1343](https://github.com/rokwire/illinois-app/issues/1343).
- implement "Only admins can create Polls" for group [#1346](https://github.com/rokwire/illinois-app/issues/1346).
### Changed
- Values for the courses dropdown in Canvas calendar [#1274](https://github.com/rokwire/illinois-app/issues/1274).
### Fixed
- Fixed some display tweaks of Twitter entries [#1322](https://github.com/rokwire/illinois-app/issues/1322).

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
