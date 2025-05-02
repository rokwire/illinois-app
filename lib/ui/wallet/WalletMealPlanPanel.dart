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
import 'package:illinois/ui/wallet/WalletHomePanel.dart';
import 'package:illinois/ui/wallet/WalletIlliniCashPanel.dart';
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

//////////////////////////
// WalletMealPlanPanel

class WalletMealPlanPanel extends StatelessWidget {

  WalletMealPlanPanel({super.key});

  static void present(BuildContext context) {
    if (Connectivity().isOffline) {
      AppAlert.showOfflineMessage(context, Localization().getStringEx('panel.browse.label.offline.meal_plan', 'University Housing Meal Plan is not available while offline.'));
    }
    else if (!Auth2().isOidcLoggedIn) {
      AppAlert.showLoggedOutFeatureNAMessage(context, Localization().getStringEx('generic.app.feature.meal_plan', 'University Housing Meal Plan'));
    }
    else {
      Navigator.push(context, CupertinoPageRoute(settings: RouteSettings(name: WalletIlliniCashPanel.routeName), builder: (context) => WalletMealPlanPanel()));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: _buildScaffoldBody(),
    backgroundColor: Styles().colors.background,
    bottomNavigationBar: uiuc.TabBar()
  );

  Widget _buildScaffoldBody() => CustomScrollView(
    slivers: <Widget>[
      SliverHeaderBar(
        leadingIconKey: 'caret-left',
        title: Localization().getStringEx('panel.settings.meal_plan.label.title','University Housing Meal Plan'),
        textStyle:  Styles().textStyles.getTextStyle("widget.heading.regular.extra_fat.light"),
      ),
      SliverList(
        delegate: SliverChildListDelegate([
          WalletMealPlanContentWidget(),
        ]),
      )
    ],
  );
}

/////////////////////////////////
// WalletMealPlanContentWidget

class WalletMealPlanContentWidget extends StatefulWidget with WalletHomeContentWidget {

  final double headerHeight;
  WalletMealPlanContentWidget({super.key, this.headerHeight = 0});

  @override
  _WalletMealPlanContentWidgetState createState() => _WalletMealPlanContentWidgetState();

  @override
  Color get backgroundColor => Styles().colors.fillColorPrimaryVariant;
}

class _WalletMealPlanContentWidgetState extends State<WalletMealPlanContentWidget> implements NotificationsListener {
  bool _authLoading = false;

  bool _illiniCashLoading = false;
  bool _showHistory = false;

  List<BaseTransaction>? _mealPlanTransactions;
  bool _mealPlanTransactionsLoading = false;

  List<BaseTransaction>? _cafeCreditTransactions;
  bool _cafeCreditTransactionsLoading = false;

  final int _historyNumberOfDays = 14;

  _WalletMealPlanContentWidgetState();

  @override
  void initState() {
    NotificationService().subscribe(this, [
      IlliniCash.notifyPaymentSuccess,
      IlliniCash.notifyBallanceUpdated,
      IlliniCash.notifyEligibilityUpdated,
    ]);

    _illiniCashLoading = (IlliniCash().ballance == null);
    IlliniCash().updateBalance().then((_) {
      setStateIfMounted(() {
        _illiniCashLoading = false;
      });
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
  Widget build(BuildContext context) {
    return _authLoading ? _buildLoading() : _buildBody();
  }

  Widget _buildBody() =>
    Container(color: widget.backgroundColor, child:
      Column(crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _buildContentHeader(),
          _buildSettingsHeader(Localization().getStringEx("panel.settings.meal_plan.heading.text", "University Housing Meal Plan"), 'dining'),
          _buildMealPlanSection(),
          _buildHistory(),
        ],
      ),
    );

  Widget _buildHistory() =>
    Padding(padding: const EdgeInsets.symmetric(vertical: 24), child:
      Column(children: <Widget>[
        Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
          RoundedButton(
            label: Localization().getStringEx('panel.settings.meal_plan.button.view_history.title', 'View History'),
            hint: Localization().getStringEx('panel.settings.meal_plan.button.view_history.hint', ''),
            textStyle: Styles().textStyles.getTextStyle("widget.button.title.enabled"),
            backgroundColor: Colors.white,
            borderColor: Styles().colors.fillColorSecondary,
            onTap: _onTapViewHistory,
          ),
        ),
        if (_showHistory)
          ...<Widget>[
            _buildMealPlanHistory(),
            _buildCafeCreditHistory(),
          ],
      ],),
    );

  Widget _buildMealPlanHistory() =>
    Padding(padding: const EdgeInsets.only(top: 24), child:
      Column(children: <Widget>[
        _buildSettingsHeader(Localization().getStringEx("panel.settings.meal_plan.classic_meal_history.text", "Classic Meal History"), 'calendar'),
        _buildBalanceTableRow(_mealPlanTransactionsLoading, _mealPlanTransactions),
      ],),
    );

  Widget _buildCafeCreditHistory() =>
    Padding(padding: const EdgeInsets.only(top: 24), child:
      Column(children: <Widget>[
        _buildSettingsHeader(Localization().getStringEx("panel.settings.meal_plan.dining_dollars_history.text", "Dining Dollars History"), 'calendar'),
        _buildBalanceTableRow(_cafeCreditTransactionsLoading, _cafeCreditTransactions),
      ],),
    );

  Widget _buildContentHeader() =>
    Container(height: widget.headerHeight, color: Styles().colors.fillColorPrimaryVariant,);

  Widget _buildSettingsHeader(String? title, String iconKey) =>
    Semantics(label: title, header: true, excludeSemantics: true, child:
      Container(color: Styles().colors.fillColorPrimaryVariant, child:
        Align(alignment: Alignment.centerLeft, child:
          Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
            Row(children: <Widget>[
              Styles().images.getImage(StringUtils.ensureNotEmpty(iconKey, defaultValue: 'settings')) ?? Container(),
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

  Widget _buildMealPlanSection() {
    List<Widget> widgets = [];

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
          titleTextStyle: Styles().textStyles.getTextStyle("widget.title.dark.large.extra_fat"),
          value: status,
          valueTextStyle: Styles().textStyles.getTextStyle("widget.detail.medium"),
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
    else if (FlexUI().isAuthenticationAvailable) {
      widgets.add(Padding(
        padding: EdgeInsets.only(left: 20, right: 20, bottom: 16, top: 16),
        child: RoundedButton(
          label: Localization().getStringEx("panel.settings.meal_plan.button.login_to_view_meal_plan.text", "Sign in to View Your Meal Plan"),
          hint: Localization().getStringEx('panel.settings.meal_plan.button.login_to_view_meal_plan.hint', ''),
          textStyle: Styles().textStyles.getTextStyle("widget.button.title.enabled"),
          backgroundColor: Styles().colors.surface,
          borderColor: Styles().colors.fillColorSecondary,
          onTap: _onTapLogIn,
        ),
      ));
    }
    else {
      widgets.add(_buildPrivacyAlertMessage());
    }

    return Padding(padding: EdgeInsets.only(top: 8), child:
      Stack(children: <Widget>[
        Container(color: Colors.white, child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: widgets)
        ),
        if (_illiniCashLoading)
          Positioned.fill(child:
            Center(child:
              Padding(padding: EdgeInsets.symmetric(vertical: 24), child:
                SizedBox(width: 24, height: 24, child:
                  CircularProgressIndicator(color: Styles().colors.fillColorSecondary, strokeWidth: 3,)
                )
              ),
            ),
          ),
      ],),
    );
  }

  Widget _buildBalanceTableRow(bool loadingFlag, List<BaseTransaction>? transactionList) {
    if (loadingFlag) {
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
    else if (CollectionUtils.isEmpty(transactionList)) {
      String text = (transactionList != null) ?
        Localization().getStringEx('panel.settings.meal_plan.transactions.message.no_transactions.text', 'There are no transactions in the last {{number_of_days}} days.').replaceAll('{{number_of_days}}', _historyNumberOfDays.toString()) :
        Localization().getStringEx('panel.settings.meal_plan.transactions.message.failed_transactions.text', 'Failed to load transactions.');
      String hint = (transactionList != null) ?
        Localization().getStringEx('panel.settings.meal_plan.transactions.message.no_transactions.hint', '') :
        Localization().getStringEx('panel.settings.meal_plan.transactions.message.failed_transactions.hint', '');
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
      String dateHeader = Localization().getStringEx('panel.settings.meal_plan.label.date', 'Date');
      String locationHeader = Localization().getStringEx('panel.settings.meal_plan.label.location', 'Location');
      String descriptionHeader = Localization().getStringEx('panel.settings.meal_plan.label.description', 'Description');
      String amountHeader = Localization().getStringEx('panel.settings.meal_plan.label.amount', 'Amount');

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
      transactionList?.forEach((BaseTransaction? balance) {

        //date
        String date = balance!.dateString!;
        dateLenght = dateLenght < date.length ? date.length : dateLenght;

        //location
        String location = balance.location!;
        locationLenght = locationLenght < location.length ? location.length : locationLenght;

        //description
        String description = balance.description!;
        descriptionLenght = descriptionLenght < description.length ? description.length : descriptionLenght;

        //balance
        String amount = balance.amount!;
        amountLenght =amountLenght < amount.length ? amount.length : amountLenght;

        dateWidgets.add(_buildBalanceTableItem(text: date));
        locationWidgets.add(_buildBalanceTableItem(text: location));
        descriptionWidgets.add(_buildBalanceTableItem(text: description));
        amountViewWidgets.add(_buildAmountView(amount));
      });

      return Row(children: [
        Expanded(child:
          SingleChildScrollView(scrollDirection: Axis.horizontal, child:
            Container(child:
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(width: (dateLenght * textSize) + 20, child:
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: dateWidgets),
                ),
                Container(width: locationLenght * textSize + 20, child:
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: locationWidgets)
                ),
                Container(width: descriptionLenght * textSize + 16 /*the padding*/, child:
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: descriptionWidgets)
                ),
              ]),
            ),
          )
        ),
        Container(width: amountLenght * textSize + 16 /*the padding*/, child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: amountViewWidgets)
        ),
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

  Widget _buildBalanceTableItem({required String text, bool showBorder = true, Color? backColor, TextStyle? textStyle, TextAlign textAlign = TextAlign.left}) =>
    Container(
      width: double.infinity,
      height: 40,
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: backColor ?? Styles().colors.background,
        border: showBorder ?
          Border.all(color: Styles().colors.surfaceAccent, width: 1, style: BorderStyle.solid) :
          Border.all(color: backColor ?? Styles().colors.background, width: 0)
      ), child:
        Padding(padding: EdgeInsets.all(8), child:
          Row(children: <Widget>[
            Expanded(child:
              Text(text,maxLines: 1, textAlign: textAlign, style: textStyle ?? Styles().textStyles.getTextStyle("widget.item.small.thin"),),
            ),
          ],),
        )
      );

  Widget _buildAmountView(String balance) =>
    _buildBalanceTableItem(text: balance,
      backColor: Styles().colors.surface,
      textAlign: TextAlign.right,
      textStyle: Styles().textStyles.getTextStyle("widget.item.small.fat")
    );

  Widget _buildPrivacyAlertMessage() {
    final String iconMacro = '{{privacy_level_icon}}';
    String privacyMsg = Localization().getStringEx('panel.settings.meal_plan.label.privacy_alert.msg', "With your privacy level at $iconMacro , you can't sign in. To view your mean plan, you must set your privacy level to 4 and sign in.");
    int iconMacroPosition = privacyMsg.indexOf(iconMacro);
    String privacyMsgStart = (0 < iconMacroPosition) ? privacyMsg.substring(0, iconMacroPosition) : '';
    String privacyMsgEnd = ((0 < iconMacroPosition) && (iconMacroPosition < privacyMsg.length)) ? privacyMsg.substring(iconMacroPosition + iconMacro.length) : '';

    return Container(padding: EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 16), child:
      RichText(text: TextSpan(style: Styles().textStyles.getTextStyle("panel.settings.heading.title.large"), children: [
        TextSpan(text: privacyMsgStart),
        WidgetSpan(alignment: PlaceholderAlignment.middle, child: _buildPrivacyLevelIcon()),
        TextSpan(text: privacyMsgEnd)
      ])
      )
    );
  }

  Widget _buildPrivacyLevelIcon() {
    String privacyLevel = Auth2().prefs?.privacyLevel?.toString() ?? '';
    return Container(height: 40, width: 40, alignment: Alignment.center, decoration: BoxDecoration(border: Border.all(color: Styles().colors.fillColorPrimary, width: 2), color: Styles().colors.surface, borderRadius: BorderRadius.all(Radius.circular(100)),), child:
      Container(height: 32, width: 32, alignment: Alignment.center, decoration: BoxDecoration(border: Border.all(color: Styles().colors.fillColorSecondary, width: 2), color: Styles().colors.surface, borderRadius: BorderRadius.all(Radius.circular(100)),), child:
        Text(privacyLevel, style: Styles().textStyles.getTextStyle("widget.title.medium.extra_fat"))
      ),
    );
  }

  Widget _buildLoading() => Padding(padding: EdgeInsets.symmetric(horizontal: 32, vertical: 72), child:
    Center(child:
      CircularProgressIndicator(color: Styles().colors.fillColorSecondary,),
    ),
  );

  // Handlers

  void _onTapViewHistory() {
    Analytics().logSelect(target: "View History");
    if (_showHistory == false) {
      setState(() {
        _showHistory = true;
      });
    }
    _updateHistory();
  }

  void _updateHistory() {
    DateTime endDate = DateTime.now();
    DateTime startDate = DateTimeUtils.midnight(endDate.subtract(Duration(days: _historyNumberOfDays))) ?? endDate;

    if (_mealPlanTransactionsLoading == false) {
      setState(() {
        _mealPlanTransactionsLoading = true;
      });
      IlliniCash().loadMealPlanTransactionHistory(startDate, endDate).then((List<MealPlanTransaction>? transactions) {
        setStateIfMounted((){
          _mealPlanTransactionsLoading = false;
          _mealPlanTransactions = transactions;
        });
      });
    }

    if (_cafeCreditTransactionsLoading == false) {
      setState(() {
        _cafeCreditTransactionsLoading = true;
      });
      IlliniCash().loadCafeCreditTransactionHistory(startDate, endDate).then((List<CafeCreditTransaction>? transactions) {
        setStateIfMounted((){
          _cafeCreditTransactionsLoading = false;
          _cafeCreditTransactions = transactions;
        });
      });
    }
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
          if (result?.status == Auth2OidcAuthenticateResultStatus.failed) {
            AppAlert.showDialogResult(context, Localization().getStringEx("logic.general.login_failed", "Unable to login. Please try again later."));
          }
        }
      });
    }
  }
}
