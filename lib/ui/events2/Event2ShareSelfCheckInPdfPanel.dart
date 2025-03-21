import 'dart:typed_data';

import 'package:flutter/material.dart';
//import 'package:flutter/services.dart' show rootBundle;
import 'package:illinois/ext/Event2.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/service/events2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class Event2ShareSelfCheckInPdfPanel extends StatefulWidget {

  final Event2 event;
  String get eventId => event.id ?? '';

  Event2ShareSelfCheckInPdfPanel._(this.event);

  static void present(BuildContext context, {
    required Event2 event,
  }) {
    MediaQueryData mediaQuery = MediaQueryData.fromView(View.of(context));
    double height = mediaQuery.size.height - mediaQuery.viewPadding.top - mediaQuery.viewInsets.top - 128;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      clipBehavior: Clip.antiAlias,
      backgroundColor: Styles().colors.background,
      constraints: BoxConstraints(maxHeight: height),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => Event2ShareSelfCheckInPdfPanel._(event),
    );
  }

  @override
  State<StatefulWidget> createState() => _Event2ShareSelfCheckInPdfPanelState();
}

class _Event2ShareSelfCheckInPdfPanelState extends State<Event2ShareSelfCheckInPdfPanel> {

  bool _isPreparing = false;
  String? _contentMessage;
  String? _eventSecret;

  Map<String, Uint8List?>? _imagesData;
  Map<String, pw.Font?>? _fontsData;

  static final String _universityLogoKey = 'images/block-i-orange-blue-large.png';
  static final String _appStoreKey = 'images/app-store.png';
  static final String _googlePlayKey = 'images/google-play.png';

  Uint8List? get _universityLogo  => _imagesData?[_universityLogoKey];
  Uint8List? get _appStore        => _imagesData?[_appStoreKey];
  Uint8List? get _googlePlay      => _imagesData?[_googlePlayKey];

  pw.Font? get _openSansMedium    => _fontsData?['OpenSans-Medium'];
  pw.Font? get _openSansBold      => _fontsData?['OpenSans-Bold'];
  //pw.Font? get _openSansLight     => _fontsData?['OpenSans-Light'];
  //pw.Font? get _openSansRegular   => _fontsData?['OpenSans-Regular'];
  //pw.Font? get _openSansSemiBold  => _fontsData?['OpenSans-SemiBold'];
  //pw.Font? get _openSansExtraBold => _fontsData?['OpenSans-ExtraBold'];

  //static final int _qrCodeImageSize = 512;
  //Uint8List? _qrCodeImageData;


  @override
  void initState() {
    _initData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) => Stack(children: [
    _panelContent,
    Align(alignment: Alignment.topRight, child: _closeButton),
  ],);

  Widget get _panelContent {
    if (_isPreparing) {
      return _progressContent;
    }
    else if (_contentMessage != null) {
      return _messageContent;
    }
    else {
      return _pdfContent;
    }
  }


  Widget get _pdfContent =>
    Padding(padding: EdgeInsets.only(top: 24 + 2 * 16 /* close button size */, bottom: 16), child:
      Column(children: [
        Expanded(child:
          PdfPreview(
            build: (format) => generatePdf(format),
            scrollViewDecoration: BoxDecoration(color: Styles().colors.background),
            actions: null,
            initialPageFormat: PdfPageFormat.letter,
            canChangePageFormat: false,
            canChangeOrientation: false,
            canDebug: false,
          ),
        ),
      ]),
    );

  Widget get _progressContent => Center(child:
      SizedBox(width: 32, height: 32, child:
        CircularProgressIndicator(color: Styles().colors.fillColorSecondary, strokeWidth: 3,),
      )
  );

  Widget get _messageContent => Padding(padding: EdgeInsets.symmetric(horizontal: 32, vertical: 38), child:
      Column(children: [
        Expanded(child: Center(child:
          Text(_contentMessage ?? '', style: Styles().textStyles.getTextStyle('widget.message.regular'), textAlign: TextAlign.center,),
        )),
        Expanded(child: Container()),
      ],)
    );

  Widget get _closeButton =>
    Semantics( label: Localization().getStringEx('dialog.close.title', 'Close'), hint: Localization().getStringEx('dialog.close.hint', ''), inMutuallyExclusiveGroup: true, button: true, child:
      InkWell(onTap : _onTapClose, child:
        Container(padding: EdgeInsets.only(left: 8, right: 16, top: 16, bottom: 16), child:
          Styles().images.getImage('close-circle', excludeFromSemantics: true),
        ),
      ),
    );

  Future<void> _preparePdf() async {
    setState(() {
      _isPreparing = true;
    });
    String? secret = await Events2().getEventSelfCheckSecret(widget.eventId);
    setStateIfMounted(() {
      _isPreparing = false;
      if (secret != null) {
        _eventSecret = secret;
      }
      else {
        _contentMessage = Localization().getStringEx('panel.event2.share.self_check.error.secret.msg', 'Failed to retrieve Self Check-In security token.');
      }
    });
  }



  /*Uint8List? qrCodeImageData = await NativeCommunicator().getBarcodeImageData({
    'content': _selfCheckInUrl,
    'format': 'qrCode',
    'width': _qrCodeImageSize,
    'height': _qrCodeImageSize,
  });
  if (mounted) {
    setState(() {
      _isPreparing = false;
      if (qrCodeImageData != null) {
        _qrCodeImageData = qrCodeImageData;
      }
      else {
        _contentMessage = Localization().getStringEx('panel.event2.setup.attendance.self_check.generate_pdf.error.qr_code.msg', 'Failed to generate Self Check-In QR code image.');
      }
    });
  } */

  String get _selfCheckInUrl =>
    Events2.eventSelfCheckUrl(widget.eventId, secret: _eventSecret ?? '');

  Future<Uint8List> generatePdf(PdfPageFormat pageFormat) async {

    List<pw.Font> fonts = await Future.wait([
      PdfGoogleFonts.openSansRegular(),
      PdfGoogleFonts.openSansBold(),
    ]);

    PdfColor borderColor = PdfColor.fromInt(Styles().colors.dividerLineAccent.toARGB32());
    PdfColor textColor = PdfColor.fromInt(Styles().colors.textColorPrimary.toARGB32());
    PdfColor bottomBackColor = PdfColor.fromInt(Styles().colors.fillColorPrimary.toARGB32());
    PdfColor bottomTextColor = PdfColor.fromInt(Styles().colors.textColorPrimary.toARGB32());

    final pdf = pw.Document();
    pdf.addPage(pw.Page(
      pageTheme: pw.PageTheme(
        pageFormat: pageFormat,
        margin: pw.EdgeInsets.all(0),
        theme: pw.ThemeData.withFont(
          base: _openSansMedium,
          bold: _openSansBold,
        ),
      ),
      build: (context) =>
        pw.Container(
          margin: const pw.EdgeInsets.all(24),
          decoration: pw.BoxDecoration(border: pw.Border.all(color: borderColor, width: 1.5),),
          width: double.infinity,
          height: double.infinity,
          child: pw.Column(children: [
            pw.Expanded(child:
              pw.Padding(padding: const pw.EdgeInsets.all(24), child:
                pw.Column(children: [
                  pw.Spacer(flex: 2),
                  pw.Image(pw.MemoryImage(_universityLogo ?? Uint8List(0),), width: 30, height: 30, ),
                  pw.Spacer(flex: 2),
                  pw.Text('Event Check-In', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 24,),),
                  pw.Spacer(flex: 1),
                  pw.Text(widget.event.name ?? '', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18,),),
                  pw.Text(widget.event.longDisplayStartDateTime ?? '', style: pw.TextStyle(fontWeight: pw.FontWeight.normal, fontSize: 18,),),
                  pw.Spacer(flex: 3),
                  //pw.Image(pw.MemoryImage(_qrCodeImageData ?? Uint8List(0),), width: 192, height: 192, ),
                  pw.BarcodeWidget(data: _selfCheckInUrl, width: 192, height: 192, barcode: pw.Barcode.qrCode(), drawText: false,),
                  pw.Spacer(flex: 3), //pw.Padding(padding: const pw.EdgeInsets.only(top: 16),),
                ]),
              ),
            ),
            pw.Container(color: bottomBackColor, padding: const pw.EdgeInsets.all(24), child:
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('1. To check in, you must be in signed in to the Illinois app at a privacy level 4 or 5.', style: pw.TextStyle(fontSize: 16, color: bottomTextColor),),
                pw.Padding(padding: const pw.EdgeInsets.only(top: 8),),
                pw.Text('2. Using your phone’s camera, scan the QR code.', style: pw.TextStyle(fontSize: 16, color: bottomTextColor),),
                pw.Padding(padding: const pw.EdgeInsets.only(top: 8),),
                pw.Text('3. You should see a confirm action in the Illinois app that you are now checked in for this event.', style: pw.TextStyle(fontSize: 16, color: bottomTextColor),),
                pw.Padding(padding: const pw.EdgeInsets.only(top: 24),),
                pw.Row(children: [
                  pw.Spacer(),
                  if (Config().upgradeIOSUrl?.isNotEmpty == true)
                    pw.UrlLink(destination: Config().upgradeIOSUrl ?? '', child:
                      pw.Image(pw.MemoryImage(_appStore ?? Uint8List(0),), width: 50 * 2020 / 610, height: 50, )
                    ),

                  if ((Config().upgradeIOSUrl?.isNotEmpty == true) && (Config().upgradeAndroidUrl?.isNotEmpty == true))
                    pw.Container(width: 32),

                  if (Config().upgradeAndroidUrl?.isNotEmpty == true)
                    pw.UrlLink(destination: Config().upgradeAndroidUrl ?? '', child:
                      pw.Image(pw.MemoryImage(_googlePlay ?? Uint8List(0),), width: 50 * 2020 / 610, height: 50, )
                    ),
                  pw.Spacer(),
                ]),
              ]),
            ),
        ],),
      ),
      ),
    );

    return pdf.save();
  }

  Future<void> _initData() async {
    setState(() {
      _isPreparing = true;
    });
    List<dynamic> results = await Future.wait([
      Events2().getEventSelfCheckSecret(widget.eventId),
      _preloadImages(),
      _preloadFonts(),
    ]);
    if (mounted) {
      String? secret = JsonUtils.stringValue(results[0]);
      Map<String, Uint8List?>? imagesData = JsonUtils.mapCastValue(JsonUtils.mapValue(results[1]));
      Map<String, pw.Font?>? fontsData = JsonUtils.mapCastValue(JsonUtils.mapValue(results[2]));
      setState(() {
        _isPreparing = false;
        if (secret != null) {
          _eventSecret = secret;
        }
        else {
          _contentMessage = Localization().getStringEx('panel.event2.share.self_check.error.secret.msg', 'Failed to retrieve Self Check-In security token.');
        }
        _imagesData = imagesData;
        _fontsData = fontsData;
      });
    }
  }

  Future<Map<String, Uint8List?>> _preloadImages() async {
    List<String> imageNames = [_universityLogoKey, _appStoreKey, _googlePlayKey, ];
    Iterable<Future<ByteData?>> imageFutures = imageNames.map((String imageName) => AppBundle.loadBytes(imageName));
    List<ByteData?> images = await Future.wait(imageFutures);
    Map<String, Uint8List?> imagesMap = <String, Uint8List>{};
    for (int index = 0; index < imageNames.length; index++) {
      imagesMap[imageNames[index]] = ListUtils.entry<ByteData?>(images, index)?.buffer.asUint8List();
    }
    return imagesMap;
  }

  Future<Map<String, pw.Font?>> _preloadFonts() async {
    List<pw.Font> fonts = await Future.wait([
      PdfGoogleFonts.openSansLight(),
      PdfGoogleFonts.openSansRegular(),
      PdfGoogleFonts.openSansMedium(),
      PdfGoogleFonts.openSansSemiBold(),
      PdfGoogleFonts.openSansBold(),
      PdfGoogleFonts.openSansExtraBold(),
    ]);
    Map<String, pw.Font?> fontsMap = <String, pw.Font>{};
    for (pw.Font font in fonts) {
      fontsMap[font.fontName] = font;
    }
    return fontsMap;
  }

  void _onTapClose() {
    Analytics().logSelect(target: 'Close', source: runtimeType.toString());
    Navigator.of(context).pop();
  }
}