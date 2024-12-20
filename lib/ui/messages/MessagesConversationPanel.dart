import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:illinois/ext/Social.dart';
import 'package:illinois/service/AppDateTime.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/SpeechToText.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/model/social.dart';
import 'package:rokwire_plugin/service/content.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/social.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class MessagesConversationPanel extends StatefulWidget {
  final Conversation? conversation;
  final String? conversationId;
  MessagesConversationPanel({Key? key, this.conversation, this.conversationId}) : super(key: key);

  _MessagesConversationPanelState createState() => _MessagesConversationPanelState();
}

class _MessagesConversationPanelState extends State<MessagesConversationPanel>
    with AutomaticKeepAliveClientMixin<MessagesConversationPanel>, WidgetsBindingObserver implements NotificationsListener {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _chatBarKey = GlobalKey();
  final GlobalKey _lastContentItemKey = GlobalKey();
  final GlobalKey _inputFieldKey = GlobalKey();
  final FocusNode _inputFieldFocus = FocusNode();

  bool _shouldScrollToBottom = false;
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
  bool _hasMoreMessages = false;
  final int _messagesPageSize = 20;

  final Set<String> _globalIds = {};

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
      appBar: RootHeaderBar(title: _conversation?.membersString, leading: RootHeaderBarLeading.Back,),
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

  Widget _buildMessageCard(Message message) {
    String? senderId = message.sender?.accountId;
    bool isCurrentUser = (senderId == _currentUserId);

    return FutureBuilder<Widget>(
      future: _buildAvatarWidget(isCurrentUser: isCurrentUser, senderId: senderId),
      builder: (context, snapshot) {
        Widget avatar = snapshot.data ??
            (Styles().images.getImage('person-circle-white', size: 20.0, color: Styles().colors.fillColorSecondary) ?? Container());

        return Container(
          margin: EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Styles().colors.white,
          ),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(
                children: [
                  avatar,
                  SizedBox(width: 8),
                  Expanded(
                      child: Text(
                          "${message.sender?.name ?? 'Unknown'}",
                          style: Styles().textStyles.getTextStyle('widget.card.title.regular.fat')
                      )
                  ),
                  if (message.dateSentUtc != null)
                    Text(
                        AppDateTime().formatDateTime(message.dateSentUtc, format: 'h:mm a') ?? '',
                        style: Styles().textStyles.getTextStyle('widget.description.small')
                    ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                  message.message ?? '',
                  style: Styles().textStyles.getTextStyle('widget.card.title.small')
              ),
            ]),
          ),
        );
      },
    );
  }

  Future<Widget> _buildAvatarWidget({required bool isCurrentUser, String? senderId}) async {
    if (isCurrentUser) {
      // Current user's avatar
      Uint8List? profilePicture = Auth2().profilePicture;
      if (profilePicture != null) {
        return Container(
          width: 20,
          height: 20,
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

    return Semantics(
        container: true,
        child: Material(
            color: Styles().colors.background,
            child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Row(mainAxisSize: MainAxisSize.max, children: [
                  //_buildMessageOptionsWidget(),
                  SizedBox(width: 32,), //TODO: add image picker handling
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
                ])
            )
        )
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
      offset: 0,
      limit: _messagesPageSize,
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
          _messages = (_conversation?.isGroupConversation == true) ?
            _removeDuplicateMessagesByGlobalId(messages, _globalIds) : List.from(messages);
          _hasMoreMessages = (_messagesPageSize <= messages.length);
          _shouldScrollToBottom = true;
        }
      });
    }
  }

  Future<void> _refreshMessages() async {
    if (_conversationId == null) {
      return;
    }

    // Use the Social API to load conversation messages
    List<Message>? loadedMessages = await Social().loadConversationMessages(
      conversationId: _conversationId!,
      limit: max(_messages.length, _messagesPageSize),
      offset: 0,
    );

    setStateIfMounted(() {
      if (loadedMessages != null) {
        Message.sortListByDateSent(loadedMessages);
        _globalIds.clear();
        _messages = (_conversation?.isGroupConversation == true) ?
          _removeDuplicateMessagesByGlobalId(loadedMessages, _globalIds) : List.from(loadedMessages);
        _hasMoreMessages = (_messagesPageSize <= loadedMessages.length);
        _shouldScrollToBottom = true;
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
      offset: _messages.length,
    );

    setStateIfMounted(() {
      _loadingMore = false;
      if (loadedMessages != null) {
        Message.sortListByDateSent(loadedMessages);
        List<Message> newMessages = (_conversation?.isGroupConversation == true) ?
          _removeDuplicateMessagesByGlobalId(loadedMessages, _globalIds) : List.from(loadedMessages);
        newMessages.addAll(_messages);
        _messages = newMessages;
        _hasMoreMessages = (_messagesPageSize <= loadedMessages.length);
        _shouldScrollToBottom = false;
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

  Future<void> _submitMessage(String message) async {
    if (StringUtils.isNotEmpty(_inputController.text) && _conversationId != null && _currentUserId != null && _submitting == false) {
      FocusScope.of(context).requestFocus(FocusNode());

      String messageText = _inputController.text.trim();
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
        _shouldScrollToBottom = true;
      });

      try {
        // Send to the backend
        List<Message>? newMessages = await Social().createConversationMessage(
          conversationId: _conversationId!,
          message: messageText,
        );

        if (newMessages != null && newMessages.isNotEmpty) {
          Message serverMessage = newMessages.first;
          // Update the temporary message with the server's message if needed
          int index = _messages.indexOf(tempMessage);
          if (index >= 0) {
            _inputController.text = '';
            setState(() {
              _submitting = false;
              _messages[index] = serverMessage;
              Message.sortListByDateSent(_messages);
            });
          }
        } else {
          _messages.remove(tempMessage);
          setState(() {
            _submitting = false;
          });
          AppToast.showMessage(Localization().getStringEx('', 'Failed to send message'));
        }
      } catch (e) {
        // On error, remove the temporary message
        _messages.remove(tempMessage);
        setState(() {
          _submitting = false;
        });
        AppToast.showMessage(Localization().getStringEx('', 'Failed to send message'));
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
      _shouldScrollToBottom = true;
    });
  }

  void _scrollToBottomIfNeeded() {
    BuildContext? handleContext = _lastContentItemKey.currentContext;
    if (handleContext != null && _shouldScrollToBottom) {
      Scrollable.ensureVisible(handleContext, duration: Duration(milliseconds: 500)).then((_) {});
      _shouldScrollToBottom = false;
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
    final checkPosition = () => (MediaQuery.of(context).viewInsets.bottom);
    final double position = checkPosition();
    final double secondPosition = await Future.delayed(Duration(milliseconds: 100), () => checkPosition());

    if (position == secondPosition) {
      return position > 0;
    } else {
      return _checkKeyboardVisible; // Check again
    }
  }

}
