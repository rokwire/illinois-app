import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/model/GBV.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:url_launcher/url_launcher.dart';

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
              onTap: () => GeoMapUtils.launchLocation(detail.content),
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
              onTap: () => launchUrl(uri),
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
              onTap: () => AppLaunchUrl.launch(context: context, url: detail.content),
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
                  onTap: () => AppLaunchUrl.launch(context: context, url: detail.content)
              )
            )
          )
        ];
      case GBVResourceDetailType.phone:
        Uri uri = Uri.parse('tel:${detail.content}');
        return [
          Styles().images.getImage('phone', excludeFromSemantics: true) ?? Container(),
            GestureDetector(
              onTap: () => launchUrl(uri),
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
              Text(detail.content ?? '', style: Styles().textStyles.getTextStyle("widget.detail.small"))
            )
          )
        ];
    }
  }
}
