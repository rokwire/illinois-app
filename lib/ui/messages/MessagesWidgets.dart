import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/profile/ProfileDirectoryWidgets.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/social.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/social.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class RecentConversationsPage extends StatefulWidget {
  final ScrollController? scrollController;
  final List<Conversation> recentConversations;
  final int conversationPageSize;
  final void Function()? onSelectedConversationChanged;

  RecentConversationsPage({super.key, required this.recentConversations, required this.conversationPageSize, this.scrollController, this.onSelectedConversationChanged });

  @override
  State<StatefulWidget> createState() => RecentConversationsPageState();
}

class RecentConversationsPageState extends State<RecentConversationsPage> with AutomaticKeepAliveClientMixin {

  List<Conversation>? _conversations;
  late Map<String, Conversation> _conversationsMap;
  String _searchText = '';
  bool _loading = false;
  bool _loadingProgress = false;
  bool _extending = false;
  bool _canExtend = false;

  String? _expandedConversationId;
  final Set<String> _selectedIds = <String>{};

  final TextEditingController _searchTextController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  // Map<String, dynamic> _filterAttributes = <String, dynamic>{};

  @override
  void initState() {
    widget.scrollController?.addListener(_scrollListener);
    _conversations = widget.recentConversations;
    _conversationsMap = _buildConversationsMap(widget.recentConversations);
    _sortConversationsByMemberNames();
    super.initState();
  }


  @override
  void dispose() {
    widget.scrollController?.removeListener(_scrollListener);
    _searchTextController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    List<Widget> contentList = <Widget>[
      _searchBarWidget,
    ];
    if (_loadingProgress) {
      contentList.add(_loadingContent);
    }
    else if (_conversations == null) {
      contentList.add(_messageContent(Localization().getStringEx('panel.messages.directory.conversations.failed.text', 'Failed to load recent conversations.')));
    }
    else if (_conversations?.isEmpty == true) {
      contentList.add(_messageContent(Localization().getStringEx('panel.messages.directory.conversations.empty.text', 'There are no recent conversations.')));
    }
    else {
      contentList.add(_conversationsContent);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: contentList);
  }

  Widget get _conversationsContent {
    List<Widget> contentList = <Widget>[];

    List<Conversation>? conversations = _conversations;
    if ((conversations != null) && conversations.isNotEmpty) {
      for (Conversation conversation in conversations) {
        contentList.add(RecentConversationCard(conversation,
          expanded: (_expandedConversationId != null) && (conversation.id == _expandedConversationId),
          onToggleExpanded: () => _onToggleConversationExpanded(conversation),
          selected: _selectedIds.contains(conversation.id),
          onToggleSelected: (value) => _onToggleConversationSelected(value, conversation),
        ));
      }
    }

    if (_extending) {
      contentList.add(_extendingIndicator);
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: contentList);
  }

  void _onToggleConversationExpanded(Conversation conversation) {
    Analytics().logSelect(target: 'Expand', source: conversation.id);
    setState(() {
      _expandedConversationId = (_expandedConversationId != conversation.id) ? conversation.id : null;
    });
  }

  void _onToggleConversationSelected(bool value, Conversation conversation) {
    Analytics().logSelect(target: 'Select', source: conversation.id);
    if (StringUtils.isNotEmpty(conversation.id) && mounted) {
      setState(() {
        if (value) {
          _selectedIds.add(conversation.id!);
        }
        else {
          _selectedIds.remove(conversation.id);
        }
      });
      widget.onSelectedConversationChanged?.call();
    }
  }

  Set<String> get selectedConversationIds =>
    _selectedIds;

  Set<String> get selectedAccountIds {
    Set<String> selectedIds = <String>{};
    for (String conversationId in _selectedIds) {
      List<String>? memberIds = _conversationsMap[conversationId]?.memberIds;
      if (memberIds != null) {
        selectedIds.addAll(memberIds);
      }
    }
    return selectedIds;
  }

  void clearSelectedIds() {
    setStateIfMounted(() {
      _selectedIds.clear();
    });
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
          label: Localization().getStringEx('panel.messages.directory.conversations.search.field.label', 'SEARCH FIELD'),
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
    //TODO
  }

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

  void _scrollListener() {
    ScrollController? scrollController = widget.scrollController;
    if ((scrollController != null) && (scrollController.offset >= scrollController.position.maxScrollExtent) && _canExtend && !_loading && !_extending) {
      _extend();
    }
  }

  Future<void> _load({ bool silent = false }) async {
    if (!_loading) {
      setStateIfMounted(() {
        _loading = true;
        _loadingProgress = !silent;
        _extending = false;
      });

      //TODO: add time intervals to filter
      List<Conversation>? conversations = await Social().loadConversations(offset: _conversationsCount, limit: widget.conversationPageSize);
      setStateIfMounted(() {
        _loading = false;
        _loadingProgress = false;
        if (conversations != null) {
          _conversations = List.from(conversations);
          _conversationsMap = _buildConversationsMap(conversations);
          _sortConversationsByMemberNames();
          _canExtend = (conversations.length >= widget.conversationPageSize);
        }
        else if (!silent) {
          _conversations = null;
          _conversationsMap.clear();
          _canExtend = false;
        }
      });
    }
  }

  Future<void> refresh() => _load(silent: true);

  Future<void> _extend() async {
    if (!_loading && !_extending) {
      setStateIfMounted(() {
        _extending = true;
      });

      //TODO: add time intervals to filter
      List<Conversation>? conversations = await Social().loadConversations(offset: _conversationsCount, limit: widget.conversationPageSize);
      if (mounted && _extending && !_loading) {
        setState(() {
          if (conversations != null) {
            if (_conversations != null) {
              _conversations?.addAll(conversations);
              _conversationsMap.addAll(_buildConversationsMap(conversations));
            }
            else {
              _conversations = List.from(conversations);
              _conversationsMap = _buildConversationsMap(conversations);
              _sortConversationsByMemberNames();
            }

            _canExtend = (conversations.length >= widget.conversationPageSize);
          }
          _extending = false;
        });
      }
    }
  }

  int get _conversationsCount => _conversations?.length ?? 0;

  static Map<String, Conversation> _buildConversationsMap(List<Conversation>? conversations) {
    Map<String, Conversation> map = <String, Conversation>{};
    if (conversations != null) {
      for (Conversation conversation in conversations) {
        if (StringUtils.isNotEmpty(conversation.id)) {
          map[conversation.id!] = conversation;
        }
      }
    }
    return map;
  }

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

  void _sortConversationsByMemberNames() {
    DateTime now = DateTime.now();
    _conversations?.sort((Conversation conv1, Conversation conv2) {
      DateTime time1 = conv1.lastActivityTimeUtc ?? now;
      DateTime time2 = conv2.lastActivityTimeUtc ?? now;
      return time2.compareTo(time1);  // reverse chronological
    });
  }
}

class RecentConversationCard extends StatefulWidget {
  final Conversation conversation;
  final bool expanded;
  final void Function()? onToggleExpanded;
  final bool selected;
  final void Function(bool)? onToggleSelected;

  RecentConversationCard(this.conversation, { super.key, this.expanded = false, this.onToggleExpanded, this.selected = false, this.onToggleSelected });

  @override
  State<StatefulWidget> createState() => _RecentConversationCardState();
}

class _RecentConversationCardState extends State<RecentConversationCard> {

  @override
  Widget build(BuildContext context) =>
      widget.expanded ? _expandedContent : _collapsedContent;

  Widget get _expandedContent =>
    InkWell(onTap: widget.onToggleExpanded, child:
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _cardSelectionContent(padding: const EdgeInsets.only(top: 12, bottom: 12, right: 8)),
        Expanded(child:
          _expandedMembersContent
        ),
        Padding(padding: EdgeInsets.symmetric(horizontal: 6, vertical: 16), child:
          Styles().images.getImage('chevron2-up',)
        ),
      ],),
      );

  Widget _cardSelectionContent({ EdgeInsetsGeometry padding = EdgeInsets.zero }) =>
    InkWell(onTap: _onSelect, child:
      Padding(padding: padding, child:
        SizedBox(height: 24.0, width: 24.0, child:
          Checkbox(
            checkColor: Styles().colors.surface,
            activeColor: Styles().colors.fillColorPrimary,
            value: widget.selected,
            visualDensity: VisualDensity.compact,
            side: BorderSide(color: Styles().colors.fillColorPrimary, width: 1.0),
            onChanged: _onToggleSelected,
          ),
        ),
      ),
    );

  void _onSelect() =>
    _onToggleSelected(!widget.selected);

  void _onToggleSelected(bool? value) {
    if (value != null) {
      widget.onToggleSelected?.call(value);
    }
  }

  Widget get _collapsedContent =>
      InkWell(onTap: widget.onToggleExpanded, child:
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _cardSelectionContent(padding: EdgeInsets.only(top: 12, bottom: 12, right: 8)),
          Expanded(child:
            Padding(padding: EdgeInsets.symmetric(vertical: 12), child:
              RichText(
                textAlign: TextAlign.left,
                text: TextSpan(style: Styles().textStyles.getTextStyle('widget.title.regular'), children: _nameSpans),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ),
          Padding(padding: EdgeInsets.symmetric(vertical: 12, horizontal: 6), child:
            Styles().images.getImage('chevron2-down',)
          )
        ],)
      );

  Widget get _expandedMembersContent {
    List<Widget> content = [];
    for (ConversationMember member in widget.conversation.members ?? []) {
      List<TextSpan> nameSpans = [];
      List<String> names = member.name?.split(' ') ?? [];
      if (names.length > 1) {
        _addNameSpan(nameSpans, names[0]);
        if (names.length > 2) {
          _addNameSpan(nameSpans, names[1]);
        }
        _addNameSpan(nameSpans, names.last, style: Styles().textStyles.getTextStyle('widget.title.regular.fat'));
      }
      content.add(Padding(padding: const EdgeInsets.only(bottom: 12.0), child:
        RichText(
          textAlign: TextAlign.left,
          text: TextSpan(style: Styles().textStyles.getTextStyle('widget.title.regular'), children: nameSpans),
          overflow: TextOverflow.ellipsis,
        ),
      ));
    }
    return Padding(padding: const EdgeInsets.only(top: 12.0), child:
      Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: content,),
    );
  }

  List<TextSpan> get _nameSpans {
    List<TextSpan> spans = <TextSpan>[];
    for (ConversationMember member in widget.conversation.members ?? []) {
      List<TextSpan> nameSpans = [];
      List<String> names = member.name?.split(' ') ?? [];
      if (names.length > 1) {
        _addNameSpan(nameSpans, names[0]);
        if (names.length > 2) {
          _addNameSpan(nameSpans, names[1]);
        }
        _addNameSpan(nameSpans, names.last, style: Styles().textStyles.getTextStyle('widget.title.regular.fat'));
      }
      if (spans.isNotEmpty) {
        spans.add(TextSpan(text: ', '));
      }
      spans.addAll(nameSpans);
    }
    return spans;
  }

  void _addNameSpan(List<TextSpan> spans, String? name, {TextStyle? style}) {
    if (name?.isNotEmpty == true) {
      if (spans.isNotEmpty) {
        spans.add(TextSpan(text: ' '));
      }
      spans.add(TextSpan(text: name ?? '', style: style));
    }
  }
}
