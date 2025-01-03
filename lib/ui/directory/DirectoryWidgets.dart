
import 'dart:io';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/DeepLink.dart';
import 'package:illinois/ui/attributes/ContentAttributesPanel.dart';
import 'package:illinois/ui/messages/MessagesConversationPanel.dart';
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
import 'package:rokwire_plugin/service/social.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

enum DirectoryDisplayMode { browse, select }

class DirectoryAccountCard extends StatefulWidget {
  final Auth2PublicAccount account;
  final DirectoryDisplayMode displayMode;
  final String? photoImageToken;
  final bool expanded;
  final void Function()? onToggleExpanded;
  final bool selected;
  final void Function(bool)? onToggleSelected;

  DirectoryAccountCard(this.account, { super.key, this.displayMode = DirectoryDisplayMode.browse, this.photoImageToken, this.expanded = false, this.onToggleExpanded, this.selected = false, this.onToggleSelected });

  @override
  State<StatefulWidget> createState() => _DirectoryAccountCardState();
}

class _DirectoryAccountCardState extends State<DirectoryAccountCard> {

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

  Widget  get _messageButton => _iconButton(icon: _messageIcon, onTap: _onMessage, progress: _messageProgress);
  Widget? get _messageIcon => Styles().images.getImage('message', size: 20, color: Styles().colors.fillColorPrimary);

  void _onMessage() {
    Analytics().logSelect(target: 'Message User');
    String? accountId = widget.account.id;
    if (accountId != null) {
      setState(() {
        _messageProgress = true;
      });
      Social().createConversation(memberIds: [accountId]).then((Conversation? conversation){
        if (mounted) {
          setState(() {
            _messageProgress = false;
          });
          if (conversation != null) {
            Navigator.push(context, CupertinoPageRoute(builder: (context) => MessagesConversationPanel(conversation: conversation,)));
          } else {
            AppAlert.showDialogResult(context, Localization().getStringEx('panel.messages.directory.button.continue.failed.msg', 'Failed to create a conversation with the selected members.'));
          }
        }
      });
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
  final Map<String, String>? photoUrlHeaders;
  final Uint8List? photoData;
  final double imageSize;
  final double borderSize;

  DirectoryProfilePhoto({ super.key, this.photoUrl, this.photoUrlHeaders, this.photoData, this.borderSize = 0, required this.imageSize });

  @override
  Widget build(BuildContext context) {
    ImageProvider<Object>? decorationImage = _decorationImage;
    return (decorationImage != null) ?
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
                image: decorationImage
              ),
            )
          )
        ),
      ) : (Styles().images.getImage('profile-placeholder', excludeFromSemantics: true, size: imageSize + borderSize) ?? Container());
  }

    ImageProvider<Object>? get _decorationImage {
      if (photoData != null) {
        return Image.memory(photoData ?? Uint8List(0)).image;
      }
      else if (photoUrl != null) {
        return NetworkImage(photoUrl ?? '', headers: photoUrlHeaders);
      }
      else {
        return null;
      }
    } 
}

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

class DirectoryPronunciationButton extends StatefulWidget {
  final String? url;
  final Uint8List? data;

  DirectoryPronunciationButton({super.key, this.url, this.data});

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
          description: Localization().getStringEx('panel.directory.accounts.filters.header.description', 'Choose at leasrt one attribute to filter the User Directory.'),
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