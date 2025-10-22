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
import 'package:expandable_page_view/expandable_page_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:geolocator/geolocator.dart';
import 'package:illinois/ext/Assistant.dart';
import 'package:illinois/ext/Event2.dart';
import 'package:illinois/ext/Explore.dart';
import 'package:illinois/model/Assistant.dart';
import 'package:illinois/model/Building.dart';
import 'package:illinois/model/Dining.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Assistant.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/FirebaseMessaging.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/service/IlliniCash.dart';
import 'package:illinois/service/SpeechToText.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/ui/assistant/AssistantWidgets.dart';
import 'package:illinois/ui/athletics/AthleticsGameDetailPanel.dart';
import 'package:illinois/ui/dining/DiningCard.dart';
import 'package:illinois/ui/dining/FoodDetailPanel.dart';
import 'package:illinois/ui/events2/Event2DetailPanel.dart';
import 'package:illinois/ui/events2/Event2Widgets.dart';
import 'package:illinois/ui/explore/ExploreDiningDetailPanel.dart';
import 'package:illinois/ui/map2/Map2ExploreCard.dart';
import 'package:illinois/ui/widgets/SemanticsWidgets.dart';
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

///
/// TBD: DD - This panel is for debug purposes and should be removed at some point. [#4445]
///
class AssistantProvidersConversationContentWidget extends StatefulWidget {

  AssistantProvidersConversationContentWidget();

  @override
  State<AssistantProvidersConversationContentWidget> createState() => _AssistantProvidersConversationContentWidgetState();
}

class _AssistantProvidersConversationContentWidgetState extends State<AssistantProvidersConversationContentWidget>
    with NotificationsListener, WidgetsBindingObserver, AutomaticKeepAliveClientMixin<AssistantProvidersConversationContentWidget> {

  late List<AssistantProvider> _availableProviders;

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

  List<Message> _messages = <Message>[];
  int? _queryLimit;
  bool _evaluatingQueryLimit = false;

  Map<String, String>? _userContext;

  LocationServicesStatus? _locationStatus;
  AssistantLocation? _currentLocation;

  Map<String, PageController>? _structsPageControllers;

  bool _loading = false;

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
      FlexUI.notifyChanged,
    ]);
    _scrollController = ScrollController(initialScrollOffset: _scrollPosition ?? 0);
    _scrollController.addListener(_scrollListener);
    _availableProviders = _buildAvailableProviders();

    _loadLocationStatus();
    _onPullToRefresh();

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
    _inputFieldFocus.dispose();
    _structsPageControllers?.values.forEach((controller) {
      controller.dispose();
    });
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  List<AssistantProvider> _buildAvailableProviders() =>
    AssistantProviderUI.listFromCodes(JsonUtils.listStringsValue(FlexUI()['assistant'])) ?? <AssistantProvider>[];

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
    } else if (name == FlexUI.notifyChanged) {
      _availableProviders = _buildAvailableProviders();
      _onPullToRefresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    _scrollToBottomIfNeeded();

    return Positioned.fill(
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

  @override
  void didChangeMetrics() {
    _checkKeyboardVisible.then((visible){
      _onKeyboardVisibilityChanged(visible);
    });
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
    contentList.add(Container(key: _lastContentItemKey, height: (_hideChatBar ? _chatBarHeight : 0)));
    return contentList;
  }

  Widget _buildChatBubble(Message message) {
    EdgeInsets bubblePadding = message.user ? EdgeInsets.only(left: 100.0) : EdgeInsets.only(right: 100);
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
                                                  WidgetSpan(
                                                      child: MarkdownBody(
                                                          data: (message.user ? message.content : '**[${message.providerDisplayString}]** ${message.content}'),
                                                          styleSheet: MarkdownStyleSheet(p: message.user ? Styles().textStyles.getTextStyle('widget.assistant.bubble.message.user.regular') : Styles().textStyles.getTextStyle('widget.assistant.bubble.feedback.disclaimer.main.regular'), a: TextStyle(decoration: TextDecoration.underline)),
                                                          onTapLink: (text, href, title) {
                                                            AppLaunchUrl.launch(url: href, context: context);
                                                          }))
                                                ])),
                                          ])),
                                    ]))))))
              ])),
      _buildDeepLinksWidget(message),
      Visibility(visible: (message.structElements?.isNotEmpty == true), child: _buildStructElementsContainerWidget(message)),
      _buildSourcesExpandedWidget(message)
    ]);
  }

  Widget _buildSourcesExpandedWidget(Message message) {
    bool additionalControlsVisible = !message.user && (_messages.indexOf(message) != 0);
    bool areSourcesLabelsVisible = additionalControlsVisible && CollectionUtils.isNotEmpty(message.sourceDatEntries);
    bool areSourcesValuesVisible = (additionalControlsVisible && areSourcesLabelsVisible && (message.sourcesExpanded == true));
    List<Widget> webLinkWidgets = _buildWebLinkWidgets(message.sourceDatEntries);

    return Visibility(
        visible: additionalControlsVisible,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Visibility(
                visible: areSourcesLabelsVisible,
                child: Padding(padding: EdgeInsets.only(top: 10, left: 5),
                    child: Semantics(
                        child: InkWell(
                            onTap: () => _onTapLinksLabel(message),
                            splashColor: Colors.transparent,
                            child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                              Text(Localization().getStringEx('panel.assistant.links.label', 'Links'),
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
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: webLinkWidgets)))
                  ])))
        ]));
  }

  void _onTapLinksLabel(Message message) {
    Analytics().logSelect(target: 'Assistant: Links');
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
        elementCard = AssistantDiningProductItemCard(item: element, onTap: () => _onTapDiningProductItem(element));
      } else if (element is DiningNutritionItem) {
        elementCard = AssistantDiningNutritionItemCard(item: element, onTap: () => _onTapDiningNutritionItem(element, elements));
      } else if (element is Building) {
        elementCard = Map2ExploreCard(element, onTap: () => _onTapBuildingItem(element));
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

  void _onTapBuildingItem(Building building) {
    Analytics().logSelect(target: 'Assistant: Building Item "${building.name}"');
    building.exploreLaunchDetail(context);
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

  Widget _buildDeepLinksWidget(Message message) {
    List<Link>? deepLinks = message.links;
    bool hasDeepLinks = CollectionUtils.isNotEmpty(deepLinks);
    return Visibility(visible: hasDeepLinks, child: Padding(padding: EdgeInsets.only(top: 10), child: _buildDeepLinkWidgets(deepLinks)));
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
                                      onSubmitted: (value) {
                                        _submitMessage(message: value);
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
              onPressed: enabled
                  ? () {
                _submitMessage(message: _inputController.text);
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
            label: Localization().getStringEx('panel.assistant.button.context.title', 'Context'),
            onTap: _showContext,
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

  Future<void> _submitMessage({required String message}) async {
    Analytics().logSelect(target: 'Assistant: Send query');
    FocusScope.of(context).requestFocus(FocusNode());
    if (_loadingResponse) {
      return;
    }

    if (_availableProviders.isEmpty) {
      // Do not allow sending message if there is no available providers
      return;
    }

    if (message.isNotEmpty) {
      _addMessage(Message(content: message, user: true));
    }
    setStateIfMounted(() {
      _inputController.text = '';
      _loadingResponse = true;
      _shouldScrollToBottom = true;
      _shouldSemanticFocusToLastBubble = true;
    });

    int? queryLimit = _queryLimit;
    if ((queryLimit != null) && (queryLimit <= 0)) {
      setState(() {
        _addMessage(Message(
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

    List<Future<dynamic>> assistantFutures = [];
    Map<int, AssistantProvider> providerPositions = {};
    for (int i = 0; i < _availableProviders.length; i++) {
      AssistantProvider provider = _availableProviders[i];
      providerPositions.addAll({i: provider});
      assistantFutures.add(Assistant().sendQuery(message, provider: provider, location: _currentLocation, context: userContext));
    }

    List<dynamic> queryResults = await Future.wait(assistantFutures);

    for (int j = 0; j<queryResults.length;j++) {
      dynamic result = queryResults[j];
      AssistantProvider provider = _availableProviders[j];
      if (result is Message) {
        result.provider = provider;
        _addMessage(result);
        if (result.queryLimit != null) {
          _queryLimit = result.queryLimit;
        } else if (_queryLimit != null) {
          _queryLimit = _queryLimit! - 1;
        }
      } else {
        _addMessage(Message(
            content: Localization().getStringEx('panel.assistant.label.error.title',
                'Sorry, something went wrong. For the best results, please restart the app and try your question again.'),
            user: false, provider: provider));
        _inputController.text = message;
      }
    }
    setStateIfMounted(() {
      _loadingResponse = false;
      _shouldScrollToBottom = true;
    });
  }

  void _addMessage(Message message) {
    _messages.add(message);
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

  void _onKeyboardVisibilityChanged(bool visible) {
    setStateIfMounted(() {
      _shouldScrollToBottom = true;
      if(visible) {
        _shouldSemanticFocusToLastBubble = false; //We want to keep the semantics focus on the textField
      }
    });
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

  double get _chatBarPaddingBottom {
    return _hideChatBar ? 0 : _keyboardHeight;
  }

  double get _keyboardHeight => (mounted && context.mounted) ? MediaQuery.of(context).viewInsets.bottom : 0.0;

  double get _chatBarHeight {
    RenderObject? chatBarRenderBox = _chatBarKey.currentContext?.findRenderObject();
    double? chatBarHeight = ((chatBarRenderBox is RenderBox) && chatBarRenderBox.hasSize) ? chatBarRenderBox.size.height : null;
    return chatBarHeight ?? 0;
  }

  double get _scrollContentPaddingBottom => _keyboardHeight + (_hideChatBar ? 0 : _chatBarHeight);

  bool get _hideChatBar => (_keyboardHeight <= 0);
}
