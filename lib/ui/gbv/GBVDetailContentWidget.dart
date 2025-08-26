import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/model/GBV.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:url_launcher/url_launcher.dart';

class GBVDetailContentWidget extends StatelessWidget {
  final GBVResourceDetail resourceDetail;

  GBVDetailContentWidget({super.key, required this.resourceDetail});

  @override
  Widget build(BuildContext context) {
    return Padding(padding: EdgeInsets.symmetric(vertical: 8), child:
      Row(children: _buildDetailContent(context, resourceDetail))
    );
  }

  List<Widget> _buildDetailContent(BuildContext context, GBVResourceDetail detail) {
    switch (detail.type) {
      case GBVResourceDetailType.address:
        return [
          Styles().images.getImage('location', excludeFromSemantics: true) ?? Container(),
          Padding(padding: EdgeInsets.symmetric(horizontal: 4)),
          Expanded(child:
            GestureDetector(
              onTap: () => GeoMapUtils.launchLocation(detail.content),
              child: Text(detail.content ?? '', style: Styles().textStyles.getTextStyle("widget.detail.small.underline")))
          )
        ];
      case GBVResourceDetailType.email:
        Uri uri = Uri.parse('mailto:${detail.content}');
        return [
          Styles().images.getImage('envelope', excludeFromSemantics: true) ?? Container(),
          Padding(padding: EdgeInsets.symmetric(horizontal: 4)),
          Expanded(child:
            GestureDetector(
              onTap: () => launchUrl(uri),
              child: Text(detail.content ?? '', style: Styles().textStyles.getTextStyle("widget.detail.small.underline")))
          )
        ];
      case GBVResourceDetailType.external_link:
        return [
          Styles().images.getImage('external-link', excludeFromSemantics: true) ?? Container(),
          Padding(padding: EdgeInsets.symmetric(horizontal: 4)),
          Expanded(child:
            GestureDetector(
                onTap: () => AppLaunchUrl.launch(context: context, url: detail.content),
                child: Text(detail.content ?? '', style: Styles().textStyles.getTextStyle("widget.detail.small.underline")))
          )
        ];
      case GBVResourceDetailType.phone:
        Uri uri = Uri.parse('tel:${detail.content}');
        return [
          Styles().images.getImage('phone', excludeFromSemantics: true) ?? Container(),
          Padding(padding: EdgeInsets.symmetric(horizontal: 4)),
          Expanded(child:
            GestureDetector(
              onTap: () => launchUrl(uri),
              child: Text(detail.content ?? '', style: Styles().textStyles.getTextStyle("widget.detail.small.underline")))
          )
        ];
      case GBVResourceDetailType.text:
        return [
          Expanded(child:
            Text(detail.content ?? '', style: Styles().textStyles.getTextStyle("widget.detail.small"))
          )
        ];
    }
  }
}
