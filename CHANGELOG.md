# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased
### Added
- Contributor guidelines (CONTRIBUTING.md). [#126](https://github.com/rokwire/illinois-app/issues/124)

## [2.3.12] - 2020-10-21
- Unable to log in with iOS Default Browser changed [#124](https://github.com/rokwire/illinois-app/issues/124)

## [2.3.11] - 2020-10-13
- Upgrade Flutter to v1.22.1 - Additional fixes and cleanup [#116](https://github.com/rokwire/illinois-app/issues/116)

## [2.3.10] - 2020-10-12
- Upgrade Flutter to v1.22.1 - fix broken Android polls plugin and crashlytics[#116](https://github.com/rokwire/illinois-app/issues/116)

## [2.3.9] - 2020-10-09
- Upgrade Flutter to v1.22.1 [#116](https://github.com/rokwire/illinois-app/issues/116)
- Make debug button being visible as in Safer Illinois App [#112](https://github.com/rokwire/illinois-app/issues/112)
- Support languages defined only in the backend [#114](https://github.com/rokwire/illinois-app/issues/114)

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
### Removed Save buttons from Profile Informations panels

## [2.2.15] - 2020-09-01
### Exposed Strings for localisation

## [2.2.14] - 2020-08-31

### Improved VO features [#24]

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
