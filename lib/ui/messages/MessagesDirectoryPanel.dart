import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/ui/messages/MessagesConversationPanel.dart';
import 'package:illinois/ui/messages/MessagesWidgets.dart';
import 'package:illinois/ui/profile/ProfileDirectoryAccountsPage.dart';
import 'package:illinois/ui/profile/ProfileDirectoryPage.dart';
import 'package:illinois/ui/profile/ProfileDirectoryWidgets.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/social.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/social.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';

class MessagesDirectoryPanel extends StatefulWidget {
  final List<Conversation> recentConversations;
  final int conversationPageSize;
  final bool? unread;
  final void Function()? onTapBanner;
  MessagesDirectoryPanel({Key? key, required this.recentConversations, required this.conversationPageSize, this.unread, this.onTapBanner}) :
    super(key: key);

  _MessagesDirectoryPanelState createState() => _MessagesDirectoryPanelState();
}

class _MessagesDirectoryPanelState extends State<MessagesDirectoryPanel> with TickerProviderStateMixin {
  final GlobalKey<RecentConversationsPageState> _recentPageKey = GlobalKey();
  final GlobalKey<ProfileDirectoryAccountsPageState> _allUsersPageKey = GlobalKey();
  final GlobalKey<ConversationSearchBarState> _searchBarKey = GlobalKey();
  final ScrollController _recentScrollController = ScrollController();
  final ConversationsSearchController _searchController = ConversationsSearchController();
  final ScrollController _allUsersScrollController = ScrollController();
  late TabController _tabController;
  int _selectedTab = 0;

  final List<String> _tabNames = [
    Localization().getStringEx('panel.messages.directory.tab.recent.label', 'Recent'),
    Localization().getStringEx('panel.messages.directory.tab.all.label', 'All Users'),
  ];

  @override
  void initState() {
    _tabController = TabController(length: _tabNames.length, initialIndex: _selectedTab, vsync: this);
    _tabController.addListener(_onTabChanged);

    super.initState();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _recentScrollController.dispose();
    _allUsersScrollController.dispose();

    super.dispose();
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
        child: ConversationsSearchBar(key: _searchBarKey, searchController: _searchController, showFilters: _selectedTab != 0,),
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
                          backgroundColor: Styles().colors.fillColorPrimary,
                          borderColor: Styles().colors.fillColorPrimary,
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
      searchController: _searchController,
      initialSearch: searchText,
      recentConversations: widget.recentConversations,
      conversationPageSize: widget.conversationPageSize,
      scrollController: _recentScrollController,
      onSelectedConversationChanged: _onSelectedConversationChanged,
    );

  Widget get _allUsersContent =>
    ProfileDirectoryAccountsPage(DirectoryAccounts.userDirectory,
      displayMode: DirectoryDisplayMode.select,
      key: _allUsersPageKey,
      scrollController: _allUsersScrollController,
      searchController: _searchController,
      initialSearch: searchText,
      onSelectedAccountsChanged: _onSelectedAccountsChanged,
    );

  Future<void> _onTapCreateConversation() async {
    // do not need to check for existing conversation with selected members because Social BB handles it
    Set<String>? memberIds = (_selectedTab == 0) ?
      _recentPageKey.currentState?.selectedAccountIds :
      _allUsersPageKey.currentState?.selectedAccountIds;

    if ((memberIds != null) && memberIds.isNotEmpty) {
      Conversation? conversation = await Social().createConversation(memberIds: memberIds.toList());
      if (mounted) {
        if (conversation != null) {
          if (_selectedTab == 0) {
            _allUsersPageKey.currentState?.clearSelectedIds();
          }
          else {
            _recentPageKey.currentState?.clearSelectedIds();
          }
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

      if (_tabController.index == 0) {
        _recentPageKey.currentState?.onConversationsTabChanged(searchText, filterAttributes);
      } else {
        _allUsersPageKey.currentState?.onConversationsTabChanged(searchText, filterAttributes);
      }
    }
  }

  void _onSelectedAccountsChanged() {
    setStateIfMounted(() {});
  }

  void _onSelectedConversationChanged() {
    setStateIfMounted(() {});
  }

  Future<void> _onRefresh() async => (_selectedTab == 0) ?
    _recentPageKey.currentState?.refresh() : _allUsersPageKey.currentState?.refresh();

  bool get _hasSelectedAccounts => (_selectedTab == 0) ?
    (_recentPageKey.currentState?.selectedConversationIds.isNotEmpty == true) :
    (_allUsersPageKey.currentState?.selectedAccountIds.isNotEmpty == true);

  String get searchText => _searchBarKey.currentState?.searchText ?? '';
  Map<String, dynamic> get filterAttributes => _searchBarKey.currentState?.filterAttributes ?? {};
}

enum MessagesDirectoryContentType { recent, all }