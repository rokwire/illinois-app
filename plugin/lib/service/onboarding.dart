/*
 * Copyright 2020 Board of Trustees of the University of Illinois.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:flutter/cupertino.dart';
import 'package:rokwire_plugin/service/flex_ui.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';

class Onboarding with Service implements NotificationsListener {

  static const String notifyFinished  = "edu.illinois.rokwire.onboarding.finished";

  List<dynamic>? _contentCodes;

  // Singletone Factory

  static Onboarding? _instance;

  static Onboarding? get instance => _instance;
  
  @protected
  static set instance(Onboarding? value) => _instance = value;

  factory Onboarding() => _instance ?? (_instance = Onboarding.internal());

  @protected
  Onboarding.internal();


  // Service

  @override
  void createService() {
    NotificationService().subscribe(this,[
      FlexUI.notifyChanged,
    ]);
  }

  @override
  void destroyService() {
    NotificationService().unsubscribe(this);
  }

  @override
  Future<void> initService() async {
    _contentCodes = loadContent();
    await super.initService();
  }

  @override
  Set<Service> get serviceDependsOn {
    return { FlexUI() };
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == FlexUI.notifyChanged) {
      _contentCodes = loadContent();
    }
  }

  // Implementation

  @protected
  String get flexUIEntry => 'onboarding';

  @protected
  List<dynamic>? loadContent() => FlexUI()[flexUIEntry];


  Widget? get startPanel {
    for (int index = 0; index < _contentCodes!.length; index++) {
      OnboardingPanel? nextPanel = createPanel(code: _contentCodes![index], context: {});
      if ((nextPanel != null) && (nextPanel is Widget) && nextPanel.onboardingCanDisplay && (nextPanel is Widget)) {
        return nextPanel as Widget;
      }
    }
    return null;
  }

  void next(BuildContext context, OnboardingPanel panel, {bool replace = false}) {
    nextPanel(panel).then((dynamic nextPanel) {
      if (nextPanel is Widget) {
        if (replace) {
          Navigator.pushReplacement(context, CupertinoPageRoute(builder: (context) => nextPanel));
        }
        else {
          Navigator.push(context, CupertinoPageRoute(builder: (context) => nextPanel));
        }
      }
      else if ((nextPanel is bool) && !nextPanel) {
        finish(context);
      }
    });
  }

  void finish(BuildContext context) {
    NotificationService().notify(notifyFinished, context);
  }

  @protected
  Future<dynamic> nextPanel(OnboardingPanel? panel) async {
    if (_contentCodes != null) {
      int? nextPanelIndex;
      if (panel == null) {
        nextPanelIndex = 0;
      }
      else {
        String? panelCode = getPanelCode(panel: panel);
        int panelIndex = _contentCodes!.indexOf(panelCode);
        if (0 <= panelIndex) {
          nextPanelIndex = panelIndex + 1;
        }
      }

      if (nextPanelIndex != null) {
        while (nextPanelIndex! < _contentCodes!.length) {
          String? nextPanelCode = _contentCodes![nextPanelIndex];
          OnboardingPanel? nextPanel = createPanel(code: nextPanelCode, context: panel?.onboardingContext ?? {});
          if ((nextPanel != null) && (nextPanel is Widget) && nextPanel.onboardingCanDisplay && await nextPanel.onboardingCanDisplayAsync) {
            return nextPanel as Widget;
          }
          else {
            nextPanelIndex++;
          }
        }
        return false;
      }
    }
    return null;
  }

  @protected
  OnboardingPanel? createPanel({String? code, Map<String, dynamic>? context}) => null;

  @protected
  String? getPanelCode({OnboardingPanel? panel}) => null;
}

abstract class OnboardingPanel {
  
  Map<String, dynamic>? get onboardingContext {
    return null;
  }
  
  bool get onboardingCanDisplay {
    return true;
  }

  Future<bool> get onboardingCanDisplayAsync async {
    return true;
  }
}