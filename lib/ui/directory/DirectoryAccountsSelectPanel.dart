
import 'dart:collection';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/directory/DirectoryAccountsList.dart';
import 'package:illinois/ui/directory/DirectoryWidgets.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/PopScopeFix.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/auth2.directory.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';

class DirectoryAccountsSelectPanel extends StatefulWidget {
  final LinkedHashSet<Auth2PublicAccount>? selectedAccounts;
  final String? headerBarTitle;
  final String? headingDescription;

  DirectoryAccountsSelectPanel({super.key, this.selectedAccounts,
    this.headerBarTitle, this.headingDescription
  });

  @override
  State<StatefulWidget> createState() => _DirectoryAccountsSelectPanelState();
}

class _DirectoryAccountsSelectPanelState extends State<DirectoryAccountsSelectPanel> {

  GlobalKey<DirectoryAccountsListState> _usersListKey = GlobalKey<DirectoryAccountsListState>();
  final ScrollController _usersListScrollController = ScrollController();
  final LinkedHashMap<String, Auth2PublicAccount> _selectedAccouts = LinkedHashMap<String, Auth2PublicAccount>();
  final Set<String> _initialAccountsSelection = <String>{};

  String _searchText = '';
  Map<String, dynamic> _filterAttributes = <String, dynamic>{};

  @override
  void initState() {

    if (widget.selectedAccounts?.isNotEmpty == true) {
      widget.selectedAccounts?.forEach((Auth2PublicAccount account) {
        String? accountId = account.id;
        if (accountId != null) {
          _selectedAccouts[accountId] = account;
          _initialAccountsSelection.add(accountId);
        }
      });
    }

    super.initState();
  }

  @override
  void dispose() {
    _usersListScrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
    PopScopeFix(onBack: _onSwipeBack, child:
      Scaffold(
        appBar: HeaderBar(
          title: widget.headerBarTitle ?? Localization().getStringEx("panel.directory.accounts.select.header.title", "Directory Users"),
          onLeading: _onTapHeaderBack,
          actions: _headerBarActions,
        ),
        backgroundColor: Styles().colors.background,
        body: _scaffoldContent,
      ),
    );

  Widget get _scaffoldContent => Padding(padding: EdgeInsets.all(16), child:
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (widget.headingDescription?.isNotEmpty == true)
        Padding(padding: EdgeInsets.only(bottom: 8), child:
          Text(widget.headingDescription ?? '', style: Styles().textStyles.getTextStyle('widget.description.regular'),),
        ),
      _searchBarWidget,
      Expanded(child:
        _usersScrollWidget
      ),
    ])
  );

  // Directory List

  Widget get _usersScrollWidget => RefreshIndicator(onRefresh: _onRefresh, child:
    SingleChildScrollView(controller: _usersListScrollController, physics: AlwaysScrollableScrollPhysics(), child:
      Padding(padding: EdgeInsets.symmetric(vertical: 24), child:
        _usersListWidget
      )
    ),
  );

  Widget get _usersListWidget =>
    DirectoryAccountsList(DirectoryAccounts.directory,
      key: _usersListKey,
      displayMode: DirectoryDisplayMode.select,
      scrollController: _usersListScrollController,
      searchText: _searchText,
      filterAttributes: _filterAttributes,
      onAccountSelectionChanged: _onAccountSelectionChanged,
      selectedAccountIds: Set<String>.from(_selectedAccouts.keys),
    );

  void _onAccountSelectionChanged(Auth2PublicAccount account, bool value) {
    String? accountId = account.id;
    if ((accountId != null) && accountId.isNotEmpty) {
      setStateIfMounted(() {
        if (value) {
          _selectedAccouts[accountId] = account;
        } else {
          _selectedAccouts.remove(accountId);
        }
      });
    }
  }

  Future<void> _onRefresh() async => _usersListKey.currentState?.refresh();

  // Search & Filters

  Widget get _searchBarWidget =>
    DirectoryFilterBar(
      key: ValueKey(DirectoryFilter(searchText: _searchText, attributes: _filterAttributes)),
      searchText: _searchText,
      onSearchText: _onSearchText,
      filterAttributes: _filterAttributes,
      onFilterAttributes: _onFilterAttributes,
    );

  void _onSearchText(String text) {
    setStateIfMounted((){
      _searchText = text;
      _usersListKey = GlobalKey<DirectoryAccountsListState>();
    });
  }

  void _onFilterAttributes(Map<String, dynamic> filterAttributes) {
    setStateIfMounted((){
      _filterAttributes = filterAttributes;
      _usersListKey = GlobalKey<DirectoryAccountsListState>();
    });
  }


  bool get _isModified =>
    (DeepCollectionEquality().equals(_selectedAccouts.keys.toSet(), _initialAccountsSelection) != true);

  // Header bar

  List<Widget>? get _headerBarActions => _isModified ? <Widget>[
    HeaderBarActionTextButton(
      title:  Localization().getStringEx('dialog.apply.title', 'Apply'),
      onTap: _onTapApply,
    ),
  ] : null;

  void _onTapApply() {
    Analytics().logSelect(target: 'HeaderBar: Apply');
    _popAndApply();
  }

  void _onTapHeaderBack() {
    Analytics().logSelect(target: 'HeaderBar: Back');
    _onHeaderBack();
  }

  void _onSwipeBack() {
    Analytics().logSelect(target: 'Swipte Right: Back');
    _onHeaderBack();
  }

  void _onHeaderBack() {
    Analytics().logSelect(target: 'Back');
    if (_isModified) {
      showDialog<bool?>(context: context, builder: (BuildContext context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0),),
        content: Text(_headerBackApplyPromptText(), textAlign: TextAlign.center, style: Styles().textStyles.getTextStyle('widget.message.regular.fat'),),
        actions: [
          _headerBackPromptButton(context, promptBuilder: _headerBackApplyPromptText, textBuilder: _headerBackPromptYesText, value: true),
          _headerBackPromptButton(context, promptBuilder: _headerBackApplyPromptText, textBuilder: _headerBackPromptNoText, value: false),
          _headerBackPromptButton(context, promptBuilder: _headerBackApplyPromptText, textBuilder: _headerBackPromptCancelText, value: null),
        ],
      )).then((bool? result) {
        if (mounted) {
          if (result == true) {
            _popAndApply();
          }
          else if (result == false) {
            _popAndSkip();
          }
        }
      });
    }
    else {
      _popAndSkip();
    }
  }

  Widget _headerBackPromptButton(BuildContext context, {String Function({String? language})? promptBuilder, String Function({String? language})? textBuilder, bool? value}) =>
    OutlinedButton(
      style: ButtonStyle(
        shape: WidgetStatePropertyAll<RoundedRectangleBorder>(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0),)),
      ),
      onPressed: () => _onTapHeaderBackPromptButton(context,
        prompt: (promptBuilder != null) ? promptBuilder(language: 'en') : null,
        text: (textBuilder != null) ? textBuilder(language: 'en') : null,
        value: value
      ),
      child: Text((textBuilder != null)  ? textBuilder() : '',
        style: Styles().textStyles.getTextStyle('widget.message.regular.semi_fat'),
      ),
    );

  void _onTapHeaderBackPromptButton(BuildContext context, {String? prompt, String? text, bool? value}) {
    Analytics().logAlert(text: prompt, selection: text);
    Navigator.of(context).pop(value);
  }

  String _headerBackApplyPromptText({String? language}) =>
    Localization().getStringEx('panel.directory.accounts.select.apply.prompt', 'Apply your changes?', language: language);

  String _headerBackPromptYesText({String? language}) => Localization().getStringEx("dialog.yes.title", "Yes", language: language);
  String _headerBackPromptNoText({String? language}) => Localization().getStringEx("dialog.no.title", "No", language: language);
  String _headerBackPromptCancelText({String? language}) => Localization().getStringEx("dialog.cancel.title", "Cancel", language: language);

  void _popAndApply() =>
    Navigator.of(context).pop(LinkedHashSet<Auth2PublicAccount>.from(_selectedAccouts.values));

  void _popAndSkip() =>
    Navigator.of(context).pop(null);
}

