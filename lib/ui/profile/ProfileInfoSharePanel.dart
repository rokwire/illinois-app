import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:gal/gal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:illinois/ext/Auth2.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/directory/DirectoryWidgets.dart';
import 'package:illinois/ui/widgets/QrCodePanel.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/model/auth2.directory.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:sms_mms/sms_mms.dart';
//import 'package:share/share.dart';

class ProfileInfoSharePanel extends StatefulWidget {

  final Auth2UserProfile? profile;
  final Uint8List? photoImageData;
  final Uint8List? pronunciationAudioData;

  ProfileInfoSharePanel._({this.profile, this.photoImageData, this.pronunciationAudioData});

  static void present(BuildContext context, {
    Auth2UserProfile? profile,
    Uint8List? photoImageData,
    Uint8List? pronunciationAudioData,
  }) {
    MediaQueryData mediaQuery = MediaQueryData.fromView(View.of(context));
    double height = mediaQuery.size.height - mediaQuery.viewPadding.top - mediaQuery.viewInsets.top - 16;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      clipBehavior: Clip.antiAlias,
      backgroundColor: Styles().colors.backgroundVariant,
      constraints: BoxConstraints(maxHeight: height),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => ProfileInfoSharePanel._(
        profile: profile,
        photoImageData: photoImageData,
        pronunciationAudioData: pronunciationAudioData,
      ),
    );
  }
  
  @override
  State<StatefulWidget> createState() => _ProfileInfoSharePanelState();
}

class _ProfileInfoSharePanelState extends State<ProfileInfoSharePanel> {

  final GlobalKey _repaintBoundaryKey = GlobalKey();
  bool _savingToPhotos = false;
  bool _sharingDigitalCard = false;
  bool _preparingEmail = false;
  bool _preparingTextMessage = false;
  bool _preparingClipboardText = false;

  @override
  Widget build(BuildContext context) => Stack(children: [
    _panelContent,
    Align(alignment: Alignment.topRight, child: _closeButton),
  ],);

  Widget get _panelContent => SingleChildScrollView(child:
    Padding(padding: EdgeInsets.only(top: 24 + 2 * 16 /* close button size */, bottom: 16), child:
      Column(children: [
        Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
          RepaintBoundary(key: _repaintBoundaryKey, child:
            DirectoryAccountContactCard(account: Auth2PublicAccount(profile: widget.profile), printMode: true,),
          ),
        ),
        Padding(padding: EdgeInsets.symmetric(vertical: 16), child:
          Container(color: Styles().colors.surfaceAccent, height: 1,),
        ),
        _buildCommand(
          icon: Styles().images.getImage('download', size: _commandIconSize),
          text: Localization().getStringEx('panel.profile.info.share.command.button.save.text', 'Save to Photos'),
          progress: _savingToPhotos,
          onTap: _onTapSaveToPhotos,
        ),
        _buildCommand(
          icon: Styles().images.getImage('envelope', size: _commandIconSize),
          text: Localization().getStringEx('panel.profile.info.share.command.button.share.email.text', 'Share Digital Business Card'),
          progress: _preparingEmail,
          onTap: _onTapShareViaEmail,
        ),
        _buildCommand(
          icon: Styles().images.getImage('message', size: _commandIconSize),
          text: Localization().getStringEx('panel.profile.info.share.command.button.share.message.text', 'Share via Text Message'),
          progress: _preparingTextMessage,
          onTap: _onTapShareViaTextMessage,
        ),
        _buildCommand(
          icon: Styles().images.getImage('up-from-bracket', size: _commandIconSize),
          text: Localization().getStringEx('panel.profile.info.share.command.button.share.digital_card.text', 'Add to Device Contacts'),
          progress: _sharingDigitalCard,
          onTap: _onTapShareDigitalCard,
        ),
        _buildCommand(
          icon: Styles().images.getImage('copy-fa', size: _commandIconSize),
          text: Localization().getStringEx('panel.profile.info.share.command.button.copy.clipboard.text', 'Copy Text to Clipboard'),
          progress: _preparingClipboardText,
          onTap: _onTapCopyTextToClipboard,
        ),
      ]),
    ),
  );

  Widget get _closeButton =>
    Semantics( label: Localization().getStringEx('dialog.close.title', 'Close'), hint: Localization().getStringEx('dialog.close.hint', ''), inMutuallyExclusiveGroup: true, button: true, child:
      InkWell(onTap : _onTapClose, child:
        Container(padding: EdgeInsets.only(left: 8, right: 16, top: 16, bottom: 16), child:
          Styles().images.getImage('close-circle', excludeFromSemantics: true),
        ),
      ),
    );

  final double _commandIconSize = 14;
  
  Widget _buildCommand({Widget? icon, String? text, bool progress = false, void Function()? onTap}) =>
    InkWell(onTap: onTap, child:
      Row(children: [
        Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16), child:
          SizedBox(width: _commandIconSize, height: _commandIconSize, child: progress ?
            CircularProgressIndicator(strokeWidth: 2, color: Styles().colors.fillColorSecondary, ) :
            (icon ?? SizedBox(width: _commandIconSize, height: _commandIconSize,)),
          ),
        ),
        Padding(padding: EdgeInsets.only(right: 16), child:
          Text(text ?? '', style: Styles().textStyles.getTextStyle('widget.button.title.medium.fat'),),
        ),
      ],)
    );

  void _onTapSaveToPhotos() async {
    Analytics().logSelect(target: 'Save to Files');
    setState(() {
      _savingToPhotos = true;
    });
    String? imagePath = await _saveImage(addToGallery: true);
    if (mounted) {
      setState(() {
        _savingToPhotos = false;
      });
      String message = (imagePath != null) ?
        Localization().getStringEx('panel.profile.info.share.command.save.image.succeeded', 'Contact card image saved successfully.') :
        Localization().getStringEx('panel.profile.info.share.command.save.image.failed', 'Failed to save contact card image.');
      AppAlert.showTextMessage(context, message);
    }
  }

  void _onTapShareDigitalCard() async {
    Analytics().logSelect(target: 'Share Digital Card');
    QrCodePanel.presentProfile(context,
      profile: widget.profile,
      photoImageData: widget.photoImageData,
      pronunciationAudioData: widget.pronunciationAudioData,
    );
  }

  /* void _onTapShareDigitalCard1() async {
    Analytics().logSelect(target: 'Share Digital Card');

    setState(() {
      _sharingDigitalCard = true;
    });
    String? vcardPath = await _saveDigitalCard();
    if (mounted) {
      setState(() {
        _sharingDigitalCard = false;
      });
      if (vcardPath != null) {
        Share.shareFiles([vcardPath],
          mimeTypes: ['text/vcard'],
          text: widget.profile?.vcardFullName,
        );
      }
      else {
        AppAlert.showTextMessage(context, Localization().getStringEx('panel.profile.info.share.command.save.digital_card.failed', 'Failed to save Digital Business Card.'));
      }
    }
  } */

  void _onTapShareViaEmail() async {
    Analytics().logSelect(target: 'Share via Email');
    setState(() {
      _preparingEmail = true;
    });
    List<String?> results = await Future.wait(<Future<String?>>[
      _saveImage(),
      _saveDigitalCard(),
    ]);
    String? imageFilePath = (0 < results.length) ? results[0] : null;
    String? vCardFilePath = (1 < results.length) ? results[1] : null;
    if (mounted) {
      setState(() {
        _preparingEmail = false;
      });

      final Email email = Email(
        body: widget.profile?.toDisplayText() ?? '',
        attachmentPaths: [
          if (imageFilePath != null)
            imageFilePath,
          if (vCardFilePath != null)
            vCardFilePath,
        ],
        isHTML: false,
      );

      FlutterEmailSender.send(email);
    }
  }

  void _onTapShareViaTextMessage() async {
    Analytics().logSelect(target: 'Share via Text Message');
    setState(() {
      _preparingTextMessage = true;
    });
    String? imagePath = await _saveImage();
    if (mounted) {
      setState(() {
        _preparingTextMessage = false;
      });
      SmsMms.send(
        recipients: [],
        message: widget.profile?.toDisplayText() ?? '',
        filePath: imagePath,
      );
    }
  }

  void _onTapCopyTextToClipboard() async {
    Analytics().logSelect(target: 'Copy Text to Clipboard');
    setState(() {
      _preparingClipboardText = true;
    });

    bool succeeded = await _copyTextToClipbiard();

    if (mounted) {
      setState(() {
        _preparingClipboardText = false;
      });
      String message = succeeded ?
        Localization().getStringEx('panel.profile.info.share.command.copy.clipboard.succeeded', 'Profile details were copied to Clipboard successfully.') :
        Localization().getStringEx('panel.profile.info.share.command.copy.clipboard.failed', 'Failed to copy profile detail to Clipboard.');
      AppAlert.showTextMessage(context, message);
    }
  }

  Future<String?> _saveImage({bool addToGallery = false} ) async {
    try {
      RenderRepaintBoundary? boundary = JsonUtils.cast(_repaintBoundaryKey.currentContext?.findRenderObject());
      if (boundary != null) {
        final ui.Image image = await boundary.toImage(pixelRatio: MediaQuery.of(context).devicePixelRatio * 3);
        ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          Uint8List buffer = byteData.buffer.asUint8List();
          final String dir = (await getApplicationDocumentsDirectory()).path;
          final String saveFileName = '${widget.profile?.vcardFullName} ${DateTimeUtils.localDateTimeFileStampToString(DateTime.now())}';
          final String fullPath = '$dir/$saveFileName.png';
          File capturedFile = File(fullPath);
          await capturedFile.writeAsBytes(buffer);
          if (addToGallery) {
            await Gal.putImage(capturedFile.path);
          }
          return capturedFile.path;
        }
      }
    }
    catch(e) { debugPrint(e.toString()); }
    return null;
  }

  Future<String?> _saveDigitalCard() async {
    try {
      String? vcfContent = widget.profile?.toDigitalCard(
        photoImageData: widget.photoImageData,
      );
      if ((vcfContent != null) && vcfContent.isNotEmpty) {
        final String dir = (await getApplicationDocumentsDirectory()).path;
        final String saveFileName = '${widget.profile?.vcardFullName} ${DateTimeUtils.localDateTimeFileStampToString(DateTime.now())}';
        final String fullPath = '$dir/$saveFileName.vcf';
        File capturedFile = File(fullPath);
        await capturedFile.writeAsString(vcfContent);
        return capturedFile.path;
      }
    }
    catch(e) { debugPrint(e.toString()); }
    return null;
  }

  Future<bool> _copyTextToClipbiard() async {
    try {
      await Clipboard.setData(ClipboardData(text: widget.profile?.toDisplayText() ?? ''));
      return true;
    }
    catch(e) {
      debugPrint(e.toString());
      return false;
    }
  }

  void _onTapClose() {
    Analytics().logSelect(target: 'Close', source: runtimeType.toString());
    Navigator.of(context).pop();
  }
}