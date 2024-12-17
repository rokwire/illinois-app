import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:illinois/ext/Social.dart';
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
  
  List<Post> _messages = [];

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
    
    //TODO: insert some test messages into _messages for now - use Social() service to get these messages later

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

  Widget _buildContent() {
    return Stack(children: [
      Padding(padding: EdgeInsets.only(bottom: _scrollContentPaddingBottom), child: _messages.isNotEmpty ?
        Stack(alignment: Alignment.center, children: [
          SingleChildScrollView(
              controller: _scrollController,
              physics: AlwaysScrollableScrollPhysics(),
              child: Padding(padding: EdgeInsets.all(16), child:
                Semantics(/*liveRegion: true, */child:
                  Column(children: _buildContentList())
                )
              )
          ),
          Visibility(visible: _loading, child: CircularProgressIndicator(color: Styles().colors.fillColorSecondary))
        ]) : Center(child: Text('No message history', style: Styles().textStyles.getTextStyle('widget.message.light.medium')))),
      Positioned(bottom: _chatBarPaddingBottom, left: 0, right: 0, child: Container(key: _chatBarKey, color: Styles().colors.background, child: SafeArea(child: _buildChatBar())))
    ]);
  }

  List<Widget> _buildContentList() {
    List<Widget> contentList = <Widget>[];

    for (Post message in _messages) {
      contentList.add(Padding(padding: EdgeInsets.only(bottom: 16),
          child: _buildChatBubble(message)));
    }

    if (_loadingResponse) {
      contentList.add(_buildTypingChatBubble());
    }
    contentList.add(Container(key: _lastContentItemKey, height: 0));
    return contentList;
  }

  Widget _buildChatBubble(Post message) {
    EdgeInsets bubblePadding = message.createdByUser ? EdgeInsets.only(left: 100.0) : EdgeInsets.only(right: 100);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
          padding: bubblePadding,
          child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: message.createdByUser ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: [
                Flexible(
                    child: Semantics(focused: _shouldSemanticFocusToLastBubble && (!_loadingResponse && message == _messages.lastOrNull),
                        child: Material(
                            color: message.createdByUser
                                ? Styles().colors.blueAccent
                                : Styles().colors.surface,
                            borderRadius: BorderRadius.circular(16.0),
                            child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(message.body ?? '',
                                    style: message.createdByUser
                                        ? Styles().textStyles.getTextStyle('widget.assistant.bubble.message.user.regular')
                                        : Styles().textStyles.getTextStyle('widget.assistant.bubble.feedback.disclaimer.main.regular'),
                                    textAlign: TextAlign.start)
                                )
                            )
                        )
                    )
              ])),
    ]);
  }

  Widget _buildTypingChatBubble() {
    return Align(
        alignment: AlignmentDirectional.centerStart,
        child: Semantics(focused: true, label: "Loading", child: SizedBox(
            width: 100,
            height: 50,
            child: Material(
                color: Styles().colors.blueAccent,
                borderRadius: BorderRadius.circular(16.0),
                child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TypingIndicator(
                        flashingCircleBrightColor: Styles().colors.surface, flashingCircleDarkColor: Styles().colors.blueAccent))))));
  }

  Widget _buildChatBar() {
    return Semantics(container: true,
        child: Material(
            color: Styles().colors.background,
            child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Row(mainAxisSize: MainAxisSize.max, children: [
                  _buildAttachImage(),
                  Expanded(
                      child:
                      Stack(children: [
                        Semantics(container: true, child: TextField(
                            key: _inputFieldKey,
                            enabled: true,
                            controller: _inputController,
                            minLines: 1,
                            textCapitalization: TextCapitalization.sentences,
                            textInputAction: TextInputAction.send,
                            focusNode: _inputFieldFocus,
                            onSubmitted: _submitMessage,
                            onChanged: (_) => setStateIfMounted((){}),
                            cursorColor: Styles().colors.textColorPrimary,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                              fillColor: Styles().colors.surface,
                              focusColor: Styles().colors.surface,
                              hoverColor: Styles().colors.surface,
                            ),
                            style: Styles().textStyles.getTextStyle('widget.title.regular')
                        )),
                        Align(
                          alignment: Alignment.centerRight,
                          child: _buildSpeechToTextImage(),
                        )
                      ],)
                  ),
                  _buildSendImage(),
                ])
            )
        )
    );
  }

  Widget _buildSendImage() {
    return MergeSemantics(child: Semantics(label: Localization().getStringEx('', "Send"), enabled: true,
        child: IconButton(
            splashRadius: 24,
            icon: Icon(Icons.send, color: Styles().colors.fillColorSecondary, semanticLabel: "",),
            onPressed: () {
              _submitMessage(_inputController.text);
            }
        )));
  }

  Widget _buildAttachImage() {
    return MergeSemantics(child: Semantics(label: Localization().getStringEx('', "Attach"), enabled: true,
        child: IconButton(
            splashRadius: 24,
            icon: Styles().images.getImage('plus') ?? Container(),  //TODO: placeholder icon - @manav2modi replace this icon with yours
            onPressed: () {
              _submitMessage(_inputController.text);
            }
        )));
  }

  Widget _buildSpeechToTextImage() {
    return Visibility(
        visible: SpeechToText().isEnabled,
        child: MergeSemantics(child: Semantics(label: Localization().getStringEx('', "Speech to text"),
            child:IconButton(
                splashRadius: 24,
                icon: _listening ? Icon(Icons.stop_circle_outlined, color: Styles().colors.fillColorSecondary, semanticLabel: "Stop",) : Icon(Icons.mic, color: Styles().colors.fillColorSecondary, semanticLabel: "microphone",),
                onPressed: () {
                  if (_listening) {
                    _stopListening();
                  } else {
                    _startListening();
                  }
                }
            )
        ))
    );
  }

  Future<void> _submitMessage(String message) async {
    if (StringUtils.isNotEmpty(_inputController.text)) {
      FocusScope.of(context).requestFocus(FocusNode());
      if (_loadingResponse) {
        return;
      }

      setState(() {
        //TODO: create message on Social BB
        // if (message.isNotEmpty) {
        //   Social().addMessage(Post(content: message, user: true, displayName: Auth2().fullName ?? '', dateCreated: DateTime.now()));
        // }
        _inputController.text = '';
        _loadingResponse = true;
        _shouldScrollToBottom = true;
        _shouldSemanticFocusToLastBubble = true;
      });

      //TODO: send message to Social BB
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
    _checkKeyboardVisible.then((visible){
      _onKeyboardVisibilityChanged(visible);
    });
  }

  void _onKeyboardVisibilityChanged(bool visible) {
    setStateIfMounted(() {
      _shouldScrollToBottom = true;
      if(visible) {
        _shouldSemanticFocusToLastBubble = false; //We want to keep the semantics focus on the textField
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
    //Check if the position of the keyboard is still changing
    final double position = checkPosition();
    final double secondPosition = await Future.delayed(Duration(milliseconds: 100), () => checkPosition());

    if(position == secondPosition){ //Animation is finished
      return position > 0;
    } else {
      return _checkKeyboardVisible; //Check again
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