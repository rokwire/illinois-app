import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:illinois/ext/Social.dart';
import 'package:illinois/service/AppDateTime.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/service/SpeechToText.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:illinois/ui/widgets/TypingIndicator.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/model/social.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
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
  bool _shouldSemanticFocusToLastBubble = false;

  bool _listening = false;
  bool _loadingResponse = false;
  bool _loading = false;

  // TODO: Replace 'current-user' logic with actual Auth2().accountId logic when available
  final String currentUserId = "current-user";

  // Fake test messages to mirror the design
  // TODO: Once APIs are ready, load these from the backend.
  List<Post> _messages = [
    Post(
        body: "Message here. No subject line necessary. Right to the point. This message could be as long as needed to be and wouldn’t need to get cut off unless it was over 500 characters.",
        creator: Creator(accountId: "mallory", name: "Mallory Simonds"),
        // TODO: Add dateCreatedUtc for formatting date/time. For now, use static date.
        dateCreatedUtc: DateTime(2024, 7, 10, 10, 0)
    ),
    Post(
        body: "Are you joining the call?",
        creator: Creator(accountId: "john", name: "John Paul"),
        dateCreatedUtc: DateTime(2024, 7, 10, 18, 12)
    ),
    Post(
        body: "Hey, JP! I just finished up the changes we discussed on Friday. I'm looking into Surveys now to see how we could improve them, but let me know if you think there's something else I should focus on.",
        creator: Creator(accountId: "mallory", name: "Mallory Simonds"),
        dateCreatedUtc: DateTime(2024, 7, 10, 18, 14)
    ),
    Post(
        body: "Great\n\nI think I might need some Neom U app tweaks tomorrow. I have a call early Thursday\n\nWe can discuss tomorrow",
        creator: Creator(accountId: "john", name: "John Paul"),
        dateCreatedUtc: DateTime(2024, 8, 10, 18, 30)
    ),
  ];

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

    if (CollectionUtils.isNotEmpty(_messages)) {
      _shouldScrollToBottom = true;
    }

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

  @override
  bool get wantKeepAlive => true;

  @override
  void onNotification(String name, dynamic param) {
    if (name == FlexUI.notifyChanged) {
      _updateContentCodes();
      setStateIfMounted(() {});
    } else if ((name == Auth2UserPrefs.notifyFavoritesChanged) ||
        (name == Localization.notifyStringsUpdated) ||
        (name == Styles.notifyChanged)) {
      setStateIfMounted(() {});
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
      // TODO: Adjust header bar to match design. The screenshot shows "To Mallory Simonds"
      // TODO: Possibly add icons (envelope, bell, gear) as seen in the screenshot's top bar.
      appBar: AppBar(
        backgroundColor: Styles().colors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Styles().colors.textColorPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text("To Mallory Simonds",
            style: Styles().textStyles.getTextStyle('widget.title.large')), // TODO: Update style to match the Figma if needed
        actions: [
          IconButton(
              icon: Icon(Icons.mail, color: Styles().colors.fillColorSecondary, size: 20,),
              onPressed: () {} // TODO: Implement action
          ),
          IconButton(
              icon: Icon(Icons.notifications, color: Styles().colors.fillColorSecondary, size: 20,),
              onPressed: () {} // TODO: Implement action
          ),
          IconButton(
              icon: Icon(Icons.settings, color: Styles().colors.fillColorSecondary, size: 20,),
              onPressed: () {} // TODO: Implement action
          ),
        ],
      ),
      body: _buildContent(),
      backgroundColor: Styles().colors.background,
      bottomNavigationBar: uiuc.TabBar(),
    );
  }

  Widget _buildContent() {
    return Stack(children: [
      Padding(
          padding: EdgeInsets.only(bottom: _scrollContentPaddingBottom),
          child: _messages.isNotEmpty
              ? Stack(alignment: Alignment.center, children: [
            SingleChildScrollView(
                controller: _scrollController,
                physics: AlwaysScrollableScrollPhysics(),
                child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Semantics(
                        child: Column(children: _buildContentList())
                    )
                )
            ),
            Visibility(visible: _loading, child: CircularProgressIndicator(color: Styles().colors.fillColorSecondary))
          ])
              : Center(
              child: Text('No message history', style: Styles().textStyles.getTextStyle('widget.message.light.medium'))
          )
      ),
      Positioned(
          bottom: _chatBarPaddingBottom,
          left: 0,
          right: 0,
          child: Container(
              key: _chatBarKey,
              color: Styles().colors.background, // TODO: Update chat bar background color if needed.
              child: SafeArea(child: _buildChatBar())
          )
      )
    ]);
  }

  List<Widget> _buildContentList() {
    List<Widget> contentList = <Widget>[];

    if (_messages.isNotEmpty) {
      DateTime? lastDate;
      for (int i = 0; i < _messages.length; i++) {
        DateTime? msgDate = _messages[i].dateCreatedUtc;
        if (msgDate != null) {

          String msgDateString = AppDateTime().formatDateTime(msgDate, format: 'MMMM dd, yyyy') ?? '';

          if ((lastDate == null) ||
              (lastDate.year != msgDate.year || lastDate.month != msgDate.month || lastDate.day != msgDate.day)) {
            contentList.add(_buildDateDivider(msgDateString));
            lastDate = msgDate;
          }
        }
        contentList.add(_buildMessageCard(_messages[i]));
      }
    }

    if (_loadingResponse) {
      contentList.add(_buildTypingChatBubble());
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

  Widget _buildMessageCard(Post message) {
    bool fromUser = (message.creator?.accountId == currentUserId);

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Styles().colors.white,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [BoxShadow(color: Styles().colors.blackTransparent018, spreadRadius: 2.0, blurRadius: 6.0, offset: Offset(2, 2))],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            children: [
              // TODO: Replace placeholder avatar with actual avatar if available
              Icon(Icons.account_circle, color: Styles().colors.fillColorPrimary, size: 24),
              SizedBox(width: 8),
              Expanded(
                  child: Text(
                      "${message.creator?.name ?? 'Unknown'}",
                      style: Styles().textStyles.getTextStyle('widget.card.title.regular.fat')
                  )
              ),
              // TODO: Format time based on dateCreatedUtc if needed:
              (message.dateCreatedUtc != null) ?
              Text(AppDateTime().formatDateTime(message.dateCreatedUtc, format: 'h:mm a') ?? '',
                  style: Styles().textStyles.getTextStyle('widget.description.small')
              )
                  : Container(),
            ],
          ),
          SizedBox(height: 8),
          // Message body text
          Text(
              message.body ?? '',
              style: Styles().textStyles.getTextStyle('widget.card.title.small')
          ),
        ]),
      ),
    );
  }

  //TODO: Check if this is something we want
  Widget _buildTypingChatBubble() {
    return Align(
        alignment: AlignmentDirectional.centerStart,
        child: Semantics(
            focused: true,
            label: "Loading",
            child: SizedBox(
                width: 100,
                height: 50,
                child: Material(
                    color: Styles().colors.blueAccent, // TODO: Check if typing indicator bubble should match user color or another color
                    borderRadius: BorderRadius.circular(16.0),
                    child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: TypingIndicator(
                            flashingCircleBrightColor: Styles().colors.surface,
                            flashingCircleDarkColor: Styles().colors.blueAccent
                        )
                    )
                )
            )
        )
    );
  }

  Widget _buildChatBar() {
    return Semantics(
        container: true,
        child: Material(
            color: Styles().colors.background,
            child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Row(mainAxisSize: MainAxisSize.max, children: [
                  _buildAttachImage(),
                  Expanded(
                      child: Stack(children: [
                        Semantics(
                            container: true,
                            child: TextField(
                                key: _inputFieldKey,
                                enabled: true,
                                controller: _inputController,
                                minLines: 1,
                                textCapitalization: TextCapitalization.sentences,
                                textInputAction: TextInputAction.send,
                                focusNode: _inputFieldFocus,
                                onSubmitted: _submitMessage,
                                onChanged: (_) => setStateIfMounted(() {}),
                                cursorColor: Styles().colors.textColorPrimary,
                                decoration: InputDecoration(
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                                    fillColor: Styles().colors.surface, // TODO: Confirm chat input field BG color with final design
                                    focusColor: Styles().colors.surface,
                                    hoverColor: Styles().colors.surface,
                                    hintText: "Message Mallory Simonds", // Matches design placeholder
                                    hintStyle: Styles().textStyles.getTextStyle('widget.item.small')
                                ),
                                style: Styles().textStyles.getTextStyle('widget.title.regular') // TODO: Update style if needed
                            )
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: _buildSpeechToTextImage(),
                        )
                      ])
                  ),
                  _buildSendImage(),
                ])
            )
        )
    );
  }

  Widget _buildSendImage() {
    return MergeSemantics(
        child: Semantics(
            label: Localization().getStringEx('', "Send"),
            enabled: true,
            child: IconButton(
                splashRadius: 24,
                icon: Icon(Icons.send, color: Styles().colors.fillColorSecondary, semanticLabel: ""),
                onPressed: () {
                  _submitMessage(_inputController.text);
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
                icon: Styles().images.getImage('plus-circle', size: 20.0, color: Styles().colors.fillColorSecondary) ?? Container(),
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

  Future<void> _submitMessage(String message) async {
    if (StringUtils.isNotEmpty(_inputController.text)) {
      FocusScope.of(context).requestFocus(FocusNode());
      if (_loadingResponse) {
        return;
      }

      setState(() {
        // TODO: Create message via Social BB API once ready.
        _inputController.text = '';
        _loadingResponse = true;
        _shouldScrollToBottom = true;
        _shouldSemanticFocusToLastBubble = true;
      });

      // TODO: After sending the message via API, await response and add the new message to _messages.
      await Future.delayed(Duration(seconds: 1));
      setState(() {
        // For now, just add the user's message to the list:
        _messages.add(Post(
            body: message,
            creator: Creator(accountId: currentUserId, name: "Me"),
            dateCreatedUtc: DateTime.now()
        ));
        _loadingResponse = false;
      });
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
      if (visible) {
        // We want to keep the semantics focus on the textField when keyboard is visible
        _shouldSemanticFocusToLastBubble = false;
      }
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

  double get _chatBarPaddingBottom => _keyboardHeight;

  double get _keyboardHeight => MediaQuery.of(context).viewInsets.bottom;

  double get _chatBarHeight {
    RenderObject? chatBarRenderBox = _chatBarKey.currentContext?.findRenderObject();
    double? chatBarHeight = ((chatBarRenderBox is RenderBox) && chatBarRenderBox.hasSize) ? chatBarRenderBox.size.height : null;
    return chatBarHeight ?? 0;
  }

  double get _scrollContentPaddingBottom => _keyboardHeight + _chatBarHeight;

  Future<bool> get _checkKeyboardVisible async {
    final checkPosition = () => (MediaQuery.of(context).viewInsets.bottom);
    // Check if the position of the keyboard is still changing
    final double position = checkPosition();
    final double secondPosition = await Future.delayed(Duration(milliseconds: 100), () => checkPosition());

    if (position == secondPosition) {
      // Animation is finished
      return position > 0;
    } else {
      return _checkKeyboardVisible; // Check again
    }
  }

  static List<String>? buildContentCodes() {
    List<String>? codes = JsonUtils.listStringsValue(FlexUI()['assistant']);
    // codes?.sort((String code1, String code2) {
    //   String title1 = _BrowseSection.title(sectionId: code1);
    //   String title2 = _BrowseSection.title(sectionId: code2);
    //   return title1.toLowerCase().compareTo(title2.toLowerCase());
    // });
    return codes;
  }
}
