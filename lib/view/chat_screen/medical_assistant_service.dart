import 'package:google_generative_ai/google_generative_ai.dart';

class MedicalAssistantService {
  final String apiKey='AIzaSyCRVfU3YisNLx4lBIDaBqKw3yz_AOMOEjQ';
  late final GenerativeModel _model;

  MedicalAssistantService() {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash-latest',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        maxOutputTokens: 1000,
        temperature: 0.4, // Slightly lower temperature for medical accuracy
      ),
      safetySettings: [
        // SafetySetting(HarmCategory.medical, HarmBlockThreshold.high),
        // SafetySetting(HarmCategory.dangerous, HarmBlockThreshold.high),
      ],
    );
  }

  Future<String> sendMessage(String text) async {
    try {
      // Add medical context to the prompt
      final prompt = "You are a medical assistant for sehatyab app. "
          "Provide accurate, concise medical information. "
          "If asked about symptoms, suggest consulting a doctor. "
          "Never provide diagnoses. User question: $text";

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      return response.text ?? 'I couldn\'t process that request. Please try again.';
    } on GenerativeAIException catch (e) {
      throw 'Medical API Error: ${e.message}';
    } catch (e) {
      throw 'Network Error: Please check your connection and try again.';
    }
  }
}