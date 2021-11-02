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
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:illinois/model/Groups.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Groups.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/Log.dart';
import 'package:illinois/service/NativeCommunicator.dart';
import 'package:illinois/service/Styles.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/ScalableWidgets.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:path_provider/path_provider.dart';

class GroupQrCodePanel extends StatefulWidget {
  final Group group;

  const GroupQrCodePanel({@required this.group});

  @override
  _GroupQrCodePanelState createState() => _GroupQrCodePanelState();
}

class _GroupQrCodePanelState extends State<GroupQrCodePanel> {
  Uint8List _qrCodeBytes;

  @override
  void initState() {
    super.initState();
    _loadQrImageBytes().then((imageBytes) {
      setState(() {
        _qrCodeBytes = imageBytes;
      });
    });
  }

  Future<Uint8List> _loadQrImageBytes() async {
    String groupPromotionKey = '${Groups.GROUP_URI}?group_id=${widget.group?.id}';
    return (groupPromotionKey != null) ? await NativeCommunicator().getBarcodeImageData({
      'content': groupPromotionKey,
      'format': 'qrCode',
      'width': 1024,
      'height': 1024,
    }) : null;
  }

  Future<void> _saveQrCode() async {
    Analytics.instance.logSelect(target: "Save Group QR Code");

    if (_qrCodeBytes == null) {
      AppAlert.showDialogResult(context, Localization().getStringEx("panel.group_qr_code.alert.no_qr_code.msg", "There is no QR Code"));
    } else {
      final String dir = (await getApplicationDocumentsDirectory()).path;
      final String fileName = 'Group - ${widget.group?.title}.png';
      final String fullPath = '$dir/$fileName';
      File capturedFile = File(fullPath);
      await capturedFile.writeAsBytes(_qrCodeBytes);
      bool saveResult = false;
      try {
        saveResult = await GallerySaver.saveImage(capturedFile.path);
      } catch (e) {
        Log.e('Failed to save group promotion image to gallery. \nException: ${e?.toString()}');
      }
      String platformTargetText = (defaultTargetPlatform == TargetPlatform.android)
          ? Localization().getStringEx("panel.group_qr_code.alert.save.success.pictures", "Pictures")
          : Localization().getStringEx("panel.group_qr_code.alert.save.success.gallery", "Gallery");
      String message = saveResult
          ? (Localization().getStringEx("panel.group_qr_code.alert.save.success.msg", "Successfully saved qr code in ") + platformTargetText)
          : Localization().getStringEx("panel.group_qr_code.alert.save.fail.msg", "Failed to save qr code in ") + platformTargetText;
      AppAlert.showDialogResult(context, message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SimpleHeaderBarWithBack(
        context: context,
        titleWidget: Text(
          Localization().getStringEx('panel.group_qr_code.title', 'Promote this group'),
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
          ),
          textAlign: TextAlign.center,
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          color: Styles().colors.background,
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  Localization().getStringEx('panel.group_qr_code.description.label', 'Save this QRCode so you can share or print it.'),
                  style: TextStyle(color: Styles().colors.fillColorPrimary, fontSize: 16, fontFamily: Styles().fontFamilies.bold),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: ((_qrCodeBytes != null)
                      ? Semantics(
                          label: Localization().getStringEx('panel.group_qr_code.code.hint', "QR code image"),
                          child: Container(
                            decoration: BoxDecoration(color: Styles().colors.white, borderRadius: BorderRadius.all(Radius.circular(5))),
                            padding: EdgeInsets.all(5),
                            child: Image.memory(
                              _qrCodeBytes,
                              fit: BoxFit.fitWidth,
                              semanticLabel: Localization().getStringEx("panel.group_qr_code.primary.heading.title", "Group promotion Key"),
                            ),
                          ),
                        )
                      : Container(
                          width: MediaQuery.of(context).size.width,
                          height: MediaQuery.of(context).size.width - 10,
                          child: Align(
                            alignment: Alignment.center,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Styles().colors.fillColorSecondary),
                              strokeWidth: 2,
                            ),
                          ),
                        )),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 24, bottom: 12),
                  child: ScalableRoundedButton(
                    label: Localization().getStringEx('panel.group_qr_code.button.save.title', 'Save'),
                    hint: '',
                    backgroundColor: Styles().colors.background,
                    fontSize: 16.0,
                    textColor: Styles().colors.fillColorPrimary,
                    borderColor: Styles().colors.fillColorSecondary,
                    onTap: _onTapSave,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      backgroundColor: Styles().colors.background,
    );
  }

  void _onTapSave() {
    _saveQrCode();
  }
}
