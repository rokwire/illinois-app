
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:html/dom.dart' as dom;
import 'package:illinois/service/DeepLink.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class OnboardingMessagePanel extends StatelessWidget {
  final String? title;
  final String? titleHtml;
  final String? message;
  final String? messageHtml;
  final Widget? footer;

  OnboardingMessagePanel({Key? key,
    this.title, this.titleHtml,
    this.message, this.messageHtml,
    this.footer
  }) :
    super(key: key);

  @override
  Widget build(BuildContext context) =>
    Scaffold(backgroundColor: Styles().colors.background, body:
      Column(children: <Widget>[
        Styles().images.getImage('header-login', fit: BoxFit.fitWidth, width: MediaQuery.of(context).size.width, excludeFromSemantics: true,) ?? Container(),
        Expanded(child:
          SafeArea(child:
            Padding(padding: EdgeInsets.symmetric(horizontal: 42), child:
              _contentWidget(context),
            )
          )
        )
      ],)
    );

  Widget _contentWidget(BuildContext context) {

    Widget? titleWidget;
    if (titleHtml != null) {
      titleWidget = HtmlWidget(
        titleHtml ?? "",
        onTapUrl : (url) => _onTapLink(context, url),
        textStyle:  _titleTextStyle,
        customStylesBuilder: _getHtmlStyle,
      );
    }
    else if (title != null) {
      titleWidget = Text(title ?? '', textAlign: TextAlign.center, style: _titleTextStyle,);
    }

    Widget? messageWidget;
    if (messageHtml != null) {
      messageWidget = HtmlWidget(
        messageHtml ?? "",
        onTapUrl : (url) => _onTapLink(context, url),
        textStyle: _messageTextStyle,
        customStylesBuilder: _getHtmlStyle,
      );
    }
    else if (message != null) {
      messageWidget = Text(message ?? '', textAlign: TextAlign.center, style: _messageTextStyle);
    }

    return Column(children: <Widget>[
      Expanded(flex: 1, child: Container()),

      if (titleWidget != null)
        titleWidget,

      if ((titleWidget != null) && (messageWidget != null))
        Expanded(flex: 1, child: Container()),

      if (messageWidget != null)
        messageWidget,

      Expanded(flex: 3, child: Container()),

      if (footer != null)
        footer ?? Container(),
    ]);
  }

  TextStyle get _titleTextStyle =>
    TextStyle(fontFamily: Styles().fontFamilies.bold, fontSize: 32, color: Styles().colors.fillColorPrimary);

  TextStyle get _messageTextStyle =>
    TextStyle(fontFamily: Styles().fontFamilies.regular, fontSize: 20, color: Styles().colors.fillColorPrimary,);

  Map<String, String>? _getHtmlStyle(dom.Element element) {
    if (element.localName == "a") {
      return {
        "text-decoration": "underline",
        "text-decoration-color": ColorUtils.toHex(Styles().colors.fillColorSecondary),
        "color": ColorUtils.toHex(Styles().colors.fillColorSecondary),
      };
    }
    else if (element.localName == "body") {
      return { "text-align": "center" };
    }
    else {
      return null;
    }
  }

  bool _onTapLink(BuildContext context, String? url, { bool? useInternalBrowser }) {
    if (StringUtils.isNotEmpty(url)) {
      if (DeepLink().isAppUrl(url)) {
        DeepLink().launchUrl(url);
      }
      else {
        // use internal browser but only if allowed
        AppLaunchUrl.launch(context: context, url: url, tryInternal: (useInternalBrowser == true));
      }
    }
    return true;
  }
}
