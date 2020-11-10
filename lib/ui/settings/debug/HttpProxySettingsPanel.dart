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
import 'package:illinois/service/HttpProxy.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/Styles.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:illinois/ui/widgets/RoundedButton.dart';

class HttpProxySettingsPanel extends StatefulWidget{
  _HttpProxySettingsPanelState createState() => _HttpProxySettingsPanelState();
}

class _HttpProxySettingsPanelState extends State<HttpProxySettingsPanel>{

  bool _proxyEnabled;

  final TextEditingController _hostController = TextEditingController();
  final TextEditingController _portController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _proxyEnabled = HttpProxy().httpProxyEnabled;
    _hostController.text = HttpProxy().httpProxyHost;
    _portController.text = HttpProxy().httpProxyPort;
  }

  @override
  void dispose() {
    super.dispose();
    _portController.dispose();
    _hostController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Styles().colors.surface,
      appBar: SimpleHeaderBarWithBack(
        context: context,
        titleWidget: Text(
          Localization().getStringEx("panel.debug_http_proxy.header.title", "Http Proxy"),
          style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: Styles().fontFamilies.extraBold),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              ToggleRibbonButton(label: Localization().getStringEx("panel.debug_http_proxy_enable.button.save.title", "Http Proxy Enabled"), toggled: _proxyEnabled, onTap: (){
                setState(() {
                  _proxyEnabled = !_proxyEnabled;
                });
              }),
              Padding(
                  padding: EdgeInsets.only(left: 12, right: 12, bottom: 12),
                  child: Semantics(
                    excludeSemantics: true,
                    label: Localization().getStringEx("panel.debug_http_proxy.edit.host.title", "Http Proxy Host"),
                    hint: Localization().getStringEx("panel.debug_http_proxy.edit.host.hint", ""),
                    value: _hostController.text,
                    child: TextField(
                      controller: _hostController,
                      autofocus: false,
                      cursorColor: Styles().colors.textBackground,
                      keyboardType: TextInputType.text,
                      style: TextStyle(
                          fontSize: 16,
                          fontFamily: Styles().fontFamilies.regular,
                          color: Styles().colors.textBackground),
                      decoration: InputDecoration(
                        labelText: Localization().getStringEx("panel.debug_http_proxy.edit.host.title", "Http Proxy Host"),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: Colors.black,
                              width: 2.0,
                              style: BorderStyle.solid),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black, width: 2.0),
                        ),
                      ),
                    ),
                  )),
              Padding(
                  padding: EdgeInsets.only(left: 12, right: 12, bottom: 12),
                  child: Semantics(
                    excludeSemantics: true,
                    label: Localization().getStringEx("panel.debug_http_proxy.edit.host.title", "Http Proxy Port"),
                    hint: Localization().getStringEx("panel.debug_http_proxy.edit.host.hint", ""),
                    value: _portController.text,
                    child: TextField(
                      controller: _portController,
                      autofocus: false,
                      cursorColor: Styles().colors.textBackground,
                      keyboardType: TextInputType.text,
                      style: TextStyle(
                          fontSize: 16,
                          fontFamily: Styles().fontFamilies.regular,
                          color: Styles().colors.textBackground),
                      decoration: InputDecoration(
                        labelText: Localization().getStringEx("panel.debug_http_proxy.edit.host.title", "Http Proxy Port"),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: Colors.black,
                              width: 2.0,
                              style: BorderStyle.solid),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black, width: 2.0),
                        ),
                      ),
                    ),
                  )),
              RoundedButton(
                  label: Localization().getStringEx("panel.debug_http_proxy.button.save.title", "Save"),
                  backgroundColor: Styles().colors.background,
                  fontSize: 16.0,
                  textColor: Styles().colors.fillColorPrimary,
                  borderColor: Styles().colors.fillColorPrimary,
                  onTap: ()=> _onTapSave(context))
            ],
          ),
        ),
      ),
    );
  }

  void _onTapSave(BuildContext context){
    HttpProxy().httpProxyEnabled = _proxyEnabled;
    HttpProxy().httpProxyHost = _hostController.text;
    HttpProxy().httpProxyPort = _portController.text;
    Navigator.pop(context);
  }
}


