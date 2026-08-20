
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:illinois/model/Analytics.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/DeepLink.dart';
import 'package:illinois/service/Wellness.dart';
import 'package:illinois/ui/gbv/GBVResourceDirectoryContentPanel.dart';
import 'package:illinois/ui/home/HomeSavedGBVResourcesWidget.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:illinois/ui/wellness/WellnessDailyTipsContentWidget.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class WellnessLinksPanel extends GBVResourceDirectoryContentPanel {
  WellnessLinksPanel() : super(
    headerBarTitle: Localization().getStringEx('panel.browse.entry.wellness.wellness_links.title', '24/7 Hotlines & Links'),
    contentWidgetBuilder: (context) => WellnessLinksWidget(),
    analyticsFeature: AnalyticsFeature.WellnessLinks,
  );
}

class WellnessLinksWidget extends StatelessWidget {

  WellnessLinksWidget();

  @override
  Widget build(BuildContext context) =>
    GBVResourceDirectoryContentWidget(
      contentCategory: 'wellness_links',
      contentAssetKey: 'assets/extra/wellnessLinks.json',
      favoriteKey: HomeSavedGBVResourcesWidget.favoriteKey,
      favoriteListner: HomeSavedGBVResourcesWidget.favoriteListener,
      contentFailedMessage: Localization().getStringEx('', 'Failed to load wellness links data'),
      prefixWidgetBuilder: (context) => _prefixWidget,
      suffixWidgetBuilder: (context) => _suffixWidget,
    );

  Widget get _prefixWidget =>
    Padding(padding: EdgeInsets.only(bottom: 16), child:
      WellnessLinksDailyTipWidget()
    );
  
  Widget get _suffixWidget =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Padding(padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4), child:
        _whereToStartButton,
      ),
      Padding(padding: EdgeInsets.only(top: 24, bottom: 16), child:
        Divider(color: Styles().colors.surfaceAccent, height: 1),
      ),
      Padding(padding: EdgeInsets.symmetric(horizontal: 4), child:
        WellnessLinksEightDimensionWidget(),
      ),
    ],);

  Widget get _whereToStartButton =>
      Semantics(label: _whereToStartTitle, hint: _whereToStartHint, button: true, image: true, child:
        InkWell(onTap: _onTapWhereToStart, child:
          Padding(padding: EdgeInsets.symmetric(vertical: 8), child:
            RichText(textAlign: TextAlign.left, text:
              TextSpan(style: Styles().textStyles.getTextStyle('panel.event.attendance.detail.description.italic'), children: [
                TextSpan(text: _whereToStartTitle, style: Styles().textStyles.getTextStyle('panel.event.attendance.detail.description.italic.underline'),),
                WidgetSpan(child:
                  Padding(padding: EdgeInsets.only(left: 6, bottom: 2), child:
                    Styles().images.getImage('external-link', size: 14, fit: BoxFit.contain) ?? Container(),
                  )
                )
              ]),
            ),
          ),
        ),
      );

  String get _whereToStartTitle => Localization().getStringEx('', 'Don’t know where to start?');
  String get _whereToStartHint => Localization().getStringEx('', 'Tap to see where to start');

  void _onTapWhereToStart() {
    Analytics().logSelect(target: 'Don’t know where to start?', source: runtimeType.toString());
    _launchUrl(Config().wellnessWhereToStartUrl);
  }

  void _launchUrl(String? url) {
    if ((url != null) && url.isNotEmpty) {
      if (DeepLink().isAppUrl(url)) {
        DeepLink().launchUrl(url);
      }
      else {
        AppLaunchUrl.launchExternal(url: url);
      }
    }
  }

}

class WellnessLinksDailyTipWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
    Container(decoration: _widgetDecoration, padding: EdgeInsets.all(16), child:
      Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          Expanded(child:
            Text(_title, style: _titleTextStyle),
          )
        ],),
        Padding(padding: EdgeInsets.only(top: 8), child:
          Container(decoration: _tipDecoration, padding: EdgeInsets.only(left: 12, top: 2, bottom: 2), child:
            Row(children: [
              Expanded(child:
                HtmlWidget(Wellness().dailyTip ?? '',
                  onTapUrl : (url) { _launchUrl(url); return true; },
                  textStyle:  _tipTextStyle,
                  customStylesBuilder: (element) => (element.localName == "a") ? {"color": ColorUtils.toHex(Styles().colors.fillColorSecondary)} : null,
                )
              )
            ],)
          )
        )

      ],),
    );

  void _launchUrl(String url) {
    if (DeepLink().isAppUrl(url)) {
      DeepLink().launchUrl(url);
    }
    else {
      AppLaunchUrl.launchExternal(url: url);
    }
  }

  String get _title => Localization().getStringEx('widget.home.wellness.tips.title', 'Daily Wellness Tip').toUpperCase();

  TextStyle? get _titleTextStyle => Styles().textStyles.getTextStyle("widget.title.small.fat");
  TextStyle? get _tipTextStyle => Styles().textStyles.getTextStyle("widget.detail.small");

  BoxDecoration get _widgetDecoration => BoxDecoration(
    color: Styles().colors.surface,
    border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
    borderRadius: BorderRadius.all(Radius.circular(8)),
    boxShadow: [HomeCard.boxShadow],
  );

  BoxDecoration get _tipDecoration => BoxDecoration(
    border: Border(left: BorderSide(color: Styles().colors.fillColorSecondary, width: 3),),
  );
}

class WellnessLinksEightDimensionWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Row(children: [
        _buildEightDimensionImage(context),
        Expanded(child:
          Padding(padding: EdgeInsets.only(left: 8), child:
            _eightDimensionHeading
          )
        ),
      ],),
      Padding(padding: EdgeInsets.symmetric(vertical: 16), child:
        Row(children: [
          Expanded(child:
            _eightDimensionDescriptionText,
          )
        ],),
      )
    ],);

  Widget _buildEightDimensionImage(BuildContext context) =>
    Semantics(label: Localization().getStringEx('panel.wellness.sections.dimensions.title', '8 Dimensions of Wellness'), hint: Localization().getStringEx('panel.wellness.sections.dimensions.hint', 'Tap to see the 8 Dimensions of Wellness'), button: true, image: true, child:
      InkWell(onTap: () => _onTapEightDimensionsImage(context), child:
        Styles().images.getImage('wellness-wheel-small', excludeFromSemantics: true,),
      ),
    );

  Widget get _eightDimensionHeading =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Row(children: [
        Expanded(child:
          _eightDimensionDescriptionTitle,
        )
      ],),
      Row(children: [
        Expanded(child:
          _eightDimensionDescriptionInfo,
        )
      ],),
    ],);

  Widget get _eightDimensionDescriptionTitle =>
    Text(Localization().getStringEx('panel.wellness.sections.dimensions.title', '8 Dimensions of Wellness').toUpperCase(), style: _titleTextStyle,);
  
  Widget get _eightDimensionDescriptionInfo =>
    Text(Localization().getStringEx('', '(tap on the image to enlarge)'), style:
      _regularTextStyle,
    );

  Widget get _eightDimensionDescriptionText =>
    RichText(textAlign: TextAlign.left, text:
      TextSpan(style: _regularTextStyle, children: [
        TextSpan(text: Localization().getStringEx('panel.wellness.sections.description.footer.wellness.text', 'Wellness '), style: _boldTextStyle),
        TextSpan(text: Localization().getStringEx('panel.wellness.sections.description.footer.description.text', 'is a state of optimal well-being that is oriented toward maximizing an individual\'s potential. This is a life-long process of moving towards enhancing your ')),
        TextSpan(text: Localization().getStringEx('panel.wellness.sections.description.footer.dimensions.text', 'physical, mental, environmental, financial, spiritual, vocational, emotional, and social wellness.'), style: _boldTextStyle)
      ]));
  
  TextStyle? get _titleTextStyle => Styles().textStyles.getTextStyle("widget.title.small.fat");
  TextStyle? get _regularTextStyle => Styles().textStyles.getTextStyle("widget.detail.small");
  TextStyle? get _boldTextStyle => Styles().textStyles.getTextStyle("widget.detail.small.fat");
      
  void _onTapEightDimensionsImage(BuildContext context) {
    Analytics().logSelect(target: '8 dimensions of Wellness', source: runtimeType.toString());
    showDialog(context: context, barrierDismissible: true, builder: (BuildContext context) => WellnessEightDimensionsPopup(),);
  }
}
