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
import 'dart:io';
import 'dart:typed_data';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/firebase_crashlytics.dart';
import 'package:rokwire_plugin/service/log.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/utils/utils.dart';

abstract class NetworkAuthProvider {
  Map<String, String>? get networkAuthHeaders;
  dynamic get networkAuthToken => null;
  Future<bool> refreshNetworkAuthTokenIfNeeded(http.BaseResponse? response, dynamic token) async => false;
}

class Network  {

  static const String notifyHttpResponse  = "edu.illinois.rokwire.network.http_response";
  static const String notifyHttpRequestUrl  = "requestUrl";
  static const String notifyHttpRequestMethod  = "requestMethod";
  static const String notifyHttpResponseCode  = "responseCode";

  // Singleton Factory

  static Network? _instance;

  static Network? get instance => _instance;

  @protected
  static set instance(Network? value) => _instance = value;

  factory Network() => _instance ?? (_instance = Network.internal());

  @protected
  Network.internal();

  // Implementation

  Future<http.Response?> _get2(dynamic url, { String? body, Encoding? encoding, Map<String, String?>? headers, int? timeout, http.Client? client }) async {
    try {
      
      Uri? uri = _uriFromUrlString(url);

      if (uri != null) {
        
        http.Client? localClient;
        client ??= (localClient = http.Client());

        http.Request request = http.Request("GET", uri);
        
        if (headers != null) {
          headers.forEach((String key, String? value) {
            if (value != null) {
              request.headers[key] = value;
            }
          });
        }
        
        if (encoding != null) {
          request.encoding = encoding;  
        }
        
        if (body != null) {
          request.body = body;
        }

        Future<http.StreamedResponse?>? responseStreamFuture = client.send(request);
        if ((timeout != null)) {
          responseStreamFuture = responseStreamFuture.timeout(Duration(seconds: timeout));
        }

        http.StreamedResponse? responseStream = await responseStreamFuture;

        if (localClient != null) {
          localClient.close();
        }

        return (responseStream != null) ? http.Response.fromStream(responseStream) : null;
      }
    } catch (e) { 
      Log.d(e.toString());
      FirebaseCrashlytics().recordError(e, null);
    }
    return null;
  }

  Future<http.Response?> _get(url, { String? body, Encoding? encoding, Map<String, String?>? headers, NetworkAuthProvider? auth, int? timeout, http.Client? client} ) async {
    if (Connectivity().isNotOffline) {
      try {
        Uri? uri = _uriFromUrlString(url);
        if (uri != null) {

          Map<String, String>? requestHeaders = await _prepareHeaders(headers, auth, uri);

          Future<http.Response?> response;
          if (body != null) {
            response = _get2(uri, headers: requestHeaders, body: body, encoding: encoding, timeout: timeout, client: client);
          }
          else if (client != null) {
            response = client.get(uri, headers: requestHeaders);
          }
          else {
            response = http.get(uri, headers: requestHeaders);
          }
          
          if (timeout != null) {
            response = response.timeout(Duration(seconds: timeout), onTimeout: _responseTimeoutHandler);
          }

          return response;
        }
      } catch (e) { 
        Log.d(e.toString());
        FirebaseCrashlytics().recordError(e, null);
      }
    }
    return null;
  }

  Future<http.Response?> get(url, { String? body, Encoding? encoding, Map<String, String?>? headers, NetworkAuthProvider? auth, http.Client? client, int? timeout = 60, bool sendAnalytics = true, String? analyticsUrl }) async {
    http.Response? response;

    try {
      dynamic token = auth?.networkAuthToken;
      response = await _get(url, headers: headers, body: body, encoding: encoding, auth: auth, client: client, timeout: timeout);
      
      if (await auth?.refreshNetworkAuthTokenIfNeeded(response, token) == true) {
        response = await _get(url, body: body, headers: headers, auth: auth, client: client, timeout: timeout);
      }
    } catch (e) { 
      Log.d(e.toString());
      FirebaseCrashlytics().recordError(e, null);
    }

    if (sendAnalytics) {
      NotificationService().notify(notifyHttpResponse, _notifyHttpResponseParam(response, analyticsUrl: analyticsUrl));
    }

    _saveCookiesFromResponse(url, response);
    
    return response;
  }

  Future<http.Response?> _post(url, { Object? body, Encoding? encoding, Map<String, String?>? headers, NetworkAuthProvider? auth, int? timeout}) async{
    if (Connectivity().isNotOffline) {
      try {
        Uri? uri = _uriFromUrlString(url);
        Future<http.Response?>? response = (uri != null) ? http.post(uri, headers: await _prepareHeaders(headers, auth, uri), body: body, encoding: encoding) : null;
        return ((response != null) && (timeout != null)) ? response.timeout(Duration(seconds: timeout), onTimeout: _responseTimeoutHandler) : response;
      } catch (e) {
        Log.d(e.toString());
        FirebaseCrashlytics().recordError(e, null);
      }
    }
    return null;
  }

  Future<http.Response?> post(url, {Object? body, Encoding? encoding, Map<String, String?>? headers, NetworkAuthProvider? auth, int? timeout = 60, bool sendAnalytics = true, String? analyticsUrl }) async{
    http.Response? response;
    
    try {
      dynamic token = auth?.networkAuthToken;
      response = await _post(url, body: body, encoding: encoding, headers: headers, auth: auth, timeout: timeout);
      
      if (await auth?.refreshNetworkAuthTokenIfNeeded(response, token) == true) {
        response = await _post(url, body: body, encoding: encoding, headers: headers, auth: auth, timeout: timeout);
      }
    } catch (e) {
      Log.d(e.toString());
      FirebaseCrashlytics().recordError(e, null);
    }

    if (sendAnalytics) {
      NotificationService().notify(notifyHttpResponse, _notifyHttpResponseParam(response, analyticsUrl: analyticsUrl));
    }

    _saveCookiesFromResponse(url, response);

    return response;
  }

  Future<http.Response?> _put(url, {Object? body, Encoding? encoding, Map<String, String?>? headers, NetworkAuthProvider? auth, int? timeout, http.Client? client }) async {
    if (Connectivity().isNotOffline) {
      try {
        Uri? uri = _uriFromUrlString(url);
        Future<http.Response?>? response = (uri != null) ?
          ((client != null) ?
            client.put(uri, headers: await _prepareHeaders(headers, auth, uri), body: body, encoding: encoding) :
              http.put(uri, headers: await _prepareHeaders(headers, auth, uri), body: body, encoding: encoding)) :
            null;

        return ((response != null) && (timeout != null)) ? response.timeout(Duration(seconds: timeout), onTimeout: _responseTimeoutHandler) : response;

      } catch (e) {
        Log.d(e.toString());
        FirebaseCrashlytics().recordError(e, null);
      }
    }
    return null;
  }

  Future<http.Response?> put(url, {Object? body, Encoding? encoding, Map<String, String?>? headers, NetworkAuthProvider? auth, int? timeout = 60, http.Client? client, bool sendAnalytics = true, String? analyticsUrl }) async {
    http.Response? response;
    
    try {
      dynamic token = auth?.networkAuthToken;
      response = await _put(url, body: body, encoding: encoding, headers: headers, auth: auth, timeout: timeout, client: client);
      
      if (await auth?.refreshNetworkAuthTokenIfNeeded(response, token) == true) {
        response = await _put(url, body: body, encoding: encoding, headers: headers, auth: auth, timeout: timeout, client: client);
      }
    } catch (e) {
      Log.d(e.toString());
      FirebaseCrashlytics().recordError(e, null);
    }

    if (sendAnalytics) {
      NotificationService().notify(notifyHttpResponse, _notifyHttpResponseParam(response, analyticsUrl: analyticsUrl));
    }

    _saveCookiesFromResponse(url, response);

    return response;
  }

  Future<http.Response?> _patch(url, {Object? body, Encoding? encoding, Map<String, String?>? headers, NetworkAuthProvider? auth, int? timeout }) async {
    if (Connectivity().isNotOffline) {
      try {
        Uri? uri = _uriFromUrlString(url);
        Future<http.Response?>? response = (uri != null) ? http.patch(uri, headers: await _prepareHeaders(headers, auth, uri), body: body, encoding: encoding) : null;
        return ((response != null) && (timeout != null)) ? response.timeout(Duration(seconds: timeout), onTimeout: _responseTimeoutHandler) : response;
      } catch (e) {
        Log.d(e.toString());
        FirebaseCrashlytics().recordError(e, null);
      }
    }
    return null;
  }

  Future<http.Response?> patch(url, {Object? body, Encoding? encoding, Map<String, String?>? headers, NetworkAuthProvider? auth, int? timeout = 60, bool sendAnalytics = true, String? analyticsUrl }) async {
    http.Response? response;
    
    try {    
      dynamic token = auth?.networkAuthToken;
      response = await _patch(url, body: body, encoding: encoding, headers: headers, auth: auth, timeout: timeout);
      
      if (await auth?.refreshNetworkAuthTokenIfNeeded(response, token) == true) {
        response = await _patch(url, body: body, encoding: encoding, headers: headers, auth: auth, timeout: timeout);
      }
    } catch (e) {
      Log.d(e.toString());
      FirebaseCrashlytics().recordError(e, null);
    }

    if (sendAnalytics) {
      NotificationService().notify(notifyHttpResponse, _notifyHttpResponseParam(response, analyticsUrl: analyticsUrl));
    }

    _saveCookiesFromResponse(url, response);

    return response;
  }

  Future<http.Response?> _delete(url, {Object? body, Encoding? encoding, Map<String, String?>? headers, NetworkAuthProvider? auth, int? timeout }) async {
    if (Connectivity().isNotOffline) {
      try {
        Uri? uri = _uriFromUrlString(url);
        Future<http.Response?>? response = (uri != null) ? http.delete(uri, headers: await _prepareHeaders(headers, auth, uri), body: body, encoding: encoding) : null;
        return ((response != null) && (timeout != null)) ? response.timeout(Duration(seconds: timeout), onTimeout: _responseTimeoutHandler) : response;
      } catch (e) {
        Log.d(e.toString());
        FirebaseCrashlytics().recordError(e, null);
      }
    }
    return null;
  }

  Future<http.Response?> delete(url, {Object? body, Encoding? encoding, Map<String, String?>? headers, NetworkAuthProvider? auth, int? timeout = 60, bool sendAnalytics = true, String? analyticsUrl }) async {
    http.Response? response;
    try {
      dynamic token = auth?.networkAuthToken;
      response = await _delete(url, body: body, encoding:encoding, headers: headers, auth: auth, timeout: timeout);
      
      if (await auth?.refreshNetworkAuthTokenIfNeeded(response, token) == true) {
        response = await _delete(url, body: body, encoding:encoding, headers: headers, auth: auth, timeout: timeout);
      }
    } catch (e) {
      Log.d(e.toString());
      FirebaseCrashlytics().recordError(e, null);
    }

    if (sendAnalytics) {
      NotificationService().notify(notifyHttpResponse, _notifyHttpResponseParam(response, analyticsUrl: analyticsUrl));
    }

    _saveCookiesFromResponse(url, response);

    return response;
  }

  Future<String?> _read(url, { Map<String, String?>? headers, NetworkAuthProvider? auth, int? timeout = 60 }) async {
    if (Connectivity().isNotOffline) {
      try {
        Uri? uri = _uriFromUrlString(url);
        Future<String>? response = (uri != null) ? http.read(uri, headers: await _prepareHeaders(headers, auth, uri)) : null;
        return ((response != null) && (timeout != null)) ? response.timeout(Duration(seconds: timeout)) : response;
      } catch (e) {
        Log.d(e.toString());
        FirebaseCrashlytics().recordError(e, null);
      }
    }
    return null;
  }

  Future<String?> read(url, { Map<String, String?>? headers, NetworkAuthProvider? auth, int? timeout = 60 }) async {
    try {
      return await _read(url, headers: headers, auth: auth, timeout: timeout);
    }
    catch (e) {
      Log.d(e.toString());
      FirebaseCrashlytics().recordError(e, null);
    }
    return null;
  }

  Future<Uint8List?> _readBytes(url, { Map<String, String?>? headers, NetworkAuthProvider? auth, int? timeout = 60 }) async{
    if (Connectivity().isNotOffline) {
      try {
        Uri? uri = _uriFromUrlString(url);
        Future<Uint8List?>? response = (uri != null) ? http.readBytes(uri, headers: await _prepareHeaders(headers, auth, uri)) : null;
        return ((response != null) && (timeout != null)) ? response.timeout(Duration(seconds: timeout), onTimeout: _responseBytesHandler) : response;
      } catch (e) {
        Log.d(e.toString());
        FirebaseCrashlytics().recordError(e, null);
      }
    }
    return null;
  }

  Future<Uint8List?> readBytes(url, { Map<String, String?>? headers, NetworkAuthProvider? auth, int? timeout = 60 }) async {
    return _readBytes(url, headers: headers, auth: auth, timeout: timeout);
  }

  Future<http.StreamedResponse?> multipartPost({String? url, String? fileKey, List<int>? fileBytes, String? fileName, String? contentType, Map<String, String?>? headers, Map<String, String>? fields, NetworkAuthProvider? auth, bool refreshToken = true, bool sendAnalytics = true, String? analyticsUrl}) async {
    http.StreamedResponse? response;

    try {
      dynamic token = auth?.networkAuthToken;
      response = await _multipartPost(url: url, fileKey: fileKey, fileBytes: fileBytes, fileName: fileName, contentType: contentType, headers: headers, fields: fields, auth: auth);

      if (await auth?.refreshNetworkAuthTokenIfNeeded(response, token) == true) {
        response = await _multipartPost(url: url, fileKey: fileKey, fileBytes: fileBytes, fileName: fileName, contentType: contentType, headers: headers, fields: fields, auth: auth);
      }
    } catch (e) {
      Log.d(e.toString());
      FirebaseCrashlytics().recordError(e, null);
    }

    if (sendAnalytics) {
      NotificationService().notify(notifyHttpResponse, _notifyHttpResponseParam(response, analyticsUrl: analyticsUrl));
    }

    _saveCookiesFromResponse(url, response);

    return response;
  }

  Future<http.StreamedResponse?> _multipartPost({String? url, String? fileKey, List<int>? fileBytes, String? fileName, String? contentType, Map<String, String?>? headers, Map<String, String?>? fields, NetworkAuthProvider? auth}) async {
    if (Connectivity().isNotOffline) {
      try {
        Uri? uri = _uriFromUrlString(url);
        if (uri != null) {
          Map<String, String>? preparedHeaders = await _prepareHeaders(headers, auth, uri);
          http.MultipartRequest request = http.MultipartRequest("POST", uri);
          if (preparedHeaders != null) {
            request.headers.addAll(preparedHeaders);
          }

          Map<String, String>? preparedFields = _ensureMapValues(fields);
          if (preparedFields != null) {
            request.fields.addAll(preparedFields);
          }
          if ((fileKey != null) && (fileBytes != null)) {
            http.MultipartFile multipartFile = http.MultipartFile.fromBytes(fileKey, fileBytes, filename: fileName, contentType: (contentType != null) ? MediaType.parse(contentType) : null);
            request.files.add(multipartFile);
            http.StreamedResponse response = await request.send();
            return response;
          }
        }
      } catch (e) {
        Log.d(e.toString());
        FirebaseCrashlytics().recordError(e, null);
      }
    }
    return null;
  }

  // NetworkAuth

  Future<Map<String, String>?> _prepareHeaders(Map<String, String?>? headers, NetworkAuthProvider? auth, Uri? uri) async {

    // authentication
    Map<String, String>? result = _prepareAuthHeaders(headers, auth);

    // cookies
    String? cookies = (uri != null) ? await _loadCookiesForRequest(uri) : null;
    if ((cookies != null) && cookies.isNotEmpty) {
      result ??= <String, String>{};
      result["Cookie"] = cookies;
    }

    return result;
  }

  Map<String, String>? _prepareAuthHeaders(Map<String, String?>? headers, NetworkAuthProvider? auth) {

    Map<String, String>? result = (headers != null) ? _ensureMapValues(headers) : null;

    Map<String, String>? authHeaders = auth?.networkAuthHeaders;
    if ((authHeaders != null) && authHeaders.isNotEmpty) {
      if (result != null) {
        result.addAll(authHeaders);
      }
      else {
        result = Map.from(authHeaders);
      }
    }

    return result;
  }

  static Map<String, String>? _ensureMapValues(Map<String, String?>? headers) {
    Map<String, String>? result = <String, String>{};
    headers?.forEach((key, value) {
      if (value != null) {
        result[key] = value;
      }
    });
    return result;
  }

  http.Response _responseTimeoutHandler() {
    return http.Response('Request Timeout', 408);
  }

  Uint8List? _responseBytesHandler() {
    return null;
  }

  static void _saveCookiesFromResponse(String? url, http.BaseResponse? response) {
    Uri? uri = _uriFromUrlString(url);
    if ((uri == null) || response == null) {
      return;
    }

    Map<String, String?> responseHeaders = response.headers;

    String? setCookie = responseHeaders["set-cookie"];
    if (StringUtils.isEmpty(setCookie)) {
      return;
    }

    //Split format like this "AWSALB2=12342; Path=/; Expires=Mon, 21 Oct 2019 12:48:37 GMT,AWSALB=1234; Path=/; Expires=Mon, 21 Oct 2019 12:48:37 GMT"
    List<String>? cookiesData = setCookie?.split(RegExp(",(?! )")); //comma not followed by a space
    if (cookiesData == null || cookiesData.isEmpty) {
      return;
    }

    List<Cookie> cookies = [];
    for (String cookieData in cookiesData) {
      Cookie cookie = Cookie.fromSetCookieValue(cookieData);
      cookies.add(cookie);
    }

    var cj = CookieJar();
    cj.saveFromResponse(uri, cookies);
  }

  static Future<String?> _loadCookiesForRequest(Uri uri) async{
    var cj = CookieJar();
    List<Cookie> cookies = await cj.loadForRequest(uri);
    if (cookies.isEmpty) {
      return null;
    }

    String result = "";
    for (Cookie cookie in cookies) {
      result += cookie.name + "=" + cookie.value + "; ";
    }

    //remove the last "; "
    result = result.substring(0, result.length - 2);

    return result;
  }

  static dynamic _notifyHttpResponseParam(http.BaseResponse? response, { String? analyticsUrl }) {
    return (analyticsUrl != null) ? response : {
      notifyHttpRequestUrl: response?.request?.url.toString(),
      notifyHttpRequestMethod: response?.request?.method,
      notifyHttpResponseCode: response?.statusCode,
    };
  }

  static Uri? _uriFromUrlString(dynamic url) {
    Uri? uri;
    if (url is Uri) {
      uri = url;
    }
    else if (url is String) {
      uri = Uri.tryParse(url);
    }
    else if (url != null) {
      uri = Uri.tryParse(url.toString());
    }
    return uri;
  }
}
