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
import 'package:http/http.dart' as Http;
import 'package:http_parser/http_parser.dart';
import 'package:illinois/model/Auth2.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Connectivity.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/FirebaseCrashlytics.dart';
import 'package:illinois/service/Log.dart';
import 'package:illinois/utils/Utils.dart';

enum NetworkAuth {
  ApiKey,      // Config.rokwireApiKey
  UIUC_Id,     // UIUC.idToken
  UIUC_Access, // UIUC.accessToken
  Auth2,       // Auth2.accessToken
}

class Network  {

  static const String RokwireApiKey = 'ROKWIRE-API-KEY';
  static const String RokwireUserUuid = 'ROKWIRE-USER-UUID';
  static const String RokwireUserPrivacyLevel = 'ROKWIRE-USER-PRIVACY-LEVEL';
  static const String RokwirePadaapiKey = 'x-api-key';
  static const String UIUCAccessToken = 'access_token';

  static final Network _network = new Network._internal();
  factory Network() {
    return _network;
  }

  Network._internal();

  Future<Http.Response?> _get2(dynamic url, { String? body, Encoding? encoding, Map<String, String?>? headers, int? timeout, Http.Client? client }) async {
    try {
      
      Uri? uri = _uriFromUrlString(url);

      if (uri != null) {
        
        Http.Client? localClient;
        if (client == null) {
          client = localClient = Http.Client();
        }

        Http.Request request = Http.Request("GET", uri);
        
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

        Future<Http.StreamedResponse?>? responseStreamFuture = client.send(request);
        if ((timeout != null)) {
          responseStreamFuture = responseStreamFuture.timeout(Duration(seconds: timeout));
        }

        Http.StreamedResponse? responseStream = await responseStreamFuture;

        if (localClient != null) {
          localClient.close();
        }

        return (responseStream != null) ? Http.Response.fromStream(responseStream) : null;
      }
    } catch (e) { 
      Log.d(e.toString());
      FirebaseCrashlytics().recordError(e, null);
    }
    return null;
  }

  Future<Http.Response?> _get(url, { String? body, Encoding? encoding, Map<String, String?>? headers, NetworkAuth? auth, int? timeout, Http.Client? client} ) async {
    if (Connectivity().isNotOffline) {
      try {
        Uri? uri = _uriFromUrlString(url);
        if (uri != null) {

          Map<String, String>? requestHeaders = await _prepareHeaders(headers, auth, uri);

          Future<Http.Response?> response;
          if (body != null) {
            response = _get2(uri, headers: requestHeaders, body: body, encoding: encoding, timeout: timeout, client: client);
          }
          else if (client != null) {
            response = client.get(uri, headers: requestHeaders);
          }
          else {
            response = Http.get(uri, headers: requestHeaders);
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

  Future<Http.Response?> get(url, { String? body, Encoding? encoding, Map<String, String?>? headers, NetworkAuth? auth, Http.Client? client, int? timeout = 60, bool sendAnalytics = true, String? analyticsUrl }) async {
    Http.Response? response;

    try {
      Auth2Token? token = _authToken(auth);
      response = await _get(url, headers: headers, body: body, encoding: encoding, auth: auth, client: client, timeout: timeout);
      
      if ((response is Http.Response) && _requiresRefreshToken(response, auth, token)) {
        if (await _refreshToken() == true) {
          response = await _get(url, body: body, headers: headers, auth: auth, client: client, timeout: timeout);
        }
      }
    } catch (e) { 
      Log.d(e.toString());
      FirebaseCrashlytics().recordError(e, null);
    }

    if (sendAnalytics) {
      Analytics().logHttpResponse(response, requestMethod:'GET', requestUrl: analyticsUrl ?? url);
    }

    _saveCookiesFromResponse(url, response);
    
    return response;
  }

  Future<Http.Response?> _post(url, { Object? body, Encoding? encoding, Map<String, String?>? headers, NetworkAuth? auth, int? timeout}) async{
    if (Connectivity().isNotOffline) {
      try {
        Uri? uri = _uriFromUrlString(url);
        Future<Http.Response?>? response = (uri != null) ? Http.post(uri, headers: await _prepareHeaders(headers, auth, uri), body: body, encoding: encoding) : null;
        return ((response != null) && (timeout != null)) ? response.timeout(Duration(seconds: timeout), onTimeout: _responseTimeoutHandler) : response;
      } catch (e) {
        Log.d(e.toString());
        FirebaseCrashlytics().recordError(e, null);
      }
    }
    return null;
  }

  Future<Http.Response?> post(url, {Object? body, Encoding? encoding, Map<String, String?>? headers, NetworkAuth? auth, int? timeout = 60, bool sendAnalytics = true, String? analyticsUrl }) async{
    Http.Response? response;
    
    try {
      Auth2Token? token = _authToken(auth);
      response = await _post(url, body: body, encoding: encoding, headers: headers, auth: auth, timeout: timeout);
      
      if ((response is Http.Response) && _requiresRefreshToken(response, auth, token)) {
        if (await _refreshToken() == true) {
          response = await _post(url, body: body, encoding: encoding, headers: headers, auth: auth, timeout: timeout);
        }
      }
    } catch (e) {
      Log.d(e.toString());
      FirebaseCrashlytics().recordError(e, null);
    }

    if (sendAnalytics) {
      Analytics().logHttpResponse(response, requestMethod:'POST', requestUrl: analyticsUrl ?? url);
    }

    _saveCookiesFromResponse(url, response);

    return response;
  }

  Future<Http.Response?> _put(url, {Object? body, Encoding? encoding, Map<String, String?>? headers, NetworkAuth? auth, int? timeout, Http.Client? client }) async {
    if (Connectivity().isNotOffline) {
      try {
        Uri? uri = _uriFromUrlString(url);
        Future<Http.Response?>? response = (uri != null) ?
          ((client != null) ?
            client.put(uri, headers: await _prepareHeaders(headers, auth, uri), body: body, encoding: encoding) :
              Http.put(uri, headers: await _prepareHeaders(headers, auth, uri), body: body, encoding: encoding)) :
            null;

        return ((response != null) && (timeout != null)) ? response.timeout(Duration(seconds: timeout), onTimeout: _responseTimeoutHandler) : response;

      } catch (e) {
        Log.d(e.toString());
        FirebaseCrashlytics().recordError(e, null);
      }
    }
    return null;
  }

  Future<Http.Response?> put(url, {Object? body, Encoding? encoding, Map<String, String?>? headers, NetworkAuth? auth, int? timeout = 60, Http.Client? client, bool sendAnalytics = true, String? analyticsUrl }) async {
    Http.Response? response;
    
    try {
      Auth2Token? token = _authToken(auth);
      response = await _put(url, body: body, encoding: encoding, headers: headers, auth: auth, timeout: timeout, client: client);
      
      if ((response is Http.Response) && _requiresRefreshToken(response, auth, token)) {
        if (await _refreshToken() == true) {
          response = await _put(url, body: body, encoding: encoding, headers: headers, auth: auth, timeout: timeout, client: client);
        }
      }
    } catch (e) {
      Log.d(e.toString());
      FirebaseCrashlytics().recordError(e, null);
    }

    if (sendAnalytics) {
      Analytics().logHttpResponse(response, requestMethod:'PUT', requestUrl: analyticsUrl ?? url);
    }

    _saveCookiesFromResponse(url, response);

    return response;
  }

  Future<Http.Response?> _patch(url, {Object? body, Encoding? encoding, Map<String, String?>? headers, NetworkAuth? auth, int? timeout }) async {
    if (Connectivity().isNotOffline) {
      try {
        Uri? uri = _uriFromUrlString(url);
        Future<Http.Response?>? response = (uri != null) ? Http.patch(uri, headers: await _prepareHeaders(headers, auth, uri), body: body, encoding: encoding) : null;
        return ((response != null) && (timeout != null)) ? response.timeout(Duration(seconds: timeout), onTimeout: _responseTimeoutHandler) : response;
      } catch (e) {
        Log.d(e.toString());
        FirebaseCrashlytics().recordError(e, null);
      }
    }
    return null;
  }

  Future<Http.Response?> patch(url, {Object? body, Encoding? encoding, Map<String, String?>? headers, NetworkAuth? auth, int? timeout = 60, bool sendAnalytics = true, String? analyticsUrl }) async {
    Http.Response? response;
    
    try {    
      Auth2Token? token = _authToken(auth);
      response = await _patch(url, body: body, encoding: encoding, headers: headers, auth: auth, timeout: timeout);
      
      if ((response is Http.Response) && _requiresRefreshToken(response, auth, token)) {
        if (await _refreshToken() == true) {
          response = await _patch(url, body: body, encoding: encoding, headers: headers, auth: auth, timeout: timeout);
        }
      }
    } catch (e) {
      Log.d(e.toString());
      FirebaseCrashlytics().recordError(e, null);
    }

    if (sendAnalytics) {
      Analytics().logHttpResponse(response, requestMethod:'PATCH', requestUrl: analyticsUrl ?? url);
    }

    _saveCookiesFromResponse(url, response);

    return response;
  }

  Future<Http.Response?> _delete(url, {Object? body, Encoding? encoding, Map<String, String?>? headers, NetworkAuth? auth, int? timeout }) async {
    if (Connectivity().isNotOffline) {
      try {
        Uri? uri = _uriFromUrlString(url);
        Future<Http.Response?>? response = (uri != null) ? Http.delete(uri, headers: await _prepareHeaders(headers, auth, uri), body: body, encoding: encoding) : null;
        return ((response != null) && (timeout != null)) ? response.timeout(Duration(seconds: timeout), onTimeout: _responseTimeoutHandler) : response;
      } catch (e) {
        Log.d(e.toString());
        FirebaseCrashlytics().recordError(e, null);
      }
    }
    return null;
  }

  Future<Http.Response?> delete(url, {Object? body, Encoding? encoding, Map<String, String?>? headers, NetworkAuth? auth, int? timeout = 60, bool sendAnalytics = true, String? analyticsUrl }) async {
    Http.Response? response;
    try {
      Auth2Token? token = _authToken(auth);
      response = await _delete(url, body: body, encoding:encoding, headers: headers, auth: auth, timeout: timeout);
      
      if ((response is Http.Response) && _requiresRefreshToken(response, auth, token)) {
        if (await _refreshToken() == true) {
          response = await _delete(url, body: body, encoding:encoding, headers: headers, auth: auth, timeout: timeout);
        }
      }
    } catch (e) {
      Log.d(e.toString());
      FirebaseCrashlytics().recordError(e, null);
    }

    if (sendAnalytics) {
      Analytics().logHttpResponse(response, requestMethod:'DELETE', requestUrl: analyticsUrl ?? url);
    }

    _saveCookiesFromResponse(url, response);

    return response;
  }

  Future<String?> _read(url, { Map<String, String?>? headers, NetworkAuth? auth, int? timeout = 60 }) async {
    if (Connectivity().isNotOffline) {
      try {
        Uri? uri = _uriFromUrlString(url);
        Future<String>? response = (uri != null) ? Http.read(uri, headers: await _prepareHeaders(headers, auth, uri)) : null;
        return ((response != null) && (timeout != null)) ? response.timeout(Duration(seconds: timeout)) : response;
      } catch (e) {
        Log.d(e.toString());
        FirebaseCrashlytics().recordError(e, null);
      }
    }
    return null;
  }

  Future<String?> read(url, { Map<String, String?>? headers, NetworkAuth? auth, int? timeout = 60 }) async {
    try {
      return await _read(url, headers: headers, auth: auth, timeout: timeout);
    }
    catch (e) {
      Log.d(e.toString());
      FirebaseCrashlytics().recordError(e, null);
    }
    return null;
  }

  Future<Uint8List?> _readBytes(url, { Map<String, String?>? headers, NetworkAuth? auth, int? timeout = 60 }) async{
    if (Connectivity().isNotOffline) {
      try {
        Uri? uri = _uriFromUrlString(url);
        Future<Uint8List?>? response = (uri != null) ? Http.readBytes(uri, headers: await _prepareHeaders(headers, auth, uri)) : null;
        return ((response != null) && (timeout != null)) ? response.timeout(Duration(seconds: timeout), onTimeout: _responseBytesHandler) : response;
      } catch (e) {
        Log.d(e.toString());
        FirebaseCrashlytics().recordError(e, null);
      }
    }
    return null;
  }

  Future<Uint8List?> readBytes(url, { Map<String, String?>? headers, NetworkAuth? auth, int? timeout = 60 }) async {
    return _readBytes(url, headers: headers, auth: auth, timeout: timeout);
  }

  Future<Http.StreamedResponse?> multipartPost({String? url, String? fileKey, List<int>? fileBytes, String? fileName, String? contentType, Map<String, String?>? headers, Map<String, String>? fields, NetworkAuth? auth, bool refreshToken = true, bool sendAnalytics = true, String? analyticsUrl}) async {
    Http.StreamedResponse? response;

    try {
      Auth2Token? token = _authToken(auth);
      response = await _multipartPost(url: url, fileKey: fileKey, fileBytes: fileBytes, fileName: fileName, contentType: contentType, headers: headers, fields: fields, auth: auth);

      if (refreshToken && (response is Http.BaseResponse) && _requiresRefreshToken(response, auth, token)) {
        if (await _refreshToken() == true) {
          response = await _multipartPost(
              url: url, fileKey: fileKey, fileBytes: fileBytes, fileName: fileName, contentType: contentType, headers: headers, fields: fields, auth: auth);
        }
      }
    } catch (e) {
      Log.d(e.toString());
      FirebaseCrashlytics().recordError(e, null);
    }

    if (sendAnalytics) {
      Analytics().logHttpResponse(response, requestMethod: 'POST', requestUrl: analyticsUrl ?? url);
    }

    _saveCookiesFromResponse(url, response);

    return response;
  }

  Future<Http.StreamedResponse?> _multipartPost({String? url, String? fileKey, List<int>? fileBytes, String? fileName, String? contentType, Map<String, String?>? headers, Map<String, String?>? fields, NetworkAuth? auth}) async {
    if (Connectivity().isNotOffline) {
      try {
        Uri? uri = _uriFromUrlString(url);
        if (uri != null) {
          Map<String, String>? preparedHeaders = await _prepareHeaders(headers, auth, uri);
          Http.MultipartRequest request = Http.MultipartRequest("POST", uri);
          if (preparedHeaders != null) {
            request.headers.addAll(preparedHeaders);
          }

          Map<String, String>? preparedFields = _ensureMapValues(fields);
          if (preparedFields != null) {
            request.fields.addAll(preparedFields);
          }
          if ((fileKey != null) && (fileBytes != null)) {
            Http.MultipartFile multipartFile = Http.MultipartFile.fromBytes(fileKey, fileBytes, filename: fileName, contentType: (contentType != null) ? MediaType.parse(contentType) : null);
            request.files.add(multipartFile);
            Http.StreamedResponse response = await request.send();
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


  static Map<String, String>? get authApiKeyHeader {
    return authHeaders(NetworkAuth.ApiKey);
  }

  static Map<String, String>? authHeaders(NetworkAuth? auth) {
    return _prepareAuthHeaders(null, auth);
  }

  static Future<Map<String, String>?> _prepareHeaders(Map<String, String?>? headers, NetworkAuth? auth, Uri? uri) async {

    // authentication
    Map<String, String>? result = _prepareAuthHeaders(headers, auth);

    // cookies
    String? cookies = (uri != null) ? await _loadCookiesForRequest(uri) : null;
    if ((cookies != null) && (0 < cookies.length)) {
      if (result == null) {
        result = <String, String>{};
      }
      result["Cookie"] = cookies;
    }

    return result;
  }

  static Map<String, String>? _prepareAuthHeaders(Map<String, String?>? headers, NetworkAuth? auth) {

    Map<String, String>? result = (headers != null) ? _ensureMapValues(headers) : null;

    if (auth == NetworkAuth.ApiKey) {
      String? rokwireApiKey = Config().rokwireApiKey;
      if ((rokwireApiKey != null) && rokwireApiKey.isNotEmpty) {
        if (result == null) {
          result = <String, String>{};
        }
        result[RokwireApiKey] = rokwireApiKey;
      }
    }
    else if (auth == NetworkAuth.UIUC_Id) {
      String? idToken = Auth2().uiucToken?.idToken;
      String? tokenType = Auth2().uiucToken?.tokenType ?? 'Bearer';
      if ((idToken != null) && idToken.isNotEmpty) {
        if (result == null) {
          result = <String, String>{};
        }
        result[HttpHeaders.authorizationHeader] = "$tokenType $idToken";
      }
    }
    else if (auth == NetworkAuth.UIUC_Access) {
      String? accessToken = Auth2().uiucToken?.accessToken;
      if ((accessToken != null) && accessToken.isNotEmpty) {
        if (result == null) {
          result = <String, String>{};
        }
        result[UIUCAccessToken] = accessToken;
      }
    }
    else if (auth == NetworkAuth.Auth2) {
      String? accessToken = Auth2().token?.accessToken;
      String? tokenType = Auth2().token?.tokenType ?? 'Bearer';
      if ((accessToken != null) && accessToken.isNotEmpty) {
        if (result == null) {
          result = <String, String>{};
        }
        result[HttpHeaders.authorizationHeader] = "$tokenType $accessToken";
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

  static Auth2Token? _authToken(NetworkAuth? auth) {
    
    if (auth == NetworkAuth.UIUC_Id) {
      return Auth2().uiucToken;
    }
    else if (auth == NetworkAuth.UIUC_Access) {
      return Auth2().uiucToken;
    }
    else if (auth == NetworkAuth.Auth2) {
      return Auth2().token;
    }

    return null;
  }

  bool _requiresRefreshToken(Http.BaseResponse? response, NetworkAuth? auth, Auth2Token? token) {
    return ((response != null)
      && (
//        (response.statusCode == 400) || 
          (response.statusCode == 401)
      )
      && ((NetworkAuth.UIUC_Id == auth) || (NetworkAuth.UIUC_Access == auth) || (NetworkAuth.Auth2 == auth))
      && (token != null)
      && (token == _authToken(auth))
      && (Auth2().token?.refreshToken != null)
    );
  }

  Future<bool?> _refreshToken() async {
    return (await Auth2().refreshToken() != null);
  }

  Http.Response _responseTimeoutHandler() {
    return Http.Response('Request Timeout', 408);
  }

  Uint8List? _responseBytesHandler() {
    return null;
  }

  static void _saveCookiesFromResponse(String? url, Http.BaseResponse? response) {
    Uri? uri = _uriFromUrlString(url);
    if ((uri == null) || response == null)
      return;

    Map<String, String?> responseHeaders = response.headers;

    String? setCookie = responseHeaders["set-cookie"];
    if (AppString.isStringEmpty(setCookie))
      return;

    //Split format like this "AWSALB2=12342; Path=/; Expires=Mon, 21 Oct 2019 12:48:37 GMT,AWSALB=1234; Path=/; Expires=Mon, 21 Oct 2019 12:48:37 GMT"
    List<String>? cookiesData = setCookie?.split(new RegExp(",(?! )")); //comma not followed by a space
    if (cookiesData == null || cookiesData.length == 0)
      return;

    List<Cookie> cookies = [];
    for (String cookieData in cookiesData) {
      Cookie cookie = Cookie.fromSetCookieValue(cookieData);
      cookies.add(cookie);
    }

    var cj = new CookieJar();
    cj.saveFromResponse(uri, cookies);
  }

  static Future<String?> _loadCookiesForRequest(Uri uri) async{
    var cj = new CookieJar();
    List<Cookie> cookies = await cj.loadForRequest(uri);
    if (cookies.length == 0)
      return null;

    String result = "";
    for (Cookie cookie in cookies) {
      result += cookie.name + "=" + cookie.value + "; ";
    }

    //remove the last "; "
    result = result.substring(0, result.length - 2);

    return result;
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

