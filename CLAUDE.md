# Illinois Flutter App

## Commands
- `flutter pub get` — install dependencies
- `flutter analyze` — run linter
- `flutter build apk --no-tree-shake-icons --flavor IllinoisDev -t lib/mainDev.dart` — build dev apk

## Architecture
The application consists of an `illinois-app` application and a `app-flutter-plugin` library. Тhe library is located in plugin subdirectory.
Function-first folder structure for both app and plugin library.
Model definitions live in lib/model/.
Data/Document layer lives in lib/service/.
UI is separated by features. Each UI feature lives in lib/ui/<name>.
Notification management: custom service NotificationService located in the plugin library.
HTTP: custom Network class layer that uses http dart package located in plugin/lib/service/network.dart.

## Conventions
- Prefix private widgets with an underscore.
- Always check widget's 'mounted state after asynchronous operations.
- Always use visual feedback when performing asynchronous operations, e.g. progress indicator.
- Use the same code style and alignment as the existing in the project.
- Write source code as a very experiened senior software developer.

## What NOT to do
- Do not introduce build errors or warnings.
- Do not make straight network calls from UI - all data should be retriebed from the corresponding data/document module.
- Do not add new packages without asking first.
- Do not check in anything in GitHub.

## Links
- GitHub app: https://github.com/rokwire/illinois-app
- GitHub plugin: https://github.com/rokwire/app-flutter-plugin
- Backend API documentation: https://api-dev.rokwire.illinois.edu/<service-name>/doc/ui/index.html
