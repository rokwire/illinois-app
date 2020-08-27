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

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/ui/WebPanel.dart';
import 'package:illinois/ui/widgets/RoundedButton.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:illinois/service/Styles.dart';
import 'package:url_launcher/url_launcher.dart';

/*
	"widgets": {
		"home":{
			"widget1": {
				"title": "UIUC Wednesday 2020/03/18",
				"text": "7 Dobromir, can we have 3 widgets made like we hacked voter widget for covid. Stored in assets.json. They will be hidden by talent chooser/assets until needed.",
				"can_close": true,
				"buttons":[
					{"title":"Yes", "link": {"url": "https://illinois.edu", "options": { "target": "internal" } } },
					{"title":"No", "link": {"url": "https://illinois.edu", "options": { "target": "external" } } },
					{"title":"Maybe", "link": {"url": "https://illinois.edu", "options": { "target": { "ios": "internal", "android": "external" } } } }
				]
			}
		}
	},
*/

class FlexContentWidget extends StatefulWidget {
  final Map<String, dynamic> jsonContent;

  FlexContentWidget({@required this.jsonContent});

  @override
  _FlexContentWidgetState createState() => _FlexContentWidgetState();
}

class _FlexContentWidgetState extends State<FlexContentWidget> {
  bool _visible = true;

  @override
  Widget build(BuildContext context) {
    bool closeVisible = widget.jsonContent != null ? (widget.jsonContent['can_close'] ?? false) : false;
    return Visibility(
        visible: _visible,
        child: Semantics(
            container: true,
            child: Container(
                color: Styles().colors.lightGray,
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Stack(
                        children: <Widget>[
                          Container(
                            height: 1,
                            color: Styles().colors.fillColorPrimaryVariant,
                          ),
                          Padding(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 30), child: _buildContent()),
                          Visibility(visible: closeVisible, child: Container(
                              alignment: Alignment.topRight,
                              child: Semantics(
                                  label: Localization().getStringEx("widget.flex_content_widget.button.close.hint", "Close"),
                                  button: true,
                                  excludeSemantics: true,
                                  child: InkWell(
                                      onTap: _onClose,
                                      child: Container(width: 48, height: 48, alignment: Alignment.center, child: Image.asset('images/close-orange.png'))))),),
                        ],
                      ),
                    )
                  ],
                ))));
  }

  Widget _buildContent() {
    bool hasJsonContent = (widget.jsonContent != null);
    String title = hasJsonContent ? widget.jsonContent['title'] : null;
    String text = hasJsonContent ? widget.jsonContent['text'] : null;
    List<dynamic> buttonsJsonContent = hasJsonContent ? widget.jsonContent['buttons'] : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Visibility(visible: AppString.isStringNotEmpty(title), child: Padding(padding: EdgeInsets.only(bottom: 10), child: Text(
          AppString.getDefaultEmptyString(value: title),
          style: TextStyle(
            color: Styles().colors.fillColorPrimary,
            fontFamily: Styles().fontFamilies.extraBold,
            fontSize: 20,
          ),
        ),),),
        Visibility(visible: AppString.isStringNotEmpty(text), child: Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: Text(
            AppString.getDefaultEmptyString(value: text),
            style: TextStyle(
              color: Color(0xff494949),
              fontFamily: Styles().fontFamilies.medium,
              fontSize: 16,
            ),
          ),
        ),),
        _buildButtons(buttonsJsonContent)
      ],
    );
  }

  Widget _buildButtons(List<dynamic> buttonsJsonContent) {
    if (AppCollection.isCollectionEmpty(buttonsJsonContent)) {
      return Container();
    }
    List<Widget> buttons = List();
    for (Map<String, dynamic> buttonContent in buttonsJsonContent) {
      String title = buttonContent['title'];
      buttons.add(Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          RoundedButton(
            label: AppString.getDefaultEmptyString(value: title),
            padding: EdgeInsets.symmetric(horizontal: 14),
            textColor: Styles().colors.fillColorPrimary,
            borderColor: Styles().colors.fillColorSecondary,
            backgroundColor: Styles().colors.white,
            onTap: () => _onTapButton(buttonContent),
          ),
        ],
      ));
    }
    return Wrap(runSpacing: 8, spacing: 16, children: buttons);
  }

  void _onClose() {
    Analytics.instance.logSelect(target: "Flex Content: Close");
    setState(() {
      _visible = false;
    });
  }

  void _onTapButton(Map<String, dynamic> button) {
    String title = button['title'];
    Analytics.instance.logSelect(target: "Flex Content: $title");
    
    Map<String, dynamic> linkJsonContent = button['link'];
    if (linkJsonContent == null) {
      return;
    }
    String url = linkJsonContent['url'];
    if (AppString.isStringEmpty(url)) {
      return;
    }
    Map<String, dynamic> options = linkJsonContent['options'];
    dynamic target = (options != null) ? options['target'] : 'internal';
    if (target is Map) {
      target = target[Platform.operatingSystem.toLowerCase()];
    }

    if ((target is String) && (target == 'external')) {
      launch(url);
    }
    else {
      Navigator.of(context).push(CupertinoPageRoute(builder: (context) => WebPanel(url: url )));
    }
  }
}
