import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:http/retry.dart';

import 'api_config.dart';

/// Shared HTTP client with retries, timeouts and exponential backoff.
class BackendClient {
  BackendClient._();

  static final http.Client client = RetryClient(
    http.Client(),
    retries: 3,
    whenError: (error, stackTrace) =>
        error is SocketException ||
        error is TimeoutException ||
        error is http.ClientException,
    delay: (retryCount) =>
        Duration(milliseconds: 500 * pow(2, retryCount - 1).toInt()),
  );

  static Future<http.Response> get(Uri uri, {Map<String, String>? headers}) =>
      client.get(uri, headers: headers).timeout(ApiConfig.backendTimeout);

  static Future<http.Response> post(Uri uri,
          {Map<String, String>? headers, Object? body, Encoding? encoding}) =>
      client
          .post(uri, headers: headers, body: body, encoding: encoding)
          .timeout(ApiConfig.backendTimeout);
}
