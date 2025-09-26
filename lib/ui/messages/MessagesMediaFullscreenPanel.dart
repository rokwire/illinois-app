import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:illinois/service/NativeCommunicator.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/styles.dart';

class MessagesMediaFullscreenPanel extends StatefulWidget {
  final Widget media;
  final String? url;
  final String? filename;
  const MessagesMediaFullscreenPanel({super.key, required this.media, this.url,
    this.filename});

  @override
  State<MessagesMediaFullscreenPanel> createState() => _MessagesMediaFullscreenPanelState();
}

class _MessagesMediaFullscreenPanelState extends State<MessagesMediaFullscreenPanel> {
  List<DeviceOrientation>? _allowedOrientations;

  @override
  void initState() {
    super.initState();
    _enableLandscapeOrientations();
  }

  @override
  void dispose() {
    _revertToAllowedOrientations();
    super.dispose();
  }


  void _enableLandscapeOrientations() {
    NativeCommunicator().enabledOrientations(
        [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight, DeviceOrientation.portraitUp]).then((orientationList) {
      _allowedOrientations = orientationList;
    });
  }

  void _revertToAllowedOrientations() {
    if (_allowedOrientations != null) {
      NativeCommunicator().enabledOrientations(_allowedOrientations!).then((orientationList) {
        _allowedOrientations = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Styles().colors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Center(child: widget.media),
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Row(children: [
                _backButton(),
                Spacer(),
                _shareMedia(),
              ]),
            )
          ],
        ),
      )
    );
  }

  Widget _backButton() {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop();
      },
      child: Styles().images.getImage('back-light'),
    );
  }

  Widget _shareMedia() {
    return Visibility(
      visible: widget.url != null,
      child: GestureDetector(
        onTap: () {
          AppFile.downloadFile(context: context, fileName: widget.filename ?? 'media.out', url: widget.url);
        },
        child: Styles().images.getImage('download', color: Styles().colors.iconColor, size: 18),
      ),
    );
  }
}
