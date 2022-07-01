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
import 'package:rokwire_plugin/service/app_datetime.dart';
import 'package:illinois/model/IlliniCash.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:illinois/service/IlliniCash.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:illinois/ui/settings/SettingsAddIlliniCashPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/ui/widgets/section.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;

import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/service/styles.dart';

class SettingsIlliniCashPanel extends StatefulWidget {

  static final String routeName = 'settings_illini_cash';

  final ScrollController? scrollController;

  SettingsIlliniCashPanel({this.scrollController});

  @override
  _SettingsIlliniCashPanelState createState() => _SettingsIlliniCashPanelState();

  static void present(BuildContext context) {
    if (Connectivity().isOffline) {
      AppAlert.showOfflineMessage(context, Localization().getStringEx('panel.browse.label.offline.illini_cash', 'Illini Cash is not available while offline.'));
    }
    else if (!Auth2().isOidcLoggedIn) {
      AppAlert.showMessage(context, Localization().getStringEx('panel.browse.label.logged_out.illini_cash', 'You need to be logged in to access Illini Cash.'));
    }
    else {
      Navigator.push(context, CupertinoPageRoute(settings: RouteSettings(name: SettingsIlliniCashPanel.routeName), builder: (context) => SettingsIlliniCashPanel()));
    }
  }
}

class _SettingsIlliniCashPanelState extends State<SettingsIlliniCashPanel> implements NotificationsListener {

  DateTime? _startDate;
  DateTime? _endDate;
  List<IlliniCashTransaction>? _transactions;
  bool _transactionHistoryVisible = false;
  bool _transactionsLoading = false;
  bool _authLoading = false;
  bool _illiniCashLoading = false;

  _SettingsIlliniCashPanelState();

  @override
  void initState() {
    NotificationService().subscribe(this, [
      IlliniCash.notifyPaymentSuccess,
      IlliniCash.notifyBallanceUpdated,
    ]);

    _loadBallance();
    _loadThisMonthHistory();
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  void _loadTransactions() {
    _transactionHistoryVisible = true;
    _showTransactionsProgress(true);
    IlliniCash().loadTransactionHistory(_startDate, _endDate).then((
        transactions) => _onTransactionsLoaded(transactions));
  }

  void _loadBallance() {
    _illiniCashLoading = (IlliniCash().ballance == null);
    IlliniCash().updateBalance().then((_) {
      if (mounted) {
        setState(() {
          _illiniCashLoading = false;
        });
      }
    });
  }

  void _loadThisMonthHistory() {
    if(Auth2().isOidcLoggedIn) {
      Analytics().logSelect(target: "This Month");
      DateTime now = DateTime.now();
      DateTime lastMonth = now.subtract(Duration(
        days: 30,
      ));
      _startDate = lastMonth;
      _endDate = now;
      _loadTransactions();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildScaffoldBody(),
      backgroundColor: Styles().colors!.background,
      bottomNavigationBar: widget.scrollController == null
          ? uiuc.TabBar()
          : Container(height: 0,),
    );
  }

  Widget _buildScaffoldBody() {
    if (_authLoading) {
      return Center(child: CircularProgressIndicator(),);
    }
    return CustomScrollView(
      controller: widget.scrollController,
      slivers: <Widget>[
        SliverHeaderBar(
          leadingAsset: widget.scrollController == null
              ? 'images/chevron-left-white.png'
              : 'images/chevron-left-blue.png',
          title: Localization().getStringEx('panel.settings.illini_cash.label.title','Illini Cash'),
          textColor: widget.scrollController == null
              ? Styles().colors!.white
              : Styles().colors!.fillColorPrimary,
        ),
        SliverList(
          delegate: SliverChildListDelegate([
            Container(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _buildPrivacyAlertSection(),
                  _buildBalanceSection(),
                  _buildAddIlliniCashSection(),
                  Auth2().isOidcLoggedIn ? _buildHistorySection() : Container(),
                ],
              ),
            ),
          ]),
        )
      ],

    );
  }

  Widget _buildBalanceSection() {
    return Container(
        color: Colors.white,
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(child: Stack(
                    children: <Widget>[
                      VerticalTitleValueSection(
                        title: Localization().getStringEx(
                            'panel.settings.illini_cash.label.current_balance',
                            'Current Illini Cash Balance'),
                        value: _illiniCashLoading ? "" : (IlliniCash().ballance?.balanceDisplayText ?? "\$0.00"),
                      ),
                      _illiniCashLoading ? Column(
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Center(child: CircularProgressIndicator(),),
                          )
                        ],
                      ) : Container(),
                    ],
                  )),
                  ((!Auth2().isOidcLoggedIn) && _canSignIn) ? Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(left: 20, right: 20, bottom: 16),
                      child: RoundedButton(
                        label: Localization().getStringEx(
                            'panel.settings.illini_cash.button.log_in.title',
                            'Sign in to View'),
                        hint: Localization().getStringEx(
                            'panel.settings.illini_cash.button.log_in.hint', ''),
                        backgroundColor: Styles().colors!.white,
                        fontSize: 16.0,
                        textColor: Styles().colors!.fillColorPrimary,
                        textAlign: TextAlign.center,
                        borderColor: Styles().colors!.fillColorSecondary,
                        onTap: _onTapLogIn,
                      ),
                    ),
                  ) : Container(),
                ],
              ),
            ],
        )
    );
  }

  Widget _buildAddIlliniCashSection() {
    return Container(
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildSettingsHeader(Localization().getStringEx("panel.settings.illini_cash.label.buy_illini_cash", "Buy Illini Cash"),
                'images/icon-schedule.png'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                Localization().getStringEx("panel.settings.illini_cash.label.for_yourself_or", "For yourself or someone else"),
                style: TextStyle(
                    color: Styles().colors!.fillColorPrimary,
                    fontSize: 14,
                    fontFamily: Styles().fontFamilies!.regular
                ),
              ),
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
                      backgroundColor: Styles().colors!.white,
                      fontSize: 16.0,
                      textColor: Styles().colors!.fillColorPrimary,
                      borderColor: Styles().colors!.fillColorSecondary,
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

  Widget _buildHistorySection(){
    return Column(
      children: <Widget>[
        _buildSettingsHeader(Localization().getStringEx(
            "panel.settings.illini_cash.label.history", "History"), 'images/icon-schedule.png'),
        _buildBalanceTableRow(),
        _buildBalancePeriodViewPicker(),

      ],
    );
  }

  Widget _buildSettingsHeader(String? title, String iconSrc){
    return Semantics(
      label: title,
      header: true,
      excludeSemantics: true,
      child: Container(
        color: Styles().colors!.fillColorPrimaryVariant,
        height: 56,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: <Widget>[
                Image.asset(StringUtils.ensureNotEmpty(iconSrc, defaultValue: 'images/icon-settings.png')),
                Padding(
                  padding: EdgeInsets.only(left: 12),
                  child: Text(
                    StringUtils.ensureNotEmpty(title),
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBalancePeriodViewPicker() {
    if (!Auth2().isOidcLoggedIn) {
      return Container();
    }
    return Padding(
      padding: EdgeInsets.only(left: 16, right: 16, top: 20, bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              Localization().getStringEx("panel.settings.illini_cash.label.custom_period", "Custom Period"),
              style: TextStyle(
                  color: Styles().colors!.fillColorPrimary,
                  fontSize: 16,
                  fontFamily: Styles().fontFamilies!.regular
              )
            ),
          ),
          Padding(
            padding: EdgeInsets.only(bottom: 16), child: Row(children: <Widget>[
            _DateLabel(label: Localization().getStringEx('panel.settings.illini_cash.label.start_date', 'Start Date'),),
            Container(width: 8,),
            Expanded(child: _DateValue(title: StringUtils.ensureNotEmpty(
                _getFormattedDate(_startDate)),
                label: Localization().getStringEx('panel.settings.illini_cash.button.start_date.title', 'Start Date'),
                hint: Localization().getStringEx('panel.settings.illini_cash.button.start_date.hint', ''),
                onTap: _onStartDateTap,))
          ],),),
          Padding(
            padding: EdgeInsets.only(bottom: 16), child: Row(children: <Widget>[
            _DateLabel(label: Localization().getStringEx('panel.settings.illini_cash.label.end_date', 'End Date'),),
            Container(width: 8,),
            Expanded(child: _DateValue(
              title: StringUtils.ensureNotEmpty(
                  _getFormattedDate(_endDate)),
              label: Localization().getStringEx('panel.settings.illini_cash.button.end_date.title', 'End Date'),
              hint: Localization().getStringEx('panel.settings.illini_cash.button.end_date.hint', ''),
              onTap: _onEndDateTap,))
          ],),),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: <Widget>[
            Expanded(child: RoundedButton(
              textColor: Styles().colors!.fillColorPrimary,
              label: Localization().getStringEx('panel.settings.illini_cash.button.view_history.title', 'View History'),
              hint: Localization().getStringEx('panel.settings.illini_cash.button.view_history.hint', ''),
              backgroundColor: Colors.white,
              borderColor: Styles().colors!.fillColorSecondary,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              fontSize: 16,
              onTap: _onTapViewHistory,)),
          ],)
      ],),);
  }

  Widget _buildBalanceTableRow() {
    if (!_transactionHistoryVisible) {
      return Container();
    }
    if (_transactionsLoading) {
      return Center(child: Padding(padding: EdgeInsets.only(bottom: 20),
        child: CircularProgressIndicator(),),);
    }
    if (_startDate == null || _endDate == null ||
        _startDate!.isAfter(_endDate!)) {
      String text = Localization().getStringEx(
          'panel.settings.illini_cash.transactions.message.start_end_validation.text',
          'Start date must be before end date');
      return Semantics(
        label: text, hint: Localization().getStringEx(
          'panel.settings.illini_cash.transactions.message.start_end_validation.hint',
          ''), excludeSemantics: true, child: Center(child: Padding(
        padding: EdgeInsets.only(left: 40, right: 40, bottom: 20),
        child: Text(text,
          style: TextStyle(color: Styles().colors!.fillColorPrimary,
              fontSize: 16,
              fontFamily: Styles().fontFamilies!.bold),),),),);
    }
    if (_transactions == null || _transactions!.isEmpty) {
      String text = Localization().getStringEx(
          'panel.settings.illini_cash.transactions.message.no_transactions.text',
          'There is no transactions for the selected period');
      return Semantics(label: text, hint: Localization().getStringEx(
          'panel.settings.illini_cash.transactions.message.no_transactions.hint',
          ''), excludeSemantics: true, child: Center(child: Padding(
        padding: EdgeInsets.only(left: 40, right: 40, bottom: 20),
        child: Text(text,
          textAlign: TextAlign.center,
          style: TextStyle(color: Styles().colors!.fillColorPrimary,
              fontSize: 14,
              fontFamily: Styles().fontFamilies!.regular),),),),);
    }
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
    _transactions!.forEach((IlliniCashTransaction? balance){
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
    return Row(
    children:[
      Expanded(child:
        SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child:
      Container(
        child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children:[
        Container(
            width: (dateLenght*textSize) + 20,
            child:
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
            children: dateWidgets),),
        Container(
            width: locationLenght*textSize+ 20,
            child:
            Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: locationWidgets)),
        Container(
            width: descriptionLenght*textSize+ 16/*the padding*/,
            child:
            Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: descriptionWidgets)),
        ]),
      ),
      )),
      Container(
      width: amountLenght*textSize+ 16/*the padding*/,
      child:Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: amountViewWidgets))
    ]);
  }

  Widget _buildBalanceTableHeaderItem(String text){
      return _buildBalanceTableItem(text: text, backColor: Styles().colors!.fillColorPrimaryVariant,
          showBorder: false,
          textStyle: TextStyle(
              fontFamily: Styles().fontFamilies!.regular,
              color: Styles().colors!.white,
              fontWeight: FontWeight.bold,
              fontSize: 14));
  }

  Widget _buildBalanceTableItem({required String text, bool showBorder = true, Color? backColor, TextStyle? textStyle}) {
    return
           Container(
             width: double.infinity,
             height: 40,
             alignment: Alignment.centerLeft,
             decoration: BoxDecoration(
               color: backColor ?? Styles().colors!.background,
               border: showBorder?
               Border.all(
                   color: Styles().colors!.surfaceAccent!,
                   width: 1,
                   style: BorderStyle.solid) :
               Border.all(color: backColor ?? Styles().colors!.background!,width: 0)
             ),
              child: Padding(
                  padding: EdgeInsets.all(8),
                  child:
                  Text(text,
                    maxLines: 1,
                    style: textStyle!=null? textStyle:
                    TextStyle(
                        fontFamily: Styles().fontFamilies!.regular,
                        color: Styles().colors!.textBackground,
                        fontSize: 14),),

              )
    );
  }

  Widget _buildAmountView(String balance){
    return _buildBalanceTableItem(text: balance, backColor: Styles().colors!.background,
        textStyle: TextStyle(
            fontFamily: Styles().fontFamilies!.bold,
            color: Styles().colors!.textBackground,
            fontSize: 14));
  }

  Widget _buildPrivacyAlertSection() {
    if(_canSignIn){
      return Container();
    }

    final String iconMacro = '{{privacy_level_icon}}';
    String privacyMsg = Localization().getStringEx('panel.settings.illini_cash.label.privacy_alert.msg', "With your privacy level at $iconMacro , you can't sign in. To view your balance, you must set your privacy level to 4 and sign in.");
    int iconMacroPosition = privacyMsg.indexOf(iconMacro);
    String privacyMsgStart = (0 < iconMacroPosition) ? privacyMsg.substring(0, iconMacroPosition) : '';
    String privacyMsgEnd = ((0 < iconMacroPosition) && (iconMacroPosition < privacyMsg.length)) ? privacyMsg.substring(iconMacroPosition + iconMacro.length) : '';

    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: RichText(text: TextSpan(
        style: TextStyle(
          color: Styles().colors!.fillColorPrimary,
          fontFamily: Styles().fontFamilies!.semiBold,
          fontSize: 24,
        ),
        children: [
          TextSpan(text: privacyMsgStart),
          WidgetSpan(alignment: PlaceholderAlignment.middle, child: _buildPrivacyLevelIcon()),
          TextSpan(text: privacyMsgEnd)
        ])));
  }

  Widget _buildPrivacyLevelIcon() {
    String privacyLevel = Auth2().prefs?.privacyLevel?.toString() ?? '';
    return Container(height: 40, width: 40, alignment: Alignment.center, decoration: BoxDecoration(border: Border.all(color: Styles().colors!.fillColorPrimary!, width: 2), color: Styles().colors!.white, borderRadius: BorderRadius.all(Radius.circular(100)),), child:
      Container(height: 32, width: 32, alignment: Alignment.center, decoration: BoxDecoration(border: Border.all(color: Styles().colors!.fillColorSecondary!, width: 2), color: Styles().colors!.white, borderRadius: BorderRadius.all(Radius.circular(100)),), child:
        Text(privacyLevel, style: TextStyle(fontFamily: Styles().fontFamilies!.extraBold, fontSize: 18, color: Styles().colors!.fillColorPrimary))
      ),
    );
  }

  void _onTransactionsLoaded(List<IlliniCashTransaction>? transactions) {
    _showTransactionsProgress(false, changeState: false);
    if (mounted) {
      setState(() {
        _transactions = transactions;
      });
    }
  }

  void _onTapViewHistory() {
    Analytics().logSelect(target: "View History");
    _loadTransactions();
  }

  void _showTransactionsProgress(bool loading, {bool changeState = true}) {
    _transactionsLoading = loading;
    if (changeState) {
      if (mounted) {
        setState(() {});
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
          return SettingsAddIlliniCashPanel(scrollController: widget.scrollController,);
        }
    ));
  }

  void _onTapLogIn() {
    Analytics().logSelect(target: "Log in");
    if (_authLoading != true) {
      setState(() { _authLoading = true; });
      Auth2().authenticateWithOidc().then((Auth2OidcAuthenticateResult? result) {
        if (mounted) {
          setState(() { _authLoading = false; });
          if (result != Auth2OidcAuthenticateResult.succeeded) {
            AppAlert.showDialogResult(context, Localization().getStringEx("logic.general.login_failed", "Unable to login. Please try again later."));
          }
        }
      });
    }
  }

  void _onStartDateTap() {
    Analytics().logSelect(target: "Start date");
    DateTime initialDate = _startDate ?? DateTime.now();
    DateTime firstDate =
    DateTime.fromMillisecondsSinceEpoch(initialDate.millisecondsSinceEpoch)
        .add(Duration(days: -365));
    DateTime lastDate =
    DateTime.fromMillisecondsSinceEpoch(initialDate.millisecondsSinceEpoch)
        .add(Duration(days: 365));
    showDatePicker(
      context: context,
      firstDate: firstDate,
      lastDate: lastDate,
      initialDate: initialDate,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light(),
          child: child!,
        );
      },
    ).then((selectedDateTime) => _onStartDateChanged(selectedDateTime));
  }

  void _onStartDateChanged(DateTime? startDate) {
    if(mounted) {
      setState(() {
        _startDate = startDate;
      });
    }
  }

  void _onEndDateTap() {
    Analytics().logSelect(target: "End date");
    DateTime initialDate = _endDate ?? DateTime.now();
    DateTime firstDate =
    DateTime.fromMillisecondsSinceEpoch(initialDate.millisecondsSinceEpoch)
        .add(Duration(days: -365));
    DateTime lastDate =
    DateTime.fromMillisecondsSinceEpoch(initialDate.millisecondsSinceEpoch)
        .add(Duration(days: 365));
    showDatePicker(
      context: context,
      firstDate: firstDate,
      lastDate: lastDate,
      initialDate: initialDate,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light(),
          child: child!,
        );
      },
    ).then((selectedDateTime) => _onEndDateChanged(selectedDateTime));
  }

  void _onEndDateChanged(DateTime? endDate) {
    if(mounted) {
      setState(() {
        _endDate = endDate;
      });
    }
  }

  String? _getFormattedDate(DateTime? date) {
    return AppDateTime().formatDateTime(
        date, format: 'MM/dd/yyyy');
  }

  bool get _canSignIn{
    return Auth2().privacyMatch(4);
  }

  // NotificationsListener
  
  @override
  void onNotification(String name, dynamic param) {
    if (name == IlliniCash.notifyPaymentSuccess) {
      _loadThisMonthHistory();
    }
    else if (name == IlliniCash.notifyBallanceUpdated) {
      setState(() {});
      _loadThisMonthHistory();
    }
  }
}

class _DateLabel extends StatelessWidget {
  final String? label;

  _DateLabel({this.label});

  @override
  Widget build(BuildContext context) {
    return Container(width: 70,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Text(label!, style: TextStyle(color: Styles().colors!.textBackground,
            fontSize: 16,
            fontFamily: Styles().fontFamilies!.regular),),
        Container(height: 2, color: Styles().colors!.surfaceAccent,)
      ],),);
  }
}

class _DateValue extends StatelessWidget {
  final String? title;
  final String? label;
  final String? hint;
  final GestureTapCallback? onTap;

  _DateValue({this.title, this.label, this.hint, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(label: (0 < title!.length) ? title : label, hint: hint, button: true, excludeSemantics: true, child:InkWell(onTap: onTap, child: Column(children: <Widget>[
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(title!, style: TextStyle(
              color: Styles().colors!.fillColorPrimary,
              fontSize: 16,
              fontFamily: Styles().fontFamilies!.bold),),
          Image.asset('images/icon-down.png')
        ],), Container(height: 2, color: Styles().colors!.fillColorSecondary,)
    ],),),);
  }
}

