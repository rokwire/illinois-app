import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:illinois/model/occupation/Occupation.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/skills/IOccupationsData.dart';

class OnetOccupationsData implements IOccupationsData {
  static const String _baseUrl = 'https://services.onetcenter.org/ws/online/';
  static String? username = Config().onetUsername;
  static String? password = Config().onetPassword;

  late final Dio _dio;

  OnetOccupationsData() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        headers: {
          'Authorization': base64.encode(utf8.encode('$username:$password')),
          'Accept': 'application/json',
        },
        responseType: ResponseType.json,
      ),
    );
    // ..interceptors.add(InterceptorsWrapper(
    //     onRequest: (options, handler) {
    //       debugPrint(options.uri.toString());
    //     },
    //   ));
  }

  @override
  Future<List<Occupation>> getAllOccupations() async {
    // TODO: implement getAllOccupations
    return [
      Occupation(
        code: '17-2051.00',
        title: 'Software Developer',
        description: 'Die from segmentation fault',
        matchPercentage: 75.0,
        onetLink: '',
        skills: [],
        technicalSkills: [],
      ),
    ];
    // try {
    //   final response = await _dio.get('occupations/');
    //   debugPrint("Response Code: ${response.statusCode}");
    //   debugPrint("Respone Data: ${response.data}");
    //   if (response.statusCode == 200) {
    //     final result = json['occupation'][]
    //     debugPrint(result);
    //     return result;
    //   }
    // } catch (e) {
    //   debugPrint("Respnse error: $e");
    //   return Occupation(
    //     title: 'Software Developer',
    //     description: 'Die from segmentation fault',
    //     matchPercentage: 75.0,
    //     onetLink: '',
    //     skills: [],
    //     technicalSkills: [],
    //   );
    // }
    // throw UnimplementedError();
  }

  @override
  Future<Occupation> getOccupation({required String occupationCode}) async {
    // TODO: implement getOccupation
    try {
      final response = await _dio.get(
        'occupations/$occupationCode/summary',
        queryParameters: {
          'display': 'long',
        },
      );
      debugPrint("Response Code: ${response.statusCode}");
      debugPrint("Respone Data: ${response.data}");
      if (response.statusCode == 200) {
        final result = Occupation.fromJson(response.data as Map<String, dynamic>);
        debugPrint(result.toString());
        return result;
      }
    } catch (e) {
      debugPrint("Respnse error: $e");
    }
    return Occupation(
      title: 'Software Developer',
      description: 'Die from segmentation fault',
      matchPercentage: 75.0,
      onetLink: '',
      skills: [],
      technicalSkills: [],
    );
    // throw UnimplementedError();
  }

  @override
  Future<List<Occupation>> getOccupationsByKeyword({required String keyword}) {
    // TODO: implement getOccupationsByKeyword
    throw UnimplementedError();
  }

  @override
  Future<List<Occupation>> getTop10Occupations() async {
    // TODO: implement getTop10Occupations
    // 'online/occupations/'
    throw UnimplementedError();
  }
}
