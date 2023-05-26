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

import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/app_datetime.dart';
import 'package:illinois/model/IlliniCash.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:illinois/service/Storage.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart';
import 'package:crypto/crypto.dart';
import 'package:convert/convert.dart';

import 'package:illinois/service/Auth2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/service/Config.dart';
import 'package:rokwire_plugin/service/network.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:xml/xml.dart';

class IlliniCash with Service, NetworkAuthProvider implements NotificationsListener {

  static const String notifyPaymentSuccess  = "edu.illinois.rokwire.illinicash.payment.success";
  static const String notifyBallanceUpdated  = "edu.illinois.rokwire.illinicash.ballance.updated";
  static const String notifyEligibilityUpdated  = "edu.illinois.rokwire.illinicash.eligibility.updated";
  static const String notifyStudentClassificationUpdated  = "edu.illinois.rokwire.illinicash.student.classification.updated";

  static const String uiucAccessToken      = 'access_token';

  IlliniCashEligibility?       _eligibility;
  IlliniCashBallance?          _ballance;
  IlliniStudentClassification? _studentClassification;

  DateTime? _pausedDateTime;
  bool      _buyIlliniCashInProgress = false;

  // Singletone Instance

  IlliniCash._internal();
  static final IlliniCash _instance = new IlliniCash._internal();

  factory IlliniCash() {
    return _instance;
  }

  // Initialization

  @override
  void createService() {
    NotificationService().subscribe(this, [
      AppLivecycle.notifyStateChanged,
      Auth2.notifyLoginChanged,
    ]);
  }

  @override
  void destroyService() {
    NotificationService().unsubscribe(this);
  }

  @override
  Future<void> initService() async {
    if (_enabled) {
      _eligibility = IlliniCashEligibility.fromJson(JsonUtils.decodeMap(Storage().illiniCashEligibility));
      _ballance = IlliniCashBallance.fromJson(JsonUtils.decodeMap(Storage().illiniCashBallance));
      _studentClassification = IlliniStudentClassification.fromJson(JsonUtils.decodeMap(Storage().illiniStudentClassification));
      updateBalance();
      await super.initService();
    }
  }

  @override
  Set<Service> get serviceDependsOn {
    return Set.from([Storage(), Config(), Auth2()]);
  }
  
  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if(_enabled) {
      if (name == AppLivecycle.notifyStateChanged) {
        _onAppLivecycleStateChanged(param);
      }
      else if (name == Auth2.notifyLoginChanged) {
        updateBalance();
      }
    }
  }

  void _onAppLivecycleStateChanged(AppLifecycleState? state) {
    
    if (state == AppLifecycleState.paused) {
      _pausedDateTime = DateTime.now();
    }
    if (state == AppLifecycleState.resumed) {
      if (_pausedDateTime != null) {
        Duration pausedDuration = DateTime.now().difference(_pausedDateTime!);
        if (Config().refreshTimeout < pausedDuration.inSeconds) {
          updateBalance();
        }
      }
    }
  }

  // NetworkAuthProvider

  String? get _networkAuthHeaderToken => Auth2().uiucToken?.accessToken;

  @override
  Map<String, String>? get networkAuthHeaders {
    String? accessToken = _networkAuthHeaderToken;
    if ((accessToken != null) && accessToken.isNotEmpty) {
      return { uiucAccessToken : accessToken };
    }
    return null;
  }

  @override
  dynamic get networkAuthToken => Auth2().token;
  
  @override
  Future<bool> refreshNetworkAuthTokenIfNeeded(BaseResponse? response, dynamic token) async {
    if ((response?.statusCode == 401) && (token is Auth2Token) && (Auth2().token == token)) {
      return (await Auth2().refreshToken(token) != null);
    }
    return false;
  }

  // Ballances

  IlliniCashEligibility? get eligibility {
    return _eligibility;
  }

  IlliniCashBallance? get ballance {
    return _ballance;
  }

  Future<void> updateBalance() async {
    if(_enabled) {
      dynamic studentSummary = await _loadStudentSummary();
      if (studentSummary is IlliniStudentSummary) {
        _applyEligibility(studentSummary.eligibility);
        _applyStudentClassifiction(studentSummary.classification);
        
        bool? eligible = studentSummary.eligibility?.eligible;
        if (eligible == true) {
          String url = "${Config().illiniCashBaseUrl}/Balances/${Auth2().uin}";
          String analyticsUrl = "${Config().illiniCashBaseUrl}/Balances/${Analytics.LogAnonymousUin}";
          Response? response = await Network().get(url, auth: this, analyticsUrl: analyticsUrl);
          if ((response != null) && (response.statusCode >= 200) && (response.statusCode <= 301)) {
            String responseBody = response.body;
            Map<String, dynamic>? jsonData = JsonUtils.decode(responseBody);
            IlliniCashBallance? ballance = (jsonData != null) ? IlliniCashBallance.fromJson(jsonData) : null;
            if (ballance != null) {
              _applyBallance(ballance);
            }
          }
        }
        else if (eligible == false) {
          _applyBallance(null);
          _applyStudentClassifiction(null);
        }
      }
      else if (studentSummary == false) {
        _applyEligibility(null);
        _applyBallance(null);
        _applyStudentClassifiction(null);
      }
    }
  }

  Future<dynamic> _loadStudentSummary() async {
    String? uin = Auth2().uin;
    String? firstName = Auth2().account?.authType?.uiucUser?.firstName;
    String? lastName = Auth2().account?.authType?.uiucUser?.lastName;

    if ((Config().illiniCashBaseUrl != null) && StringUtils.isNotEmpty(_networkAuthHeaderToken) && StringUtils.isNotEmpty(uin) && StringUtils.isNotEmpty(firstName) && StringUtils.isNotEmpty(lastName)) {
      String url =  "${Config().illiniCashBaseUrl}/StudentSummary/$uin/$firstName/$lastName";
      String analyticsUrl = "${Config().illiniCashBaseUrl}/StudentSummary/${Analytics.LogAnonymousUin}/${Analytics.LogAnonymousFirstName}/${Analytics.LogAnonymousLastName}";
      Response? response;
      try { response = await Network().get(url, analyticsUrl: analyticsUrl, auth: this); } on Exception catch(e) { print(e.toString()); }
      int responseCode = response?.statusCode ?? -1;
      if ((response != null) && responseCode >= 200 && responseCode <= 301) {
        String responseString = response.body;
        return IlliniStudentSummary.fromJson(JsonUtils.decodeMap(responseString)); // request succeeded
      }
      else {
        return null; // request failed, eligible not determined
      }
    }
    else {
      return false; // eligible not available
    }
  }

  void _applyEligibility(IlliniCashEligibility? value) {
    if (_eligibility != value) {
      _eligibility = value;
      Storage().illiniCashEligibility = JsonUtils.encode(value?.toJson());
      NotificationService().notify(notifyEligibilityUpdated, null);
    }
  }

  void _applyBallance(IlliniCashBallance? value) {
    if (_ballance != value) {
      _ballance = value;
      Storage().illiniCashBallance = JsonUtils.encode(value?.toJson());
      NotificationService().notify(notifyBallanceUpdated, null);
    }
  }

  // Student Classification

  IlliniStudentClassification? get studentClassification {
    return _studentClassification;
  }

  void _applyStudentClassifiction(IlliniStudentClassification? value) {
    if (_studentClassification != value) {
      _studentClassification = value;
      Storage().illiniStudentClassification = JsonUtils.encode(value?.toJson());
      NotificationService().notify(notifyStudentClassificationUpdated, null);
    }
  }

  Future<List<IlliniCashTransaction>?> loadTransactionHistory(DateTime? startDate, DateTime? endDate) async {

    if (!_enabled || startDate == null || endDate == null || startDate.isAfter(endDate)) {
      return null;
    }
    
    String uin = Auth2().uin ?? "";
    String? startDateFormatted = AppDateTime().formatDateTime(startDate, format: IlliniCashTransaction.dateFormat, ignoreTimeZone: true);
    String? endDateFormatted = AppDateTime().formatDateTime(endDate, format: IlliniCashTransaction.dateFormat, ignoreTimeZone: true);
    String transactionHistoryUrl = "${Config().illiniCashBaseUrl}/IlliniCashTransactions/$uin/$startDateFormatted/$endDateFormatted";
    String analyticsUrl = "${Config().illiniCashBaseUrl}/IlliniCashTransactions/${Analytics.LogAnonymousUin}/$startDateFormatted/$endDateFormatted";

    final response = await Network().get(transactionHistoryUrl, auth: this, analyticsUrl: analyticsUrl );
    if (response != null && response.statusCode >= 200 && response.statusCode <= 301) {
      String responseBody = response.body;
      List<dynamic>? jsonListData = JsonUtils.decode(responseBody);
      if (jsonListData != null) {
        List<IlliniCashTransaction> transactions = <IlliniCashTransaction>[];
        for (var jsonData in jsonListData) {
          IlliniCashTransaction? transaction = IlliniCashTransaction.fromJson(
              jsonData);
          if (transaction != null) {
            transactions.add(transaction);
          }
        }
        return transactions;
      }
    }

    return null;
  }

  Future<List<MealPlanTransaction>?> loadMealPlanTransactionHistory(DateTime? startDate, DateTime? endDate) async {
    if (!_enabled || startDate == null || endDate == null || startDate.isAfter(endDate)) {
      return null;
    }
    String uin = Auth2().uin ?? "";
    String? startDateFormatted = AppDateTime().formatDateTime(startDate, format: IlliniCashTransaction.dateFormat, ignoreTimeZone: true);
    String? endDateFormatted = AppDateTime().formatDateTime(endDate, format: IlliniCashTransaction.dateFormat, ignoreTimeZone: true);
    String transactionHistoryUrl = "${Config().illiniCashBaseUrl}/MealPlanTransactions/$uin/$startDateFormatted/$endDateFormatted";
    String analyticsUrl = "${Config().illiniCashBaseUrl}/MealPlanTransactions/${Analytics.LogAnonymousUin}/$startDateFormatted/$endDateFormatted";
    final response = await Network().get(transactionHistoryUrl, auth: this, analyticsUrl: analyticsUrl);

    // TMP: "[{\"Amount\":\"1\",\"Date\":\"2017-01-19 18:24:09 \",\"Location\":\"IKE\",\"Description\":\"LateDinner\"},{\"Amount\":\"1\",\"Date\":\"2017-01-19 11:41:07 \",\"Location\":\"IKE\",\"Description\":\"EarlyLunch\"},{\"Amount\":\"1\",\"Date\":\"2017-01-18 18:42:01 \",\"Location\":\"IKE\",\"Description\":\"LateDinner\"},{\"Amount\":\"1\",\"Date\":\"2017-01-18 11:36:14 \",\"Location\":\"IKE\",\"Description\":\"EarlyLunch\"},{\"Amount\":\"1\",\"Date\":\"2017-01-17 18:40:11 \",\"Location\":\"IKE\",\"Description\":\"LateDinner\"},{\"Amount\":\"1\",\"Date\":\"2017-01-17 11:27:49 \",\"Location\":\"IKE\",\"Description\":\"EarlyLunch\"},{\"Amount\":\"1\",\"Date\":\"2017-01-16 18:40:20 \",\"Location\":\"IKE\",\"Description\":\"LateDinner\"},{\"Amount\":\"1\",\"Date\":\"2017-01-16 12:42:43 \",\"Location\":\"IKE\",\"Description\":\"Lunch\"}]";

    if (response != null && response.statusCode >= 200 && response.statusCode <= 301) {
      String responseBody = response.body;
      List<dynamic>? jsonListData = JsonUtils.decode(responseBody);
      if (jsonListData != null) {
        List<MealPlanTransaction> transactions = <MealPlanTransaction>[];
        for (var jsonData in jsonListData) {
          MealPlanTransaction? transaction = MealPlanTransaction.fromJson(
              jsonData);
          if (transaction != null) {
            transactions.add(transaction);
          }
        }
        return transactions;
      }
    }

    return null;
  }

  Future<List<CafeCreditTransaction>?> loadCafeCreditTransactionHistory(DateTime? startDate,
      DateTime? endDate) async {
    if (!_enabled || startDate == null || endDate == null || startDate.isAfter(endDate)) {
      return null;
    }
    String uin = Auth2().uin ?? "";
    String? startDateFormatted = AppDateTime().formatDateTime(startDate, format: IlliniCashTransaction.dateFormat, ignoreTimeZone: true);
    String? endDateFormatted = AppDateTime().formatDateTime(endDate, format: IlliniCashTransaction.dateFormat, ignoreTimeZone: true);
    String transactionHistoryUrl = "${Config().illiniCashBaseUrl}/CafeCreditTransactions/$uin/$startDateFormatted/$endDateFormatted";
    String analyticsUrl = "${Config().illiniCashBaseUrl}/CafeCreditTransactions/${Analytics.LogAnonymousUin}/$startDateFormatted/$endDateFormatted";

    final response = await Network().get(transactionHistoryUrl, auth: this, analyticsUrl: analyticsUrl);

    // TMP "[{\"Date\":\"1/18/2019 10:55:06 AM\",\"Description\":\"Rollover\",\"Location\":\"OFFICE-CDHAYES1\",\"Amount\":\"100.0\"}]";

    if (response != null && response.statusCode >= 200 && response.statusCode <= 301) {
      String responseBody = response.body;
      List<dynamic>? jsonListData = JsonUtils.decode(responseBody);
      if (jsonListData != null) {
        List<CafeCreditTransaction> transactions = <CafeCreditTransaction>[];
        for (var jsonData in jsonListData) {
          CafeCreditTransaction? transaction = CafeCreditTransaction.fromJson(jsonData);
          if (transaction != null) {
            transactions.add(transaction);
          }
        }
        return transactions;
      }
    }

    return null;
  }

  Future<void> _saveCreditCard(_TransactionContext context) async{
    String? token = await _loadDataToken();

    if(StringUtils.isNotEmpty(token) && StringUtils.isNotEmpty(context.cc)){
      String? storeToken = await _loadStoreToken(token);

      if(StringUtils.isNotEmpty(storeToken)){
        String? baseUrl = (Config().illiniCashTrustcommerceHost != null) ? "${Config().illiniCashTrustcommerceHost}/trusteeapi/payment.php?action=store&cvv=${context.cvv}&cc=${context.cc}&name=${context.name}&exp=${context.expiry}&returnurl=xml&token=$storeToken" : null;

        Response? response = await Network().get(baseUrl);
        if ((response != null) && response.statusCode >= 200 &&
            response.statusCode <= 301) {

          context.cardResponse = _CreditCardResponse.fromXMLString(response.body);
          context.cardStatusResponse = await _completeToken(token, storeToken);
        }
      }
    }
  }

  /////////////////////////
  // BuyIlliniCash

  Future<void> buyIlliniCash({String? firstName, String? lastName, String? uin, String? email, String? cc, String? expiry, String? cvv, double? amount}) async {
    if(_enabled) {
      try {
        if (!_buyIlliniCashInProgress) {
          _buyIlliniCashInProgress = true;

          bool? eligible = await _isEligible(uin: uin, firstName: firstName, lastName: lastName);
          if (eligible != true) {
            _throwBuyIlliniCashError(Localization().getStringEx("panel.settings.add_illini_cash.error.buy_illini_cash_elligible.text", "The recipient is not eligible to buy Illini Cash"));
          }

          String amountString = NumberFormat("0.00", "en_US").format(amount);

          // 0. Create Transaction Context
          final _TransactionContext context = _TransactionContext(
            firstName: firstName,
            lastName: lastName,
            uin: uin,
            email: email,
            cc: cc,
            cvv: cvv,
            expiry: expiry,
            amount: amountString,
          );

          // 1. Save Credit Card into the system and use the resulted billingId
          await _saveCreditCard(context);

          if (context.cardStatusResponse?.status == "accepted" && StringUtils.isNotEmpty(context.cardStatusResponse?.billingId)) {
            // 2. PreAuth
            await _preAuth(context);

            if (context.preAuthStatusResponse?.status == "approved") {
              // 3. Process Payment
              await _completeTransaction(context);
            }
            else {
              _throwBuyIlliniCashError(null);
            }
          }
          else if (context.cardStatusResponse?.status == "baddata") {
            _throwBuyIlliniCashError(Localization().getStringEx(
                "panel.settings.add_illini_cash.error.baddata.text",
                "Unable to complete transaction. Please revise your credit card information."));
          }
          else {
            _throwBuyIlliniCashError(null);
          }
        }
        else {
          _throwBuyIlliniCashError(Localization().getStringEx(
              "panel.settings.add_illini_cash.error.duplicate_transaction.text",
              "Buy Illini Cash process has been already started. Please wait, monitor your balance and check your mail for receipt."));
        }
      }
      finally {
        _buyIlliniCashInProgress = false;
      }
    }
  }

  Future<bool?> _isEligible({String? uin, String? firstName, String? lastName}) async {
    if ((Config().illiniCashBaseUrl != null) && !StringUtils.isEmpty(uin) && !StringUtils.isEmpty(firstName) && !StringUtils.isEmpty(lastName)) {
      String url = "${Config().illiniCashBaseUrl}/ICEligible/$uin/$firstName/$lastName";
      String analyticsUrl = "${Config().illiniCashBaseUrl}/ICEligible/${Analytics.LogAnonymousUin}/${Analytics.LogAnonymousFirstName}/${Analytics.LogAnonymousLastName}";
      Response? response;
      try { response = await Network().get(url, analyticsUrl: analyticsUrl); } on Exception catch(e) { print(e.toString()); }
      int responseCode = response?.statusCode ?? -1;
      if ((response != null) && responseCode >= 200 && responseCode <= 301) {
        String responseString = response.body;
        Map<String, dynamic>? jsonData = JsonUtils.decode(responseString);
        return (jsonData != null) ? JsonUtils.boolValue(jsonData['IlliniCashEligible']) : null;
      }
      else {
        // request failed, eligible not determined
        return null;
      }
    }
    else {
      // eligible not available
      return false;
    }
  }

  Future<void> _preAuth(_TransactionContext context) async{
    String? token = await _loadDataToken();

    if(StringUtils.isNotEmpty(token)){
      String? preAuthToken = await _loadPreAuthToken(token, context.cardStatusResponse!.billingId);

      if(StringUtils.isNotEmpty(preAuthToken)){
        String? baseUrl = (Config().illiniCashTrustcommerceHost != null) ? "${Config().illiniCashTrustcommerceHost}/trusteeapi/payment.php?action=preauth&returnurl=xml&amount=${context.amount}&billingid=${context.cardStatusResponse!.billingId}&exp=${context.expiry}&token=$preAuthToken" : null;

        Response? response = await Network().get(baseUrl);
        if ((response != null) && response.statusCode >= 200 &&
            response.statusCode <= 301) {
          // Sample body: authcode=0YXLJH transid=032-0003229265 status=approved
          context.preAuthStatusResponse = await _completeToken(token, preAuthToken);

        }
      }
    }
  }

  Future<void> _completeTransaction(_TransactionContext context) async{

    // 1. Generate signature
    String? appKey =  Config().illiniCashAppKey;
    String hmacKey = Config().illiniCashHmacKey!;
    String? secretKey = Config().illiniCashSecretKey;

    String timestamp = (DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000).toInt().toString();
    String signingString = "$timestamp|$appKey|${context.amount}|$secretKey|${context.preAuthStatusResponse!.transId}";
    String signedString = _generateHmacSha1(signingString, hmacKey).toUpperCase();

    //String baseUrl = "https://web.housing.illinois.edu/Rokwirefinancial/TrustCommerce.asmx/ProcessTransaction"; //"$PROCESS_TRANSACTION_HOST/FinTrans/TrustCommerce.asmx/ProcessTransaction";
    String? baseUrl = (Config().illiniCashPaymentHost != null) ? "${Config().illiniCashPaymentHost}/FinTrans/TrustCommerce.asmx/PostAuth" : null;


    Map<String,dynamic> params = {
      "appKey" : appKey ?? "",
      "signature" : signedString,
      "timeStamp" : timestamp,
      "uin" : context.uin ?? "",
      "emailAddress" : context.email ?? "",
      "amount" : context.amount ?? "",
      "ccID" : context.preAuthStatusResponse?.transId ?? "",
      "cclastfour" : context.cardResponse?.lastFour ?? "",
      "authcode" : context.preAuthStatusResponse!.authCode,
      "firstName" : context.firstName ?? "",
      "lastName" : context.lastName ?? "",
    };

    String paramsString = json.encode(params);

    final response = await Network().post(baseUrl,
        headers: {'Content-Type':'application/json'},
        body: paramsString,
    );

    String? responseString = response?.body;
    if ((response != null) && response.statusCode >= 200 &&
        response.statusCode <= 301) {
      Map<String, dynamic>? jsonData = JsonUtils.decode(responseString);
      if (jsonData != null) {
        Map<String, dynamic>? innerData = jsonData["d"];
        if (innerData != null && innerData.isNotEmpty) {
          String? status = innerData["Status"];
          String? message = innerData["Message"];

          if (status != "0") {
            _throwBuyIlliniCashError(message);
          }
          else {
            updateBalance();
            NotificationService().notify(notifyPaymentSuccess, null);
          }
        }
        else {
          _throwBuyIlliniCashError(null);
        }
      }
    }
    else {
      _throwBuyIlliniCashError(responseString);
    }
  }

  Future<String?> _loadPreAuthToken(String? token, String? billingId) async{

    String? baseUrl = (Config().illiniCashTokenHost != null) ? "${Config().illiniCashTokenHost}/financeWS/cc/token/edu.uillinois.aits.uiDining/$token/preauth/$billingId" : null;

    Response? response = await Network().get(baseUrl);
    if ((response != null) && response.statusCode >= 200 &&
        response.statusCode <= 301) {
      return response.body;
    }
    return null;
  }

  Future<String?> _loadDataToken() async {

    String? url = (Config().illiniCashTokenHost != null) ? "${Config().illiniCashTokenHost}/aitsWS/security/generateDataToken" : null;
    Map<String,String> headers = {
      "Content-Type": "application/json",
      "X-senderAppId": "edu.uillinois.aits.uiDining",
    };

    Response? response = await Network().post(url, headers: headers);
    if ((response != null) && response.statusCode >= 200 &&
        response.statusCode <= 301) {
      String xmlString = response.body;

      XmlDocument document = XmlDocument.parse(xmlString);
      Iterable<XmlElement> tokenElements = document.findAllElements("Token");

      if(tokenElements.isNotEmpty){
        for(XmlElement element in tokenElements){
          if(element.name.local == "Token"){
            return element.innerText;
          }
        }
      }
    }

    return null;
  }

  Future<String?> _loadStoreToken(String? token) async{

    String? baseUrl = (Config().illiniCashTokenHost != null) ? "${Config().illiniCashTokenHost}/financeWS/cc/token/edu.uillinois.aits.uiDining/$token/store" : null;

    Response? response = await Network().get(baseUrl);
    if ((response != null) && response.statusCode >= 200 &&
        response.statusCode <= 301) {
      return response.body;
    }
    return null;
  }

  Future<_StatusResponse?> _completeToken(String? token, String? paymentToken) async{

    if(StringUtils.isNotEmpty(token) && StringUtils.isNotEmpty(paymentToken)) {
      String? baseUrl = (Config().illiniCashTokenHost != null) ? "${Config().illiniCashTokenHost}/financeWS/cc/complete/edu.uillinois.aits.uiDining/$token/$paymentToken" : null;

      Response? response = await Network().get(baseUrl);
      if ((response != null) && response.statusCode >= 200 &&
          response.statusCode <= 301) {
        return _StatusResponse.fromString(response.body);
      }
    }
    return null;
  }

  /////////////////////////
  // Enabled

  bool get _enabled => StringUtils.isNotEmpty(Config().illiniCashBaseUrl);

  /////////////////////////
  // Helpers

  void _throwBuyIlliniCashError(String? message){
    if(StringUtils.isEmpty(message)) {
      throw BuyIlliniCashException(Localization().getStringEx(
          "panel.settings.add_illini_cash.error.buy_illini_cash.text",
          "Unable to complete transaction. Please try again later."));
    }
    else{
      throw BuyIlliniCashException(message);
    }
  }

  String _generateHmacSha1(String hashString, String hmacKey){

    var key = utf8.encode(hmacKey);
    var bytes = utf8.encode(hashString);

    var hmacSha256 = new Hmac(sha1, key);
    return hex.encode(hmacSha256.convert(bytes).bytes);
  }
}

class _TransactionContext{
  final String? firstName;
  final String? lastName;
  final String? uin;
  final String? email;
  final String? cc;
  final String? expiry;
  final String? cvv;
  final String? amount;

  _CreditCardResponse? cardResponse;
  _StatusResponse? cardStatusResponse;

  // No reason to keep this piece for now
  //_CreditCardResponse preAuthResponse;
  _StatusResponse? preAuthStatusResponse;

  String get name{
    return "$firstName $lastName";
  }

  _TransactionContext({this.firstName, this.lastName, this.uin, this.email, this.cc, this.expiry, this.cvv, this.amount});
}

class _CreditCardResponse{
  final String? name;
  final String? lastFour;
  final String? exp;
  _CreditCardResponse({this.name, this.lastFour, this.exp});

  static _CreditCardResponse? fromXMLString(String? xmlString){
    XmlDocument? document;
    try {
      document = (xmlString != null) ? XmlDocument.parse(xmlString) : null;
    }
    catch(e) {
      print(e.toString());
    }

    return (document != null) ? _CreditCardResponse(
      name: _getValueFromXmlItem(document, "name"),
      lastFour: _getValueFromXmlItem(document, "cc"),
      exp: _getValueFromXmlItem(document, "exp")
    ) : null;
  }

  static _getValueFromXmlItem(XmlDocument? document, String? elementName){
    if(document != null && elementName != null){
      var elements = document.findAllElements(elementName);
      for(XmlElement element in elements){
        if(element.name.local == elementName) {
          return element.innerText;
        }
      }
    }

    return null;
  }
}

class _StatusResponse{
  final String? transId;
  final String? authCode;
  final String? billingId;
  final String? status;

  _StatusResponse({this.transId, this.authCode, this.billingId, this.status});

  static _StatusResponse? fromString(String? value){
    List<String>? lines = value?.split(" ");

    if (lines != null) {
      String? transId;
      String? authCode;
      String? billingId;
      String? status;


      for(String line in lines){
        List<String> cells = line.split("=");
        if(cells.length > 1){
          if("authcode" == cells[0]){
            authCode = cells[1];
          }
          if("transid" == cells[0]){
            transId = cells[1];
          }
          else if("status" == cells[0]){
            status = cells[1];
          }
          else if("billingid" == cells[0]){
            billingId = cells[1];
          }
        }
      }

      return _StatusResponse(
        transId: transId,
        authCode: authCode,
        billingId: billingId,
        status: status,
      );
    }
    else {
      return null;
    }
  }
}

class BuyIlliniCashException implements Exception{
  final String? message;
  BuyIlliniCashException(this.message);
}