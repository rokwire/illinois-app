import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:illinois/model/GBV.dart';
import 'package:illinois/service/DeepLink.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:illinois/service/Analytics.dart';

class GBVDetailContentWidget extends StatelessWidget {
  final GBVResourceDetail resourceDetail;
  final bool isTextSelectable;

  final CardDisplayMode displayMode;
  bool get _homeDisplayMode => (displayMode == CardDisplayMode.home);

  GBVDetailContentWidget(this.resourceDetail, {super.key, this.isTextSelectable = true, this.displayMode = CardDisplayMode.browse });

  @override
  Widget build(BuildContext context) => Row(children:
    _buildDetailContent(context, resourceDetail)
  );

  List<Widget> _buildDetailContent(BuildContext context, GBVResourceDetail detail) {
    switch (detail.type) {

      case GBVResourceDetailType.address:
        return [
          Container(padding: EdgeInsets.only(right: 8), child:
            Styles().images.getImage('location', excludeFromSemantics: true) ?? Container(),
          ),
          if (detail.contentPrefix != null)
            Text(detail.contentPrefix ?? '', style: Styles().textStyles.getTextStyle("widget.detail.small")),
          Expanded(child:
            GestureDetector(
              onTap: () => _onTapAddress(detail.content),
              behavior: HitTestBehavior.translucent,
              child:
                Container(padding: EdgeInsets.symmetric(vertical: 12), child:
                  Text(detail.content ?? '', style: Styles().textStyles.getTextStyle("widget.detail.small.underline"), maxLines: _homeDisplayMode ? 1 : null, overflow: TextOverflow.ellipsis,))
            )
          )
        ];

      case GBVResourceDetailType.email:
        Uri uri = Uri.parse('mailto:${detail.content}');
        return [
          Container(padding: EdgeInsets.only(right: 8), child:
            Styles().images.getImage('envelope', excludeFromSemantics: true) ?? Container(),
          ),
          if (detail.contentPrefix != null)
            Text(detail.contentPrefix ?? '', style: Styles().textStyles.getTextStyle("widget.detail.small")),
          Expanded(child:
            GestureDetector(
              onTap: () => _onTapEmail(uri),
              behavior: HitTestBehavior.translucent,
              child:
                Container(padding: EdgeInsets.symmetric(vertical: 12), child:
                  Text(detail.content ?? '', style: Styles().textStyles.getTextStyle("widget.detail.small.underline"), maxLines: _homeDisplayMode ? 1 : null, overflow: TextOverflow.ellipsis,))
            )
          )
        ];

      case GBVResourceDetailType.external_link:
      case GBVResourceDetailType.internal_link:
        return [
          Container(padding: EdgeInsets.only(right: 8), child:
            Styles().images.getImage('external-link', excludeFromSemantics: true) ?? Container(),
          ),
          if (detail.contentPrefix != null)
            Text(detail.contentPrefix ?? '', style: Styles().textStyles.getTextStyle("widget.detail.small")),
          Expanded(child:
            GestureDetector(
              onTap: () => _onTapExternalLink(context, detail.content),
              behavior: HitTestBehavior.translucent,
              child:
              Container(padding: EdgeInsets.symmetric(vertical: 12), child:
                Text(detail.content ?? '', style: Styles().textStyles.getTextStyle("widget.detail.small.underline"), maxLines: _homeDisplayMode ? 3 : null, overflow: TextOverflow.ellipsis,))
            )
          )
        ];

      case GBVResourceDetailType.button:
        return [
          Expanded(child:
            Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12), child:
              RoundedButton(
                  label: detail.title ?? detail.content ?? '',
                  textStyle: Styles().textStyles.getTextStyle('widget.detail.regular.fat'),
                  textAlign: TextAlign.center,
                  rightIcon: Styles().images.getImage('external-link', excludeFromSemantics: true) ?? Container(),
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  onTap: () => _onTapButton(context, detail)
              )
            )
          )
        ];

      case GBVResourceDetailType.phone:
        Uri uri = Uri.parse('tel:${detail.content}');
        return [
          Container(padding: EdgeInsets.only(right: 8), child:
            Styles().images.getImage('phone', excludeFromSemantics: true) ?? Container(),
          ),
          if (detail.contentPrefix != null)
            Text(detail.contentPrefix ?? '', style: Styles().textStyles.getTextStyle("widget.detail.small")),
          GestureDetector(
            onTap: () => _onTapPhone(uri),
            behavior: HitTestBehavior.translucent,
            child:
            Container(padding: EdgeInsets.symmetric(vertical: 12), child:
              Text(detail.content ?? '', style: Styles().textStyles.getTextStyle("widget.detail.small.underline"), maxLines: _homeDisplayMode ? 1 : null, overflow: TextOverflow.ellipsis,))
          )
        ];

      case GBVResourceDetailType.text:
        String textContent = detail.content ?? '';
        TextStyle? textStyle = Styles().textStyles.getTextStyle("widget.detail.small");
        bool isHtml = StringUtils.containsHtmlTags(textContent);
        Widget contentWidget = isHtml ? HtmlWidget('<div>$textContent</div>',
          textStyle: textStyle,
          customStylesBuilder: (element) => _htmlContentStyles[element.localName],
          onTapUrl: (String url) => _onTapHtmlLink(context, url),
        ) : Text(textContent,
          style: textStyle,
          maxLines: _homeDisplayMode ? 3 : null,
          overflow: _homeDisplayMode ? TextOverflow.ellipsis : null,
        );

        double verticalPadding = 12;
        BoxConstraints? htmlConstraints = (_homeDisplayMode && isHtml) ?
          BoxConstraints(maxHeight: MediaQuery.of(context).textScaler.scale(textStyle?.fontSize ?? 0) * 1.5 * 3 + 2 * verticalPadding) : null;

        return [
          Expanded(child:
            Container(padding: EdgeInsets.symmetric(vertical: verticalPadding), constraints: htmlConstraints, child:
              isTextSelectable ? SelectionArea(child: contentWidget) : contentWidget,
            )
          )
        ];
    }
  }

  void _onTapAddress (String? address) {
    Analytics().logSelect(target: 'Resource Detail - Email');
    GeoMapUtils.launchLocation(address);
  }

  void _onTapEmail (Uri uri) {
    Analytics().logSelect(target: 'Resource Detail - Email');
    launchUrl(uri, mode: LaunchMode.externalApplication).catchError((e) { debugPrint(e.toString()); return false; });
  }

  void _onTapExternalLink (BuildContext context, String? url) {
    Analytics().logSelect(target: 'Resource Detail - External link');
    AppLaunchUrl.launch(context: context, url: url);
  }

  void _onTapPhone (Uri uri) {
    Analytics().logSelect(target: 'Resource Detail - Phone');
    launchUrl(uri, mode: LaunchMode.externalApplication)..catchError((e) { debugPrint(e.toString()); return false; });
  }

  void _onTapButton (BuildContext context, GBVResourceDetail detail) {
    Analytics().logSelect(target: 'Resource Button - ${detail.title ?? detail.content}');
    AppLaunchUrl.launchExternal(url: detail.content);
  }

  Map<String, Map<String, String>> get _htmlContentStyles => {
    'a' : _htmlLinkStyle,
    if (_homeDisplayMode)
      'div' : _htmlLimitTextStyle,
  };

  Map<String, String> get _htmlLimitTextStyle => <String, String>{
    'line-clamp': '3',
    //'text-overflow': 'ellipsis',
  };

  Map<String, String> get _htmlLinkStyle => <String, String>{
    // 'color': _htmlLinkColor,
    'text-decoration-color': _htmlLinkColor,
  };

  String get _htmlLinkColor =>
    ColorUtils.toHex(Styles().colors.fillColorSecondary);

  bool _onTapHtmlLink(BuildContext context, String url)  {
    Analytics().logSelect(target: 'Link: $url');
    if (DeepLink().isAppUrl(url)) {
      DeepLink().launchUrl(url);
    } else {
      AppLaunchUrl.launchExternal(url: url);
    }
    return true;
  }
}
