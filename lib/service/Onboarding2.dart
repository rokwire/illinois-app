
import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:illinois/model/Questionnaire.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/service/Questionnaire.dart';
import 'package:illinois/ui/onboarding2/Onboarding2ProfileInfoPanel.dart';
import 'package:illinois/ui/onboarding2/Onboarding2ResearchQuestionnaireAcknowledgementPanel.dart';
import 'package:illinois/ui/onboarding2/Onboarding2ResearchQuestionnairePromptPanel.dart';
import 'package:illinois/ui/onboarding2/Onboarding2ResearchQuestionnairePanel.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:illinois/ui/onboarding/OnboardingAuthNotificationsPanel.dart';
import 'package:illinois/ui/onboarding/OnboardingLoginNetIdPanel.dart';
import 'package:illinois/ui/onboarding2/Onboarding2LoginPhoneOrEmailStatementPanel.dart';


class Onboarding2 with Service {

  static const String notifyFinished  = "edu.illinois.rokwire.onboarding.finished";

  // Singleton Factory
  Onboarding2._internal();
  static final Onboarding2 _instance = Onboarding2._internal();
  factory Onboarding2() => _instance;

  // Privacy Selection
  bool privacyLocationServicesSelection = true;
  bool privacyPersonalizeSelection = true;
  bool privacyImproveSelection = true;

  void finalize(BuildContext context) =>
    _proceedToNotificationsAuthIfNeeded(context);

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
        },
        "onContinueActionEx": (dynamic state) {
          _didProceedToLogin(context, currentPanelState: state);
        }
      })));
    }
    else if (codes.contains('login_phone')) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => Onboarding2LoginPhoneOrEmailStatementPanel(onboardingContext: {
        "onContinueAction": () {
          _didProceedToLogin(context);
        },
        "onContinueActionEx": (dynamic state) {
          _didProceedToLogin(context, currentPanelState: state);
        }
      })));
    }
    else {
      _didProceedToLogin(context);
    }
  }

  void _didProceedToLogin(BuildContext context, { dynamic currentPanelState}) {
    _proceedToProfileInfoIfNeeded(context, currentPanelState: currentPanelState);
  }

  void _proceedToProfileInfoIfNeeded(BuildContext context, { dynamic currentPanelState }) {
    Set<dynamic> codes = Set.from(FlexUI()['onboarding'] ?? []);
    if (codes.contains('profile_info')) {
      Navigator.push(context, CupertinoPageRoute<bool>(builder: (context) => Onboarding2ProfileInfoPanel(onboardingContext: {
        'onContinueAction': () => _didProceedProfileInfo(context),
        'onContinueActionEx': (state) => _didProceedProfileInfo(context, currentPanelState: state),
      },)));
    }
    else {
      _didProceedProfileInfo(context, currentPanelState: currentPanelState);
    }
  }

  void _didProceedProfileInfo(BuildContext context, { dynamic currentPanelState}) {
    Set<dynamic> codes = Set.from(FlexUI()['onboarding'] ?? []);
    if (codes.contains('profile_info')) {
      _startResearhQuestionnaireIfNeeded(context, currentPanelState: currentPanelState);
    }
    else {
      _didFinishResearhQuestionnaire(context);
    }
  }

  void _startResearhQuestionnaireIfNeeded(BuildContext context, { dynamic currentPanelState }) {
    if (Questionnaires().participateInResearch == true) {
      Onboarding2ProgressableState? progressableState = (currentPanelState is Onboarding2ProgressableState) ? currentPanelState : null;
      progressableState?.onboarding2Progress = true;
      Questionnaires().loadResearch().then((Questionnaire? questionnaire) {
        progressableState?.onboarding2Progress = false;
        Map<String, LinkedHashSet<String>>? questionnaireAnswers = Auth2().profile?.getResearchQuestionnaireAnswers(questionnaire?.id);
        if (questionnaireAnswers?.isNotEmpty ?? false) {
          _didFinishResearhQuestionnaire(context);
        }
        else {
          _promptForResearhQuestionnaire(context, questionanire: questionnaire);
        }
      });
    }
    else {
      _promptForResearhQuestionnaire(context);
    }
  }

  void _promptForResearhQuestionnaire(BuildContext context, { Questionnaire? questionanire }) {
    Navigator.push(context, CupertinoPageRoute<bool>(builder: (context) => researhQuestionnairePromptPanel(questionanire: questionanire)));
  }

  Widget researhQuestionnairePromptPanel({ Questionnaire? questionanire, Map<String, dynamic>? invocationContext}) {
    return Onboarding2ResearchQuestionnairePromptPanel(onboardingContext: {
      "onConfirmActionEx": (BuildContext context) {
        _proceedToResearhQuestionnaire(context, questionanire: questionanire, invocationContext: invocationContext);
      },
      "onRejectActionEx": (BuildContext context) {
        _didFinishResearhQuestionnaire(context, invocationContext: invocationContext);
      }
    });
  }
  
  void _proceedToResearhQuestionnaire(BuildContext context, { Questionnaire? questionanire, Map<String, dynamic>? invocationContext }) {
    Navigator.push(context, CupertinoPageRoute(builder: (context) => Onboarding2ResearchQuestionnairePanel(onboardingContext: {
      "questionanire": questionanire,
      'onContinueAction':  () {
        _didProceedResearchQuestionnaire(context, invocationContext: invocationContext);
      }
    },)));
  }

  void _didProceedResearchQuestionnaire(BuildContext context, { Map<String, dynamic>? invocationContext }) {
    _acknowledgeResearhQuestionnaire(context, invocationContext: invocationContext);
  }

  void _acknowledgeResearhQuestionnaire(BuildContext context, { Map<String, dynamic>? invocationContext }) {
    Navigator.push(context, CupertinoPageRoute(builder: (context) => Onboarding2ResearchQuestionnaireAcknowledgementPanel(onboardingContext: {
      'onContinueAction':  () {
        _didAcknowledgeResearhQuestionnaire(context, invocationContext: invocationContext);
      }
    },)));
  }

  void _didAcknowledgeResearhQuestionnaire(BuildContext context, { Map<String, dynamic>? invocationContext }) {
    _didFinishResearhQuestionnaire(context, invocationContext: invocationContext);
  }

  void _didFinishResearhQuestionnaire(BuildContext context, { Map<String, dynamic>? invocationContext }) {
    Function? onFinish = (invocationContext != null) ? invocationContext["onFinishResearhQuestionnaireAction"] : null;
    Function? onFinishEx = (invocationContext != null) ? invocationContext["onFinishResearhQuestionnaireActionEx"] : null;
    if (onFinishEx != null) {
      onFinishEx(context);
    }
    else if (onFinish != null) {
      onFinish();
    }
    else {
      finish(context);
    }
  }

  void finish(BuildContext context) {
    NotificationService().notify(notifyFinished, context);
  }
  

  int get getPrivacyLevel{
    //TBD refactoring
    int privacyLevel = -1;
    if (privacyLocationServicesSelection){
      if (privacyPersonalizeSelection){
        if(privacyImproveSelection){
          privacyLevel = 5;
        } else {
          //!privacyImprove
          privacyLevel = 3;
        }
      }else {
        //!getPersonalizeChoice
        privacyLevel = 2;
      }
    } else {
      //!privacyEnableLocationServices
      if(privacyPersonalizeSelection){
        if(privacyImproveSelection){
          privacyLevel = 5;
        } else {
          //!privacyImprove
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

abstract class Onboarding2ProgressableState {
  bool get onboarding2Progress;
  set onboarding2Progress(bool progress);
}