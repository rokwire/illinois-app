
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:illinois/service/Config.dart';
import 'package:rokwire_plugin/service/log.dart';
import 'package:illinois/service/Network.dart';
import 'package:illinois/service/Styles.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class DebugInboxUserInfoPanel extends StatefulWidget{
  DebugInboxUserInfoPanel();

  _DebugInboxUserInfoPanelState createState() => _DebugInboxUserInfoPanelState();
}

class _DebugInboxUserInfoPanelState extends State<DebugInboxUserInfoPanel>{

  bool _loading = false;

  InboxUserInfo? _info;

  @override
  void initState() {
    super.initState();
    setState(() {
      _loading = true;
    });
    _lodUserInfo().whenComplete((){
      setState(() {
        _loading = false;
      });
    });
  }

  Future<void> _lodUserInfo() async{
      try {
        Response? response = (Config().notificationsUrl != null) ? await Network().get("${Config().notificationsUrl}/api/user",
            auth: NetworkAuth.Auth2) : null;
        Map<String, dynamic>? jsonData = JsonUtils.decode(response?.body);
        if(jsonData != null){
          setState(() {
            _info = InboxUserInfo.fromJson(jsonData);
          });
        }
      } catch (e) {
        Log.e('Failed to load inbox user info');
        Log.e(e.toString());
      }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SimpleHeaderBarWithBack(
        context: context,
        titleWidget: Text(
          "Inbox User Info",
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.0),
        ),
      ),
      body: _loading
          ? Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              Text("Loading"),
            ],
          ),)
          : (_info != null ? SingleChildScrollView(
            child: _buildInboxUserInfo()) : Center(child:Text("Missing user info or user is not logged in yet"))),
    );
  }

  Widget _buildInboxUserInfo(){
    return _info != null ? Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("User ID"),
          Text(_info?.userId ?? ""),
          Container(height: 1, margin: EdgeInsets.symmetric(vertical: 4), color: Styles().colors!.lightGray,),
          Text("Date Created"),
          Text(_info?.dateCreated?.toIso8601String() ?? ""),
          Container(height: 1, margin: EdgeInsets.symmetric(vertical: 4), color: Styles().colors!.lightGray,),
          Text("Date Updated"),
          Text(_info?.dateUpdated?.toIso8601String() ?? ""),
          Container(height: 1, margin: EdgeInsets.symmetric(vertical: 4), color: Styles().colors!.lightGray,),
          Text("Topics"),
          Wrap(
            children: _info!.topics!.map((e) => Container(
              decoration: BoxDecoration(
                color: Styles().colors!.fillColorPrimary,
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              padding: EdgeInsets.all(8),
              margin: EdgeInsets.all(4),
              child: Text(e, style: TextStyle(color: Colors.white),),
            )).toList(),
          ),
          Container(height: 1, margin: EdgeInsets.symmetric(vertical: 4), color: Styles().colors!.lightGray,),
          Text("Tokens"),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _info!.firebaseTokens!.map((e) => Container(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.token!, style: TextStyle(fontFamily: Styles().fontFamilies!.bold),),
                  Text("Platform: ${e.appPlatform}", style: TextStyle(fontFamily: Styles().fontFamilies!.regular),),
                  Text("Version: ${e.appVersion}", style: TextStyle(fontFamily: Styles().fontFamilies!.regular),),
                  Text("Date created: ${e.dateCreated!.toIso8601String()}", style: TextStyle(fontFamily: Styles().fontFamilies!.regular),),
                  Container(height: 1, margin: EdgeInsets.symmetric(vertical: 4), color: Styles().colors!.lightGray,),
                ],
              ),
            )).toList(),
          )
        ],
      ),
    ) : Container();
  }
}

class InboxUserInfo{
  final String? userId;
  final List<FirebaseToken>? firebaseTokens;
  final List<String>? topics;
  final DateTime? dateCreated;
  final DateTime? dateUpdated;

  InboxUserInfo({this.userId, this.firebaseTokens, this.topics, this.dateCreated, this.dateUpdated});

  static InboxUserInfo? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? InboxUserInfo(
      userId: json['user_id'],
      firebaseTokens: json['firebase_tokens']?.map((e) => FirebaseToken.fromJson(e))?.toList(),
      topics:  json['topics']?.map((e) => e.toString())?.toList(),
      dateCreated: DateTimeUtils.dateTimeFromString(json['date_created']),
      dateUpdated: DateTimeUtils.dateTimeFromString(json['date_updated']),
    ) : null;
  }
}

class FirebaseToken{
  final String? token;
  final String? appPlatform;
  final String? appVersion;
  final DateTime? dateCreated;
  FirebaseToken({this.token, this.appPlatform, this.appVersion, this.dateCreated});

  static FirebaseToken? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? FirebaseToken(
      token: json['token'] ?? "",
      appPlatform: json['app_platform'] ?? "",
      appVersion: json['app_version'] ?? "",
      dateCreated: DateTimeUtils.dateTimeFromString(json['date_created'] ?? "", format: "yyyy-MM-ddTHH:mm:ssZ", isUtc: true),
    ) : null;
  }
}