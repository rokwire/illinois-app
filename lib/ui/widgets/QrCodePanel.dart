
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:neom/model/Analytics.dart';
import 'package:neom/model/StudentCourse.dart';
import 'package:neom/service/Analytics.dart';
import 'package:neom/service/Config.dart';
import 'package:neom/service/Gateway.dart';
import 'package:neom/service/NativeCommunicator.dart';
import 'package:neom/service/Safety.dart';
import 'package:neom/service/SkillsSelfEvaluation.dart';
import 'package:neom/ui/events2/Event2HomePanel.dart';
import 'package:neom/ui/widgets/HeaderBar.dart';
import 'package:neom/utils/AppUtils.dart';
import 'package:intl/intl.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/model/group.dart';
import 'package:rokwire_plugin/service/events2.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/image_utils.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:share/share.dart';

class QrCodePanel extends StatefulWidget with AnalyticsInfo { //TBD localize
  //final Event2? event;
  //const Event2QrCodePanel({required this.event});

  final String deepLinkUrl;

  final String saveFileName;
  final String? saveWatermarkText;
  final TextStyle? saveWatermarkStyle;

  final String? title;
  final String? description;

  final AnalyticsFeature? analyticsFeature; //This overrides AnalyticsInfo.analyticsFeature getter

  const QrCodePanel({Key? key,
    required this.deepLinkUrl,

    required this.saveFileName,
    this.saveWatermarkText,
    this.saveWatermarkStyle,

    this.title,
    this.description,

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

  factory QrCodePanel.fromSafeWalk({ Key? key, Map<String, dynamic>? origin, Map<String, dynamic>? destination, AnalyticsFeature? analyticsFeature}) => QrCodePanel(
    key: key,
    deepLinkUrl: Safety.safeWalkDetailUrl({
      'origin': (origin != null) ? JsonUtils.encode(origin) : null,
      'destination': (destination != null) ? JsonUtils.encode(destination) : null,
    }),
    saveFileName: 'SafeWalks ${DateTimeUtils.localDateTimeToString(DateTime.now())}',
    saveWatermarkText: Localization().getStringEx('panel.safewalks_request.header.title', 'SafeWalks'),
    saveWatermarkStyle: TextStyle(fontFamily: Styles().fontFamilies.bold, fontSize: 64, color: Styles().colors.textSurface),
    title: Localization().getStringEx('panel.qr_code.feature.title', 'Share this feature'),
    description: Localization().getStringEx('panel.qr_code.feature.description.label', 'Want to invite other Illinois app users to view this feature? Use one of the sharing options below.'),
    analyticsFeature: analyticsFeature,
  );

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(
        title: widget.title,
        textAlign: TextAlign.center,
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
                    widget.description ?? '',
                    style: Styles().textStyles.getTextStyle("widget.title.regular.fat")
                ),
                Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: ((_qrCodeBytes != null)
                      ? Semantics(
                    label: Localization().getStringEx('panel.qr_code.code.hint', "QR code image"),
                    child: Container(
                      decoration: BoxDecoration(color: Styles().colors.surface, borderRadius: BorderRadius.all(Radius.circular(5))),
                      padding: EdgeInsets.all(5),
                      child: Image.memory(
                        _qrCodeBytes!,
                        fit: BoxFit.fitWidth,
                        semanticLabel: Localization().getStringEx("panel.qr_code.primary.heading.title", "Promotion Key"),
                      ),
                    ),
                  )
                      : Container(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.width - 10,
                    child: Align(
                      alignment: Alignment.center,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors.fillColorSecondary),
                        strokeWidth: 2,
                      ),
                    ),
                  )),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 24, bottom: 12),
                  child: RoundedButton(
                    label: Localization().getStringEx('panel.qr_code.button.save.title', 'Save QR Code'),
                    hint: '',
                    textStyle: Styles().textStyles.getTextStyle("widget.title.regular.fat"),
                    backgroundColor: Styles().colors.background,
                    borderColor: Styles().colors.fillColorSecondary,
                    onTap: _onTapSave,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: RoundedButton(
                    label: Localization().getStringEx('panel.qr_code.button.share.title', 'Share Link'),
                    hint: '',
                    textStyle: Styles().textStyles.getTextStyle("widget.button.title.medium.fat"),
                    backgroundColor: Styles().colors.background,
                    borderColor: Styles().colors.fillColorSecondary,
                    onTap: _onTapShare,
                  ),
                )
              ],
            ),
          ),
        ),
      ),
      backgroundColor: Styles().colors.background,
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
    String? redirectUrl = Config().deepLinkRedirectUrl;
    return ((redirectUrl != null) && redirectUrl.isNotEmpty) ? UrlUtils.buildWithQueryParameters(redirectUrl, <String, String>{
      'target': widget.deepLinkUrl
    }) : widget.deepLinkUrl;
  }
}