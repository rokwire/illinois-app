/*
 * Copyright 2023 Board of Trustees of the University of Illinois.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/ui/wallet/ICardFaqsContentWidget.dart';
import 'package:illinois/ui/wallet/IDCardContentWidget.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:sprintf/sprintf.dart';

enum ICardContent { i_card, faqs }

class ICardHomeContentPanel extends StatefulWidget {
  final ICardContent? content;

  ICardHomeContentPanel._({this.content});

  @override
  _ICardHomeContentPanelState createState() => _ICardHomeContentPanelState();

  static void present(BuildContext context, {ICardContent? content}) {
    if (!Auth2().isOidcLoggedIn) {
      AppAlert.showMessage(
          context,
          Localization().getStringEx('panel.browse.label.logged_out.illini_id',
              'You need to be logged in with your NetID to access Illini ID. Set your privacy level to 4 or 5 in your Profile. Then find the sign-in prompt under Settings.'));
    } else {
      if (StringUtils.isEmpty(Auth2().authCard?.cardNumber)) {
        AppAlert.showMessage(
            context,
            Localization().getStringEx('panel.browse.label.no_card.illini_id',
                'No Illini ID information. You do not have an active Illini ID. Please visit the ID Center.'));
      } else {
        String? warning;
        int? expirationDays = Auth2().authCard?.expirationIntervalInDays;
        if (expirationDays != null) {
          if (expirationDays <= 0) {
            warning = sprintf(
                Localization().getStringEx('panel.browse.label.expired_card.illini_id',
                    'No Illini ID information. Your Illini ID expired on %s. Please visit the ID Center.'),
                [Auth2().authCard?.expirationDate ?? '']);
          } else if ((0 < expirationDays) && (expirationDays < 30)) {
            warning = sprintf(
                Localization()
                    .getStringEx('panel.browse.label.expiring_card.illini_id', 'Your ID will expire on %s. Please visit the ID Center.'),
                [Auth2().authCard?.expirationDate ?? '']);
          }
        }

        if (warning != null) {
          AppAlert.showMessage(context, warning).then((_) {
            _present(context, content: content);
          });
        } else {
          _present(context, content: content);
        }
      }
    }
  }

  static void _present(BuildContext context, {ICardContent? content}) {
    MediaQueryData mediaQuery = MediaQueryData.fromView(View.of(context));
    double height = mediaQuery.size.height - mediaQuery.viewPadding.top - mediaQuery.viewInsets.top - 16;
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        isDismissible: true,
        clipBehavior: Clip.antiAlias,
        backgroundColor: Styles().colors!.background,
        constraints: BoxConstraints(maxHeight: height, minHeight: height),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
        builder: (context) => ICardHomeContentPanel._(content: content));
  }
}

class _ICardHomeContentPanelState extends State<ICardHomeContentPanel> {
  static ICardContent? _lastSelectedContent;
  late ICardContent _selectedContent;
  bool _contentValuesVisible = false;
  late List<ICardContent> _contentValues;

  @override
  void initState() {
    super.initState();
    _selectedContent = widget.content ?? (_lastSelectedContent ?? ICardContent.i_card);
    _loadContentValues();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Styles().colors?.white,
        body: Column(children: [
          Row(children: [
            Expanded(
                child: Padding(
                    padding: EdgeInsets.only(left: 16),
                    child: Text(Localization().getStringEx('panel.icard.home.title.label', 'Illini ID'),
                        style: Styles().textStyles?.getTextStyle('panel.id_card.heading.title')))),
            Semantics(
                label: Localization().getStringEx('dialog.close.title', 'Close'),
                hint: Localization().getStringEx('dialog.close.hint', ''),
                inMutuallyExclusiveGroup: true,
                button: true,
                child: InkWell(
                    onTap: _onTapClose,
                    child: Container(
                        padding: EdgeInsets.only(left: 8, right: 16, top: 16, bottom: 16),
                        child: Styles().images?.getImage('close-circle', excludeFromSemantics: true))))
          ]),
          Container(color: Styles().colors?.surfaceAccent, height: 1),
          Expanded(child: _buildContent())
        ]));
  }

  Widget _buildContent() {
    return Column(children: <Widget>[
      Expanded(
          child: SingleChildScrollView(
              physics: (_contentValuesVisible ? NeverScrollableScrollPhysics() : null),
              child: Container(
                  color: Styles().colors!.white,
                  child: Stack(children: [
                    _contentWidget,
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Padding(
                          padding: EdgeInsets.only(left: 16, top: 16, right: 16),
                          child: RibbonButton(
                              textStyle: Styles().textStyles?.getTextStyle("widget.button.title.medium.fat.secondary"),
                              backgroundColor: Styles().colors!.white,
                              borderRadius: BorderRadius.all(Radius.circular(5)),
                              border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1),
                              rightIconKey: (_contentValuesVisible ? 'icon-up-orange' : 'icon-down-orange'),
                              label: _getContentLabel(_selectedContent),
                              onTap: _onTapContentDropdown)),
                      _buildContentValuesContainer()
                    ])
                  ]))))
    ]);
  }

  Widget _buildContentValuesContainer() {
    return Visibility(
        visible: _contentValuesVisible,
        child: Container(child: Stack(children: <Widget>[_buildContentDismissLayer(), _buildContentValuesWidget()])));
  }

  Widget _buildContentDismissLayer() {
    return Container(
        child: BlockSemantics(
            child: GestureDetector(
                onTap: () {
                  setState(() {
                    _contentValuesVisible = false;
                  });
                },
                child: Container(color: Styles().colors!.blackTransparent06, height: MediaQuery.of(context).size.height))));
  }

  Widget _buildContentValuesWidget() {
    List<Widget> sectionList = <Widget>[];
    sectionList.add(Container(color: Styles().colors!.fillColorSecondary, height: 2));
    for (ICardContent currentContent in _contentValues) {
      if ((_selectedContent != currentContent)) {
        sectionList.add(_buildContentItem(currentContent));
      }
    }
    return Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: SingleChildScrollView(child: Column(children: sectionList)));
  }

  Widget _buildContentItem(ICardContent contentItem) {
    return RibbonButton(
        backgroundColor: Styles().colors!.white,
        border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1),
        rightIconKey: null,
        label: _getContentLabel(contentItem),
        onTap: () => _onTapContentItem(contentItem));
  }

  void _loadContentValues() {
    _contentValues = <ICardContent>[];
    for (ICardContent iCardContent in ICardContent.values) {
      // Hide FAQs for all
      if (iCardContent != ICardContent.faqs) {
        _contentValues.add(iCardContent);
      }
    }
  }

  void _onTapContentDropdown() {
    if (_contentValues.length > 1) {
      Analytics().logSelect(target: 'Content Dropdown');
      _changeContentValuesVisibility();
    }
  }

  void _onTapContentItem(ICardContent contentItem) {
    Analytics().logSelect(target: "Content Item: ${contentItem.toString()}");
    _selectedContent = _lastSelectedContent = contentItem;
    _changeContentValuesVisibility();
  }

  void _changeContentValuesVisibility() {
    setStateIfMounted(() {
      _contentValuesVisible = !_contentValuesVisible;
    });
  }

  Widget get _contentWidget {
    switch (_selectedContent) {
      case ICardContent.i_card:
        return IDCardContentWidget();
      case ICardContent.faqs:
        return ICardFaqsContentWidget();
    }
  }

  void _onTapClose() {
    Analytics().logSelect(target: 'Close', source: widget.runtimeType.toString());
    Navigator.of(context).pop();
  }

  // Utilities

  String _getContentLabel(ICardContent content) {
    switch (content) {
      case ICardContent.i_card:
        return Localization().getStringEx('panel.icard.home.content.icard.label', 'Illini ID');
      case ICardContent.faqs:
        return Localization().getStringEx('panel.icard.home.content.faqs.label', 'FAQs');
    }
  }
}
