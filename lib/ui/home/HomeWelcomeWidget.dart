import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/model/Video.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:illinois/ui/settings/SettingsVideoTutorialPanel.dart';
import 'package:illinois/ui/widgets/VideoPlayButton.dart';
import 'package:rokwire_plugin/service/assets.dart';
import 'package:rokwire_plugin/service/config.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class HomeWelcomeWidget extends StatefulWidget {
  final String? favoriteId;
  final StreamController<String>? updateController;

  HomeWelcomeWidget({Key? key, this.favoriteId, this.updateController}) : super(key: key);

  static Widget handle({Key? key, String? favoriteId, HomeDragAndDropHost? dragAndDropHost, int? position}) =>
    HomeHandleWidget(key: key, favoriteId: favoriteId, dragAndDropHost: dragAndDropHost, position: position,
      title: Localization().getStringEx("widget.home_create_poll.heading.title", "Polls"),
    );

  @override
  State<HomeWelcomeWidget> createState() => _HomeWelcomeWidgetState();
}

class _HomeWelcomeWidgetState extends State<HomeWelcomeWidget> {
  Video? _video;
  bool? _visible;

  @override
  void initState() {
    super.initState();
    _visible = Storage().homeWelcomeVisible;
    _loadVideo();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _loadVideo() {
    Map<String, dynamic>? videoTutorials = JsonUtils.mapValue(Assets()['video_tutorials']);
    if (videoTutorials != null) {
      String? welcomeVideoId;
      Map<String, dynamic>? welcomeMap = videoTutorials['welcome'];
      String? envKey = configEnvToString(Config().configEnvironment);
      if (StringUtils.isNotEmpty(envKey)) {
        welcomeVideoId = welcomeMap?[envKey];
      }
      if (StringUtils.isNotEmpty(welcomeVideoId)) {
        List<dynamic>? videos = JsonUtils.listValue(videoTutorials['videos']);
        if (CollectionUtils.isNotEmpty(videos)) {
          for (dynamic video in videos!) {
            String? videoId = video['id'];
            if (videoId == welcomeVideoId) {
              Map<String, dynamic>? strings = JsonUtils.mapValue(videoTutorials['strings']);
              String? videoTitle = Localization().getContentString(strings, videoId);
              video['title'] = videoTitle;
              _video = Video.fromJson(video);
              break;
            }
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Visibility(visible: _visible ?? true, child:
      Container(color: Styles().colors?.fillColorPrimary, child:
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Container(height: 1, color: Styles().colors?.disabledTextColor),
          Row(children: [
            Expanded(child:
              Padding(padding: EdgeInsets.only(left: 16), child:
                Text(Localization().getStringEx("widget.home.welcome.text.title", 'Welcome to {{app_title}} {{app_version}}').
                  replaceAll('{{app_title}}', Localization().getStringEx('app.title', 'Illinois')).
                  replaceAll('{{app_version}}', Config().appMasterVersion ?? ''),
                  style: TextStyle(color: Styles().colors!.textColorPrimary, fontFamily: Styles().fontFamilies!.extraBold, fontSize: 20, ),),
              ),
            ),
            Semantics(label: Localization().getStringEx('widget.home.welcome.button.close.label', 'Close'), button: true, excludeSemantics: true, child:
              InkWell(onTap : _onClose, child:
                Padding(padding: EdgeInsets.all(16), child:
                  Styles().images?.getImage('close-circle-white', excludeFromSemantics: true)
                ),
              ),
            ),
          ],),
          Padding(padding: EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 16), child: 
            _buildVideoEntry()
          ),
          Container(height: 1, color: Styles().colors?.disabledTextColor),
        ],),
      )
    );
  }

  Widget _buildVideoEntry() {
    if (_video == null) {
      return Container();
    }
    final Widget emptyImagePlaceholder = Container(height: 102);
    return GestureDetector(
        onTap: _onTapVideo,
        child: Semantics(
            button: true,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Stack(alignment: Alignment.center, children: [
                Container(
                    foregroundDecoration: BoxDecoration(color: Styles().colors!.blackTransparent06),
                    child: StringUtils.isNotEmpty(_video!.thumbUrl)
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                                child: Image.network(_video!.thumbUrl!,
                                    loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                              return (loadingProgress == null) ? child : emptyImagePlaceholder;
                            }))
                        : emptyImagePlaceholder),
                VideoPlayButton(hasBackground: false)
              ])
            ])));
  }

  void _onTapVideo() {
    if (_video != null) {
      Analytics().logSelect(target: 'Video Tutorial', source: widget.runtimeType.toString(), attributes: _video!.analyticsAttributes);
      Navigator.push(context, CupertinoPageRoute(builder: (context) => SettingsVideoTutorialPanel(videoTutorial: _video!)));
    }
  }

  void _onClose() {
    Analytics().logSelect(target: "Close", source: widget.runtimeType.toString());
    setState(() {
      Storage().homeWelcomeVisible = _visible = false;
    });
  }
}
