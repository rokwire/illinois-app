import 'dart:async';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:expandable_page_view/expandable_page_view.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/ui/messages/MessagesWidgets.dart';
import 'package:illinois/ui/widgets/LinkButton.dart';
import 'package:illinois/ui/widgets/SemanticsWidgets.dart';
import 'package:rokwire_plugin/model/social.dart';
import 'package:rokwire_plugin/service/app_lifecycle.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/social.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:illinois/ui/messages/MessagesHomePanel.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class HomeMessagesSectionWidget extends StatefulWidget {
  final String? favoriteId;
  final StreamController<String>? updateController;

  const HomeMessagesSectionWidget({Key? key, this.favoriteId, this.updateController}) : super(key: key);

  static Widget handle({Key? key, String? favoriteId, HomeDragAndDropHost? dragAndDropHost, int? position}) =>
      HomeHandleWidget(key: key, favoriteId: favoriteId, dragAndDropHost: dragAndDropHost, position: position,
        title: StringUtils.capitalize(title),
      );

  static String get title => Localization().getStringEx('widget.home.messages.label.header.title', 'CONVERSATIONS');

  @override
  State<StatefulWidget> createState() => _HomeMessagesSectionWidgetState();
}

class _HomeMessagesSectionWidgetState extends State<HomeMessagesSectionWidget> with NotificationsListener {
  List<Conversation> _conversations = [];
  Map<String, GlobalKey> _conversationCardKeys = <String, GlobalKey>{};
  DateTime? _pausedDateTime;

  PageController? _pageController;
  Key _pageViewKey = UniqueKey();
  final double _pageSpacing = 16;
  final double _pageBottomPadding = 16;

  @override
  void initState() {
    super.initState();

    NotificationService().subscribe(this, [
      Social.notifyConversationsUpdated,
      Social.notifyMessageSent,
      Auth2.notifyLoginChanged,
      AppLifecycle.notifyStateChanged,]);

    if (widget.updateController != null) {
      widget.updateController!.stream.listen((String command) {
        if (command == HomePanel.notifyRefresh) {
          _updateConversations();
        }
      });
    }

    _loadConversations();
  }

  @override
  void dispose() {
    super.dispose();
    _pageController?.dispose();
    NotificationService().unsubscribe(this);
  }

  @override
  void onNotification(String name, param) {
    if (name == AppLifecycle.notifyStateChanged) {
      _onAppLifecycleStateChanged(param);
    }
    else if ((name == Social.notifyConversationsUpdated) ||
        (name == Social.notifyMessageSent) ||
        (name == Auth2.notifyLoginChanged)) {
      _loadConversations();
    }
  }

  void _onAppLifecycleStateChanged(AppLifecycleState? state) {
    if (state == AppLifecycleState.paused) {
      _pausedDateTime = DateTime.now();
    }
    else if (state == AppLifecycleState.resumed) {
      if (_pausedDateTime != null) {
        Duration pausedDuration = DateTime.now().difference(_pausedDateTime!);
        if (Config().refreshTimeout < pausedDuration.inSeconds) {
          _updateConversations();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return HomeBannerWidget(
      favoriteId: widget.favoriteId,
      title: HomeMessagesSectionWidget.title,
      bannerImageKey: 'banner-messages',
      child: CollectionUtils.isEmpty(_conversations) ? _buildEmpty() : _buildContent(),
      childPadding: const EdgeInsets.only(top: 24.0, bottom: 12.0),
    );
  }

  Widget _buildContent() {
    Widget? contentWidget;
    int visibleCount = _conversations.length;
    int pageCount = visibleCount ~/ _cardsPerPage;
    bool extraPage = (visibleCount % _cardsPerPage) > 0;

    List<Widget> pages = <Widget>[];
    for (int index = 0; index < pageCount + (extraPage ? 1 : 0); index++) {
      List<Widget> pageCards = [];
      for (int conversationIndex = 0; conversationIndex < _cardsPerPage; conversationIndex++) {
        Widget pageCard = SizedBox(width: _cardWidth);
        if (index * _cardsPerPage + conversationIndex < _conversations.length) {
          Conversation conversation = _conversations[index * _cardsPerPage + conversationIndex];
          GlobalKey conversationKey = (_conversationCardKeys[conversation.id!] ??= GlobalKey());
          pageCard = Padding(padding: EdgeInsets.only(right: _pageSpacing, bottom: _pageBottomPadding), child:
            Semantics(/* excludeSemantics: !(_pageController?.page == _conversations?.indexOf(conversation)),*/ child:
              Container(
                constraints: BoxConstraints(maxWidth: _cardWidth),
                child: ConversationCard(
                  key: conversationKey,
                  conversation: conversation,
                  isHorizontal: true,
                ),
              ),
            )
          );
        }
        pageCards.add(pageCard);
      }
      if (_cardsPerPage > 1) {
        pages.add(Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: pageCards,
        ));
      } else {
        pages.addAll(pageCards);
      }
    }

    if (_pageController == null) {
      double screenWidth = MediaQuery.of(context).size.width;
      double pageViewport = (screenWidth - 2 * _pageSpacing) / screenWidth;
      _pageController = PageController(viewportFraction: pageViewport);
    }

    contentWidget = Container(constraints: BoxConstraints(minHeight: _pageHeight), child:
      ExpandablePageView(
        key: _pageViewKey,
        controller: _pageController,
        estimatedPageSize: _pageHeight,
        allowImplicitScrolling: true,
        children: pages,
      ),
    );

    return Column(children: [
      contentWidget,
      AccessibleViewPagerNavigationButtons(
        controller: _pageController,
        pagesCount: () => pages.length,
        centerWidget: LinkButton(
          title: Localization().getStringEx('widget.home.messages.button.all.title', 'View All'),
          hint: Localization().getStringEx('widget.home.messages.button.all.hint', 'Tap to view all conversations'),
          textStyle: Styles().textStyles.getTextStyle('widget.description.regular.light.underline'),
          onTap: _onSeeAll,
        ),
      ),
    ],);
  }

  Widget _buildEmpty() => HomeMessageCard(message: Localization().getStringEx('widget.home.messages.text.empty', 'No recent conversations'),);

  double get _pageHeight {

    double? minContentHeight;
    for(GlobalKey contentKey in _conversationCardKeys.values) {
      final RenderObject? renderBox = contentKey.currentContext?.findRenderObject();
      if ((renderBox is RenderBox) && renderBox.hasSize && ((minContentHeight == null) || (renderBox.size.height < minContentHeight))) {
        minContentHeight = renderBox.size.height;
      }
    }

    return minContentHeight ?? 0;
  }

  double get _cardWidth {
    double screenWidth = MediaQuery.of(context).size.width;
    return (screenWidth - 2 * _cardsPerPage * _pageSpacing) / _cardsPerPage;
  }

  int get _cardsPerPage {
    ScreenType screenType = ScreenUtils.getType(context);
    switch (screenType) {
      case ScreenType.desktop:
        return min(5, (_conversations.length));
      case ScreenType.tablet:
        return min(3, (_conversations.length));
      case ScreenType.phone:
        return 1;
      default:
        return 1;
    }
  }

  Future<void> _loadConversations() async {
    List<Conversation>? conversations = await Social().loadConversations();

    if (mounted) {
      setState(() {
        _conversations = conversations ?? [];
        _conversationCardKeys.clear();
      });
    }
  }

  Future<void> _updateConversations() async {
    List<Conversation>? conversations = await Social().loadConversations();
    if (mounted && !DeepCollectionEquality().equals(_conversations, conversations)) {
      setState(() {
        _conversations = conversations ?? [];
        _pageViewKey = UniqueKey();
        _conversationCardKeys.clear();
        _pageController?.jumpToPage(0);
      });
    }
  }

  void _onSeeAll() {
    Analytics().logSelect(target: "View All", source: '${widget.runtimeType}' );
    MessagesHomePanel.present(context, conversations: _conversations);
  }
}