/*
 * Copyright 2023 Board of Trustees of the University of Illinois.
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
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/ui/wallet/WalletICardWidget.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:sprintf/sprintf.dart';

class WalletICardHomePanel extends StatefulWidget {
  WalletICardHomePanel._();

  @override
  _WalletICardHomePanelState createState() => _WalletICardHomePanelState();

  static void present(BuildContext context) {
    if (!Auth2().isOidcLoggedIn) {
      AppAlert.showLoggedOutFeatureNAMessage(context, Localization().getStringEx('generic.app.feature.illini_id', 'Illini ID'));
    }
    else if (StringUtils.isEmpty(Auth2().iCard?.cardNumber)) {
      AppAlert.showTextMessage( context, Localization().getStringEx('panel.browse.label.no_card.illini_id', 'No Illini ID information. You do not have an active Illini ID. Please visit the ID Center.'));
    }
    else {
      String? warning;
      int? expirationDays = Auth2().iCard?.expirationIntervalInDays;
      if (expirationDays != null) {
        if (expirationDays <= 0) {
          warning = sprintf(Localization().getStringEx('panel.browse.label.expired_card.illini_id', 'No Illini ID information. Your Illini ID expired on %s. Please visit the ID Center.'),
            [Auth2().iCard?.expirationDate ?? '']
          );
        } else if ((0 < expirationDays) && (expirationDays < 30)) {
          warning = sprintf(Localization().getStringEx('panel.browse.label.expiring_card.illini_id', 'Your ID will expire on %s. Please visit the ID Center.'),
            [Auth2().iCard?.expirationDate ?? '']
          );
        }
      }

      if (warning != null) {
        AppAlert.showTextMessage(context, warning).then((_) {
          _present(context);
        });
      } else {
        _present(context);
      }
    }
  }

  static void _present(BuildContext context) {
    MediaQueryData mediaQuery = MediaQueryData.fromView(View.of(context));
    double height = mediaQuery.size.height - mediaQuery.viewPadding.top - mediaQuery.viewInsets.top - 16;
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        isDismissible: true,
        clipBehavior: Clip.antiAlias,
        backgroundColor: Styles().colors.background,
        constraints: BoxConstraints(maxHeight: height, minHeight: height),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
        builder: (context) => WalletICardHomePanel._());
  }
}

class _WalletICardHomePanelState extends State<WalletICardHomePanel> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold( backgroundColor: Styles().colors.white, body:
      Column(children: [
        Row(children: [
          Expanded(child:
            Padding(padding: EdgeInsets.only(left: 16), child:
              Text(Localization().getStringEx('panel.icard.home.title.label', 'Illini ID'), style: Styles().textStyles.getTextStyle('panel.id_card.heading.title'))
            )
          ),
          Semantics(label: Localization().getStringEx('dialog.close.title', 'Close'), hint: Localization().getStringEx('dialog.close.hint', ''), inMutuallyExclusiveGroup: true, button: true, child:
            InkWell(onTap: _onTapClose, child:
              Container(padding: EdgeInsets.only(left: 8, right: 16, top: 16, bottom: 16), child:
                Styles().images.getImage('close-circle', excludeFromSemantics: true)
              )
            )
          )
        ]),
        Container(color: Styles().colors.surfaceAccent, height: 1),
        Expanded(child: _buildContent())
      ]));
  }

  Widget _buildContent() {
    return Column(children: <Widget>[
      Expanded(child:
        SingleChildScrollView(child:
          Container(color: Styles().colors.white, child:
            WalletICardWidget(),
          )
        )
      )
    ]);
  }

  void _onTapClose() {
    Analytics().logSelect(target: 'Close', source: widget.runtimeType.toString());
    Navigator.of(context).pop();
  }
}
