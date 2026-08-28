import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/explore/ExploreMessagePopup.dart';
import 'package:illinois/ui/profile/ProfileHomePanel.dart';
import 'package:illinois/ui/profile/ProfileLoginEmailPanel.dart';
import 'package:illinois/ui/profile/ProfileLoginPhoneConfirmPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class ProfileLoginPhoneOrEmailPanel extends StatefulWidget {
  final SettingsLoginPhoneOrEmailMode mode;
  final String? identifier;
  final void Function()? onFinish;

  ProfileLoginPhoneOrEmailPanel({this.mode = SettingsLoginPhoneOrEmailMode.both, this.identifier, this.onFinish });

  _ProfileLoginPhoneOrEmailPanelState createState() => _ProfileLoginPhoneOrEmailPanelState();
}

class _ProfileLoginPhoneOrEmailPanelState extends State<ProfileLoginPhoneOrEmailPanel>  {

  TextEditingController? _phoneOrEmailController;

  String? _validationErrorMsg;
  String? _validationErrorDetails;
  GlobalKey _validationErrorKey = GlobalKey();

  bool _isLoading = false;

  @override
  void initState() {
    _phoneOrEmailController = TextEditingController(text: widget.identifier);
    super.initState();
  }

  @override
  void dispose() {
    _phoneOrEmailController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String title, description, headingTitle, headingHint, buttonProceedTitle, buttonProceedHint;
    TextInputType keyboardType;
    Widget? proceedRightIcon;
    
    if (widget.mode == SettingsLoginPhoneOrEmailMode.phone) {
      title = Localization().getStringEx('panel.settings.login.phone.label.title', 'Sign In with Mobile');
      description = Localization().getStringEx('panel.settings.login.phone.label.description', 'Enter your mobile phone number and receive a verification code via text message.');
      headingTitle = Localization().getStringEx('panel.settings.login.phone.label.heading', 'Mobile Phone Number:');
      headingHint = Localization().getStringEx('panel.settings.login.phone.label.heading.hint', '');
      buttonProceedTitle = Localization().getStringEx('panel.settings.login.phone.button.proceed.title', 'Proceed');
      buttonProceedHint = Localization().getStringEx('panel.settings.login.phone.button.proceed.hint', '');
      keyboardType = TextInputType.phone;
    }
    else if (widget.mode == SettingsLoginPhoneOrEmailMode.email){
      title = Localization().getStringEx('panel.settings.login.email.label.title', 'Sign In with Email');
      description = Localization().getStringEx('panel.settings.login.email.label.description', 'Enter your personal email address and follow the steps to sign in by email.');
      headingTitle = Localization().getStringEx('panel.settings.login.email.label.heading', 'Email Address:');
      headingHint = Localization().getStringEx('panel.settings.login.email.label.heading.hint', '');
      buttonProceedTitle = Localization().getStringEx('panel.settings.login.email.button.proceed.title', 'Proceed');
      buttonProceedHint = Localization().getStringEx('panel.settings.login.email.button.proceed.hint', '');
      keyboardType = TextInputType.emailAddress;
    }
    else {
      title = Localization().getStringEx('panel.settings.login.both.label.title', 'Sign In with Mobile or Email');
      description = Localization().getStringEx('panel.settings.login.both.label.description', 'Enter your mobile phone number and receive a verification code via text message OR enter your personal email address and follow the steps to sign in by email.');
      headingTitle = Localization().getStringEx('panel.settings.login.both.label.heading', 'Mobile Phone Number or Email Address:');
      headingHint = Localization().getStringEx('panel.settings.login.both.label.heading.hint', '');
      buttonProceedTitle = Localization().getStringEx('panel.settings.login.both.button.proceed.title', 'Proceed');
      buttonProceedHint = Localization().getStringEx('panel.settings.login.both.button.proceed.hint', '');
      keyboardType = TextInputType.emailAddress;
    }


    return Scaffold(
      appBar: HeaderBar(title: title,),
      body: Column(children: <Widget>[
        Expanded(child:
          SingleChildScrollView(scrollDirection: Axis.vertical, child:
            Padding(padding: EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(children:[
                HtmlWidget("<p>$description</p><p>$_signInWithNetIdInfo</p>",
                  onTapUrl : (url) { _onTapSignInWithNetIdLink(url); return true; },
                  textStyle:  Styles().textStyles.getTextStyle("widget.description.regular.thin"),
                  customStylesBuilder: (element) => _htmlStyleMap[element.localName?.toLowerCase()],
                ),
                Container(height: 24),
                Row(children: [ Expanded(child:
                  Text(headingTitle.toUpperCase(), style: Styles().textStyles.getTextStyle("widget.title.regular.fat"),)
                )],),
                Container(height: 6),
                Semantics(label: headingTitle, hint: headingHint, textField: true, excludeSemantics: true,
                  value: _phoneOrEmailController?.text,
                  child: Container(
                    color: (widget.identifier == null) ? Styles().colors.white : Styles().colors.background,
                    child: TextField(
                      controller: _phoneOrEmailController,
                      readOnly: widget.identifier != null,
                      autofocus: false,
                      autocorrect: false,
                      onSubmitted: (_) => _clearErrorMsg,
                      cursorColor: Styles().colors.textBackground,
                      keyboardType: keyboardType,
                      style: Styles().textStyles.getTextStyle("widget.input_field.text.medium"),
                      decoration: InputDecoration(
                        disabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Styles().colors.mediumGray, width: 1.0),),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Styles().colors.mediumGray, width: 1.0),),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Styles().colors.mediumGray, width: 1.0),),
                      ),
                    ),
                  ),
                ),
                Visibility(visible: StringUtils.isNotEmpty(_validationErrorMsg), child:
                  Padding(key: _validationErrorKey, padding: EdgeInsets.symmetric(vertical: 12), child:
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(StringUtils.ensureNotEmpty(_validationErrorMsg ?? ''), style: Styles().textStyles.getTextStyle("panel.settings.error.text")),
                      Visibility(visible: StringUtils.isNotEmpty(_validationErrorDetails), child:
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(StringUtils.ensureNotEmpty(_validationErrorDetails ?? ''), style: Styles().textStyles.getTextStyle("widget.detail.small")),
                        ),
                      ),
                    ],),
                  ),
                ),
                Container(height: 24),
                RoundedButton(
                  label: buttonProceedTitle,
                  hint: buttonProceedHint,
                  textStyle: Styles().textStyles.getTextStyle("widget.button.title.large.fat"),
                  onTap: _onTapProceed,
                  backgroundColor: Styles().colors.white,
                  borderColor: Styles().colors.fillColorSecondary,
                  rightIcon: proceedRightIcon,
                  iconPadding: 16,
                  progress: _isLoading,
                  contentWeight: 0.5,
                  padding: EdgeInsetsGeometry.symmetric(horizontal: 16, vertical: 6),
                ),
              ]),
            ),
          ),
        ),
        Container(height: 16,)
      ],),
      backgroundColor: Styles().colors.background,
      bottomNavigationBar: uiuc.TabBar(),
    );
  }

  static const String _localScheme = 'local';
  static const String _signInHost = 'signin';
  static const String _signInUrlMacro = '{{signin_url}}';
  static const String _signInUrl = '$_localScheme://$_signInHost';

  String get _signInWithNetIdInfo => Localization().getStringEx("panel.settings.login.label.info", "Once a NetID is issued, students and employees should <a href='{{signin_url}}'>Sign in with Your NetID</a> to access university features.").
    replaceAll(_signInUrlMacro, _signInUrl);

  Map<String, Map<String, String>> get _htmlStyleMap => {
    'a' : _htmlLinkStyle
  };

  Map<String, String> get _htmlLinkStyle => <String, String>{
    'color': _htmlTextColor,
    'text-decoration-color': _htmlLinkColor,
  };

  String get _htmlTextColor => ColorUtils.toHex(Styles().colors.fillColorPrimary);
  String get _htmlLinkColor => ColorUtils.toHex(Styles().colors.fillColorSecondary);

  void _onTapSignInWithNetIdLink(String? url) {
    Uri? uri = (url != null) ? Uri.tryParse(url) : null;
    if ((uri?.scheme == _localScheme) && (uri?.host == _signInHost)) {
      _signInWithNetId();
    }
  }

  void _signInWithNetId() {
    Analytics().logSelect(target: 'Sign in with Your NetID');
    if (ProfileHomePanel.state != null) {
      Navigator.of(context).popUntil((route) => (route.settings.name == ProfileHomePanel.routeName) || (route.isFirst));
      NotificationService().notify(ProfileHomePanel.notifySelectContent, [ ProfileContentType.login, ]);
    } else {
      Navigator.pop(context);
      ProfileHomePanel.present(context, contentType: ProfileContentType.login,);
    }
  }

  void _clearErrorMsg() {
    setState(() {
      _validationErrorMsg = null;
    });
  }
  
  void _onTapProceed() {
    String analyticsText, validationText;
    if (widget.mode == SettingsLoginPhoneOrEmailMode.phone) {
      analyticsText = 'Add Phone Number';
      validationText = Localization().getStringEx('panel.settings.login.phone.label.validation', 'Please enter your phone number.');
    }
    else if (widget.mode == SettingsLoginPhoneOrEmailMode.email){
      analyticsText = 'Add Email Address';
      validationText = Localization().getStringEx('panel.settings.login.email.label.validation', 'Please enter your email address.');
    }
    else {
      analyticsText = 'Add Phone or Email';
      validationText = Localization().getStringEx('panel.settings.login.both.label.validation', 'Please enter your phone number or email address.');
    }


    Analytics().logSelect(target: analyticsText);

    if (_isLoading != true) {
      _clearErrorMsg();

      String phoneOrEmailValue = _phoneOrEmailController!.text;
      String? phone, email;
      if (widget.mode == SettingsLoginPhoneOrEmailMode.phone || widget.mode == SettingsLoginPhoneOrEmailMode.both) {
        phone = _validatePhoneNumber(phoneOrEmailValue);
      }
      if (widget.mode == SettingsLoginPhoneOrEmailMode.email || widget.mode == SettingsLoginPhoneOrEmailMode.both) {
        email = StringUtils.isEmailValid(phoneOrEmailValue) ? phoneOrEmailValue : null;
      }

      if (StringUtils.isNotEmpty(phone)) {
        _loginByPhone(phone);
      }
      else if (StringUtils.isNotEmpty(email)) {
        if (AppEmail.isUniversityEmail(email!)) {
          _showUniversityEmailWarning();
        }
        else {
          _loginByEmail(email);
        }
      }
      else {
        setErrorMsg(validationText);
      }
    }
  }

  void _showUniversityEmailWarning() {
    final String netIdRef = 'net_id';
    String linkText = Localization().getStringEx('common.message.login.net_id_warning.link.net_id', 'sign in using NetID');
    String title = Localization().getStringEx('common.message.login.net_id_warning.title', "It looks like you're using an Illinois email address.");
    String message = Localization().getStringEx('common.message.login.net_id_warning.message',
        'Illinois students and employees should {{link_net_id}}. This ensures your university features, Illini ID, and personalized content are available.')
      .replaceAll('{{link_net_id}}', "<a href='$netIdRef'>$linkText</a>");
    String html = "<b>$title</b><br><br>$message";

    ExploreMessagePopup.show(context, html, onTapUrl: (String url) {
      if (url == netIdRef) {
        Analytics().logSelect(target: 'Sign in using NetID');
        Navigator.of(context).pop();
        Navigator.of(context).pop();
      }
      return true;
    });
  }

  void _loginByPhone(String? phoneNumber) {
    setState(() { _isLoading = true; });

    Auth2().authenticateWithPhone(phoneNumber).then((Auth2PhoneRequestCodeResult result) {
      _onPhoneInitiated(phoneNumber, result);
    });
  }

  void _onPhoneInitiated(String? phoneNumber, Auth2PhoneRequestCodeResult result) {
    if (mounted) {
      setState(() { _isLoading = false; });

      if (result == Auth2PhoneRequestCodeResult.succeeded) {
        Navigator.push(context, CupertinoPageRoute(builder: (context) => ProfileLoginPhoneConfirmPanel(phoneNumber: phoneNumber, onFinish: widget.onFinish)));
      } else if (result == Auth2PhoneRequestCodeResult.failedAccountExist) {
        setErrorMsg(Localization().getStringEx("panel.settings.login.phone.label.failed.exists", "An account is already using this phone number."),
            details: Localization().getStringEx("panel.settings.login.phone.label.failed.exists.detail", "1. You will need to sign in to the other account with this phone number.\n2. Go to \"Settings\" and press \"Forget all of my information\".\nYou can now use this as an alternate login."));
      } else {
        setErrorMsg(Localization().getStringEx("panel.settings.login.phone.label.failed", "Failed to send phone verification code. An unexpected error has occurred."));
      }
    }
  }

  void _loginByEmail(String? email) {
    setState(() { _isLoading = true; });

    Auth2().canSignIn(email, Auth2LoginType.email).then((bool? result) {
      if (mounted) {
        setState(() { _isLoading = false; });
        if (result != null) {
          Navigator.push(context, CupertinoPageRoute(builder: (context) => ProfileLoginEmailPanel(email: email,
              state: result ? Auth2EmailAccountState.verified : Auth2EmailAccountState.nonExistent, onFinish: widget.onFinish)));
        }
        else {
          setErrorMsg(Localization().getStringEx("panel.onboarding2.phone_or_email.email.failed", "Failed to verify email address."));
        }
      }
    });
  }

  void setErrorMsg(String? msg, {String? details}) {
    setState(() {
      _validationErrorMsg = msg;
      _validationErrorDetails = details;
    });

    if (StringUtils.isNotEmpty(msg)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_validationErrorKey.currentContext != null) {
          Scrollable.ensureVisible(_validationErrorKey.currentContext!, duration: Duration(milliseconds: 300)).then((_) {
          });
        }
      });
    }
  }

  static String? _validatePhoneNumber(String? phoneNumber) {
    if (kReleaseMode) {
      if (StringUtils.isUsPhoneValid(phoneNumber)) {
        phoneNumber = StringUtils.constructUsPhone(phoneNumber);
        if (StringUtils.isUsPhoneValid(phoneNumber)) {
          return phoneNumber;
        }
      }
    }
    else {
      if (StringUtils.isPhoneValid(phoneNumber)) {
        return phoneNumber;
      }
    }
    return null;
  }
}

enum SettingsLoginPhoneOrEmailMode {
  phone,
  email,
  both
}

String settingsLoginPhoneOrEmailModeToString(SettingsLoginPhoneOrEmailMode mode) {
  switch(mode) {
    case SettingsLoginPhoneOrEmailMode.phone: return 'phone';
    case SettingsLoginPhoneOrEmailMode.email: return 'email';
    case SettingsLoginPhoneOrEmailMode.both: return 'both';
  }
}