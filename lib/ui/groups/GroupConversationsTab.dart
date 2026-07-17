
import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/model/Analytics.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/events2/Event2Widgets.dart';
import 'package:illinois/ui/groups/GroupConversationPanel.dart';
import 'package:illinois/ui/groups/GroupConversationWidgets.dart';
import 'package:illinois/ui/groups/GroupDetailPanel.dart';
import 'package:illinois/ui/widgets/LinkButton.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:rokwire_plugin/model/group.dart';
import 'package:rokwire_plugin/model/social.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/social.dart';
import 'package:rokwire_plugin/service/styles.dart';


class GroupConversationsTab extends StatefulWidget {

  final Group? group;
  final List<Member>? groupAdmins;
  final StreamController<dynamic>? updateController;
  final bool editMode;
  final AnalyticsFeature? analyticsFeature;

  GroupConversationsTab({ super.key, this.group, this.updateController, this.groupAdmins, this.editMode = false, this.analyticsFeature });

  @override
  State<StatefulWidget> createState() => _GroupConversationsTabState();
}

class _GroupConversationsTabState extends State<GroupConversationsTab> with NotificationsListener, AutomaticKeepAliveClientMixin<GroupConversationsTab> {
  List<Conversation>? _conversations;
  ContentActivity? _conversationsActivity;
  Set<String> _selectedConversations = <String>{};
  bool _selectedConversationsProgress = false;

  @override
  void initState() {
    NotificationService().subscribe(this, [ Social.notifyConversationsUpdated ]);
    widget.updateController?.stream.listen(_onUpdate);
    _initConversations();
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant GroupConversationsTab oldWidget) {
    if (oldWidget.editMode != widget.editMode) {
      _selectedConversations.clear();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void onNotification(String name, dynamic param) {
    if (name == Social.notifyConversationsUpdated) {
      if (mounted) {
        _refreshConversations();
      }
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_conversationsActivity == ContentActivity.reload) {
      return _loadingContent;
    }
    else if (_conversations == null) {
      return _messageContent(Localization().getStringEx('', 'Failed to load groups messages'));
    }
    else if (_conversations?.isEmpty == true) {
      return _messageContent(Localization().getStringEx('', 'No group messages'));
    }
    else {
      return _conversationsContent;
    }
  }

  Widget get _conversationsContent =>
    Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (widget.editMode && _selectedConversations.isNotEmpty)
        _editBar,
      ..._conversations?.map((Conversation conversation) =>
        Padding(padding: EdgeInsets.only(top: 8), child:
          _conversationListItem(conversation),
        )
      ) ?? <Widget>[],
      Padding(padding: EdgeInsets.only(top: 8),),
    ],);

  Widget _conversationListItem(Conversation conversation) => widget.editMode ?
      Row(children: [
        _conversationSelectWidget(conversation),
        Expanded(child:
          Padding(padding: EdgeInsetsGeometry.only(right: 16), child:
            _conversationCard(conversation)
          )
        )
      ],) :
      Padding(padding: EdgeInsetsGeometry.symmetric(horizontal: 16), child:
        _conversationCard(conversation)
      );

  Widget _conversationSelectWidget(Conversation conversation) => Event2ImageCommandButton(
      Styles().images.getImage(_selectedConversations.contains(conversation.id) ? 'check-circle-filled' : 'check-circle-outline-gray', size: 24, excludeFromSemantics: true),
      label: Localization().getStringEx('', 'Select'),
      hint: Localization().getStringEx('', 'Tap to select conversation'),
      contentPadding: EdgeInsets.all(16),
      onTap: () => _onSelectConversation(conversation),
    );

  Widget _conversationCard(Conversation conversation) =>
    GroupConversationCard(conversation,
      groupAdmins: widget.groupAdmins,
      onTap: () => _onTapConversation(conversation),
    );

  Widget get _editBar => Row(children: [
    Expanded(child:
      LinkButton(
        title: (1 < _selectedConversations.length) ? Localization().getStringEx('', 'Delete Selected Messages') : Localization().getStringEx('', 'Delete Selected Message'),
        textAlign: TextAlign.start,
        textStyle: Styles().textStyles.getTextStyle('widget.button.title.small.fat.underline'),
        padding: EdgeInsetsGeometry.symmetric(horizontal: 16, vertical: 8),
        onTap: _onTapDelete,
      )
    ),
    if (_selectedConversationsProgress)
      _editBarProgress
  ],);

  Widget get _editBarProgress => Padding(padding: EdgeInsetsGeometry.symmetric(horizontal: 16), child:
      SizedBox.square(dimension: 14, child:
          CircularProgressIndicator(color: Styles().colors.fillColorSecondary, strokeWidth: 2,)
      )
  );

  Widget get _loadingContent =>
    Padding(padding: EdgeInsetsGeometry.symmetric(horizontal: 32, vertical: 64), child:
      Center(child:
        SizedBox.square(dimension: 24, child:
          CircularProgressIndicator(strokeWidth: 2, color: Styles().colors.fillColorSecondary,)
        ),
      ),
    );

  Widget _messageContent(String message) =>
    Padding(padding: EdgeInsetsGeometry.symmetric(horizontal: 32, vertical: 64), child:
      Center(child:
        Text(message, textAlign: TextAlign.center, style: Styles().textStyles.getTextStyle('widget.title.regular.thin')),
      ),
    );

  void _onUpdate(dynamic command) {
    if (command == GroupDetailPanel.notifyRefresh) {
      _refreshConversations();
    }
  }

  // Conversations content

  Future<List<Conversation>?> _initConversations() async {
    if (_conversationsActivity != ContentActivity.reload) {
      setStateIfMounted(() {
        _conversationsActivity = ContentActivity.reload;
      });
      List<Conversation>? conversations = await Social().loadConversations(contextId: widget.group?.id);
      if ((_conversationsActivity == ContentActivity.reload) && mounted)
      setState(() {
        _conversationsActivity = null;
        _conversations = conversations;
      });
      return conversations;
    } else {
      return null;
    }
  }

  Future<List<Conversation>?> _refreshConversations() async {
    if (_conversationsActivity?.loading != true) {
      setStateIfMounted(() {
        _conversationsActivity = ContentActivity.refresh;
      });
      List<Conversation>? conversations = await Social().loadConversations(contextId: widget.group?.id, type: ConversationType.groupSubset);
      if ((_conversationsActivity == ContentActivity.refresh) && mounted) {
        setState(() {
          _conversationsActivity = null;
          if ((conversations != null) && !DeepCollectionEquality().equals(_conversations, conversations)) {
            _conversations = conversations;
          }
        });

      }
      return conversations;
    } else {
      return null;
    }
  }

  // Event Handlers

  void _onTapConversation(Conversation conversation) {
    Navigator.of(context).push(CupertinoPageRoute(builder: (context) =>
      GroupConversationPanel(conversation,
        group: widget.group,
        groupAdmins: widget.groupAdmins,
        analyticsFeature: widget.analyticsFeature,
      )
    ));
  }

  void _onSelectConversation(Conversation conversation) {
    Analytics().logSelect(target: 'Conversation');
    String? conversationId = conversation.id;
    if ((conversationId != null) && conversationId.isNotEmpty) {
      setState(() {
        if (_selectedConversations.contains(conversationId)) {
          _selectedConversations.remove(conversationId);
        } else {
          _selectedConversations.add(conversationId);
        }
      });
    }
  }

  void _onTapDelete() async {
    Analytics().logSelect(target: 'Delete Selected Messages');

    if (_selectedConversationsProgress == false) {
      bool? deleteConfirmed = await GroupConversationConfirmDeleteDialog.show(context,
        Localization().getStringEx('', 'Deleting messages cannot be reversed.'),
        Localization().getStringEx('', 'How would you like to proceed?',));

      if ((deleteConfirmed == true) && mounted) {
        setState(() {
          _selectedConversationsProgress = true;
        });
        bool? deleteSucceeded = await Social().deleteConverstions(conversationIds: List.from(_selectedConversations));
        if (mounted) {
          if (deleteSucceeded == true) {
            setState(() {
              _selectedConversations.clear();
              _selectedConversationsProgress = false;
            });
            _refreshConversations();
          } else {
            setState(() {
              _selectedConversationsProgress = false;
            });
            AppAlert.showDialogResult(context, Localization().getStringEx('', 'Failed to delete messages'));
          }
        }
      }
    }
  }
}
