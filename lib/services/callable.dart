import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../config.dart';

/// A failed call to a callable Cloud Function. [code] is the function's
/// status in lower-case with dashes, e.g. 'unauthenticated',
/// 'invalid-argument', 'not-found', 'unavailable'.
class CallableException implements Exception {
  const CallableException(this.code, [this.message]);

  final String code;
  final String? message;

  @override
  String toString() => 'CallableException($code, $message)';
}

/// Calls a callable Cloud Function over HTTPS using the callable protocol:
/// POST {"data": ...} with the signed-in user's ID token as a Bearer token.
/// The function verifies that token itself, so `request.auth.uid` on the
/// server comes from Firebase Auth and never from this request body.
///
/// This replaces the cloud_functions plugin, whose Android build failed on
/// the emulator with "1 out of 2 underlying tasks failed" before any request
/// was sent. The server side (onCall) is unchanged.
Future<Map<String, dynamic>> callFunction(
  String name,
  Map<String, dynamic> data,
) async {
  final token = await FirebaseAuth.instance.currentUser?.getIdToken();
  final projectId = Firebase.app().options.projectId;
  final uri = useEmulators
      ? Uri.parse(
          'http://$emulatorHost:5001/$projectId/$functionsRegion/$name',
        )
      : Uri.parse(
          'https://$functionsRegion-$projectId.cloudfunctions.net/$name',
        );

  final client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 10);
  try {
    final request =
        await client.postUrl(uri).timeout(const Duration(seconds: 15));
    request.headers.contentType = ContentType.json;
    if (token != null) {
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
    }
    request.add(utf8.encode(jsonEncode({'data': data})));
    final response =
        await request.close().timeout(const Duration(seconds: 30));
    final body = await response.transform(utf8.decoder).join();

    Map<String, dynamic>? json;
    try {
      json = jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      json = null;
    }
    final result = json?['result'];
    if (result is Map) {
      return Map<String, dynamic>.from(result);
    }
    final error = json?['error'];
    if (error is Map) {
      final status = (error['status'] as String? ?? 'UNKNOWN')
          .toLowerCase()
          .replaceAll('_', '-');
      throw CallableException(status, error['message'] as String?);
    }
    throw CallableException('unknown', 'HTTP ${response.statusCode}');
  } on TimeoutException {
    throw const CallableException('deadline-exceeded');
  } on SocketException catch (error) {
    throw CallableException('unavailable', error.message);
  } finally {
    client.close();
  }
}
