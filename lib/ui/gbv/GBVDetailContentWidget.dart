import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/model/GBV.dart';
import 'package:rokwire_plugin/service/styles.dart';

class GBVDetailContentWidget extends StatelessWidget {
  final GBVResourceDetail resourceDetail;

  GBVDetailContentWidget({super.key, required this.resourceDetail});

  @override
  Widget build(BuildContext context) {
    return Padding(padding: EdgeInsets.symmetric(vertical: 8), child:
      Row(children: _buildDetailContent(resourceDetail))
    );
  }

  List<Widget> _buildDetailContent(GBVResourceDetail detail) {
    switch (detail.type) {
      case GBVResourceDetailType.address:
        return [
          Styles().images.getImage('location', excludeFromSemantics: true) ?? Container(),
          Padding(padding: EdgeInsets.symmetric(horizontal: 4)),
          Expanded(child:
            GestureDetector(child: Text(detail.content ?? ''))
          )
        ];
      case GBVResourceDetailType.email:
        return [
          Styles().images.getImage('envelope', excludeFromSemantics: true) ?? Container(),
          Padding(padding: EdgeInsets.symmetric(horizontal: 4)),
          Expanded(child:
            GestureDetector(child: Text(detail.content ?? ''))
          )
        ];
      case GBVResourceDetailType.external_link:
        return [
          Styles().images.getImage('external-link', excludeFromSemantics: true) ?? Container(),
          Padding(padding: EdgeInsets.symmetric(horizontal: 4)),
          Expanded(child:
            GestureDetector(child: Text(detail.content ?? ''))
          )
        ];
      case GBVResourceDetailType.phone:
        return [
          Styles().images.getImage('phone', excludeFromSemantics: true) ?? Container(),
          Padding(padding: EdgeInsets.symmetric(horizontal: 4)),
          Expanded(child:
            GestureDetector(child: Text(detail.content ?? ''))
          )
        ];
      case GBVResourceDetailType.text:
        return [
          Expanded(child:
            GestureDetector(child: Text(detail.content ?? ''))
          )
        ];
    }
  }
}
