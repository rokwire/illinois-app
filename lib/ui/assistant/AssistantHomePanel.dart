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
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:illinois/model/Assistant.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Assistant.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/ui/assistant/AssistantConversationContentWidget.dart';
import 'package:illinois/ui/assistant/AssistantFaqsContentWidget.dart';
import 'package:illinois/ui/assistant/AssistantProvidersConversationContentWidget.dart';
import 'package:illinois/ui/profile/ProfileHomePanel.dart';
import 'package:illinois/ui/settings/SettingsHomeContentPanel.dart';
import 'package:illinois/ui/widgets/LinkButton.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/ribbon_button.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';

enum AssistantContent { google_conversation, grok_conversation, perplexity_conversation, openai_conversation, all_assistants, faqs }

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
    } else if (!Auth2().isLoggedIn) {
      showDialog(context: context, builder: (context) => _AssistantSignInInfoPopup());
    } else if (!Assistant().hasUserAcceptedTerms()) {
      showDialog(context: context, builder: (context) => _AssistantTermsPopup());
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
      Assistant.notifyProvidersChanged,
      Assistant.notifySettingsChanged,
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
      // 1. Force to calculate correct content height
      setStateIfMounted((){});
      // 2. Check if the Assistant is available
      _checkAvailable();
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
    if (name == Auth2.notifyLoginChanged ||
        name == FlexUI.notifyChanged ||
        name == Assistant.notifyProvidersChanged ||
        name == Assistant.notifySettingsChanged) {
      _checkAvailable();
      _updateContentTypes();
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildSheet(context);
  }

  Widget _buildSheet(BuildContext context) {
    bool clearAllVisible = (_selectedContent != null) && (_selectedContent != AssistantContent.all_assistants) && (_selectedContent != AssistantContent.faqs);
    return Column(children: [
      Container(
          color: Styles().colors.gradientColorPrimary,
          child: Row(children: [
            Expanded(
                child: Semantics(container: true,
                  child: Padding(
                    padding: EdgeInsets.only(left: 16),
                    child: Text(Localization().getStringEx('panel.assistant.header.title', 'NEOM U ASSISTANT'),
                        style: Styles().textStyles.getTextStyle("widget.title.light.large.fat"))))),
            Visibility(visible: clearAllVisible && !Config().assistantComingSoon, child: LinkButton(
              onTap: _onTapClearAll,
              title: Localization().getStringEx('panel.assistant.clear_all.label', 'Clear All'),
              textStyle: Styles().textStyles.getTextStyle('widget.description.regular.light.underline'),
            )),
            Semantics(
                label: Localization().getStringEx('dialog.close.title', 'Close'),
                hint: Localization().getStringEx('dialog.close.hint', ''),
                inMutuallyExclusiveGroup: true,
                button: true,
                child: InkWell(
                    onTap: _onTapClose,
                    child: Container(
                        padding: EdgeInsets.only(left: 8, right: 16, top: 16, bottom: 16),
                        child: Styles().images.getImage('close-circle-white', excludeFromSemantics: true))))
          ])),
      Expanded(child: _buildPage(context))
    ]);
  }

  Widget _buildPage(BuildContext context) {
    return Column(key: _pageKey, children: <Widget>[
      Container(
              color: Styles().colors.background,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    // Padding(
                    //   key: _pageHeadingKey,
                    //   padding: EdgeInsets.only(left: 16, top: 16, right: 16),
                    //   child: Semantics(hint: Localization().getStringEx("dropdown.hint", "DropDown"), focused: true, container: true, child: RibbonButton(
                    //       textStyle: Styles().textStyles.getTextStyle("widget.button.title.medium.fat.secondary"),
                    //       backgroundColor: Styles().colors.gradientColorPrimary,
                    //       borderRadius: BorderRadius.all(Radius.circular(5)),
                    //       border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
                    //       rightIconKey: (_contentValuesVisible ? 'chevron-up' : 'chevron-down'),
                    //       label: _getContentItemName(_selectedContent) ?? '',
                    //       onTap: _onTapContentSwitch))),
                _buildContent(),
              ]))
    ]);
  }

  Widget _buildContent() {
    return Stack(children: [(_contentWidget ?? _buildMissingContentWidget()), Container(height: _contentHeight), _buildContentValuesContainer()]);
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

  Widget _buildMissingContentWidget() {
    return Positioned.fill(child: Center(child: Text(Localization().getStringEx('panel.assistant.content.missing.assistant.msg', 'There is no assistant available.'), style: Styles().textStyles.getTextStyle('widget.message.medium.thin'))));
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
        backgroundColor: Styles().colors.gradientColorPrimary,
        textStyle: Styles().textStyles.getTextStyle("widget.button.title.medium.fat"),
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
    List<AssistantProvider>? availableProviders = Assistant().providers;
    if (availableProviders != null) {
      for (AssistantProvider provider in availableProviders) {
        AssistantContent? value = _assistantContentFromProvider(provider);
        if (value != null) {
          contentTypes.add(value);
        }
      }
      int contentTypesLength = contentTypes.length;
      if ((contentTypesLength > 1) && FlexUI().isAllAssistantsAvailable) {
        contentTypes.add(AssistantContent.all_assistants);
      }
      if ((contentTypesLength > 0) && FlexUI().isAssistantFaqsAvailable) {
        contentTypes.add(AssistantContent.faqs);
      }
    }
    return contentTypes;
  }

  // Global On/Off / Available

  void _checkAvailable() {
    if (!_isAvailable) {
      String unavailableMessage = Assistant().localizedUnavailableText ??
          Localization().getStringEx('panel.assistant.global.unavailable.default.msg',
          'The Illinois Assistant is currently unavailable due to high demand. Please check back later for restored access.');
      AppAlert.showDialogResult(context, unavailableMessage);
    }
  }

  bool get _isAvailable => Assistant().isAvailable;

  // Utilities

  String? _getContentItemName(AssistantContent? contentItem) {
    switch (contentItem) {
      case AssistantContent.google_conversation:
        return Localization().getStringEx('panel.assistant.content.conversation.google.label', 'Ask the Google Assistant');
      case AssistantContent.grok_conversation:
        return Localization().getStringEx('panel.assistant.content.conversation.grok.label', 'Ask the Grok Assistant');
      case AssistantContent.perplexity_conversation:
        return Localization().getStringEx('panel.assistant.content.conversation.perplexity.label', 'Ask the Perplexity Assistant');
      case AssistantContent.openai_conversation:
        return Localization().getStringEx('panel.assistant.content.conversation.openai.label', 'Ask the Open AI Assistant');
      case AssistantContent.all_assistants:
        return Localization().getStringEx('panel.assistant.content.conversation.all.label', 'Use All Assistants',);
      case AssistantContent.faqs:
        return Localization().getStringEx('panel.assistant.content.faqs.label', 'Illinois Assistant FAQs');
      default:
        return null;
    }
  }

  AssistantContent? _assistantContentFromProvider(AssistantProvider? provider) {
    switch (provider) {
      case AssistantProvider.google:
        return AssistantContent.google_conversation;
      case AssistantProvider.grok:
        return AssistantContent.grok_conversation;
      case AssistantProvider.perplexity:
        return AssistantContent.perplexity_conversation;
      case AssistantProvider.openai:
        return AssistantContent.openai_conversation;
      default:
        return null;
    }
  }

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
      case AssistantContent.openai_conversation:
        return AssistantConversationContentWidget(shouldClearAllMessages: _clearMessagesNotifier.stream, provider: _selectedProvider);
      case AssistantContent.all_assistants:
        return AssistantProvidersConversationContentWidget();
      case AssistantContent.faqs:
        return AssistantFaqsContentWidget();
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
      case AssistantContent.openai_conversation:
        return AssistantProvider.openai;
      default:
        return null;
    }
  }

  AssistantContent? get _initialSelectedContent => CollectionUtils.isNotEmpty(_contentTypes) ? _contentTypes.first : null;
}

class _AssistantSignInInfoPopup extends StatefulWidget {
  _AssistantSignInInfoPopup();

  @override
  State<_AssistantSignInInfoPopup> createState() => _AssistantSignInInfoPopupState();
}

class _AssistantSignInInfoPopupState extends State<_AssistantSignInInfoPopup> {

  static const String _signInUrl = 'profile://sign_in';
  static const String _privacyUrl = 'settings://privacy';
  static const String _signInUrlMacro = '{{profile_sign_in_url}}';
  static const String _privacyUrlMacro = '{{settings_privacy_url}}';

  @override
  Widget build(BuildContext context) {
    String message = Localization().getStringEx('panel.assistant.logged_out.label',
                "To access the Illinois Assistant, <a href='$_signInUrlMacro'><b>sign in</b></a> with your NetID and <a href='$_privacyUrlMacro'><b>set your privacy level to 4 or 5</b></a> under Settings.")
        .replaceAll(_signInUrlMacro, _signInUrl).replaceAll(_privacyUrlMacro, _privacyUrl);
    return AlertDialog(
        contentPadding: EdgeInsets.zero,
        content: Container(
            decoration: BoxDecoration(color: Styles().colors.white, borderRadius: BorderRadius.circular(10.0)),
            child: Stack(alignment: Alignment.center, children: [
              Padding(
                  padding: EdgeInsets.only(top: 30, bottom: 22),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 28),
                      child: Column(children: [
                        Padding(
                            padding: EdgeInsets.only(top: 14),
                            child:
                                HtmlWidget(message,
                                    onTapUrl: (url) => _onTapUrl(url),
                                    textStyle: Styles().textStyles.getTextStyle("panel.assistant.popup.detail.small"),
                                    customStylesBuilder: (element) => (element.localName == "a") ? {"color": ColorUtils.toHex(Styles().colors.fillColorSecondary)} : null))
                      ]),
                    ),
                  ])),
              Positioned.fill(
                  child: Align(
                      alignment: Alignment.topRight,
                      child: Semantics(
                          button: true,
                          label: "close",
                          child: InkWell(
                              onTap: () {
                                Analytics().logSelect(target: 'Close Assistant Sign-In info popup');
                                Navigator.of(context).pop();
                              },
                              child: Padding(padding: EdgeInsets.all(12), child: Styles().images.getImage('close-circle', excludeFromSemantics: true)))))),
            ])));
  }

  bool _onTapUrl(String url) {
    if (url == _privacyUrl) {
      Analytics().logSelect(target: 'Settings: My App Privacy', source: widget.runtimeType.toString());
      Navigator.of(context).pop();
      SettingsHomeContentPanel.present(context, content: SettingsContent.privacy);
      return true;
    } else if (url == _signInUrl) {
      Analytics().logSelect(target: 'Profile: Sign In / Sign Out', source: widget.runtimeType.toString());
      Navigator.of(context).pop();
      ProfileHomePanel.present(context, content: ProfileContent.login);
      return true;
    } else {
      return false;
    }
  }
}

class _AssistantTermsPopup extends StatefulWidget {
  _AssistantTermsPopup();

  @override
  State<_AssistantTermsPopup> createState() => _AssistantTermsPopupState();
}

class _AssistantTermsPopupState extends State<_AssistantTermsPopup> {

  bool _accepting = false;

  @override
  Widget build(BuildContext context) {
    String text = Assistant().localizedTermsText ??
        Localization().getStringEx('panel.assistant.terms.default.msg',
            'The Illinois Assistant is a search tool that helps you learn more about official university resources. While the feature aims to provide useful information, responses may occasionally be incomplete or inaccurate. **You are responsible for confirming information before taking action based on it.**\n\nBy continuing, you acknowledge that the NEOM U Assistant is a supplemental tool and not a substitute for official university sources.');
    return AlertDialog(
        contentPadding: EdgeInsets.zero,
        content: Container(
            decoration: BoxDecoration(color: Styles().colors.white, borderRadius: BorderRadius.circular(10.0)),
            child: Stack(alignment: Alignment.center, children: [
              Padding(
                  padding: EdgeInsets.only(top: 36, bottom: 22),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 28),
                      child: Column(children: [
                        Styles().images.getImage('university-logo', excludeFromSemantics: true) ?? Container(),
                        Padding(
                            padding: EdgeInsets.only(top: 14),
                            child:
                            MarkdownBody(
                                data: text,
                                styleSheet: MarkdownStyleSheet(
                                    p: Styles().textStyles.getTextStyle('widget.detail.dark.small'),
                                    a: TextStyle(decoration: TextDecoration.underline)))),
                        Padding(padding: EdgeInsets.only(top: 14), child: RoundedButton(
                            label: Localization().getStringEx('panel.assistant.terms.accept.button', 'I Accept'),
                            onTap: _onTapAccept, fontSize: 16,
                            progress: _accepting,
                            conentAlignment: MainAxisAlignment.center,
                            padding: EdgeInsets.symmetric(vertical: 5),
                            contentWeight: 0.5))]))
                  ])),
              Positioned.fill(
                  child: Align(
                      alignment: Alignment.topRight,
                      child: Semantics(
                          button: true,
                          label: "close",
                          child: InkWell(
                              onTap: () {
                                Analytics().logSelect(target: 'Close Assistant Terms Popup');
                                Navigator.of(context).pop();
                              },
                              child: Padding(padding: EdgeInsets.all(12), child: Styles().images.getImage('close-circle', excludeFromSemantics: true)))))),
            ])));
  }

  void _onTapAccept() {
    Analytics().logSelect(target: 'Accept Assistant Terms');
    setStateIfMounted(() {
      _accepting = true;
    });
    Assistant().acceptTerms().then((accepted) {
      setStateIfMounted(() {
        _accepting = false;
      });
      if (accepted) {
        Navigator.of(context).pop();
        AssistantHomePanel.present(context);
      } else {
        AppAlert.showDialogResult(context, Localization().getStringEx('panel.assistant.terms.accepted.fail.msg', 'Something went wrong. Please, try again later.'));
      }
    });
  }
}