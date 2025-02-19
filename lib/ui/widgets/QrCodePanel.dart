
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:illinois/ext/Auth2.dart';
import 'package:illinois/model/Analytics.dart';
import 'package:illinois/model/StudentCourse.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/Gateway.dart';
import 'package:illinois/service/NativeCommunicator.dart';
import 'package:illinois/service/Safety.dart';
import 'package:illinois/service/SkillsSelfEvaluation.dart';
import 'package:illinois/ui/events2/Event2HomePanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/model/group.dart';
import 'package:rokwire_plugin/model/places.dart' as places;
import 'package:rokwire_plugin/service/events2.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/places.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/image_utils.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:share/share.dart';

class QrCodePanel extends StatefulWidget with AnalyticsInfo { //TBD localize
  //final Event2? event;
  //const Event2QrCodePanel({required this.event});

  final String? deepLinkUrl;
  final String? digitalCardQrCode;
  final String? digitalCardShare;

  final String saveFileName;
  final String? saveWatermarkText;
  final TextStyle? saveWatermarkStyle;

  final String? title;
  final String? description;

  final bool modalSheet;
  final AnalyticsFeature? analyticsFeature; //This overrides AnalyticsInfo.analyticsFeature getter

  QrCodePanel({Key? key,
    this.deepLinkUrl,
    this.digitalCardQrCode,
    this.digitalCardShare,

    required this.saveFileName,
    this.saveWatermarkText,
    this.saveWatermarkStyle,

    this.title,
    this.description,

    this.modalSheet = false,
    this.analyticsFeature,
  });

  factory QrCodePanel.fromEvent(Event2? event, {Key? key, AnalyticsFeature? analyticsFeature }) => QrCodePanel(
    key: key,
    deepLinkUrl: Events2.eventDetailUrl(event),
      saveFileName: 'event - ${event?.name}',
      saveWatermarkText: event?.name,
      saveWatermarkStyle: TextStyle(fontFamily: Styles().fontFamilies.bold, fontSize: 64, color: Styles().colors.textSurface),
    title: Localization().getStringEx('panel.qr_code.event.title', 'Share this event'),
    description: Localization().getStringEx('panel.qr_code.event.description', 'Want to invite other Illinois app users to view this event? Use one of the sharing options below.'),
    analyticsFeature: analyticsFeature,
  );

  factory QrCodePanel.fromEventFilterParam(Event2FilterParam filterParam, {Key? key, AnalyticsFeature? analyticsFeature}) => QrCodePanel(
    key: key,
    deepLinkUrl: Events2.eventsQueryUrl(filterParam.toUriParams()),
      saveFileName: "events ${DateFormat('yyyy-MM-dd HH.mm.ss').format(DateTime.now())}",
      saveWatermarkText: filterParam.buildDescription().map((span) => span.toPlainText()).join(),
      saveWatermarkStyle: TextStyle(fontFamily: Styles().fontFamilies.regular, fontSize: 32, color: Styles().colors.textSurface),
    title: Localization().getStringEx('panel.qr_code.event_query.title', 'Share this event set'),
    description: Localization().getStringEx('panel.qr_code.event_query.description', 'Want to invite other Illinois app users to view this set of filtered events? Use one of the sharing options below.'),
    analyticsFeature: analyticsFeature,
  );

  factory QrCodePanel.fromGroup(Group? group, {Key? key, AnalyticsFeature? analyticsFeature}) => QrCodePanel(
    key: key,
    deepLinkUrl: '${Groups().groupDetailUrl}?group_id=${group?.id}',
      saveFileName: 'group - ${group?.title}',
      saveWatermarkText: group?.title,
      saveWatermarkStyle: TextStyle(fontFamily: Styles().fontFamilies.bold, fontSize: 64, color: Styles().colors.textSurface),
    title: Localization().getStringEx('panel.qr_code.group.title', 'Share this group'),
    description: Localization().getStringEx('panel.qr_code.group.description.label', 'Want to invite other Illinois app users to view this group? Use one of the sharing options below.'),
    analyticsFeature: analyticsFeature,
  );

  factory QrCodePanel.skillsSelfEvaluation({Key? key, AnalyticsFeature? analyticsFeature}) => QrCodePanel(
    key: key,
    deepLinkUrl: SkillsSelfEvaluation.skillsSelfEvaluationUrl,
    saveFileName: 'skills self-evaluation',
    saveWatermarkText: 'Skills Self-Evaluation',
    saveWatermarkStyle: TextStyle(fontFamily: Styles().fontFamilies.bold, fontSize: 64, color: Styles().colors.textSurface),
    title: Localization().getStringEx('panel.qr_code.feature.title', 'Share this feature'),
    description: Localization().getStringEx('panel.qr_code.feature.description.label', 'Want to invite other Illinois app users to view this feature? Use one of the sharing options below.'),
    analyticsFeature: analyticsFeature,
  );

  factory QrCodePanel.fromBuilding(Building? building, {Key? key, AnalyticsFeature? analyticsFeature}) => QrCodePanel(
    key: key,
    deepLinkUrl: '${Gateway.buildingDetailUrl}?building_number=${building?.number}',
    saveFileName: 'Location - ${building?.name}',
    saveWatermarkText: building?.name,
    saveWatermarkStyle: TextStyle(fontFamily: Styles().fontFamilies.bold, fontSize: 64, color: Styles().colors.textSurface),
    title: Localization().getStringEx('panel.qr_code.building.title', 'Share this location'),
    description: Localization().getStringEx('panel.qr_code.building.description.label', 'Want to invite other Illinois app users to view this location? Use one of the sharing options below.'),
    analyticsFeature: analyticsFeature,
  );

  factory QrCodePanel.fromPlace(places.Place? place, {Key? key, AnalyticsFeature? analyticsFeature}) => QrCodePanel(
    key: key,
    deepLinkUrl: Places.placeDetailUrl(place),
    saveFileName: 'Location - ${place?.name}',
    saveWatermarkText: place?.name,
    saveWatermarkStyle: TextStyle(fontFamily: Styles().fontFamilies.bold, fontSize: 64, color: Styles().colors.textSurface),
    title: Localization().getStringEx('panel.qr_code.building.title', 'Share this location'),
    description: Localization().getStringEx('panel.qr_code.building.description.label', 'Want to invite other Illinois app users to view this location? Use one of the sharing options below.'),
    analyticsFeature: analyticsFeature,
  );

  factory QrCodePanel.fromSafeWalk({ Key? key, Map<String, dynamic>? origin, Map<String, dynamic>? destination, AnalyticsFeature? analyticsFeature}) => QrCodePanel(
    key: key,
    deepLinkUrl: Safety.safeWalkDetailUrl({
      'origin': (origin != null) ? JsonUtils.encode(origin) : null,
      'destination': (destination != null) ? JsonUtils.encode(destination) : null,
    }),
    saveFileName: 'SafeWalks ${DateTimeUtils.localDateTimeToString(DateTime.now())}',
    saveWatermarkText: Localization().getStringEx('model.safety.safewalks.title', 'SafeWalks'),
    saveWatermarkStyle: TextStyle(fontFamily: Styles().fontFamilies.bold, fontSize: 64, color: Styles().colors.textSurface),
    title: Localization().getStringEx('panel.qr_code.feature.title', 'Share this feature'),
    description: Localization().getStringEx('panel.qr_code.feature.description.label', 'Want to invite other Illinois app users to view this feature? Use one of the sharing options below.'),
  );

  factory QrCodePanel.fromProfile({ Key? key, Auth2UserProfile? profile, Uint8List? photoImageData, Uint8List? pronunciationAudioData, bool modalSheet = false, AnalyticsFeature? analyticsFeature}) => QrCodePanel(
    key: key, modalSheet: modalSheet,
    digitalCardQrCode: profile?.toDigitalCard(), // photoImageData: photoImageData
    digitalCardShare: profile?.toDigitalCard(photoImageData: photoImageData),
    saveFileName: profile?.vcardFullName ?? 'Digital Business Card',
    saveWatermarkText: profile?.vcardFullName,
    saveWatermarkStyle: TextStyle(fontFamily: Styles().fontFamilies.bold, fontSize: 64, color: Styles().colors.textSurface),
    title: Localization().getStringEx('panel.qr_code.digital_card.title', 'Digital Business Card'),
    description: Localization().getStringEx('panel.qr_code.digital_card.description.label', 'Scan the QR code image below to import your Digital Business Card.'),
  );

  static void presentProfile(BuildContext context, { Key? key, Auth2UserProfile? profile, Uint8List? photoImageData, Uint8List? pronunciationAudioData, AnalyticsFeature? analyticsFeature}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      clipBehavior: Clip.antiAlias,
      backgroundColor: Styles().colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => QrCodePanel.fromProfile(
        profile: profile,
        photoImageData: photoImageData,
        pronunciationAudioData: pronunciationAudioData,
        modalSheet: true,
      ),
    );
  }

  @override
  State<StatefulWidget> createState() => _QrCodePanelState();
}

class _QrCodePanelState extends State<QrCodePanel> {
  static final int _imageSize = 1024;
  Uint8List? _qrCodeBytes;

  @override
  void initState() {
    super.initState();
    _loadQrImageBytes().then((imageBytes) {
      setStateIfMounted(() {
        _qrCodeBytes = imageBytes;
      });
    });
  }

  @override
  Widget build(BuildContext context) => widget.modalSheet ? _modalSheetContent : _scaffoldContent;

  Widget get _modalSheetContent => Column(mainAxisSize: MainAxisSize.min, children: [
    Row(children: [
      Expanded(child:
        Padding(padding: EdgeInsets.only(left: 24,), child:
          Text(widget.title ?? '', style: Styles().textStyles.getTextStyle('widget.message.regular.extra_fat'),)
        )
      ),
      Semantics( label: Localization().getStringEx('dialog.close.title', 'Close'), hint: Localization().getStringEx('dialog.close.hint', ''), inMutuallyExclusiveGroup: true, button: true, child:
        InkWell(onTap : _onTapClose, child:
          Container(padding: EdgeInsets.only(left: 8, right: 24, top: 16, bottom: 16), child:
            Styles().images.getImage('close-circle', excludeFromSemantics: true),
          ),
        ),
      ),
    ],),
    Padding(padding: EdgeInsets.only(top: 12, bottom: 24), child:
      _panelContent,
    ),
  ],);

  Widget get _scaffoldContent => Scaffold(
    appBar: HeaderBar(title: widget.title, textAlign: TextAlign.center,),
    backgroundColor: Styles().colors.background,
    body: SingleChildScrollView(child: Padding(padding: EdgeInsets.symmetric(vertical: 24), child: _panelContent)),
  );

  Widget get _panelContent =>
    Container(padding: EdgeInsets.symmetric(horizontal: 24), color: _backgroundColor, child:
      Column(children: [
        Text(widget.description ?? '', style: Styles().textStyles.getTextStyle("widget.title.regular.fat")),
        Padding(padding: EdgeInsets.only(top: 24), child: (_qrCodeBytes != null) ?
          Semantics(label: Localization().getStringEx('panel.qr_code.code.hint', "QR code image"), child:
            Container(
              decoration: BoxDecoration(color: Styles().colors.white, borderRadius: BorderRadius.all(Radius.circular(5))),
              padding: EdgeInsets.all(5),
              child: Image.memory(_qrCodeBytes!,
                fit: BoxFit.fitWidth,
                semanticLabel: Localization().getStringEx("panel.qr_code.primary.heading.title", "Promotion Key"),
              ),
            ),
          ) :
          Container(width: MediaQuery.of(context).size.width, height: MediaQuery.of(context).size.width - 10, child:
            Align(alignment: Alignment.center, child:
              CircularProgressIndicator(color: Styles().colors.fillColorSecondary, strokeWidth: 2,),
            ),
          ),
        ),
        Padding(padding: EdgeInsets.only(top: 24), child:
          RoundedButton(
            label: Localization().getStringEx('panel.qr_code.button.save.title', 'Save QR Code'),
            hint: '',
            textStyle: Styles().textStyles.getTextStyle("widget.title.regular.fat"),
            backgroundColor: _backgroundColor,
            borderColor: Styles().colors.fillColorSecondary,
            onTap: _onTapSave,
          ),
        ),
        if (_canShareLink)
          Padding(padding: EdgeInsets.only(top: 12), child:
            RoundedButton(
              label: Localization().getStringEx('panel.qr_code.button.share_link.title', 'Share Link'),
              hint: '',
              textStyle: Styles().textStyles.getTextStyle("widget.button.title.medium.fat"),
              backgroundColor: _backgroundColor,
              borderColor: Styles().colors.fillColorSecondary,
              onTap: _onTapShareLink,
            ),
          ),
        if (_canShareDigitalCard)
          Padding(padding: EdgeInsets.only(top: 12), child:
            RoundedButton(
              label: Localization().getStringEx('panel.qr_code.button.share_digital_card.title', 'Share Digital Business Card'),
              hint: '',
              textStyle: Styles().textStyles.getTextStyle("widget.button.title.medium.fat"),
              backgroundColor: _backgroundColor,
              borderColor: Styles().colors.fillColorSecondary,
              onTap: _onTapShareDigitalCard,
            ),
          ),
          Padding(padding: EdgeInsets.only(top: 12)),
      ],),
    );

  Color? get _backgroundColor => widget.modalSheet ?
    Styles().colors.white : Styles().colors.background;

  Future<Uint8List?> _loadQrImageBytes() async {
    return await NativeCommunicator().getBarcodeImageData({
      'content': _promotionUrl ?? widget.digitalCardQrCode,
      'format': 'qrCode',
      'width': _imageSize,
      'height': _imageSize,
    });
  }

  Future<void> _saveQrCode() async {
    Analytics().logSelect(target: "Save QR Code");

    if (_qrCodeBytes == null) {
      AppAlert.showDialogResult(context, Localization().getStringEx("panel.qr_code.alert.no_qr_code.msg", "There is no QR Code"));
    } else {
      Uint8List? updatedImageBytes = await ImageUtils.applyLabelOverImage(_qrCodeBytes, widget.saveWatermarkText,
        width: _imageSize.toDouble(),
        height: _imageSize.toDouble(),
        textStyle: widget.saveWatermarkStyle,
      );
      bool result = (updatedImageBytes != null);
      if (result) {
        result = await ImageUtils.saveToFs(updatedImageBytes, widget.saveFileName) ?? false;
      }

      const String destinationMacro = '{{Destination}}';
      String messageSource = (result
          ? (Localization().getStringEx("panel.qr_code.alert.save.success.msg", "Successfully saved qr code in $destinationMacro"))
          : Localization().getStringEx("panel.qr_code.alert.save.fail.msg", "Failed to save qr code in $destinationMacro"));
      String destinationTargetText = (defaultTargetPlatform == TargetPlatform.android)
          ? Localization().getStringEx("panel.qr_code.alert.save.success.pictures", "Pictures")
          : Localization().getStringEx("panel.qr_code.alert.save.success.gallery", "Gallery");
      String message = messageSource.replaceAll(destinationMacro, destinationTargetText);
      AppAlert.showDialogResult(context, message).then((value) {
        if(result) {
          Navigator.of(context).pop();
        }
      });
    }
  }

  void _onTapSave() {
    Analytics().logSelect(target: 'Save Qr Code');
    _saveQrCode();
  }

  String? get _promotionUrl {
    if (widget.deepLinkUrl?.isNotEmpty == true) {
      String? redirectUrl = Config().deepLinkRedirectUrl;
      return ((redirectUrl != null) && redirectUrl.isNotEmpty) ? UrlUtils.buildWithQueryParameters(redirectUrl, <String, String>{
        'target': widget.deepLinkUrl!
      }) : widget.deepLinkUrl!;
    }
    else {
      return null;
    }
  }

  bool get _canShareLink => (widget.deepLinkUrl?.isNotEmpty == true);

  void _onTapShareLink() {
    Analytics().logSelect(target: 'Share QR Code');
    String? promotionUrl = _promotionUrl;
    if (promotionUrl != null) {
      Share.share(promotionUrl);
    }
  }

  bool get _canShareDigitalCard => (widget.digitalCardShare?.isNotEmpty == true);

  void _onTapShareDigitalCard() async {
    Analytics().logSelect(target: 'Share Digital Card');
    final String dir = (await getApplicationDocumentsDirectory()).path;
    final String fullPath = '$dir/${widget.saveFileName}.vcf';
    File capturedFile = File(fullPath);
    await capturedFile.writeAsString(widget.digitalCardShare ?? '');
    if (mounted) {
      Share.shareFiles([fullPath],
        mimeTypes: ['text/vcard'],
        text: widget.saveWatermarkText,
      );
    }
  }

  void _onTapClose() {
    Analytics().logSelect(target: 'Close', source: runtimeType.toString());
    Navigator.of(context).pop();
  }

}