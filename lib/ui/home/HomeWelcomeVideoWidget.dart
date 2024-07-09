import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:neom/model/Video.dart';
import 'package:neom/service/Analytics.dart';
import 'package:neom/service/Content.dart';
import 'package:neom/service/Storage.dart';
import 'package:neom/ui/apphelp/AppHelpVideoTutorialPanel.dart';
import 'package:neom/ui/widgets/VideoPlayButton.dart';
import 'package:neom/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/config.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class HomeWelcomeVideoWidget extends StatefulWidget {
  final String? favoriteId;
  final StreamController<String>? updateController;

  HomeWelcomeVideoWidget({Key? key, this.favoriteId, this.updateController}) : super(key: key);

  @override
  State<HomeWelcomeVideoWidget> createState() => _HomeWelcomeVideoWidgetState();
}

class _HomeWelcomeVideoWidgetState extends State<HomeWelcomeVideoWidget> implements NotificationsListener {
  Video? _video;
  bool? _visible;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Content.notifyVideoTutorialsChanged,
    ]);

    _visible = Storage().homeWelcomeVideoVisible;
    _video = _loadVideo();
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == Content.notifyVideoTutorialsChanged) {
      setStateIfMounted(() {
        _video ??= _loadVideo();
      });
    }
  }

  Video? _loadVideo() {
    Map<String, dynamic>? videoTutorials = Content().videoTutorials;
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
              return Video.fromJson(video);
            }
          }
        }
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Visibility(visible: _visible ?? true, child:
      Container(color: Styles().colors.fillColorPrimary, child:
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Container(height: 1, color: Styles().colors.disabledTextColor),
          Row(children: [
            Expanded(child:
              Padding(padding: EdgeInsets.only(left: 16), child:
                Text(Localization().getStringEx("widget.home.welcome_video.title.text", 'Welcome to {{app_title}} {{app_version}}').
                  replaceAll('{{app_title}}', Localization().getStringEx('app.title', 'Illinois')).
                  replaceAll('{{app_version}}', Config().appMajorVersion ?? ''),
                  style: Styles().textStyles.getTextStyle("widget.title.light.large.extra_fat")),
              ),
            ),
            Semantics(label: Localization().getStringEx('dialog.close.title', 'Close'), button: true, excludeSemantics: true, child:
              InkWell(onTap : _onClose, child:
                Padding(padding: EdgeInsets.all(16), child:
                  Styles().images.getImage('close-circle-white', excludeFromSemantics: true)
                ),
              ),
            ),
          ],),
          Padding(padding: EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 16), child: 
            _buildVideoEntry()
          ),
          Container(height: 1, color: Styles().colors.disabledTextColor),
        ],),
      )
    );
  }

  Widget get emptyImagePlaceholder => imagePlaceholder(); //Container(height: 102);

  Widget imagePlaceholder({ Widget? child}) =>
    AspectRatio(aspectRatio: (8000.0 / 4500.0), child:
      Container(color: Styles().colors.fillColorPrimary, child: child,)
    );

  Widget _buildVideoEntry() {
    if (_video == null) {
      return emptyImagePlaceholder;
    }
    return GestureDetector(onTap: _onTapVideo, child:
      Semantics(button: true, child:
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Stack(alignment: Alignment.center, children: [
            StringUtils.isNotEmpty(_video!.thumbUrl) ?
              ClipRRect(borderRadius: BorderRadius.circular(4), child:
                Image.network(_video!.thumbUrl!, loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                  return imagePlaceholder(child: (loadingProgress != null) ? Center(child:
                    CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors.surface), )
                  ) : child);
                })
              ) :
              emptyImagePlaceholder,
            VideoPlayButton(hasBackground: false)
          ])
        ])
      )
    );
  }

  void _onTapVideo() {
    if (_video != null) {
      Analytics().logSelect(target: 'Video Tutorial', source: widget.runtimeType.toString(), attributes: _video!.analyticsAttributes);
      Navigator.push(context, CupertinoPageRoute(builder: (context) => AppHelpVideoTutorialPanel(videoTutorial: _video!)));
    }
  }

  void _onClose() {
    Analytics().logSelect(target: "Close", source: widget.runtimeType.toString());
    setState(() {
      Storage().homeWelcomeVideoVisible = _visible = false;
    });
  }
}
