import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:neom/ext/Social.dart';
import 'package:neom/service/Analytics.dart';
import 'package:neom/service/Auth2.dart';
import 'package:neom/ui/directory/DirectoryWidgets.dart';
import 'package:neom/ui/messages/MessagesConversationPanel.dart';
import 'package:neom/ui/messages/MessagesHomePanel.dart';
import 'package:neom/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/social.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/social.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:sprintf/sprintf.dart';

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

class RecentConversationsPageState extends State<RecentConversationsPage> with AutomaticKeepAliveClientMixin implements NotificationsListener {

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
        if (CollectionUtils.isEmpty(conversation.members)) {
          continue;
        }
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

class RecentConversationCard extends StatelessWidget {
  final Conversation conversation;
  final bool expanded;
  final void Function()? onToggleExpanded;
  final bool selected;
  final void Function(bool)? onToggleSelected;

  RecentConversationCard(this.conversation, { super.key, this.expanded = false, this.onToggleExpanded, this.selected = false, this.onToggleSelected });

  @override
  Widget build(BuildContext context) =>
      expanded ? _expandedContent : _collapsedContent;

  Widget get _expandedContent =>
    InkWell(onTap: _onSelect, child:
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _cardSelectionContent(padding: const EdgeInsets.only(top: 12, bottom: 12, right: 8)),
        Expanded(child:
          _expandedMembersContent
        ),
        if (onToggleExpanded != null)
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
            checkColor: Styles().colors.iconPrimary,
            activeColor: Styles().colors.fillColorPrimary,
            value: selected,
            visualDensity: VisualDensity.compact,
            side: BorderSide(
              color: selected ? Styles().colors.iconPrimary : Styles().colors.iconLight,
              width: 1.0,
            ),
            onChanged: _onToggleSelected,
          ),
        ),
      ),
    );

  void _onSelect() =>
    _onToggleSelected(!selected);

  void _onToggleSelected(bool? value) {
    if (value != null) {
      onToggleSelected?.call(value);
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
          if (onToggleExpanded != null)
            Padding(padding: EdgeInsets.symmetric(vertical: 12, horizontal: 6), child:
              Styles().images.getImage('chevron2-down',)
            )
        ],)
      );

  Widget get _expandedMembersContent {
    List<Widget> content = [];
    for (ConversationMember member in conversation.members ?? []) {
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
    for (ConversationMember member in conversation.members ?? []) {
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

class ConversationCard extends StatelessWidget {
  final Conversation conversation;
  final bool? selected;
  final void Function(Conversation)? onTap;
  final bool isHorizontal;

  const ConversationCard({
    super.key,
    required this.conversation,
    this.selected,
    this.onTap,
    this.isHorizontal = false
  });

  String _getConversationTitle() {
    if (CollectionUtils.isEmpty(conversation.members)) {
      return Auth2().fullName ?? 'Unknown';
    }
    return conversation.membersString ?? 'Group Conversation';
  }

  @override
  Widget build(BuildContext context) {
    return isHorizontal
        ? _buildHorizontalLayout(context)
        : _buildVerticalLayout(context);
  }

  Widget _buildVerticalLayout(BuildContext context) {
    double leftPadding = (selected != null) ? 12 : 16;
    return Container(
      color: Styles().colors.surface,
      clipBehavior: Clip.none,
      child: Stack(children: [
        InkWell(
          onTap: () => (onTap != null ? onTap!(conversation) : _onTapCard(context)),
          child: Padding(
            padding: EdgeInsets.only(
                left: leftPadding,
                right: 16,
                top: 16,
                bottom: 16
            ),
            child: Row(children: <Widget>[
              Visibility(
                visible: (selected != null),
                child: Padding(
                  padding: EdgeInsets.only(right: leftPadding),
                  child: Semantics(
                    label: (selected == true)
                        ? Localization().getStringEx('widget.conversation_card.selected.hint', 'Selected')
                        : Localization().getStringEx('widget.conversation_card.unselected.hint', 'Not Selected'),
                    child: Styles().images.getImage(
                      (selected == true)
                          ? 'check-circle-filled'
                          : 'check-circle-outline-gray',
                      excludeFromSemantics: true,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Styles().images.getImage(
                              (conversation.isGroupConversation)
                                  ? 'messages-group-dark-blue'
                                  : 'person-circle-dark-blue'
                          ) ?? Container(),
                        ),
                        Expanded(
                          child: Text(
                              _getConversationTitle(),
                              textAlign: TextAlign.left,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                              style: Styles().textStyles.getTextStyle('widget.card.title.small')
                          ),
                        ),
                        if (MessagesHomePanel.enableMute && conversation.mute == true)
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(Icons.notifications_off, size: 20),
                          ),
                        _buildDisplayDateWidget,
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildLastMessageWidget()
                  ],
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildHorizontalLayout(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Styles().colors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () => _onTapCard(context),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            height: 160,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeaderSection(),
                const SizedBox(height: 12),
                _buildLastMessageWidget(),
                Spacer(),
                Align(
                  alignment: Alignment.centerRight,
                  child: _buildDisplayDateWidget,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Styles().images.getImage(
            (conversation.isGroupConversation)
                ? 'messages-group-dark-blue'
                : 'person-circle-dark-blue',
            excludeFromSemantics: true,
          ) ?? Container(),
        ),
        Expanded(
          child: Text(
            _getConversationTitle(),
            style: Styles().textStyles.getTextStyle('widget.card.detail.tiny'),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
        if (MessagesHomePanel.enableMute && conversation.mute == true)
          const Padding(
            padding: EdgeInsets.only(left: 4),
            child: Icon(Icons.notifications_off, size: 20),
          ),
      ],
    );
  }

  Widget _buildLastMessageWidget() {
    Message? lastMessage = conversation.lastMessage;
    String? messageText = StringUtils.isNotEmpty(lastMessage?.message) ? lastMessage?.message : conversation.lastMessageText;

    ConversationMember? sender = lastMessage?.sender;
    String? senderName = (StringUtils.isNotEmpty(sender?.accountId) &&
        (sender?.accountId == Auth2().accountId)) ? Localization().getStringEx('widget.conversation_card.sender.me', 'You')
        : sender?.name;

    if (!StringUtils.isNotEmpty(messageText)) {
      return Container();
    }

    return Semantics(
      label: sprintf(Localization().getStringEx('widget.conversation_card.body.hint', 'Message: %s',), [messageText ?? ''],),
      child: RichText(
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          children: <TextSpan>[
            if (StringUtils.isNotEmpty(senderName))
              TextSpan(
                text: '$senderName: ',
                style: Styles().textStyles.getTextStyle("widget.card.detail.tiny.fat"),),
            TextSpan(
              text: messageText,
              style: Styles().textStyles.getTextStyle("widget.card.detail.tiny.medium_fat"),
            ),
          ],
        ),
      ),
    );
  }

  Widget get _buildDisplayDateWidget {
    String displayDateTime = StringUtils.ensureNotEmpty(conversation.displayDateTime);
    bool noSuffix = displayDateTime.toLowerCase().contains("now") || displayDateTime.toLowerCase().contains(",");
    return Semantics(child: Text(noSuffix ? displayDateTime : "$displayDateTime ago",
        semanticsLabel: "Updated ${conversation.displayDateTime ?? ""} ago",
        textAlign: TextAlign.right,
        style: Styles().textStyles.getTextStyle('widget.card.detail.tiny.medium_fat')));
  }

  void _onTapCard(BuildContext context) {
    Analytics().logSelect(target: conversation.id);
    Navigator.push(context, CupertinoPageRoute(builder: (context) => MessagesConversationPanel(conversation: conversation,)));
  }
}