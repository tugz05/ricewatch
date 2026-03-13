import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_config.dart';

/// AI-generated treatment recommendations for a rice disease.
class TreatmentRecommendation {
  const TreatmentRecommendation({
    required this.diseaseName,
    required this.organicTreatments,
    required this.chemicalTreatments,
    required this.commonProducts,
    required this.applicationSteps,
    this.rawMarkdown,
  });

  final String diseaseName;
  final List<String> organicTreatments;
  final List<String> chemicalTreatments;
  final List<String> commonProducts;
  final List<String> applicationSteps;
  final String? rawMarkdown;
}

/// Fetches treatment recommendations from OpenAI for a given rice disease.
class TreatmentRecommendationService {
  static const _url = 'https://api.openai.com/v1/chat/completions';

  static const _systemPrompt = '''
Ikaw usa ka eksperto sa rice disease treatment sa Pilipinas. Ang imong role kay mohatag og praktikal nga rekomendasyon sa pagtambal sa rice leaf diseases.

MANDATORY: Tubaga LAMANG sa Cebuano/Bisaya. Gamita og Markdown formatting.

Para sa kada sakit nga gihatag, ihulagway:
1. **Organiko nga Pagtambal** - Natural, organic methods (e.g. neem oil, garlic spray, proper spacing, crop rotation)
2. **Kemikal nga Pagtambal** - Approved fungicides/pesticides nga available sa Pilipinas
3. **Common nga Produkto** - Specific product names nga makit-an sa agri stores (e.g. Fuzion, Nativo, Amistar)
4. **Application Steps** - Step-by-step unsaon pag-apply (dosis, frequency, safety)

Himoa nga praktikal ug makatabang sa mga mag-uuma. I-link ang products sa common Philippine brands.
''';

  static Future<TreatmentRecommendation?> getRecommendations(String diseaseName) async {
    if (!hasOpenAiKey) return null;

    try {
      final response = await http.post(
        Uri.parse(_url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $openAiApiKey',
        },
        body: jsonEncode({
          'model': openAiModel,
          'messages': [
            {'role': 'system', 'content': _systemPrompt},
            {
              'role': 'user',
              'content':
                  'Hatagi ko og detalyadong treatment recommendations para sa rice disease: **$diseaseName**. '
                  'Include organic ug chemical options, common products sa Pilipinas, ug application steps. Tubag sa Cebuano.',
            },
          ],
          'max_tokens': 800,
        }),
      ).timeout(const Duration(seconds: 45));

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>?;
      final choices = data?['choices'] as List<dynamic>?;
      if (choices == null || choices.isEmpty) return null;

      final content = (choices.first as Map<String, dynamic>?)?['message']?['content'];
      if (content is! String || content.isEmpty) return null;

      return TreatmentRecommendation(
        diseaseName: diseaseName,
        organicTreatments: [],
        chemicalTreatments: [],
        commonProducts: [],
        applicationSteps: [],
        rawMarkdown: content.trim(),
      );
    } catch (_) {
      return null;
    }
  }
}
