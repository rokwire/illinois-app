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
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:rokwire_plugin/service/styles.dart';

class OnboardingErrorPanel extends StatefulWidget {
  final ServiceError? error;
  final Future<ServiceError?>Function()? retryHandler;
  
  OnboardingErrorPanel({Key? key, this.error, this.retryHandler}) : super(key: key);

  @override
  _OnboardingErrorPanelState createState() => _OnboardingErrorPanelState();
}

class _OnboardingErrorPanelState extends State<OnboardingErrorPanel> {

  ServiceError? _error;
  bool? _retryInProgress;

  @override
  void initState() {
    _error = widget.error;
    super.initState();
  }


  @override
  Widget build(BuildContext context) {

    String buttonTitle = Localization().getStringEx('panel.onboarding.error.button.try_again.title', 'Try Again');
    String? buttonHint = Localization().getStringEx('panel.onboarding.error.button.try_again.hint', '');
    Color buttonBackColor = Styles().colors?.fillColorSecondary ?? Color(0xFFE84A27);

    return Scaffold(backgroundColor: Styles().colors?.background ?? Color(0xFFF5F5F5), body:
      Stack(children: [
        Image.asset('images/login-header.png', fit: BoxFit.fitWidth, width: MediaQuery.of(context).size.width, excludeFromSemantics: true,),
        Column(mainAxisAlignment: MainAxisAlignment.start, children: <Widget>[
          Expanded(child:
            SingleChildScrollView(child:
              Column(children: [
                Container(height: 148 + 48 + MediaQuery.of(context).padding.top),
                Padding(padding: EdgeInsets.symmetric(horizontal: 30), child:
                  Align(alignment: Alignment.center, child:
                    Text(_error?.title ?? '', textAlign: TextAlign.center, style: TextStyle(fontFamily: Styles().fontFamilies?.bold ?? "ProximaNovaBold", fontSize: 32, color: Styles().colors?.fillColorPrimary ?? Color(0xFF002855)),),
                  ),
                ),
                Container(height: 48),
                Padding(padding: EdgeInsets.symmetric(horizontal: 40), child:
                  Align(alignment: Alignment.topCenter, child:
                    Text(_error?.description ?? '', textAlign: TextAlign.center, style: TextStyle(fontFamily: Styles().fontFamilies?.regular ?? "ProximaNovaRegular", fontSize: 20, color: Styles().colors?.fillColorPrimary ?? Color(0xFF002855)),),
                  ),
                ),
              ],)
            ),
          ),
          SafeArea(child:          
            Padding(padding: EdgeInsets.symmetric(horizontal: 60, vertical: 20), child:
              Column(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
                Stack(children: [
                  Visibility(visible: (_error != null), child:
                    Semantics(label: buttonTitle, hint: buttonHint, button: true, child:
                      InkWell(onTap: () => _onRetry(), child:
                        Container(height: 48, decoration: BoxDecoration(color: buttonBackColor, border: Border.all(color: buttonBackColor, width: 2), borderRadius: BorderRadius.circular(24),), child:
                          Container(height: 46, decoration: BoxDecoration(color: buttonBackColor, border: Border.all(color: buttonBackColor, width: 2), borderRadius: BorderRadius.circular(24)), child:
                            Padding(padding: EdgeInsets.all(0), child:
                              Semantics( excludeSemantics: true, child:
                                Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
                                  Text(buttonTitle, textAlign: TextAlign.center, style: TextStyle(fontFamily: Styles().fontFamilies?.bold ?? 'ProximaNovaBold', fontSize: 20, color: Colors.white,),),
                                ],),
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  ),
                  Visibility(visible: ((_error != null) && (_retryInProgress == true)), child:
                    Center(child:
                      Padding(padding: EdgeInsets.only(top: 12), child:
                        Container(width: 24, height: 24, child:
                          CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white), strokeWidth: 2,)
                        ),
                      ),
                    ),
                  ),
                ],),
              ],),
            ),
          ),
        ],),
      ],)
    );
  }

  void _onRetry() {
    if ((widget.retryHandler != null) && (_retryInProgress != true)) {
      setState(() {
        _retryInProgress = true;
      });
      widget.retryHandler!().then((ServiceError? error) {
        setState(() {
          _retryInProgress = false;
          _error = error;
        });
      });
    }
  }
}
