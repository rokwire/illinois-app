# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased
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
- Handled location error in iOS Directions controller [#254](https://github.com/rokwire/safer-illinois-app/issues/254).

## [2.4.11] - 2021-05-26
### Fixed
- Illini Cash isn't displaying unless logged in [#252](https://github.com/rokwire/safer-illinois-app/issues/252).

## [2.4.10] - 2021-05-21
### Changed
- Name change - "Cafe Credits" to "Dining Dollars" [#250](https://github.com/rokwire/safer-illinois-app/issues/250).

## [2.4.9] - 2021-05-18
### Changed
- Flutter 2.0 integration [#245](https://github.com/rokwire/safer-illinois-app/issues/245).

## [2.4.8] - 2021-05-14
### Added
- Added capability to override Styles content from Settings Debug panel [#246](https://github.com/rokwire/safer-illinois-app/issues/246).

## [2.4.7] - 2021-05-13
### Fixed
- Handled exceptions when system date time is much behind the current date time [#243](https://github.com/rokwire/safer-illinois-app/issues/243).

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
- Pass application id as header field in FCM API calls from sports service [#154](https://github.com/rokwire/safer-illinois-app/issues/154).

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
- Locale strings from net just override the built-in asset strings [104](https://github.com/rokwire/safer-illinois-app/issues/104).

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
