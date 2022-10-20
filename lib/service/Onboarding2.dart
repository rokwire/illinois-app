
import 'package:flutter/cupertino.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/ui/onboarding2/Onboarding2ResearchQuestionnairePanel.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:illinois/ui/onboarding/OnboardingAuthNotificationsPanel.dart';
import 'package:illinois/ui/onboarding/OnboardingLoginNetIdPanel.dart';
import 'package:illinois/ui/onboarding2/Onboarding2LoginPhoneOrEmailStatementPanel.dart';

import 'Storage.dart';

class Onboarding2 with Service{

  static const String notifyFinished  = "edu.illinois.rokwire.onboarding.finished";

  // Singleton Factory
  Onboarding2._internal();
  static final Onboarding2 _instance = Onboarding2._internal();

  factory Onboarding2() {
    return _instance;
  }

  Onboarding2 get instance {
    return _instance;
  }

  void finalize(BuildContext context) {
    _proceedToNotificationsAuthIfNeeded(context);
  }

  void _proceedToNotificationsAuthIfNeeded(BuildContext context) {
    Set<dynamic> codes = Set.from(FlexUI()['onboarding'] ?? []);
    if (codes.contains('notifications_auth')) {
      OnboardingAuthNotificationsPanel authNotificationsPanel = OnboardingAuthNotificationsPanel(onboardingContext:{
        'onContinueAction':  () {
          _didProceedNotificationsAuth(context);
        }
      });
      authNotificationsPanel.onboardingCanDisplayAsync.then((bool result) {
        if (result) {
          Navigator.push(context, CupertinoPageRoute(builder: (context) => authNotificationsPanel));
        }
        else {
          _didProceedNotificationsAuth(context);
        }
      });
    }
    else {
      _didProceedNotificationsAuth(context);
    }
  }

  void _didProceedNotificationsAuth(BuildContext context) {
    _proceedToLogin(context);
  }

  void _proceedToLogin(BuildContext context){
    Set<dynamic> codes = Set.from(FlexUI()['onboarding'] ?? []);
    if (codes.contains('login_netid')) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => OnboardingLoginNetIdPanel(onboardingContext: {
        "onContinueAction": () {
          _didProceedToLogin(context);
        }
      })));
    }
    else if (codes.contains('login_phone')) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => Onboarding2LoginPhoneOrEmailStatementPanel(onboardingContext: {
        "onContinueAction": () {
          _didProceedToLogin(context);
        }
      })));
    }
    else {
      _didProceedToLogin(context);
    }
  }

  void _didProceedToLogin(BuildContext context) {
      _proceedToDemographicsQuestionnaireIfNeeded(context);
  }

  void _proceedToDemographicsQuestionnaireIfNeeded(BuildContext context) {
    Set<dynamic> codes = Set.from(FlexUI()['onboarding'] ?? []);
    if (codes.contains('demographics_questionnaire')) {
      Onboarding2ResearchQuestionnairePanel.prompt(context).then((bool? result) {
        if (result == true) {
          Navigator.push(context, CupertinoPageRoute(builder: (context) => Onboarding2ResearchQuestionnairePanel(onboardingContext: {
            'onContinueAction':  () {
              _didProceedToDemographicsQuestionnaire(context);
            }
          },)));
        }
        else {
          _didProceedToDemographicsQuestionnaire(context);
        }
      });
    }
    else {
      _didProceedToDemographicsQuestionnaire(context);
    }
  }

  void _didProceedToDemographicsQuestionnaire(BuildContext context) {
    finish(context);
  }

  void finish(BuildContext context) {
    NotificationService().notify(notifyFinished, context);
  }
  
  void storeExploreCampusChoice(bool? choice){
    Storage().onBoardingExploreCampus = choice;
  }

  void storePersonalizeChoice(bool? choice){
    Storage().onBoardingPersonalizeChoice = choice;
  }

  void storeImproveChoice(bool? choice){
    Storage().onBoardingImproveChoice = choice;
  }

  bool get getExploreCampusChoice{
    return Storage().onBoardingExploreCampus ?? false;
  }

  bool get getPersonalizeChoice{
    return Storage().onBoardingPersonalizeChoice ?? false;
  }

  bool get getImproveChoice{
    return Storage().onBoardingImproveChoice ?? false;
  }

  int get getPrivacyLevel{
    //TBD refactoring
    int privacyLevel = -1;
    if(getExploreCampusChoice){
      if(getPersonalizeChoice){
        if(getImproveChoice){
          privacyLevel = 5;
        } else {
          //!getImproveChoice
          privacyLevel = 3;
        }
      }else {
        //!getPersonalizeChoice
        privacyLevel = 2;
      }
    } else {
      //!getExploreCampusChoice
      if(getPersonalizeChoice){
        if(getImproveChoice){
          privacyLevel = 5;
        } else {
          //!getImproveChoice
          privacyLevel = 3;
        }
      }else {
        //!getPersonalizeChoice
        privacyLevel = 1;
      }
    }

    return privacyLevel;
  }
}