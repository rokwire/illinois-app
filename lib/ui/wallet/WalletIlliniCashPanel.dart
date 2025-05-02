/*
 * Copyright 2020 Board of Trustees of the University of Illinois.
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

import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/ui/wallet/WalletHomePanel.dart';
import 'package:illinois/model/IlliniCash.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:illinois/service/IlliniCash.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:illinois/ui/wallet/WalletAddIlliniCashPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/ui/widgets/section.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;

import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:url_launcher/url_launcher.dart';

class WalletIlliniCashPanel extends StatelessWidget {

  static final String routeName = 'settings_illini_cash';

  WalletIlliniCashPanel({super.key});

  static void present(BuildContext context) {
    if (Connectivity().isOffline) {
      AppAlert.showOfflineMessage(context, Localization().getStringEx('panel.browse.label.offline.illini_cash', 'Illini Cash is not available while offline.'));
    }
    else if (!Auth2().isOidcLoggedIn) {
      AppAlert.showLoggedOutFeatureNAMessage(context, Localization().getStringEx('generic.app.feature.illini_cash', 'Illini Cash'));
    }
    else {
      Navigator.push(context, CupertinoPageRoute(settings: RouteSettings(name: WalletIlliniCashPanel.routeName), builder: (context) => WalletIlliniCashPanel()));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: CustomScrollView(slivers: <Widget>[
      SliverHeaderBar(
        leadingIconKey: 'caret-left',
        title: Localization().getStringEx('panel.settings.illini_cash.label.title','Illini Cash'),
        textStyle:  Styles().textStyles.getTextStyle("widget.heading.regular.extra_fat.light"),
      ),
      SliverList(delegate: SliverChildListDelegate([
        WalletIlliniCashContentWidget(),
      ]),),
    ],),
    backgroundColor: Styles().colors.background,
    bottomNavigationBar: uiuc.TabBar(),
  );
}

class WalletIlliniCashContentWidget extends StatefulWidget with WalletHomeContentWidget {

  final double headerHeight;
  WalletIlliniCashContentWidget({super.key, this.headerHeight = 0});

  @override
  _WalletIlliniCashContentWidgetState createState() => _WalletIlliniCashContentWidgetState();

  @override
  Color get backgroundColor => Styles().colors.fillColorPrimaryVariant;
}

class _WalletIlliniCashContentWidgetState extends State<WalletIlliniCashContentWidget> implements NotificationsListener {

  List<IlliniCashTransaction>? _transactions;
  bool _transactionHistoryVisible = false;
  bool _transactionsLoading = false;
  bool _authLoading = false;
  bool _illiniCashLoading = false;
  final int _historyNumberOfDays = 14;

  bool get _isLoggedIn => Auth2().isOidcLoggedIn;
  bool get _canLogin => FlexUI().isAuthenticationAvailable;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      IlliniCash.notifyPaymentSuccess,
      IlliniCash.notifyBallanceUpdated,
      IlliniCash.notifyEligibilityUpdated,
    ]);

    _illiniCashLoading = (IlliniCash().ballance == null);
    IlliniCash().updateBalance().then((_) {
      if (mounted) {
        setState(() {
          _illiniCashLoading = false;
        });
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == IlliniCash.notifyBallanceUpdated) {
      setState(() {});
      _updateHistory();
    }
    else if (name == IlliniCash.notifyEligibilityUpdated) {
      setState(() {});
    }
    else if (name == IlliniCash.notifyPaymentSuccess) {
      _updateHistory();
    }
  }

  @override
  Widget build(BuildContext context) =>
    _authLoading ? _buildLoadingStatus() : _buildContentSection();

  Widget _buildContentSection() =>
    Container(color: widget.backgroundColor, child:
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[
        if (0 < widget.headerHeight)
          _buildContentHeader(),
        if (!_canLogin)
          _buildPrivacyAlertSection(),
        if (_isLoggedIn || _canLogin)
          _buildBalanceSection(),
        _buildAddIlliniCashSection(),
        if (_isLoggedIn)
          _buildHistorySection(),
      ],),
    );

  Widget _buildBalanceSection() {
    Widget contentWidget;
    if (_illiniCashLoading) {
      contentWidget = VerticalTitleValueSection(title: '', value: '',);
    }
    else if (IlliniCash().eligibility?.eligible == false) {
      String title = Localization().getStringEx('panel.settings.illini_cash.label.ineligible', 'Ineligible');
      String? status = StringUtils.isNotEmpty(IlliniCash().eligibility?.accountStatus) ? IlliniCash().eligibility?.accountStatus :
        Localization().getStringEx('panel.settings.illini_cash.label.ineligible_status', 'You are not eligibile for Illini Cash');

      contentWidget = VerticalTitleValueSection(
        title: title,
        titleTextStyle: Styles().textStyles.getTextStyle("widget.title.dark.large.extra_fat"),
        value: status,
        valueTextStyle: Styles().textStyles.getTextStyle("widget.detail.medium"),
      );
    }
    else {
      contentWidget = VerticalTitleValueSection(
        title: Localization().getStringEx('panel.settings.illini_cash.label.current_balance', 'Current Illini Cash Balance'),
        value: IlliniCash().ballance?.balanceDisplayText ?? "\$0.00",
      );
    }

    return Container(color: Colors.white, child:
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Row(children: <Widget>[
          Expanded(flex: 60, child:
            Stack(children: <Widget>[
              contentWidget,
              _illiniCashLoading ? Column(children: <Widget>[
                  Padding(padding: const EdgeInsets.all(16.0), child:
                    Center(child: CircularProgressIndicator(),),
                  )
              ],) : Container(),
            ],)
          ),
          (!_isLoggedIn && _canLogin) ? Expanded(flex: 40, child:
            Padding(padding: EdgeInsets.only(left: 20, right: 20, bottom: 16, top: 16), child:
              RoundedButton(
                label: Localization().getStringEx('panel.settings.illini_cash.button.log_in.title', 'Sign in to View'),
                hint: Localization().getStringEx('panel.settings.illini_cash.button.log_in.hint', ''),
                textStyle: Styles().textStyles.getTextStyle("widget.button.title.enabled"),
                backgroundColor: Styles().colors.surface,
                textAlign: TextAlign.center,
                borderColor: Styles().colors.fillColorSecondary,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                onTap: _onTapLogIn,
              ),
            ),
          ) : Container(),
        ],),
      ],)
    );
  }

  Widget _buildAddIlliniCashSection() {
    final String servicesUrlMacro = '{{services_url}}';
    final String whiteSpaceMacro = '{{white_space}}';
    final String externalLinIconMacro = '{{external_link_icon}}';
    String contentHtml = Localization().getStringEx("panel.settings.illini_cash.label.for_yourself_or", "Use Illini Cash to purchase food, books, printing, and <a href='{{services_url}}'>other selected services</a>{{white_space}}<img src='asset:{{external_link_icon}}' alt=''/> with your Illinois app or Illini ID.");
    contentHtml = contentHtml.replaceAll(servicesUrlMacro, Config().illiniCashServicesUrl ?? '');
    contentHtml = contentHtml.replaceAll(externalLinIconMacro, 'images/external-link.png');
    contentHtml = contentHtml.replaceAll(whiteSpaceMacro, '&nbsp;');
    return Container(
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildSettingsHeader(Localization().getStringEx("panel.settings.illini_cash.label.buy_illini_cash", "Buy Illini Cash"), 'cost'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: HtmlWidget(
                  StringUtils.ensureNotEmpty(contentHtml),
                  onTapUrl : (url) {_onTapLink(context, url); return true;},
                  textStyle: Styles().textStyles.getTextStyle("widget.message.small"),
                  customStylesBuilder: (element) => (element.localName == "a") ? {"color": ColorUtils.toHex(Styles().colors.fillColorSecondaryVariant)} : null
              )
            ),
            Row(
              children: <Widget>[
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                    child: RoundedButton(
                      label: Localization().getStringEx(
                          'panel.settings.illini_cash.button.add_cash.title',
                          'Add Illini Cash'),
                      hint: Localization().getStringEx(
                          'panel.settings.illini_cash.button.add_cash.hint', ''),
                      textStyle: Styles().textStyles.getTextStyle("widget.button.title.enabled"),
                      backgroundColor: Styles().colors.surface,
                      borderColor: Styles().colors.fillColorSecondary,
                      onTap: _onAddIlliniCashTapped,
                    ),
                  ),
                )
              ],
            )
          ],
        )
    );
  }

  Widget _buildHistorySection() =>
    Padding(padding: const EdgeInsets.symmetric(vertical: 24), child:
      Column(children: <Widget>[
        Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
          RoundedButton(
            label: Localization().getStringEx('panel.settings.illini_cash.button.view_history.title', 'View History'),
            hint: Localization().getStringEx('panel.settings.illini_cash.button.view_history.hint', ''),
            textStyle: Styles().textStyles.getTextStyle("widget.button.title.enabled"),
            backgroundColor: Colors.white,
            borderColor: Styles().colors.fillColorSecondary,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            onTap: _onTapViewHistory,
          )
        ),
        if (_transactionHistoryVisible)
          Padding(padding: const EdgeInsets.only(top: 24), child:
            Column(children: [
              _buildSettingsHeader(Localization().getStringEx("panel.settings.illini_cash.label.history", "History"), 'history'),
              _buildBalanceTableRow(),
            ],)
          ),
      ],),
    );

  Widget _buildSettingsHeader(String? title, String iconSrc) =>
    Semantics(label: title, header: true, excludeSemantics: true, child:
      Container(color: Styles().colors.fillColorPrimaryVariant, child:
        Align(alignment: Alignment.centerLeft, child:
          Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8), child:
            Row(children: <Widget>[
              Styles().images.getImage(StringUtils.ensureNotEmpty(iconSrc, defaultValue: 'settings'), excludeFromSemantics: true) ?? Container(),
              Expanded(child:
                Padding(padding: EdgeInsets.only(left: 12), child:
                  Text(StringUtils.ensureNotEmpty(title), style: Styles().textStyles.getTextStyle("widget.heading.large"),),
                )
              )
            ],),
          ),
        ),
      ),
    );

  Widget _buildBalanceTableRow() {
    if (_transactionsLoading) {
      return Padding(padding: EdgeInsets.only(top: 8), child:
        Container(color: Styles().colors.surface, child:
          Row(children: [
            Expanded(child:
              Center(child:
                Padding(padding: EdgeInsets.symmetric(vertical: 24), child:
                  SizedBox(width: 24, height: 24, child:
                    CircularProgressIndicator(color: Styles().colors.fillColorSecondary, strokeWidth: 3,)
                  )
                ),
              )
            )
          ],),
        ),
      );
    }
    else if (CollectionUtils.isEmpty(_transactions)) {
      String text = (_transactions != null) ?
        Localization().getStringEx('panel.settings.illini_cash.transactions.message.no_transactions.text', 'There are no transactions for the selected period.').replaceAll('{{number_of_days}}', _historyNumberOfDays.toString()) :
        Localization().getStringEx('panel.settings.illini_cash.transactions.message.failed_transactions.text', 'Failed to load transactions.');
      String hint = (_transactions != null) ?
        Localization().getStringEx('panel.settings.illini_cash.transactions.message.no_transactions.hint', '') :
        Localization().getStringEx('panel.settings.illini_cash.transactions.message.failed_transactions.hint', '');
      return Padding(padding: EdgeInsets.only(top: 8), child:
        Semantics(label: text, hint: hint, excludeSemantics: true, child:
          Container(color: Styles().colors.surface, child:
            Row(children: [
              Expanded(child:
                Center(child:
                  Padding(padding: EdgeInsets.only(left: 32, right: 32, top: 16, bottom: 16), child:
                    Text(text, textAlign: TextAlign.center, style: Styles().textStyles.getTextStyle("widget.message.regular.fat"),),
                  ),
                ),
              ),
            ]),
          ),
        ),
      );
    }
    else {
      String dateHeader = Localization().getStringEx('panel.settings.illini_cash.label.date', 'Date');
      String locationHeader = Localization().getStringEx('panel.settings.illini_cash.label.location', 'Location');
      String descriptionHeader = Localization().getStringEx('panel.settings.illini_cash.label.description', 'Description');
      String amountHeader = Localization().getStringEx('panel.settings.illini_cash.label.amount', 'Amount');

      List<Widget> dateWidgets        =  [];
      List<Widget> locationWidgets    =  [];
      List<Widget> descriptionWidgets =  [];
      List<Widget> amountViewWidgets  =  [];

      //Headers
      dateWidgets.add(_buildBalanceTableHeaderItem(dateHeader));
      locationWidgets.add(_buildBalanceTableHeaderItem(locationHeader));
      descriptionWidgets.add(_buildBalanceTableHeaderItem(descriptionHeader));
      amountViewWidgets.add(_buildBalanceTableHeaderItem(amountHeader));

      //Workaround to make BalanceItem fill the column lane (needed for bordering)
      double textSize = 8;
      int dateLenght = dateHeader.length;
      int locationLenght = locationHeader.length;
      int descriptionLenght = descriptionHeader.length;
      int amountLenght = amountHeader.length;
      _transactions?.forEach((IlliniCashTransaction? balance){

        //date
        String date = balance!.dateString!;
        dateLenght = dateLenght<date.length? date.length : dateLenght;

        //location
        String location = balance.location!;
        locationLenght = locationLenght<location.length? location.length : locationLenght;

        //description
        String description = balance.description!;
        descriptionLenght = descriptionLenght<description.length? description.length : descriptionLenght;

        //balance
        String amount = balance.amount!;
        amountLenght = max(amountLenght + 1, amount.length);

        dateWidgets.add(_buildBalanceTableItem(text: date));
        locationWidgets.add(_buildBalanceTableItem(text: location));
        descriptionWidgets.add(_buildBalanceTableItem(text: description));
        amountViewWidgets.add(_buildAmountView(amount));
      });

      return Row(children:[
        Expanded(child:
          SingleChildScrollView(scrollDirection: Axis.horizontal, child:
            Container(child:
              Row(crossAxisAlignment: CrossAxisAlignment.start, children:[
                Container(width: dateLenght * textSize + 20, child:
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: dateWidgets),
                ),
                Container( width: locationLenght * textSize + 20, child:
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: locationWidgets)
                ),
                Container(width: descriptionLenght * textSize + 16 /*the padding*/, child:
               Column(crossAxisAlignment: CrossAxisAlignment.start, children: descriptionWidgets)),
            ]),
          ),
        )
      ),
      Container(width: amountLenght*textSize + 16/*the padding*/, child:
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: amountViewWidgets))
      ]);
    }
  }

  Widget _buildBalanceTableHeaderItem(String text) =>
    _buildBalanceTableItem(
      text: text,
      backColor: Styles().colors.fillColorPrimaryVariant,
      showBorder: false,
      textStyle: Styles().textStyles.getTextStyle("widget.heading.small.fat")
    );

  Widget _buildBalanceTableItem({required String text, bool showBorder = true, Color? backColor, TextStyle? textStyle}) =>
   Container(
     width: double.infinity,
     height: 40,
     alignment: Alignment.centerLeft,
     decoration: BoxDecoration(
       color: backColor ?? Styles().colors.background,
       border: showBorder?
       Border.all(color: Styles().colors.surfaceAccent, width: 1, style: BorderStyle.solid) :
       Border.all(color: backColor ?? Styles().colors.background,width: 0)
     ), child:
      Padding(padding: EdgeInsets.all(8), child:
        Row(children: <Widget>[
          Expanded(child:
            Text(text,maxLines: 1, style: textStyle ?? Styles().textStyles.getTextStyle("panel.settings.detail.title.small"),),
          ),
        ],),
      )
    );

  Widget _buildAmountView(String balance) =>
    _buildBalanceTableItem(
      text: balance,
      backColor: Styles().colors.background,
      textStyle: Styles().textStyles.getTextStyle("panel.settings.detail.title.small.fat")
    );

  Widget _buildPrivacyAlertSection() {
    final String iconMacro = '{{privacy_level_icon}}';
    String privacyMsg = Localization().getStringEx('panel.settings.illini_cash.label.privacy_alert.msg', "With your privacy level at $iconMacro , you can't sign in. To view your balance, you must set your privacy level to 4 and sign in.");
    int iconMacroPosition = privacyMsg.indexOf(iconMacro);
    String privacyMsgStart = (0 < iconMacroPosition) ? privacyMsg.substring(0, iconMacroPosition) : '';
    String privacyMsgEnd = ((0 < iconMacroPosition) && (iconMacroPosition < privacyMsg.length)) ? privacyMsg.substring(iconMacroPosition + iconMacro.length) : '';

    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: RichText(text: TextSpan(
        style: Styles().textStyles.getTextStyle("panel.settings.heading.title.large"),
        children: [
          TextSpan(text: privacyMsgStart),
          WidgetSpan(alignment: PlaceholderAlignment.middle, child: _buildPrivacyLevelIcon()),
          TextSpan(text: privacyMsgEnd)
        ])));
  }

  Widget _buildPrivacyLevelIcon() {
    String privacyLevel = Auth2().prefs?.privacyLevel?.toString() ?? '';
    return Container(height: 40, width: 40, alignment: Alignment.center, decoration: BoxDecoration(border: Border.all(color: Styles().colors.fillColorPrimary, width: 2), color: Styles().colors.surface, borderRadius: BorderRadius.all(Radius.circular(100)),), child:
      Container(height: 32, width: 32, alignment: Alignment.center, decoration: BoxDecoration(border: Border.all(color: Styles().colors.fillColorSecondary, width: 2), color: Styles().colors.surface, borderRadius: BorderRadius.all(Radius.circular(100)),), child:
        Text(privacyLevel, style:  Styles().textStyles.getTextStyle("widget.title.medium.extra_fat"))
      ),
    );
  }

  Widget _buildContentHeader() =>
    Container(height: widget.headerHeight, color: Styles().colors.fillColorPrimaryVariant,);

  Widget _buildLoadingStatus() {
    return Padding(padding: EdgeInsets.symmetric(vertical: 128, horizontal: 48), child:
      Center(child:
        CircularProgressIndicator(strokeWidth: 2, color: Styles().colors.fillColorSecondary,),
      ),
    );
  }

  void _onTapViewHistory() {
    Analytics().logSelect(target: "View History");
    if (_transactionHistoryVisible == false) {
      setState(() {
        _transactionHistoryVisible = true;
      });
    }
    _updateHistory();
  }

  void _updateHistory() {
    DateTime endDate = DateTime.now();
    DateTime startDate = DateTimeUtils.midnight(endDate.subtract(Duration(days: _historyNumberOfDays))) ?? endDate;

    if (_transactionsLoading == false) {
      setState(() {
        _transactionsLoading = true;
      });
      IlliniCash().loadTransactionHistory(startDate, endDate).then((List<IlliniCashTransaction>? transactions) {
        setStateIfMounted((){
          _transactionsLoading = false;
          _transactions = transactions;
        });
      });
    }

  }

  void _onTapLink(BuildContext context, String? url) {
    Analytics().logAlert(text: "Info", selection: "Other Select Services");
    if (StringUtils.isNotEmpty(url)) {
      Uri? uri = Uri.tryParse(url!);
      if (uri != null) {
        launchUrl(uri);
      }
    }
  }

  void _onAddIlliniCashTapped(){
    Analytics().logSelect(target: "Add Illini Cash");
    Navigator.push(context, CupertinoPageRoute(
        settings: RouteSettings(
            name:"settings_add_illini_cash"
        ),
        builder: (context){
          return WalletAddIlliniCashPanel();
        }
    ));
  }

  void _onTapLogIn() {
    Analytics().logSelect(target: "Log in");
    if (!FlexUI().isAuthenticationAvailable) {
      AppAlert.showAuthenticationNAMessage(context);
    }
    else if (_authLoading != true) {
      setState(() { _authLoading = true; });
      Auth2().authenticateWithOidc().then((Auth2OidcAuthenticateResult? result) {
        if (mounted) {
          setState(() { _authLoading = false; });
          if (result?.status != Auth2OidcAuthenticateResultStatus.succeeded) {
            AppAlert.showDialogResult(context, Localization().getStringEx("logic.general.login_failed", "Unable to login. Please try again later."));
          }
        }
      });
    }
  }
}

