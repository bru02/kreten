import 'dart:convert';
import 'dart:io';

import 'package:filcnaplo/api/login.dart';
import 'package:filcnaplo/api/nonce.dart';
import 'package:filcnaplo/api/providers/user_provider.dart';
import 'package:filcnaplo/models/settings.dart';
import 'package:filcnaplo/models/user.dart';
import 'package:filcnaplo/utils/jwt.dart';
import 'package:filcnaplo_kreta_api/client/api.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart' as http;
import 'dart:async';

import 'package:provider/provider.dart';

class KretaClient {
  String? accessToken;
  String? userAgent;
  BuildContext? context;
  late http.Client client;

  KretaClient({this.accessToken, this.userAgent, this.context}) {
    var ioclient = new HttpClient();
    ioclient.badCertificateCallback = _checkCerts;
    client = http.IOClient(ioclient);
  }

  bool _checkCerts(X509Certificate cert, String host, int port) {
    if (context == null) return false;
    return Provider.of<SettingsProvider>(context!, listen: false).developerMode;
  }

  Future<dynamic> getAPI(
    String url, {
    Map<String, String>? headers,
    bool autoHeader = true,
    bool json = true,
    bool rawResponse = false,
  }) async {
    Map<String, String> headerMap;

    if (rawResponse) json = false;

    if (headers != null)
      headerMap = headers;
    else
      headerMap = {};

    try {
      http.Response? res;

      for (int i = 0; i < 3; i++) {
        if (autoHeader) {
          if (!headerMap.containsKey("authorization") && accessToken != null) headerMap["authorization"] = "Bearer $accessToken";
          if (!headerMap.containsKey("user-agent") && userAgent != null) headerMap["user-agent"] = "$userAgent";
        }

        res = await client.get(Uri.parse(url), headers: headerMap);
        if (res.statusCode == 401)
          await refreshLogin();
        else
          break;

        // Wait before retrying
        await Future.delayed(Duration(milliseconds: 500));
      }

      if (res == null) throw "Login error";

      if (json)
        return jsonDecode(res.body);
      else if (rawResponse)
        return res.bodyBytes;
      else
        return res.body;
    } catch (error) {
      print("ERROR: KretaClient.getAPI ($url) $error");
    }
  }

  Future<dynamic> postAPI(
    String url, {
    Map<String, String>? headers,
    bool autoHeader = true,
    bool json = true,
    Object? body,
  }) async {
    Map<String, String> headerMap;

    if (headers != null)
      headerMap = headers;
    else
      headerMap = {};

    try {
      http.Response? res;

      for (int i = 0; i < 3; i++) {
        if (autoHeader) {
          if (!headerMap.containsKey("authorization") && accessToken != null) headerMap["authorization"] = "Bearer $accessToken";
          if (!headerMap.containsKey("user-agent") && userAgent != null) headerMap["user-agent"] = "$userAgent";
          if (!headerMap.containsKey("content-type")) headerMap["content-type"] = "application/json";
        }

        res = await client.post(Uri.parse(url), headers: headerMap, body: body);
        if (res.statusCode == 401)
          await refreshLogin();
        else
          break;
      }

      if (res == null) throw "Login error";

      if (json)
        return jsonDecode(res.body);
      else
        return res.body;
    } catch (error) {
      print("ERROR: KretaClient.postAPI ($url) $error");
    }
  }

  Future<void> refreshLogin() async {
    if (context == null) return;
    User? loginUser = Provider.of<UserProvider>(context!, listen: false).user;
    if (loginUser == null) return;

    Map<String, String> headers = {
      "content-type": "application/x-www-form-urlencoded",
    };

    String nonceStr = await getAPI(KretaAPI.nonce, json: false);
    Nonce nonce = getNonce(context!, nonceStr, loginUser.username, loginUser.instituteCode);
    headers.addAll(nonce.header());

    print("DEBUG: refreshLogin: ${loginUser.id} ${loginUser.name}");

    Map? loginRes = await postAPI(KretaAPI.login,
        headers: headers,
        body: User.loginBody(
          username: loginUser.username,
          password: loginUser.password,
          instituteCode: loginUser.instituteCode,
        ));

    if (loginRes != null) {
      if (loginRes.containsKey("access_token")) accessToken = loginRes["access_token"];

      // Update role
      loginUser.role = JwtUtils.getRoleFromJWT(accessToken ?? "") ?? Role.student;
    }
  }
}
