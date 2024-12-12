import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/ui/messages/MessagesConversationPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/ribbon_button.dart';

class MessagesDirectoryPanel extends StatefulWidget {
  final bool? unread;
  final void Function()? onTapBanner;
  MessagesDirectoryPanel({Key? key, this.unread, this.onTapBanner}) : super(key: key);

  _MessagesDirectoryPanelState createState() => _MessagesDirectoryPanelState();
}

class _MessagesDirectoryPanelState extends State<MessagesDirectoryPanel> with TickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTab = 0;

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
            // MessagesInboxPage(),
            // MessagesInboxPage(unread: true),
          ],
        ),
      ),
    ],);
  }

  // Widget get _scaffoldContent => RefreshIndicator(onRefresh: _onRefresh, child:
  //   SingleChildScrollView(controller: _scrollController, physics: AlwaysScrollableScrollPhysics(), child:
  //     Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24), child:
  //       ProfileDirectoryAccountsPage(widget.contentType, key: _pageKey, scrollController: _scrollController, onEditProfile: _onEditProfile,),
  //     )
  //   )
  // );

  void _onTabChanged({bool manual = true}) {
    if (!_tabController.indexIsChanging && _selectedTab != _tabController.index) {
      setState(() {
        _selectedTab = _tabController.index;
      });
    }
  }
}

enum MessagesDirectoryContentType { recent, all }