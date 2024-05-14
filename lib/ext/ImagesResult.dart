import 'package:rokwire_plugin/service/content.dart';

extension ImagesResultExt on ImagesResult{

  bool get succeeded => resultType == ImagesResultType.succeeded;

  T? getDataAs<T>(){
    return data != null && data is T ? data as T : null;
  }

  String? get stringData => getDataAs();
}