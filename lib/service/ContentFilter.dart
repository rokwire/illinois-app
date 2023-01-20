
import 'package:illinois/model/ContentFilter.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class ContentFilters /* with Service */ {

  // Singletone instance

  static final ContentFilters _service = ContentFilters._internal();
  factory ContentFilters() => _service;

  ContentFilters._internal();

  // Implementation

  Future<ContentFilterSet?> loadFilterSet(String category) async {
    return ContentFilterSet.fromJson(JsonUtils.decodeMap(await AppBundle.loadString('assets/content.filters.$category.json')));
  }
}