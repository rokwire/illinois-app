// Copyright 2024 Board of Trustees of the University of Illinois.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:illinois/model/Assistant.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/ui/assistant/AssistantConversationContentWidget.dart';
import 'package:illinois/ui/assistant/AssistantProvidersConversationContentWidget.dart';
import 'package:illinois/ui/widgets/LinkButton.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/ribbon_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';

enum AssistantContent { google_conversation, grok_conversation, perplexity_conversation, all_assistants }

class AssistantHomePanel extends StatefulWidget {
  final AssistantContent? content;

  AssistantHomePanel._({this.content});

  @override
  _AssistantHomePanelState createState() => _AssistantHomePanelState();

  static String pageRuntimeTypeName = 'AssistantHomePanel';

  static void present(BuildContext context, {AssistantContent? content}) {
    if (Connectivity().isOffline) {
      AppAlert.showOfflineMessage(
          context, Localization().getStringEx('panel.assistant.offline.label', 'The Illinois Assistant is not available while offline.'));
    } else if (!Auth2().isOidcLoggedIn) {
      AppAlert.showTextMessage(
          context,
          Localization().getStringEx('panel.assistant.logged_out.label',
              'To access the Illinois Assistant, you need to sign in with your NetID and set your privacy level to 4 or 5 under Profile.'));
    } else {
      MediaQueryData mediaQuery = MediaQueryData.fromView(View.of(context));
      double height = mediaQuery.size.height - mediaQuery.viewPadding.top - mediaQuery.viewInsets.top - 16;
      showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          isDismissible: true,
          useRootNavigator: true,
          routeSettings: RouteSettings(),
          clipBehavior: Clip.antiAlias,
          backgroundColor: Styles().colors.background,
          constraints: BoxConstraints(maxHeight: height, minHeight: height),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
          builder: (context) {
            return AssistantHomePanel._(content: content);
          });
    }
  }
}

class _AssistantHomePanelState extends State<AssistantHomePanel> with NotificationsListener {
  late List<AssistantContent> _contentTypes;
  AssistantContent? _selectedContent;
  static AssistantContent? _lastSelectedContent;
  bool _contentValuesVisible = false;

  final GlobalKey _pageKey = GlobalKey();
  final GlobalKey _pageHeadingKey = GlobalKey();
  final _clearMessagesNotifier = new StreamController.broadcast();


  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, [
      Auth2.notifyLoginChanged,
      FlexUI.notifyChanged,
    ]);

    _contentTypes = _buildAssistantContentTypes();

    if (widget.content != null) {
      _selectedContent = _lastSelectedContent = widget.content;
    } else if (_lastSelectedContent != null) {
      _selectedContent = _lastSelectedContent;
    } else {
      _selectedContent = _initialSelectedContent;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Force to calculate correct content height
      setStateIfMounted((){});
    });
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    _clearMessagesNotifier.close();
    super.dispose();
  }

  // NotificationsListener

  @override
  void onNotification(String name, param) {
    if (name == Auth2.notifyLoginChanged) {
      _updateContentTypes();
    } else if (name == FlexUI.notifyChanged) {
      _updateContentTypes();
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildSheet(context);
  }

  Widget _buildSheet(BuildContext context) {
    return Column(children: [
      Container(
          color: Styles().colors.white,
          child: Row(children: [
            Expanded(
                child: Semantics(container: true,
                  child: Padding(
                    padding: EdgeInsets.only(left: 16),
                    child: Text(Localization().getStringEx('panel.assistant.header.title', 'Illinois Assistant'),
                        style: Styles().textStyles.getTextStyle("widget.label.medium.fat"))))),
            // was: visible: (_selectedContent == AssistantContent.uiuc_conversation)
            Visibility(visible: false, child: LinkButton(onTap: _onTapClearAll, title: Localization().getStringEx('panel.assistant.clear_all.label', 'Clear All'), fontSize: 14)),
            Semantics(
                label: Localization().getStringEx('dialog.close.title', 'Close'),
                hint: Localization().getStringEx('dialog.close.hint', ''),
                inMutuallyExclusiveGroup: true,
                button: true,
                child: InkWell(
                    onTap: _onTapClose,
                    child: Container(
                        padding: EdgeInsets.only(left: 8, right: 16, top: 16, bottom: 16),
                        child: Styles().images.getImage('close-circle', excludeFromSemantics: true))))
          ])),
      Container(color: Styles().colors.surfaceAccent, height: 1),
      Expanded(child: _buildPage(context))
    ]);
  }

  Widget _buildPage(BuildContext context) {
    return Column(key: _pageKey, children: <Widget>[
      Container(
              color: Styles().colors.background,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Padding(
                      key: _pageHeadingKey,
                      padding: EdgeInsets.only(left: 16, top: 16, right: 16),
                      child: Semantics(hint: Localization().getStringEx("dropdown.hint", "DropDown"), focused: true, container: true, child: RibbonButton(
                          textStyle: Styles().textStyles.getTextStyle("widget.button.title.medium.fat.secondary"),
                          backgroundColor: Styles().colors.white,
                          borderRadius: BorderRadius.all(Radius.circular(5)),
                          border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
                          rightIconKey: (_contentValuesVisible ? 'chevron-up' : 'chevron-down'),
                          label: _getContentItemName(_selectedContent) ?? '',
                          onTap: _onTapContentSwitch))),
                _buildContent(),
              ]))
    ]);
  }

  Widget _buildContent() {
    return Stack(children: [(_contentWidget ?? Container()), Container(height: _contentHeight), _buildContentValuesContainer()]);
  }

  Widget _buildContentValuesContainer() {
    return Visibility(
        visible: _contentValuesVisible,
        child: Positioned.fill(child: Stack(children: <Widget>[_buildContentDismissLayer(), _buildContentValuesWidget()])));
  }

  Widget _buildContentDismissLayer() {
    return Positioned.fill(
        child:
            BlockSemantics(child: GestureDetector(onTap: _onTapDismissLayer, child: Container(color: Styles().colors.blackTransparent06))));
  }

  Widget _buildContentValuesWidget() {
    List<Widget> contentList = <Widget>[];
    contentList.add(Container(color: Styles().colors.fillColorSecondary, height: 2));
    for (AssistantContent contentItem in _contentTypes) {
      if (_selectedContent != contentItem) {
        contentList.add(_buildContentItem(contentItem));
      }
    }
    return Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: SingleChildScrollView(child: Column(children: contentList)));
  }

  Widget _buildContentItem(AssistantContent contentItem) {
    return RibbonButton(
        backgroundColor: Styles().colors.white,
        border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
        rightIconKey: null,
        label: _getContentItemName(contentItem),
        onTap: () => _onTapContentItem(contentItem));
  }

  void _onTapContentItem(AssistantContent contentItem) {
    Analytics().logSelect(target: contentItem.toString(), source: widget.runtimeType.toString());
    setState(() {
      _selectedContent = _lastSelectedContent = contentItem;
      _contentValuesVisible = !_contentValuesVisible;
    });
  }

  void _onTapClearAll() {
    Analytics().logSelect(target: 'Clear All', source: widget.runtimeType.toString());
    AppAlert.showConfirmationDialog(context,
      message: Localization().getStringEx('panel.assistant.clear_all.confirm_prompt.text', 'Are you sure you want to clear your Illinois Assistant history? This action cannot be undone.'),
      positiveButtonLabel: Localization().getStringEx('dialog.yes.title', 'Yes'),
      negativeButtonLabel: Localization().getStringEx('dialog.cancel.title', 'Cancel'),
    ).then((value) {
      if (mounted && (value == true)) {
        _clearMessagesNotifier.sink.add(1);
      }
    });
  }

  void _onTapClose() {
    Analytics().logSelect(target: 'Close', source: widget.runtimeType.toString());
    Navigator.of(context).pop();
  }

  void _onTapContentSwitch() {
    setState(() {
      _contentValuesVisible = !_contentValuesVisible;
    });
  }

  void _onTapDismissLayer() {
    setState(() {
      _contentValuesVisible = false;
    });
  }

  // Content Codes

  void _updateContentTypes() {
    List<AssistantContent> contentTypes = _buildAssistantContentTypes();
    if (!DeepCollectionEquality().equals(_contentTypes, contentTypes) && mounted) {
      setState(() {
        _contentTypes = contentTypes;
        _contentValuesVisible = false;
        if (!_contentTypes.contains(_selectedContent)) {
          _selectedContent = _contentTypes.isNotEmpty ? _contentTypes.first : null;
        }
      });
    }
  }

  List<AssistantContent> _buildAssistantContentTypes() {
    List<AssistantContent> contentTypes = <AssistantContent>[];
    List<String>? contentCodes = JsonUtils.listStringsValue(FlexUI()['assistant']);
    if (contentCodes != null) {
      for (String code in contentCodes) {
        AssistantContent? value = _assistantContentFromString(code);
        if (value != null) {
          contentTypes.add(value);
        }
      }
    }
    return contentTypes;
  }

  AssistantContent? _assistantContentFromString(String? value) {
    switch (value) {
      case 'google_assistant':
        return AssistantContent.google_conversation;
      case 'grok_assistant':
        return AssistantContent.grok_conversation;
      case 'perplexity_assistant':
        return AssistantContent.perplexity_conversation;
      case 'all_assistants':
        return AssistantContent.all_assistants;
      default:
        return null;
    }
  }

  // Utilities

  double? get _contentHeight {
    RenderObject? pageRenderBox = _pageKey.currentContext?.findRenderObject();
    double? pageHeight = ((pageRenderBox is RenderBox) && pageRenderBox.hasSize) ? pageRenderBox.size.height : null;

    RenderObject? pageHeaderRenderBox = _pageHeadingKey.currentContext?.findRenderObject();
    double? pageHeaderHeight = ((pageHeaderRenderBox is RenderBox) && pageHeaderRenderBox.hasSize) ? pageHeaderRenderBox.size.height : null;

    return ((pageHeight != null) && (pageHeaderHeight != null)) ? (pageHeight - pageHeaderHeight) : null;
  }

  Widget? get _contentWidget {
    switch (_selectedContent) {
      case AssistantContent.google_conversation:
        return AssistantConversationContentWidget(shouldClearAllMessages: _clearMessagesNotifier.stream, provider: _selectedProvider);
      case AssistantContent.grok_conversation:
        return AssistantConversationContentWidget(shouldClearAllMessages: _clearMessagesNotifier.stream, provider: _selectedProvider);
      case AssistantContent.perplexity_conversation:
        return AssistantConversationContentWidget(shouldClearAllMessages: _clearMessagesNotifier.stream, provider: _selectedProvider);
      case AssistantContent.all_assistants:
        return AssistantProvidersConversationContentWidget();
      default:
        return null;
    }
  }

  String? _getContentItemName(AssistantContent? contentItem) {
    switch (contentItem) {
      case AssistantContent.google_conversation:
        return Localization().getStringEx('panel.assistant.content.conversation.google.label', 'Ask the Google Assistant');
      case AssistantContent.grok_conversation:
        return Localization().getStringEx('panel.assistant.content.conversation.grok.label', 'Ask the Grok Assistant');
      case AssistantContent.perplexity_conversation:
        return Localization().getStringEx('panel.assistant.content.conversation.perplexity.label', 'Ask the Perplexity Assistant');
      case AssistantContent.all_assistants:
        return Localization().getStringEx('panel.assistant.content.conversation.all.label', 'Use All Assistants',);
      default:
        return null;
    }
  }

  AssistantProvider? get _selectedProvider {
    switch (_selectedContent) {
      case AssistantContent.google_conversation:
        return AssistantProvider.google;
      case AssistantContent.grok_conversation:
        return AssistantProvider.grok;
      case AssistantContent.perplexity_conversation:
        return AssistantProvider.perplexity;
      default:
        return null;
    }
  }

  AssistantContent? get _initialSelectedContent => CollectionUtils.isNotEmpty(_contentTypes) ? _contentTypes.first : null;
}
