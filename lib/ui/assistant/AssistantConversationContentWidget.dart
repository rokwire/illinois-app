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
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:expandable_page_view/expandable_page_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:illinois/model/Dining.dart';
import 'package:illinois/service/Dinings.dart';
import 'package:illinois/ui/athletics/AthleticsGameDetailPanel.dart';
import 'package:illinois/ui/dining/DiningCard.dart';
import 'package:illinois/ui/dining/FoodDetailPanel.dart';
import 'package:illinois/ui/events2/Event2DetailPanel.dart';
import 'package:illinois/ui/events2/Event2Widgets.dart';
import 'package:illinois/ui/explore/ExploreDiningDetailPanel.dart';
import 'package:illinois/ui/widgets/SemanticsWidgets.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:geolocator/geolocator.dart';
import 'package:illinois/ext/Assistant.dart';
import 'package:illinois/ext/Event2.dart';
import 'package:illinois/model/Assistant.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Assistant.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/FirebaseMessaging.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/service/IlliniCash.dart';
import 'package:illinois/service/SpeechToText.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/ui/widgets/AccessWidgets.dart';
import 'package:illinois/ui/widgets/TypingIndicator.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/location_services.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class AssistantConversationContentWidget extends StatefulWidget {
  final Stream shouldClearAllMessages;
  final AssistantProvider? provider;
  final String? initialQuestion;

  AssistantConversationContentWidget({required this.shouldClearAllMessages, this.provider, this.initialQuestion});

  @override
  State<AssistantConversationContentWidget> createState() => _AssistantConversationContentWidgetState();
}

class _AssistantConversationContentWidgetState extends State<AssistantConversationContentWidget>
    with NotificationsListener, WidgetsBindingObserver, AutomaticKeepAliveClientMixin<AssistantConversationContentWidget> {
  static final String resourceName = 'assistant';

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

  LocationServicesStatus? _locationStatus;
  AssistantLocation? _currentLocation;

  Map<String, PageController>? _structsPageControllers;

  late StreamSubscription _streamSubscription;
  bool _loading = false;
  TextEditingController _negativeFeedbackController = TextEditingController();
  FocusNode _negativeFeedbackFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, [
      Auth2UserPrefs.notifyFavoritesChanged,
      Localization.notifyStringsUpdated,
      Styles.notifyChanged,
      SpeechToText.notifyError,
      LocationServices.notifyStatusChanged,
      LocationServices.notifyLocationChanged,
    ]);
    _scrollController = ScrollController(initialScrollOffset: _scrollPosition ?? 0);
    _scrollController.addListener(_scrollListener);
    _streamSubscription = widget.shouldClearAllMessages.listen((event) {
      _clearAllMessages();
    });

    _loadLocationStatus();
    _onPullToRefresh().then((_) {
      _askInitialQuestionIfAllowed();
    });

    _userContext = _getUserContext();

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
    _negativeFeedbackController.dispose();
    _streamSubscription.cancel();
    _inputFieldFocus.dispose();
    _negativeFeedbackFocusNode.dispose();
    _structsPageControllers?.values.forEach((controller) {
      controller.dispose();
    });
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
    if ((name == Auth2UserPrefs.notifyFavoritesChanged) ||
        (name == Localization.notifyStringsUpdated) ||
        (name == Styles.notifyChanged)) {
      setStateIfMounted((){});
    } else if (name == SpeechToText.notifyError) {
      setState(() {
        _listening = false;
      });
    } else if (name == LocationServices.notifyStatusChanged) {
      if (param == null) {
        _loadLocationStatus();
      } else if (param is LocationServicesStatus) {
        _locationStatus = param;
        _loadLocationIfAllowed();
      }
    } else if (name == LocationServices.notifyLocationChanged) {
      if (_locationStatus == LocationServicesStatus.permissionAllowed) {
        _currentLocation = _getLocation(param as Position);
      } else {
        _currentLocation = null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

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

  List<Widget> _buildContentList() {
    List<Widget> contentList = <Widget>[];

    for (Message message in _messages) {
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
    if (_provider == null) {
      return Container();
    }
    bool isNegativeFeedbackFormVisible = (message.feedbackResponseType == FeedbackResponseType.negative);
    bool isPositiveFeedbackFormVisible = (message.feedbackResponseType == FeedbackResponseType.positive);
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
                    child: Semantics(focused: _shouldSemanticFocusToLastBubble && (!_loadingResponse && message == _messages.lastOrNull),
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
                                        Assistant().removeMessage(provider: _provider!, message: message);
                                        _submitMessage(message: message.content, provider: _provider!);
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
                                            GestureDetector(onLongPressStart: (details) => _onLongPressMessage(message, details), child:
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
                                                  WidgetSpan(
                                                      child: MarkdownBody(
                                                          data: answer,
                                                          builders: {
                                                            'thumb_up': _AssistantMarkdownIconBuilder(icon: Icons.thumb_up_outlined, size: 18, color: Styles().colors.fillColorPrimary),
                                                            'thumb_down': _AssistantMarkdownIconBuilder(icon: Icons.thumb_down_outlined, size: 18, color: Styles().colors.fillColorPrimary),
                                                          },
                                                          inlineSyntaxes: [_AssistantMarkdownCustomIconSyntax()],
                                                          styleSheet: MarkdownStyleSheet(p: message.user ? Styles().textStyles.getTextStyle('widget.assistant.bubble.message.user.regular') : Styles().textStyles.getTextStyle('widget.assistant.bubble.feedback.disclaimer.main.regular'), a: TextStyle(decoration: TextDecoration.underline)),
                                                          onTapLink: (text, href, title) {
                                                            AppLaunchUrl.launch(url: href, context: context);
                                                          }))
                                                ]))
                                            ),
                                            Visibility(visible: isNegativeFeedbackFormVisible, child: _buildNegativeFeedbackFormWidget(message)),
                                            Visibility(visible: isPositiveFeedbackFormVisible, child: _buildFeedbackResponseDisclaimer())
                                          ])),
                                          Visibility(visible: isNegativeFeedbackFormVisible, child:
                                            Align(alignment: Alignment.centerRight, child:
                                              GestureDetector(onTap: () => _onTapCloseNegativeFeedbackForm(message), child:
                                                Padding(padding: EdgeInsets.only(left: 16, top: 8, right: 8, bottom: 16), child:
                                                  Styles().images.getImage('close-circle', excludeFromSemantics: true)
                                                )
                                              )
                                            )
                                          )
                                    ])))))))
              ])),

      Visibility(visible: (message.structElements?.isNotEmpty == true), child: _buildStructElementsContainerWidget(message)),
      _buildFeedbackAndSourcesExpandedWidget(message)
    ]);
  }

  void _onLongPressMessage(Message message, LongPressStartDetails longPressDetails) {
    Analytics().logSelect(target: 'Assistant: Copy To Clipboard');
    if (!_canCopyMessage(message)) {
      return;
    }
    String textContent = message.content;
    if (Platform.isIOS) {
      _showIosContextMenu(textContent: textContent, longPressDetails: longPressDetails);
    } else {
      _copyToClipboard(textContent);
    }
  }

  void _showIosContextMenu({required String textContent, required LongPressStartDetails longPressDetails}) {
    if (Platform.isIOS) {
      const String copyItemValue = 'copy';
      Offset globalPosition = longPressDetails.globalPosition;
      final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

      showMenu<String>(context: context,
          position: RelativeRect.fromRect(globalPosition & const Size(40, 40), Offset.zero & overlay.size),
          constraints: BoxConstraints(minWidth: 80, minHeight: 40),
          items: [_buildPopupMenuItemWidget(value: copyItemValue, label: Localization().getStringEx('dialog.copy.title', 'Copy'))],
          color: Styles().colors.white).then((value) {
        switch (value) {
          case copyItemValue:
            _copyToClipboard(textContent);
            break;
          default:
            break;
        }
      });
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
  }

  PopupMenuItem<String> _buildPopupMenuItemWidget({required String value, required String label}) {
    return PopupMenuItem(value: value, height: 32, padding: EdgeInsets.zero, child:
      Container(alignment: Alignment.center,
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: DefaultTextStyle(style: TextStyle(color: CupertinoColors.label, fontSize: 16), child: Text(label))));
  }

  bool _canCopyMessage(Message message) {
    int? messageIndex = _getMessageIndex(message);
    if (messageIndex == null) {
      return false;
    }
    if (messageIndex == (_messages.length - 1)) {
      return !_loadingResponse;
    } else {
      return true;
    }
  }

  int? _getMessageIndex(Message message) {
    int index = _messages.indexOf(message);
    return (index > -1) ? index : null;
  }

  Widget _buildFeedbackAndSourcesExpandedWidget(Message message) {
    final double feedbackIconSize = 24;
    bool feedbackControlsVisible = (message.acceptsFeedback && !message.isAnswerUnknown);
    bool additionalControlsVisible = !message.user && (_messages.indexOf(message) != 0);
    bool areSourcesLabelsVisible = additionalControlsVisible && ((CollectionUtils.isNotEmpty(message.sourceDatEntries) || CollectionUtils.isNotEmpty(message.links)));
    bool areSourcesValuesVisible = (additionalControlsVisible && areSourcesLabelsVisible && (message.sourcesExpanded == true));
    List<Link>? deepLinks = message.links;
    List<Widget> webLinkWidgets = _buildWebLinkWidgets(message.sourceDatEntries);

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
    Analytics().logSelect(target: 'Assistant: Sources and Links');
    setStateIfMounted(() {
      message.sourcesExpanded = !(message.sourcesExpanded ?? false);
      int msgsLength = _messages.length;
      int msgIndex = (msgsLength > 0) ? _messages.indexOf(message) : -1;
      if ((msgIndex >= 0) && (msgIndex == (msgsLength - 1))) {
        // Automatically scroll only if the last message "Sources and Links" label is tapped
        _shouldScrollToBottom = true;
      }
    });
  }

  Widget _buildStructElementsContainerWidget(Message? message) {
    List<dynamic>? elements = message?.structElements;

    if ((elements == null) || (elements.isNotEmpty != true)) {
      return Container();
    }
    String messageId = message?.id ?? '';
    if (_structsPageControllers == null) {
      _structsPageControllers = <String, PageController>{};
    }
    PageController? currentController = _structsPageControllers![messageId];
    if (currentController == null) {
      const int pageSpacing = 8;
      double screenWidth = MediaQuery.of(context).size.width - (2 * pageSpacing);
      double pageViewport = (screenWidth - 2 * pageSpacing) / screenWidth;
      currentController = PageController(viewportFraction: pageViewport);
      _structsPageControllers![messageId] = currentController;
    }
    int elementsCount = elements.length;
    List<Widget> pages = <Widget>[];
    for (int index = 0; index < elementsCount; index++) {
      dynamic element = elements[index];
      Widget? elementCard;
      if (element is Event2) {
        elementCard = Event2Card(element, displayMode: Event2CardDisplayMode.list, onTap: () => _onTapEvent(element));
      } else if (element is Dining) {
        elementCard = DiningCard(element, onTap: (_) => _onTapDiningLocation(element));
      } else if (element is DiningProductItem) {
        elementCard = _DiningProductItemCard(item: element, onTap: () => _onTapDiningProductItem(element));
      } else if (element is DiningNutritionItem) {
        elementCard = _DiningNutritionItemCard(item: element, onTap: () => _onTapDiningNutritionItem(element, elements));
      }

      if (elementCard != null) {
        pages.add(Padding(padding: EdgeInsets.only(right: 18, bottom: 8), child: elementCard));
      }
    }
    return Container(
        padding: EdgeInsets.only(top: 10),
        child: Column(children: <Widget>[
          ExpandablePageView(allowImplicitScrolling: true, controller: currentController, children: pages, padEnds: false,),
          AccessibleViewPagerNavigationButtons(controller: currentController, pagesCount: () => elementsCount),
        ]));
  }

  void _onTapEvent(Event2 event) {
    Analytics().logSelect(target: 'Assistant: Event "${event.name}"');
    if (event.hasGame) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => AthleticsGameDetailPanel(game: event.game)));
    } else {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => Event2DetailPanel(event: event)));
    }
  }

  void _onTapDiningLocation(Dining dining) {
    Analytics().logSelect(target: 'Assistant: Dining Location "${dining.title}"');
    Navigator.push(context, CupertinoPageRoute(builder: (context) => ExploreDiningDetailPanel(dining: dining)));
  }

  void _onTapDiningProductItem(DiningProductItem item) {
    Analytics().logSelect(target: 'Assistant: Dining Product Item "${item.name}"');
    Navigator.push(context, CupertinoPageRoute(builder: (context) => FoodDetailPanel(productItem: item)));
  }

  void _onTapDiningNutritionItem(DiningNutritionItem item, List<dynamic>? elements) {
    Analytics().logSelect(target: 'Assistant: Dining Nutrition Item "${item.name}"');
    String? itemId = item.itemID;
    DiningProductItem? productItem;
    if (itemId != null) {
      if ((elements != null) && elements.isNotEmpty) {
        for (dynamic e in elements) {
          if (e is DiningProductItem) {
            if (e.itemID == itemId) {
              productItem = e;
              break;
            }
          }
        }
      }
    }
    if (productItem != null) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => FoodDetailPanel(productItem: productItem!)));
    }
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
    Analytics().logSelect(target: 'Assistant: Thumb ${good ? 'Up' : 'Down'}');
    if ((_provider == null) || message.feedbackExplanation != null) {
      return;
    }

    bool bad = false;

    setState(() {
      if (good) {
        if (message.feedback == MessageFeedback.good) {
          message.feedback = null;
        } else {
          message.feedback = MessageFeedback.good;
          Assistant().addMessage(
              provider: _provider!,
              message: Message(
                  content:
                      Localization().getStringEx('panel.assistant.label.feedback.disclaimer.prompt.title', 'Thanks for your feedback!'),
                  user: false,
                  feedbackResponseType: FeedbackResponseType.positive));
          _shouldScrollToBottom = true;
          _shouldSemanticFocusToLastBubble = true;
        }
      } else {
        if (message.feedback == MessageFeedback.bad) {
          message.feedback = null;
        } else {
          message.feedback = MessageFeedback.bad;
          Assistant().addMessage(
              provider: _provider!,
              message: Message(
                  content:
                      Localization().getStringEx('panel.assistant.label.feedback.disclaimer.prompt.title', 'Thanks for your feedback!'),
                  user: false,
                  feedbackResponseType: FeedbackResponseType.negative));
          _feedbackMessage = message;
          bad = true;
          _shouldScrollToBottom = true;
          _shouldSemanticFocusToLastBubble = true;
        }
      }
    });

    if (!bad && _feedbackMessage != null) {
      Assistant().removeLastMessage(provider: _provider!);
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

  List<Widget> _buildWebLinkWidgets(List<SourceDataEntry>? sourceDataEntries) {
    List<Widget> sourceLinks = [];
    if (CollectionUtils.isNotEmpty(sourceDataEntries)) {
      for (SourceDataEntry sourceDataEntry in sourceDataEntries!) {
        String? actionLink = sourceDataEntry.actionLink;
        Uri? uri = UriExt.tryParse(actionLink);
        if (uri?.isValid ?? false) {
          sourceLinks.add(_buildWebLinkWidget(uri: uri!));
        }
      }
    }
    return sourceLinks;
  }

  Widget _buildWebLinkWidget({required Uri uri}) {
    return Padding(
        padding: EdgeInsets.only(bottom: 8, right: 140),
        child: Material(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22), side: BorderSide(color: Styles().colors.fillColorSecondary, width: 1)),
            color: Styles().colors.white,
            child: InkWell(
                onTap: () {
                  Analytics().logSelect(target: 'Assistant: Open Source Link');
                  UriExt.launchExternal(uri);
                },
                borderRadius: BorderRadius.circular(22),
                child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Padding(padding: EdgeInsets.only(right: 8), child: Styles().images.getImage('external-link')),
                      Expanded(
                          child: Text(StringUtils.ensureNotEmpty(uri.host),
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
                  Analytics().logSelect(target: 'Assistant: Open Deep Link');
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
    if (_provider == null) {
      return Container();
    }
    int? queryLimit = _availableQueryLimit;
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
                                    onSubmitted: (value) {
                                      _submitMessage(message: value, provider: _provider!);
                                    },
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
            onPressed: ((_provider != null) && enabled)
                ? () {
              _submitMessage(message: _inputController.text, provider: _provider!);
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
    int? queryLimit = _availableQueryLimit;
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
                style: Styles().textStyles.getTextStyle('widget.title.small'))
          ]),
          Padding(
              padding: EdgeInsets.only(top: 5),
              child: Text(
                  Localization().getStringEx('panel.assistant.inaccurate.description.disclaimer',
                      'The Illinois Assistant may display inaccurate information.\nPlease double-check its responses.'),
                  style: Styles().textStyles.getTextStyle('widget.info.tiny'),
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
          enabled: _isAssistantAvailable,
          label: Localization().getStringEx('panel.assistant.button.context.title', 'Context'),
          borderColor: _isAssistantAvailable ? Styles().colors.fillColorSecondary : Styles().colors.disabledTextColor,
          textColor: _isAssistantAvailable ? Styles().colors.fillColorPrimary : Styles().colors.disabledTextColor,
          onTap: _isAssistantAvailable ? () => _showContext() : null,
        ),
    ));
  }

  Future<void> _showContext() {
    Analytics().logSelect(target: 'Assistant: Show Context');
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
                        Analytics().logSelect(target: 'Assistant: Add Context');
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
                          Analytics().logSelect(target: 'Assistant: Default Context');
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
                          Analytics().logSelect(target: 'Assistant: Context Profile 1');
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
                          Analytics().logSelect(target: 'Assistant: Context Profile 2');
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
                    Analytics().logSelect(target: 'Assistant: Save Context');
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

  Future<void> _submitMessage({required String message, required AssistantProvider provider}) async {
    Analytics().logSelect(target: 'Assistant: Send query');
    FocusScope.of(context).requestFocus(FocusNode());
    if ((_provider == null) || _loadingResponse) {
      return;
    }

    setState(() {
      if (message.isNotEmpty) {
        Assistant().addMessage(provider: provider, message: Message(content: message, user: true));
      }
      _inputController.text = '';
      _loadingResponse = true;
      _shouldScrollToBottom = true;
      _shouldSemanticFocusToLastBubble = true;
    });

    int? queryLimit = _queryLimit;
    if ((queryLimit != null) && (queryLimit <= 0)) {
      setState(() {
        Assistant().addMessage(
            provider: _provider!,
            message: Message(
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

    Message? response = await Assistant().sendQuery(message, provider: provider, location: _currentLocation, context: userContext);
    if (mounted) {
      setState(() {
        if (response != null) {
          Assistant().addMessage(provider: _provider!, message: response);
          if (response.queryLimit != null) {
            _queryLimit = response.queryLimit;
          } else if (_queryLimit != null) {
            _queryLimit = _queryLimit! - 1;
          }
        } else {
          Assistant().addMessage(
              provider: _provider!,
              message: Message(
                  content: Localization().getStringEx('panel.assistant.label.error.title',
                      'Sorry, something went wrong. For the best results, please restart the app and try your question again.'),
                  user: false));
          _inputController.text = message;
        }
        _loadingResponse = false;
        _shouldScrollToBottom = true;
      });
    }
  }

  Future<void> _submitNegativeFeedbackMessage({required Message systemMessage, required String negativeFeedbackExplanation}) async {
    Analytics().logSelect(target: 'Assistant: Submit feedback');
    if ((_provider == null) || (_feedbackMessage == null) || StringUtils.isEmpty(negativeFeedbackExplanation) || _loadingResponse) {
      return;
    }
    FocusScope.of(context).requestFocus(FocusNode());
    setStateIfMounted(() {
      Assistant().addMessage(
          provider: _provider!, message: Message(content: negativeFeedbackExplanation, user: true, isNegativeFeedbackMessage: true));
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

  void _onTapCloseNegativeFeedbackForm(Message message) {
    Analytics().logSelect(target: 'Assistant: Close Feedback Form');
    if (_provider != null) {
      Assistant().removeMessage(provider: _provider!, message: message);
      setStateIfMounted(() {
        _negativeFeedbackController.text = '';
        _feedbackMessage = null;
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
      AppAlert.showTextMessage(context, msg);
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

  void _askInitialQuestionIfAllowed() {
    if ((widget.initialQuestion != null) && (widget.initialQuestion?.isNotEmpty == true) && (_provider != null) && ((_availableQueryLimit ?? 0) > 0)) {
      _submitMessage(message: widget.initialQuestion ?? '', provider: _provider!);
    }
  }

  void _loadLocationStatus() {
    LocationServices().status.then((LocationServicesStatus? status) {
      _onLocationStatus(status);
    });
  }

  void _onLocationStatus(LocationServicesStatus? status) {
    _locationStatus = status;
    _loadLocationIfAllowed();
  }

  void _loadLocationIfAllowed() {
    if (_locationStatus == LocationServicesStatus.permissionAllowed) {
      LocationServices().location.then((position) {
        _currentLocation = _getLocation(position);
      });
    } else {
      _currentLocation = null;
    }
  }
  
  AssistantLocation? _getLocation(Position? position) => Storage().debugAssistantLocation ?? AssistantLocation.fromPosition(position);

  AssistantProvider? get _provider => widget.provider;

  List<Message> get _messages => Assistant().getMessages(provider: _provider);

  double get _chatBarPaddingBottom {
    return _hideChatBar ? 0 : _keyboardHeight;
  }

  double get _keyboardHeight => (mounted && context.mounted) ? MediaQuery.of(context).viewInsets.bottom : 0;

  double get _chatBarHeight {
    RenderObject? chatBarRenderBox = _chatBarKey.currentContext?.findRenderObject();
    double? chatBarHeight = ((chatBarRenderBox is RenderBox) && chatBarRenderBox.hasSize) ? chatBarRenderBox.size.height : null;
    return chatBarHeight ?? 0;
  }

  double get _scrollContentPaddingBottom => _keyboardHeight + (_hideChatBar ? 0 : _chatBarHeight);

  bool get _hideChatBar => _negativeFeedbackFocusNode.hasFocus && _keyboardHeight > 0;

  Future<bool> get _checkKeyboardVisible async {
    final checkPosition = () => _keyboardHeight;
    //Check if the position of the keyboard is still changing
    final double position = checkPosition();
    final double secondPosition = await Future.delayed(Duration(milliseconds: 100), () => checkPosition());

    if(position == secondPosition){ //Animation is finished
      return position > 0;
    } else {
      return _checkKeyboardVisible; //Check again
    }
  }

  int? get _availableQueryLimit => _isAssistantAvailable ? _queryLimit : 0;
  bool get _isAssistantAvailable => Assistant().isAvailable;
}

class _AssistantMarkdownCustomIconSyntax extends md.InlineSyntax {
  _AssistantMarkdownCustomIconSyntax() : super(r'\[:(thumb_up|thumb_down):\]');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final tag = match.group(1)!;
    parser.addNode(md.Element.text(tag, ''));
    return true;
  }
}

class _AssistantMarkdownIconBuilder extends MarkdownElementBuilder {
  final IconData icon;
  final Color? color;
  final double? size;

  _AssistantMarkdownIconBuilder({required this.icon, this.color, this.size});

  @override
  Widget visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    return RichText(text: TextSpan(children: [WidgetSpan(child: Icon(icon, color: color, size: size), alignment: PlaceholderAlignment.middle)]));
  }
}

class _DiningProductItemCard extends StatefulWidget {
  final DiningProductItem item;
  final GestureTapCallback? onTap;

  _DiningProductItemCard({required this.item, this.onTap});

  @override
  State<_DiningProductItemCard> createState() => _DiningProductItemCardState();
}

class _DiningProductItemCardState extends State<_DiningProductItemCard> {

  Dining? _dining;
  bool _loadingDining = false;

  @override
  void initState() {
    super.initState();
    _loadDining();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _loadDining() {
    String? diningOptionId = widget.item.diningOptionId;
    if ((diningOptionId != null) && diningOptionId.isNotEmpty) {
      setStateIfMounted(() {
        _loadingDining = true;
      });
      Dinings().loadDining(diningOptionId).then((result) {
        setStateIfMounted(() {
          _dining = result;
          _loadingDining = false;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      child: Container(
          decoration: BoxDecoration(color: Styles().colors.surface, borderRadius: BorderRadius.all(Radius.circular(8)), boxShadow: [BoxShadow(color: Color.fromRGBO(19, 41, 75, 0.3), spreadRadius: 1.0, blurRadius: 1.0, offset: Offset(0, 2))]),
          margin: EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          child: ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(8)),
            child: Container(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _buildDiningWidget(),
                  Row(crossAxisAlignment: CrossAxisAlignment.center, mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.start, children: [
                    Text(widget.item.category ?? '', style: Styles().textStyles.getTextStyle('widget.card.title.tiny.fat'), overflow: TextOverflow.ellipsis, maxLines: 1),
                    Visibility(visible: (widget.item.meal?.isNotEmpty == true), child: Text(' (${widget.item.meal ?? ''})', style: Styles().textStyles.getTextStyle('common.title.secondary'), overflow: TextOverflow.ellipsis, maxLines: 1)),
                  ]),
                  Padding(padding: EdgeInsets.only(top: 2, bottom: 14), child: Row(children: [Expanded(child: Text(widget.item.name ?? '', style: Styles().textStyles.getTextStyle('widget.title.medium.fat'), overflow: TextOverflow.ellipsis))])),
                  Visibility(
                      visible: widget.item.ingredients.isNotEmpty,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(Localization().getStringEx('panel.assistant.dining_product_item.ingredients.label', 'INGREDIENTS:'), style: Styles().textStyles.getTextStyle('widget.label.small.fat'), overflow: TextOverflow.ellipsis),
                        Row(children: [Expanded(child: Text(widget.item.ingredients.join(', '), style: Styles().textStyles.getTextStyle('widget.detail.small'), overflow: TextOverflow.ellipsis))])
                      ])),
                  Visibility(
                      visible: widget.item.dietaryPreferences.isNotEmpty,
                      child: Padding(
                          padding: EdgeInsets.only(top: (widget.item.ingredients.isNotEmpty ? 8 : 0)),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(Localization().getStringEx('panel.assistant.dining_product_item.dietary_preferences.label', 'DIETARY PREFERENCES:'), style: Styles().textStyles.getTextStyle('widget.label.small.fat'), overflow: TextOverflow.ellipsis),
                            Row(children: [Expanded(child: Text(widget.item.dietaryPreferences.join(', '), style: Styles().textStyles.getTextStyle('widget.detail.small'), overflow: TextOverflow.ellipsis))])
                          ]))),
                ],
              ),
            ),
          )),
    );
  }

  Widget _buildDiningWidget() {
    late Widget diningContentWidget;
    if (_loadingDining) {
      diningContentWidget = Padding(padding: EdgeInsets.only(bottom: 8), child: SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)));
    } else if (_dining != null) {
      diningContentWidget = Padding(padding: EdgeInsets.only(bottom: 8), child: Row(crossAxisAlignment: CrossAxisAlignment.center, mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.start, children: [Text(_dining?.title ?? '', style: Styles().textStyles.getTextStyle('widget.card.title.tiny.fat'), overflow: TextOverflow.ellipsis, maxLines: 1)]));
    } else {
      diningContentWidget = Container();
    }
    return diningContentWidget;
  }
}

class _DiningNutritionItemCard extends StatelessWidget {
  final DiningNutritionItem item;
  final GestureTapCallback? onTap;

  _DiningNutritionItemCard({required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
          decoration: BoxDecoration(color: Styles().colors.surface, borderRadius: BorderRadius.all(Radius.circular(8)), boxShadow: [BoxShadow(color: Color.fromRGBO(19, 41, 75, 0.3), spreadRadius: 1.0, blurRadius: 1.0, offset: Offset(0, 2))]),
          margin: EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          child: ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(8)),
            child: Container(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(padding: EdgeInsets.only(top: 2, bottom: 14), child: Row(children: [Expanded(child: Text(item.name ?? '', style: Styles().textStyles.getTextStyle('widget.title.medium.fat'), overflow: TextOverflow.ellipsis))])),
                  Visibility(
                    visible: (item.nutritionList?.isNotEmpty == true),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(Localization().getStringEx('panel.assistant.dining_nutrition_item.info.label', 'NUTRITION INFO:'), style: Styles().textStyles.getTextStyle('widget.label.small.fat'), overflow: TextOverflow.ellipsis),
                      _buildNutritionInfoWidget(item.nutritionList),
                    ]),
                  ),
                ],
              ),
            ),
          )),
    );
  }

  Widget _buildNutritionInfoWidget(List<NutritionNameValuePair>? nutritionList) {
    if (nutritionList == null || nutritionList.isEmpty) {
      return Container();
    }
    String nutritionInfo = '';
    for (NutritionNameValuePair pair in nutritionList) {
      if (nutritionInfo.isNotEmpty) {
        nutritionInfo += ', ';
      }
      nutritionInfo += '${pair.name}: ${pair.value}';
    }
    return Row(mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.center, children: [
      Expanded(
        child: Text(nutritionInfo, style: Styles().textStyles.getTextStyle('widget.detail.small'), overflow: TextOverflow.ellipsis, maxLines: 5),
      ),
    ]);
  }
}