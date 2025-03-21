import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:illinois/ext/Event2.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Config.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/service/auth2.dart';
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
    //final double iconSize = _Event2ShareSelfCheckInPdfPanelState._barIconSize;
    //final double iconPadding = _Event2ShareSelfCheckInPdfPanelState._barIconPadding;
    final double barHeight = _Event2ShareSelfCheckInPdfPanelState._barHeight;
    final EdgeInsets previewPageMargin = _Event2ShareSelfCheckInPdfPanelState._previewPageMargin;
    final PdfPageFormat pdfPageFormat = _Event2ShareSelfCheckInPdfPanelState._pdfPageFormat;

    MediaQueryData mediaQuery = MediaQueryData.fromView(View.of(context));
    double screenWidth = max(mediaQuery.size.width - mediaQuery.viewPadding.horizontal - mediaQuery.viewInsets.horizontal, 0);
    double pageWidth = max(screenWidth - previewPageMargin.horizontal, 0);
    double pageHeight = pageWidth * pdfPageFormat.height / pdfPageFormat.width;
    pageHeight += 2 * barHeight;
    pageHeight += previewPageMargin.vertical;
    //pageHeight += mediaQuery.viewPadding.bottom + mediaQuery.viewInsets.bottom;
    //pageHeight += 12; // 72

    double screenHeight = max(mediaQuery.size.height - mediaQuery.viewPadding.top - mediaQuery.viewInsets.top, 0);
    pageHeight = min(screenHeight, pageHeight);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      clipBehavior: Clip.antiAlias,
      backgroundColor: Styles().colors.background,
      constraints: BoxConstraints(maxHeight: pageHeight),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => Event2ShareSelfCheckInPdfPanel._(event),
    );
  }

  @override
  State<StatefulWidget> createState() => _Event2ShareSelfCheckInPdfPanelState();
}

class _Event2ShareSelfCheckInPdfPanelState extends State<Event2ShareSelfCheckInPdfPanel> {

  bool _isPreparing = false;
  bool _preparingShare = false;
  String? _contentMessage;
  String? _eventSecret;

  Map<String, Uint8List?>? _imagesData;
  Map<String, pw.Font?>? _fontsData;

  static const String _universityLogoKey = 'images/block-i-orange-blue-large.png';
  static const String _appStoreKey = 'images/app-store.png';
  static const String _googlePlayKey = 'images/google-play.png';

  Uint8List? get _universityLogo  => _imagesData?[_universityLogoKey];
  Uint8List? get _appStore        => _imagesData?[_appStoreKey];
  Uint8List? get _googlePlay      => _imagesData?[_googlePlayKey];

  pw.Font? get _openSansMedium    => _fontsData?['OpenSans-Medium'];
  pw.Font? get _openSansBold      => _fontsData?['OpenSans-Bold'];
  //pw.Font? get _openSansLight     => _fontsData?['OpenSans-Light'];
  //pw.Font? get _openSansRegular   => _fontsData?['OpenSans-Regular'];
  //pw.Font? get _openSansSemiBold  => _fontsData?['OpenSans-SemiBold'];
  //pw.Font? get _openSansExtraBold => _fontsData?['OpenSans-ExtraBold'];

  //static const int _qrCodeImageSize = 512;
  //Uint8List? _qrCodeImageData;

  static const double _barIconSize = 20;
  static const double _barIconPadding = 16;
  static const _pdfPageFormat = PdfPageFormat.letter;
  static double get _barHeight => _barIconSize * 1.2 + 2 * _barIconPadding;
  static const EdgeInsets _previewPageMargin = const EdgeInsets.symmetric(horizontal: _barIconPadding);

  String get _selfCheckInUrl =>
    Events2.eventSelfCheckUrl(widget.eventId, secret: _eventSecret ?? '');

  String get _saveFileName =>
    'Check-In PDF "${widget.event.name}" - ${DateTimeUtils.localDateTimeFileStampToString(DateTime.now())}';

  @override
  void initState() {
    _initData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) =>
    Column(children: [
    _headerBar,
    Expanded(child: _panelContent),
    _footerSpacer,
  ]);

  // Panel Content

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

  // PDF Content

  Widget get _pdfContent =>
    Column(children: [
      Expanded(child:
        PdfPreview(
          build: (format) => generatePdf(format),
          initialPageFormat: _pdfPageFormat,
          scrollViewDecoration: BoxDecoration(color: Styles().colors.background),
          useActions: false,
          enableScrollToPage: true,
          loadingWidget: _progressControl,
          previewPageMargin: _previewPageMargin,
        ),
      ),
    ]);

  Future<Uint8List> generatePdf(PdfPageFormat pageFormat) async {

    PdfColor borderColor = PdfColor.fromInt(Styles().colors.dividerLineAccent.toARGB32());
    PdfColor bottomBackColor = PdfColor.fromInt(Styles().colors.fillColorPrimary.toARGB32());
    PdfColor bottomTextColor = PdfColor.fromInt(Styles().colors.textColorPrimary.toARGB32());

    String title = Localization().getStringEx('panel.event2.share.self_check.title', 'Event Check In');
    String? appStoreUrl = Config().upgradeIOSUrl;
    String? playStoreUrl = Config().upgradeAndroidUrl;
    final Size storeButtonSize = Size(50 * 2020 / 610, 50);

    final pdf = pw.Document(
      title: title,
      author: Auth2().uiucUser?.fullName,
    );
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
          margin: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 32),
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
                  pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 24,),),
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
                pw.Text(Localization().getStringEx('panel.event2.share.self_check.description.1', '1. To check in, you must be in signed in to the Illinois app at a privacy level 4 or 5.'), style: pw.TextStyle(fontSize: 16, color: bottomTextColor),),
                pw.Padding(padding: const pw.EdgeInsets.only(top: 8),),
                pw.Text(Localization().getStringEx('panel.event2.share.self_check.description.2', '2. Using your phone’s camera, scan the QR code.'), style: pw.TextStyle(fontSize: 16, color: bottomTextColor),),
                pw.Padding(padding: const pw.EdgeInsets.only(top: 8),),
                pw.Text(Localization().getStringEx('panel.event2.share.self_check.description.3', '3. You should see a confirm action in the Illinois app that you are now checked in for this event.'), style: pw.TextStyle(fontSize: 16, color: bottomTextColor),),
                pw.Padding(padding: const pw.EdgeInsets.only(top: 24),),
                pw.Row(children: [
                  pw.Spacer(),
                  if ((appStoreUrl != null) && appStoreUrl.isNotEmpty)
                    pw.UrlLink(destination: appStoreUrl, child:
                      pw.Image(pw.MemoryImage(_appStore ?? Uint8List(0),), width: storeButtonSize.width, height: storeButtonSize.height, )
                    ),

                  if ((appStoreUrl?.isNotEmpty == true) && (playStoreUrl?.isNotEmpty == true))
                    pw.Container(width: 32),

                  if ((playStoreUrl != null) && playStoreUrl.isNotEmpty)
                    pw.UrlLink(destination: playStoreUrl, child:
                      pw.Image(pw.MemoryImage(_googlePlay ?? Uint8List(0),), width: storeButtonSize.width, height: storeButtonSize.height, )
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

  // Other Content Types

  Widget get _progressContent =>
    Center(child:_progressControl  );

  Widget get _progressControl => SizedBox(width: 32, height: 32, child:
    CircularProgressIndicator(color: Styles().colors.fillColorSecondary, strokeWidth: 3,),
  );

  Widget get _messageContent => Padding(padding: EdgeInsets.symmetric(horizontal: 32, vertical: 38), child:
      Column(children: [
        Expanded(child: Center(child:
          Text(_contentMessage ?? '', style: Styles().textStyles.getTextStyle('widget.message.regular'), textAlign: TextAlign.center,),
        )),
        Expanded(child: Container()),
      ],)
    );

  // Header/Footer Bars && Commands

  Widget get _headerBar => Row(children: [
    Expanded(child: _isHeaderBarActionsAvailable ? _headerBarActions : Container()),
    _closeButton,
  ],);

  bool get _isHeaderBarActionsAvailable => !_isPreparing && (_contentMessage?.isNotEmpty != true);

  Widget get _headerBarActions => Wrap(children: [
    _printButton, _shareButton
  ],);

  Widget get _printButton => _iconButton('print',
    label: Localization().getStringEx('dialog.print.title', 'Print'),
    hint: Localization().getStringEx('dialog.print.hint', ''),
    padding: const EdgeInsets.only(left: _barIconPadding, right: _barIconPadding / 2, top: _barIconPadding, bottom: _barIconPadding),
    onTap: _onTapPrint,
  );

  void _onTapPrint() {
    Analytics().logSelect(target: 'Print', source: runtimeType.toString());
    Printing.layoutPdf(onLayout: (PdfPageFormat format) async => generatePdf(format));
  }

  /*Widget get _saveButton => _iconButton('download',
    label: Localization().getStringEx('dialog.save.title', 'Save'),
    hint: Localization().getStringEx('dialog.save.hint', ''),
    padding: const EdgeInsets.only(left: 8, right: 8, top: 16, bottom: 16),
    onTap: _onTapSave,
  );

  void _onTapSave() {
    Analytics().logSelect(target: 'Save', source: runtimeType.toString());
  }*/

  Widget get _shareButton => _iconButton('share-nodes',
    label: Localization().getStringEx('dialog.share.title', 'Share'),
    hint: Localization().getStringEx('dialog.share.hint', ''),
    padding: const EdgeInsets.only(left: _barIconPadding / 2, right: _barIconPadding, top: _barIconPadding, bottom: _barIconPadding),
    progress: _preparingShare,
    onTap: _onTapShare,
  );

  void _onTapShare() async {
    Analytics().logSelect(target: 'Share', source: runtimeType.toString());
    setState(() { _preparingShare = true; });
    Uint8List pdf = await generatePdf(_pdfPageFormat);
    if (mounted) {
      setState(() { _preparingShare = false; });
      Printing.sharePdf(bytes: pdf, filename: _saveFileName);
    }
  }

  Widget get _closeButton => _iconButton('close-circle',
    label: Localization().getStringEx('dialog.close.title', 'Close'),
    hint: Localization().getStringEx('dialog.close.hint', ''),
    iconSize: _barIconSize * 1.2,
    onTap: _onTapClose,
  );

  void _onTapClose() {
    Analytics().logSelect(target: 'Close', source: runtimeType.toString());
    Navigator.of(context).pop();
  }

  Widget _iconButton(String? iconName, {
    void Function()? onTap,
    double iconSize = _barIconSize,
    EdgeInsetsGeometry padding = const EdgeInsets.all(_barIconPadding),
    bool progress = false,
    String? label, String? hint,
  }) => Semantics(label: label, hint: hint, inMutuallyExclusiveGroup: true, button: true, child:
    InkWell(onTap : onTap, child:
      Container(padding: padding, child: progress ?
        SizedBox(width: iconSize * 0.8, height: iconSize * 0.8, child:
          CircularProgressIndicator(color: Styles().colors.fillColorSecondary, strokeWidth: 3,)
        ) :
        Styles().images.getImage(iconName, excludeFromSemantics: true, size: iconSize),
      ),
    ),
  );

  Widget get _footerSpacer =>
    Container(height: _barHeight);

  // Data

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

}