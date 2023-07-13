import 'dart:async';
import 'dart:math';

import 'package:expandable_page_view/expandable_page_view.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:illinois/ui/settings/SettingsInboxHomeContentWidget.dart';
import 'package:illinois/ui/settings/SettingsNotificationsContentPanel.dart';
import 'package:illinois/ui/widgets/LinkButton.dart';
import 'package:illinois/ui/widgets/SemanticsWidgets.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/inbox.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/inbox.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
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
      AppLivecycle.notifyStateChanged,
      Auth2.notifyLoginChanged,
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
    else if (name == AppLivecycle.notifyStateChanged) {
      _onAppLivecycleStateChanged(param);
    }
    else if (name == Auth2.notifyLoginChanged) {
      setStateIfMounted(() {});
    }
    else if (name == Inbox.notifyInboxUserInfoChanged) {
      setStateIfMounted(() {});
    }
    else if (name == Inbox.notifyInboxMessageRead) {
      _refresh(showProgress: true);
    }
  }

  void _onAppLivecycleStateChanged(AppLifecycleState state) {
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

    if (1 < (_messages?.length ?? 0)) {

      for (InboxMessage message in _messages!) {
        pages.add(Padding(key: _contentKeys[message.messageId ?? ''] ??= GlobalKey(), padding: EdgeInsets.only(right: _pageSpacing, bottom: 16), child:
          InboxMessageCard(message: message, onTap: () => _onTapMessage(message)),
        ));
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
    }
    else {
      contentWidget = Padding(padding: EdgeInsets.only(left: 16, right: 16), child:
        InboxMessageCard(message: _messages!.first, onTap: () => _onTapMessage(_messages!.first))
      );
    }

    return Column(children: <Widget>[
      contentWidget,
      AccessibleViewPagerNavigationButtons(controller: _pageController, pagesCount: () => pages.length, centerWidget:
        LinkButton(
          title: Localization().getStringEx('widget.home.inbox.button.all.title', 'View All'),
          hint: Localization().getStringEx('widget.home.inbox.button.all.hint', 'Tap to view all notifications'),
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
      if ((renderBox is RenderBox) && ((minContentHeight == null) || (renderBox.size.height < minContentHeight))) {
        minContentHeight = renderBox.size.height;
      }
    }

    return minContentHeight ?? 0;
  }

  void _onTapMessageLink(String? url) {
    Uri? uri = (url != null) ? Uri.tryParse(url) : null;
    if (uri?.scheme == localScheme) {
      if (uri?.host.toLowerCase() == allNotificationsHost.toLowerCase()) {
        SettingsNotificationsContentPanel.present(context, content: SettingsNotificationsContent.all);
      }
    }
  }

  void _onTapMessage(InboxMessage message) {
    Analytics().logSelect(target: message.subject);
    SettingsNotificationsContentPanel.launchMessageDetail(message);
  }

  void _onTapSeeAll() {
    Analytics().logSelect(target: "View All", source: widget.runtimeType.toString());
    SettingsNotificationsContentPanel.present(context, content: (_unread == true) ? SettingsNotificationsContent.unread : SettingsNotificationsContent.all);
  }
}
