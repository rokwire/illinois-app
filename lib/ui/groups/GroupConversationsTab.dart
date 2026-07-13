
import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/model/Analytics.dart';
import 'package:illinois/ui/groups/GroupConversationMessagesPanel.dart';
import 'package:illinois/ui/groups/GroupConversationWidgets.dart';
import 'package:illinois/ui/groups/GroupDetailPanel.dart';
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
  final AnalyticsFeature? analyticsFeature;

  GroupConversationsTab({ super.key, this.group, this.updateController, this.groupAdmins, this.analyticsFeature });

  @override
  State<StatefulWidget> createState() => _GroupConversationsTabState();
}

class _GroupConversationsTabState extends State<GroupConversationsTab> with NotificationsListener {
  List<Conversation>? _conversations;
  ContentActivity? _conversationsActivity;

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
  void onNotification(String name, dynamic param) {
    if (name == Social.notifyConversationsUpdated) {
      if (mounted) {
        _refreshConversations();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
    Padding(padding: EdgeInsetsGeometry.symmetric(horizontal: 16), child:
      Column(mainAxisSize: MainAxisSize.min, children: [
        ..._conversations?.map((Conversation conversation) =>
          Padding(padding: EdgeInsets.only(top: 8), child:
            GroupConversationCard(conversation,
              groupAdmins: widget.groupAdmins,
              onTap: () => _onTapConversation(conversation),
            ),
          )
        ) ?? <Widget>[],
        Padding(padding: EdgeInsets.only(top: 8),),
      ],),
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
      List<Conversation>? conversations = await Social().loadConversations();
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
    if ((_conversationsActivity != ContentActivity.reload) && (_conversationsActivity != ContentActivity.refresh)) {
      setStateIfMounted(() {
        _conversationsActivity = ContentActivity.refresh;
      });
      List<Conversation>? conversations = await Social().loadConversations();
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
      GroupConversationMessagesPanel(conversation,
        group: widget.group,
        groupAdmins: widget.groupAdmins,
        analyticsFeature: widget.analyticsFeature,
      )
    ));
  }
}
