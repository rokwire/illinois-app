// Copyright 2024 Board of Trustees of the University of Illinois.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:neom/model/Assistant.dart';
import 'package:neom/service/Assistant.dart';
import 'package:neom/service/Auth2.dart';
import 'package:neom/service/Config.dart';
import 'package:neom/service/FirebaseMessaging.dart';
import 'package:neom/service/FlexUI.dart';
import 'package:neom/service/IlliniCash.dart';
import 'package:neom/service/SpeechToText.dart';
import 'package:neom/ui/widgets/AccessWidgets.dart';
import 'package:neom/ui/widgets/TypingIndicator.dart';
import 'package:neom/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class AssistantConversationContentWidget extends StatefulWidget {
  final Stream shouldClearAllMessages;
  AssistantConversationContentWidget({required this.shouldClearAllMessages});

  @override
  State<AssistantConversationContentWidget> createState() => _AssistantConversationContentWidgetState();
}

class _AssistantConversationContentWidgetState extends State<AssistantConversationContentWidget>
    with AutomaticKeepAliveClientMixin<AssistantConversationContentWidget>, WidgetsBindingObserver
    implements NotificationsListener {
  static final String resourceName = 'assistant';

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
  Message? _feedbackMessage;

  int? _queryLimit;
  bool _evaluatingQueryLimit = false;

  Map<String, String>? _userContext;

  late StreamSubscription _streamSubscription;
  bool _loading = false;
  TextEditingController _negativeFeedbackController = TextEditingController();
  FocusNode _negativeFeedbackFocusNode = FocusNode();

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
    _streamSubscription = widget.shouldClearAllMessages.listen((event) {
      _clearAllMessages();
    });

    _contentCodes = buildContentCodes();

    _onPullToRefresh();

    _userContext = _getUserContext();

    if (CollectionUtils.isNotEmpty(Assistant().messages)) {
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
    _negativeFeedbackController.dispose();
    _streamSubscription.cancel();
    _inputFieldFocus.dispose();
    _negativeFeedbackFocusNode.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didUpdateWidget(AssistantConversationContentWidget old) {
    super.didUpdateWidget(old);
    // in case the stream instance changed, subscribe to the new one
    if (widget.shouldClearAllMessages != old.shouldClearAllMessages) {
      _streamSubscription.cancel();
      _streamSubscription = widget.shouldClearAllMessages.listen((_) => _clearAllMessages);
    }
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

    if (Config().assistantComingSoon) {
      return _comingSoon();
    }

    Widget? accessWidget = AccessCard.builder(resource: resourceName);
    _scrollToBottomIfNeeded();

    return accessWidget != null
        ? Column(children: [Padding(padding: EdgeInsets.only(top: 16.0), child: accessWidget)])
        :  Positioned.fill(
                child: Stack(children: [
                Padding(padding: EdgeInsets.only(bottom: _scrollContentPaddingBottom), child: RefreshIndicator(
                    onRefresh: _onPullToRefresh,
                    child: Stack(alignment: Alignment.center, children: [
                      SingleChildScrollView(
                          controller: _scrollController,
                          physics: AlwaysScrollableScrollPhysics(),
                          child: Padding(padding: EdgeInsets.all(16), child:
                          Container(
                              child: Semantics(/*liveRegion: true, */child:
                              Column(children:
                              _buildContentList()))))),
                      Visibility(visible: _loading, child: CircularProgressIndicator(color: Styles().colors.fillColorSecondary))
                    ]))),
                Positioned(bottom: _chatBarPaddingBottom, left: 0, right: 0, child: Container(key: _chatBarKey, color: Styles().colors.surface, child: SafeArea(child: _buildChatBar())))
          ]));
  }

  Widget _comingSoon() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 56.0),
          child: Text(Localization().getStringEx('panel.assistant.coming_soon.message', '{{app_title}} Assistant\nComing Soon!').replaceAll('{{app_title}}', Localization().getStringEx('app.title', 'Illinois')),
            style: Styles().textStyles.getTextStyle('widget.title.light.large.fat'),
            textAlign: TextAlign.center,),
        ),
      ),
    );
  }

  List<Widget> _buildContentList() {
    List<Widget> contentList = <Widget>[];

    for (Message message in Assistant().messages) {
      contentList.add(Padding(padding: EdgeInsets.only(bottom: 16),
          child: _buildChatBubble(message)));
    }

    if (_loadingResponse) {
      contentList.add(_buildTypingChatBubble());
    }
    contentList.add(Container(key: _lastContentItemKey, height: 0));
    return contentList;
  }

  Widget _buildChatBubble(Message message) {
    bool isNegativeFeedbackFormVisible = (message.feedbackResponseType == FeedbackResponseType.negative);
    EdgeInsets bubblePadding = message.user ? EdgeInsets.only(left: 100.0) : EdgeInsets.only(right: 100);
    String answer = message.isAnswerUnknown
        ? Localization()
            .getStringEx('panel.assistant.unknown.answer.value', "I wasn’t able to find an answer from an official university source.")
        : message.content;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
          padding: bubblePadding,
          child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: message.user ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: [
                Flexible(
                    child: Semantics(focused: _shouldSemanticFocusToLastBubble && (!_loadingResponse && message == Assistant().messages.lastOrNull),
                      child:Opacity(
                        opacity: message.example ? 0.5 : 1.0,
                        child: Material(
                            color: message.user
                                ? message.example
                                    ? Styles().colors.background
                                    : Styles().colors.blueAccent
                                : Styles().colors.white,
                            borderRadius: BorderRadius.circular(16.0),
                            child: InkWell(
                                onTap: message.example
                                    ? () {
                                        Assistant().removeMessage(message);
                                        _submitMessage(message.content);
                                      }
                                    : null,
                                child: Container(
                                    decoration: message.example
                                        ? BoxDecoration(
                                            borderRadius: BorderRadius.circular(16.0),
                                            border: Border.all(color: Styles().colors.fillColorPrimary))
                                        : null,
                                    child: Stack(children: [
                                      Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                            message.example
                                                ? Text(
                                                Localization().getStringEx('panel.assistant.label.example.eg.title', "eg. ") +
                                                    message.content,
                                                style: message.user
                                                    ? Styles().textStyles.getTextStyle('widget.title.regular')
                                                    : Styles().textStyles.getTextStyle('widget.title.light.regular'))
                                                : RichText(
                                                textAlign: TextAlign.start,
                                                text: TextSpan(children: [
                                                  WidgetSpan(
                                                      child: Visibility(
                                                          visible: (message.isNegativeFeedbackMessage == true),
                                                          child: Padding(
                                                              padding: EdgeInsets.only(right: 6),
                                                              child: Icon(Icons.thumb_down, size: 18, color: Styles().colors.white)))),
                                                  TextSpan(
                                                      text: answer,
                                                      style: message.user
                                                          ? Styles().textStyles.getTextStyle('widget.assistant.bubble.message.user.regular')
                                                          : Styles().textStyles.getTextStyle('widget.assistant.bubble.feedback.disclaimer.main.regular'))
                                                ])),
                                            Visibility(visible: isNegativeFeedbackFormVisible, child: _buildNegativeFeedbackFormWidget(message)),
                                            Visibility(
                                                visible: (message.feedbackResponseType == FeedbackResponseType.positive),
                                                child: _buildFeedbackResponseDisclaimer())
                                          ])),
                                          Visibility(visible: isNegativeFeedbackFormVisible, child: Align(alignment: Alignment.centerRight, child: Padding(padding: EdgeInsets.only(left: 16, top: 8, right: 8, bottom: 16), child:
                                            GestureDetector(onTap: () => _onTapCloseNegativeFeedbackForm(message), child: Styles().images.getImage('close-circle', excludeFromSemantics: true))
                                          )))
                                    ])))))))
              ])),
      _buildFeedbackAndSourcesExpandedWidget(message)
    ]);
  }

  Widget _buildFeedbackAndSourcesExpandedWidget(Message message) {
    final double feedbackIconSize = 24;
    bool feedbackControlsVisible = (message.acceptsFeedback && !message.isAnswerUnknown);
    bool additionalControlsVisible = !message.user && (Assistant().messages.indexOf(message) != 0);
    bool areSourcesLabelsVisible = additionalControlsVisible && ((CollectionUtils.isNotEmpty(message.sources) || CollectionUtils.isNotEmpty(message.links)));
    bool areSourcesValuesVisible = (additionalControlsVisible && areSourcesLabelsVisible && (message.sourcesExpanded == true));
    List<Link>? deepLinks = message.links;
    List<Widget> webLinkWidgets = _buildWebLinkWidgets(message.sources);

    return Visibility(
        visible: additionalControlsVisible,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Visibility(
                visible: feedbackControlsVisible,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  MergeSemantics(child: Semantics(label: Localization().getStringEx('', "Like"), selected: message.feedback == MessageFeedback.good,
                    child: IconButton(
                        onPressed: message.feedbackExplanation == null
                            ? () {
                                _sendFeedback(message, true);
                              }
                            : null,
                        icon: Icon(message.feedback == MessageFeedback.good ? Icons.thumb_up : Icons.thumb_up_outlined,
                            size: feedbackIconSize,
                            color:
                                message.feedbackExplanation == null ? Styles().colors.fillColorPrimary : Styles().colors.disabledTextColor),
                        iconSize: feedbackIconSize,
                        splashRadius: feedbackIconSize))),
                    MergeSemantics(child: Semantics(label: Localization().getStringEx('', "Dislike"), selected: message.feedback == MessageFeedback.bad,
                      child: IconButton(
                        onPressed: message.feedbackExplanation == null
                            ? () {
                                _sendFeedback(message, false);
                              }
                            : null,
                        icon: Icon(message.feedback == MessageFeedback.bad ? Icons.thumb_down : Icons.thumb_down_outlined,
                            size: feedbackIconSize, color: Styles().colors.fillColorPrimary),
                        iconSize: feedbackIconSize,
                        splashRadius: feedbackIconSize)))
                ])),
            Visibility(
                visible: areSourcesLabelsVisible,
                child: Padding(padding: EdgeInsets.only(top: (!message.acceptsFeedback ? 10 : 0), left: (!message.acceptsFeedback ? 5 : 0)),
                    child: Semantics(
                      child: InkWell(
                        onTap: () => _onTapSourcesAndLinksLabel(message),
                        splashColor: Colors.transparent,
                        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                          Text(Localization().getStringEx('panel.assistant.sources_links.label', 'Sources and Links'),
                              style: Styles().textStyles.getTextStyle('widget.message.small')),
                          Padding(
                              padding: EdgeInsets.only(left: 10),
                              child: Styles().images.getImage(areSourcesValuesVisible ? 'chevron-up-dark-blue' : 'chevron-down-dark-blue') ??
                                  Container())
                    ])))))
          ]),
          Visibility(
              visible: areSourcesValuesVisible,
              child: Padding(
                  padding: EdgeInsets.only(top: 5),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Visibility(
                        visible: CollectionUtils.isNotEmpty(webLinkWidgets),
                        child: Padding(
                            padding: EdgeInsets.only(top: 15),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: webLinkWidgets))),
                    Visibility(
                        visible: CollectionUtils.isNotEmpty(deepLinks),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Padding(
                              padding: EdgeInsets.only(top: 15, bottom: 5),
                              child: Text(Localization().getStringEx('panel.assistant.related.label', 'Related:'),
                                  style: Styles().textStyles.getTextStyle('widget.title.small.semi_fat'))),
                          _buildDeepLinkWidgets(deepLinks)
                        ]))
                  ])))
        ]));
  }

  void _onTapSourcesAndLinksLabel(Message message) {
    setStateIfMounted(() {
      message.sourcesExpanded = !(message.sourcesExpanded ?? false);
      int msgsLength = Assistant().messages.length;
      int msgIndex = (msgsLength > 0) ? Assistant().messages.indexOf(message) : -1;
      if ((msgIndex >= 0) && (msgIndex == (msgsLength - 1))) {
        // Automatically scroll only if the last message "Sources and Links" label is tapped
        _shouldScrollToBottom = true;
      }
    });
  }

  Widget _buildNegativeFeedbackFormWidget(Message message) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
          Localization().getStringEx(
              'panel.assistant.label.feedback.negative.prompt.title', 'Please provide additional information on the issue(s).'),
          style: Styles().textStyles.getTextStyle('widget.assistant.bubble.feedback.negative.description.regular.fat')),
      Padding(
          padding: EdgeInsets.only(top: 10),
          child: Container(
              decoration:
              BoxDecoration(border: Border.all(color: Styles().colors.surfaceAccent), borderRadius: BorderRadius.circular(12.0)),
              child: Padding(
                  padding: EdgeInsets.only(left: 16.0),
                  child: TextField(
                      controller: _negativeFeedbackController,
                      focusNode: _negativeFeedbackFocusNode,
                      maxLines: 2,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(border: InputBorder.none),
                      style: Styles().textStyles.getTextStyle('widget.title.regular'))))),
      Padding(
          padding: EdgeInsets.only(top: 15),
          child: RoundedButton(
              label: Localization().getStringEx('panel.assistant.button.submit.title', 'Submit'),
              contentWeight: 0.4,
              padding: EdgeInsets.symmetric(vertical: 8),
              fontSize: 16,
              onTap: () => _submitNegativeFeedbackMessage(
                  systemMessage: message, negativeFeedbackExplanation: _negativeFeedbackController.text))),
      _buildFeedbackResponseDisclaimer()
    ]);
  }

  Widget _buildFeedbackResponseDisclaimer() {
    return Padding(padding: EdgeInsets.only(top: 10), child: Text(
        Localization().getStringEx('panel.assistant.feedback.disclaimer.description',
            'Your input on this response is anonymous and will be reviewed to improve the quality of the Illinois Assistant.'),
        style: Styles().textStyles.getTextStyle('widget.assistant.bubble.feedback.disclaimer.description.thin')));
  }

  void _sendFeedback(Message message, bool good) {
    if (message.feedbackExplanation != null) {
      return;
    }

    bool bad = false;

    setState(() {
      if (good) {
        if (message.feedback == MessageFeedback.good) {
          message.feedback = null;
        } else {
          message.feedback = MessageFeedback.good;
          Assistant().addMessage(Message(
              content: Localization().getStringEx(
                  'panel.assistant.label.feedback.disclaimer.prompt.title',
                  'Thanks for your feedback!'),
              user: false, feedbackResponseType: FeedbackResponseType.positive));
          _shouldScrollToBottom = true;
          _shouldSemanticFocusToLastBubble = true;
        }
      } else {
        if (message.feedback == MessageFeedback.bad) {
          message.feedback = null;
        } else {
          message.feedback = MessageFeedback.bad;
          Assistant().addMessage(Message(
              content: Localization().getStringEx(
                  'panel.assistant.label.feedback.disclaimer.prompt.title',
                  'Thanks for your feedback!'),
              user: false, feedbackResponseType: FeedbackResponseType.negative));
          _feedbackMessage = message;
          bad = true;
          _shouldScrollToBottom = true;
          _shouldSemanticFocusToLastBubble = true;
        }
      }
    });

    if (!bad && _feedbackMessage != null) {
      Assistant().removeLastMessage();
      _feedbackMessage = null;
      _shouldScrollToBottom = true;
      _shouldSemanticFocusToLastBubble = true;
    }

    Assistant().sendFeedback(message);
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

  List<Widget> _buildWebLinkWidgets(List<String> sources) {
    List<Widget> sourceLinks = [];
    for (String source in sources) {
      Uri? uri = Uri.tryParse(source);
      if ((uri != null) && uri.host.isNotEmpty) {
        sourceLinks.add(_buildWebLinkWidget(source));
      }
    }
    return sourceLinks;
  }

  Widget _buildWebLinkWidget(String source) {
    Uri? uri = Uri.tryParse(source);
    return Padding(
        padding: EdgeInsets.only(bottom: 8, right: 140),
        child: Material(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22), side: BorderSide(color: Styles().colors.fillColorSecondary, width: 1)),
            color: Styles().colors.white,
            child: InkWell(
                onTap: () => _onTapSourceLink(source),
                borderRadius: BorderRadius.circular(22),
                child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Padding(padding: EdgeInsets.only(right: 8), child: Styles().images.getImage('external-link')),
                      Expanded(
                          child: Text(StringUtils.ensureNotEmpty(uri?.host),
                              overflow: TextOverflow.ellipsis,
                              style: Styles().textStyles.getTextStyle('widget.button.link.source.title.semi_fat')))
                    ])))));
  }

  Widget _buildDeepLinkWidgets(List<Link>? links) {
    List<Widget> linkWidgets = [];
    for (Link link in links ?? []) {
      if (linkWidgets.isNotEmpty) {
        linkWidgets.add(SizedBox(height: 8.0));
      }
      linkWidgets.add(_buildDeepLinkWidget(link));
    }
    return Column(children: linkWidgets);
  }

  Widget _buildDeepLinkWidget(Link? link) {
    if (link == null) {
      return Container();
    }
    EdgeInsets padding = const EdgeInsets.only(right: 160.0);
    return Padding(
        padding: padding,
        child: Material(
            color: Styles().colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10), side: BorderSide(color: Styles().colors.mediumGray2, width: 1)),
            child: InkWell(
                borderRadius: BorderRadius.circular(10.0),
                onTap: () {
                  NotificationService().notify('${FirebaseMessaging.notifyBase}.${link.link}', link.params);
                },
                child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(children: [
                      Visibility(
                          visible: (link.iconKey != null),
                          child: Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Styles().images.getImage(link.iconKey ?? '') ?? Container())),
                      Expanded(child: Text(link.name, style: Styles().textStyles.getTextStyle('widget.message.small.semi_fat'))),
                      Styles().images.getImage('chevron-right') ?? Container()
                    ])))));
  }

  Widget _buildChatBar() {
    int? queryLimit = _queryLimit;
    bool enabled = (queryLimit == null) || (queryLimit > 0);
    return Semantics(container: true,
        child: Material(
          color: Styles().colors.surface,
          child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.center, children: [
                Padding(padding: EdgeInsets.symmetric(horizontal: 14), child: Row(mainAxisSize: MainAxisSize.max, children: [
                  Expanded(
                      child:
                        Container(
                          decoration: BoxDecoration(
                              border: Border.all(color: Styles().colors.surfaceAccent), borderRadius: BorderRadius.circular(12.0)),
                          child: Padding(
                              padding: const EdgeInsets.only(left: 16.0),
                              child: Stack(children: [
                                  Semantics(container: true, child:  Padding(padding: EdgeInsets.only(right: 28), child: TextField(
                                    key: _inputFieldKey,
                                    enabled: enabled,
                                    controller: _inputController,
                                    minLines: 1,
                                    maxLines: 3,
                                    textCapitalization: TextCapitalization.sentences,
                                    textInputAction: TextInputAction.send,
                                    focusNode: _inputFieldFocus,
                                    onSubmitted: _submitMessage,
                                    onChanged: (_) => setStateIfMounted((){}),
                                    decoration: InputDecoration(
                                        border: InputBorder.none,
                                        hintText: enabled
                                            ? null
                                            : Localization().getStringEx('panel.assistant.label.queries.limit.title',
                                            'Sorry you are out of questions for today. Please check back tomorrow to ask more questions!')),
                                    style: Styles().textStyles.getTextStyle('widget.title.regular')))),
                                Align(
                                    alignment: Alignment.centerRight,
                                    child: Padding(padding: EdgeInsets.only(right: 0), child: _buildSendImage(enabled)))
                              ]))))
                ])),
                _buildQueryLimit(),
                Visibility(visible: Auth2().isDebugManager && FlexUI().hasFeature('assistant_personalization'), child: _buildContextButton())
              ]))));
  }

  Widget _buildSendImage(bool enabled) {
    if (StringUtils.isNotEmpty(_inputController.text)) {
      return MergeSemantics(child: Semantics(label: Localization().getStringEx('', "Send"), enabled: enabled,
          child: IconButton(
            splashRadius: 24,
            icon: Icon(Icons.send, color: enabled ? Styles().colors.fillColorSecondary : Styles().colors.disabledTextColor, semanticLabel: "",),
            onPressed: enabled
                ? () {
              _submitMessage(_inputController.text);
            }
                : null)));
    } else {
      return Visibility(
          visible: enabled && SpeechToText().isEnabled,
          child: MergeSemantics(child: Semantics(label: Localization().getStringEx('', "Speech to text"),
            child:IconButton(
              splashRadius: 24,
              icon: _listening ? Icon(Icons.stop_circle_outlined, color: Styles().colors.fillColorSecondary, semanticLabel: "Stop",) : Icon(Icons.mic, color: Styles().colors.fillColorSecondary, semanticLabel: "microphone",),
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

  Widget _buildQueryLimit() {
    int? queryLimit = _queryLimit;
    if ((queryLimit == null) && !_evaluatingQueryLimit) {
      return Container();
    }
    return Semantics(container: true,
      child: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
                height: _evaluatingQueryLimit ? 12 : 10,
                width: _evaluatingQueryLimit ? 12 : 10,
                decoration: _evaluatingQueryLimit ? null : BoxDecoration(
                  color: ((queryLimit ?? 0) > 0)
                      ? Styles().colors.saferLocationWaitTimeColorGreen
                      : Styles().colors.saferLocationWaitTimeColorRed,
                  shape: BoxShape.circle),
                child: _evaluatingQueryLimit ? CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Styles().colors.fillColorSecondary,
                ) : null,
            ),
            SizedBox(width: 8),
            Text(_evaluatingQueryLimit ?
                Localization()
                    .getStringEx('panel.assistant.label.queries.evaluating.title', "Evaluating remaining questions today") :
                Localization()
                    .getStringEx('panel.assistant.label.queries.remaining.title', "{{query_limit}} questions remaining today")
                    .replaceAll('{{query_limit}}', queryLimit.toString()),
                style: Styles().textStyles.getTextStyle('widget.title.dark.small'))
          ]),
          Padding(
              padding: EdgeInsets.only(top: 5),
              child: Text(
                  Localization().getStringEx('panel.assistant.inaccurate.description.disclaimer',
                      'The Illinois Assistant may display inaccurate information.\nPlease double-check its responses.'),
                  style: Styles().textStyles.getTextStyle('widget.info.dark.tiny'),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 5))
        ])));
  }

  Widget _buildContextButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Semantics(container: true,
        child: RoundedButton(
          label: Localization().getStringEx('panel.assistant.button.context.title', 'Context'),
          onTap: _showContext,
        ),
    ));
  }

  Future<void> _showContext() {
    List<String> userContextKeys = _userContext?.keys.toList() ?? [];
    List<String> userContextVals = _userContext?.values.toList() ?? [];
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setStateForDialog) {
          List<Widget> contextFields = [];
          for (int i = 0; i < userContextKeys.length; i++) {
            String key = userContextKeys[i];
            String val = userContextVals[i]; // TextEditingController controller = TextEditingController();
            // controller.text = context;
            contextFields.add(Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                Expanded(
                  child: TextFormField(
                      initialValue: key,
                      onChanged: (value) {
                        userContextKeys[i] = value;
                      }),
                ),
                SizedBox(width: 8.0),
                Expanded(
                  child: TextFormField(
                      initialValue: val,
                      onChanged: (value) {
                        userContextVals[i] = value;
                      }),
                ),
              ],
            ));
          }
          return AlertDialog(
            title: Text(Localization().getStringEx('panel.assistant.dialog.context.title', 'User Context')),
            content: SingleChildScrollView(
              child: ListBody(
                children: contextFields,
              ),
            ),
            actions: [
              Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Expanded(
                    child: RoundedButton(
                      label: Localization().getStringEx('panel.assistant.dialog.context.button.add.title', 'Add'),
                      onTap: () {
                        setStateForDialog(() {
                          userContextKeys.add('');
                          userContextVals.add('');
                        });
                      },
                    ),
                  ),
                  SizedBox(
                    width: 8.0,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: RoundedButton(
                        label: Localization().getStringEx('panel.assistant.dialog.context.button.default.title', 'Default'),
                        onTap: () {
                          _userContext = _getUserContext();
                          Navigator.of(context).pop();
                          _showContext();
                        },
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: RoundedButton(
                        label: Localization().getStringEx('panel.assistant.dialog.context.button.profile1.title', 'Profile 1'),
                        onTap: () {
                          _userContext = _getUserContext(
                              name: 'John Doe', netID: 'jdoe', college: 'Media', department: 'Journalism', studentLevel: 'Sophomore');
                          Navigator.of(context).pop();
                          _showContext();
                        },
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 8.0,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: RoundedButton(
                        label: Localization().getStringEx('panel.assistant.dialog.context.button.profile2.title', 'Profile 2'),
                        onTap: () {
                          _userContext = _getUserContext(
                              name: 'Jane Smith',
                              netID: 'jsmith',
                              college: 'Grainger Engineering',
                              department: 'Electrical and Computer Engineering',
                              studentLevel: 'Senior');
                          Navigator.of(context).pop();
                          _showContext();
                        },
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: RoundedButton(
                  label: Localization().getStringEx('panel.assistant.dialog.context.button.save.title', 'Save'),
                  onTap: () {
                    _userContext = {};
                    for (int i = 0; i < userContextKeys.length; i++) {
                      String key = userContextKeys[i];
                      String val = userContextVals[i];
                      if (key.isNotEmpty && val.isNotEmpty) {
                        _userContext?[key] = val;
                      }
                    }
                    if (_userContext?.isEmpty ?? false) {
                      _userContext = null;
                    }
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          );
        });
      },
    );
  }

  Future<void> _submitMessage(String message) async {
    FocusScope.of(context).requestFocus(FocusNode());
    if (_loadingResponse) {
      return;
    }

    setState(() {
      if (message.isNotEmpty) {
        Assistant().addMessage(Message(content: message, user: true));
      }
      _inputController.text = '';
      _loadingResponse = true;
      _shouldScrollToBottom = true;
      _shouldSemanticFocusToLastBubble = true;
    });

    int? queryLimit = _queryLimit;
    if ((queryLimit != null) && (queryLimit <= 0)) {
      setState(() {
        Assistant().addMessage(Message(
            content: Localization().getStringEx(
                'panel.assistant.label.queries.limit.title',
                'Sorry you are out of questions for today. '
                    'Please check back tomorrow to ask more questions!'),
            user: false));
        _shouldScrollToBottom = true;
      });
      return;
    }

    Map<String, String>? userContext = FlexUI().hasFeature('assistant_personalization') ? _userContext : null;

    Message? response = await Assistant().sendQuery(message, context: userContext);
    if (mounted) {
      setState(() {
        if (response != null) {
          Assistant().addMessage(response);
          if (response.queryLimit != null) {
            _queryLimit = response.queryLimit;
          } else if (_queryLimit != null) {
            _queryLimit = _queryLimit! - 1;
          }
        } else {
          Assistant().addMessage(Message(
              content: Localization()
                  .getStringEx('panel.assistant.label.error.title', 'Sorry, something went wrong. For the best results, please restart the app and try your question again.'),
              user: false));
          _inputController.text = message;
        }
        _loadingResponse = false;
        _shouldScrollToBottom = true;
      });
    }
  }

  Future<void> _submitNegativeFeedbackMessage({required Message systemMessage, required String negativeFeedbackExplanation}) async {
    if ((_feedbackMessage == null) || StringUtils.isEmpty(negativeFeedbackExplanation) || _loadingResponse) {
      return;
    }
    FocusScope.of(context).requestFocus(FocusNode());
    setStateIfMounted(() {
      Assistant().addMessage(Message(content: negativeFeedbackExplanation, user: true, isNegativeFeedbackMessage: true));
      _negativeFeedbackController.text = '';
      _shouldScrollToBottom = true;
      _shouldSemanticFocusToLastBubble = true;
    });
    _feedbackMessage?.feedbackExplanation = negativeFeedbackExplanation;
    systemMessage.feedbackResponseType = FeedbackResponseType.positive;
    Message? responseMessage = await Assistant().sendFeedback(_feedbackMessage!);
    debugPrint((responseMessage != null ? 'Succeeded' : 'Failed') + ' to submit negative feedback message.');
    setStateIfMounted(() {
      _feedbackMessage = null;
    });
  }

  Map<String, String>? _getUserContext({String? name, String? netID, String? college, String? department, String? studentLevel}) {
    Map<String, String> context = {};

    college ??= IlliniCash().studentClassification?.collegeName;
    department ??= IlliniCash().studentClassification?.departmentName;
    if (college != null && department != null) {
      context['college'] = college;
      context['department'] = department;
    }

    studentLevel ??= IlliniCash().studentClassification?.studentLevelDescription;
    if (studentLevel != null) {
      context['level'] = studentLevel;
    }

    return context.isNotEmpty ? context : null;
  }

  void _onTapSourceLink(String source) {
    UrlUtils.launchExternal(source);
  }

  void _onTapCloseNegativeFeedbackForm(Message message) {
    Assistant().removeMessage(message);
    setStateIfMounted(() {
      _negativeFeedbackController.text = '';
      _feedbackMessage = null;
    });
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

  Future<void> _onPullToRefresh() async {
    if (mounted && (_evaluatingQueryLimit == false)) {
      setState((){
        _evaluatingQueryLimit = true;
      });
      int? limit = await Assistant().getQueryLimit();
      if (mounted && (limit != null)) {
        setState(() {
          _queryLimit = limit;
          _evaluatingQueryLimit = false;
        });
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

  void _clearAllMessages() {
    if (_loading) {
      return;
    }
    setStateIfMounted(() {
      _loading = true;
    });
    Assistant().removeAllMessages().then((succeeded) {
      setStateIfMounted(() {
        _loading = false;
      });
      late String msg;
      if (succeeded) {
        msg = Localization().getStringEx('panel.assistant.messages.delete.succeeded.msg', 'Successfully removed all messages.');
      } else {
        msg = Localization().getStringEx('panel.assistant.messages.delete.failed.msg', 'Failed to clear all messages.');
      }
      AppAlert.showMessage(context, msg);
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

  double get _chatBarPaddingBottom {
    return _hideChatBar ? 0 : _keyboardHeight;
  }

  double get _keyboardHeight => MediaQuery.of(context).viewInsets.bottom;

  double get _chatBarHeight {
    RenderObject? chatBarRenderBox = _chatBarKey.currentContext?.findRenderObject();
    double? chatBarHeight = ((chatBarRenderBox is RenderBox) && chatBarRenderBox.hasSize) ? chatBarRenderBox.size.height : null;
    return chatBarHeight ?? 0;
  }

  double get _scrollContentPaddingBottom => _keyboardHeight + (_hideChatBar ? 0 : _chatBarHeight);

  bool get _hideChatBar => _negativeFeedbackFocusNode.hasFocus && _keyboardHeight > 0;

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
