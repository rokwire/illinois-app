
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

  Future<List<InboxMessage>> loadMessages({DateTime startDate, DateTime endDate, String category, Iterable messageIds, int offset, int limit }) async {
    
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

    if (startDate != null) {
      if (urlParams.isNotEmpty) {
        urlParams += "&";
      }
      urlParams += "start_date=${startDate.millisecondsSinceEpoch}";
    }

    if (endDate != null) {
      if (urlParams.isNotEmpty) {
        urlParams += "&";
      }
      urlParams += "end_date=${endDate.millisecondsSinceEpoch}";
    }

    if (urlParams.isNotEmpty) {
      urlParams = "?$urlParams";
    }

    dynamic body = (messageIds != null) ? AppJson.encode({ "ids": List.from(messageIds) }) : null;

    String url = "${Config().notificationsUrl}/api/messages$urlParams";
    Response response = await Network().get(url, body: body, auth: NetworkAuth.User);
    return (response?.statusCode == 200) ? (InboxMessage.listFromJson(AppJson.decodeList(response?.body)) ?? []) : null;
  }

  Future<bool> deleteMessages(Iterable messageIds) async {
    String url = "${Config().notificationsUrl}/api/messages";
    String body = AppJson.encode({
      "ids": (messageIds != null) ? List.from(messageIds) : null
    });

    Response response = await Network().delete(url, body: body, auth: NetworkAuth.User);
    return (response?.statusCode == 200);
  }

  Future<bool> sendMessage(InboxMessage message) async {
    String url = "${Config().notificationsUrl}/api/message";
    String body = AppJson.encode(message?.toJson());

    Response response = await Network().post(url, body: body, auth: NetworkAuth.User);
    return (response?.statusCode == 200);
  }
}