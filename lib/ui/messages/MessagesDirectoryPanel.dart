import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:neom/ui/messages/MessagesConversationPanel.dart';
import 'package:neom/ui/widgets/HeaderBar.dart';
import 'package:neom/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/ribbon_button.dart';

class MessagesDirectoryPanel extends StatefulWidget {
  final bool? unread;
  final void Function()? onTapBanner;
  MessagesDirectoryPanel({Key? key, this.unread, this.onTapBanner}) : super(key: key);

  _MessagesDirectoryPanelState createState() => _MessagesDirectoryPanelState();
}

class _MessagesDirectoryPanelState extends State<MessagesDirectoryPanel> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: RootHeaderBar(title: Localization().getStringEx("panel.messages.home.header.title", "Messages"), leading: RootHeaderBarLeading.Back,),
      body: _buildContent(),
      backgroundColor: Styles().colors.surface,
      bottomNavigationBar: uiuc.TabBar(),
    );
  }

  Widget _buildContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        RibbonButton(
          backgroundColor: Styles().colors.fillColorSecondary,
          label: "Conversation",
          onTap: _onTapConversation,
        ),
      ],
    );
  }

  void _onTapConversation() {
    Navigator.push(context, CupertinoPageRoute(builder: (context) => MessagesConversationPanel()));
  }
}