
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/model/UserData.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/NotificationService.dart';
import 'package:illinois/service/Service.dart';
import 'package:illinois/service/User.dart';
import 'package:illinois/ui/onboarding/OnboardingLoginNetIdPanel.dart';
import 'package:illinois/ui/onboarding/OnboardingLoginPhonePanel.dart';

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

  void finish(BuildContext context) {

    NotificationService().notify(notifyFinished, context);
  }
  
  void proceedToLogin(BuildContext context){
    final UserData storedUserData = User().data;
    if(getPrivacyLevel>=3) {
      if (Auth2().prefs?.roles?.intersection(Set.from([UserRole.employee, UserRole.student]))?.isNotEmpty ?? false) { //Roles that requires NetId Login
        Navigator.push(context, CupertinoPageRoute(builder: (context) =>
            OnboardingLoginNetIdPanel(
              onboardingContext: {"onContinueAction": () {
                _proceedAfterLogin(storedUserData, context);
              }},
            )));
      } else { //Phone Login
        Navigator.push(context, CupertinoPageRoute(builder: (context) =>
            OnboardingLoginPhonePanel(
              onboardingContext: {"onContinueAction": () {
                _proceedAfterLogin(storedUserData, context);
              }
              },)));
      }
    } else { //Proceed without login
      _proceedAfterLogin(storedUserData, context);
    }
  }

  _proceedAfterLogin(UserData storedUserData, context){
    if(storedUserData?.privacyLevel!=null && storedUserData.privacyLevel>0) {
      User().privacyLevel = storedUserData.privacyLevel;
    }
//      Navigator.push(context, CupertinoPageRoute(
//          builder: (context) => Onboarding2PermissionsPanel()));

    finish(context);
  }

  void storeExploreCampusChoice(bool choice){
    Storage().onBoardingExploreCampus = choice;
  }

  void storePersonalizeChoice(bool choice){
    Storage().onBoardingPersonalizeChoice = choice;
  }

  void storeImproveChoice(bool choice){
    Storage().onBoardingImproveChoice = choice;
  }

  bool get getExploreCampusChoice{
    return Storage().onBoardingExploreCampus;
  }

  bool get getPersonalizeChoice{
    return Storage().onBoardingPersonalizeChoice;
  }

  bool get getImproveChoice{
    return Storage().onBoardingImproveChoice;
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