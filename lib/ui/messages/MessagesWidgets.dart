import 'package:flutter/material.dart';
import 'package:illinois/ui/directory/DirectoryWidgets.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/social.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/social.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class RecentConversationsPage extends StatefulWidget {
  final String? searchText;
  final ScrollController? scrollController;
  final List<Conversation>? recentConversations;
  final int conversationPageSize;
  final void Function(bool, Conversation)? onConversationSelectionChanged;
  final Set<String>? selectedAccountIds;

  RecentConversationsPage({super.key, this.recentConversations, required this.conversationPageSize,
    this.searchText, this.scrollController,
    this.onConversationSelectionChanged, this.selectedAccountIds });

  @override
  State<StatefulWidget> createState() => RecentConversationsPageState();
}

class RecentConversationsPageState extends State<RecentConversationsPage> with NotificationsListener, AutomaticKeepAliveClientMixin {

  List<Conversation>? _conversations;
  late Map<String, Conversation> _conversationsMap;
  bool _loading = false;
  bool _loadingProgress = false;
  bool _extending = false;
  bool _canExtend = false;

  String? _expandedConversationId;

  // Map<String, dynamic> _filterAttributes = <String, dynamic>{};

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Social.notifyMessageSent,
    ]);

    widget.scrollController?.addListener(_scrollListener);
    if (widget.recentConversations != null) {
      _conversations = widget.recentConversations;
      _conversationsMap = _buildConversationsMap(widget.recentConversations);
      Conversation.sortListByLastActivityTime(_conversations!);
    } else {
      _load();
    }
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    widget.scrollController?.removeListener(_scrollListener);
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  // NotificationsListener
  @override
  void onNotification(String name, dynamic param) {
    if (name == Social.notifyMessageSent) {
      if (mounted) {
        _load();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_loadingProgress) {
      return _loadingContent;
    }
    else if (_conversations == null) {
      return _messageContent(Localization().getStringEx('panel.messages.directory.conversations.failed.text', 'Failed to load recent conversations.'));
    }
    else if (_conversations?.isEmpty == true) {
      return _messageContent(Localization().getStringEx('panel.messages.directory.conversations.empty.text', 'There are no recent conversations.'));
    }
    else {
      return _conversationsContent;
    }
  }

  Widget get _conversationsContent {
    List<Widget> contentList = <Widget>[];

    List<Conversation>? conversations = _conversations;
    if ((conversations != null) && conversations.isNotEmpty) {
      for (Conversation conversation in conversations) {
        contentList.add(RecentConversationCard(conversation,
          expanded: (_expandedConversationId != null) && (conversation.id == _expandedConversationId),
          // onToggleExpanded: conversation.isGroupConversation ? () => _onToggleConversationExpanded(conversation) : null, //TODO: should group conversations be expandable to show all names?
          selected: ListUtils.contains(widget.selectedAccountIds, conversation.memberIds, checkAll: true) ?? false, // conversation must contain all selected account IDs to be selected
          onToggleSelected: (value) => widget.onConversationSelectionChanged?.call(value, conversation),
        ));
      }
    }

    if (_extending) {
      contentList.add(_extendingIndicator);
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: contentList);
  }

  // void _onToggleConversationExpanded(Conversation conversation) {
  //   Analytics().logSelect(target: 'Expand', source: conversation.id);
  //   setState(() {
  //     _expandedConversationId = (_expandedConversationId != conversation.id) ? conversation.id : null;
  //   });
  // }

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
      List<Conversation>? conversations = await Social().loadConversations(offset: 0, limit: widget.conversationPageSize, name: widget.searchText);
      setStateIfMounted(() {
        _loading = false;
        _loadingProgress = false;
        if (conversations != null) {
          _conversations = List.from(conversations);
          _conversationsMap = _buildConversationsMap(conversations);
          Conversation.sortListByLastActivityTime(_conversations!);
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
      List<Conversation>? conversations = await Social().loadConversations(offset: _conversationsCount, limit: widget.conversationPageSize, name: widget.searchText);
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
            }
            Conversation.sortListByLastActivityTime(_conversations!);

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
    InkWell(onTap: _onSelect, child:
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _cardSelectionContent(padding: const EdgeInsets.only(top: 12, bottom: 12, right: 8)),
        Expanded(child:
          _expandedMembersContent
        ),
        if (widget.onToggleExpanded != null)
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
      InkWell(onTap: _onSelect, child:
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
          if (widget.onToggleExpanded != null)
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
