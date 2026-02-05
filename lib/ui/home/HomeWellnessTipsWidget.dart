import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/DeepLink.dart';
import 'package:illinois/service/Transportation.dart';
import 'package:illinois/service/Wellness.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:illinois/ui/wellness/WellnessHomePanel.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class HomeWellnessTipsWidget extends StatefulWidget {
  
  final String? favoriteId;
  final StreamController<String>? updateController;

  HomeWellnessTipsWidget({Key? key, this.favoriteId, this.updateController}) : super(key: key);

  static Widget handle({Key? key, String? favoriteId, HomeDragAndDropHost? dragAndDropHost, int? position}) =>
    HomeHandleWidget(key: key, favoriteId: favoriteId, dragAndDropHost: dragAndDropHost, position: position,
      title: title,
    );

  static String get title => Localization().getStringEx('widget.home.wellness.tips.title', 'Daily Wellness Tip');

  @override
  State<HomeWellnessTipsWidget> createState() => _HomeWellnessTipsWidgetState();
}

class _HomeWellnessTipsWidgetState extends State<HomeWellnessTipsWidget> with NotificationsListener {

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
    return HomeFavoriteWidget(favoriteId: widget.favoriteId,
      title: HomeWellnessTipsWidget.title,
      child: Padding(padding: HomeCard.defaultChildMargin,
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    return GestureDetector(onTap: _onTap, child:
      Container(decoration: HomeCard.boxDecoration, child:
        Row(children: <Widget>[
          Expanded(child:
            Column(children: <Widget>[
              _loadingTipColor ? _buildLoading() : _buildTip()
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildLoading() {
    return Padding(padding: EdgeInsets.all(32), child:
      Row(children: <Widget>[
        Expanded(child:
          Center(child:
            SizedBox(height: 24, width: 24, child:
              CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color?>(_tipColor ?? Styles().colors.fillColorSecondary), ),
            )
          ),
        ),
      ]),
    );
  }

  Widget _buildTip() {
    return Padding(padding: EdgeInsets.all(16), child:
      Row(children: <Widget>[
        Expanded(child:
          HtmlWidget(
              Wellness().dailyTip ?? '',
              onTapUrl : (url) {_launchUrl(url); return true;},
              textStyle:  Styles().textStyles.getTextStyle("widget.detail.small.semi_fat"),
          )
        ),
      ]),
    );
  }

  void _onTap() {
    Analytics().logSelect(target: "View", source: widget.runtimeType.toString());
    Navigator.push(context, CupertinoPageRoute(builder: (context) => WellnessHomePanel(contentType: WellnessContentType.dailyTips,)));
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
      else {
        AppLaunchUrl.launch(context: context, url: url);
      }
    }
  }

}
