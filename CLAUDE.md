# Illinois Flutter App

## Overview
Official University of Illinois mobile app (Rokwire Platform). No automated
test suite currently exists — do not assume test files or write instructions
that depend on `flutter test` passing.

## Commands
- `flutter pub get` — install dependencies
- `flutter analyze` — run linter
- `flutter build apk --no-tree-shake-icons --flavor IllinoisDev -t lib/mainDev.dart` — build dev apk

## Architecture
Two-repo structure joined as git submodules:
- Main app: this repo (illinois-app)
- `plugin/` — app-flutter-plugin, a git submodule (rokwire/app-flutter-plugin), not a plain subdirectory
- `libs/` — illinois-app-libs, a git submodule for private external libraries
- 
Function-first folder structure for both app and plugin library.
- Models: `lib/model/`
- Data/document layer: `lib/service/`
- UI, split by feature: `lib/ui/<name>`
- Notifications: NotificationService (in plugin)
- HTTP: custom Network class over `http` package — `plugin/lib/service/network.dart`
  
No state management library (Provider/Bloc/Riverpod) — this project does not use one; do not introduce one without asking first.

## Conventions
- Prefix private widgets with an underscore.
- Always check widget's `mounted` state after asynchronous operations.
- Always use visual feedback when performing asynchronous operations, e.g. progress indicator.
- Use the same code style and alignment as the existing in the project.
- Write source code as a very experienced senior software developer.

## What NOT to do
- Do not introduce build errors or warnings.
- Do not make straight network calls from UI - all data should be retrieved from the corresponding data/document module.
- Do not add new packages without asking first.
- Do not run any git commands (`git add`, `git commit`, `git push`, etc.) —
  prepare and leave changes in the working tree only; a human commits.

## Links
- GitHub app: https://github.com/rokwire/illinois-app
- GitHub plugin: https://github.com/rokwire/app-flutter-plugin
- Backend API documentation: https://api-dev.rokwire.illinois.edu/<service-name>/doc/ui/index.html
