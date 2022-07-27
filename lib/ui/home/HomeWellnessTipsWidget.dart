import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/DeepLink.dart';
import 'package:illinois/service/Transportation.dart';
import 'package:illinois/service/Wellness.dart';
import 'package:illinois/ui/WebPanel.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:illinois/ui/wellness/WellnessHomePanel.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeWellnessTipsWidget extends StatefulWidget {
  
  final String? favoriteId;
  final StreamController<String>? updateController;

  HomeWellnessTipsWidget({Key? key, this.favoriteId, this.updateController}) : super(key: key);

  static Widget handle({String? favoriteId, HomeDragAndDropHost? dragAndDropHost, int? position}) =>
    HomeHandleWidget(favoriteId: favoriteId, dragAndDropHost: dragAndDropHost, position: position,
      title: title,
    );

  static String get title => Localization().getStringEx('widget.home.wellness.tips.title', 'DAILY TIPS');

  @override
  State<HomeWellnessTipsWidget> createState() => _HomeWellnessTipsWidgetState();
}

class _HomeWellnessTipsWidgetState extends State<HomeWellnessTipsWidget> implements NotificationsListener {

  Color? _tipColor;
  bool _loadingTipColor = false;
  
  @override
  void initState() {
    NotificationService().subscribe(this, [
      Wellness.notifyDailyTipChanged,
    ]);

    if (widget.updateController != null) {
      widget.updateController!.stream.listen((String command) {
        if (command == HomePanel.notifyRefresh) {
          if (mounted) {
            setState(() {
              _loadingTipColor = true;
            });

            Wellness().refreshDailyTip();

            Transportation().loadAlternateColor().then((Color? activeColor) {
              Wellness().refreshDailyTip();
              if (mounted) {
                setState(() {
                  if (activeColor != null) {
                    _tipColor = activeColor;
                  }
                  _loadingTipColor = false;
                });
              }
            });
          }
        }
      });
    }

    _loadingTipColor = true;
    Transportation().loadAlternateColor().then((Color? activeColor) {
      if (mounted) {
        setState(() {
          if (activeColor != null) {
            _tipColor = activeColor;
          }
          _loadingTipColor = false;
        });
      }
    });

    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  // NotificationsListener

  void onNotification(String name, dynamic param) {
    if (name == Wellness.notifyDailyTipChanged) {
      _updateTipColor();
    }
  }

  @override
  Widget build(BuildContext context) {
    return HomeSlantWidget(favoriteId: widget.favoriteId,
      title: HomeWellnessTipsWidget.title,
      titleIcon: Image.asset('images/campus-tools.png', excludeFromSemantics: true,),
      childPadding: HomeSlantWidget.defaultChildPadding,
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    return GestureDetector(onTap: _onTap, child:
      Container(decoration: BoxDecoration(boxShadow: [BoxShadow(color: Color.fromRGBO(19, 41, 75, 0.3), spreadRadius: 2.0, blurRadius: 8.0, offset: Offset(0, 2))]), child:
        ClipRRect(borderRadius: BorderRadius.all(Radius.circular(6)), child:
          Row(children: <Widget>[
            Expanded(child:
              Column(children: <Widget>[
                _loadingTipColor ? _buildLoading() : _buildTip()
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Container(color: Styles().colors?.white, child:
      Padding(padding: EdgeInsets.all(32), child:
        Row(children: <Widget>[
          Expanded(child:
            Center(child:
              SizedBox(height: 24, width: 24, child:
                CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color?>(_tipColor ?? Styles().colors?.fillColorSecondary), ),
              )
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildTip() {
    Color? textColor = Styles().colors?.fillColorPrimary;
    Color? backColor = Styles().colors?.white; // _tipColor ?? Styles().colors?.accentColor3;
    return Container(color: backColor, child:
      Padding(padding: EdgeInsets.all(16), child:
        Row(children: <Widget>[
          Expanded(child:
            Html(data: Wellness().dailyTip ?? '',
              onLinkTap: (url, context, attributes, element) => _launchUrl(url),
              style: { "body": Style(color: textColor, fontFamily: Styles().fontFamilies?.bold, fontSize: FontSize(16), padding: EdgeInsets.zero, margin: EdgeInsets.zero), },
            ),
          ),
        ]),
      ),
    );
  }

  void _onTap() {
    Analytics().logSelect(target: "View", source: widget.runtimeType.toString());
    Navigator.push(context, CupertinoPageRoute(builder: (context) => WellnessHomePanel(content: WellnessContent.dailyTips,)));
  }

  void _updateTipColor() {
    Transportation().loadAlternateColor().then((Color? activeColor) {
      if (mounted) {
        setState(() {
          if (activeColor != null) {
            _tipColor = activeColor;
          }
        });
      }
    });
  }

  void _launchUrl(String? url) {
    if (StringUtils.isNotEmpty(url)) {
      if (DeepLink().isAppUrl(url)) {
        DeepLink().launchUrl(url);
      }
      else if (UrlUtils.launchInternal(url)){
        Navigator.push(context, CupertinoPageRoute(builder: (context) => WebPanel(url: url)));
      }
      else{
        launch(url!);
      }
    }
  }

}
