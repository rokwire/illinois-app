
import 'package:http/http.dart';
import 'package:illinois/model/Inbox.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/Network.dart';
import 'package:illinois/utils/Utils.dart';

/// Inbox service does rely on Service initialization API so it does not override service interfaces and is not registered in Services.
class Inbox /* with Service */ {

  static final Inbox _instance = Inbox._internal();

  factory Inbox() {
    return _instance;
  }

  Inbox._internal();

  Future<List<InboxMessage>> loadMessages({DateTime startDate, DateTime endDate, String category, int offset, int limit }) async {
    String urlParams = "";
    if (offset != null) {
      if (urlParams.isNotEmpty) {
        urlParams += "&";
      }
      urlParams += "offset=$offset";
    }
    if (limit != null) {
      if (urlParams.isNotEmpty) {
        urlParams += "&";
      }
      urlParams += "limit=$limit";
    }
    if (urlParams.isNotEmpty) {
      urlParams = "?$urlParams";
    }

    String url = "${Config().notificationsUrl}/api/messages$urlParams";
    Map<String, String> headers = {
      Network.RokwireApiKey : Config().rokwireApiKey,
    };

    Response response = await Network().get(url, auth: NetworkAuth.User, headers: headers);
    return (response?.statusCode == 200) ? (InboxMessage.listFromJson(AppJson.decodeList(response?.body)) ?? []) : null;
  }
}