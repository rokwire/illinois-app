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

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rokwire_plugin/model/group.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Config.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/service/NativeCommunicator.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/utils/image_utils.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:share/share.dart';

class GroupQrCodePanel extends StatefulWidget {
  final Group? group;

  const GroupQrCodePanel({required this.group});

  @override
  _GroupQrCodePanelState createState() => _GroupQrCodePanelState();
}

class _GroupQrCodePanelState extends State<GroupQrCodePanel> {
  static final int _imageSize = 1024;
  Uint8List? _qrCodeBytes;

  @override
  void initState() {
    super.initState();
    _loadQrImageBytes().then((imageBytes) {
      setState(() {
        _qrCodeBytes = imageBytes;
      });
    });
  }

  Future<Uint8List?> _loadQrImageBytes() async {
    return await NativeCommunicator().getBarcodeImageData({
      'content': _groupPromotionUrl,
      'format': 'qrCode',
      'width': _imageSize,
      'height': _imageSize,
    });
  }

  Future<void> _saveQrCode() async {
    Analytics().logSelect(target: "Save Group QR Code");

    if (_qrCodeBytes == null) {
      AppAlert.showDialogResult(context, Localization().getStringEx("panel.group_qr_code.alert.no_qr_code.msg", "There is no QR Code"));
    } else {
      final String? groupName = widget.group?.title;
      Uint8List? updatedImageBytes = await ImageUtils.applyLabelOverImage(_qrCodeBytes, groupName,
        width: _imageSize.toDouble(),
        height: _imageSize.toDouble(),
        fontFamily: Styles().fontFamilies!.bold,
        fontSize: 54,
        textColor: Styles().colors!.textSurface!,
      );
      bool result = (updatedImageBytes != null);
      if (result) {
        final String fileName = 'Group - $groupName';
        result = await ImageUtils.saveToFs(updatedImageBytes, fileName) ?? false;
      }
      String platformTargetText = (defaultTargetPlatform == TargetPlatform.android)
          ? Localization().getStringEx("panel.group_qr_code.alert.save.success.pictures", "Pictures")
          : Localization().getStringEx("panel.group_qr_code.alert.save.success.gallery", "Gallery");
      String message = result
          ? (Localization().getStringEx("panel.group_qr_code.alert.save.success.msg", "Successfully saved qr code in ") + platformTargetText)
          : Localization().getStringEx("panel.group_qr_code.alert.save.fail.msg", "Failed to save qr code in ") + platformTargetText;
      AppAlert.showDialogResult(context, message).then((value) {
        if(result) {
          Navigator.of(context).pop();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(
        title: Localization().getStringEx('panel.group_qr_code.title', 'Promote this group'),
        textAlign: TextAlign.center,
      ),
      body: SingleChildScrollView(
        child: Container(
          color: Styles().colors!.background,
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  Localization().getStringEx('panel.group_qr_code.description.label', 'Invite others to join this group by sharing a link or the QR code after saving it to your photo library.'),
                  style: Styles().textStyles?.getTextStyle("widget.title.regular.fat")
                ),
                Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: ((_qrCodeBytes != null)
                      ? Semantics(
                          label: Localization().getStringEx('panel.group_qr_code.code.hint', "QR code image"),
                          child: Container(
                            decoration: BoxDecoration(color: Styles().colors!.white, borderRadius: BorderRadius.all(Radius.circular(5))),
                            padding: EdgeInsets.all(5),
                            child: Image.memory(
                              _qrCodeBytes!,
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
                              valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors!.fillColorSecondary),
                              strokeWidth: 2,
                            ),
                          ),
                        )),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 24, bottom: 12),
                  child: RoundedButton(
                    label: Localization().getStringEx('panel.group_qr_code.button.save.title', 'Save QR Code'),
                    hint: '',
                    textStyle: Styles().textStyles?.getTextStyle("widget.title.regular.fat"),
                    backgroundColor: Styles().colors!.background,
                    borderColor: Styles().colors!.fillColorSecondary,
                    onTap: _onTapSave,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: RoundedButton(
                    label: Localization().getStringEx('panel.group_qr_code.button.share.title', 'Share Link'),
                    hint: '',
                    textStyle: Styles().textStyles?.getTextStyle("widget.button.title.medium.fat"),
                    backgroundColor: Styles().colors!.background,
                    borderColor: Styles().colors!.fillColorSecondary,
                    onTap: _onTapShare,
                    rightIcon: Styles().images?.getImage('share-dark', excludeFromSemantics: true),
                    rightIconPadding: EdgeInsets.only(right: 75),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
      backgroundColor: Styles().colors!.background,
    );
  }

  void _onTapSave() {
    Analytics().logSelect(target: 'Save Group Qr Code');
    _saveQrCode();
  }

  void _onTapShare() {
    Analytics().logSelect(target: 'Share Group Qr Code');
    Share.share(_groupPromotionUrl);
  }

  String get _groupPromotionUrl {
    String deepLink = '${Groups().groupDetailUrl}?group_id=${widget.group!.id}';
    String? redirectUrl = Config().deepLinkRedirectUrl;
    return StringUtils.isNotEmpty(redirectUrl) ? "$redirectUrl?target=$deepLink" : deepLink;
  }
}
