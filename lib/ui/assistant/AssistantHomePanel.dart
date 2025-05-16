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
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/ui/assistant/AssistantConversationContentWidget.dart';
import 'package:illinois/ui/assistant/AssistantFaqsContentWidget.dart';
import 'package:illinois/ui/assistant/AssistantProvidersConversationContentWidget.dart';
import 'package:illinois/ui/profile/ProfileHomePanel.dart';
import 'package:illinois/ui/settings/SettingsHomePanel.dart';
import 'package:illinois/ui/widgets/LinkButton.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/ribbon_button.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';

enum AssistantContentType { google, grok, perplexity, openai, all, faqs }

class AssistantHomePanel extends StatefulWidget {
  final AssistantContentType? contentType;

  AssistantHomePanel._({this.contentType});

  @override
  _AssistantHomePanelState createState() => _AssistantHomePanelState();

  static String pageRuntimeTypeName = 'AssistantHomePanel';

  static void present(BuildContext context, {AssistantContentType? content}) {
    if (Connectivity().isOffline) {
      AppAlert.showOfflineMessage(
          context, Localization().getStringEx('panel.assistant.offline.label', 'The Illinois Assistant is not available while offline.'));
    } else if (!Auth2().isOidcLoggedIn) {
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
            return AssistantHomePanel._(contentType: content);
          });
    }
  }
}

class _AssistantHomePanelState extends State<AssistantHomePanel> with NotificationsListener {
  late List<AssistantContentType> _contentTypes;
  AssistantContentType? _selectedContentType;
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

    _selectedContentType = _ensureContentType(widget.contentType, contentTypes: _contentTypes) ??
      _ensureContentType(Storage()._assistantContentType, contentTypes: _contentTypes) ??
      (_contentTypes.isNotEmpty ? _contentTypes.first : null);

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
    bool clearAllVisible = (_selectedContentType != null) && (_selectedContentType != AssistantContentType.all) && (_selectedContentType != AssistantContentType.faqs);
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
            Visibility(visible: clearAllVisible, child: LinkButton(onTap: _onTapClearAll, title: Localization().getStringEx('panel.assistant.clear_all.label', 'Clear All'), fontSize: 14)),
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
                          label: _selectedContentType?.displayTitle ?? '',
                          onTap: _onTapContentSwitch))),
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
    for (AssistantContentType contentType in _contentTypes) {
      contentList.add(RibbonButton(
        backgroundColor: Styles().colors.white,
        border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
        textStyle: Styles().textStyles.getTextStyle((_selectedContentType == contentType) ? 'widget.button.title.medium.fat.secondary' : 'widget.button.title.medium.fat'),
        rightIconKey: (_selectedContentType == contentType) ? 'check-accent' : null,
        label: contentType.displayTitle,
        onTap: () => _onTapContentItem(contentType)
      ));
    }
    return Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: SingleChildScrollView(child: Column(children: contentList)));
  }

  void _onTapContentItem(AssistantContentType contentItem) {
    Analytics().logSelect(target: contentItem.toString(), source: widget.runtimeType.toString());
    setState(() {
      Storage()._assistantContentType = _selectedContentType = contentItem;
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
    List<AssistantContentType> contentTypes = _buildAssistantContentTypes();
    if (!DeepCollectionEquality().equals(_contentTypes, contentTypes) && mounted) {
      setState(() {
        _contentTypes = contentTypes;
        _contentValuesVisible = false;
        if (!_contentTypes.contains(_selectedContentType)) {
          Storage()._assistantContentType = _selectedContentType = _contentTypes.isNotEmpty ? _contentTypes.first : null;
        }
      });
    }
  }

  static List<AssistantContentType> _buildAssistantContentTypes() {
    List<AssistantContentType> contentTypes = <AssistantContentType>[];
    List<AssistantProvider>? availableProviders = Assistant().providers;
    if (availableProviders != null) {
      for (AssistantProvider provider in availableProviders) {
        contentTypes.add(AssistantContentTypeImpl.fromProvider(provider));
      }
      contentTypes.sortAlphabetical();

      int numberOfProviders = contentTypes.length;
      if ((numberOfProviders > 1) && FlexUI().isAllAssistantsAvailable) {
        contentTypes.add(AssistantContentType.all);
      }
      if ((numberOfProviders > 0) && FlexUI().isAssistantFaqsAvailable) {
        contentTypes.add(AssistantContentType.faqs);
      }
    }
    return contentTypes;
  }

  static AssistantContentType? _ensureContentType(AssistantContentType? contentType, { List<AssistantContentType>? contentTypes }) =>
    ((contentType != null) && (contentTypes?.contains(contentType) != false)) ? contentType : null;

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

  double? get _contentHeight {
    RenderObject? pageRenderBox = _pageKey.currentContext?.findRenderObject();
    double? pageHeight = ((pageRenderBox is RenderBox) && pageRenderBox.hasSize) ? pageRenderBox.size.height : null;

    RenderObject? pageHeaderRenderBox = _pageHeadingKey.currentContext?.findRenderObject();
    double? pageHeaderHeight = ((pageHeaderRenderBox is RenderBox) && pageHeaderRenderBox.hasSize) ? pageHeaderRenderBox.size.height : null;

    return ((pageHeight != null) && (pageHeaderHeight != null)) ? (pageHeight - pageHeaderHeight) : null;
  }

  Widget? get _contentWidget {
    switch (_selectedContentType) {
      case AssistantContentType.google: return AssistantConversationContentWidget(shouldClearAllMessages: _clearMessagesNotifier.stream, provider: _selectedProvider);
      case AssistantContentType.grok: return AssistantConversationContentWidget(shouldClearAllMessages: _clearMessagesNotifier.stream, provider: _selectedProvider);
      case AssistantContentType.perplexity: return AssistantConversationContentWidget(shouldClearAllMessages: _clearMessagesNotifier.stream, provider: _selectedProvider);
      case AssistantContentType.openai: return AssistantConversationContentWidget(shouldClearAllMessages: _clearMessagesNotifier.stream, provider: _selectedProvider);
      case AssistantContentType.all: return AssistantProvidersConversationContentWidget();
      case AssistantContentType.faqs: return AssistantFaqsContentWidget();
      default: return null;
    }
  }

  AssistantProvider? get _selectedProvider => _selectedContentType?.provider;
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
      SettingsHomePanel.present(context, content: SettingsContentType.privacy);
      return true;
    } else if (url == _signInUrl) {
      Analytics().logSelect(target: 'Profile: Sign In / Sign Out', source: widget.runtimeType.toString());
      Navigator.of(context).pop();
      ProfileHomePanel.present(context, contentType: ProfileContentType.login);
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
            'The Illinois Assistant is a search tool that helps you learn more about official university resources. While the feature aims to provide useful information, responses may occasionally be incomplete or inaccurate. **You are responsible for confirming information before taking action based on it.**\n\nBy continuing, you acknowledge that the Illinois Assistant is a supplemental tool and not a substitute for official university sources.');
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
                                    p: Styles().textStyles.getTextStyle('widget.detail.small'),
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

extension AssistantContentTypeImpl on AssistantContentType {
  String get displayTitle => displayTitleLng();
  String get displayTitleEn => displayTitleLng('en');

  String displayTitleLng([String? language]) {
    switch (this) {
      case AssistantContentType.google: return Localization().getStringEx('panel.assistant.content.conversation.google.label', 'Ask the Google Assistant');
      case AssistantContentType.grok: return Localization().getStringEx('panel.assistant.content.conversation.grok.label', 'Ask the Grok Assistant');
      case AssistantContentType.perplexity: return Localization().getStringEx('panel.assistant.content.conversation.perplexity.label', 'Ask the Perplexity Assistant');
      case AssistantContentType.openai: return Localization().getStringEx('panel.assistant.content.conversation.openai.label', 'Ask the Open AI Assistant');
      case AssistantContentType.all: return Localization().getStringEx('panel.assistant.content.conversation.all.label', 'Use All Assistants',);
      case AssistantContentType.faqs: return Localization().getStringEx('panel.assistant.content.faqs.label', 'Illinois Assistant FAQs');
    }
  }

  String get jsonString {
    switch (this) {
      case AssistantContentType.google: return 'google';
      case AssistantContentType.grok: return 'grok';
      case AssistantContentType.perplexity: return 'perplexity';
      case AssistantContentType.openai: return 'openai';
      case AssistantContentType.all: return 'all';
      case AssistantContentType.faqs: return 'faqs';
    }
  }

  static AssistantContentType? fromJsonString(String? value) {
    switch (value) {
      case 'google': return AssistantContentType.google;
      case 'grok': return AssistantContentType.grok;
      case 'perplexity': return AssistantContentType.perplexity;
      case 'openai': return AssistantContentType.openai;
      case 'all': return AssistantContentType.all;
      case 'faqs': return AssistantContentType.faqs;
      default: return null;
    }
  }

  static AssistantContentType fromProvider(AssistantProvider provider) {
    switch (provider) {
      case AssistantProvider.google: return AssistantContentType.google;
      case AssistantProvider.grok: return AssistantContentType.grok;
      case AssistantProvider.perplexity: return AssistantContentType.perplexity;
      case AssistantProvider.openai: return AssistantContentType.openai;
    }
  }

  AssistantProvider? get provider {
    switch (this) {
      case AssistantContentType.google: return AssistantProvider.google;
      case AssistantContentType.grok: return AssistantProvider.grok;
      case AssistantContentType.perplexity: return AssistantProvider.perplexity;
      case AssistantContentType.openai: return AssistantProvider.openai;
      default: return null;
    }
  }
}

extension _AssistantContentTypeList on List<AssistantContentType> {
  void sortAlphabetical() => sort((AssistantContentType t1, AssistantContentType t2) => t1.displayTitle.compareTo(t2.displayTitle));
}

extension _StorageAssistantExt on Storage {
  AssistantContentType? get _assistantContentType => AssistantContentTypeImpl.fromJsonString(assistantContentType);
  set _assistantContentType(AssistantContentType? value) => assistantContentType = value?.jsonString;
}
