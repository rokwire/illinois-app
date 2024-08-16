import 'dart:async';
import 'dart:math';

import 'package:expandable_page_view/expandable_page_view.dart';
import 'package:flutter/material.dart';
import 'package:neom/service/Analytics.dart';
import 'package:neom/service/Auth2.dart';
import 'package:neom/service/Config.dart';
import 'package:neom/ui/home/HomePanel.dart';
import 'package:neom/ui/home/HomeWidgets.dart';
import 'package:neom/ui/notifications/NotificationsInboxPage.dart';
import 'package:neom/ui/notifications/NotificationsHomePanel.dart';
import 'package:neom/ui/widgets/LinkButton.dart';
import 'package:neom/ui/widgets/SemanticsWidgets.dart';
import 'package:neom/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/inbox.dart';
import 'package:rokwire_plugin/service/app_lifecycle.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/inbox.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

enum HomeInboxContent { all, unread }

class HomeInboxWidget extends StatefulWidget {

  final HomeInboxContent content;
  final String? favoriteId;
  final StreamController<String>? updateController;

  HomeInboxWidget({Key? key, required this.content, this.favoriteId, this.updateController}) : super(key: key);

  static Widget handle({Key? key, required HomeInboxContent content, String? favoriteId, HomeDragAndDropHost? dragAndDropHost, int? position}) =>
    HomeHandleWidget(key: key, favoriteId: favoriteId, dragAndDropHost: dragAndDropHost, position: position,
      title: titleForContent(content),
    );

  String get _title => titleForContent(content);

  static String title({required HomeInboxContent content}) => titleForContent(content);

  static String titleForContent(HomeInboxContent content) {
    switch (content) {
      case HomeInboxContent.all:
        return Localization().getStringEx('widget.home.inbox.text.all.title', 'All Notifications');
      case HomeInboxContent.unread:
        return Localization().getStringEx('widget.home.inbox.text.unread.title', 'Unread Notifications');
    }
  }

  State<HomeInboxWidget> createState() => _HomeInboxWidgetState();
}

class _HomeInboxWidgetState extends State<HomeInboxWidget> implements NotificationsListener {
  List<InboxMessage>? _messages;
  bool _loadingMessages = false;
  bool _loadingMessagesPage = false;
  bool _hasMoreMessages = true;
  bool? _unread;
  DateTime? _pausedDateTime;

  PageController? _pageController;
  Key _pageViewKey = UniqueKey();
  Map<String, GlobalKey> _contentKeys = <String, GlobalKey>{};
  final double _pageSpacing = 16;

  static const String localScheme = 'local';
  static const String allNotificationsHost = 'all_notifications';
  static const String localUrlMacro = '{{local_url}}';

  @override
  void initState() {

    NotificationService().subscribe(this, [
      Connectivity.notifyStatusChanged,
      AppLifecycle.notifyStateChanged,
      Auth2.notifyLoginSucceeded,
      Inbox.notifyInboxUserInfoChanged,
      Inbox.notifyInboxMessageRead,
    ]);

    _unread = (widget.content == HomeInboxContent.unread) ? true : null;

    if (widget.updateController != null) {
      widget.updateController!.stream.listen((String command) {
        if (command == HomePanel.notifyRefresh) {
          _refresh(showProgress: true);
        }
      });
    }

    if (Connectivity().isOnline && Auth2().isLoggedIn) {
      _loadingMessages = true;
      Inbox().loadMessages(unread: _unread, muted: false, offset: 0, limit: Config().homeRecentNotificationsCount).then((List<InboxMessage>? messages) {
        setStateIfMounted(() {
          _loadingMessages = false;
          _messages = messages;
          _hasMoreMessages = messages?.length == Config().homeRecentNotificationsCount;
        });
      });
    }

    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    _pageController?.dispose();
    super.dispose();
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == Connectivity.notifyStatusChanged) {
      _refresh();
    }
    else if (name == AppLifecycle.notifyStateChanged) {
      _onAppLifecycleStateChanged(param);
    }
    else if (name == Auth2.notifyLoginSucceeded) {
      _refresh(showProgress: true);
    }
    else if (name == Inbox.notifyInboxUserInfoChanged) {
      setStateIfMounted(() {});
    }
    else if (name == Inbox.notifyInboxMessageRead) {
      _refresh(showProgress: true);
    }
  }

  void _onAppLifecycleStateChanged(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedDateTime = DateTime.now();
    }
    else if (state == AppLifecycleState.resumed) {
      if (_pausedDateTime != null) {
        Duration pausedDuration = DateTime.now().difference(_pausedDateTime!);
        if (Config().refreshTimeout < pausedDuration.inSeconds) {
          _refresh();
        }
      }
    }
  }

  void _refresh({bool showProgress = false}) {
    if (Connectivity().isOnline && Auth2().isLoggedIn) {
      if (showProgress) {
        setStateIfMounted(() {
          _loadingMessagesPage = true;
        });
      }
      Inbox().loadMessages(unread: _unread, muted: false, offset: 0, limit: max(_messages?.length ?? 0, Config().homeRecentNotificationsCount)).then((List<InboxMessage>? messages) {
        if (showProgress) {
          _loadingMessages = false;
        }
        setStateIfMounted(() {
          _messages = messages;
        });
      });
    } else {
      setStateIfMounted(() {});
    }
  }

  void _loadNextPage() {
    if (Connectivity().isOnline && Auth2().isLoggedIn && !_loadingMessagesPage && _hasMoreMessages) {
      if (mounted) {
        setState(() {
          _loadingMessagesPage = true;
        });
        Inbox().loadMessages(unread: _unread, muted: false, offset: _messages?.length ?? 0, limit: Config().homeRecentNotificationsCount).then((List<InboxMessage>? messages) {
          setStateIfMounted(() {
            _loadingMessagesPage = false;
            _hasMoreMessages = (messages?.length ?? 0) == Config().homeRecentNotificationsCount;
            if (messages != null) {
              if (_messages != null) {
                _messages?.addAll(messages);
              }
              else {
                _messages = messages;
              }
            }
          });
        });
      }
    }
    else {
      setStateIfMounted(() {
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return HomeSlantWidget(favoriteId: widget.favoriteId,
      title: widget._title,
      titleIconKey: 'inbox',
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (Connectivity().isOffline) {
      return HomeMessageCard(
        title: Localization().getStringEx("common.message.offline", "You appear to be offline"),
        message: Localization().getStringEx("widget.home.inbox.text.offline", "Notifications are not available while offline."),);
    }
    else if (!Auth2().isLoggedIn) {
      return HomeMessageCard(
        title: Localization().getStringEx("common.message.logged_out", "You are not logged in"),
        message: Localization().getStringEx("widget.home.inbox.text.logged_out", "You need to be logged in to access Notifications. Set your privacy level to 4 or 5 in your Profile. Then find the sign-in prompt under Settings."),);
    }
    else if (_loadingMessages) {
      return HomeProgressWidget();
    }
    else if (_messages == null) {
      return HomeMessageCard(message: Localization().getStringEx("widget.home.inbox.text.failed.description", "Failed to load notifications."),);
    }
    else if (CollectionUtils.isEmpty(_messages)) {
      if (widget.content == HomeInboxContent.unread) {
        String message = Localization().getStringEx("widget.home.inbox.text.empty.unread.description", "You have no unread notifications. <a href='$localUrlMacro'><b>View all notifications</b></а>.")
          .replaceAll(localUrlMacro, '$localScheme://$allNotificationsHost');
          return HomeMessageHtmlCard(message: message, onTapLink: _onTapMessageLink,);
      }
      else {
        return HomeMessageCard(
          message: Localization().getStringEx("widget.home.inbox.text.empty.all.description", "You have not any notifications yet."),);
      }
    }
    else {
      return _buildMessagesContent();
    }
  }

  Widget _buildMessagesContent() {
    Widget contentWidget;
    List<Widget> pages = <Widget>[];
    int messagesCount = _messages?.length ?? 0;
    int pageCount = messagesCount ~/ _cardsPerPage;

    for (int index = 0; index < pageCount + 1; index++) {
      List<Widget> pageCards = [];
      for (int messageIndex = 0; messageIndex < _cardsPerPage; messageIndex++) {
        if (index * _cardsPerPage + messageIndex >= _messages!.length) {
          break;
        }
        InboxMessage message = _messages![index * _cardsPerPage + messageIndex];
        pageCards.add(Padding(key: _contentKeys[message.messageId ?? ''] ??= GlobalKey(), padding: EdgeInsets.only(right: _pageSpacing, bottom: 16), child:
          Container(constraints: BoxConstraints(maxWidth: _cardWidth), child: InboxMessageCard(message: message, onTap: () => _onTapMessage(message))),
        ));
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
        onPageChanged: _onPageChanged,
        allowImplicitScrolling: true,
        children: pages,
      ),
    );

    return Column(children: <Widget>[
      contentWidget,
      AccessibleViewPagerNavigationButtons(
        controller: _pageController,
        pagesCount: () {
          if ((_messages?.length ?? 0) == _cardsPerPage) {
            return 1;
          }
          return (_messages?.length ?? 0) ~/ _cardsPerPage + 1;
        },
        centerWidget: LinkButton(
          title: Localization().getStringEx('widget.home.inbox.button.all.title', 'View All'),
          hint: Localization().getStringEx('widget.home.inbox.button.all.hint', 'Tap to view all notifications'),
          textStyle: Styles().textStyles.getTextStyle('widget.description.regular.light.underline'),
          onTap: _onTapSeeAll,
        ),
      ),
    ]);
  }

  void _onPageChanged(int index) {
    if (((_messages?.length ?? 0) <= (index + 1)) && _hasMoreMessages && !_loadingMessagesPage) {
      _loadNextPage();
    }
  }

  double get _pageHeight {

    double? minContentHeight;
    for(GlobalKey contentKey in _contentKeys.values) {
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
        return min(5, (_messages?.length ?? 1));
      case ScreenType.tablet:
        return min(3, (_messages?.length ?? 1));
      case ScreenType.phone:
        return 1;
      default:
        return 1;
    }
  }

  void _onTapMessageLink(String? url) {
    Uri? uri = (url != null) ? Uri.tryParse(url) : null;
    if (uri?.scheme == localScheme) {
      if (uri?.host.toLowerCase() == allNotificationsHost.toLowerCase()) {
        NotificationsHomePanel.present(context, content: NotificationsContent.all);
      }
    }
  }

  void _onTapMessage(InboxMessage message) {
    Analytics().logSelect(target: message.subject);
    NotificationsHomePanel.launchMessageDetail(message);
  }

  void _onTapSeeAll() {
    Analytics().logSelect(target: "View All", source: widget.runtimeType.toString());
    NotificationsHomePanel.present(context, content: (_unread == true) ? NotificationsContent.unread : NotificationsContent.all);
  }
}
