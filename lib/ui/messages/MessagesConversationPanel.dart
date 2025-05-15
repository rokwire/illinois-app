import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:illinois/ext/Social.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/AppDateTime.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/DeepLink.dart';
import 'package:illinois/service/SpeechToText.dart';
import 'package:illinois/ui/directory/DirectoryWidgets.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:illinois/ui/widgets/WebEmbed.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:illinois/ui/widgets/LinkTextEx.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/model/social.dart';
import 'package:rokwire_plugin/service/content.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/social.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

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
    with NotificationsListener, WidgetsBindingObserver, AutomaticKeepAliveClientMixin<MessagesConversationPanel> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _chatBarKey = GlobalKey();
  final GlobalKey _lastContentItemKey = GlobalKey();
  final GlobalKey _targetMessageContentItemKey = GlobalKey();
  final GlobalKey _inputFieldKey = GlobalKey();
  final FocusNode _inputFieldFocus = FocusNode();

  _ScrollTarget? _shouldScrollToTarget;
  Map<String, Uint8List?> _userPhotosCache = {};

  bool _listening = false;
  bool _loading = false;
  bool _loadingMore = false;
  bool _submitting = false;

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

  final Set<String> _globalIds = {};

  static const double _photoSize = 20;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Auth2UserPrefs.notifyFavoritesChanged,
      Localization.notifyStringsUpdated,
      Styles.notifyChanged,
      SpeechToText.notifyError,
    ]);
    WidgetsBinding.instance.addObserver(this);

    _scrollController.addListener(_scrollListener);

    if (widget.conversation != null) {
      _conversation = widget.conversation;
    }

    // Load conversation (if needed) and messages from the backend
    _initConversationAndMessages();

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
    return Stack(children: [
      RefreshIndicator(
        onRefresh: _onPullToRefresh,
        child: Padding(
          padding: EdgeInsets.only(bottom: _scrollContentPaddingBottom),
          child: _messages.isNotEmpty ? Stack(alignment: Alignment.center, children: [
            Column(children: [
              Expanded(
                child: SingleChildScrollView(
                    controller: _scrollController,
                    reverse: true,
                    physics: AlwaysScrollableScrollPhysics(),
                    child: Padding(
                        padding: EdgeInsets.only(left: 16, right: 16, top:16,),
                        child: Semantics(
                            child: Column(children: _buildContentList())
                        )
                    )
                ),
              )
            ],),
            Visibility(visible: _loading, child: CircularProgressIndicator(color: Styles().colors.fillColorSecondary))
          ])
              : _loading
              ? Center(child: CircularProgressIndicator(color: Styles().colors.fillColorSecondary))
              : Center(child: Text((_conversation != null) ? 'No message history' : 'Failed to load conversation', style: Styles().textStyles.getTextStyle('widget.message.light.medium'))
          )
        )
      ),
      Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
              key: _chatBarKey,
              color: Styles().colors.background,
              child: SafeArea(child: _buildChatBar())
          )
      )
    ]);
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
    return contentList;
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
                style: Styles().textStyles.getTextStyle('widget.description.small')
            )
        )
    );
  }

  Decoration get _messageCardDecoration => BoxDecoration(
    color: Styles().colors.white,
    border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
    borderRadius: BorderRadius.all(Radius.circular(8)),
    //boxShadow: [BoxShadow(color: Styles().colors.blackTransparent018, spreadRadius: 1.0, blurRadius: 3.0, offset: Offset(1, 1))],
  );

  Decoration get _highlightedMessageCardDecoration => BoxDecoration(
    color: Styles().colors.white,
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
          Padding(padding: EdgeInsets.all(16), child:
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
                  LinkTextEx(
                    key: UniqueKey(),
                    message.message ?? '',
                    textStyle: Styles().textStyles.getTextStyle('widget.detail.regular'),
                    linkStyle: Styles().textStyles.getTextStyleEx('widget.detail.regular.underline', decorationColor: Styles().colors.fillColorPrimary),
                    onLinkTap: _onTapLink,
                  ),
                ),
                // If dateUpdatedUtc is not null, show a small “(edited)” label
                if (message.dateUpdatedUtc != null)
                  Padding(padding: EdgeInsets.only(left: 4), child:
                    Text(Localization().getStringEx('', '(edited)'), style: Styles().textStyles.getTextStyle('widget.message.light.small')?.copyWith(fontStyle: FontStyle.italic),),
                  ),
                ],),
                WebEmbed(body: message.message)
              ]),
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
    url = UrlUtils.fixUrl(url, scheme: 'https') ?? url;
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
            color: Styles().colors.white,
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
      title: Text(userName, style: Styles().textStyles.getTextStyle('widget.card.title.regular.fat')),
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
          child: Row(
            mainAxisSize: MainAxisSize.max,
            //_buildMessageOptionsWidget(),
            children: [
              if (isEditing) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _editingMessage = null;
                          _inputController.clear();
                        });
                      },
                      child: Styles().images.getImage('close', size: 32) ?? Container()
                  ),
                ),
                SizedBox(width: 8),
              ] else ...[
                SizedBox(width: 32),
              ],
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
                        textInputAction: TextInputAction.send,
                        focusNode: _inputFieldFocus,
                        onSubmitted: _submitMessage,
                        onChanged: (_) => setStateIfMounted(() {}),
                        cursorColor: Styles().colors.fillColorPrimary,
                        decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: BorderSide(color: Styles().colors.fillColorPrimary)),
                            fillColor: Styles().colors.surface,
                            focusColor: Styles().colors.surface,
                            hoverColor: Styles().colors.surface,
                            hintText: "Message ${_getConversationTitle()}",
                            hintStyle: Styles().textStyles.getTextStyle('widget.item.small')
                        ),
                        style: Styles().textStyles.getTextStyle('widget.title.regular')
                    )
                ),
              ),
              _buildSendImage(enabled),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSendImage(bool enabled) {
    if (StringUtils.isNotEmpty(_inputController.text)) {
      // Show send button if there's text
      return MergeSemantics(child: Semantics(label: Localization().getStringEx('', "Send"), enabled: enabled,
          child: IconButton(
              splashRadius: 24,
              icon: Icon(Icons.send, color: enabled ? Styles().colors.fillColorSecondary : Styles().colors.disabledTextColor, semanticLabel: ""),
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
                      : Icon(Icons.mic, color: Styles().colors.fillColorSecondary, semanticLabel: "microphone"),
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
    futures.add(Social().loadConversationMessages(
      conversationId: _conversationId!,
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
    List<Message>? messages = await Social().loadConversationMessages(
      conversationId: _conversationId!,
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
    List<Message>? loadedMessages = await Social().loadConversationMessages(
      conversationId: _conversationId!,
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

  static List<Message> _removeDuplicateMessagesByGlobalId(List<Message> source, Set<String> globalIds) {
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
    if (StringUtils.isNotEmpty(messageText) && _conversationId != null && _currentUserId != null && !_submitting) {
      FocusScope.of(context).requestFocus(FocusNode());

      _inputController.text = '';

      // Create a temporary message and add it immediately
      Message tempMessage = Message(
        sender: ConversationMember(accountId: _currentUserId, name: Auth2().fullName ?? 'You'),
        message: messageText,
        dateSentUtc: DateTime.now().toUtc(),
      );

      setState(() {
        _submitting = true;
        _messages.add(tempMessage);
        Message.sortListByDateSent(_messages);
        _shouldScrollToTarget = _ScrollTarget.bottom; //TBD
      });

      // Send to the backend
      List<Message>? newMessages = await Social().createConversationMessage(
        conversationId: _conversationId!,
        message: messageText,
      );

      if (mounted) {
        if (newMessages != null && newMessages.isNotEmpty) {
          setState(() {
            Message serverMessage = newMessages.first;
            // Update the temporary message with the server's message if needed
            int index = _messages.indexOf(tempMessage);
            if (index >= 0) {
              _messages[index] = serverMessage;
              Message.sortListByDateSent(_messages);
            }
            _submitting = false;
          });
        } else {
          // If creation failed
          setState(() {
            _messages.remove(tempMessage);
            _submitting = false;
          });
          AppToast.showMessage(Localization().getStringEx('', 'Failed to send message'));
        }
      }
    }
  }

  Future<void> _updateEditingMessage(String newText) async {
    if (_conversationId != null && _editingMessage?.globalId != null) {
      if (newText == _editingMessage?.message?.trim()) {
        FocusScope.of(context).unfocus();
        setState(() {
          _editingMessage = null;
          _submitting = false;
          //_shouldScrollToTarget = _ScrollTarget.bottom;
        });
        _inputController.clear();
      }
      else {
        setState(() {
          _submitting = true;
        });

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
                _submitting = false;
                _inputController.clear();
                // _shouldScrollToTarget = _ScrollTarget.bottom;
              });
            } else {
              debugPrint('Could not find the old message with globalId: ${_editingMessage?.globalId} to replace.');
            }
          } else {
            setState(() {
              _submitting = false;
            });
            AppToast.showMessage(Localization().getStringEx('', 'Failed to update message'));
          }
        }
      }
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

  double get _chatBarHeight {
    RenderObject? chatBarRenderBox = _chatBarKey.currentContext?.findRenderObject();
    double? chatBarHeight = ((chatBarRenderBox is RenderBox) && chatBarRenderBox.hasSize) ? chatBarRenderBox.size.height : null;
    return chatBarHeight ?? 0;
  }

  double get _scrollContentPaddingBottom => _chatBarHeight;

  Future<bool> get _checkKeyboardVisible async {
    final checkPosition = () => context.mounted ? MediaQuery.of(context).viewInsets.bottom : 0.0;
    final double position = checkPosition();
    final double secondPosition = await Future.delayed(Duration(milliseconds: 100), () => checkPosition());

    if (position == secondPosition) {
      return position > 0;
    } else {
      return _checkKeyboardVisible; // Check again
    }
  }

}
