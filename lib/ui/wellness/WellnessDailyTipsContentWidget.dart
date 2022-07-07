/*
 * Copyright 2020 Board of Trustees of the University of Illinois.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/DeepLink.dart';
import 'package:illinois/service/Transportation.dart';
import 'package:illinois/service/Wellness.dart';
import 'package:illinois/ui/WebPanel.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

class WellnessDailyTipsContentWidget extends StatefulWidget {
  WellnessDailyTipsContentWidget();

  @override
  State<WellnessDailyTipsContentWidget> createState() => _WellnessDailyTipsContentWidgetState();
}

class _WellnessDailyTipsContentWidgetState extends State<WellnessDailyTipsContentWidget> implements NotificationsListener {
  Color? _tipColor;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, [
      Auth2.notifyLoginChanged,
      Wellness.notifyDailyTipChanged,
    ]);
    _loadTipColor();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  void _loadTipColor() {
    _setLoading(true);
    Transportation().loadAlternateColor().then((activeColor) {
      _tipColor = activeColor;
      _setLoading(false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return _loading ? _buildLoadingContent() : _buildContent();
  }

  Widget _buildContent() {
    return Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [_buildTipDescription(), _buildEightDimensionImage(), _buildFooterDescription(), _buildEightDimensionButton()]));
  }

  Widget _buildLoadingContent() {
    return Center(
        child: Column(children: <Widget>[
      Container(height: MediaQuery.of(context).size.height / 5),
      CircularProgressIndicator(),
      Container(height: MediaQuery.of(context).size.height / 5 * 3)
    ]));
  }

  Widget _buildTipDescription() {
    Color? textColor = Styles().colors!.white;
    Color? backColor = _tipColor ?? Styles().colors?.accentColor3;
    return Container(color: backColor, padding: EdgeInsets.all(42), child:
      Html(data: Wellness().dailyTip ?? '',
        onLinkTap: (url, context, attributes, element) => _launchUrl(url),
        style: {
          "body": Style(color: textColor, fontFamily: Styles().fontFamilies?.extraBold, fontSize: FontSize(22), padding: EdgeInsets.zero, margin: EdgeInsets.zero),
          "a": Style(color: textColor),
        },
      ),
    );
  }

  Widget _buildEightDimensionImage() {
    return Padding(padding: EdgeInsets.only(top: 16), child:
      Semantics(label: Localization().getStringEx('panel.wellness.sections.dimensions.title', '8 Dimensions of Wellness'), hint: Localization().getStringEx('panel.wellness.sections.dimensions.hint', 'Tap to see the 8 Dimensions of Wellness'), button: true, image: true, child:
        InkWell(onTap: _onTapEightDimensionsImage, child:
          Image.asset('images/wellness-wheel-2019.png', width: 45, height: 45),
        ),
      ),
    );
  }

  Widget _buildFooterDescription() {
    return Padding(
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
                style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 16, fontFamily: Styles().fontFamilies!.regular),
                children: [
                  TextSpan(
                      text: Localization().getStringEx('panel.wellness.sections.description.footer.wellness.text', 'Wellness '),
                      style: TextStyle(fontFamily: Styles().fontFamilies!.bold)),
                  TextSpan(
                      text: Localization().getStringEx('panel.wellness.sections.description.footer.description.text',
                          'is a state of optimal well-being that is oriented toward maximizing an individual\'s potential. This is a life-long process of moving towards enhancing your ')),
                  TextSpan(
                      text: Localization().getStringEx('panel.wellness.sections.description.footer.dimensions.text',
                          'physical, mental, environmental, financial, spiritual, vocational, emotional and social wellness.'),
                      style: TextStyle(fontFamily: Styles().fontFamilies!.bold))
                ])));
  }

  Widget _buildEightDimensionButton() {
    return RoundedButton(
        label: Localization().getStringEx('panel.wellness.sections.dimensions.button', 'Learn more about the 8 dimensions'),
        textStyle: TextStyle(fontSize: 14),
        rightIcon: Image.asset('images/external-link.png'),
        rightIconPadding: EdgeInsets.only(left: 4, right: 6),
        onTap: onTapEightDimension);
  }

  void _setLoading(bool loading) {
    _loading = loading;
    if (mounted) {
      setState(() {});
    }
  }

  static Widget _buildEightDimensionsPopup(BuildContext context) {
    return Dialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8),), child:
      ClipRRect(borderRadius: BorderRadius.all(Radius.circular(8)), child:
        Container(color: Color(0xfffffcdf), child:
          Stack(children: [
            Padding(padding: EdgeInsets.symmetric(vertical: 32), child:
              Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
                Row(children: [
                  Expanded(child:
                    Text(Localization().getStringEx('panel.wellness.sections.dimensions.title', '8 Dimensions of Wellness'), textAlign: TextAlign.center, style: TextStyle(color: Styles().colors!.fillColorSecondary, fontSize: 20, fontFamily: Styles().fontFamilies?.extraBold),),
                  ),
                ],),
                Container(height: 16),
                Image.asset('images/wellness-wheel-2019.png'),
              ],),
            ),
            Column(mainAxisSize: MainAxisSize.min, children: [
              Row(children: [
                Expanded(child: Container()),
                Semantics( label: Localization().getStringEx('dialog.close.title', 'Close'), hint: Localization().getStringEx('dialog.close.hint', ''), button: true, child:
                  InkWell(onTap : () => _onClosePopup(context), child:
                    Padding(padding: EdgeInsets.all(18), child: 
                      Image.asset('images/close-orange-small.png', semanticLabel: '',),
                    ),
                  ),
                ),
              ]),
            ],)
          ],)
        ),
      ),
    );
  }

  void onTapEightDimension() {
    Analytics().logSelect(target: 'Learn more about the 8 dimensions');
    if (StringUtils.isNotEmpty(Config().wellness8DimensionsUrl)) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => WebPanel(url: Config().wellness8DimensionsUrl, title: Localization().getStringEx('panel.wellness.sections.dimensions.title', '8 Dimensions of Wellness'),)));
    }
  }

  void _onTapEightDimensionsImage() {
    Analytics().logSelect(target: '8 dimensions of Wellness');
    showDialog(context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return _buildEightDimensionsPopup(context);
      },
    );
  }

  static void _onClosePopup(BuildContext context) {
    Analytics().logSelect(target: 'Close');
    Navigator.of(context).pop();
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

  // Notifications Listener

  @override
  void onNotification(String name, param) {
    if (name == Auth2.notifyLoginChanged) {
      _loadTipColor();
    }
    else if (name == Wellness.notifyDailyTipChanged) {
      if (mounted) {
        setState(() {
        });
      }
    }
  }
}
