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
import 'package:rokwire_plugin/service/styles.dart';

import 'RoundedButton.dart';

class PopupDialog extends StatelessWidget {
  final String? _displayText;
  final String? _positiveButtonText;

  PopupDialog({String? displayText, String? positiveButtonText}) : _displayText = displayText, _positiveButtonText = positiveButtonText;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.all(Radius.circular(8)),
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Container(
                    color: Styles().colors!.fillColorPrimary,
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: Center(
                        child: Text(
                          Localization().getStringEx("app.title", "Illinois")!,
                          style: TextStyle(fontSize: 20, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Container(height: 26,),
            Text(
              _displayText!,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: Styles().fontFamilies!.bold,
                  fontSize: 16,
                  color: Colors.black),
            ),
            Container(height: 26,),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  RoundedButton(
                      onTap: () {
                        Navigator.of(context).pop(true);
                      },
                      backgroundColor: Colors.transparent,
                      borderColor: Styles().colors!.fillColorSecondary,
                      textColor: Styles().colors!.fillColorPrimary,
                      label: _positiveButtonText ?? ''),
                  Container(height: 10,),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}