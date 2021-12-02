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

//////////////////////////////
/// IlliniCashBallance

class IlliniCashBallance {
  String? mealPlanName;
  double? balance;
  double? cafeCreditBalance;
  int? mealBalance;
  String? status;
  bool? housingResidenceStatus;

  IlliniCashBallance(
      {this.mealPlanName,
      this.balance = 0.0,
      this.cafeCreditBalance = 0.0,
      this.mealBalance = 0,
      this.status,
      this.housingResidenceStatus = false});

  String get balanceDisplayText {
    return _formatBalance(balance!);
  }

  String get cafeCreditBalanceDisplayText {
    return _formatBalance(cafeCreditBalance!);
  }

  String get mealBalanceDisplayText {
    return mealBalance.toString();
  }

  bool equals(IlliniCashBallance o) {
    return (o is IlliniCashBallance) &&
      (o.mealPlanName == mealPlanName) &&
      (o.balance == balance) &&
      (o.mealBalance == mealBalance) &&
      (o.cafeCreditBalance == cafeCreditBalance) &&
      (o.status == status) &&
      (o.housingResidenceStatus == housingResidenceStatus);
  }


  static IlliniCashBallance? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? IlliniCashBallance(
        mealPlanName: json['MealPlanName'],
        balance: json['IllinCashBalance'],
        cafeCreditBalance: json['CafeCreditBalance'],
        mealBalance: json['MPBalance'],
        status: json['Status'],
        housingResidenceStatus: json['HousingResidentStatus']) : null;
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

  String _formatBalance(double value) {
    return '\$ ' + value.toStringAsFixed(2);
  }
}
