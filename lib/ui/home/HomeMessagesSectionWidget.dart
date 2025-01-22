import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:neom/ui/widgets/LinkButton.dart';
import 'package:rokwire_plugin/model/social.dart';
import 'package:rokwire_plugin/service/social.dart';
import 'package:neom/ui/home/HomePanel.dart';
import 'package:neom/ui/home/HomeWidgets.dart';
import 'package:neom/ui/messages/MessagesConversationPanel.dart';
import 'package:neom/ui/messages/MessagesHomePanel.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class HomeMessagesSectionWidget extends StatefulWidget {
  final String? favoriteId;
  final StreamController<String>? updateController;

  const HomeMessagesSectionWidget({Key? key, this.favoriteId, this.updateController}) : super(key: key);

  static Widget handle({Key? key, String? favoriteId, HomeDragAndDropHost? dragAndDropHost, int? position}) =>
      HomeHandleWidget(key: key, favoriteId: favoriteId, dragAndDropHost: dragAndDropHost, position: position,
        title: StringUtils.capitalize(title),
      );

  static String get title => Localization().getStringEx('', 'CONVERSATION');

  @override
  State<StatefulWidget> createState() => _HomeMessagesSectionWidgetState();
}

class _HomeMessagesSectionWidgetState extends State<HomeMessagesSectionWidget> {
  static const int _conversationsPageSize = 5;
  List<Conversation> _conversations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  @override
  Widget build(BuildContext context) {
    return HomeBannerWidget(
      favoriteId: widget.favoriteId,
      title: HomeMessagesSectionWidget.title,
      bannerImageKey: 'banner-messages',
      child: _widgetContent,
      childPadding: const EdgeInsets.only(top: 24.0, bottom: 12.0),
    );
  }

  Widget get _widgetContent {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildConversationsList(),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildViewAllButton(),
        ),
      ],
    );
  }

  Widget _buildConversationsList() {
    return SizedBox(
      height: 160,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _conversations.isEmpty
          ? _buildEmptyContent()
          : ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _conversations.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) => _buildConversationCard(_conversations[index]),
      ),
    );
  }

  Widget _buildConversationCard(Conversation conversation) {
    return SizedBox(
      width: 280,
      child: ConversationCard(
        conversation: conversation,
        onTap: () => _openConversation(conversation),
        isHorizontal: true,
      ),
    );
  }

  Widget _buildViewAllButton() {
    return Align(
      alignment: Alignment.center,
      child: LinkButton(
        title: 'View all',
        textStyle: Styles().textStyles.getTextStyle('widget.description.regular.light.underline'),
        onTap: () => MessagesHomePanel.present(context),
      )
    );
  }

  Widget _buildEmptyContent() {
    return Center(
      child: Text(
        Localization().getStringEx('widget.home.messages.text.empty', 'No recent messages'),
        style: Styles().textStyles.getTextStyle('widget.description.regular'),
      ),
    );
  }

  void _openConversation(Conversation conversation) {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => MessagesConversationPanel(conversation: conversation),
      ),
    );
  }

  Future<void> _loadConversations() async {
    List<Conversation>? conversations = await Social().loadConversations(
      limit: _conversationsPageSize,
    );

    if (mounted) {
      setState(() {
        _loading = false;
        _conversations = conversations ?? [];
      });
    }
  }
}