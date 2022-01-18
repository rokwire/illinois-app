
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/Styles.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/utils/Utils.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeSaferWellnessAnswerCenterPanel extends StatelessWidget{

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Styles().colors!.background,
      appBar: SimpleHeaderBarWithBack(
        context: context,
        titleWidget: Text(Localization().getStringEx("panel.home.safer.wellness_answer_center.header.title", "Wellness Answer Center")!,
          style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: Styles().fontFamilies!.extraBold),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                Localization().getStringEx("panel.home.safer.wellness_answer_center.label.description", "If you are having issues with the app or getting a test result, contact the Wellness Answer Center for assistance.")!,
                style: TextStyle(
                  fontFamily: Styles().fontFamilies!.regular,
                  fontSize: 16,
                  color: Styles().colors!.textSurface
                ),
              ),
              Container(height: 20,),
              RichText(
                textScaleFactor: MediaQuery.textScaleFactorOf(context),
                textAlign: TextAlign.start,
                text: TextSpan(
                  text: Localization().getStringEx("panel.home.safer.wellness_answer_center.label.email", "Email the Wellness Answer Center at "),
                  style: TextStyle(
                      fontFamily: Styles().fontFamilies!.regular,
                      fontSize: 16,
                      color: Styles().colors!.textSurface
                  ),
                  children: [
                    TextSpan(
                      text: this.displayEmail,
                      style: TextStyle(
                          fontFamily: Styles().fontFamilies!.regular,
                          fontSize: 16,
                          color: Styles().colors!.fillColorSecondary,
                          decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()..onTap = ()=>onEmailTapped(),
                    ),
                  ]
                ),
              ),
              Container(height: 20,),
              RichText(
                textScaleFactor: MediaQuery.textScaleFactorOf(context),
                textAlign: TextAlign.start,
                text: TextSpan(
                    text: Localization().getStringEx("panel.home.safer.wellness_answer_center.label.phone", "Phone the Answer Center at "),
                    style: TextStyle(
                        fontFamily: Styles().fontFamilies!.regular,
                        fontSize: 16,
                        color: Styles().colors!.textSurface
                    ),
                    children: [
                      TextSpan(
                        text: this.displayPhone,
                        style: TextStyle(
                          fontFamily: Styles().fontFamilies!.regular,
                          fontSize: 16,
                          color: Styles().colors!.fillColorSecondary,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()..onTap = ()=>onPhoneTapped(),
                      ),
                    ]
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get displayEmail {
    return Config().saferWellness['email']  ?? '';
  }

  void onEmailTapped(){
    String? email = Config().saferWellness['email'];
    if (StringUtils.isNotEmpty(email)) {
      launch('mailto:$email');
    }
  }

  String get displayPhone {
    String? displayPhone;
    String? phone = Config().saferWellness['phone'];
    if (StringUtils.isNotEmpty(phone)) {
      displayPhone = phone;
      if (displayPhone!.startsWith('+1')) {
        displayPhone = displayPhone.substring(2);
      }
      if (displayPhone.length == 10) {
        displayPhone = '${displayPhone.substring(0, 3)} ${displayPhone.substring(3, 6)}-${displayPhone.substring(6)}';
      }
    }
    return displayPhone ?? '';
  }

  void onPhoneTapped(){
    String? phone = Config().saferWellness['phone'];
    if (StringUtils.isNotEmpty(phone)) {
      launch('tel:$phone');
    }
  }
}