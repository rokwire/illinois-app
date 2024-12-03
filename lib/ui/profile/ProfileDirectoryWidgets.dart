
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/DeepLink.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:illinois/utils/AudioUtils.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/model/directory.dart';
import 'package:rokwire_plugin/service/content.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

class DirectoryAccountCard extends StatefulWidget {
  final Auth2PublicAccount account;
  final bool expanded;
  final void Function()? onToggleExpanded;
  DirectoryAccountCard(this.account, { super.key, this.expanded = false, this.onToggleExpanded });

  @override
  State<StatefulWidget> createState() => _DirectoryAccountCardState();
}

class _DirectoryAccountCardState extends State<DirectoryAccountCard> {

  @override
  Widget build(BuildContext context) =>
    widget.expanded ? _expandedContent : _collapsedContent;

  Widget get _expandedContent => Column(children: [
    _expandedHeading,
    _expandedBody,
  ],);

  Widget get _expandedHeading =>
    InkWell(onTap: widget.onToggleExpanded, child:
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child:
          _expandedHeadingLeftContent
        ),
        Padding(padding: EdgeInsets.symmetric(horizontal: 6, vertical: 12), child:
          Styles().images.getImage('chevron2-up',)
        ),
      ],),
    );

  bool get _hasPronunciation => (widget.account.profile?.pronunciationUrl?.isNotEmpty == true);

  Widget get _expandedHeadingLeftContent => _hasPronunciation ?
    _expandedHeadingTextAndPronunciationContent : _expandedHeadingTextContent;

  Widget get _expandedHeadingTextAndPronunciationContent =>
    Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      _expandedHeadingTextContent,
      DirectoryPronunciationButton(url: widget.account.profile?.pronunciationUrl,),
    ],);

  Widget get _expandedHeadingTextContent =>
    Padding(padding: EdgeInsets.only(top: 16), child:
      Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Text(widget.account.profile?.fullName ?? '', style: Styles().textStyles.getTextStyleEx('widget.title.large.fat', fontHeight: 0.85)),
        if (widget.account.profile?.pronouns?.isNotEmpty == true)
          Text(widget.account.profile?.pronouns ?? '', style: Styles().textStyles.getTextStyle('widget.detail.small')),
      ],),
    );


  Widget get _expandedBody =>
    Padding(padding: EdgeInsets.only(bottom: 16), child:
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child:
          Padding(padding: EdgeInsets.only(top: 12), child:
          DirectoryProfileDetails(widget.account.profile),
          ),
        ),
        Expanded(child:
          Padding(padding: EdgeInsets.only(top: 0), child:
            DirectoryProfilePhoto(widget.account.profile?.photoUrl, imageSize: _photoImageSize, borderSize: 12,)
          ),
        ),
        //Container(width: 32,),
      ],),
    );

  double get _photoImageSize => MediaQuery.of(context).size.width / 4;

  Widget get _collapsedContent =>
    InkWell(onTap: widget.onToggleExpanded, child:
      Padding(padding: EdgeInsets.symmetric(vertical: 12), child:
        Row(children: [
          Expanded(child:
            RichText(textAlign: TextAlign.left, text:
              TextSpan(style: Styles().textStyles.getTextStyle('widget.title.regular'), children: _nameSpans),
            )
          ),
          Padding(padding: EdgeInsets.symmetric(horizontal: 6), child:
            Styles().images.getImage('chevron2-down',)
          )
        ],)
     ),
    );

  List<TextSpan> get _nameSpans {
    List<TextSpan> spans = <TextSpan>[];
    _addNameSpan(spans, widget.account.profile?.firstName);
    _addNameSpan(spans, widget.account.profile?.middleName);
    _addNameSpan(spans, widget.account.profile?.lastName, style: Styles().textStyles.getTextStyle('widget.title.regular.fat'));
    return spans;
  }

  void _addNameSpan(List<TextSpan> spans, String? name, {TextStyle? style}) {
    if (name?.isNotEmpty == true) {
      if (spans.isNotEmpty) {
        spans.add(TextSpan(text: ' '));
      }
      spans.add(TextSpan(text: name ?? '', style: style));
    }
  }
}

class DirectoryProfileDetails extends StatelessWidget {
  final Auth2UserProfile? profile;

  DirectoryProfileDetails(this.profile, { super.key });
  
  String? get college => null;
  String? get department => null;
  String? get major => null;
  
  String? get email => null;
  String? get email2 => null;
  String? get phone => null;
  String? get website => null;
  
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (profile?.college?.isNotEmpty == true)
          Text(profile?.college ?? '', style: Styles().textStyles.getTextStyle('widget.detail.small'),),
        if (profile?.department?.isNotEmpty == true)
          Text(profile?.department ?? '', style: Styles().textStyles.getTextStyle('widget.detail.small'),),
        if (profile?.major?.isNotEmpty == true)
          Text(profile?.major ?? '', style: Styles().textStyles.getTextStyle('widget.detail.small'),),
        if (profile?.email?.isNotEmpty == true)
          _linkDetail(profile?.email ?? '', 'mailto:${email}'),
        if (profile?.email2?.isNotEmpty == true)
          _linkDetail(profile?.email2 ?? '', 'mailto:${email2}'),
        if (profile?.phone?.isNotEmpty == true)
          _linkDetail(profile?.phone ?? '', 'tel:${phone}'),
        if (profile?.website?.isNotEmpty == true)
          _linkDetail(profile?.website ?? '', UrlUtils.fixUrl(profile?.website ?? '', scheme: 'https') ?? profile?.website ?? ''),
      ],);

  Widget _linkDetail(String text, String url) =>
    InkWell(onTap: () => _onTapLink(url, analyticsTarget: text), child:
      Text(text, style: Styles().textStyles.getTextStyleEx('widget.button.title.small.underline', decorationColor: Styles().colors.fillColorPrimary),),
    );

  void _onTapLink(String url, { String? analyticsTarget }) {
    Analytics().logSelect(target: analyticsTarget ?? url);
    _launchUrl(url);
  }
}

void _launchUrl(String? url) {
  if (StringUtils.isNotEmpty(url)) {
    if (DeepLink().isAppUrl(url)) {
      DeepLink().launchUrl(url);
    }
    else {
      Uri? uri = Uri.tryParse(url!);
      if (uri != null) {
        launchUrl(uri, mode: (Platform.isAndroid ? LaunchMode.externalApplication : LaunchMode.platformDefault));
      }
    }
  }
}

class DirectoryProfilePhoto extends StatelessWidget {
  final String? photoUrl;
  final double imageSize;
  final double borderSize;
  final Map<String, String>? headers;

  DirectoryProfilePhoto(this.photoUrl, { super.key, required this.imageSize, this.borderSize = 0, this.headers });

  @override
  Widget build(BuildContext context) => (photoUrl?.isNotEmpty == true) ?
    Container(
      width: imageSize + borderSize, height: imageSize + borderSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Styles().colors.white,
        border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
      ),
      child: Center(
        child: Container(
          width: imageSize, height: imageSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Styles().colors.background,
            image: DecorationImage(
              fit: BoxFit.cover,
              image: NetworkImage(photoUrl ?? '',
                headers: headers
              )
            ),
          )
        )
      ),
    ) : (Styles().images.getImage('profile-placeholder', excludeFromSemantics: true, size: imageSize + borderSize) ?? Container());
}

class DirectoryPronunciationButton extends StatefulWidget {
  final String? url;

  DirectoryPronunciationButton({super.key, this.url});

  @override
  State<StatefulWidget> createState() => _DirectoryPronunciationButtonState();

  static Widget spacer() => _DirectoryPronunciationButtonState._pronunciationButtonStaticContent();
}

class _DirectoryPronunciationButtonState extends State<DirectoryPronunciationButton> {

  AudioPlayer? _audioPlayer;
  bool _initializingAudioPlayer = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _audioPlayer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
    InkWell(onTap: _onPronunciation, child:
      _pronunciationButtonContent
    );

    Widget? get _pronunciationButtonContent =>
      _initializingAudioPlayer ? _pronunciationButtonInitializingContent : _pronunciationButtonPlaybackContent;

    Widget get _pronunciationButtonInitializingContent =>
      _pronunciationButtonStaticContent(child: DirectoryProgressWidget());

    static Widget _pronunciationButtonStaticContent({Widget? child}) =>
        Padding(padding: EdgeInsets.symmetric(horizontal: 13, vertical: 18), child:
          SizedBox(width: _pronunciationButtonIconSize, height: _pronunciationButtonIconSize, child:
            child
          ),
        );

    Widget get _pronunciationButtonPlaybackContent =>
      Padding(padding: EdgeInsets.symmetric(horizontal: _pronunciationPlaying ? 11 : 12, vertical: 18), child:
        Styles().images.getImage(_pronunciationPlaying ? 'volume-high' : 'volume', size: _pronunciationButtonIconSize),
      );

    bool get _pronunciationPlaying =>
      _audioPlayer?.playing == true;

    static const double _pronunciationButtonIconSize = 16;

  void _onPronunciation() async {
    Analytics().logSelect(target: 'pronunciation');

    if (_audioPlayer == null) {
      if (_initializingAudioPlayer == false) {
        setState(() {
          _initializingAudioPlayer = true;
        });

        AudioResult? result = await Content().loadUserNamePronunciationFromUrl(widget.url);

        if (mounted) {
          Uint8List? audioData = (result?.resultType == AudioResultType.succeeded) ? result?.data : null;
          if (audioData != null) {
            _audioPlayer = AudioPlayer();

            _audioPlayer?.playerStateStream.listen((PlayerState state) {
              if ((state.processingState == ProcessingState.completed) && mounted) {
                setState(() {
                  _audioPlayer?.dispose();
                  _audioPlayer = null;
                });
              }
            });

            Duration? duration;
            try { duration = await _audioPlayer?.setAudioSource(Uint8ListAudioSource(audioData)); }
            catch(e) {}

            if (mounted) {
              if ((duration != null) && (duration.inMilliseconds > 0)) {
                setState(() {
                  _initializingAudioPlayer = false;
                  _audioPlayer?.play();
                });
              }
              else {
                _handlePronunciationPlaybackError();
              }
            }
          }
          else {
            _handlePronunciationPlaybackError();
          }
        }
      }
      else {
        // ignore taps while initializing
      }
    }
    else if (_audioPlayer?.playing == true) {
      setState(() {
        _audioPlayer?.pause();
      });
    }
    else {
      setState(() {
        _audioPlayer?.play();
      });
    }
  }

  void _handlePronunciationPlaybackError() {
    setState(() {
      _initializingAudioPlayer = false;
      _audioPlayer?.dispose();
      _audioPlayer = null;
    });
    AppAlert.showTextMessage(context, Localization().getStringEx('panel.profile.directory.my_info.playback.failed.text', 'Failed to play audio stream.'));
  }
}

class DirectoryProgressWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
    CircularProgressIndicator(strokeWidth: 2, color: Styles().colors.fillColorSecondary,);
}

class DirectoryProfileCard extends StatelessWidget {
  final Widget? child;
  DirectoryProfileCard({super.key, this.child});

  @override
  Widget build(BuildContext context) =>
    Container(decoration: cardDecoration, child: child);

  Decoration get cardDecoration => BoxDecoration(
    color: Styles().colors.white,
    border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
    borderRadius: BorderRadius.all(Radius.circular(16)),
    boxShadow: [BoxShadow(color: Styles().colors.blackTransparent018, spreadRadius: 1.0, blurRadius: 3.0, offset: Offset(1, 1))],
  );
}