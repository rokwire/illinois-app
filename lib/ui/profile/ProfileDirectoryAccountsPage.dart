
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart' as illinois;
import 'package:illinois/ui/attributes/ContentAttributesPanel.dart';
import 'package:illinois/ui/profile/ProfileDirectoryPage.dart';
import 'package:illinois/ui/profile/ProfileDirectoryWidgets.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/auth2.directory.dart';
import 'package:rokwire_plugin/model/content_attributes.dart';
import 'package:rokwire_plugin/model/group.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/auth2.directory.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class ProfileDirectoryAccountsPage extends StatefulWidget {
  static const String notifyEditInfo  = "edu.illinois.rokwire.profile.directory.accounts.edit";

  final DirectoryAccounts contentType;
  final ScrollController? scrollController;
  ProfileDirectoryAccountsPage({super.key, required this.contentType, this.scrollController});

  @override
  State<StatefulWidget> createState() => _ProfileDirectoryAccountsPageState();
}

class _ProfileDirectoryAccountsPageState extends State<ProfileDirectoryAccountsPage> implements NotificationsListener  {

  List<Auth2PublicAccount>? _accounts;
  String _searchText = '';
  bool _loading = false;
  bool _loadingProgress = false;
  bool _extending = false;
  bool _canExtend = false;
  static const int _pageLength = 32;

  String? _expandedAccountId;

  String _directoryPhotoImageToken = DirectoryProfilePhotoUtils.newToken;
  String _userPhotoImageToken = DirectoryProfilePhotoUtils.newToken;

  final TextEditingController _searchTextController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  Map<String, dynamic> _filters = <String, dynamic>{};

  @override
  void initState() {
    NotificationService().subscribe(this, [
      illinois.Auth2.notifyProfilePictureChanged,
      Auth2.notifyProfileChanged,
      Auth2.notifyPrivacyChanged,
    ]);
    widget.scrollController?.addListener(_scrollListener);
    _load();
    super.initState();
  }


  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    widget.scrollController?.removeListener(_scrollListener);
    _searchTextController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  void onNotification(String name, dynamic param) {
    if (name == illinois.Auth2.notifyProfilePictureChanged) {
      if (mounted) {
        setState((){
          _userPhotoImageToken = DirectoryProfilePhotoUtils.newToken;
        });
      }
    }
    else if ((name == Auth2.notifyProfileChanged) || (name == Auth2.notifyPrivacyChanged)) {
      if (mounted) {
        setState((){
          _userPhotoImageToken = DirectoryProfilePhotoUtils.newToken;
        });
        _refresh();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> contentList = <Widget>[
      _editDescription,
      _searchBarWidget,
    ];
    if (_loadingProgress) {
      contentList.add(_loadingContent);
    }
    else if (_accounts == null) {
      contentList.add(_messageContent(_failedText));
    }
    else if (_accounts?.isEmpty == true) {
      contentList.add(_messageContent(_emptyText));
    }
    else {
      contentList.add(_accountsContent);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: contentList);
  }

  Widget get _accountsContent {
    List<Widget> contentList = <Widget>[];

    List<Auth2PublicAccount>? accounts = _accounts;
    if ((accounts != null) && accounts.isNotEmpty) {
      String? directoryIndex;
      for (Auth2PublicAccount account in accounts) {
        String? accountDirectoryIndex = account.directoryKey;
        if ((accountDirectoryIndex != null) && (directoryIndex != accountDirectoryIndex)) {
          if (contentList.isNotEmpty) {
            contentList.add(Padding(padding: EdgeInsets.only(bottom: 16), child: _sectionSplitter));
          }
          contentList.add(_sectionHeading(directoryIndex = accountDirectoryIndex));
        }
        contentList.add(_sectionSplitter);
        contentList.add(DirectoryAccountCard(account,
          photoImageToken: (account.id == Auth2().accountId) ? _userPhotoImageToken : _directoryPhotoImageToken,
          expanded: (_expandedAccountId != null) && (account.id == _expandedAccountId),
          onToggleExpanded: () => _onToggleAccountExpanded(account),
        ));
      }
      if (contentList.isNotEmpty) {
        contentList.add(Padding(padding: EdgeInsets.only(bottom: 16), child: _sectionSplitter));
      }
    }

    if (_extending) {
      contentList.add(_extendingIndicator);
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: contentList);
  }

  void _onToggleAccountExpanded(Auth2PublicAccount profile) {
    Analytics().logSelect(target: 'Expand', source: profile.id);
    setState(() {
      _expandedAccountId = (_expandedAccountId != profile.id) ? profile.id : null;
    });
  }

  Widget _sectionHeading(String dirEntry) =>
    Padding(padding: EdgeInsets.zero, child:
      Text(dirEntry, style: Styles().textStyles.getTextStyle('widget.title.small.semi_fat'),)
    );

  static const String _linkEditMacro = "{{link.edit.info}}";

  Widget get _editDescription {
    List<String> messages = _editDescriptionTemplate.split(_linkEditMacro);
    List<InlineSpan> spanList = <InlineSpan>[];
    if (0 < messages.length)
      spanList.add(TextSpan(text: messages.first));
    for (int index = 1; index < messages.length; index++) {
      spanList.add(TextSpan(
        text: Localization().getStringEx('panel.profile.directory.accounts.command.edit.info.text', 'Edit your information'),
        style : Styles().textStyles.getTextStyleEx("widget.detail.small.fat.underline", color: Styles().colors.fillColorSecondary),
        recognizer: TapGestureRecognizer()..onTap = _onTapEditInfo, )
      );
      spanList.add(TextSpan(text: messages[index]));
    }

    return Padding(padding: EdgeInsets.only(bottom: 16), child:
      RichText(textAlign: TextAlign.left, text:
        TextSpan(style: Styles().textStyles.getTextStyle("widget.detail.small"), children: spanList)
      )
    );
  }

  String get _editDescriptionTemplate {
    switch(widget.contentType) {
      case DirectoryAccounts.myConnections: return AppTextUtils.appTitleString('panel.profile.directory.accounts.connections.edit.info.description', '$_linkEditMacro that shows up in the ${AppTextUtils.appTitleMacro} Connections.');
      case DirectoryAccounts.appDirectory: return AppTextUtils.appTitleString('panel.profile.directory.accounts.directory.edit.info.description', '$_linkEditMacro that shows up in the ${AppTextUtils.appTitleMacro} App Directory.');
    }
  }

  void _onTapEditInfo() {
    Analytics().logSelect(target: 'Edit Info');
    NotificationService().notify(ProfileDirectoryAccountsPage.notifyEditInfo, widget.contentType.profileInfo);
  }

  Widget get _searchBarWidget =>
    Padding(padding: const EdgeInsets.only(bottom: 16), child:
      Row(children: [
        Expanded(child:
          Container(decoration: _searchBarDecoration, padding: EdgeInsets.only(left: 16), child:
            Row(children: <Widget>[
              Expanded(child:
                _searchTextWidget
              ),
              _searchImageButton('close',
                label: Localization().getStringEx('panel.search.button.clear.title', 'Clear'),
                hint: Localization().getStringEx('panel.search.button.clear.hint', ''),
                rightPadding: _searchImageButtonHorzPadding / 2,
                onTap: _onTapClear,
              ),
              _searchImageButton('search',
                label: Localization().getStringEx('panel.search.button.search.title', 'Search'),
                hint: Localization().getStringEx('panel.search.button.search.hint', ''),
                leftPadding: _searchImageButtonHorzPadding / 2,
                onTap: _onTapSearch,
              ),
            ],)
          )
        ),
        Padding(padding: EdgeInsets.only(left: 6), child:
          _filtersButton
        ),
      ],),
    );

    Widget get _searchTextWidget =>
      Semantics(
        label: Localization().getStringEx('panel.profile.directory.accounts.search.field.label', 'SEARCH FIELD'),
        hint: null,
        textField: true,
        excludeSemantics: true,
        value: _searchTextController.text,
        child: TextField(
          controller: _searchTextController,
          focusNode: _searchFocusNode,
          decoration: InputDecoration(border: InputBorder.none,),
          style: Styles().textStyles.getTextStyle('widget.input_field.dark.text.regular.thin'),
          cursorColor: Styles().colors.fillColorSecondary,
          keyboardType: TextInputType.text,
          autocorrect: false,
          autofocus: false,
          maxLines: 1,
          onSubmitted: (_) => _onTapSearch(),
      )
    );

  Decoration get _searchBarDecoration => BoxDecoration(
    color: Styles().colors.white,
    border: Border.all(color: Styles().colors.disabledTextColor, width: 1),
    borderRadius: BorderRadius.circular(12),
  );

  Widget _searchImageButton(String image, { String? label, String? hint, double leftPadding = _searchImageButtonHorzPadding, double rightPadding = _searchImageButtonHorzPadding, void Function()? onTap }) =>
    Semantics(label: label, hint: hint, button: true, excludeSemantics: true, child:
      InkWell(onTap: onTap, child:
        Padding(padding: EdgeInsets.only(left: leftPadding, right: rightPadding, top: _searchImageButtonVertPadding, bottom: _searchImageButtonVertPadding), child:
          Styles().images.getImage(image, excludeFromSemantics: true),
        ),
      ),
    );

  static const double _searchImageButtonHorzPadding = 16;
  static const double _searchImageButtonVertPadding = 12;

  Widget get _filtersButton =>
    InkWell(onTap: _onFilter, child:
      Container(decoration: _searchBarDecoration, padding: EdgeInsets.symmetric(vertical: 14, horizontal: 14), child:
        Styles().images.getImage('filters') ?? SizedBox(width: 18, height: 18,),
      ),
    );

  void _onFilter() {
    Analytics().logSelect(target: 'Filters');
    ContentAttributes? directoryAttributes = _directoryAttributes;
    if (directoryAttributes != null) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => ContentAttributesPanel(
        title: Localization().getStringEx('panel.profile.directory.accounts.filters.header.title', 'App Directory Filters'),
        description: AppTextUtils.appTitleString('panel.profile.directory.accounts.filters.header.description', 'Choose at leasrt one attribute to filter the ${AppTextUtils.appTitleMacro} App Directory.'),
        scope: Auh2Directory.attributesScope,
        contentAttributes: directoryAttributes,
        selection: _filters,
        sortType: ContentAttributesSortType.alphabetical,
        filtersMode: true,
      ))).then((selection) {
        if ((selection != null) && mounted) {
          setState(() {
            _filters = selection;
          });
          _load();
        }
      });
    }
  }

  ContentAttributes? get _directoryAttributes {
    ContentAttributes? directoryAttributes = Auth2().directoryAttributes;
    if (directoryAttributes != null) {
      ContentAttribute? groupsAttribute = _groupsAttribute;
      if (groupsAttribute != null) {
        directoryAttributes = ContentAttributes.fromOther(directoryAttributes);
        directoryAttributes?.attributes?.add(groupsAttribute);
      }
      return directoryAttributes;
    }
    else {
      return null;
    }
  }

  static const String _groupsAttributeId = 'groups';

  ContentAttribute? get _groupsAttribute {
    List<Group>? userGroups = Groups().userGroups;
    return ((userGroups != null) && userGroups.isNotEmpty) ?
      ContentAttribute(
        id: _groupsAttributeId,
        title: Localization().getStringEx('panel.profile.directory.accounts.attributes.event_type.hint.empty', 'My Groups'),
        emptyHint: Localization().getStringEx('panel.profile.directory.accounts.attributes.event_type.hint.empty', 'Select groups'),
        semanticsHint: Localization().getStringEx('panel.profile.directory.accounts.home.attributes.event_type.hint.semantics', 'Double type to show groups.'),
        widget: ContentAttributeWidget.dropdown,
        scope: <String>{ Auh2Directory.attributesScope },
        requirements: null,
        values: List.from(userGroups.map<ContentAttributeValue>((Group group) => ContentAttributeValue(
          label: group.title,
          value: group.id,
        )))
      ) : null;
  }



  Widget get _sectionSplitter => Container(height: 1, color: Styles().colors.dividerLineAccent,);

  Widget get _extendingIndicator => Container(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8), child:
    Align(alignment: Alignment.center, child:
      SizedBox(width: 24, height: 24, child:
        DirectoryProgressWidget()
      ),
    ),
  );


  Widget get _loadingContent => Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 64,), child:
    Center(child:
      SizedBox(width: 32, height: 32, child:
        CircularProgressIndicator(color: Styles().colors.fillColorSecondary, strokeWidth: 3,)
      )
    )
  );

  Widget _messageContent(String message) => Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 64,), child:
    Center(child:
      Text(message, style: Styles().textStyles.getTextStyle("widget.message.dark.regular"), textAlign: TextAlign.center,)
    )
  );

  String get _emptyText {
    switch (widget.contentType) {
      case DirectoryAccounts.myConnections: return AppTextUtils.appTitleString('panel.profile.directory.accounts.connections.empty.text', 'You do not have any ${AppTextUtils.appTitleMacro} Connections. Your connections will appear after you swap info with another ${AppTextUtils.universityLongNameMacro} student or employee.').replaceAll(AppTextUtils.universityLongNameMacro, AppTextUtils.universityLongName);
      case DirectoryAccounts.appDirectory: return AppTextUtils.appTitleString('panel.profile.directory.accounts.directory.empty.text', 'The ${AppTextUtils.appTitleMacro} App Directory is empty.');
    }
  }

  String get _failedText {
    switch (widget.contentType) {
      case DirectoryAccounts.myConnections: return AppTextUtils.appTitleString('panel.profile.directory.accounts.connections.failed.text', 'Failed to load ${AppTextUtils.appTitleMacro} Connections content.');
      case DirectoryAccounts.appDirectory: return AppTextUtils.appTitleString('panel.profile.directory.accounts.directory.failed.text', 'Failed to load ${AppTextUtils.appTitleMacro} App Directory content.');
    }
  }

  void _scrollListener() {
    ScrollController? scrollController = widget.scrollController;
    if ((scrollController != null) && (scrollController.offset >= scrollController.position.maxScrollExtent) && _canExtend && !_loading && !_extending) {
      _extend();
    }
  }

  Future<void> _load({ int limit = _pageLength, bool silent = false }) async {
    if (!_loading) {
      setStateIfMounted(() {
        _loading = true;
        _loadingProgress = !silent;
        _extending = false;
      });

      List<Auth2PublicAccount>? accounts = await Auth2().loadDirectoryAccounts(
        search: StringUtils.ensureEmpty(_searchText),
        limit: limit
      );

      setStateIfMounted(() {
        _loading = false;
        _loadingProgress = false;
        if (accounts != null) {
          _accounts = List.from(accounts);
          _canExtend = (accounts.length >= limit);
        }
        else if (!silent) {
          _accounts = null;
          _canExtend = false;
        }
      });
    }
  }

  Future<void> _refresh() =>
    _load(limit: max(_accountsCount, _pageLength), silent: true);

  Future<void> _extend() async {
    if (!_loading && !_extending) {
      setStateIfMounted(() {
        _extending = true;
      });

      List<Auth2PublicAccount>? accounts = await Auth2().loadDirectoryAccounts(
        search: StringUtils.ensureEmpty(_searchText),
        offset: _accountsCount,
        limit: _pageLength
      );

      if (mounted && _extending && !_loading) {
        setState(() {
          if (accounts != null) {
            if (_accounts != null) {
              _accounts?.addAll(accounts);
            }
            else {
              _accounts = List.from(accounts);
            }

            _canExtend = (accounts.length >= _pageLength);
          }
          _extending = false;
        });
      }
    }
  }

  int get _accountsCount => _accounts?.length ?? 0;

  void _onTapClear() {
    Analytics().logSelect(target: 'Search Clear');
    if (_searchText.isNotEmpty) {
      setState(() {
        _searchTextController.text = _searchText = '';
      });
      _searchFocusNode.unfocus();
      _load();
    }

  }

  void _onTapSearch() {
    Analytics().logSelect(target: 'Search Text');
    if (_searchText != _searchTextController.text) {
      setState(() {
        _searchText = _searchTextController.text;
      });
      _searchFocusNode.unfocus();
      _load();
    }
  }

}

extension _Auth2PublicAccountUtils on Auth2PublicAccount {
  String? get directoryKey => (profile?.lastName?.isNotEmpty == true) ?
    profile?.lastName?.substring(0, 1).toUpperCase() : null;
}