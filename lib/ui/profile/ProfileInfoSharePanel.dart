import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/directory/DirectoryWidgets.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/model/auth2.directory.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/image_utils.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class ProfileInfoSharePanel extends StatefulWidget {

  final Auth2UserProfile? profile;

  ProfileInfoSharePanel._({this.profile});

  static void present(BuildContext context, { Auth2UserProfile? profile }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      clipBehavior: Clip.antiAlias,
      backgroundColor: Styles().colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => ProfileInfoSharePanel._(profile: profile,),
    );
  }
  
  @override
  State<StatefulWidget> createState() => _ProfileInfoSharePanelState();
}

class _ProfileInfoSharePanelState extends State<ProfileInfoSharePanel> {

  final GlobalKey _repaintBoundaryKey = GlobalKey();
  bool _savingToPhotos = false;

  @override
  Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, children: [
    Align(alignment: Alignment.centerRight, child:
      Semantics( label: Localization().getStringEx('dialog.close.title', 'Close'), hint: Localization().getStringEx('dialog.close.hint', ''), inMutuallyExclusiveGroup: true, button: true, child:
        InkWell(onTap : _onTapClose, child:
          Container(padding: EdgeInsets.only(left: 8, right: 16, top: 16, bottom: 16), child:
            Styles().images.getImage('close-circle', excludeFromSemantics: true),
          ),
        ),
      ),
    ),
    Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
      RepaintBoundary(key: _repaintBoundaryKey, child:
        DirectoryAccountContactCard(account: Auth2PublicAccount(profile: widget.profile), printMode: true,),
      ),
    ),
    Padding(padding: EdgeInsets.symmetric(vertical: 16), child:
      Container(color: Styles().colors.surfaceAccent, height: 1,),
    ),
    _buildCommand(
        icon: Styles().images.getImage('down-to-bracket', size: _commandIconSize),
        text: Localization().getStringEx('panel.profile.info.share.command.button.save.text', 'Save to Photos'),
        onTap: _onTapSaveToPhotos,
        progress: _savingToPhotos,
    ),
    _buildCommand(
        icon: Styles().images.getImage('envelope', size: _commandIconSize),
        text: Localization().getStringEx('panel.profile.info.share.command.button.share.email.text', 'Share via Email'),
        onTap: _onTapShareViaEmail,
    ),
    _buildCommand(
        icon: Styles().images.getImage('message-lines', size: _commandIconSize),
        text: Localization().getStringEx('panel.profile.info.share.command.button.share.message.text', 'Share via Text Message'),
        onTap: _onTapShareViaTextMessage,
    ),
    _buildCommand(
        icon: Styles().images.getImage('copy-fa', size: _commandIconSize),
        text: Localization().getStringEx('panel.profile.info.share.command.button.copy.clipboard.text', 'Copy Text to Clipboard'),
        onTap: _onTapCopyTextToClipboard,
    ),
    Padding(padding: EdgeInsets.only(bottom: 16)),
  ],);

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
    RenderRepaintBoundary? boundary = JsonUtils.cast(_repaintBoundaryKey.currentContext?.findRenderObject());
    if (boundary != null) {
      setState(() {
        _savingToPhotos = true;
      });
      final ui.Image image = await boundary.toImage(pixelRatio: MediaQuery.of(context).devicePixelRatio * 3);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (mounted) {
        if (byteData != null) {
          Uint8List buffer = byteData.buffer.asUint8List();
          String saveFileName = 'Contact Card ${DateTimeUtils.localDateTimeToString(DateTime.now())}';
          bool? saveResult = await ImageUtils.saveToFs(buffer, saveFileName) ?? false;
          if (mounted) {
            setState(() {
              _savingToPhotos = false;
            });
            String message = saveResult ?
              Localization().getStringEx('panel.profile.info.share.command.save.succeeded', 'Contact card image saved successfully') :
              Localization().getStringEx('panel.profile.info.share.command.save.save.failed', 'Failed to save contact card image');
            AppAlert.showTextMessage(context, message).then((_){
              Navigator.of(context).pop();
            });
          }
        }
        else {
          setState(() {
            _savingToPhotos = false;
          });
          AppAlert.showTextMessage(context, Localization().getStringEx('panel.profile.info.share.command.save.create.failed', 'Failed to create contact card image')).then((_){
            Navigator.of(context).pop();
          });
        }
      }
    }
    else {
      AppAlert.showTextMessage(context, Localization().getStringEx('panel.profile.info.share.command.save.unknown.failed', 'Unknown problem occured')).then((_){
        Navigator.of(context).pop();
      });
    }

  }

  void _onTapShareViaEmail() => _onTBD();
  void _onTapShareViaTextMessage() => _onTBD();
  void _onTapCopyTextToClipboard() => _onTBD();

  void _onTBD() {
    AppAlert.showTextMessage(context, 'TBD').then((_){
      Navigator.of(context).pop();
    });
  }

  void _onTapClose() {
    Analytics().logSelect(target: 'Close', source: runtimeType.toString());
    Navigator.of(context).pop();
  }
}