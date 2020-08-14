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

abstract class BaseTransaction {
  String dateString;
  String description;
  String location;
  String amount;

  BaseTransaction(
      {this.dateString, this.description, this.location, this.amount});

}

class IlliniCashTransaction extends BaseTransaction {

  IlliniCashTransaction(
      {String dateString, String description, String location, String amount}):
        super(dateString: dateString, description: description, location: location, amount: amount);

  factory IlliniCashTransaction.fromJson(Map<String, dynamic> json) {
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

class MealPlanTransaction extends BaseTransaction{

  MealPlanTransaction(
      {String dateString, String description, String location, String amount}):
        super(dateString: dateString, description: description, location: location, amount: amount);

  factory MealPlanTransaction.fromJson(Map<String, dynamic> json) {
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

class CafeCreditTransaction extends BaseTransaction{

  CafeCreditTransaction(
      {String dateString, String description, String location, String amount}):
        super(dateString: dateString, description: description, location: location, amount: amount);

  factory CafeCreditTransaction.fromJson(Map<String, dynamic> json) {
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