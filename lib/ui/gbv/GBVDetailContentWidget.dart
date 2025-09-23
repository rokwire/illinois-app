import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/model/GBV.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:illinois/service/Analytics.dart';

class GBVDetailContentWidget extends StatelessWidget {
  final GBVResourceDetail resourceDetail;

  GBVDetailContentWidget({super.key, required this.resourceDetail});

  @override
  Widget build(BuildContext context) {
    return
      Row(children: _buildDetailContent(context, resourceDetail));
  }

  List<Widget> _buildDetailContent(BuildContext context, GBVResourceDetail detail) {
    switch (detail.type) {
      case GBVResourceDetailType.address:
        return [
          Styles().images.getImage('location', excludeFromSemantics: true) ?? Container(),
          Expanded(child:
            GestureDetector(
              onTap: () => _onTapAddress(detail.content),
              behavior: HitTestBehavior.translucent,
              child:
                Container(padding: EdgeInsets.only(left: 8, top: 12, bottom: 12), child:
                  Text(detail.content ?? '', style: Styles().textStyles.getTextStyle("widget.detail.small.underline")))
            )
          )
        ];
      case GBVResourceDetailType.email:
        Uri uri = Uri.parse('mailto:${detail.content}');
        return [
          Styles().images.getImage('envelope', excludeFromSemantics: true) ?? Container(),
          Expanded(child:
            GestureDetector(
              onTap: () => _onTapEmail(uri),
              behavior: HitTestBehavior.translucent,
              child:
                Container(padding: EdgeInsets.only(left: 8, top: 12, bottom: 12), child:
                  Text(detail.content ?? '', style: Styles().textStyles.getTextStyle("widget.detail.small.underline")))
            )
          )
        ];
      case GBVResourceDetailType.external_link:
        return [
          Styles().images.getImage('external-link', excludeFromSemantics: true) ?? Container(),
          Expanded(child:
            GestureDetector(
              onTap: () => _onTapExternalLink(context, detail.content),
              behavior: HitTestBehavior.translucent,
              child:
              Container(padding: EdgeInsets.only(left: 8, top: 12, bottom: 12), child:
                Text(detail.content ?? '', style: Styles().textStyles.getTextStyle("widget.detail.small.underline")))
            )
          )
        ];
      case GBVResourceDetailType.button:
        return [
          Expanded(child:
            Padding(padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12), child:
              RoundedButton(
                  label: detail.title ?? detail.content ?? '',
                  textStyle: Styles().textStyles.getTextStyle('widget.detail.regular.fat'),
                  rightIcon: Styles().images.getImage('external-link', excludeFromSemantics: true) ?? Container(),
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  onTap: () => _onTapButton(context, detail)
              )
            )
          )
        ];
      case GBVResourceDetailType.phone:
        Uri uri = Uri.parse('tel:${detail.content}');
        return [
          Styles().images.getImage('phone', excludeFromSemantics: true) ?? Container(),
            GestureDetector(
              onTap: () => _onTapPhone(uri),
              behavior: HitTestBehavior.translucent,
              child:
              Container(padding: EdgeInsets.only(left: 8, top: 12, bottom: 12), child:
                Text(detail.content ?? '', style: Styles().textStyles.getTextStyle("widget.detail.small.underline")))
          )
        ];
      case GBVResourceDetailType.text:
        return [
          Expanded(child:
            Container(padding: EdgeInsets.symmetric(vertical: 12), child:
              SelectableText(detail.content ?? '', style: Styles().textStyles.getTextStyle("widget.detail.small"))
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
    launchUrl(uri);
  }

  void _onTapExternalLink (BuildContext context, String? url) {
    Analytics().logSelect(target: 'Resource Detail - External link');
    AppLaunchUrl.launch(context: context, url: url);
  }

  void _onTapPhone (Uri uri) {
    Analytics().logSelect(target: 'Resource Detail - Phone');
    launchUrl(uri);
  }

  void _onTapButton (BuildContext context, GBVResourceDetail detail) {
    Analytics().logSelect(target: 'Resource Button - ${detail.title ?? detail.content}');
    AppLaunchUrl.launch(context: context, url: detail.content);
  }
}
