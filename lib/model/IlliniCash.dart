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

import 'package:intl/intl.dart';
import 'package:rokwire_plugin/utils/utils.dart';

//////////////////////////////
/// IlliniCashBallance

class IlliniCashBallance {
  final String? mealPlanName;
  final double? balance;
  final double? cafeCreditBalance;
  final int? mealBalance;
  final String? status;
  final bool? housingResidenceStatus;

  IlliniCashBallance(
      {this.mealPlanName,
      this.balance,
      this.cafeCreditBalance,
      this.mealBalance,
      this.status,
      this.housingResidenceStatus});

  static IlliniCashBallance? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? IlliniCashBallance(
      mealPlanName:           JsonUtils.stringValue(json['MealPlanName']) ,
      balance:                JsonUtils.doubleValue(json['IllinCashBalance']) ,
      cafeCreditBalance:      JsonUtils.doubleValue(json['CafeCreditBalance']),
      mealBalance:            JsonUtils.intValue(json['MPBalance']),
      status:                 JsonUtils.stringValue(json['Status']),
      housingResidenceStatus: JsonUtils.boolValue(json['HousingResidentStatus'])
    ): null;
  }

  Map<String, dynamic> toJson() {
    return {
      'MealPlanName': mealPlanName,
      'IllinCashBalance': balance,
      'CafeCreditBalance': cafeCreditBalance,
      'MPBalance': mealBalance,
      'Status': status,
      'HousingResidentStatus': housingResidenceStatus
    };
  }

  @override
  bool operator ==(other) =>
      other is IlliniCashBallance &&
          other.mealPlanName == mealPlanName &&
          other.balance == balance &&
          other.cafeCreditBalance == cafeCreditBalance &&
          other.mealBalance == mealBalance &&
          other.status == status &&
          other.housingResidenceStatus == housingResidenceStatus;

  @override
  int get hashCode =>
      (mealPlanName?.hashCode ?? 0) ^
      (balance?.hashCode ?? 0) ^
      (cafeCreditBalance?.hashCode ?? 0) ^
      (mealBalance?.hashCode ?? 0) ^
      (status?.hashCode ?? 0) ^
      (housingResidenceStatus?.hashCode ?? 0);


  String get balanceDisplayText           =>  _formatBalance(balance ?? 0);
  String get cafeCreditBalanceDisplayText =>  _formatBalance(cafeCreditBalance ?? 0);
  String get mealBalanceDisplayText       =>  mealBalance.toString();

  String _formatBalance(double value) => '\$ ${value.toStringAsFixed(2)}';
}

//////////////////////////////
/// BaseTransaction

abstract class BaseTransaction {
  String? dateString;
  String? description;
  String? location;
  String? amount;

  BaseTransaction(
      {this.dateString, this.description, this.location, this.amount});

}

//////////////////////////////
/// IlliniCashTransaction

class IlliniCashTransaction extends BaseTransaction {

  static final String dateFormat = 'MM-dd-yyyy';

  IlliniCashTransaction(
      {String? dateString, String? description, String? location, String? amount}):
        super(dateString: dateString, description: description, location: location, amount: amount);

  static IlliniCashTransaction? fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) {
      return null;
    }
    double amount = double.parse(json['Amount']);
    String amountString = NumberFormat("\$ 0.00").format(amount);

    return IlliniCashTransaction(
      dateString: json['Date'],
      description: json['Description'],
      location: json['Location'],
      amount: amountString,
    );
  }
}

//////////////////////////////
/// MealPlanTransaction

class MealPlanTransaction extends BaseTransaction{

  MealPlanTransaction(
      {String? dateString, String? description, String? location, String? amount}):
        super(dateString: dateString, description: description, location: location, amount: amount);

  static MealPlanTransaction? fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) {
      return null;
    }

    return MealPlanTransaction(
      dateString: json['Date'],
      description: json['Description'],
      location: json['Location'],
      amount: json['Amount'],
    );
  }
}

//////////////////////////////
/// CafeCreditTransaction

class CafeCreditTransaction extends BaseTransaction{

  CafeCreditTransaction(
      {String? dateString, String? description, String? location, String? amount}):
        super(dateString: dateString, description: description, location: location, amount: amount);

  static CafeCreditTransaction? fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) {
      return null;
    }
    double amount = double.parse(json['Amount']);
    String amountString = NumberFormat("\$ 0.00").format(amount);

    return CafeCreditTransaction(
      dateString: json['Date'],
      description: json['Description'],
      location: json['Location'],
      amount: amountString,
    );
  }
}