
import 'package:flutter/material.dart';
import 'package:illinois/service/NotificationService.dart';
import 'package:illinois/service/Service.dart';

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

  void storeExploreCampusChoice(bool choice){
    //TBD
  }

  void storePersonalizeChoice(bool choice){
    //TBD
  }

  void storeImproveChoice(bool choice){
    //TBD
  }

  bool get getExploreCampusChoice{
    //TBD
    return true;
  }

  bool get getPersonalizeChoice{
    //TBD
    return true;
  }

  bool get getImproveChoice{
    //TBD
    return true;
  }

  int get getPrivacyLevel{
    //TBD
    return 3;
  }
}