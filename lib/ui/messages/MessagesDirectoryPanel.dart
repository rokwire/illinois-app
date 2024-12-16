import 'package:flutter/material.dart';
import 'package:illinois/ui/profile/ProfileDirectoryAccountsPage.dart';
import 'package:illinois/ui/profile/ProfileDirectoryPage.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/model/auth2.directory.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class MessagesDirectoryPanel extends StatefulWidget {
  final bool? unread;
  final void Function()? onTapBanner;
  MessagesDirectoryPanel({Key? key, this.unread, this.onTapBanner}) : super(key: key);

  _MessagesDirectoryPanelState createState() => _MessagesDirectoryPanelState();
}

class _MessagesDirectoryPanelState extends State<MessagesDirectoryPanel> with TickerProviderStateMixin {
  final GlobalKey<ProfileDirectoryAccountsPageState> _pageKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();
  late TabController _tabController;
  int _selectedTab = 0;
  Map<String, bool> _selectedAccountIds = {};

  final List<String> _tabNames = [
    Localization().getStringEx('panel.messages.new.tab.recent.label', 'Recent'),
    Localization().getStringEx('panel.messages.new.tab.all.label', 'All Users'),
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
    _scrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: RootHeaderBar(title: Localization().getStringEx("panel.messages.new.header.title", "Send To"), leading: RootHeaderBarLeading.Back,),
      body: _buildContent(),
      backgroundColor: Styles().colors.background,
      bottomNavigationBar: uiuc.TabBar(),
    );
  }

  Widget _buildContent() {
    List<Widget> tabs = _tabNames.map((e) => Tab(text: e)).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TabBar(tabs: tabs, controller: _tabController, isScrollable: false, onTap: (index){_onTabChanged();}),
      Expanded(
        child: TabBarView(
          controller: _tabController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            Container(),  //TODO
            _allUsersContent,
          ],
        ),
      ),
    ],);
  }

  Widget get _allUsersContent => RefreshIndicator(onRefresh: _onRefresh, child:
    Stack(
      children: [
        SingleChildScrollView(controller: _scrollController, physics: AlwaysScrollableScrollPhysics(), child:
          Padding(padding: EdgeInsets.only(left: 16, right: 16, top: 24, bottom: _isAccountSelected ? 64 : 24,), child:
            ProfileDirectoryAccountsPage(DirectoryAccounts.appDirectory, key: _pageKey, scrollController: _scrollController, selectedAccountIds: _selectedAccountIds, onToggleAccountSelection: _onToggleAccountSelected,),
          )
        ),
        if (_isAccountSelected)
          Column(
            children: [
              Expanded(child: Container()),
              Padding(
                padding: EdgeInsets.all(16),
                child: RoundedButton(
                    label: Localization().getStringEx('panel.messages.new.button.continue.label', 'Continue'),
                    textStyle: Styles().textStyles.getTextStyle("widget.button.title.medium.fat.variant2"),
                    backgroundColor: Styles().colors.fillColorPrimary,
                    // onTap: () => _saveProgress(false), //TODO
                )
              ),
            ],
          ),
      ]
    )
  );

  void _onTabChanged({bool manual = true}) {
    if (!_tabController.indexIsChanging && _selectedTab != _tabController.index) {
      setState(() {
        _selectedTab = _tabController.index;
      });
    }
  }

  void _onToggleAccountSelected(bool value, Auth2PublicAccount account) {
    setState(() {
      if (StringUtils.isNotEmpty(account.id)) {
        _selectedAccountIds[account.id!] = value;
      }
    });
  }

  Future<void> _onRefresh() async => _pageKey.currentState?.refresh();

  bool get _isAccountSelected => _selectedAccountIds.containsValue(true);
}

enum MessagesDirectoryContentType { recent, all }