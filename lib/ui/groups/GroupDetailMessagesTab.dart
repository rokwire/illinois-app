
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:illinois/ext/Social.dart';
import 'package:illinois/model/Analytics.dart';
import 'package:illinois/ui/groups/GroupDetailPanel.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/group.dart';
import 'package:rokwire_plugin/model/social.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/social.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:sprintf/sprintf.dart';

class GroupDetailMessagesTab extends StatefulWidget {

  final Group? group;
  final List<Member>? groupAdmins;
  final StreamController<dynamic>? updateController;
  final AnalyticsFeature? analyticsFeature;

  GroupDetailMessagesTab({ super.key, this.group, this.updateController, this.groupAdmins, this.analyticsFeature });

  @override
  State<StatefulWidget> createState() => _GroupDetailMessagesTabState();
}

class _GroupDetailMessagesTabState extends State<GroupDetailMessagesTab> {
  List<Conversation>? _conversations;
  bool _loadingConversations = false;

  @override
  void initState() {
    widget.updateController?.stream.listen(_onUpdate);
    _initConversations();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingConversations) {
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
        ..._conversations?.map((Conversation conversation) => Padding(padding: EdgeInsets.only(top: 8), child: _GroupConversationCard(conversation),)) ?? <Widget>[],
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
    if (_loadingConversations == false) {
      setStateIfMounted(() {
        _loadingConversations = true;
      });
      List<Conversation>? conversations = await Social().loadConversations();
      setStateIfMounted(() {
        _loadingConversations = false;
        _conversations = conversations;
      });
      return conversations;
    } else {
      return null;
    }
  }

  Future<List<Conversation>?> _refreshConversations() async {
    if (_loadingConversations == false) {
      setStateIfMounted(() {
        _loadingConversations = true;
      });
      List<Conversation>? conversations = await Social().loadConversations();
      setStateIfMounted(() {
        _loadingConversations = false;
        if (conversations != null) {
          _conversations = conversations;
        }
      });
      return conversations;
    } else {
      return null;
    }
  }
}

class _GroupConversationCard extends StatelessWidget {

  final Conversation conversation;

  _GroupConversationCard(this.conversation);

  @override
  Widget build(BuildContext context) =>
    Container(decoration: _cardDecoration, padding: _cardPadding, child:
      Row(children: [
        _GroupConversationAvtarWidget(conversation.members),
        Expanded(child:
          Padding(padding: EdgeInsets.symmetric(horizontal: _horzPadding), child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              _participantNamesWidget,
              _updateTimeWidget,
            ],)
          ),
        ),
        Styles().images.getImage('chevron-right', excludeFromSemantics: true) ?? Container(),
      ],)
    );

  Widget get _participantNamesWidget => Text(conversation.membersString ?? '',
    textAlign: TextAlign.left,
    overflow: TextOverflow.ellipsis,
    maxLines: 1,
    style: Styles().textStyles.getTextStyle('widget.card.title.small.fat')
  );

  Widget get _updateTimeWidget {
    String? updateTime = conversation.displayUpdateTime;
    String? semanticsLabel = (updateTime != null) ? sprintf(Localization().getStringEx('', 'Updated %s'), [updateTime]) : null;
    return Semantics(child:
      Text(updateTime ?? '',
        semanticsLabel: semanticsLabel,
        textAlign: TextAlign.left,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        style: Styles().textStyles.getTextStyle('widget.card.detail.small')
      )
    );

  }

  BoxDecoration get _cardDecoration => BoxDecoration(
    color: Styles().colors.surface,
    border: Border.all(color: Styles().colors.textBackgroundVariant2, width: 2),
    borderRadius: BorderRadius.all(Radius.circular(8)),
  );

  EdgeInsetsGeometry get _cardPadding =>
    EdgeInsetsGeometry.symmetric(horizontal: _horzPadding, vertical: _vertPadding);
  
  static const double _horzPadding = 12;
  static const double _vertPadding = 8;
}

class _GroupConversationAvtarWidget extends StatefulWidget {
  final List<ConversationMember>? participants;

  _GroupConversationAvtarWidget(this.participants);

  int get participantsCount => participants?.length ?? 0;

  @override
  State<StatefulWidget> createState() => _GroupConversationAvtarWidgetState();
}

class _GroupConversationAvtarWidgetState extends State<_GroupConversationAvtarWidget> {
  static const double _widgetSize = 48;

  static const double _avtarSize = _widgetSize / 2 - 1;
  static const double _avtarOffset = _avtarSize * (sqrt2 - 1) / (2 * sqrt2);

  static const double _avtar2Size = _avtarSize * 2 / 3;
  static const double _avtar2Offset = _avtarOffset + 1;

  @override
  Widget build(BuildContext context) {
    return Container(width: _widgetSize, height: _widgetSize, decoration: _avtarDecoration, child:
      Stack(children: [
        Positioned.fill(child:
          Align(alignment: Alignment.topLeft, child:
            Padding(padding: EdgeInsets.only(left: _avtarOffset, top: _avtarOffset,), child:
              Container(width: _avtarSize, height: _avtarSize, decoration: _participantDecoration(Colors.blueAccent)),
            )
          )
        ),
        Positioned.fill(child:
          Align(alignment: Alignment.bottomRight, child:
            Padding(padding: EdgeInsets.only(right: _avtarOffset, bottom: _avtarOffset,), child:
              Container(width: _avtarSize, height: _avtarSize, decoration: _participantDecoration(Colors.yellowAccent)),
            )
          )
        ),
        Positioned.fill(child:
          Align(alignment: Alignment.bottomLeft, child:
            Padding(padding: EdgeInsets.only(left: _avtar2Offset, bottom: _avtar2Offset,), child:
              Container(width: _avtar2Size, height: _avtar2Size, decoration: _participantDecoration(Colors.greenAccent)),
            )
          )
        ),
      ],)
      //Center(child:_membersIcon ?? Container())
    );
  }

  Widget? get _membersIcon {
    if (widget.participantsCount > 1) {
      return Styles().images.getImage('messages-group-dark-blue', size: _widgetSize / 2 );
    }
    else if (widget.participantsCount == 1) {
      return Styles().images.getImage('person-circle-dark-blue', size: _widgetSize / 2);
    }
    else {
      return null;
    }
  }

  BoxDecoration get _avtarDecoration => BoxDecoration(
    color: Styles().colors.textBackgroundVariant2,
    shape: BoxShape.circle,
    border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
  );

  BoxDecoration _participantDecoration(Color color) => BoxDecoration(
    color: color, shape: BoxShape.circle,
  );


}
