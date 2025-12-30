
import 'package:http/http.dart';
import 'package:illinois/model/Wordle.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/Storage.dart';
import 'package:rokwire_plugin/ext/network.dart';
import 'package:rokwire_plugin/service/network.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class WordleGameData {
  static Future<WordleDailyWord?> loadDailyWord() async {
    WordleDailyWord? debugDailyWord = WordleDailyWord.fromJson(JsonUtils.decodeMap(Storage().debugWordleDailyWord));
    return (debugDailyWord != null) ?  debugDailyWord : await loadDailyWordFromNet();
  }

  static Future<WordleDailyWord?> loadDailyWordFromNet() async {
    String? url = Config().illordleDailyWordUrl;
    Response? response = (url?.isNotEmpty == true) ? await Network().get(url) : null;
    return (response?.succeeded == true) ? WordleDailyWord.fromJson(JsonUtils.decodeMap(response?.body)) : null;
  }

  static Future<Set<String>?> loadDictionary() async {
    String? url = Config().illordleWordsUrl;
    Response? response = (url?.isNotEmpty == true) ? await Network().get(url) : null;
    return (response?.succeeded == true) ? SetUtils.from(JsonUtils.stringValue(response?.body)?.split(RegExp(r'[\r\n]')).map((String word) => word.toUpperCase())) : null;
  }
}