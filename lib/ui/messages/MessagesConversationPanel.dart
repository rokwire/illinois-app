import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:illinois/ext/Social.dart';
import 'package:illinois/service/AppDateTime.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/FlexUI.dart';
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
  final bool? unread;
  final void Function()? onTapBanner;
  final Conversation conversation;
  MessagesConversationPanel({Key? key, required this.conversation, this.unread, this.onTapBanner}) : super(key: key);

  _MessagesConversationPanelState createState() => _MessagesConversationPanelState();
}

class _MessagesConversationPanelState extends State<MessagesConversationPanel>
    with AutomaticKeepAliveClientMixin<MessagesConversationPanel>, WidgetsBindingObserver implements NotificationsListener {
  List<String>? _contentCodes;
  TextEditingController _inputController = TextEditingController();
  final GlobalKey _chatBarKey = GlobalKey();
  final GlobalKey _lastContentItemKey = GlobalKey();
  final GlobalKey _inputFieldKey = GlobalKey();
  final FocusNode _inputFieldFocus = FocusNode();
  late ScrollController _scrollController;
  static double? _scrollPosition;
  bool _shouldScrollToBottom = false;
  Map<String, Uint8List?> _userPhotosCache = {};

  bool _listening = false;
  bool _loading = false;
  bool _messageOptionsExpanded = false;

  // Use the actual Auth2 accountId instead of a placeholder.
  String? get currentUserId => Auth2().accountId;

  // Messages loaded from the backend
  List<Message> _messages = [];

  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, [
      FlexUI.notifyChanged,
      Auth2UserPrefs.notifyFavoritesChanged,
      Localization.notifyStringsUpdated,
      Styles.notifyChanged,
      SpeechToText.notifyError,
    ]);
    _scrollController = ScrollController(initialScrollOffset: _scrollPosition ?? 0);
    _scrollController.addListener(_scrollListener);

    _contentCodes = buildContentCodes();

    // Load messages from the backend
    _loadMessages();

    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _inputController.dispose();
    _inputFieldFocus.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // AutomaticKeepAliveClientMixin
  @override
  bool get wantKeepAlive => true;

  // NotificationsListener
  @override
  void onNotification(String name, dynamic param) {
    if (name == FlexUI.notifyChanged) {
      _updateContentCodes();
      setStateIfMounted((){});
    } else if ((name == Auth2UserPrefs.notifyFavoritesChanged) ||
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

    _scrollToBottomIfNeeded();

    return Scaffold(
      appBar: RootHeaderBar(title: widget.conversation.membersString, leading: RootHeaderBarLeading.Back,),
      body: _buildContent(),
      backgroundColor: Styles().colors.background,
      bottomNavigationBar: uiuc.TabBar(),
    );
  }

  String _getConversationTitle() {
    // If it's a one-on-one conversation, show the other member's name
    // If group, show something else. For now, if multiple members, just show first.
    if (widget.conversation.members?.length == 1) {
      return widget.conversation.members?.first.name ?? 'Unknown';
    } else {
      // For group conversations, you could customize the title further
      return widget.conversation.membersString ?? 'Group Conversation';
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
              : Center(
              child: Text('No message history', style: Styles().textStyles.getTextStyle('widget.message.light.medium'))
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
    bool isCurrentUser = (senderId == currentUserId);

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
                            onTap: _onTapChatBar,
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


  Widget _buildMessageOptionsWidget() {
    return _messageOptionsExpanded ? Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        //_buildAttachImage(),
        _buildSpeechToTextImage(),
        _buildMessageOptionsImage(),
      ],
    ) : _buildMessageOptionsImage();
  }

  Widget _buildMessageOptionsImage() {
    return MergeSemantics(
        child: Semantics(
            label: Localization().getStringEx('', "Options"),
            enabled: true,
            child: IconButton(
                splashRadius: 24,
                icon: Styles().images.getImage(_messageOptionsExpanded ? 'chevron-left-bold' : 'chevron-right-bold') ??
                    Icon(_messageOptionsExpanded ? Icons.chevron_left : Icons.chevron_right, color: Styles().colors.fillColorSecondary, semanticLabel: ""),
                onPressed: () {
                  setState(() {
                    _messageOptionsExpanded = !_messageOptionsExpanded;
                  });
                }
            )
        )
    );
  }

  Widget _buildAttachImage() {
    return MergeSemantics(
        child: Semantics(
            label: Localization().getStringEx('', "Attach"),
            enabled: true,
            child: IconButton(
                splashRadius: 24,
                icon: Styles().images.getImage('image-placeholder', size: 20.0, color: Styles().colors.fillColorSecondary) ?? Container(),
                onPressed: () {
                  // TODO: Implement attachment picker once ready
                }
            )
        )
    );
  }

  Widget _buildSpeechToTextImage() {
    return Visibility(
        visible: SpeechToText().isEnabled,
        child: MergeSemantics(
            child: Semantics(
                label: Localization().getStringEx('', "Speech to text"),
                child: IconButton(
                    splashRadius: 24,
                    icon: _listening
                        ? Icon(Icons.stop_circle_outlined, color: Styles().colors.fillColorSecondary, semanticLabel: "Stop")
                        : Icon(Icons.mic, color: Styles().colors.fillColorSecondary, semanticLabel: "microphone"),
                    onPressed: () {
                      if (_listening) {
                        _stopListening();
                      } else {
                        _startListening();
                      }
                    }
                )
            )
        )
    );
  }

  Future<void> _loadMessages() async {
    if (widget.conversation.id == null) {
      return;
    }
    setState(() {
      _loading = true;
    });

    // Use the Social API to load conversation messages
    List<Message>? loadedMessages = await Social().loadConversationMessages(
      conversationId: widget.conversation.id!,
      limit: 100,
      offset: 0,
    );

    setState(() {
      _loading = false;
      if (loadedMessages != null) {
        _messages = loadedMessages;
        if (widget.conversation.isGroupConversation) {
          _removeDuplicateMessagesByGlobalId();
        }
        Message.sortListByDateSent(_messages);
        _shouldScrollToBottom = true;
      } else {
        // If null, could indicate a failure to load messages
        _messages = [];
      }
    });
  }

  void _removeDuplicateMessagesByGlobalId() {
    Set<String> globalIds = {};
    List<Message> messages = [];
    for (Message message in _messages) {
      if (message.globalId != null && !globalIds.contains(message.globalId)) {
        messages.add(message);
        globalIds.add(message.globalId!);
      }
    }
    _messages = messages;
  }

  Future<void> _onPullToRefresh() async {
    _loadMessages();
  }

  void _onTapChatBar() {
    setState(() {
      _messageOptionsExpanded = false;
    });
  }

  Future<void> _submitMessage(String message) async {
    if (StringUtils.isNotEmpty(_inputController.text) && widget.conversation.id != null && currentUserId != null) {
      FocusScope.of(context).requestFocus(FocusNode());

      setState(() {
        _shouldScrollToBottom = true;
      });

      // Send message via API
      List<Message>? newMessages = await Social().createConversationMessage(
        conversationId: widget.conversation.id!,
        message: _inputController.text,
      );

      // Clear input after sending
      _inputController.text = '';

      // load the new messages
      if (CollectionUtils.isNotEmpty(newMessages)) {
        _loadMessages();
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
    setState(() {
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

  void _updateContentCodes() {
    List<String>? contentCodes = buildContentCodes();
    if ((contentCodes != null) && !DeepCollectionEquality().equals(_contentCodes, contentCodes)) {
      if (mounted) {
        setState(() {
          _contentCodes = contentCodes;
        });
      } else {
        _contentCodes = contentCodes;
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
      _shouldScrollToBottom = true;
    });
  }

  void _scrollToBottomIfNeeded() {
    BuildContext? handleContext = _lastContentItemKey.currentContext;
    if (handleContext != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_shouldScrollToBottom) {
          Scrollable.ensureVisible(handleContext, duration: Duration(milliseconds: 500)).then((_) {});
          _shouldScrollToBottom = false;
        }
      });
    }
  }

  void _scrollListener() {
    _scrollPosition = _scrollController.position.pixels;
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

  static List<String>? buildContentCodes() {
    List<String>? codes = JsonUtils.listStringsValue(FlexUI()['assistant']);
    return codes;
  }
}
