import 'dart:async';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:image_picker/image_picker.dart';
import 'package:neom/ext/Social.dart';
import 'package:neom/service/Analytics.dart';
import 'package:neom/service/AppDateTime.dart';
import 'package:neom/service/Auth2.dart';
import 'package:neom/service/DeepLink.dart';
import 'package:neom/service/FirebaseMessaging.dart';
import 'package:neom/service/SpeechToText.dart';
import 'package:neom/ui/directory/DirectoryWidgets.dart';
import 'package:neom/ui/messages/MessagesMediaFullscreenPanel.dart';
import 'package:neom/ui/profile/ProfileVoiceRecordigWidgets.dart';
import 'package:neom/ui/widgets/AudioPlayerWidget.dart';
import 'package:neom/ui/widgets/HeaderBar.dart';
import 'package:neom/ui/widgets/RibbonButton.dart';
import 'package:neom/ui/widgets/TabBar.dart' as uiuc;
import 'package:neom/ui/widgets/VideoPlayerWidget.dart';
import 'package:neom/ui/widgets/WebEmbed.dart';
import 'package:neom/utils/AppUtils.dart';
import 'package:neom/ui/widgets/LinkTextEx.dart';
import 'package:neom/utils/Utils.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/model/social.dart';
import 'package:rokwire_plugin/service/content.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/social.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:sprintf/sprintf.dart';
import 'package:universal_io/io.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:neom/platform_impl/stub.dart'
  if (dart.library.io) 'package:neom/platform_impl/mobile.dart'
  if (dart.library.html) 'package:neom/platform_impl/web.dart';

enum FileType { image, video, audio, file }

class MessagesConversationPanel extends StatefulWidget {
  final Conversation? conversation;
  final String? conversationId;
  final String? targetMessageId;
  final String? targetMessageGlobalId;

  MessagesConversationPanel({Key? key, this.conversation, this.conversationId, this.targetMessageId, this.targetMessageGlobalId}) : super(key: key);

  bool get _hasTargetMessage => ((targetMessageId != null) || (targetMessageGlobalId != null));
  bool isTargetMessage(Message message) => ((message.id == targetMessageId) || (message.globalId == targetMessageGlobalId));

  _MessagesConversationPanelState createState() => _MessagesConversationPanelState();
}

enum _ScrollTarget { bottom, targetMessage }

class _MessagesConversationPanelState extends State<MessagesConversationPanel>
    with AutomaticKeepAliveClientMixin<MessagesConversationPanel>, WidgetsBindingObserver implements NotificationsListener {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _chatBarKey = GlobalKey();
  final GlobalKey _lastContentItemKey = GlobalKey();
  final GlobalKey _targetMessageContentItemKey = GlobalKey();
  final GlobalKey _inputFieldKey = GlobalKey();
  final FocusNode _inputFieldFocus = FocusNode();
  final FileHelper _fileHelper = FileHelper();

  _ScrollTarget? _shouldScrollToTarget;
  Map<String, Uint8List?> _userPhotosCache = {};

  bool _listening = false;
  bool _loading = false;
  bool _loadingMore = false;
  bool _submitting = false;
  Map<String, bool> _uploadingFiles = {};

  // Use the actual Auth2 accountId instead of a placeholder.
  String? get _currentUserId => Auth2().accountId;
  String? get _conversationId => widget.conversationId ?? widget.conversation?.id;

  // Conversation and Messages loaded from the backend
  Conversation? _conversation;
  List<Message> _messages = [];
  int _messagesLength = 0;
  bool _hasMoreMessages = false;
  final int _messagesPageSize = 20;
  Message? _editingMessage;
  Message? _deletingMessage;
  Set<dynamic> _attachedFiles = {};

  final Set<String> _globalIds = {};

  static const double _photoSize = 20;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Auth2UserPrefs.notifyFavoritesChanged,
      Localization.notifyStringsUpdated,
      Styles.notifyChanged,
      SpeechToText.notifyError,
      FirebaseMessaging.notifyForegroundMessage,
    ]);
    WidgetsBinding.instance.addObserver(this);

    _scrollController.addListener(_scrollListener);

    if (widget.conversation != null) {
      _conversation = widget.conversation;
    }

    // Load conversation (if needed) and messages from the backend
    _initConversationAndMessages();

    _fileHelper.initializePicker();

    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    _inputController.dispose();
    _inputFieldFocus.dispose();
    super.dispose();
  }

  // AutomaticKeepAliveClientMixin
  @override
  bool get wantKeepAlive => true;

  // NotificationsListener
  @override
  void onNotification(String name, dynamic param) {
    if (name == FirebaseMessaging.notifyForegroundMessage) {
      if (ModalRoute.of(context)?.isCurrent ?? false) {
        _refreshMessages();
      }
    }
    if ((name == Auth2UserPrefs.notifyFavoritesChanged) ||
        (name == Localization.notifyStringsUpdated) ||
        (name == Styles.notifyChanged)) {
      setStateIfMounted((){});
    } else if (name == SpeechToText.notifyError) {
      setState(() {
        _listening = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottomIfNeeded();
    });

    return Scaffold(
      appBar: RootHeaderBar(title: _conversation?.membersString, leading: RootHeaderBarLeading.Back, onTapTitle: _onTapHeaderBarTitle),
      body: _buildContent(),
      backgroundColor: Styles().colors.background,
      bottomNavigationBar: uiuc.TabBar(),
    );
  }

  String _getConversationTitle() {
    // If it's a one-on-one conversation, show the other member's name
    // If group, show something else. For now, if multiple members, just show first.
    if (_conversation?.members?.length == 1) {
      return _conversation?.members?.first.name ?? 'Unknown';
    } else {
      // For group conversations, you could customize the title further
      return _conversation?.membersString ?? 'Group Conversation';
    }
  }

  Widget _buildContent() {
    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: _onPullToRefresh,
            child: _messages.isNotEmpty
                ? Stack(
              alignment: Alignment.center,
              children: [
                CustomScrollView(
                  controller: _scrollController,
                  reverse: true,
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate(_buildContentList()),
                      ),
                    ),
                  ],),
                Visibility(visible: _loading, child: CircularProgressIndicator(color: Styles().colors.fillColorSecondary)),
              ])
                : _loading
                ? Center(child: CircularProgressIndicator(color: Styles().colors.fillColorSecondary))
                : Center(
              child: Text(
                (_conversation != null) ? 'No message history' : 'Failed to load conversation',
                style: Styles().textStyles.getTextStyle('widget.message.light.medium'),
              ),
            ),
          ),
        ),
        Container(
          key: _chatBarKey,
          color: Styles().colors.background,
          child: SafeArea(child: _buildChatBar()),
        ),
      ],
    );
  }

  List<Widget> _buildContentList() {
    List<Widget> contentList = <Widget>[];

    if (_loadingMore) {
      contentList.add(_buildLoadingMoreIndicator());
    }

    if (_messages.isNotEmpty) {
      DateTime? lastDate;
      for (Message message in _messages) {
        DateTime? msgDate = message.dateSentLocal;
        if (msgDate != null) {
          if ((lastDate == null) ||
              (lastDate.year != msgDate.year || lastDate.month != msgDate.month || lastDate.day != msgDate.day)) {
            contentList.add(_buildDateDivider(message.dateSentLocalString ?? ''));
            lastDate = msgDate;
          }
        }
        contentList.add(_buildMessageCard(message));
      }
    }

    contentList.add(Container(key: _lastContentItemKey, height: 0));
    return contentList.reversed.toList();
  }

  Widget _buildLoadingMoreIndicator() {
    return Container(padding: EdgeInsets.all(6), child:
      Align(alignment: Alignment.center, child:
        SizedBox(width: 24, height: 24, child:
          CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors.fillColorSecondary),
        ),
      ),
    ),);
  }

  Widget _buildDateDivider(String dateText) {
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Center(
            child: Text(
                dateText,
                style: Styles().textStyles.getTextStyle('widget.description.small.light'),
            )
        )
    );
  }

  Decoration get _messageCardDecoration => BoxDecoration(
    color: Styles().colors.surface,
    border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
    borderRadius: BorderRadius.all(Radius.circular(8)),
    //boxShadow: [BoxShadow(color: Styles().colors.blackTransparent018, spreadRadius: 1.0, blurRadius: 3.0, offset: Offset(1, 1))],
  );

  Decoration get _highlightedMessageCardDecoration => BoxDecoration(
    color: Styles().colors.surface,
    border: Border.all(color: Styles().colors.fillColorSecondary, width: 1),
    borderRadius: BorderRadius.all(Radius.circular(8)),
    boxShadow: [BoxShadow(color: Styles().colors.blackTransparent018, spreadRadius: 1.0, blurRadius: 3.0, offset: Offset(1, 1))],
  );

  Widget _buildMessageCard(Message message) {
    String? senderId = message.sender?.accountId;
    bool isCurrentUser = (senderId == _currentUserId);
    bool hasProgress = (_deletingMessage != null) && (message.globalId == _deletingMessage?.globalId);
    bool canLongPress = isCurrentUser && (_editingMessage == null) && (_deletingMessage == null);
    Key? contentItemKey = widget.isTargetMessage(message) ? _targetMessageContentItemKey : null;
    Decoration cardDecoration = widget.isTargetMessage(message) ? _highlightedMessageCardDecoration : _messageCardDecoration;

    Widget cardWidget = GestureDetector(onLongPress: canLongPress ? () => _onMessageLongPress(message) : null, child:
      FutureBuilder<Widget>(
        future: _buildAvatarWidget(isCurrentUser: isCurrentUser, senderId: senderId),
        builder: (context, snapshot) {
          Widget avatar = (snapshot.data ?? (Styles().images.getImage('person-circle-white', size: _photoSize, color: Styles().colors.fillColorSecondary) ?? Container()));

          return Container(key: contentItemKey, margin: EdgeInsets.only(bottom: 16), decoration: cardDecoration, child:
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Column(
                children: [
                  Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(child:
                          InkWell(onTap: () => _onTapAccount(message), child:
                            Row(children: [
                              avatar,
                              SizedBox(width: 8),
                              Expanded(child:
                                Text("${message.sender?.name ?? 'Unknown'}", style: Styles().textStyles.getTextStyle('widget.card.title.regular.fat'))
                              ),
                            ]),
                          ),
                        ),
                        if (message.dateSentUtc != null)
                          Text(AppDateTime().formatDateTime(message.dateSentUtc, format: 'h:mm a') ?? '', style: Styles().textStyles.getTextStyle('widget.description.small'),),
                      ]),
                      SizedBox(height: 8),
                      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Expanded(child:
                          SelectionArea(
                            child: LinkTextEx(
                              key: UniqueKey(),
                              message.message ?? '',
                              textStyle: Styles().textStyles.getTextStyle('widget.detail.regular'),
                              linkStyle: Styles().textStyles.getTextStyleEx('widget.detail.regular.underline', decorationColor: Styles().colors.fillColorPrimary),
                              onLinkTap: _onTapLink,
                            ),
                          ),
                        ),
                        // If dateUpdatedUtc is not null, show a small “(edited)” label
                        if (message.dateUpdatedUtc != null)
                          Padding(padding: EdgeInsets.only(left: 4), child:
                            Text(Localization().getStringEx('', '(edited)'), style: Styles().textStyles.getTextStyle('widget.message.light.small')?.copyWith(fontStyle: FontStyle.italic),),
                          ),
                      ],),
                      if (!kIsWeb)
                        WebEmbed(body: message.message),

                    ]),
                  ),
                  if (CollectionUtils.isNotEmpty(message.fileAttachments))
                    _buildAttachedFilesListWidget(message: message),
                ],
              ),
            ),
          );
        },
      ),
    );

    return hasProgress ? Stack(children: [
      cardWidget,
      Positioned.fill(child:
        Center(child:
          SizedBox(width: _photoSize, height: _photoSize, child:
            CircularProgressIndicator(color: Styles().colors.fillColorSecondary, strokeWidth: 2,),
          )
        )
      )
    ]) : cardWidget;
  }

  void _onMessageLongPress(Message message) {
    showDialog(
        context: context,
        builder: (_) {
          return AlertDialog(
            title: Text(Localization().getStringEx('', 'Message Options'), style: TextStyle(color: Styles().colors.fillColorPrimary)),
            content: Text(Localization().getStringEx('', 'Edit or delete this message?'), style: TextStyle(color: Styles().colors.fillColorPrimary)),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _onEditMessage(message);
                },
                child: Text(Localization().getStringEx('dialog.edit.title', 'Edit'), style: TextStyle(color: Styles().colors.fillColorPrimary)),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _onDeleteMessage(message);
                },
                child: Text(Localization().getStringEx('dialog.delete.title', 'Delete'), style: TextStyle(color: Styles().colors.fillColorSecondary)),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(Localization().getStringEx('dialog.cancel.title', 'Cancel'), style: TextStyle(color: Styles().colors.fillColorPrimary)),
              ),
            ],
          );
        }
    );
  }

  void _onEditMessage(Message message) {
    setState(() {
      _editingMessage = message;
      _inputController.text = message.message ?? '';
    });
    FocusScope.of(context).requestFocus(_inputFieldFocus);
  }

  Future<void> _onDeleteMessage(Message message) async {
    String? globalId = message.globalId;
    if (globalId == null) {
      debugPrint('Cannot delete this message: missing globalId.');
      return;
    }
    if (_conversationId == null) {
      debugPrint('Cannot delete message: missing conversationId.');
      return;
    }

    setState(() {
      _deletingMessage = message;
    });

    bool success = await Social().deleteConversationMessage(
      conversationId: _conversationId!,
      globalMessageId: globalId,
    );

    if (mounted) {
      setState(() {
        _deletingMessage = null;
      });
      if (success) {
        setState(() {
          _messages.removeWhere((m) => m.globalId == globalId);
        });
        AppToast.showMessage('Message deleted.');
      } else {
        AppToast.showMessage('Failed to delete message.');
      }
    }
  }

  void _onTapAccount(Message message) {
    Analytics().logSelect(target: 'View Account');
    showDialog(context: context, builder:(_) => Dialog(child:
      DirectoryAccountPopupCard(accountId: message.sender?.accountId),
    ));
  }

  void _onTapLink(String url) {
    if (url.contains('@')) {
      url = UrlUtils.fixEmail(url) ?? url;
    } else {
      url = UrlUtils.fixUrl(url, scheme: 'https') ?? url;
    }
    Analytics().logSelect(target: url);
    if (StringUtils.isNotEmpty(url)) {
      if (DeepLink().isAppUrl(url)) {
        DeepLink().launchUrl(url);
      }
      else {
        Uri? uri = Uri.tryParse(url);
        if (uri != null) {
          launchUrl(uri);
        }
      }
    }
  }

  void _onTapHeaderBarTitle() {
    Analytics().logSelect(target: 'Headerbar Title', source: _conversation?.membersString);
    final members = _conversation?.members;
    if (members == null || members.isEmpty) {
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      clipBehavior: Clip.antiAlias,
      builder: (BuildContext context) => _buildMembersPopup(context, members),
    );
  }

  Widget _buildMembersPopup(BuildContext context, List<ConversationMember> members) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            color: Styles().colors.backgroundVariant,
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: 16),
                    child: Text(
                      Localization().getStringEx('', 'Conversation Members'),
                      style: Styles().textStyles.getTextStyle("widget.label.medium.fat"),
                    ),
                  ),
                ),
                Semantics(
                  label: Localization().getStringEx('dialog.close.title', 'Close'),
                  hint: Localization().getStringEx('dialog.close.hint', ''),
                  inMutuallyExclusiveGroup: true,
                  button: true,
                  child: InkWell(
                    onTap: () => _onTapMembersPopupClose(context),
                    child: Container(
                      padding: EdgeInsets.only(left: 8, right: 16, top: 16, bottom: 16),
                      child: Styles().images.getImage('close-circle', excludeFromSemantics: true),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              padding: EdgeInsets.all(16.0),
              child: ListView.builder(
                itemCount: members.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildMembersPopupMember(context,
                      userName: Auth2().fullName ?? 'You',
                      isCurrentUser: true,
                      accountId: _currentUserId,
                    );
                  } else {
                    final ConversationMember member = members[index - 1];
                    return _buildMembersPopupMember(context,
                      userName: member.name ?? 'Unknown',
                      isCurrentUser: (member.accountId == _currentUserId),
                      accountId: member.accountId,
                    );
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersPopupMember(BuildContext context, { required String userName, required bool isCurrentUser, String? accountId, }) {

    return ListTile(
      leading: FutureBuilder<Widget>(
        future: _buildAvatarWidget(
          isCurrentUser: isCurrentUser,
          senderId: accountId,
        ),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return snapshot.data!;
          } else {
            return Styles().images.getImage(
              'person-circle-white',
              size: _photoSize,
              color: Styles().colors.fillColorSecondary,
            ) ??
                Container();
          }
        },
      ),
      title: Text(userName, style: Styles().textStyles.getTextStyle('widget.title.regular.fat')),
      onTap: () => _onTapMembersPopupMember(context, accountId),
    );
  }

  void _onTapMembersPopupMember(BuildContext context, String? accountId) {
    Analytics().logSelect(target: 'View Account');
    showDialog(context: context, builder:(_) => Dialog(child:
      DirectoryAccountPopupCard(accountId: accountId),
    ));
  }

  void _onTapMembersPopupClose(BuildContext context) {
    Analytics().logSelect(target: 'Close');
    Navigator.of(context).pop();
  }

  Future<Widget> _buildAvatarWidget({required bool isCurrentUser, String? senderId}) async {
    if (isCurrentUser) {
      // Current user's avatar
      Uint8List? profilePicture = Auth2().profilePicture;
      if (profilePicture != null) {
        return Container(
          width: _photoSize,
          height: _photoSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            image: DecorationImage(
              fit: BoxFit.cover,
              image: Image.memory(profilePicture).image,
            ),
          ),
        );
      } else {
        return Styles().images.getImage('person-circle-white', size: 20.0, color: Styles().colors.fillColorSecondary) ?? Container();
      }
    } else {
      // Other user's avatar
      if (senderId == null) {
        return Styles().images.getImage('person-circle-white', size: 20.0, color: Styles().colors.fillColorSecondary) ?? Container();
      }

      // Check cache first
      if (_userPhotosCache.containsKey(senderId)) {
        Uint8List? cachedData = _userPhotosCache[senderId];
        if (cachedData != null) {
          return Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              image: DecorationImage(
                fit: BoxFit.cover,
                image: Image.memory(cachedData).image,
              ),
            ),
          );
        } else {
          // Cached as null means we tried before and got no image
          return Styles().images.getImage('person-circle-white', size: 20.0, color: Styles().colors.fillColorSecondary) ?? Container();
        }
      }

      // Load image from server
      ImagesResult? result = await Content().loadUserPhoto(
        type: UserProfileImageType.small,
        accountId: senderId,
      );

      Uint8List? imageData = result?.imageData;
      _userPhotosCache[senderId] = imageData; // Cache result (null if none)

      if (imageData != null) {
        return Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            image: DecorationImage(
              fit: BoxFit.cover,
              image: Image.memory(imageData).image,
            ),
          ),
        );
      } else {
        return Styles().images.getImage('person-circle-white', size: 20.0, color: Styles().colors.fillColorSecondary) ?? Container();
      }
    }
  }

  Widget _buildChatBar() {
    bool enabled = true; // Always enabled for now, but you can adjust if needed
    bool isEditing = (_editingMessage != null);

    return Semantics(
      container: true,
      child: Material(
        color: Styles().colors.background,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            children: [
              Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  SizedBox(width: 16),
                  if (isEditing)
                    Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _editingMessage = null;
                              _inputController.clear();
                            });
                          },
                          child: Styles().images.getImage('close-circle-white', color: Styles().colors.fillColorSecondary) ?? Container()
                      ),
                    ),
                  _buildAttachFileButton(),
                  SizedBox(width: 16),
                  Expanded(
                    child: Semantics(
                        container: true,
                        child: TextField(
                            key: _inputFieldKey,
                            enabled: enabled,
                            controller: _inputController,
                            minLines: 1,
                            maxLines: 5,
                            textCapitalization: TextCapitalization.sentences,
                            // textInputAction: TextInputAction.send,
                            focusNode: _inputFieldFocus,
                            // onSubmitted: _submitMessage,
                            onChanged: (_) => setStateIfMounted(() {}),
                            cursorColor: Styles().colors.textLight,
                            decoration: InputDecoration(
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: BorderSide(color: Styles().colors.fillColorPrimary)),
                                fillColor: Styles().colors.surface,
                                focusColor: Styles().colors.surface,
                                hoverColor: Styles().colors.surface,
                                hintText: "Message ${_getConversationTitle()}",
                                hintStyle: Styles().textStyles.getTextStyle('widget.item.light.small')
                            ),
                            style: Styles().textStyles.getTextStyle('widget.title.regular')
                        )
                    ),
                  ),
                  _buildSendImage(enabled),
                ],
              ),
              if (_attachedFiles.isNotEmpty)
                _buildAttachedFilesListWidget(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttachFileButton() {
    return MergeSemantics(child: Semantics(label: Localization().getStringEx('', "Attach"),
        child: InkWell(
            child: Styles().images.getImage('plus-circle', size: 24, fit: BoxFit.cover),
            onTap: _openAttachFileMenu
        )
    ));
  }

  void _openAttachFileMenu() {
    if (!_submitting && _editingMessage == null) {
      Analytics().logSelect(target: 'Attach File');
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
        ),
        clipBehavior: Clip.antiAlias,
        useSafeArea: true,
        builder: _buildAttachFilePopup,
      );
    }
  }

  Widget _buildAttachFilePopup(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: 400),
      child: Column(
        children: [
          Container(
            color: Styles().colors.backgroundVariant,
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: 16),
                    child: Text(
                      Localization().getStringEx('', 'Attach Files'),
                      style: Styles().textStyles.getTextStyle("widget.label.medium.fat"),
                    ),
                  ),
                ),
                Semantics(
                  label: Localization().getStringEx('dialog.close.title', 'Close'),
                  hint: Localization().getStringEx('dialog.close.hint', ''),
                  inMutuallyExclusiveGroup: true,
                  button: true,
                  child: InkWell(
                    onTap: () => _onTapMembersPopupClose(context),
                    child: Container(
                      padding: EdgeInsets.only(left: 8, right: 16, top: 16, bottom: 16),
                      child: Styles().images.getImage('close-circle', excludeFromSemantics: true),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(children: [
                RibbonButton(
                    label: Localization().getStringEx('', 'Upload an image or video'),
                    leftIconKey: 'image',
                    backgroundColor: Styles().colors.backgroundVariant,
                    textColor: Styles().colors.textPrimary,
                    onTap: _onTapUploadImageOrVideo),
                SizedBox(height: 4),
                RibbonButton(
                    label: Localization().getStringEx('', 'Take a photo'),
                    leftIconKey: 'camera',
                    backgroundColor: Styles().colors.backgroundVariant,
                    textColor: Styles().colors.textPrimary,
                    onTap: _onTapCamera),
                SizedBox(height: 4),
                RibbonButton(
                    label: Localization().getStringEx('', 'Record a video'),
                    leftIconKey: 'video-camera',
                    backgroundColor: Styles().colors.backgroundVariant,
                    textColor: Styles().colors.textPrimary,
                    onTap: () => _onTapCamera(isVideo: true)),
                SizedBox(height: 4),
                RibbonButton(
                    label: Localization().getStringEx('', 'Record an audio clip'),
                    leftIconKey: 'microphone',
                    backgroundColor: Styles().colors.backgroundVariant,
                    textColor: Styles().colors.textPrimary,
                    onTap: _onTapRecordAudio),
                SizedBox(height: 4),
                RibbonButton(
                    label: Localization().getStringEx('', 'Upload a file'),
                    leftIconKey: 'file',
                    backgroundColor: Styles().colors.backgroundVariant,
                    textColor: Styles().colors.textPrimary,
                    onTap: _onTapAttachFile)
              ])
            ),
          ),
        ],
      ),
    );
  }

  void _onTapUploadImageOrVideo() async {
    List<XFile> media = await ImagePicker().pickMultipleMedia(limit: 10);
    _addAttachedFiles(media);
    Navigator.of(context).pop();
  }

  void _onTapCamera({bool isVideo = false}) async {
    XFile? media;
    if (isVideo) {
      media = await ImagePicker().pickVideo(source: ImageSource.camera);
    } else {
      media = await ImagePicker().pickImage(source: ImageSource.camera);
    }
    if (media != null) {
      _addAttachedFiles([media]);
    }
    Navigator.of(context).pop();
  }

  void _onTapRecordAudio() async {
    Navigator.of(context).pop();
    showDialog<AudioResult?>(
        context: context,
        builder: (_) =>
          Material(
            type: MaterialType.transparency,
            borderRadius: BorderRadius.all(Radius.circular(5)),
            child: ProfileSoundRecorderDialog(onSave: (audio, extension) async {
              if (CollectionUtils.isEmpty(audio)) {
                return AudioResult.error(AudioErrorType.fileNameNotSupplied, 'Missing file.');
              }
              AudioResult result = AudioResult.succeed(audioData: audio, extension: extension);
              _addAttachedFiles([result]);
              return result;
            }),
          )
    );
  }

  Widget _buildSendImage(bool enabled) {
    if (StringUtils.isNotEmpty(_inputController.text)) {
      // Show send button if there's text
      return MergeSemantics(child: Semantics(label: Localization().getStringEx('', "Send"), enabled: enabled,
          child: IconButton(
              splashRadius: 24,
              icon: Icon(Icons.send, color: enabled ? Styles().colors.fillColorSecondary : Styles().colors.textDisabled, semanticLabel: ""),
              onPressed: enabled
                  ? () {
                _submitMessage(_inputController.text);
              }
                  : null)));
    } else {
      // Show microphone if no text and speech-to-text is enabled
      return Visibility(
          visible: enabled && SpeechToText().isEnabled,
          child: MergeSemantics(child: Semantics(label: Localization().getStringEx('', "Speech to text"),
              child: IconButton(
                  splashRadius: 24,
                  icon: _listening
                      ? Icon(Icons.stop_circle_outlined, color: Styles().colors.fillColorSecondary, semanticLabel: "Stop")
                      : Styles().images.getImage('microphone') ?? SizedBox(),
                  onPressed: enabled
                      ? () {
                    if (_listening) {
                      _stopListening();
                    } else {
                      _startListening();
                    }
                  }
                      : null))));
    }
  }

  Widget _buildAttachedFilesListWidget({Message? message}) {
    return Container(
      height: (message?.fileAttachments ?? _attachedFiles.toList()).firstWhereOrNull((e) {
        FileType type = _getFileType(e);
        return type == FileType.image || type == FileType.video;
      }) != null ? message != null ? 300.0 : 200.0 : 100.0,
      child: ListView.separated(
        padding: EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0),
        separatorBuilder: (context, index) => SizedBox(width: 8.0),
        itemCount: message?.fileAttachments?.length ?? _attachedFiles.length,
        itemBuilder: (context, index) => _buildAttachedFileEntry(context, index, message: message),
        scrollDirection: Axis.horizontal,
      ),
    );
  }

  Widget _buildAttachedFileEntry(BuildContext context, int index, {Message? message}) {
    String? name, extension;
    bool showProgress = false;
    bool allowRemove = true;
    GestureTapCallback? onTap;
    String? textStyleKey = 'widget.title.dark.small';
    if (message != null) {
      FileAttachment? file = message.fileAttachments?[index];
      if (file == null) {
        return SizedBox();
      }
      FileType type = _getFileTypeFromString(file.type);
      if (type == FileType.image || type == FileType.video) {
        return _buildAttachedMediaEntry(context, file, type);
      }
      if (type == FileType.audio) {
        return _buildAudioAttachment(context, file, type);
      }
      name = file.name;
      extension = file.extension;
      onTap = () => _onTapDownloadFile(file, message.globalId!);
      textStyleKey = 'widget.title.dark.small';
    } else {
      dynamic file = _attachedFiles.elementAt(index);
      name = _getFileName(file);
      FileType type = _getFileType(file);
      showProgress = (message == null) && (_uploadingFiles[name] == true);
      allowRemove = !_uploadingFiles.containsKey(name);
      if (type == FileType.image || type == FileType.video) {
        return _buildAttachedMediaEntry(context, file, type, inMessage: false, showProgress: showProgress, allowRemove: allowRemove);
      }
      if (type == FileType.audio) {
        return _buildAudioAttachment(context, file, type, inMessage: false, showProgress: showProgress, allowRemove: allowRemove);
      }
      textStyleKey = 'widget.title.small';
      if (_uploadingFiles[name] != true) {
        onTap = () => _removeAttachedFiles([file]);
      }
      if (file is PlatformFile) {
        extension = file.extension;
      }
    }
    return _buildAttachmentContainer(
      onTap: message != null ? onTap : null,
      onRemove: allowRemove && message == null ? onTap : null,
      inMessage:  message != null,
      showProgress: showProgress,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Styles().images.getImage('file', size: 24) ?? Container(height: 48.0),
          SizedBox(width: 12.0),
          Expanded(
            child: Container(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name ?? '',
                    style: Styles().textStyles.getTextStyle(textStyleKey),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, right: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (extension != null && extension.isNotEmpty)
                          Text(
                            extension.toUpperCase(),
                            style: Styles().textStyles.getTextStyle(textStyleKey),
                          ),
                        if (message != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 16.0),
                            child: Styles().images.getImage('download'),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ]
      ),
    );
  }

  Widget _buildAudioAttachment(BuildContext context, dynamic file, FileType type,
      {bool inMessage = true, bool showProgress = false, bool allowRemove = true}) {
    String? url;
    Uint8List? bytes;
    if (file is AudioResult) {
      bytes = file.audioData;
    }
    else if (file is FileAttachment) {
      url = file.url;
    }
    return SizedBox(
      width: 200,
      child: _buildAttachmentContainer(
        inMessage: inMessage,
        showProgress: showProgress,
        child: Align(alignment: inMessage ? Alignment.center : Alignment.bottomCenter,
            child: AudioPlayerWidget(url: url, bytes: bytes)),
        onRemove: allowRemove && !inMessage ? () => _removeAttachedFiles([file]) : null,
      ),
    );
  }

  Widget _buildAttachmentContainer({required Widget child,
    bool inMessage = true, bool showProgress = false, void Function()? onTap,
    void Function()? onRemove}) {
    return Stack(
      alignment: Alignment.center,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 200,
            height: 80,
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8.0),
                color: inMessage ? Styles().colors.surfaceAccent : Styles().colors.backgroundAccent),
            child: Stack(
              alignment: Alignment.topRight,
              children: [
                child,
                if (onRemove != null)
                  GestureDetector(onTap: onRemove,
                      child: Styles().images.getImage('close-circle')),
              ],
            ),
          ),
        ),
        Visibility(
          visible: showProgress,
          child: CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors.fillColorSecondary),),
        ),
      ],
    );
  }

  Widget _buildAttachedMediaEntry(BuildContext context, dynamic file, FileType type,
      {bool inMessage = true, bool showProgress = false, bool allowRemove = true}) {
    String? path, url;
    Uint8List? data;
    if (file is FileAttachment) {
      url = file.url;
    } else if (kIsWeb && file is PlatformFile) {
      data = file.bytes;
    } else {
      String? filePath = _getFilePath(file);
      if (kIsWeb) {
        url = filePath;
      } else {
        path = filePath;
      }
    }
    if (path == null && url == null && data == null) {
      return const SizedBox();
    }
    Widget? widget;
    if (type == FileType.image) {
      if (data != null) {
        widget = Image.memory(data, fit: BoxFit.cover,
          errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) =>
          _imageErrorBuilder,
        );
      } else if (kIsWeb || file is FileAttachment) {
        widget = Image.network(url ?? '', fit: BoxFit.cover,
          errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) =>
          _imageErrorBuilder,
        );
      } else if (path != null) {
        widget = Image.file(File(path), fit: BoxFit.cover,
          errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) =>
          _imageErrorBuilder,
        );
      } else {
        return const SizedBox();
      }
    }
    else if (type == FileType.video) {
      widget = VideoPlayerWidget(key: ValueKey(path),
          filePath: path, url: url, showControls: false,
          muted: true, fill: true, interactive: false);
    }

    return GestureDetector(
      onTap: inMessage ? () {
        if (widget != null) {
          String? filename = _getFileName(file);
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => MessagesMediaFullscreenPanel(media: widget ?? SizedBox(), filename: filename, url: url),
          ));
        }
      } : null,
      behavior: inMessage ? HitTestBehavior.opaque : null,
      child: Stack(
        alignment: Alignment.center,
        children: [
          IgnorePointer(ignoring: inMessage, child: AspectRatio(aspectRatio: 1/1, child: widget)),
          if (!inMessage && allowRemove)
            Positioned.fill(child:
              Align(alignment: Alignment.topRight, child:
                GestureDetector(onTap: () => _removeAttachedFiles([file]),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Styles().images.getImage('close-circle'),
                    ))
              )
            ),
          Visibility(
            visible: showProgress,
            child: CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors.fillColorSecondary),),
          ),
        ]
      ),
    );
  }

  Widget get _imageErrorBuilder => AspectRatio(aspectRatio: 16/9, child:
    Container(color: Styles().colors.surfaceAccent, child:
      Padding(padding: const EdgeInsets.symmetric(horizontal: 32), child:
        Center(child: Styles().images.getImage('exclamation', size: 48),
          // Text(Localization().getStringEx('', 'This image type is not supported'),
          //     style: Styles().textStyles.getTextStyle('widget.title.dark.small')),
        ),
      ),
    )
  );

  Future<void> _initConversationAndMessages() async {
    if (_conversationId == null) {
      return;
    }
    setStateIfMounted(() {
      _loading = true;
    });

    List<Future> futures = [];

    if (_conversation == null) {
      futures.add(Social().loadConversation(_conversationId!));
    }
    futures.add(_loadMessages(
      offset: 0, limit: _messagesPageSize,
      // Pass messageId param only if we messageGlobalId is not applied
      extendLimitToMessageId: (widget.targetMessageGlobalId == null) ? widget.targetMessageId : null,
      extendLimitToGlobalMessageId: widget.targetMessageGlobalId,
    ));

    List<dynamic> results = await Future.wait(futures);

    if (mounted) {
      Conversation? conversation = (1 < results.length) ? results.first : null;
      List<Message>? messages = results.isNotEmpty ? results.last : null;
      setState(() {
        _loading = false;
        if (conversation != null) {
          _conversation = conversation;
        }
        if (messages != null) {
          Message.sortListByDateSent(messages);
          _globalIds.clear();
          _messages = (_conversation?.isGroupConversation == true) ?
            _removeDuplicateMessagesByGlobalId(messages, _globalIds) : List.from(messages);
          _messagesLength = messages.length;
          _hasMoreMessages = (_messagesPageSize <= messages.length);
          _shouldScrollToTarget = widget._hasTargetMessage ? _ScrollTarget.targetMessage : _ScrollTarget.bottom;
        }
      });
    }
  }

  Future<void> _refreshMessages() async {
    if (_conversationId == null) {
      return;
    }

    // Use the Social API to load conversation messages
    int messagesCount = max(_messagesLength, _messagesPageSize);
    List<Message>? messages = await _loadMessages(
      offset: 0, limit: messagesCount,
    );

    setStateIfMounted(() {
      if (messages != null) {
        Message.sortListByDateSent(messages);
        _globalIds.clear();
        _messages = (_conversation?.isGroupConversation == true) ?
          _removeDuplicateMessagesByGlobalId(messages, _globalIds) : List.from(messages);
        _messagesLength = messages.length;
        _hasMoreMessages = (messagesCount <= messages.length);
        _shouldScrollToTarget = widget._hasTargetMessage ? _ScrollTarget.targetMessage : _ScrollTarget.bottom;
      } else {
        // If null, could indicate a failure to load messages
        // If null, silently ignore the error
        // _messages = [];
        // _hasMoreMessages = false;
        // _globalIds.clear();
      }
    });
  }

  void _loadMoreMessages() async {
    if (_conversationId == null) {
      return;
    }
    setStateIfMounted(() {
      _loadingMore = true;
    });

    // Use the Social API to load conversation messages
    List<Message>? loadedMessages = await _loadMessages(
      limit: _messagesPageSize,
      offset: _messagesLength,
    );

    setStateIfMounted(() {
      _loadingMore = false;
      if (loadedMessages != null) {
        Message.sortListByDateSent(loadedMessages);
        List<Message> newMessages = (_conversation?.isGroupConversation == true) ?
          _removeDuplicateMessagesByGlobalId(loadedMessages, _globalIds) : List.from(loadedMessages);
        newMessages.addAll(_messages);
        _messages = newMessages;
        _messagesLength += loadedMessages.length;
        _hasMoreMessages = (_messagesPageSize <= loadedMessages.length);
        _shouldScrollToTarget = null;
      }
    });
  }

  Future<List<Message>?> _loadMessages({
    int offset = 0, int limit = 100,
    String? extendLimitToMessageId, String? extendLimitToGlobalMessageId,
    bool loadAttachmentUrls = true}) async {
    List<Message>? loadedMessages = await Social().loadConversationMessages(
      conversationId: _conversationId!,
      limit: limit,
      offset: offset,
      extendLimitToGlobalMessageId: extendLimitToGlobalMessageId,
      extendLimitToMessageId: extendLimitToMessageId,
    );
    if (loadAttachmentUrls) {
      List<String> fileIds = [];
      for (Message message in loadedMessages ?? []) {
        fileIds.addAll(message.fileAttachments?.where((e) => e.type != FileType.file).map((e) => e.id).whereNotNull() ?? []);
      }

      if (CollectionUtils.isNotEmpty(fileIds)) {
        List<FileContentItemReference>? fileRefs = await Content().getFileContentDownloadUrls(fileIds, Content.conversationsContentCategory, entityId: _conversationId);
        if (CollectionUtils.isNotEmpty(fileRefs)) {
          for (Message message in loadedMessages ?? []) {
            for (FileAttachment file in message.fileAttachments ?? []) {
              for (FileContentItemReference ref in fileRefs ?? []) {
                if (ref.key == file.id) {
                  file.url = ref.url;
                }
              }
            }
          }
        }
      }
    }
    return loadedMessages;
  }

  List<Message> _removeDuplicateMessagesByGlobalId(List<Message> source, Set<String> globalIds) {
    List<Message> messages = [];
    for (Message message in source) {
      if (message.globalId != null && !globalIds.contains(message.globalId)) {
        messages.add(message);
        globalIds.add(message.globalId!);
      }
    }
    return messages;
  }

  Future<void> _onPullToRefresh() async =>
    _refreshMessages();

  Future<void> _submitMessage(String messageText) async {
    messageText = messageText.trim();
    if (StringUtils.isNotEmpty(messageText)) {
      return (_editingMessage != null) ? _updateEditingMessage(messageText) : _createNewMessage(messageText);
    }
  }

  Future<void> _createNewMessage(String messageText) async {
    if (!_submitting && StringUtils.isNotEmpty(messageText) && _conversationId != null && _currentUserId != null) {
      _submitting = true;
      FocusScope.of(context).requestFocus(FocusNode());

      List<FileContentItemReference>? fileRefs;
      if (_attachedFiles.isNotEmpty) {
        fileRefs = await _uploadAttachedFiles();
      }

      _inputController.text = '';
      List<FileAttachment> fileAttachments = await _getMessageFileAttachments(fileRefs);

      // Create a temporary message and add it immediately
      Message tempMessage = Message(
        sender: ConversationMember(accountId: _currentUserId, name: Auth2().fullName ?? 'You'),
        message: messageText,
        fileAttachments: fileAttachments,
        dateSentUtc: DateTime.now().toUtc(),
      );

      setState(() {
        _messages.add(tempMessage);
        Message.sortListByDateSent(_messages);
        _shouldScrollToTarget = _ScrollTarget.bottom; //TBD
      });

      _removeAttachedFiles(fileAttachments);

      // Send to the backend
      List<Message>? newMessages = await Social().createConversationMessage(
        conversationId: _conversationId!,
        message: messageText,
        fileAttachments: fileAttachments,
      );

      Message? newMessage;
      List<String>? fileIds;
      if (CollectionUtils.isNotEmpty(newMessages)) {
        newMessage = newMessages!.first;
        fileIds = newMessage.fileAttachments?.where((e) => e.type != FileType.file).map((e) => e.id).whereNotNull().toList();
      }
      if (CollectionUtils.isNotEmpty(fileIds)) {
        List<FileContentItemReference>? fileRefs = await Content().getFileContentDownloadUrls(fileIds!, Content.conversationsContentCategory, entityId: _conversationId);
        for (FileContentItemReference ref in fileRefs ?? []) {
          for (FileAttachment file in newMessage?.fileAttachments ?? []) {
            if (ref.key == file.id) {
              file.url = ref.url;
            }
          }
        }
      }

      if (mounted) {
        if (newMessage != null) {
          setState(() {
            Message serverMessage = newMessage!;
            // Update the temporary message with the server's message if needed
            int index = _messages.indexOf(tempMessage);
            if (index >= 0) {
              _messages[index] = serverMessage;
              Message.sortListByDateSent(_messages);
            }
          });
        } else {
          // If creation failed
          setState(() {
            _messages.remove(tempMessage);
          });
          AppToast.showMessage(Localization().getStringEx('', 'Failed to send message'));
        }
      }
      _submitting = false;
    }
  }

  Future<List<FileContentItemReference>?> _uploadAttachedFiles() async {
    List<FileContentItemReference>? uploaded = await Content().uploadFileContentItems(_attachedFileData, Content.conversationsContentCategory,
      entityId: _conversationId, preUpload: _preUploadFile, postUpload: _postUploadFile);

    int failedFileCount = _attachedFileData.length - (uploaded?.length ?? 0);
    if (failedFileCount > 0) {
      AppToast.showMessage(sprintf(Localization().getStringEx('', 'Failed to upload %s file(s)'), [failedFileCount]));
    }

    return uploaded;
  }

  void _preUploadFile(FileContentItemReference ref) {
    if (ref.name != null) {
      setStateIfMounted(() {
        _uploadingFiles[ref.name!] = true;
      });
    }
  }

  void _postUploadFile(FileContentItemReference ref, Response? response) {
    if (ref.name != null) {
      setStateIfMounted(() {
        _uploadingFiles[ref.name!] = false;
      });
    }
  }

  Future<void> _updateEditingMessage(String newText) async {
    if (!_submitting && _conversationId != null && _editingMessage?.globalId != null) {
      if (newText == _editingMessage?.message?.trim()) {
        FocusScope.of(context).unfocus();
        setState(() {
          _editingMessage = null;
          //_shouldScrollToTarget = _ScrollTarget.bottom;
        });
        _inputController.clear();
      }
      else {
        _submitting = true;

        // Close the keyboard:
        FocusScope.of(context).unfocus();

        bool success = await Social().updateConversationMessage(
          conversationId: _conversationId!,
          globalMessageId: _editingMessage!.globalId!,
          newText: newText,
        );

        if (mounted) {
          if (success) {
            int index = _messages.indexWhere((msg) => msg.globalId == _editingMessage?.globalId);
            if (index >= 0) {
              setState(() {
                Message updatedMessage = Message.fromOther(_editingMessage,
                  message: newText,
                  dateUpdatedUtc: DateTime.now().toUtc(), // Mark it as edited
                );

                _messages[index] = updatedMessage;
                Message.sortListByDateSent(_messages);

                _editingMessage = null;
                _inputController.clear();
                // _shouldScrollToTarget = _ScrollTarget.bottom;
              });
            } else {
              debugPrint('Could not find the old message with globalId: ${_editingMessage?.globalId} to replace.');
            }
          } else {
            AppToast.showMessage(Localization().getStringEx('', 'Failed to update message'));
          }
        }
      }
      _submitting = false;
    }
  }

  void _startListening() {
    SpeechToText().listen(onResult: _onSpeechResult);
    setState(() {
      _listening = true;
    });
  }

  void _stopListening() async {
    await SpeechToText().stopListening();
    setStateIfMounted(() {
      _listening = false;
    });
  }

  void _onSpeechResult(String result, bool finalResult) {
    setState(() {
      _inputController.text = result;
      if (finalResult) {
        _listening = false;
      }
    });
  }

  Future<void> _onTapAttachFile() async {
    //TODO: should file attachments be retained for draft messages?
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
      dialogTitle: Localization().getStringEx("panel.messages.conversation.attach_files.message", "Select file(s) to upload"),
    );
    _addAttachedFiles(result?.files);
    Navigator.of(context).pop();
  }

  void _addAttachedFiles(List<dynamic>? files) {
    if (files == null || files.isEmpty) {
      return;
    }
    setStateIfMounted(() {
      _attachedFiles.addAll(files);
    });
  }

  void _removeAttachedFiles(List<dynamic>? files) {
    if (files == null || files.isEmpty) {
      return;
    }
    List<dynamic> processed = [];
    for (dynamic file in files) {
      if (file is FileAttachment) {
        dynamic found = _attachedFiles.firstWhereOrNull((e) {
          return _getFileName(e) == file.name;
        });
        if (found != null) {
          processed.add(found);
        }
      } else {
        processed.add(file);
      }
    }
    if (processed.isEmpty) {
      return;
    }
    setState(() {
      _attachedFiles.removeAll(processed);
      for (dynamic file in processed) {
        String? name = _getFileName(file);
        _uploadingFiles.remove(name);
      }
    });
  }

  Future<void> _onTapDownloadFile(FileAttachment file, String messageId) async {
    //TODO: implement opening files based on type
    if (StringUtils.isNotEmpty(file.name)) {
      Map<String, Uint8List> files = await Content().getFileContentItems([file.id!], Content.conversationsContentCategory, entityId: _conversationId);
      Uint8List? data = files[file.id];
      if (CollectionUtils.isNotEmpty(data)) {
        AppFile.downloadFile(context: context, fileName: file.name ?? 'file.out', fileBytes: data);
      }
    }
  }

  @override
  void didChangeMetrics() {
    _checkKeyboardVisible.then((visible) {
      _onKeyboardVisibilityChanged(visible);
    });
  }

  void _onKeyboardVisibilityChanged(bool visible) {
    setStateIfMounted(() {
      _shouldScrollToTarget = _ScrollTarget.bottom;
    });
  }

  void _scrollToBottomIfNeeded() {
    BuildContext? scrollToContext;
    switch (_shouldScrollToTarget) {
      case _ScrollTarget.bottom: scrollToContext = _lastContentItemKey.currentContext; break;
      case _ScrollTarget.targetMessage: scrollToContext = _targetMessageContentItemKey.currentContext; break;
      default: break;
    }
    if ((scrollToContext != null) && scrollToContext.mounted) {
      Scrollable.ensureVisible(scrollToContext, duration: Duration(milliseconds: 500)).then((_) {});
      _shouldScrollToTarget = null;
    }
  }

  void _scrollListener() {
    if (_scrollController.position.atEdge) {
      bool isAtTop = (_scrollController.position.pixels == _scrollController.position.maxScrollExtent);
      if (isAtTop && _hasMoreMessages && !_loadingMore && !_loading) {
        _loadMoreMessages();
      }
    }
  }

  Future<bool> get _checkKeyboardVisible async {
    final checkPosition = () => (MediaQuery.of(context).viewInsets.bottom);
    final double position = checkPosition();
    final double secondPosition = await Future.delayed(Duration(milliseconds: 100), () => checkPosition());

    if (position == secondPosition) {
      return position > 0;
    } else {
      return _checkKeyboardVisible; // Check again
    }
  }

  Map<String, FutureOr<Uint8List?>> get _attachedFileData {
    Map<String, FutureOr<Uint8List?>> fileData = {};
    List<dynamic> files = _attachedFiles.toList();
    for (int i = 0; i < files.length; i++) {
      dynamic file = files[i];
      String? name = _getFileName(file);
      if (name != null) {
        fileData[name] = _getFileData(file);
      }
    }
    return fileData;
  }

  Future<Uint8List?> _getFileData(dynamic file) async {
    if (file is PlatformFile) {
      if (file.bytes != null) {
        return file.bytes;
      }
    } else if (file is XFile) {
      Future<Uint8List> bytes = file.readAsBytes();
      return bytes;
    } else if (file is AudioResult) {
      Uint8List? data = file.audioData;
      if (data != null) {
        return data;
      }
    }
    return null;
  }

  String? _getFilePath(dynamic file) {
    if (file is XFile) {
      return file.path;
    }
    else if (!kIsWeb && file is PlatformFile) {
      return file.path;
    }
    return null;
  }

  String? _getFileName(dynamic file) {
    if (file is XFile) {
      return file.name;
    }
    else if (file is PlatformFile) {
      return file.name;
    }
    else if (file is FileAttachment) {
      return file.name;
    }
    else if (file is AudioResult) {
      return _getAudioFileName(file);
    }
    return null;
  }

  String _getAudioFileName(AudioResult result) {
    return 'audio_${result.hashCode}${result.audioFileExtension}';
  }

  FileType _getFileType(dynamic file) {
    if (file is FileAttachment) {
      return _getFileTypeFromString(file.type);
    }
    if (file is AudioResult) {
      return FileType.audio;
    }
    FileType type = FileType.file;
    String? path = kIsWeb ?  _getFileName(file) : _getFilePath(file) ?? _getFileName(file);
    if (FileUtils.isVideo(path)) {
      type = FileType.video;
    } else if (FileUtils.isImage(path)) {
      type = FileType.image;
    } else if (FileUtils.isAudio(path)) {
      type = FileType.audio;
    }
    return type;
  }

  FileType _getFileTypeFromString(String? type) {
    return FileType.values.firstWhereOrNull((e) => e.name == type) ?? FileType.file;
  }

  List<FileAttachment> _getMessageFileAttachments(List<FileContentItemReference>? fileRefs) {
    return fileRefs != null ? List.generate(_attachedFiles.length, (index) {
      dynamic file = _attachedFiles.elementAt(index);
      FileType type = _getFileType(file);
      String? name = _getFileName(file);
      FileContentItemReference ref = fileRefs.firstWhere((ref) => ref.name == name, orElse: () => FileContentItemReference());
      return FileAttachment(name: name, type: type.name, id: ref.key);
    }) : [];
  }
}
