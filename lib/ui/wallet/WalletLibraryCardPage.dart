
import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/AppDateTime.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/DeepLink.dart';
import 'package:illinois/service/NativeCommunicator.dart';
import 'package:illinois/ui/wallet/WalletPhotoWrapper.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:illinois/service/Analytics.dart';

class WalletLibraryCardPage extends StatefulWidget {
  final double topOffset;
  WalletLibraryCardPage({super.key, this.topOffset = 0});

  State<StatefulWidget> createState() => _WalletLibraryCardPageState();
}

class _WalletLibraryCardPageState extends State<WalletLibraryCardPage> with NotificationsListener {

  MemoryImage? _barcodeImage;
  String? _barcodeNumber;
  DateTime _accessTime = DateTime.now();
  GestureRecognizer? _libraryLaunchRecognizer;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Auth2.notifyCardChanged,
    ]);

    _barcodeNumber = Auth2().iCard?.libraryNumber;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBarcodeImage(_barcodeNumber).then((MemoryImage? barcodeImage) {
        setStateIfMounted(() {
          _barcodeImage = barcodeImage;
        });
      });
    });
    _libraryLaunchRecognizer = TapGestureRecognizer()..onTap = _onLaunchLibrary;
    super.initState();
  }

  @override
  void deactivate() {
    NotificationService().unsubscribe(this);
    _libraryLaunchRecognizer?.dispose();
    super.deactivate();
  }

  // NotificationsListener
  @override
  void onNotification(String name, dynamic param) {
    if ((name == Auth2.notifyCardChanged) && (Auth2().iCard?.libraryNumber != _barcodeNumber) && mounted) {
      String? barcodeNumber = Auth2().iCard?.libraryNumber;
      if (_barcodeNumber != barcodeNumber) {
        _loadBarcodeImage(barcodeNumber).then((MemoryImage? barcodeImage) {
          setStateIfMounted(() {
            _barcodeImage = barcodeImage;
            _barcodeNumber = barcodeNumber;
          });
        });
      }
    }
  }

  void _onLaunchLibrary() {
    Analytics().logSelect(target: 'University Library');
    _launchUrl(Config().universityLibraryUrl);
  }

  static void _launchUrl(String? url) {
    if (StringUtils.isNotEmpty(url)) {
      if (DeepLink().isAppUrl(url)) {
        DeepLink().launchUrl(url);
      }
      else {
        AppLaunchUrl.launchExternal(url: url);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WalletPhotoWrapper(
      topOffset: widget.topOffset,
      headingColor: Styles().colors.lightGray,
      accentColor: _photoBorderDay ? Styles().colors.libraryCardAccentBlue : Styles().colors.libraryCardAccentOrange,
      borderColor: _photoBorderDay ? Styles().colors.libraryCardBorderBlue : Styles().colors.libraryCardBorderOrange,
      child: _buildCardContent()
    );
  }

  Widget _buildCardContent() {
    String? cardExpires = Localization().getStringEx('widget.card.label.expires.title', 'Expires');
    String? expirationDate = Auth2().iCard?.expirationDate;
    String cardExpiresText = (0 < (expirationDate?.length ?? 0)) ? "$cardExpires $expirationDate" : "";

    return Column(children: <Widget>[
      Text(Auth2().iCard?.fullName?.trim() ?? '', style: Styles().textStyles.getTextStyle("panel.id_card.detail.title.large")),
      Text(_displayRole, style:  Styles().textStyles.getTextStyle("panel.id_card.detail.title.regular")),
      Text(Auth2().iCard?.uin ?? '', style: Styles().textStyles.getTextStyle("panel.id_card.detail.title.small")),

      Container(height: 16,),
      Text(_displayAccessTime ?? '', style: Styles().textStyles.getTextStyle("panel.id_card.detail.title.regular")),
      Container(height: 8),

      _barcodeImageWidget,

      Container(height: 8,),

      Text(_barcodeNumber ?? '', style: Styles().textStyles.getTextStyle("panel.id_card.detail.title.small")),

      Container(height: 16,),

      Text(cardExpiresText, style:  Styles().textStyles.getTextStyle("panel.id_card.detail.title.tiny")),

      Container(height: 16,),

      Padding(padding: EdgeInsets.symmetric(horizontal: 48), child: _libraryCardInfoWidget
      ),

      Container(height: 16,),

    ]);
  }

  Widget get _libraryCardInfoWidget {
    final String libraryMacro = '{{library_name}}';
    final String externalLinkMacro = '{{external_link_icon}}';
    TextStyle? regularTextStyle = Styles().textStyles.getTextStyle('panel.id_card.detail.description.italic');
    TextStyle? linkTextStyle = Styles().textStyles.getTextStyle('panel.id_card.detail.description.italic.link');

    String infoText = Localization().getStringEx('widget.library_card.text.card_instructions', 'This card is needed for $libraryMacro $externalLinkMacro services such as picking up an equipment loan or checking out a book or keys to a study room.');
    String libraryText = Localization().getStringEx('widget.library_card.text.card_instructions.library_name', 'University Library');

    List<InlineSpan> spanList = StringUtils.split<InlineSpan>(infoText, macros: [libraryMacro, externalLinkMacro], builder: (String entry){
      if (entry == libraryMacro) {
        return TextSpan(text: libraryText, style : linkTextStyle, recognizer: _libraryLaunchRecognizer,);
      }
      else if (entry == externalLinkMacro) {
        return WidgetSpan(alignment: PlaceholderAlignment.middle, child: Styles().images.getImage('external-link', size: 14) ?? Container());
      }
      else {
        return TextSpan(text: entry);
      }
    });
    return RichText(textAlign: TextAlign.center, text:
      TextSpan(style: regularTextStyle, children: spanList)
    );
  }

  String get _displayRole => (Auth2().iCard?.needsUpdate ?? false) ? Localization().getStringEx("widget.id_card.label.update_i_card", "Update your Illini ID") : (Auth2().iCard?.role ?? "");
  String? get _displayAccessTime => AppDateTime().formatDateTime(_accessTime, format: 'MMM dd, yyyy HH:mm a');
  double get _barcodeWidth => MediaQuery.of(context).size.width / 1.25;
  double get _barcodeHeight => _barcodeWidth / 4;
  bool get _photoBorderDay => ((_accessTime.difference(DateTime(1970)).inDays % 2) == 0); // Used to alternate the photo border color scheme daily

  Widget get _barcodeImageWidget {
    if (kIsWeb) {
      if (StringUtils.isEmpty(_barcodeNumber)) {
        return Container();
      }
      return BarcodeWidget(
        height: _barcodeHeight,
        width: _barcodeWidth,
        barcode: Barcode.codabar(),
        data: _barcodeNumber!,
        errorBuilder: (context, error) => Center(child: Text(error)),
      );
    } else {
      return Container(width: _barcodeWidth, height: _barcodeHeight, decoration: BoxDecoration(
          shape: BoxShape.rectangle,
          color: Colors.white,
          image: (_barcodeImage != null) ? DecorationImage(fit: BoxFit.fill, image:_barcodeImage! ,) : null
      ),);
    }
  }

  Future<MemoryImage?> _loadBarcodeImage(String? libraryCode) async {
    Uint8List? barcodeBytes = ((libraryCode != null) && libraryCode.isNotEmpty) ? await NativeCommunicator().getBarcodeImageData(libraryCode,
      format: 'codabar',
      width: _barcodeWidth.toInt() * 3,
      height: _barcodeHeight.toInt(),
    ) : null;
    try { return ((barcodeBytes != null) && barcodeBytes.isNotEmpty) ? MemoryImage(barcodeBytes) : null; }
    catch(e) { debugPrint(e.toString()); return null; }
  }
}
