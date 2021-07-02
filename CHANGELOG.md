# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased
### Added
- Questions when creating group [#417](https://github.com/rokwire/illinois-app/issues/417).
- Group Admins in "About" section [#419](https://github.com/rokwire/illinois-app/issues/419).

## [2.5.3] - 2021-07-01
### Added
- Delete group [#400](https://github.com/rokwire/illinois-app/issues/400).
- Use correct categories and tags for group [#406](https://github.com/rokwire/illinois-app/issues/406).
### Changed
- Groups UI improvements [#413](https://github.com/rokwire/illinois-app/issues/413).
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
