import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/ui/messages/MessagesConversationPanel.dart';
import 'package:illinois/ui/messages/MessagesWidgets.dart';
import 'package:illinois/ui/directory/DirectoryAccountsList.dart';
import 'package:illinois/ui/directory/DirectoryAccountsPage.dart';
import 'package:illinois/ui/directory/DirectoryWidgets.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/auth2.directory.dart';
import 'package:rokwire_plugin/model/social.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/social.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';

class MessagesDirectoryPanel extends StatefulWidget {
  final List<Conversation> recentConversations;
  final int conversationPageSize;
  final bool? unread;
  final void Function()? onTapBanner;
  final bool startOnAllUsersTab;
  final List<String>? defaultSelectedAccountIds;

  MessagesDirectoryPanel({Key? key, required this.recentConversations, required this.conversationPageSize, this.unread, this.onTapBanner, this.startOnAllUsersTab = false,
    this.defaultSelectedAccountIds,}) :super(key: key);

  _MessagesDirectoryPanelState createState() => _MessagesDirectoryPanelState();
}

class _MessagesDirectoryPanelState extends State<MessagesDirectoryPanel> with NotificationsListener, TickerProviderStateMixin {
  GlobalKey<RecentConversationsPageState> _recentPageKey = GlobalKey();
  GlobalKey<DirectoryAccountsPageState> _allUsersPageKey = GlobalKey();
  final ScrollController _recentScrollController = ScrollController();
  final ScrollController _allUsersScrollController = ScrollController();

  late TabController _tabController;
  int _selectedTab = 0;

  final List<String> _tabNames = [
    Localization().getStringEx('panel.messages.directory.tab.recent.label', 'Recent'),
    Localization().getStringEx('panel.messages.directory.tab.all.label', 'All Users'),
  ];

  String _searchText = '';
  Map<String, dynamic> _filterAttributes = <String, dynamic>{};
  List<Conversation>? _recentConversations;

  final Set<String> _selectedAccountIds = <String>{};

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Social.notifyConversationsUpdated,
      Social.notifyMessageSent,
    ]);

    _selectedTab = widget.startOnAllUsersTab ? 1 : 0;
    _tabController = TabController(length: _tabNames.length, initialIndex: _selectedTab, vsync: this);
    _tabController.addListener(_onTabChanged);

    if (widget.defaultSelectedAccountIds?.isNotEmpty ?? false) {
      _selectedAccountIds.addAll(widget.defaultSelectedAccountIds!);
    }

    _recentConversations = widget.recentConversations;

    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);

    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();

    _recentScrollController.dispose();
    _allUsersScrollController.dispose();

    super.dispose();
  }

  // NotificationsListener
  @override
  void onNotification(String name, dynamic param) {
    if (name == Social.notifyConversationsUpdated) {
      if (mounted) {
        setState(() {
          _selectedAccountIds.clear();
        });
      }
    }
    else if (name == Social.notifyMessageSent) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: RootHeaderBar(title: Localization().getStringEx("panel.messages.directory.header.title", "Send To"), leading: RootHeaderBarLeading.Back,),
      body: _buildContent(),
      backgroundColor: Styles().colors.background,
      bottomNavigationBar: uiuc.TabBar(),
    );
  }

  Widget _buildContent() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          Localization().getStringEx('panel.messages.directory.header.message', 'Who do you want to send to?'),
          style: Styles().textStyles.getTextStyle('widget.title.large.fat')
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: _searchBarWidget,
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: TabBar(
          tabs: tabs,
          controller: _tabController,
          isScrollable: false,
          indicatorColor: Styles().colors.fillColorSecondary,
          indicatorSize: TabBarIndicatorSize.tab,
          onTap: (index) {
            _onTabChanged();
          }
        ),
      ),
      Expanded(
        child: TabBarView(
          controller: _tabController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildContinueButtonOverlay(_recentContent, scrollController: _recentScrollController),
            _buildContinueButtonOverlay(_allUsersContent, scrollController: _allUsersScrollController),
          ],
        ),
      ),
    ],);
  }

  List<Widget> get tabs {
    List<Widget> tabs = <Widget>[];
    for (int index = 0; index < _tabNames.length; index++) {
      tabs.add(Tab(child:
        Text(_tabNames[index], style: (_selectedTab == index) ?
          Styles().textStyles.getTextStyle('widget.title.regular.fat') :
          Styles().textStyles.getTextStyle('widget.title.regular.medium_fat')
        )
      ));
    }
    return tabs;
  }


  Widget _buildContinueButtonOverlay(Widget content, { ScrollController? scrollController }) {
    return RefreshIndicator(onRefresh: _onRefresh, child:
      Stack(
          children: [
            SingleChildScrollView(controller: scrollController, physics: AlwaysScrollableScrollPhysics(), child:
              Padding(
                padding: EdgeInsets.only(left: 16, right: 16, top: 24, bottom: _hasSelectedAccounts ? 64 : 24,),
                child: content,
              )
            ),
            if (_hasSelectedAccounts)
              Column(
                children: [
                  Expanded(child: Container()),
                  Padding(
                      padding: EdgeInsets.all(16),
                      child: RoundedButton(
                          label: Localization().getStringEx('panel.messages.directory.button.continue.label', 'Continue'),
                          textStyle: Styles().textStyles.getTextStyle("widget.button.title.medium.fat.variant2"),
                          backgroundColor: Styles().colors.fillColorSecondary,
                          borderColor: Styles().colors.fillColorSecondary,
                          onTap: _onTapCreateConversation
                      )
                  ),
                ],
              ),
          ]
      )
    );
  }

  Widget get _recentContent =>
    RecentConversationsPage(
      key: _recentPageKey,
      searchText: _searchText,
      recentConversations: _recentConversations,
      conversationPageSize: widget.conversationPageSize,
      scrollController: _recentScrollController,
      onConversationSelectionChanged: _onConversationSelectionChanged,
      selectedAccountIds: _selectedAccountIds,
    );

  Widget get _allUsersContent =>
    DirectoryAccountsList(DirectoryAccounts.directory,
      key: _allUsersPageKey,
      displayMode: DirectoryDisplayMode.select,
      scrollController: _allUsersScrollController,
      searchText: _searchText,
      filterAttributes: _filterAttributes,
      onAccountSelectionChanged: _onAccountSelectionChanged,
      selectedAccountIds: _selectedAccountIds,
    );

  // Search & Filters

  Widget get _searchBarWidget =>
    DirectoryFilterBar(
      key: ValueKey(DirectoryFilter(searchText: _searchText, attributes: _filterAttributes)),
      searchText: _searchText,
      onSearchText: _onSearchText,
      filterAttributes: (_selectedTab != 0) ? _filterAttributes : null,
      onFilterAttributes: _onFilterAttributes,
    );

  void _onSearchText(String text) {
    setStateIfMounted((){
      _searchText = text;
      _recentConversations = null;
      _recentPageKey = GlobalKey();
      _allUsersPageKey = GlobalKey();
    });
  }

  void _onFilterAttributes(Map<String, dynamic> filterAttributes) {
    setStateIfMounted((){
      _filterAttributes = filterAttributes;
      _allUsersPageKey = GlobalKey();
    });
  }

  // Event Handlers

  Future<void> _onTapCreateConversation() async {
    // do not need to check for existing conversation with selected members because Social BB handles it
    if (_hasSelectedAccounts) {
      Conversation? conversation = await Social().createConversation(memberIds: _selectedAccountIds.toList());
      if (mounted) {
        if (conversation != null) {
          clearSelectedIds();
          Navigator.push(context, CupertinoPageRoute(builder: (context) => MessagesConversationPanel(conversation: conversation,)));
        } else {
          AppAlert.showDialogResult(context, Localization().getStringEx('panel.messages.directory.button.continue.failed.msg', 'Failed to create a conversation with the selected members.'));
        }
      }
    }
  }

  void _onTabChanged({bool manual = true}) {
    if (!_tabController.indexIsChanging && _selectedTab != _tabController.index) {
      setState(() {
        _selectedTab = _tabController.index;
      });
    }
  }

  void _onAccountSelectionChanged(Auth2PublicAccount account, bool value) {
    if (account.id?.isNotEmpty ?? false) {
      setStateIfMounted(() {
        if (value) {
          _selectedAccountIds.add(account.id!);
        } else {
          _selectedAccountIds.remove(account.id);
        }
      });
    }
  }

  void _onConversationSelectionChanged(bool value, Conversation conversation) {
    setStateIfMounted(() {
      if (value) {
        _selectedAccountIds.addAll(conversation.memberIds ?? []);
      } else {
        _selectedAccountIds.removeAll(conversation.memberIds ?? []);
      }
    });
  }

  void clearSelectedIds() {
    setStateIfMounted(() {
      _selectedAccountIds.clear();
    });
  }

  Future<void> _onRefresh() async => (_selectedTab == 0) ?
    _recentPageKey.currentState?.refresh() : _allUsersPageKey.currentState?.refresh();

  bool get _hasSelectedAccounts => _selectedAccountIds.isNotEmpty;

}

enum MessagesDirectoryContentType { recent, all }