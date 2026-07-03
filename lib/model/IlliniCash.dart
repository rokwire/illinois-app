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
      housingResidenceStatus: JsonUtils.boolValue(json['HousingResidentStatus']),
    ): null;
  }

  Map<String, dynamic> toJson() {
    return {
      'MealPlanName':           mealPlanName,
      'IllinCashBalance':       balance,
      'CafeCreditBalance':      cafeCreditBalance,
      'MPBalance':              mealBalance,
      'Status':                 status,
      'HousingResidentStatus' : housingResidenceStatus
    };
  }

  dynamic fieldValue(String fieldName) {
    switch (fieldName) {
      case 'MealPlanName':          return mealPlanName;
      case 'IllinCashBalance':      return balance;
      case 'CafeCreditBalance':     return cafeCreditBalance;
      case 'MPBalance':             return mealBalance;
      case 'Status':                return status;
      case 'HousingResidentStatus': return housingResidenceStatus;
    }
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
/// IlliniCashEligibility

class IlliniCashEligibility {
  final bool? eligible;
  final String? accountStatus;

  IlliniCashEligibility({this.eligible, this.accountStatus});

  static IlliniCashEligibility? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? IlliniCashEligibility(
      eligible:      JsonUtils.boolValue(json['IlliniCashEligible']),
      accountStatus: JsonUtils.stringValue(json['AccountStatus']),
    ): null;
  }

  Map<String, dynamic> toJson() {
    return {
      'IlliniCashEligible': eligible,
      'AccountStatus': accountStatus,
    };
  }

  @override
  bool operator ==(other) =>
    other is IlliniCashEligibility &&
      other.eligible == eligible &&
      other.accountStatus == accountStatus;

  @override
  int get hashCode =>
    (eligible?.hashCode ?? 0) ^
    (accountStatus?.hashCode ?? 0);
}

//////////////////////////////
/// IlliniStudentClassification

class IlliniStudentClassification {
  final String? termCode;
  final String? admittedTerm;
  final String? studentType;
  final String? studentTypeCode;
  final String? collegeName;
  final String? collegeCode;
  final String? departmentName;
  final String? departmentCode;
  final String? department2;
  final String? major;
  final String? major2;
  final String? studentLevelCode;
  final String? studentLevelDescription;
  final String? classification;
  final String? recordType;
  final String? ferpaSuppressed;
  final bool? firstYear;
  final bool? isHousingResident;

  IlliniStudentClassification({
    this.termCode, this.admittedTerm,
    this.studentType, this.studentTypeCode,
    this.collegeName, this.collegeCode,
    this.departmentName, this.departmentCode, this.department2,
    this.major, this.major2,
    this.studentLevelCode, this.studentLevelDescription,
    this.classification, this.recordType,
    this.ferpaSuppressed, this.firstYear, this.isHousingResident
  });

  static IlliniStudentClassification? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? IlliniStudentClassification(
      termCode:                  JsonUtils.stringValue(json['TermCode']),
      admittedTerm:              JsonUtils.stringValue(json['AdmittedTerm']),
      studentType:               JsonUtils.stringValue(json['StudentType']),
      studentTypeCode:           JsonUtils.stringValue(json['StudentTypeCode']),
      collegeName:               JsonUtils.stringValue(json['CollegeName']),
      collegeCode:               JsonUtils.stringValue(json['CollegeCode']),
      departmentName:            JsonUtils.stringValue(json['DepartmentName']),
      departmentCode:            JsonUtils.stringValue(json['DepartmentCode']),
      department2:               JsonUtils.stringValue(json['SecondDept']),
      major:                     JsonUtils.stringValue(json['Major']),
      major2:                    JsonUtils.stringValue(json['SecondMajor']),
      studentLevelCode:          JsonUtils.stringValue(json['StudentLevelCode']),
      studentLevelDescription:   JsonUtils.stringValue(json['StudentLevelDescription']),
      classification:            JsonUtils.stringValue(json['Classification']),
      recordType:                JsonUtils.stringValue(json['RecordType']),
      ferpaSuppressed:           JsonUtils.stringValue(json['FerpaSuppressed']),
      firstYear:                 JsonUtils.boolValue(json['FirstYear']),
      isHousingResident:         JsonUtils.boolValue(json['IsHousingResident'])
    ): null;
  }

  Map<String, dynamic> toJson() {
    return {
      'TermCode':                termCode,
      'AdmittedTerm':            admittedTerm,
      'StudentType':             studentType,
      'StudentTypeCode':         studentTypeCode,
      'CollegeName':             collegeName,
      'CollegeCode':             collegeCode,
      'DepartmentName':          departmentName,
      'DepartmentCode':          departmentCode,
      'SecondDept':              department2,
      'Major':                   major,
      'SecondMajor':             major2,
      'StudentLevelCode':        studentLevelCode,
      'StudentLevelDescription': studentLevelDescription,
      'Classification':          classification,
      'RecordType':              recordType,
      'FerpaSuppressed':         ferpaSuppressed,
      'FirstYear':               firstYear,
      'IsHousingResident':       isHousingResident,
    };
  }

  dynamic fieldValue(String fieldName) {
    switch(fieldName) {
      case 'TermCode':                return termCode;
      case 'AdmittedTerm':            return admittedTerm;
      case 'StudentType':             return studentType;
      case 'StudentTypeCode':         return studentTypeCode;
      case 'CollegeName':             return collegeName;
      case 'CollegeCode':             return collegeCode;
      case 'DepartmentName':          return departmentName;
      case 'DepartmentCode':          return departmentCode;
      case 'SecondDept':              return department2;
      case 'Major':                   return major;
      case 'SecondMajor':             return major2;
      case 'StudentLevelCode':        return studentLevelCode;
      case 'StudentLevelDescription': return studentLevelDescription;
      case 'Classification':          return classification;
      case 'RecordType':              return recordType;
      case 'FerpaSuppressed':         return ferpaSuppressed;
      case 'FirstYear':               return firstYear;
      case 'IsHousingResident':       return isHousingResident;
      default:                        return null;
    }
  }

  @override
  bool operator ==(other) =>
    other is IlliniStudentClassification &&
      other.termCode == termCode &&
      other.admittedTerm == admittedTerm &&
      other.studentType == studentType &&
      other.studentTypeCode == studentTypeCode &&
      other.collegeName == collegeName &&
      other.collegeCode == collegeCode &&
      other.departmentName == departmentName &&
      other.departmentCode == departmentCode &&
      other.department2 == department2 &&
      other.major == major &&
      other.major2 == major2 &&
      other.studentLevelCode == studentLevelCode &&
      other.studentLevelDescription == studentLevelDescription &&
      other.classification == classification &&
      other.recordType == recordType &&
      other.ferpaSuppressed == ferpaSuppressed &&
      other.firstYear == firstYear &&
      other.isHousingResident == isHousingResident;

  @override
  int get hashCode =>
    (termCode?.hashCode ?? 0) ^
    (admittedTerm?.hashCode ?? 0) ^
    (studentType?.hashCode ?? 0) ^
    (studentTypeCode?.hashCode ?? 0) ^
    (collegeName?.hashCode ?? 0) ^
    (collegeCode?.hashCode ?? 0) ^
    (departmentName?.hashCode ?? 0) ^
    (departmentCode?.hashCode ?? 0) ^
    (department2?.hashCode ?? 0) ^
    (major?.hashCode ?? 0) ^
    (major2?.hashCode ?? 0) ^
    (studentLevelCode?.hashCode ?? 0) ^
    (studentLevelDescription?.hashCode ?? 0) ^
    (classification?.hashCode ?? 0) ^
    (recordType?.hashCode ?? 0) ^
    (ferpaSuppressed?.hashCode ?? 0) ^
    (firstYear?.hashCode ?? 0) ^
    (isHousingResident?.hashCode ?? 0);
}

//////////////////////////////
/// IlliniStudentSummary

class IlliniStudentSummary {
  final IlliniCashEligibility? eligibility;
  final IlliniStudentClassification? classification;

  IlliniStudentSummary({this.eligibility, this.classification});

  static IlliniStudentSummary? fromJson(Map<String, dynamic>? json) {
    return (json != null) ? IlliniStudentSummary(
      eligibility:    IlliniCashEligibility.fromJson(JsonUtils.mapValue(json['IlliniCashEligibility'])) ,
      classification: IlliniStudentClassification.fromJson(JsonUtils.mapValue(json['StudentClassification'])),
    ): null;
  }

  Map<String, dynamic> toJson() {
    return {
      'IlliniCashEligibility': eligibility,
      'StudentClassification': classification,
    };
  }

  @override
  bool operator ==(other) =>
    other is IlliniStudentSummary &&
      other.eligibility == eligibility &&
      other.classification == classification;

  @override
  int get hashCode =>
    (eligibility?.hashCode ?? 0) ^
    (classification?.hashCode ?? 0);
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

  static List<IlliniCashTransaction>? listFromJson(List<dynamic>? jsonList) {
    List<IlliniCashTransaction>? result;
    if (jsonList != null) {
      result = <IlliniCashTransaction>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(result, IlliniCashTransaction.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return result;
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

  static List<MealPlanTransaction>? listFromJson(List<dynamic>? jsonList) {
    List<MealPlanTransaction>? result;
    if (jsonList != null) {
      result = <MealPlanTransaction>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(result, MealPlanTransaction.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return result;
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

  static List<CafeCreditTransaction>? listFromJson(List<dynamic>? jsonList) {
    List<CafeCreditTransaction>? result;
    if (jsonList != null) {
      result = <CafeCreditTransaction>[];
      for (dynamic jsonEntry in jsonList) {
        ListUtils.add(result, CafeCreditTransaction.fromJson(JsonUtils.mapValue(jsonEntry)));
      }
    }
    return result;
  }
}