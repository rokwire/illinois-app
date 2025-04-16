
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:illinois/service/AppDateTime.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/NativeCommunicator.dart';
import 'package:illinois/ui/wallet/WalletPhotoWrapper.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';

class WalletLibraryCardPage extends StatefulWidget {
  final double topOffset;
  WalletLibraryCardPage({super.key, this.topOffset = 0});

  State<StatefulWidget> createState() => _WalletLibraryCardPageState();
}

class _WalletLibraryCardPageState extends State<WalletLibraryCardPage> with NotificationsListener {

  MemoryImage? _barcodeImage;
  String? _barcodeNumber;
  DateTime? _accessTime = DateTime.now();

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

    super.initState();
  }

  @override
  void deactivate() {
    NotificationService().unsubscribe(this);
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

  @override
  Widget build(BuildContext context) {
    return WalletPhotoWrapper(topOffset: widget.topOffset, headingColor: Styles().colors.lightGray, child: _buildCardContent());
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

      Padding(padding: EdgeInsets.symmetric(horizontal: 48), child:
        Text(Localization().getStringEx('widget.library_card.text.card_instructions', 'This card is needed for University Library services such as picking up an equipment loan or checking out a book or keys to a study room.'), textAlign: TextAlign.center, style: Styles().textStyles.getTextStyle("panel.id_card.detail.description.itallic"))
      ),

      Container(height: 16,),

    ]);
  }

  String get _displayRole => (Auth2().iCard?.needsUpdate ?? false) ? Localization().getStringEx("widget.id_card.label.update_i_card", "Update your Illini ID") : (Auth2().iCard?.role ?? "");
  String? get _displayAccessTime => AppDateTime().formatDateTime(_accessTime, format: 'MMM dd, yyyy HH:mm a');
  double get _barcodeWidth => MediaQuery.of(context).size.width / 1.25;
  double get _barcodeHeight => _barcodeWidth / 4;

  Widget get _barcodeImageWidget =>
    Container(width: _barcodeWidth, height: _barcodeHeight, decoration: BoxDecoration(
      shape: BoxShape.rectangle,
      color: Colors.white,
      image: (_barcodeImage != null) ? DecorationImage(fit: BoxFit.fill, image:_barcodeImage! ,) : null
    ),);

  Future<MemoryImage?> _loadBarcodeImage(String? libraryCode) async {
    Uint8List? barcodeBytes = (libraryCode != null) ? await NativeCommunicator().getBarcodeImageData({
      'content': libraryCode,
      'format': 'codabar',
      'width': _barcodeWidth.toInt() * 3,
      'height': _barcodeHeight.toInt(),
    }) : null;
    try { return ((barcodeBytes != null) && barcodeBytes.isNotEmpty) ? MemoryImage(barcodeBytes) : null; }
    catch(e) { debugPrint(e.toString()); return null; }
  }
}
