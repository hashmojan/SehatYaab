// gemini_services.dart
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  final String apiKey='AIzaSyCRVfU3YisNLx4lBIDaBqKw3yz_AOMOEjQ';
  late final GenerativeModel _model;

  GeminiService() {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash-latest',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        maxOutputTokens: 1000,
        temperature: 0.5,
      ),
    );
  }

  Future<String> sendMessage(String text) async {
    try {
      final content = [Content.text(text)];
      final response = await _model.generateContent(content);
      return response.text ?? 'Empty response received';
    } on GenerativeAIException catch (e) {
      throw 'API Error: ${e.message}';
    } catch (e) {
      throw 'Network Error: ${e.toString()}';
    }
  }
}