
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/localization.dart';
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
            Semantics(container: true, child:
              Padding(padding: EdgeInsets.all(30), child:
                Column(crossAxisAlignment: CrossAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
                  Styles().images.getImage('university-logo') ?? Container(),
                  Semantics(label: message, focused: true, excludeSemantics: true, container: true, child:
                    Padding(padding: EdgeInsets.only(top: 20), child:
                      // Text(message, textAlign: TextAlign.center, style: Styles().textStyles.getTextStyle("widget.detail.small")
                      HtmlWidget(message,
                          onTapUrl: (url) => (onTapUrl != null) ? onTapUrl!(url) : false,
                          textStyle: Styles().textStyles.getTextStyle("widget.detail.small"),
                          customStylesBuilder: (element) => (element.localName == "a") ? {"color": ColorUtils.toHex(Styles().colors.fillColorSecondary)} : null
                        )
                      )
                  )
                ])
              )
            ),
            Positioned.fill(child:
              Align(alignment: Alignment.topRight, child:
                Semantics(label: "close", button: true, container: true, child:
                  InkWell(onTap: () => _onClose(context, message), child:
                    Padding(padding: EdgeInsets.all(16), child:
                      Styles().images.getImage("close-circle", excludeFromSemantics: true)
                    )
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

/////////////////////////
// ExploreOptionalMessagePopup

class ExploreOptionalMessagePopup extends StatefulWidget {
  final String message;
  final String? showPopupStorageKey;
  final bool Function(String url)? onTapUrl;
  ExploreOptionalMessagePopup({Key? key, required this.message, this.showPopupStorageKey, this.onTapUrl}) : super(key: key);

  @override
  State<ExploreOptionalMessagePopup> createState() => _ExploreOptionalMessagePopupState();
}

class _ExploreOptionalMessagePopupState extends State<ExploreOptionalMessagePopup> {
  bool? showInstructionsPopup;

  @override
  void initState() {
    showInstructionsPopup = (widget.showPopupStorageKey != null) ? Storage().getBoolWithName(widget.showPopupStorageKey!) : null;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    String dontShow = Localization().getStringEx("panel.explore.instructions.mtd.dont_show.msg", "Don't show me this again.");

    return AlertDialog(contentPadding: EdgeInsets.zero, content:
      Container(decoration: BoxDecoration(color: Styles().colors.white, borderRadius: BorderRadius.circular(10.0)), child:
        Stack(alignment: Alignment.center, children: [
          Padding(padding: EdgeInsets.only(top: 36, bottom: 9), child:
            Column(mainAxisSize: MainAxisSize.min, children: [
              Padding(padding: EdgeInsets.symmetric(horizontal: 32), child:
                Column(children: [
                  Styles().images.getImage('university-logo', excludeFromSemantics: true) ?? Container(),
                  Padding(padding: EdgeInsets.only(top: 18), child:
                    //Text(widget.message, textAlign: TextAlign.left, style: Styles().textStyles.getTextStyle("widget.detail.small"))
                    HtmlWidget(widget.message,
                      onTapUrl: (url) => (widget.onTapUrl != null) ? widget.onTapUrl!(url) : false,
                      textStyle: Styles().textStyles.getTextStyle("widget.detail.small"),
                      customStylesBuilder: (element) => (element.localName == "a") ? {"color": ColorUtils.toHex(Styles().colors.fillColorSecondary)} : null
                    )
                  )
                ]),
              ),

              Visibility(visible: (widget.showPopupStorageKey != null), child:
                Padding(padding: EdgeInsets.only(left: 16, right: 32), child:
                  Semantics(
                      label: dontShow,
                      value: showInstructionsPopup == false ?   Localization().getStringEx("toggle_button.status.checked", "checked",) : Localization().getStringEx("toggle_button.status.unchecked", "unchecked"),
                      button: true,
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      InkWell(
                        onTap: (){
                          AppSemantics.announceCheckBoxStateChange(context,  /*reversed value*/!(showInstructionsPopup == false), dontShow);
                          _onDoNotShow();
                          },
                        child: Padding(padding: EdgeInsets.all(16), child:
                          Styles().images.getImage((showInstructionsPopup == false) ? "check-circle-filled" : "check-circle-outline-gray"),
                        ),
                      ),
                      Expanded(child:
                        Text(dontShow, style: Styles().textStyles.getTextStyle("widget.detail.small"), textAlign: TextAlign.left,semanticsLabel: "",)
                      ),
                  ])),
                ),
              ),
            ])
          ),
          Positioned.fill(child:
            Align(alignment: Alignment.topRight, child:
              Semantics(  button: true, label: "close",
              child: InkWell(onTap: () {
                Analytics().logSelect(target: 'Close MTD instructions popup');
                Navigator.of(context).pop();
                }, child:
                Padding(padding: EdgeInsets.all(16), child:
                  Styles().images.getImage('close-circle', excludeFromSemantics: true)
                )
              ))
            )
          ),
        ])
     )
    );
  }

  void _onDoNotShow() {
    setState(() {
      if (widget.showPopupStorageKey != null) {
        Storage().setBoolWithName(widget.showPopupStorageKey!, showInstructionsPopup = (showInstructionsPopup == false));
      }
    });
  }
}

