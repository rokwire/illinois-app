
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:illinois/model/Analytics.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/Guide.dart';
import 'package:illinois/ui/WebPanel.dart';
import 'package:illinois/ui/safety/SafetyHomePanel.dart';
import 'package:illinois/ui/settings/SettingsHomeContentPanel.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:rokwire_plugin/service/deep_link.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/triangle_painter.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

class SafetySafeWalkRequestPage extends StatelessWidget with SafetyHomeContentPage {

  @override
  Widget build(BuildContext context) => Column(children: [
    _mainLayer,
    _detailsLayer(context),
  ],);

  @override
  Color get safetyPageBackgroundColor => Styles().colors.fillColorPrimaryVariant;
  
  Widget get _mainLayer => Container(color: safetyPageBackgroundColor, child:
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: EdgeInsets.only(left: 16, top: 32), child:
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child:
            Padding(padding: EdgeInsets.symmetric(vertical: 8), child:
              Text(Localization().getStringEx('panel.safewalks_request.header.title', 'SafeWalks'), style: _titleTextStyle,)
            ),
          ),
          InkWell(onTap: _onTapMore, child:
            Padding(padding: EdgeInsets.all(16), child:
              Styles().images.getImage('more-white', excludeFromSemantics: true)
            )
          )
        ],),
      ),
      Padding(padding: EdgeInsets.only(left: 16, right: 16, bottom: 16), child:
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_subTitle1Text, style: _subTitleTextStyle,),
          Text(_subTitle2Text, style: _subTitleTextStyle,),
          Container(height: 12,),
          Text(_info1Text, style: _infoTextStyle,),
          Text(_info2Text, style: _infoTextStyle,),
          Container(height: 6,),
          Text(_info3Text, style: _infoTextStyle,),
        ])
      ),
      Stack(children: [
        Positioned.fill(child:
          Column(children: [
            Expanded(child:
              Container()
            ),
            CustomPaint(painter: TrianglePainter(painterColor: Styles().colors.background, horzDir: TriangleHorzDirection.rightToLeft), child:
              Container(height: 42,),
            ),
          ],)
        ),
        Padding(padding: EdgeInsets.only(left: 16, right: 16), child:
          SafetySafeWalkRequestCard(),
        ),
      ],),
    ],)
  );

  Widget _detailsLayer(BuildContext context) => Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16,), child:
    Column( children: [
      HtmlWidget(_phoneDetailHtml,
        onTapUrl : (url) { _onTapLink(url, context: context, analyticsTarget: Config().safeWalkPhoneNumber); return true;},
        textStyle:  Styles().textStyles.getTextStyle("widget.message.small"),
        customStylesBuilder: (element) => (element.localName == "a") ? {"color": ColorUtils.toHex(Styles().colors.fillColorSecondary)} : null
      ),
      Container(height: 24,),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: EdgeInsets.only(right: 6), child:
          Styles().images.getImage('info') ?? _detailIconSpacer,
        ),
        Expanded(child:
          HtmlWidget(_safeRidesDetailHtml,
            onTapUrl : (url) { _onTapLink(url, context: context, analyticsTarget: 'SafeRides'); return true;},
            textStyle:  Styles().textStyles.getTextStyle("widget.message.small"),
            customStylesBuilder: (element) => (element.localName == "a") ? {"color": ColorUtils.toHex(Styles().colors.fillColorSecondary)} : null
          ),
        )
      ],),
      Row(children: [
        Padding(padding: EdgeInsets.only(right: 6), child:
          Styles().images.getImage('settings') ?? _detailIconSpacer,
        ),
        Expanded(child:
          InkWell(onTap: () => _onTapLocationSettings(context), child:
            Padding(padding: EdgeInsets.symmetric(vertical: 16), child:
              Text(Localization().getStringEx('panel.safewalks_request.detail.settings.text', 'My Location Settings'),
                style:  Styles().textStyles.getTextStyle("widget.button.title.small.underline"),
              ),
            )
          )
        )
      ],),
    ],)
  );

  Widget get _detailIconSpacer => SizedBox(width: 18, height: 18,);

  TextStyle? get _titleTextStyle => Styles().textStyles.getTextStyle('widget.heading.extra2_large.extra_fat');
  TextStyle? get _subTitleTextStyle => Styles().textStyles.getTextStyle('panel.safewalks_request.sub_title');
  TextStyle? get _infoTextStyle => Styles().textStyles.getTextStyle('panel.safewalks_request.info');

  static const String _safeWalkStartTimeMacro = '{{safewalk_start_time}}';
  static const String _safeWalkEndTimeMacro = '{{safewalk_end_time}}';
  static const String _safeWalkPhoneNumberMacro = '{{safewalk_phone_number}}';
  static const String _safeRidesUrlMacro = '{{saferides_url}}';
  static const String _externalLinkMacro = '{{external_link_icon}}';

  String get _subTitle1Text =>
    Localization().getStringEx('panel.safewalks_request.sub_title1.text', 'Trust your instincts.');

  String get _subTitle2Text =>
    Localization().getStringEx('panel.safewalks_request.sub_title2.text', 'You never have to walk alone.');

  String get _info1Text =>
    Localization().getStringEx('panel.safewalks_request.info1.text', 'Request a student patrol officer to walk with you.');

  String get _info2Text =>
    Localization().getStringEx('panel.safewalks_request.info2.text', 'Please give at least 15 minutes\' notice.');

  String get _info3Text =>
    Localization().getStringEx('panel.safewalks_request.info3.text', 'Available $_safeWalkStartTimeMacro to $_safeWalkEndTimeMacro')
      .replaceAll(_safeWalkStartTimeMacro, Config().safeWalkStartTime ?? '')
      .replaceAll(_safeWalkEndTimeMacro, Config().safeWalkEndTime ?? '');

  String get _phoneDetailHtml =>
    Localization().getStringEx('panel.safewalks_request.detail.phone.html', 'You can also schedule a walk by calling <a href=\'tel:$_safeWalkPhoneNumberMacro\'>$_safeWalkPhoneNumberMacro</a>.')
      .replaceAll(_safeWalkPhoneNumberMacro, Config().safeWalkPhoneNumber ?? '');

  String get _safeRidesDetailHtml =>
    Localization().getStringEx('panel.safewalks_request.detail.saferides.html', 'Looking for a ride instead? The Champaign-Urbana Mass Transit District offers limited <a href=\'$_safeRidesUrlMacro\'>SafeRides</a>&nbsp;<img src=\'asset:$_externalLinkMacro\' alt=\'\'/> at night..')
      .replaceAll(_safeRidesUrlMacro, Guide().detailUrl(Config().safeRidesGuideId, analyticsFeature: AnalyticsFeature.Safety))
      .replaceAll(_externalLinkMacro, 'images/external-link.png');

  void _onTapMore() {

  }

  void _onTapLocationSettings(BuildContext context) {
    Analytics().logSelect(target: Localization().getStringEx('panel.safewalks_request.detail.settings.text', 'My Location Settings', language: 'en'));
    SettingsHomeContentPanel.present(context, content: SettingsContent.maps);
  }

  void _onTapLink(String url, { required BuildContext context, String? analyticsTarget, bool launchInternal = false }) {
    Analytics().logSelect(target: analyticsTarget ?? url);
    if (url.isNotEmpty) {
      if (DeepLink().isAppUrl(url)) {
        DeepLink().launchUrl(url);
      }
      else if (launchInternal && UrlUtils.launchInternal(url)){
        Navigator.push(context, CupertinoPageRoute(builder: (context) => WebPanel(url: url)));
      }
      else {
        Uri? uri = Uri.tryParse(url);
        if (uri != null) {
          launchUrl(uri, mode: (Platform.isAndroid ? LaunchMode.externalApplication : LaunchMode.platformDefault));
        }
      }
    }
  }
}

class SafetySafeWalkRequestCard extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _SafetySafeWalkRequestCardState();
}

class _SafetySafeWalkRequestCardState extends State<SafetySafeWalkRequestCard> {
  @override
  Widget build(BuildContext context) => Container(decoration: _cardDecoration, height: 256,);

  BoxDecoration get _cardDecoration => BoxDecoration(
    color: Styles().colors.background,
    border: Border.all(color: Styles().colors.mediumGray2, width: 1),
    borderRadius: BorderRadius.all(Radius.circular(16))
  );
}
