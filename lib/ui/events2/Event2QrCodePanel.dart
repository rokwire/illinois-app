
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/NativeCommunicator.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/service/events2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/image_utils.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:share/share.dart';

class Event2QrCodePanel extends StatefulWidget { //TBD localize
  final Event2? event;

  const Event2QrCodePanel({required this.event});

  @override
  _EventQrCodePanelState createState() => _EventQrCodePanelState();
}

class _EventQrCodePanelState extends State<Event2QrCodePanel> {
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
      'content': _promotionUrl,
      'format': 'qrCode',
      'width': _imageSize,
      'height': _imageSize,
    });
  }

  Future<void> _saveQrCode() async {
    Analytics().logSelect(target: "Save Event QR Code");

    if (_qrCodeBytes == null) {
      AppAlert.showDialogResult(context, Localization().getStringEx("panel.event_qr_code.alert.no_qr_code.msg", "There is no QR Code"));
    } else {
      final String? eventName = widget.event?.name;
      Uint8List? updatedImageBytes = await ImageUtils.applyLabelOverImage(_qrCodeBytes, eventName,
        width: _imageSize.toDouble(),
        height: _imageSize.toDouble(),
        fontFamily: Styles().fontFamilies!.bold,
        fontSize: 54,
        textColor: Styles().colors!.textSurface!,
      );
      bool result = (updatedImageBytes != null);
      if (result) {
        final String fileName = 'event - $eventName';
        result = await ImageUtils.saveToFs(updatedImageBytes, fileName) ?? false;
      }
      String platformTargetText = (defaultTargetPlatform == TargetPlatform.android)
          ? Localization().getStringEx("panel.event_qr_code.alert.save.success.pictures", "Pictures")
          : Localization().getStringEx("panel.event_qr_code.alert.save.success.gallery", "Gallery");
      String message = result
          ? (Localization().getStringEx("panel.event_qr_code.alert.save.success.msg", "Successfully saved qr code in ") + platformTargetText)
          : Localization().getStringEx("panel.event_qr_code.alert.save.fail.msg", "Failed to save qr code in ") + platformTargetText;
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
        title: Localization().getStringEx('panel.event_qr_code.title', 'Promote this event'),
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
                    Localization().getStringEx('panel.event_qr_code.description.label', 'Invite others to join this event by sharing a link or the QR code after saving it to your photo library.'),
                    style: Styles().textStyles?.getTextStyle("widget.title.regular.fat")
                ),
                Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: ((_qrCodeBytes != null)
                      ? Semantics(
                    label: Localization().getStringEx('panel.event_qr_code.code.hint', "QR code image"),
                    child: Container(
                      decoration: BoxDecoration(color: Styles().colors!.white, borderRadius: BorderRadius.all(Radius.circular(5))),
                      padding: EdgeInsets.all(5),
                      child: Image.memory(
                        _qrCodeBytes!,
                        fit: BoxFit.fitWidth,
                        semanticLabel: Localization().getStringEx("panel.event_qr_code.primary.heading.title", "Event promotion Key"),
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
                    label: Localization().getStringEx('panel.event_qr_code.button.save.title', 'Save QR Code'),
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
                    label: Localization().getStringEx('panel.event_qr_code.button.share.title', 'Share Link'),
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
    Analytics().logSelect(target: 'Save Event Qr Code');
    _saveQrCode();
  }

  void _onTapShare() {
    Analytics().logSelect(target: 'Share Event Qr Code');
    Share.share(_promotionUrl);
  }

  String get _promotionUrl {
    String deepLink = "${Events2().eventDetailUrl}?event_id=${widget.event?.id}";
    String? redirectUrl = Config().deepLinkRedirectUrl;
    return StringUtils.isNotEmpty(redirectUrl) ? "$redirectUrl?target=$deepLink" : deepLink;
  }
}