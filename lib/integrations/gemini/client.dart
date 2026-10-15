import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Every way an AI request can fail, each with a message fit for the user
/// (spec §9.3). The app keeps working fully whatever the error.
enum AiErrorCode { disabled, noKey, invalidKey, rateLimited, limitReached, timeout, offline, badResponse, server }

class AiError implements Exception {
  AiError(this.code, [String? message]) : message = message ?? _defaults[code]!;
  final AiErrorCode code;
  final String message;

  static const _defaults = {
    AiErrorCode.disabled: 'Turn on the AI assistant in Settings → AI assistant.',
    AiErrorCode.noKey: 'Add your Google AI key in Settings → AI assistant.',
    AiErrorCode.invalidKey: 'Google didn’t accept this key. Check it in Google AI Studio and paste it again.',
    AiErrorCode.rateLimited: 'Google is limiting requests right now. Try again later.',
    AiErrorCode.limitReached: 'You’ve reached your monthly AI request limit. Raise it in Settings → AI assistant.',
    AiErrorCode.timeout: 'The AI took too long to answer. Try again.',
    AiErrorCode.offline: 'You seem to be offline. Paisa works without AI — try again when connected.',
    AiErrorCode.badResponse: 'The AI returned an unexpected answer. Nothing was changed — try again.',
    AiErrorCode.server: 'Google AI had a problem. Try again later.',
  };

  @override
  String toString() => 'AiError(${code.name}): $message';
}

/// The first fast "flash" text model in the API's list (spec §9.2: never
/// hard-code model names), else the first model.
String? defaultModel(List<String> models) {
  bool text(String m) => !RegExp('image|tts|audio|live|embedding|vision', caseSensitive: false).hasMatch(m);
  return models.where((m) => m.contains('flash') && text(m)).firstOrNull ?? models.where(text).firstOrNull;
}

/// Google Gemini over REST, with the user's own key. All network calls to
/// Google live in this file (spec §9.3), so an API change touches one place.
/// The key is sent in a header, never in the URL.
class GeminiClient {
  GeminiClient(this._http, {this.timeout = const Duration(seconds: 20)});

  static const _base = 'https://generativelanguage.googleapis.com/v1beta';

  final http.Client _http;
  final Duration timeout;

  Map<String, String> _headers(String key) => {'x-goog-api-key': key, 'content-type': 'application/json'};

  Future<http.Response> _send(Future<http.Response> Function() call) async {
    final http.Response res;
    try {
      res = await call().timeout(timeout);
    } on TimeoutException {
      throw AiError(AiErrorCode.timeout);
    } on http.ClientException {
      throw AiError(AiErrorCode.offline);
    }
    if (res.statusCode == 200) return res;
    if (res.statusCode == 429) throw AiError(AiErrorCode.rateLimited);
    if (res.statusCode == 400 || res.statusCode == 401 || res.statusCode == 403) {
      final body = res.body.toLowerCase();
      if (res.statusCode != 400 || body.contains('api key') || body.contains('api_key')) throw AiError(AiErrorCode.invalidKey);
      throw AiError(AiErrorCode.badResponse);
    }
    throw AiError(AiErrorCode.server);
  }

  /// Models this key can use to generate text. Doubles as "Test key".
  Future<List<String>> listModels(String apiKey) async {
    final res = await _send(() => _http.get(Uri.parse('$_base/models?pageSize=200'), headers: _headers(apiKey)));
    try {
      final models = (jsonDecode(res.body) as Map<String, Object?>)['models'] as List? ?? const [];
      return [
        for (final m in models.cast<Map<String, Object?>>())
          if ((m['supportedGenerationMethods'] as List? ?? const []).contains('generateContent')) m['name']! as String,
      ];
    } on Object {
      throw AiError(AiErrorCode.badResponse);
    }
  }

  /// Structured JSON output for [schema]. Throws [AiError] on anything that
  /// is not a JSON object.
  Future<Map<String, Object?>> generateJson({
    required String apiKey,
    required String model,
    required String system,
    required String prompt,
    required Map<String, Object?> schema,
  }) async {
    final name = model.startsWith('models/') ? model : 'models/$model';
    final res = await _send(() => _http.post(
          Uri.parse('$_base/$name:generateContent'),
          headers: _headers(apiKey),
          body: jsonEncode({
            'systemInstruction': {
              'parts': [
                {'text': system},
              ],
            },
            'contents': [
              {
                'role': 'user',
                'parts': [
                  {'text': prompt},
                ],
              },
            ],
            'generationConfig': {
              'responseMimeType': 'application/json',
              'responseSchema': schema,
              'temperature': 0.3,
            },
          }),
        ));
    try {
      final body = jsonDecode(res.body) as Map<String, Object?>;
      final parts = (((body['candidates']! as List).first as Map)['content']! as Map)['parts']! as List;
      final text = parts.map((p) => (p as Map)['text'] ?? '').join();
      return (jsonDecode(text) as Map).cast<String, Object?>();
    } on Object {
      throw AiError(AiErrorCode.badResponse);
    }
  }
}
