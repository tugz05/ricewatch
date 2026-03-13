import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import '../core/constants/api_config.dart';
import '../models/chat_message_model.dart';

/// Result of an OpenAI chat call: content on success, or error message.
class OpenAIChatResult {
  const OpenAIChatResult({this.content, this.error});
  final String? content;
  final String? error;
  bool get isSuccess => content != null && content!.isNotEmpty;
}

/// Sends chat to OpenAI with rice-farming-only, Cebuano/Bisaya-only system prompt.
class OpenAIChatService {
  static const String _systemPrompt = '''
Ikaw usa ka eksperto sa rice farming ug agrikultura sa Pilipinas. Ang imong role kay motubag LAMANG sa mga pangutana nga may kalabotan sa:
- Rice farming (pagtatanom ug pag-uma sa humay)
- Paddy / palay, irigasyon, varieties, pests, harvest, soil, weather para sa humay
- Best practices sa rice production sa Pilipinas

MANDATORY RULES:
1. Tubaga LAMANG sa Cebuano o Bisaya. Ayaw gamit og English o Tagalog sa imong response gawas kon terminolohiya (e.g. scientific name).
2. Kon ang pangutana sa user WALA'y kalabotan sa rice farming o agrikultura, malumong sultihi: "Pasensya, ako kay motubag lamang sa mga pangutana bahin sa rice farming ug humay. Pangutana bahin sa pag-uma sa humay o palay."
3. Gamita og maayong formatting: listahan (bullet o numbered), bold kon kinahanglan, short paragraphs. Pwede ka mohatag og links kon may citation. Use Markdown for lists, **bold**, and [links](url).
4. Himoa nga praktikal ug makatabang sa mga mag-uuma.
''';

  static const String _baseUrl = 'https://api.openai.com/v1';

  /// [history] should already include the latest user message (controller adds it before calling).
  static Future<OpenAIChatResult> sendMessage(List<ChatMessageModel> history, String userMessage) async {
    if (!hasOpenAiKey) {
      return const OpenAIChatResult(error: 'Walay API key. I-set ang OPENAI_API_KEY.');
    }
    // Build messages: system + history (history already contains the new user message)
    final messages = <Map<String, String>>[
      {'role': 'system', 'content': _systemPrompt},
      ...history.map((m) => {'role': m.role, 'content': m.content}),
    ];
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $openAiApiKey',
        },
        body: jsonEncode({
          'model': openAiModel,
          'messages': messages,
          'max_tokens': 1024,
        }),
      ).timeout(
        const Duration(seconds: 60),
        onTimeout: () => throw Exception('Timeout'),
      );

      final body = response.body;
      if (response.statusCode != 200) {
        String err = 'Error ${response.statusCode}';
        try {
          final data = jsonDecode(body) as Map<String, dynamic>?;
          final error = data?['error'];
          if (error is Map<String, dynamic>) {
            final msg = error['message'] as String?;
            if (msg != null && msg.isNotEmpty) err = msg;
          }
        } catch (_) {}
        debugPrint('[OpenAI] $err');
        return OpenAIChatResult(error: err);
      }

      final data = jsonDecode(body) as Map<String, dynamic>?;
      if (data == null) return const OpenAIChatResult(error: 'Invalid response');
      final choices = data['choices'] as List<dynamic>?;
      if (choices == null || choices.isEmpty) {
        return const OpenAIChatResult(error: 'Walay choices sa response');
      }
      final first = choices.first as Map<String, dynamic>?;
      final message = first?['message'] as Map<String, dynamic>?;
      final content = message?['content'] as String?;
      final trimmed = content?.trim();
      if (trimmed == null || trimmed.isEmpty) {
        return const OpenAIChatResult(error: 'Walay content sa response');
      }
      return OpenAIChatResult(content: trimmed);
    } on Exception catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      final err = msg.contains('Timeout') ? 'Timeout. Sulayi usab.' : 'Koneksyon / network: $msg';
      debugPrint('[OpenAI] $err');
      return OpenAIChatResult(error: err);
    } catch (e, stack) {
      debugPrint('[OpenAI] $e\n$stack');
      return OpenAIChatResult(error: 'Error: $e');
    }
  }
}
