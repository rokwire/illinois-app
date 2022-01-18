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

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/utils/Utils.dart';

class AppAlert {
  
  static Future<bool?> showDialogResult(
    BuildContext builderContext, String? message) async {
    bool? alertDismissed = await showDialog(
      context: builderContext,
      builder: (context) {
        return AlertDialog(
          content: Text(message!),
          actions: <Widget>[
            TextButton(
                child: Text(Localization().getStringEx("dialog.ok.title", "OK")!),
                onPressed: () {
                  Analytics.instance.logAlert(text: message, selection: "Ok");
                  Navigator.pop(context, true);
                }
            ) //return dismissed 'true'
          ],
        );
      },
    );
    return alertDismissed;
  }

  static Future<bool?> showCustomDialog(
    {required BuildContext context, Widget? contentWidget, List<Widget>? actions, EdgeInsets contentPadding = const EdgeInsets.all(18), }) async {
    bool? alertDismissed = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(content: contentWidget, actions: actions,contentPadding: contentPadding,);
      },
    );
    return alertDismissed;
  }

  static Future<bool?> showOfflineMessage(BuildContext context, String? message) async {
    return showDialog(context: context, builder: (context) {
      return AlertDialog(
        content: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
          Text(Localization().getStringEx("app.offline.message.title", "You appear to be offline")!, style: TextStyle(fontSize: 18),),
          Container(height:16),
          Text(message!, textAlign: TextAlign.center,),
        ],),
        actions: <Widget>[
          TextButton(
              child: Text(Localization().getStringEx("dialog.ok.title", "OK")!),
              onPressed: (){
                Analytics.instance.logAlert(text: message, selection: "OK");
                  Navigator.pop(context, true);
              }
          ) //return dismissed 'true'
        ],
      );
    },);

  }
}

class AppSemantics {
    static void announceCheckBoxStateChange(BuildContext? context, bool checked, String? name){
      String message = (StringUtils.isNotEmpty(name)?name!+", " :"")+
          (checked ?
            Localization().getStringEx("toggle_button.status.checked", "checked",)! :
            Localization().getStringEx("toggle_button.status.unchecked", "unchecked")!); // !toggled because we announce before it got changed
      announceMessage(context, message);
    }

    static Semantics buildCheckBoxSemantics({Widget? child, String? title, bool selected = false, double? sortOrder}){
      return Semantics(label: title, button: true ,excludeSemantics: true, sortKey: sortOrder!=null?OrdinalSortKey(sortOrder) : null,
      value: (selected?Localization().getStringEx("toggle_button.status.checked", "checked",) :
      Localization().getStringEx("toggle_button.status.unchecked", "unchecked"))! +
      ", "+ Localization().getStringEx("toggle_button.status.checkbox", "checkbox")!,
      child: child );
    }

    static void announceMessage(BuildContext? context, String message){
        if(context != null){
          context.findRenderObject()!.sendSemanticsEvent(AnnounceSemanticsEvent(message,TextDirection.ltr));
        }
    }
}

