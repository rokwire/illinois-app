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

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/ui/settings/SettingsIlliniCashPanel.dart';
import 'package:rokwire_plugin/service/app_datetime.dart';
import 'package:illinois/model/IlliniCash.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:illinois/service/IlliniCash.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/ui/widgets/section.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/service/styles.dart';

class SettingsMealPlanPanel extends StatefulWidget {

  final ScrollController? scrollController;

  SettingsMealPlanPanel({this.scrollController});

  @override
  _SettingsMealPlanPanelState createState() => _SettingsMealPlanPanelState();

  static void present(BuildContext context) {
    if (Connectivity().isOffline) {
      AppAlert.showOfflineMessage(context, Localization().getStringEx('panel.browse.label.offline.meal_plan', 'University Housing Meal Plan is not available while offline.'));
    }
    else if (!Auth2().isOidcLoggedIn) {
      AppAlert.showMessage(context, Localization().getStringEx('panel.browse.label.logged_out.meal_plan', 'You need to be logged in with your NetID to access University Housing Meal Plan. Set your privacy level to 4 or 5 in your Profile. Then find the sign-in prompt under Settings.'));
    }
    else {
      Navigator.push(context, CupertinoPageRoute(settings: RouteSettings(name: SettingsIlliniCashPanel.routeName), builder: (context) => SettingsMealPlanPanel()));
    }
  }
}

class _SettingsMealPlanPanelState extends State<SettingsMealPlanPanel> implements NotificationsListener {
  bool _authLoading = false;

  bool _illiniCashLoading = false;
  bool _mealPlanTransactionsLoading = false;
  bool _cafeCreditTransactionsLoading = false;

  DateTime? _startDate;
  DateTime? _endDate;
  List<BaseTransaction>? _mealPlanTransactions;
  List<BaseTransaction>? _cafeCreditTransactions;

  _SettingsMealPlanPanelState();

  @override
  void initState() {
    NotificationService().subscribe(this, [
      IlliniCash.notifyPaymentSuccess,
      IlliniCash.notifyBallanceUpdated,
      IlliniCash.notifyEligibilityUpdated,
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

  void _loadMealPlanTransactions() {
    _showMealPlanTransactionsProgress(true);
    IlliniCash().loadMealPlanTransactionHistory(_startDate, _endDate).then((
        transactions) => _onMealPlanTransactionsLoaded(transactions));
  }

  void _loadCafeCreditTransactions() {
    _showMealPlanTransactionsProgress(true);
    IlliniCash().loadCafeCreditTransactionHistory(_startDate, _endDate).then((
        transactions) => _onCafeCreditTransactionsLoaded(transactions));
  }

  void _loadBallance() {
    _illiniCashLoading = (IlliniCash().ballance == null);
    IlliniCash().updateBalance().then((_){
      setState(() {
        _illiniCashLoading = false;
      });
    });
  }

  void _loadThisMonthHistory() {
    Analytics().logSelect(target: "This Month");
    DateTime now = DateTime.now();
    DateTime lastMonth = now.subtract(Duration(
      days: 30,
    ));
    _startDate = lastMonth;
    _endDate = now;
    _loadMealPlanTransactions();
    _loadCafeCreditTransactions();
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
          leadingIconKey: widget.scrollController == null ? 'chevron-left-white' : 'chevron-left-bold',
          title: Localization().getStringEx('panel.settings.meal_plan.label.title','University Housing Meal Plan'),
          textStyle:  widget.scrollController == null ? Styles().textStyles?.getTextStyle("widget.heading.regular.extra_fat") : Styles().textStyles?.getTextStyle("widget.title.regular.extra_fat"),
        ),
        SliverList(
          delegate: SliverChildListDelegate([
            Container(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[

                  _buildSettingsHeader(Localization().getStringEx(
                      "panel.settings.meal_plan.heading.text", "University Housing Meal Plan"), 'dining'),
                  _buildMealPlanSection(),
                  _buildMealPlanHistory(),
                  _buildCafeCreditHistory(),
                  _buildBalancePeriodViewPicker(),
                ],
              ),
            ),
          ]),
        )
      ],
    );
  }

  Widget _buildMealPlanHistory(){
    return Column(
      children: <Widget>[
        _buildSettingsHeader(Localization().getStringEx(
            "panel.settings.meal_plan.classic_meal_history.text", "Classic Meal History"), 'calendar'),
        _buildBalanceTableRow(_mealPlanTransactionsLoading, _mealPlanTransactions),
        Container(height: 20,),
      ],
    );
  }

  Widget _buildCafeCreditHistory(){
    return Column(
      children: <Widget>[
        _buildSettingsHeader(Localization().getStringEx(
            "panel.settings.meal_plan.dining_dollars_history.text", "Dining Dollars History"), 'calendar'),
        _buildBalanceTableRow(_cafeCreditTransactionsLoading, _cafeCreditTransactions),
        Container(height: 20,),
      ],
    );
  }

  Widget _buildSettingsHeader(String? title, String iconKey){
    if (!Auth2().isLoggedIn) {
      return Container();
    }
    return Semantics(
      label: title,
      header: true,
      excludeSemantics: true,
      child: Container(
        color: Styles().colors!.fillColorPrimaryVariant,
//        height: 56,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: <Widget>[
                Styles().images?.getImage(StringUtils.ensureNotEmpty(
                    iconKey, defaultValue: 'settings')) ?? Container(),
                Expanded(child:
                  Padding(
                    padding: EdgeInsets.only(left: 12),
                    child: Text(
                      StringUtils.ensureNotEmpty(title),
                      style: Styles().textStyles?.getTextStyle("widget.heading.large"),
                    ),
                  )
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMealPlanSection() {
    List<Widget> widgets = [];
    widgets.add(Padding(padding: EdgeInsets.only(top: 16)));
    
    if (Auth2().isLoggedIn) {
      if (_illiniCashLoading) {
        widgets.add(VerticalTitleValueSection(title: '', value: '',));
      }
      else if (IlliniCash().eligibility?.eligible == false) {
        String title = Localization().getStringEx('panel.settings.meal_plan.label.ineligible', 'Ineligible');
        String? status = StringUtils.isNotEmpty(IlliniCash().eligibility?.accountStatus) ? IlliniCash().eligibility?.accountStatus :
          Localization().getStringEx('panel.settings.meal_plan.label.ineligible_status', 'You are not eligibile for Meal Plan');
        
        widgets.add(VerticalTitleValueSection(
          title: title,
          titleTextStyle: Styles().textStyles?.getTextStyle("widget.title.large.extra_fat"),
          value: status,
          valueTextStyle: Styles().textStyles?.getTextStyle("widget.detail.medium"),
        ));
      }
      else {
        widgets.add(VerticalTitleValueSection(
          title: Localization().getStringEx("panel.settings.meal_plan.label.meal_plan_type.text", "Meal Plan Type"),
          value: StringUtils.isNotEmpty(IlliniCash().ballance?.mealPlanName) ? IlliniCash().ballance?.mealPlanName : Localization().getStringEx("panel.settings.meal_plan.label.meal_plan_unknown.text", "Unknown"),
        ));
        
        widgets.add(Row(children: <Widget>[
          Expanded(child:
            VerticalTitleValueSection(
              title: Localization().getStringEx("panel.settings.meal_plan.label.meals_remaining.text", "Meals Remaining"),
              value: IlliniCash().ballance?.mealBalanceDisplayText ?? "0",
            ),
          ),
          Expanded(child:
            VerticalTitleValueSection(
              title: Localization().getStringEx("panel.settings.meal_plan.label.dining_dollars.text", "Dining Dollars"),
              value: IlliniCash().ballance?.cafeCreditBalanceDisplayText ?? "0",
            ),
          )
        ],),);
      }

    }
    else if (_canSignIn) {
      widgets.add(Padding(
        padding: EdgeInsets.only(left: 20, right: 20, bottom: 16),
        child: RoundedButton(
          label: Localization().getStringEx(
              "panel.settings.meal_plan.button.login_to_view_meal_plan.text",
              "Sign in to View Your Meal Plan"),
          hint: Localization().getStringEx(
              'panel.settings.meal_plan.button.login_to_view_meal_plan.hint',
              ''),
          textStyle: Styles().textStyles?.getTextStyle("widget.button.title.enabled"),
          backgroundColor: Styles().colors!.white,
          borderColor: Styles().colors!.fillColorSecondary,
          onTap: _onTapLogIn,
        ),
      ));
    }
    else {
      widgets.add(_buildPrivacyAlertMessage());
    }

    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        Container(
            color: Colors.white,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widgets)
        ),
        _illiniCashLoading ? CircularProgressIndicator() : Container()
      ],
    );
  }

  Widget _buildBalancePeriodViewPicker() {
    if (!Auth2().isLoggedIn) {
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
                Localization().getStringEx("panel.settings.meal_plan.label.custom_period", "Custom Period"),
                style: Styles().textStyles?.getTextStyle("widget.detail.regular")
            ),
          ),
          Padding(
            padding: EdgeInsets.only(bottom: 16), child: Row(children: <Widget>[
            _DateLabel(label: Localization().getStringEx('panel.settings.meal_plan.label.start_date', 'Start Date'),),
            Container(width: 8,),
            Expanded(child: _DateValue(title: StringUtils.ensureNotEmpty(
                _getFormattedDate(_startDate)),
              label: Localization().getStringEx('panel.settings.meal_plan.button.start_date.title', 'Start Date'),
              hint: Localization().getStringEx('panel.settings.meal_plan.button.start_date.hint', ''),
              onTap: _onStartDateTap,))
          ],),),
          Padding(
            padding: EdgeInsets.only(bottom: 16), child: Row(children: <Widget>[
            _DateLabel(label: Localization().getStringEx('panel.settings.meal_plan.label.end_date', 'End Date'),),
            Container(width: 8,),
            Expanded(child: _DateValue(
              title: StringUtils.ensureNotEmpty(
                  _getFormattedDate(_endDate)),
              label: Localization().getStringEx('panel.settings.meal_plan.button.end_date.title', 'End Date'),
              hint: Localization().getStringEx('panel.settings.meal_plan.button.end_date.hint', ''),
              onTap: _onEndDateTap,))
          ],),),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: <Widget>[
            Expanded(child: RoundedButton(
              label: Localization().getStringEx('panel.settings.meal_plan.button.view_history.title', 'View History'),
              hint: Localization().getStringEx('panel.settings.meal_plan.button.view_history.hint', ''),
              textStyle: Styles().textStyles?.getTextStyle("widget.button.title.enabled"),
              backgroundColor: Colors.white,
              borderColor: Styles().colors!.fillColorSecondary,
              onTap: _onTapViewHistory,)),
          ],)
        ],),);
  }

  Widget _buildBalanceTableRow(bool loadingFlag, List<BaseTransaction>? transactionList) {
    if(Auth2().isLoggedIn) {
      if (loadingFlag) {
        return Center(child: Padding(padding: EdgeInsets.only(bottom: 20),
          child: CircularProgressIndicator(),),);
      }
      if (_startDate == null || _endDate == null ||
          _startDate!.isAfter(_endDate!)) {
        String text = Localization().getStringEx(
            'panel.settings.meal_plan.transactions.message.start_end_validation.text',
            'Start date must be before end date');
        return Semantics(
          label: text, hint: Localization().getStringEx(
            'panel.settings.meal_plan.transactions.message.start_end_validation.hint',
            ''), excludeSemantics: true, child: Center(child: Padding(
          padding: EdgeInsets.only(left: 40, right: 40, bottom: 20),
          child: Text(text,
            style: Styles().textStyles?.getTextStyle("widget.message.regular.fat"),),),),);
      }
      if (transactionList == null || transactionList.isEmpty) {
        String text = Localization().getStringEx(
            'panel.settings.meal_plan.transactions.message.no_transactions.text',
            'There is no transactions for the selected period');
        return Semantics(label: text, hint: Localization().getStringEx(
            'panel.settings.meal_plan.transactions.message.no_transactions.hint',
            ''), excludeSemantics: true, child: Center(child: Padding(
          padding: EdgeInsets.only(left: 40, right: 40, bottom: 20),
          child: Text(text,
            textAlign: TextAlign.center,
            style: Styles().textStyles?.getTextStyle("widget.message.regular.fat"),),),),);
      }
      String dateHeader = Localization().getStringEx(
          'panel.settings.meal_plan.label.date', 'Date');
      String locationHeader = Localization().getStringEx(
          'panel.settings.meal_plan.label.location', 'Location');
      String descriptionHeader = Localization().getStringEx(
          'panel.settings.meal_plan.label.description', 'Description');
      String amountHeader = Localization().getStringEx(
          'panel.settings.meal_plan.label.amount', 'Amount');
      List<Widget> dateWidgets =  [];
      List<Widget> locationWidgets =  [];
      List<Widget> descriptionWidgets =  [];
      List<Widget> amountViewWidgets =  [];
      //Headers
      dateWidgets.add(_buildBalanceTableHeaderItem(dateHeader));
      locationWidgets.add(_buildBalanceTableHeaderItem(locationHeader));
      descriptionWidgets.add(_buildBalanceTableHeaderItem(descriptionHeader));
      amountViewWidgets.add(_buildBalanceTableHeaderItem(amountHeader));

      //Workaround to make BalanceItem fill the column lane (needed for bordering)
      double textSize = 9;
      int dateLenght = dateHeader.length;
      int locationLenght = locationHeader.length;
      int descriptionLenght = descriptionHeader.length;
      int amountLenght = amountHeader.length;
      transactionList.forEach((BaseTransaction? balance) {
        //date
        String date = balance!.dateString!;
        dateLenght = dateLenght < date.length ? date.length : dateLenght;
        //location
        String location = balance.location!;
        locationLenght =
        locationLenght < location.length ? location.length : locationLenght;
        //description
        String description = balance.description!;
        descriptionLenght = descriptionLenght < description.length
            ? description.length
            : descriptionLenght;
        //balance
        String amount = balance.amount!;
        amountLenght =
        amountLenght < amount.length ? amount.length : amountLenght;

        dateWidgets.add(_buildBalanceTableItem(text: date));
        locationWidgets.add(_buildBalanceTableItem(text: location));
        descriptionWidgets.add(_buildBalanceTableItem(text: description));
        amountViewWidgets.add(_buildAmountView(amount));
      });

      return Row(
          children: [
            Expanded(child:
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child:
              Container(
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: (dateLenght * textSize) + 20,
                        child:
                        Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: dateWidgets),),
                      Container(
                          width: locationLenght * textSize + 20,
                          child:
                          Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: locationWidgets)),
                      Container(
                          width: descriptionLenght * textSize +
                              16 /*the padding*/,
                          child:
                          Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: descriptionWidgets)),
                    ]),
              ),
            )),
            Container(
                width: amountLenght * textSize + 16 /*the padding*/,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: amountViewWidgets)),
          ]);
    }
    else{
      return Container();
    }
  }

  Widget _buildBalanceTableHeaderItem(String text){
    return _buildBalanceTableItem(text: text, backColor: Styles().colors!.fillColorPrimaryVariant,
        showBorder: false,
        textStyle: Styles().textStyles?.getTextStyle("widget.heading.medium_small"));
  }

  Widget _buildBalanceTableItem({required String text, bool showBorder = true, Color? backColor, TextStyle? textStyle, TextAlign textAlign = TextAlign.left}) {
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
              Border.all(color: backColor ?? Styles().colors!.background!, width: 0)
          ),
          child: Padding(
            padding: EdgeInsets.all(8),
            child:
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(text,
                    maxLines: 1,
                    textAlign: textAlign,
                    style: textStyle!=null? textStyle: Styles().textStyles?.getTextStyle("widget.item.small.thin"),),
                ),
              ],
            ),

          )
      );
  }

  Widget _buildAmountView(String balance){
    return _buildBalanceTableItem(text: balance, backColor: Styles().colors!.white,
        textAlign: TextAlign.right,
        textStyle: Styles().textStyles?.getTextStyle("widget.item.small.fat"));
  }

  Widget _buildPrivacyAlertMessage() {
    final String iconMacro = '{{privacy_level_icon}}';
    String privacyMsg = Localization().getStringEx('panel.settings.meal_plan.label.privacy_alert.msg', "With your privacy level at $iconMacro , you can't sign in. To view your mean plan, you must set your privacy level to 4 and sign in.");
    int iconMacroPosition = privacyMsg.indexOf(iconMacro);
    String privacyMsgStart = (0 < iconMacroPosition) ? privacyMsg.substring(0, iconMacroPosition) : '';
    String privacyMsgEnd = ((0 < iconMacroPosition) && (iconMacroPosition < privacyMsg.length)) ? privacyMsg.substring(iconMacroPosition + iconMacro.length) : '';

    return Container(
      padding: EdgeInsets.only(left: 16, right: 16, bottom: 16),
      child: RichText(text: TextSpan(
        style: Styles().textStyles?.getTextStyle("panel.settings.heading.title.large"),
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
        Text(privacyLevel, style: Styles().textStyles?.getTextStyle("widget.title.medium.extra_fat"))
      ),
    );
  }

  void _onMealPlanTransactionsLoaded(List<MealPlanTransaction>? transactions) {
    _showMealPlanTransactionsProgress(false, changeState: false);
    if (mounted) {
      setState(() {
        _mealPlanTransactions = transactions;
      });
    }
  }

  void _onCafeCreditTransactionsLoaded(List<CafeCreditTransaction>? transactions) {
    _showCafeCreditTransactionsProgress(false, changeState: false);
    if (mounted) {
      setState(() {
        _cafeCreditTransactions = transactions;
      });
    }
  }

  void _onTapViewHistory() {
    Analytics().logSelect(target: "View History");
    _loadMealPlanTransactions();
    _loadCafeCreditTransactions();
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

  void _onTapLogIn() {
    Analytics().logSelect(target: "Log in");
    if (_authLoading != true) {
      setState(() { _authLoading = true; });
      Auth2().authenticateWithOidc().then((Auth2OidcAuthenticateResult? result) {
        if (mounted) {
          setState(() { _authLoading = false; });
          if (result == Auth2OidcAuthenticateResult.succeeded) {
            _loadCafeCreditTransactions();
            _loadMealPlanTransactions();
          }
          else if (result == Auth2OidcAuthenticateResult.failed) {
            AppAlert.showDialogResult(context, Localization().getStringEx("logic.general.login_failed", "Unable to login. Please try again later."));
          }
        }
      });
    }
  }

  void _onStartDateChanged(DateTime? startDate) {
    if(mounted) {
      setState(() {
        _startDate = startDate;
      });
    }
  }

  void _onEndDateChanged(DateTime? endDate) {
    if(mounted) {
      setState(() {
        _endDate = endDate;
      });
    }
  }

  // Helpers

  void _showMealPlanTransactionsProgress(bool loading, {bool changeState = true}) {
    _mealPlanTransactionsLoading = loading;
    if (changeState) {
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _showCafeCreditTransactionsProgress(bool loading, {bool changeState = true}) {
    _cafeCreditTransactionsLoading = loading;
    if (changeState) {
      if (mounted) {
        setState(() {});
      }
    }
  }

  String? _getFormattedDate(DateTime? date) {
    return AppDateTime().formatDateTime(
        date, format: 'MM/dd/yyyy');
  }

  bool get _canSignIn{
    return FlexUI().isAuthenticationAvailable;
  }

  // NotificationsListener
  
  @override
  void onNotification(String name, dynamic param) {
    if (name == IlliniCash.notifyBallanceUpdated) {
      setState(() {});
      _loadCafeCreditTransactions();
      _loadMealPlanTransactions();
    }
    else if (name == IlliniCash.notifyEligibilityUpdated) {
      setState(() {

      });
    }
    else if (name == IlliniCash.notifyPaymentSuccess) {
      _loadCafeCreditTransactions();
      _loadMealPlanTransactions();
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
        Text(label!, style: Styles().textStyles?.getTextStyle("widget.item.regular.thin"),),
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
          Expanded(child:
            Text(title!,
              overflow: TextOverflow.ellipsis,
              style: Styles().textStyles?.getTextStyle("widget.item.regular.fat"),),
          ),
          Styles().images?.getImage('chevron-down', excludeFromSemantics: true) ?? Container(),
        ],), Container(height: 2, color: Styles().colors!.fillColorSecondary,)
    ],),),);
  }
}
