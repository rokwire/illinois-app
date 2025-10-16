
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class ExploreMessagePopup extends StatelessWidget {
  final String message;
  final bool Function(String url)? onTapUrl;
  ExploreMessagePopup({super.key, required this.message, this.onTapUrl});

  static Future<void> show(BuildContext context, String message, { bool Function(String url)? onTapUrl}) =>
    showDialog(context: context, builder: (context) => ExploreMessagePopup(message: message, onTapUrl: onTapUrl));

  @override
  Widget build(BuildContext context) =>
    AlertDialog(contentPadding: EdgeInsets.zero, content:
      Container(decoration: BoxDecoration(color: Styles().colors.white, borderRadius: BorderRadius.circular(10.0)), child:
        Stack(alignment: Alignment.center, fit: StackFit.loose, children: [
          Padding(padding: EdgeInsets.all(30), child:
            Column(crossAxisAlignment: CrossAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
              Styles().images.getImage('university-logo') ?? Container(),
              Padding(padding: EdgeInsets.only(top: 20), child:
                // Text(message, textAlign: TextAlign.center, style: Styles().textStyles.getTextStyle("widget.detail.small")
                HtmlWidget(message,
                  onTapUrl: (url) => (onTapUrl != null) ? onTapUrl!(url) : false,
                  textStyle: Styles().textStyles.getTextStyle("widget.detail.small"),
                  customStylesBuilder: (element) => (element.localName == "a") ? {"color": ColorUtils.toHex(Styles().colors.fillColorSecondary)} : null
                )
              )
            ])
          ),
          Positioned.fill(child:
            Align(alignment: Alignment.topRight, child:
              InkWell(onTap: () => _onClose(context, message), child:
                Padding(padding: EdgeInsets.all(16), child:
                  Styles().images.getImage("close-circle")
                )
              )
            )
          )
        ])
      )
    );

  void _onClose(BuildContext context, String message) {
    Analytics().logAlert(text: message, selection: 'Close');
    Navigator.of(context).pop();
  }
}

