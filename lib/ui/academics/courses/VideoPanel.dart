import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/NativeCommunicator.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/VideoPlayerWidget.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class VideoPanel extends StatefulWidget {
  final String? resourceKey;
  final String? resourceName;
  VideoPanel({Key? key, this.resourceName, this.resourceKey}) : super(key: key);

  @override
  State<VideoPanel> createState() => _VideoPanelState();
}

class _VideoPanelState extends State<VideoPanel> {
  Future<void>? _initializeVideoPlayerFuture;
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

  Uri? get _videoUri {
    if (StringUtils.isNotEmpty(widget.resourceKey)) {
      //first try to parse the resource key as a uri; if it doesn't have a host then try to use it as a file name and use content BB as the host
      Uri? videoUri = Uri.tryParse(widget.resourceKey!);
      if (StringUtils.isEmpty(videoUri?.host) && StringUtils.isNotEmpty(Config().essentialSkillsCoachKey) && StringUtils.isNotEmpty(Config().contentUrl)) {
        Map<String, String> queryParams = {
          'fileName': widget.resourceKey!,
          'category': Config().essentialSkillsCoachKey!,
        };
        String url = "${Config().contentUrl}/files";
        if (queryParams.isNotEmpty) {
          url = UrlUtils.addQueryParameters(url, queryParams);
        }
        videoUri = Uri.tryParse(url);
      }

      return videoUri;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Styles().colors.background,
      appBar: HeaderBar(title: widget.resourceName ?? Localization().getStringEx('panel.essential_skills_coach.video.header.title', 'Video'),
        textStyle: Styles().textStyles.getTextStyle('header_bar'),),
      body: Center(child: VideoPlayerWidget(
        uri: _videoUri,
        videoID: widget.resourceKey,
        videoTitle: widget.resourceName,
        useAuthHeaders: true,
      )),
    );
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
}