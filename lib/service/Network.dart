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

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:http/http.dart' as Http;
import 'package:illinois/service/Auth.dart';
import 'package:illinois/service/Connectivity.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/FirebaseCrashlytics.dart';
import 'package:illinois/service/Log.dart';
import 'package:illinois/utils/Utils.dart';

enum NetworkAuth {
  App,
  User,
  Access,
}

class Network  {

  static const String RokwireApiKey = 'ROKWIRE-API-KEY';
  static const String RokwireUserUuid = 'ROKWIRE-USER-UUID';
  static const String RokwireUserPrivacyLevel = 'ROKWIRE-USER-PRIVACY-LEVEL';

  static final Network _network = new Network._internal();
  factory Network() {
    return _network;
  }

  Network._internal();

  Future<Http.Response> _get2(dynamic url, { String body, Encoding encoding, Map<String, String> headers, int timeout, Http.Client client }) async {
    try {
      
      Uri uri;
      if (url is Uri) {
        uri = url;
      }
      else if (url is String) {
        uri = Uri.parse(url);
      }

      if (uri != null) {
        
        Http.Client localClient;
        if (client == null) {
          client = localClient = Http.Client();
        }

        Http.Request request = Http.Request("GET", uri);
        
        if (headers != null) {
          headers.forEach((String key, String value) {
            request.headers[key] = value;
          });
        }
        
        if (encoding != null) {
          request.encoding = encoding;  
        }
        
        if (body != null) {
          request.body = body;
        }

        Future<Http.StreamedResponse> responseStreamFuture = client.send(request);
        if ((responseStreamFuture != null) && (timeout != null)) {
          responseStreamFuture = responseStreamFuture.timeout(Duration(seconds: timeout));
        }

        Http.StreamedResponse responseStream = await responseStreamFuture;

        if (localClient != null) {
          localClient.close();
        }

        return (responseStream != null) ? Http.Response.fromStream(responseStream) : null;
      }
    } catch (e) { 
      Log.e(e.toString());
      FirebaseCrashlytics().recordError(e, null);
    }
    return null;
  }

  Future<Http.Response> _get(url, { String body, Encoding encoding, Map<String, String> headers, NetworkAuth auth, int timeout, Http.Client client} ) async {
    if (Connectivity().isNotOffline) {
      try {
        if (url != null) {

          Map<String, String> requestHeaders = _prepareHeaders(headers, auth, url);
          
          Future<Http.Response> response;
          if (body != null) {
            response = _get2(url, headers: requestHeaders, body: body, encoding: encoding, timeout: timeout, client: client);
          }
          else if (client != null) {
            response = client.get(url, headers: requestHeaders);
          }
          else {
            response = Http.get(url, headers: requestHeaders);
          }
          
          if ((response != null) && (timeout != null)) {
            response = response.timeout(Duration(seconds: timeout), onTimeout: _responseTimeoutHandler);
          }

          return response;
        }
      } catch (e) { 
        Log.e(e.toString());
        FirebaseCrashlytics().recordError(e, null);
      }
    }
    return null;
  }

  Future<Http.Response> get(url, { String body, Encoding encoding, Map<String, String> headers, NetworkAuth auth, Http.Client client, int timeout = 60, bool refreshToken = true, bool sendAnalytics = true, String analyticsUrl }) async {
    Http.Response response = await _get(url, headers: headers, body: body, encoding: encoding, auth: auth, client: client, timeout: timeout);
    if (sendAnalytics) {
      Analytics().logHttpResponse(response, requestMethod:'GET', requestUrl: analyticsUrl ?? url);
    }

    _saveCookiesFromResponse(url, response);

    if (refreshToken && (response is Http.Response) && _requiresRefreshToken(response, auth)) {
      await Auth().doRefreshToken();
      return _get(url, body: body, headers: headers, auth: auth, client: client, timeout: timeout);
    }
    else {
      return response;
    }
  }

  Future<Http.Response> _post(url, { body, Encoding encoding, Map<String, String> headers, NetworkAuth auth, int timeout}) async{
    if (Connectivity().isNotOffline) {
      try {
        Future<Http.Response> response = (url != null) ? Http.post(url, headers: _prepareHeaders(headers, auth, url), body: body, encoding: encoding) : null;
        return ((response != null) && (timeout != null)) ? response.timeout(Duration(seconds: timeout), onTimeout: _responseTimeoutHandler) : response;
      } catch (e) {
        Log.e(e.toString());
        FirebaseCrashlytics().recordError(e, null);
      }
    }
    return null;
  }

  Future<Http.Response> post(url, { body, Encoding encoding, Map<String, String> headers, NetworkAuth auth, int timeout = 60, bool refreshToken = true, bool sendAnalytics = true, String analyticsUrl }) async{
    Http.Response response = await _post(url, body: body, encoding: encoding, headers: headers, auth: auth, timeout: timeout);
    if (sendAnalytics) {
      Analytics().logHttpResponse(response, requestMethod:'POST', requestUrl: analyticsUrl ?? url);
    }

    _saveCookiesFromResponse(url, response);

    if (refreshToken && (response is Http.Response) && _requiresRefreshToken(response, auth)) {
      await Auth().doRefreshToken();
      return _post(url, body: body, encoding: encoding, headers: headers, auth: auth, timeout: timeout);
    }
    else {
      return response;
    }
  }

  Future<Http.Response> _put(url, { body, Encoding encoding, Map<String, String> headers, NetworkAuth auth, int timeout, Http.Client client }) async {
    if (Connectivity().isNotOffline) {
      try {
        Future<Http.Response> response = (url != null) ?
          ((client != null) ?
            client.put(url, headers: _prepareHeaders(headers, auth, url), body: body, encoding: encoding) :
              Http.put(url, headers: _prepareHeaders(headers, auth, url), body: body, encoding: encoding)) :
            null;

        return ((response != null) && (timeout != null)) ? response.timeout(Duration(seconds: timeout), onTimeout: _responseTimeoutHandler) : response;

      } catch (e) {
        Log.e(e.toString());
        FirebaseCrashlytics().recordError(e, null);
      }
    }
    return null;
  }

  Future<Http.Response> put(url, { body, Encoding encoding, Map<String, String> headers, NetworkAuth auth, int timeout = 60, Http.Client client, bool refreshToken = true, bool sendAnalytics = true, String analyticsUrl }) async {
    Http.Response response = await _put(url, body: body, encoding: encoding, headers: headers, auth: auth, timeout: timeout, client: client);
    if (sendAnalytics) {
      Analytics().logHttpResponse(response, requestMethod:'PUT', requestUrl: analyticsUrl ?? url);
    }

    _saveCookiesFromResponse(url, response);

    if (refreshToken && (response is Http.Response) && _requiresRefreshToken(response, auth)) {
      await Auth().doRefreshToken();
      return _put(url, body: body, encoding: encoding, headers: headers, auth: auth, timeout: timeout, client: client);
    }
    else {
      return response;
    }
  }

  Future<Http.Response> _patch(url, { body, Encoding encoding, Map<String, String> headers, NetworkAuth auth, int timeout }) async {
    if (Connectivity().isNotOffline) {
      try {
        Future<Http.Response> response = (url != null) ? Http.patch(url, headers: _prepareHeaders(headers, auth, url), body: body, encoding: encoding) : null;
        return ((response != null) && (timeout != null)) ? response.timeout(Duration(seconds: timeout), onTimeout: _responseTimeoutHandler) : response;
      } catch (e) {
        Log.e(e.toString());
        FirebaseCrashlytics().recordError(e, null);
      }
    }
    return null;
  }

  Future<Http.Response> patch(url, { body, Encoding encoding, Map<String, String> headers, NetworkAuth auth, int timeout = 60, bool refreshToken = true, bool sendAnalytics = true, String analyticsUrl }) async {
    Http.Response response = await _patch(url, body: body, encoding: encoding, headers: headers, auth: auth, timeout: timeout);
    if (sendAnalytics) {
      Analytics().logHttpResponse(response, requestMethod:'PATCH', requestUrl: analyticsUrl ?? url);
    }

    _saveCookiesFromResponse(url, response);

    if (refreshToken && (response is Http.Response) && _requiresRefreshToken(response, auth)) {
      await Auth().doRefreshToken();
      return _patch(url, body: body, encoding: encoding, headers: headers, auth: auth, timeout: timeout);
    }
    else {
      return response;
    }
  }

  Future<Http.Response> _delete(url, { Map<String, String> headers, NetworkAuth auth, int timeout }) async {
    if (Connectivity().isNotOffline) {
      try {
        Future<Http.Response> response = (url != null) ? Http.delete(url, headers: _prepareHeaders(headers, auth, url)) : null;
        return ((response != null) && (timeout != null)) ? response.timeout(Duration(seconds: timeout), onTimeout: _responseTimeoutHandler) : response;
      } catch (e) {
        Log.e(e.toString());
        FirebaseCrashlytics().recordError(e, null);
      }
    }
    return null;
  }

  Future<Http.Response> delete(url, { Map<String, String> headers, NetworkAuth auth, int timeout = 60, bool refreshToken = true, bool sendAnalytics = true, String analyticsUrl }) async {
    Http.Response response = await _delete(url, headers: headers, auth: auth, timeout: timeout);
    if (sendAnalytics) {
      Analytics().logHttpResponse(response, requestMethod:'DELETE', requestUrl: analyticsUrl ?? url);
    }

    _saveCookiesFromResponse(url, response);

    if (refreshToken && (response is Http.Response) && _requiresRefreshToken(response, auth)) {
      await Auth().doRefreshToken();
      return _delete(url, headers: headers, auth: auth, timeout: timeout);
    }
    else {
      return response;
    }
  }

  Future<String> _read(url, { Map<String, String> headers, NetworkAuth auth, int timeout = 60 }) async {
    if (Connectivity().isNotOffline) {
      try {
        Future<String> response = (url != null) ? Http.read(url, headers: _prepareHeaders(headers, auth, url)) : null;
        return ((response != null) && (timeout != null)) ? response.timeout(Duration(seconds: timeout)) : response;
      } catch (e) {
        Log.e(e.toString());
        FirebaseCrashlytics().recordError(e, null);
      }
    }
    return null;
  }

  Future<String> read(url, { Map<String, String> headers, NetworkAuth auth, int timeout = 60 }) async {
    return _read(url, headers: headers, auth: auth, timeout: timeout);
  }

  Future<Uint8List> _readBytes(url, { Map<String, String> headers, NetworkAuth auth, int timeout = 60 }) async{
    if (Connectivity().isNotOffline) {
      try {
        Future<Uint8List> response = (url != null) ? Http.readBytes(url, headers: _prepareHeaders(headers, auth, url)) : null;
        return ((response != null) && (timeout != null)) ? response.timeout(Duration(seconds: timeout), onTimeout: _responseBytesHandler) : response;
      } catch (e) {
        Log.e(e.toString());
        FirebaseCrashlytics().recordError(e, null);
      }
    }
    return null;
  }

  Future<Uint8List> readBytes(url, { Map<String, String> headers, NetworkAuth auth, int timeout = 60 }) async {
    return _readBytes(url, headers: headers, auth: auth, timeout: timeout);
  }

  Map<String, String> _prepareHeaders(Map<String, String> headers, NetworkAuth auth, String url) {

    if (auth == NetworkAuth.App) {
      String rokwireApiKey = Config().rokwireApiKey;
      if ((rokwireApiKey != null) && rokwireApiKey.isNotEmpty) {
        if (headers == null) {
          headers = new Map();
        }
        headers[RokwireApiKey] = rokwireApiKey;
      }
    }
    else if (auth == NetworkAuth.User) {
      String idToken = Auth().authToken?.idToken;
      String tokenType = Auth().authToken?.tokenType ?? 'Bearer';
      if ((idToken != null) && idToken.isNotEmpty) {
        if (headers == null) {
          headers = new Map();
        }
        headers[HttpHeaders.authorizationHeader] = "$tokenType $idToken";
      }
    }
    else if (auth == NetworkAuth.Access) {
      String accessToken = Auth().authToken?.accessToken;
      if ((accessToken != null) && accessToken.isNotEmpty) {
        if (headers == null) {
          headers = new Map();
        }
        headers['access_token'] = accessToken;
      }
    }

    //cookies
    String cookies = _loadCookiesForRequest(url);
    if (AppString.isStringNotEmpty(cookies)) {
      if (headers == null) {
        headers = new Map();
      }
      headers["Cookie"] = cookies;
    }

    return headers;
  }

  bool _requiresRefreshToken(Http.Response response, NetworkAuth auth){
    return (response != null
       && (
//          response.statusCode == 400 || 
            response.statusCode == 401
        )
        && Auth().isLoggedIn
        && (NetworkAuth.User == auth || NetworkAuth.Access == auth));
  }

  void _saveCookiesFromResponse(String url, Http.Response response) {
    if (AppString.isStringEmpty(url) || response == null)
      return;

    Map<String, String> responseHeaders = response.headers;
    if (responseHeaders == null)
      return;

    String setCookie = responseHeaders["set-cookie"];
    if (AppString.isStringEmpty(setCookie))
      return;

    //Split format like this "AWSALB2=12342; Path=/; Expires=Mon, 21 Oct 2019 12:48:37 GMT,AWSALB=1234; Path=/; Expires=Mon, 21 Oct 2019 12:48:37 GMT"
    List<String> cookiesData = setCookie.split(new RegExp(",(?! )")); //comma not followed by a space
    if (cookiesData == null || cookiesData.length == 0)
      return;

    List<Cookie> cookies = List();
    for (String cookieData in cookiesData) {
      Cookie cookie = Cookie.fromSetCookieValue(cookieData);
      cookies.add(cookie);
    }

    var cj = new CookieJar();
    cj.saveFromResponse(Uri.parse(url), cookies);
  }

  String _loadCookiesForRequest(String url) {
    var cj = new CookieJar();
    List<Cookie> cookies = cj.loadForRequest(Uri.parse(url));
    if (cookies == null || cookies.length == 0)
      return null;

    String result = "";
    for (Cookie cookie in cookies) {
      result += cookie.name + "=" + cookie.value + "; ";
    }

    //remove the last "; "
    result = result.substring(0, result.length - 2);

    return result;
  }

  Http.Response _responseTimeoutHandler() {
    return null;
  }

  Uint8List _responseBytesHandler() {
    return null;
  }
}

