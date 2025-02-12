
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class SignedOutWidget extends StatefulWidget {

  static const String featureTextMacro = "{{feature.text}}";
  static const String loginLinkMacro = "{{login.link}}";

  final String messageText;
  final TextStyle? messageTextStyle;

  final String loginText;
  final String loginMacro;
  final TextStyle? loginTextStyle;
  final Function()? onLogin;

  final String featureText;
  final String featureMacro;
  final TextStyle? featureTextStyle;
  final Function()? onFeature;

  final TextAlign textAlign;
  final EdgeInsetsGeometry padding;

  SignedOutWidget({super.key,
    String? message, TextStyle? messageTextStyle,
    String? feature, TextStyle? featureTextStyle, this.featureMacro = featureTextMacro, this.onFeature,
    String? login, TextStyle? loginTextStyle, this.loginMacro = featureTextMacro, this.onLogin,
    this.textAlign = TextAlign.left,
    this.padding = const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
  }) :
    loginText = login ?? Localization().getStringEx("auth.signed_out.feature.not_available.message.link.login", "sign in"),
    featureText = feature ?? Localization().getStringEx("auth.signed_out.feature.not_available.message.text.feature", "this feature"),
    messageText = message ?? Localization().getStringEx("auth.signed_out.feature.not_available.message", "To access $featureMacro, you need to $loginMacro with your NetID under Profile and set your privacy level to 4 or 5 under Settings."),

    messageTextStyle = messageTextStyle ?? Styles().textStyles.getTextStyle("widget.message.dark.regular"),
    featureTextStyle = featureTextStyle ?? messageTextStyle ?? Styles().textStyles.getTextStyle("widget.message.dark.regular"),
    loginTextStyle = loginTextStyle ??  Styles().textStyles.getTextStyle("widget.link.button.title.regular");

  @override
  State<StatefulWidget> createState() => _SignedOutWidgetState();
}

class _SignedOutWidgetState extends State<SignedOutWidget> {

  GestureRecognizer? _loginRecognizer;
  GestureRecognizer? _featureRecognizer;

  @override
  void initState() {
    _loginRecognizer = TapGestureRecognizer()..onTap = _onTapLogin;
    _featureRecognizer = TapGestureRecognizer()..onTap = _onTapFeature;
    super.initState();
  }

  @override
  void dispose() {
    _loginRecognizer?.dispose();
    _featureRecognizer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<InlineSpan> spanList = StringUtils.split<InlineSpan>(widget.messageText,
      macros: [widget.featureMacro, widget.loginMacro],
      builder: (String entry) {
        if (entry == widget.featureMacro) {
          return TextSpan(text: widget.featureText, style: widget.featureTextStyle, recognizer: (widget.onFeature != null) ? _featureRecognizer : null,);
        }
        else if (entry == widget.loginMacro) {
          return TextSpan(text: widget.loginText, style: widget.loginTextStyle, recognizer: (widget.onLogin != null) ? _loginRecognizer : null,);
        }
        else {
          return TextSpan(text: entry);
        }
      }
    );

    return Container(padding: widget.padding, child:
      RichText(textAlign: widget.textAlign, text:
        TextSpan(style: widget.messageTextStyle, children: spanList)
      )
    );
  }

  void _onTapLogin() {
    if (widget.onLogin != null) {
      Analytics().logSelect(target: widget.loginText); //TBD: widget.featureText.en
      widget.onLogin?.call();
    }
  }

  void _onTapFeature() {
    if (widget.onFeature != null) {
      Analytics().logSelect(target: widget.featureText); //TBD: widget.featureText.en
      widget.onFeature?.call();
    }
  }
}