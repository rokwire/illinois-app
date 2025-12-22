
import 'package:universal_io/io.dart';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/ext/Auth2.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/DeepLink.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/ui/attributes/ContentAttributesPanel.dart';
import 'package:illinois/ui/messages/MessagesDirectoryPanel.dart';
import 'package:illinois/ui/messages/MessagesHomePanel.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:illinois/utils/AudioUtils.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/model/auth2.directory.dart';
import 'package:rokwire_plugin/model/content_attributes.dart';
import 'package:rokwire_plugin/model/group.dart';
import 'package:rokwire_plugin/model/social.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/auth2.directory.dart';
import 'package:rokwire_plugin/service/content.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/network.dart';
import 'package:rokwire_plugin/service/social.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/accessible_image_holder.dart';
import 'package:rokwire_plugin/ui/widgets/triangle_painter.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

enum DirectoryDisplayMode { browse, select }

// DirectoryAccountCard

class DirectoryAccountListCard extends StatefulWidget {
  final Auth2PublicAccount account;
  final DirectoryDisplayMode displayMode;
  final String? photoImageToken;
  final bool expanded;
  final void Function()? onToggleExpanded;
  final bool selected;
  final void Function(bool)? onToggleSelected;

  DirectoryAccountListCard(this.account, { super.key, this.displayMode = DirectoryDisplayMode.browse, this.photoImageToken, this.expanded = false, this.onToggleExpanded, this.selected = false, this.onToggleSelected });

  @override
  State<StatefulWidget> createState() => _DirectoryAccountListCardState();
}

class _DirectoryAccountListCardState extends State<DirectoryAccountListCard> {

  bool _messageProgress = false;

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
        if (widget.displayMode == DirectoryDisplayMode.select)
          _cardSelectionContent(padding: EdgeInsets.only(top: 12, right: 8)),
        Expanded(child:
          _expandedHeadingLeftContent
        ),
        Padding(padding: EdgeInsets.symmetric(horizontal: 6, vertical: 12), child:
          Styles().images.getImage('chevron2-up',)
        ),
      ],),
    );

  Widget _cardSelectionContent({ EdgeInsetsGeometry padding = EdgeInsets.zero }) =>
    InkWell(onTap: _onSelect, child:
      Padding(padding: padding, child:
        SizedBox(height: 24.0, width: 24.0, child:
          Checkbox(
          checkColor: Styles().colors.surface,
          activeColor: Styles().colors.fillColorPrimary,
          value: widget.selected,
          visualDensity: VisualDensity.compact,
          side: BorderSide(color: Styles().colors.fillColorPrimary, width: 1.0),
          onChanged: _onToggleSelected,
        ),
      ),
    ),
  );

  void _onSelect() =>
    _onToggleSelected(!widget.selected);

  void _onToggleSelected(bool? value) {
    if (value != null) {
      widget.onToggleSelected?.call(value);
    }
  }

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
        Expanded(flex: 60, child:
          Padding(padding: EdgeInsets.only(top: 12), child:
            DirectoryProfileDetails(widget.account.profile),
          ),
        ),
        Expanded(flex: 40, child:
          Padding(padding: EdgeInsets.only(top: 0), child:
            Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.center, children: [
              DirectoryProfilePhoto(
                photoUrl: _photoUrl,
                imageSize: _photoImageSize,
                photoUrlHeaders: _photoAuthHeaders,
                borderSize: 12,
              ),
              _expandedCommandsBar,
            ],),
          ),
        ),
        //Container(width: 32,),
      ],),
    );

  Widget get _expandedCommandsBar =>
    Row(mainAxisSize: MainAxisSize.max, mainAxisAlignment: MainAxisAlignment.end, children: [
      _messageButton,
    ],);

  Widget  get _messageButton => Visibility(visible: FlexUI().isMessagesAvailable, child: _iconButton(icon: _messageIcon, onTap: _onMessage, progress: _messageProgress));
  Widget? get _messageIcon => Styles().images.getImage('message', size: 20, color: Styles().colors.fillColorPrimary);

  void _onMessage() async {
    Analytics().logSelect(target: 'Message User');
    String? accountId = widget.account.id;
    String? userName = widget.account.profile?.fullName;
    if (accountId != null) {
      List<Conversation>? conversations;
      if (userName?.isNotEmpty == true) {
        setState(() {
          _messageProgress = true;
        });
        // Search this user across existing conversations.
        conversations = await Social().loadConversations(
          offset: 0,
          limit: MessagesHomePanel.conversationsPageSize,
          name: userName,
        );
      }
      if (mounted) {
        if (_messageProgress == true) {
          setState(() {
            _messageProgress = false;
          });
        }
        if (conversations?.isNotEmpty == true) {
          // If there are existing conversatins where this user participates, show them
          MessagesHomePanel.present(context,
            search: userName,
            conversations: conversations,
          );
        }
        else {
          // otherwise, invoke new message UI having this user selected.
          Navigator.push(context, CupertinoPageRoute(builder: (context) =>
            MessagesDirectoryPanel(
              recentConversations: const [],
              conversationPageSize: MessagesHomePanel.conversationsPageSize,
              // pass "startOnAllUsersTab" and "defaultSelectedAccountIds" so we jump directly to "All" tab with that user preselected
              startOnAllUsersTab: true,
              defaultSelectedAccountIds: [accountId],
            )
          ));
        }
      }
    }
  }

  Widget _iconButton({Widget? icon, void Function()? onTap, bool progress = false }) =>
    progress ? _iconButtonProgress : _iconButtonImpl(icon: icon, onTap: onTap);

  Widget _iconButtonImpl({Widget? icon, void Function()? onTap }) =>
    InkWell(onTap: onTap, child:
      Padding(padding: EdgeInsets.all(6), child:
        icon,
      )
    );

  Widget get _iconButtonProgress =>
    Padding(padding: EdgeInsets.all(8), child:
      SizedBox(width: 16, height: 16, child:
        CircularProgressIndicator(strokeWidth: 2, color: Styles().colors.fillColorPrimary,),
      )
    );

  String? get _photoUrl => StringUtils.isNotEmpty(widget.account.profile?.photoUrl) ?
    Content().getUserPhotoUrl(type: UserProfileImageType.medium, accountId: widget.account.id, params: DirectoryProfilePhotoUtils.tokenUrlParam(widget.photoImageToken)) : null;

  double get _photoImageSize => MediaQuery.of(context).size.width / 4;

  Map<String, String>? get _photoAuthHeaders => DirectoryProfilePhotoUtils.authHeaders;

  Widget get _collapsedContent =>
    InkWell(onTap: widget.onToggleExpanded, child:
      Row(children: [
        if (widget.displayMode == DirectoryDisplayMode.select)
          _cardSelectionContent(padding: EdgeInsets.only(top: 12, bottom: 12, right: 8)),
        Expanded(child:
          Padding(padding: EdgeInsets.symmetric(vertical: 12), child:
            RichText(textAlign: TextAlign.left, text:
              TextSpan(style: Styles().textStyles.getTextStyle('widget.title.regular'), children: _nameSpans),
            )
          ),
        ),
        Padding(padding: EdgeInsets.symmetric(vertical: 12, horizontal: 6), child:
          Styles().images.getImage('chevron2-down',)
        ),
      ],),
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

// DirectoryAccountBusinessCard

class DirectoryAccountContactCard extends StatefulWidget {
  final Auth2PublicAccount? account;
  final String? accountId;
  final bool printMode;

  DirectoryAccountContactCard({super.key, this.account, this.accountId, this.printMode = false });

  @override
  State<StatefulWidget> createState() => _DirectoryAccountContactCardState();
}

class _DirectoryAccountContactCardState extends State<DirectoryAccountContactCard> {

  Auth2PublicAccount? _account;
  bool _loadingAccount = false;

  Auth2UserProfile? get _profile => _account?.profile;

  String? get _photoImageUrl => StringUtils.isNotEmpty(_profile?.photoUrl) ?
    Content().getUserPhotoUrl(accountId: _account?.id, type: _photoImageType) : null;

  double get _photoImageSize => MediaQuery.of(context).size.width / 3;
  UserProfileImageType get _photoImageType => widget.printMode ? UserProfileImageType.defaultType : UserProfileImageType.medium;

  Map<String, String>? get _photoAuthHeaders => DirectoryProfilePhotoUtils.authHeaders;

  @override
  void initState() {
    _account = widget.account;
    if ((_account == null) && (widget.accountId != null)) {
      _loadingAccount = true;
      Auth2().loadDirectoryAccounts(ids: [widget.accountId!], limit: 1).then((List<Auth2PublicAccount>? accounts){
        if (mounted) {
          setState(() {
            _loadingAccount = false;
            _account = (accounts?.isNotEmpty == true) ? accounts?.first : null;
          });
        }
      });
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) =>
    ClipRRect(borderRadius: _cardBorderRadiusGeometry, child:
      Container(decoration: _cardDecoration, child:
      _cardContent
      ),
    );

  Decoration get _cardDecoration => BoxDecoration(
    color: Styles().colors.white,
    border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
    borderRadius: _cardBorderRadiusGeometry,
    boxShadow: [BoxShadow(color: Styles().colors.blackTransparent018, spreadRadius: 1.0, blurRadius: 3.0, offset: Offset(1, 1))]
  );

  BorderRadiusGeometry get _cardBorderRadiusGeometry =>
    BorderRadius.all(Radius.circular(_cardBorderRadius));

  double get _cardBorderRadius => 16;

  Widget get _cardContent {
    if (_loadingAccount) {
      return _loadingContent;
    }
    else if (_profile == null) {
      return _messageContent(Localization().getStringEx('', 'Failed to load user account'));
    }
    else {
      return _profileContent;
    }
  }

  Widget get _profileContent =>
    Column(mainAxisSize: MainAxisSize.min, children: [
      Padding(padding: EdgeInsets.only(left: 16, right: 16, top: 16), child:
        Column(mainAxisSize: MainAxisSize.min, children: [
          (_photoImageUrl != null) ? _profileImageHeading : _profileTextHeading,
          Padding(padding: EdgeInsets.only(top: 12), child:
            Align(alignment: Alignment.centerLeft, child:
              Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(Localization().getStringEx('app.university_long_name', 'University of Illinois Urbana-Champaign'), style: Styles().textStyles.getTextStyle('widget.detail.regular.fat'),),
                DirectoryProfileDetails(_profile),
              ]),
            )
          ),
        ])
      ),

      _profileTrailing
    ],);

  Widget get _profileImageHeading =>
    Column(mainAxisSize: MainAxisSize.min, children: [
      DirectoryProfilePhoto(
        photoUrl: _photoImageUrl,
        photoUrlHeaders: _photoAuthHeaders,
        imageSize: _photoImageSize,
      ),

      Padding(padding: EdgeInsets.only(top: 12), child:
        RichText(textAlign: TextAlign.center, text: TextSpan(style: _profileNameTextStyle, children: [
          TextSpan(text: _profile?.fullName ?? ''),
        ])),
      ),

      if (_profile?.pronouns?.isNotEmpty == true)
        Text(_profile?.pronouns ?? '', style: Styles().textStyles.getTextStyle('widget.detail.small'), textAlign: TextAlign.center,),
    ],);

  Widget get _profileTextHeading =>
    Align(alignment: Alignment.centerLeft, child:
      Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [

        Padding(padding: EdgeInsets.only(top: 12), child:
          RichText(textAlign: TextAlign.left, text: TextSpan(style: _profileNameTextStyle, children: [
            TextSpan(text: _profile?.fullName ?? ''),
          ])),
        ),

        if (_profile?.pronouns?.isNotEmpty == true)
          Text(_profile?.pronouns ?? '', style: Styles().textStyles.getTextStyle('widget.detail.small'), textAlign: TextAlign.left,),
      ]),
    );

  Widget get _profileTrailing =>
    Column(mainAxisSize: MainAxisSize.min, children: [
      CustomPaint(
        painter: TrianglePainter(painterColor: Styles().colors.fillColorSecondary, horzDir: TriangleHorzDirection.leftToRight),
        child: Padding(padding: EdgeInsets.only(right: _cardBorderRadius, top: _cardBorderRadius / 2 * 3), child:
          Row( mainAxisAlignment: MainAxisAlignment.end, children: [
            Styles().images.getImage('university-logo-blue') ?? Container(),
          ],)
        ),
      ),
      Container(height: _cardBorderRadius / 2 * 3, color: Styles().colors.fillColorSecondary,),

    ],);

  TextStyle? get _profileNameTextStyle =>
    Styles().textStyles.getTextStyleEx('widget.title.medium_large.fat', fontHeight: 0.85, textOverflow: TextOverflow.ellipsis);

  Widget get _loadingContent =>
    Column(mainAxisSize: MainAxisSize.min, children: [
      Padding(padding: EdgeInsets.symmetric(vertical: 64, horizontal: 32), child:
        Center(child:
          SizedBox(width: 24, height: 24, child:
            CircularProgressIndicator(strokeWidth: 3, color: Styles().colors.fillColorSecondary,),
          )
        )
      ),
    ]);

  Widget _messageContent(String? message) =>
    Column(mainAxisSize: MainAxisSize.min, children: [
      Padding(padding: EdgeInsets.symmetric(vertical: 64, horizontal: 32), child:
        Center(child:
          Text(message ?? '', style: Styles().textStyles.getTextStyle("widget.card.detail.regular"))
        )
      ),
    ]);
}

// DirectoryAccountPopupCard

class DirectoryAccountPopupCard extends StatelessWidget {
  final Auth2PublicAccount? account;
  final String? accountId;

  DirectoryAccountPopupCard({super.key, this.account, this.accountId });

  @override
  Widget build(BuildContext context) => Stack(children: [
    DirectoryAccountContactCard(account: account, accountId: accountId,),
    Positioned.fill(child:
      Align(alignment: Alignment.topRight, child:
        InkWell(onTap: () => _onTapClose(context), child:
          Padding(padding: EdgeInsets.all(16), child:
              Styles().images.getImage('close')
          )
        )
      )
    )
  ],);

  void _onTapClose(BuildContext context) {
    Analytics().logSelect(target: 'close');
    Navigator.pop(context);
  }
}

// DirectoryProfileDetails

class DirectoryProfileDetails extends StatelessWidget {
  final Auth2UserProfile? profile;

  DirectoryProfileDetails(this.profile, { super.key });
  
  @override
  Widget build(BuildContext context) =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (profile?.title?.isNotEmpty == true)
        _textDetail(profile?.title ?? ''),
      if (profile?.college?.isNotEmpty == true)
        _textDetail(profile?.college ?? ''),
      if (profile?.department?.isNotEmpty == true)
        _textDetail(profile?.department ?? ''),
      if (profile?.major?.isNotEmpty == true)
        _textDetail(profile?.major ?? ''),
      if (profile?.department2?.isNotEmpty == true)
        _textDetail(profile?.department2 ?? ''),
      if (profile?.major2?.isNotEmpty == true)
        _textDetail(profile?.major2 ?? ''),

      if (profile?.address?.isNotEmpty == true)
        _textDetail(profile?.address ?? ''),
      if (profile?.address2?.isNotEmpty == true)
        _textDetail(profile?.address2 ?? ''),
      if (profile?.poBox?.isNotEmpty == true)
        _textDetail(profile?.displayPOBox ?? ''),
      if (profile?.isCityStateZipCountryNotEmpty == true)
        _textDetail(profile?.displayCityStateZipCountry ?? ''),

      if (profile?.email?.isNotEmpty == true)
        _linkDetail(profile?.email ?? '', 'mailto:${profile?.email}', analyticsTarget: Analytics.LogAnonymousEmail),
      if (profile?.email2?.isNotEmpty == true)
        _linkDetail(profile?.email2 ?? '', 'mailto:${profile?.email2}', analyticsTarget: Analytics.LogAnonymousEmail),
      if (profile?.phone?.isNotEmpty == true)
        _linkDetail(profile?.phone ?? '', 'tel:${profile?.phone}', analyticsTarget: Analytics.LogAnonymousPhone),
      if (profile?.website?.isNotEmpty == true)
        _linkDetail(profile?.website ?? '', UrlUtils.fixUrl(profile?.website ?? '', scheme: 'https') ?? profile?.website ?? '', analyticsTarget: Analytics.LogAnonymousWebsite),
    ],);


    Widget _textDetail(String text) =>
      Text(text, style: Styles().textStyles.getTextStyle('widget.detail.small'),);

    Widget _linkDetail(String text, String url, { String? analyticsTarget } ) =>
      InkWell(onTap: () => _onTapLink(url, analyticsTarget: analyticsTarget ?? text), child:
        Text(text, style: Styles().textStyles.getTextStyleEx('widget.button.title.small.underline', decorationColor: Styles().colors.fillColorPrimary),),
      );

    void _onTapLink(String url, { String? analyticsTarget }) {
      Analytics().logSelect(target: analyticsTarget ?? url);
      _launchUrl(url);
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
}

// DirectoryProfilePhoto

class DirectoryProfilePhoto extends StatefulWidget {

  final String? photoUrl;
  final Map<String, String>? photoUrlHeaders;
  final Uint8List? photoData;
  final double imageSize;
  final double borderSize;

  DirectoryProfilePhoto({ super.key, this.photoUrl, this.photoUrlHeaders, this.photoData, this.borderSize = 0, required this.imageSize });

  @override
  State<DirectoryProfilePhoto> createState() => _DirectoryProfilePhotoState();
}

class _DirectoryProfilePhotoState extends State<DirectoryProfilePhoto> {
  Uint8List? _photoBytes;

  @override
  void initState() {
    super.initState();
    _photoBytes = widget.photoData;
    _loadNetworkPhoto();
  }

  void _loadNetworkPhoto() {
    String? photoUrl = widget.photoUrl;
    if ((_photoBytes == null) && StringUtils.isNotEmpty(photoUrl)) {
      Network().get(photoUrl, headers: widget.photoUrlHeaders).then((response) {
        int? responseCode = response?.statusCode;
        if ((responseCode != null) && (responseCode >= 200) && (responseCode <= 301)) {
          setStateIfMounted(() {
            _photoBytes = response?.bodyBytes;
          });
        } else {
          debugPrint('${responseCode}: Failed to load photo with url: ${widget.photoUrl}');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider<Object>? decorationImage = _decorationImage;
    return (decorationImage != null) ?
      AccessibleImageHolder(imageUrl: UrlUtils.stripQueryParameters(widget.photoUrl), child:
        Container(
          width: widget.imageSize + widget.borderSize, height: widget.imageSize + widget.borderSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Styles().colors.white,
            border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
          ),
          child: Center(
            child: Container(
              width: widget.imageSize, height: widget.imageSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Styles().colors.background,
                image: DecorationImage(
                    fit: BoxFit.cover,
                    image: decorationImage
                ),
              ),
            )
          ),
        )
      ): (Styles().images.getImage('profile-placeholder', excludeFromSemantics: true, size: widget.imageSize + widget.borderSize) ?? Container());
  }

  ImageProvider<Object>? get _decorationImage {
    if (_photoBytes != null) {
      return Image.memory(_photoBytes ?? Uint8List(0)).image;
    }
    else {
      return null;
    }
  }
}

// DirectoryProfilePhotoUtils

class DirectoryProfilePhotoUtils {

  static const String tokenKey = 'edu.illinois.rokwire.token';

  static String get newToken => DateTime.now().millisecondsSinceEpoch.toString();

  static Map<String, String>? tokenUrlParam(String? token) => (token != null) ? <String, String>{
    tokenKey : token
  } : null;

  static Map<String, String>? get authHeaders {
    String tokenType = Auth2().token?.tokenType ?? 'Bearer';
    String? accessToken = Auth2().token?.accessToken;
    return (accessToken != null) ? <String, String>{
      HttpHeaders.authorizationHeader : "$tokenType $accessToken",
    } : null;
  }
}

// DirectoryPronunciationButton

class DirectoryPronunciationButton extends StatefulWidget {
  final String? url;
  final Uint8List? data;
  final EdgeInsetsGeometry padding;

  DirectoryPronunciationButton({
    super.key, this.url, this.data,
    this.padding = const EdgeInsets.symmetric(horizontal: 13, vertical: 18)
  });

  @override
  State<StatefulWidget> createState() => _DirectoryPronunciationButtonState();

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
    Semantics(label: "Pronounce", hint: "Play the pronouncement", button: true, child:
      InkWell(onTap: _onPronunciation, child:
        _pronunciationButtonContent
      )
    );

    Widget? get _pronunciationButtonContent =>
      _initializingAudioPlayer ? _pronunciationButtonInitializingContent : _pronunciationButtonPlaybackContent;

    Widget get _pronunciationButtonInitializingContent =>
      Padding(padding: widget.padding, child:
        SizedBox(width: _pronunciationButtonIconSize, height: _pronunciationButtonIconSize, child:
          DirectoryProgressWidget()
        ),
      );

    Widget get _pronunciationButtonPlaybackContent =>
      Padding(padding: widget.padding.add(EdgeInsets.symmetric(horizontal: _pronunciationPlaying ? -2 : -1)) , child:
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

        Uint8List? audioData = widget.data;
        if (audioData == null) {
          AudioResult? result = await Content().loadUserNamePronunciationFromUrl(widget.url);
          audioData = (result?.resultType == AudioResultType.succeeded) ? result?.audioData : null;
        }

        if (mounted) {
          setState(() {
            _initializingAudioPlayer = false;
          });

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
    AppAlert.showTextMessage(context, Localization().getStringEx('panel.profile.info.playback.failed.text', 'Failed to play audio stream.'));
  }
}

// DirectoryProgressWidget

class DirectoryProgressWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
    CircularProgressIndicator(strokeWidth: 2, color: Styles().colors.fillColorSecondary,);
}

// DirectoryProfileCard

class DirectoryProfileCard extends StatelessWidget {
  final Widget? child;
  final double roundingRadius;
  DirectoryProfileCard({super.key, this.child, this.roundingRadius = 8 });

  @override
  Widget build(BuildContext context) =>
    Container(decoration: _cardDecoration, child: child);

  Decoration get _cardDecoration => BoxDecoration(
    color: Styles().colors.white,
    border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
    borderRadius: BorderRadius.all(Radius.circular(roundingRadius)),
    boxShadow: [BoxShadow(color: Styles().colors.blackTransparent018, spreadRadius: 1.0, blurRadius: 3.0, offset: Offset(1, 1))],
  );
}

// DirectoryFilterBar

class DirectoryFilterBar extends StatefulWidget {
  final String? searchText;
  final void Function(String)? onSearchText;

  final Map<String, dynamic>? filterAttributes;
  final void Function(Map<String, dynamic>)? onFilterAttributes;

  DirectoryFilterBar({ super.key,
    this.searchText, this.onSearchText,
    this.filterAttributes, this.onFilterAttributes,
  });

  @override
  State<StatefulWidget> createState() => _DirectoryFilterBarState();
}

class _DirectoryFilterBarState extends State<DirectoryFilterBar> {
  final TextEditingController _searchTextController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    _searchTextController.text = widget.searchText ?? '';
    super.initState();
  }

  @override
  void dispose() {
    _searchTextController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      Padding(padding: const EdgeInsets.only(bottom: 16), child:
        Row(children: [
          if (widget.searchText != null)
            Expanded(child:
              _searchTextWidget,
            ),
          if (widget.filterAttributes != null)
            Padding(padding: EdgeInsets.only(left: 6), child:
              _filtersButton
            ),
        ],),
      );

      Widget get _searchTextWidget =>
        Container(decoration: _searchBarDecoration, padding: EdgeInsets.only(left: 16), child:
          Row(children: <Widget>[
            Expanded(child:
              _searchTextField
            ),
            _searchImageButton('close',
              label: Localization().getStringEx('panel.search.button.clear.title', 'Clear'),
              hint: Localization().getStringEx('panel.search.button.clear.hint', ''),
              rightPadding: _searchImageButtonHorzPadding / 2,
              onTap: _onTapClear,
            ),
            _searchImageButton('search',
              label: Localization().getStringEx('panel.search.button.search.title', 'Search'),
              hint: Localization().getStringEx('panel.search.button.search.hint', ''),
              leftPadding: _searchImageButtonHorzPadding / 2,
              onTap: _onTapSearch,
            ),
          ],)
        );

      Widget get _searchTextField =>
        Semantics(
          label: Localization().getStringEx('panel.directory.accounts.search.field.label', 'SEARCH FIELD'),
          hint: null,
          textField: true,
          excludeSemantics: true,
          value: _searchTextController.text,
          child: TextField(
            controller: _searchTextController,
            focusNode: _searchFocusNode,
            decoration: InputDecoration(border: InputBorder.none,),
            style: Styles().textStyles.getTextStyle('widget.input_field.dark.text.regular.thin'),
            cursorColor: Styles().colors.fillColorSecondary,
            keyboardType: TextInputType.text,
            autocorrect: false,
            autofocus: false,
            maxLines: 1,
            onSubmitted: (_) => _onTapSearch(),
        )
      );

    Decoration get _searchBarDecoration => BoxDecoration(
      color: Styles().colors.white,
      border: Border.all(color: Styles().colors.disabledTextColor, width: 1),
      borderRadius: BorderRadius.circular(12),
    );

    Widget _searchImageButton(String image, { String? label, String? hint, double leftPadding = _searchImageButtonHorzPadding, double rightPadding = _searchImageButtonHorzPadding, void Function()? onTap }) =>
      Semantics(label: label, hint: hint, button: true, excludeSemantics: true, child:
        InkWell(onTap: onTap, child:
          Padding(padding: EdgeInsets.only(left: leftPadding, right: rightPadding, top: _searchImageButtonVertPadding, bottom: _searchImageButtonVertPadding), child:
            Styles().images.getImage(image, excludeFromSemantics: true),
          ),
        ),
      );

    static const double _searchImageButtonHorzPadding = 16;
    static const double _searchImageButtonVertPadding = 12;

    Widget get _filtersButton =>
      InkWell(onTap: _onFilter, child:
        Container(decoration: _searchBarDecoration, padding: EdgeInsets.symmetric(vertical: 14, horizontal: 14), child:
          Styles().images.getImage('filters') ?? SizedBox(width: 18, height: 18,),
        ),
      );

    void _onFilter() {
      Analytics().logSelect(target: 'Filters');
      ContentAttributes? directoryAttributes = _directoryAttributes;
      if (directoryAttributes != null) {
        Navigator.push(context, CupertinoPageRoute(builder: (context) => ContentAttributesPanel(
          title: Localization().getStringEx('panel.directory.accounts.filters.header.title', 'Directory Filters'),
          description: Localization().getStringEx('panel.directory.accounts.filters.header.description', 'Choose at leasrt one attribute to filter the Directory of Users.'),
          scope: Auh2Directory.attributesScope,
          contentAttributes: directoryAttributes,
          selection: widget.filterAttributes,
          sortType: ContentAttributesSortType.alphabetical,
          filtersMode: true,
        ))).then((selection) {
          if ((selection != null) && mounted) {
            widget.onFilterAttributes?.call(selection);
          }
        });
      }
    }

    ContentAttributes? get _directoryAttributes {
      ContentAttributes? directoryAttributes = Auth2().directoryAttributes;
      if (directoryAttributes != null) {
        ContentAttribute? groupAttribute = _groupAttribute;
        if (groupAttribute != null) {
          directoryAttributes = ContentAttributes.fromOther(directoryAttributes);
          directoryAttributes?.attributes?.add(groupAttribute);
        }
        return directoryAttributes;
      }
      else {
        return null;
      }
    }

    static const String _groupAttributeId = 'group';

    ContentAttribute? get _groupAttribute {
      List<Group>? userGroups = Groups().userGroups;
      return ((userGroups != null) && userGroups.isNotEmpty) ?
        ContentAttribute(
          id: _groupAttributeId,
          title: Localization().getStringEx('panel.directory.accounts.attributes.event_type.hint.empty', 'My Groups'),
          emptyHint: Localization().getStringEx('panel.directory.accounts.attributes.event_type.hint.empty', 'Select groups'),
          semanticsHint: Localization().getStringEx('panel.directory.accounts.home.attributes.event_type.hint.semantics', 'Double type to show groups.'),
          widget: ContentAttributeWidget.dropdown,
          scope: <String>{ Auh2Directory.attributesScope },
          requirements: null,
          values: List.from(userGroups.map<ContentAttributeValue>((Group group) => ContentAttributeValue(
            label: group.title,
            value: group.id,
          )))
        ) : null;
    }

    void _onTapClear() {
      Analytics().logSelect(target: 'Search Clear');
      if (widget.searchText?.isNotEmpty == true) {
        _searchFocusNode.unfocus();
        widget.onSearchText?.call('');
      }
    }

    void _onTapSearch() {
      Analytics().logSelect(target: 'Search Text');
      if (widget.searchText != _searchTextController.text) {
        _searchFocusNode.unfocus();
        widget.onSearchText?.call(_searchTextController.text);
      }
    }
}

// DirectoryFilter

class DirectoryFilter {
  final String? searchText;
  final Map<String, dynamic>? attributes;

  DirectoryFilter({ this.searchText, this.attributes });

  factory DirectoryFilter.fromOther(DirectoryFilter other, {String? searchText, Map<String, dynamic>? attributes}) =>
    DirectoryFilter(
      searchText: searchText ?? other.searchText,
      attributes: attributes ?? other.attributes,
    );

  // Equality

  @override
  bool operator==(Object other) =>
    (other is DirectoryFilter) &&
    (searchText == other.searchText) &&
    (const DeepCollectionEquality().equals(attributes, other.attributes));

  @override
  int get hashCode =>
    (searchText?.hashCode ?? 0) ^
    (const DeepCollectionEquality().hash(attributes));

}