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

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/NativeCommunicator.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';

class HomeLibraryCardWidget extends StatefulWidget {
  HomeLibraryCardWidget();

  @override
  State<HomeLibraryCardWidget> createState() => _HomeLibraryCardWidgetState();
}

class _HomeLibraryCardWidgetState extends State<HomeLibraryCardWidget> implements NotificationsListener {
  String?        _libraryCode;
  MemoryImage?   _libraryBarcode;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Auth2.notifyCardChanged,
    ]);
    _loadLibraryBarcode();
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: _onTap, child:
      Container(margin: EdgeInsets.only(left: 16, right: 16, bottom: 20), decoration: BoxDecoration(boxShadow: [BoxShadow(color: Color.fromRGBO(19, 41, 75, 0.3), spreadRadius: 2.0, blurRadius: 8.0, offset: Offset(0, 2))]), child:
        ClipRRect(borderRadius: BorderRadius.all(Radius.circular(6)), child:
          Row(children: <Widget>[
            Expanded(child:
              Column(children: <Widget>[
                Container(color: Styles().colors!.fillColorPrimary, child:
                  Padding(padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16), child:
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Expanded(child:
                        Text(Localization().getStringEx('widget.home.library_card.title', 'Library Card'), style: TextStyle(color: Styles().colors!.white, fontFamily: Styles().fontFamilies!.extraBold, fontSize: 20))
                      ),
                      /*Row(children: <Widget>[
                        Padding(padding: EdgeInsets.only(right: 10), child:
                          Text(Localization().getStringEx('widget.home.common.button.view.title', 'View'), style: TextStyle(color: Styles().colors!.white, fontFamily: Styles().fontFamilies!.bold, fontSize: 16)),
                        ),
                        Image.asset('images/chevron-right-white.png', excludeFromSemantics: true)
                      ]),*/
                    ]),
                  ),
                ),
                Container(color: Styles().colors!.white, child:
                  Padding(padding: EdgeInsets.only(top: 16, right: 16, bottom: 16, left: 16), child:
                    Row(children: <Widget>[
                      Expanded(child:
                        Container(decoration: BoxDecoration(border: Border(left: BorderSide(color: Styles().colors?.fillColorSecondary ?? Colors.transparent, width: 3))), child:
                          Padding(padding: EdgeInsets.only(left: 10, top: 4, bottom: 4), child:
                            Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                              Container(height: 50, decoration: BoxDecoration(
                                shape: BoxShape.rectangle,
                                image: (_libraryBarcode != null) ? DecorationImage(fit: BoxFit.fill, image:_libraryBarcode! ,) : null,    
                              )),
                              Padding(padding: EdgeInsets.only(top: 4), child:
                                Row(children: [Expanded(child: Text(Auth2().authCard?.libraryNumber ?? '', style: TextStyle(fontFamily: Styles().fontFamilies?.regular, fontSize: 14, color: Styles().colors?.fillColorPrimary)))]),
                              )
                            ],),
                          )
                        )
                      ),
                    ]),
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  void _onTap() {
    Analytics().logSelect(target: 'Library Card');
  }

  void _loadLibraryBarcode() {
    String? libraryCode = Auth2().authCard?.libraryNumber;
    if (0 < (libraryCode?.length ?? 0)) {
      NativeCommunicator().getBarcodeImageData({
        'content': Auth2().authCard?.libraryNumber,
        'format': 'codabar',
        'width': 161 * 3,
        'height': 50
      }).then((Uint8List? imageData) {
        if (mounted) {
          setState(() {
            _libraryCode = libraryCode;
            _libraryBarcode = (imageData != null) ? MemoryImage(imageData) : null;
          });
        }
      });
    }
    else {
      _libraryCode = null;
      _libraryBarcode = null;
    }
  }

  void _updateLibraryBarcode() {
    String? libraryCode = Auth2().authCard?.libraryNumber;
    if (((_libraryCode == null) && (libraryCode != null)) ||
        ((_libraryCode != null) && (_libraryCode != libraryCode)))
    {
      _loadLibraryBarcode();
    }
  }

  // NotificationsListener

  void onNotification(String name, dynamic param) {
    if (name == Auth2.notifyCardChanged) {
      _updateLibraryBarcode();
    }
  }
}
