import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AzureOpenAIService {
  final String endpoint;
  final String apiKey;
  final String deploymentName;
  final String apiVersion;

  AzureOpenAIService._internal({
    required this.endpoint,
    required this.apiKey,
    required this.deploymentName,
    this.apiVersion = '2024-02-15-preview',
  });

  static AzureOpenAIService? _instance;

  static void initialize({
    required String endpoint,
    required String apiKey,
    required String deploymentName,
    String apiVersion = '2024-02-15-preview',
  }) {
    _instance = AzureOpenAIService._internal(
      endpoint: endpoint,
      apiKey: apiKey,
      deploymentName: deploymentName,
      apiVersion: apiVersion,
    );
  }

  static AzureOpenAIService get instance {
    if (_instance == null) {
      throw Exception('AzureOpenAIService not initialized!');
    }
    return _instance!;
  }

  Future<String?> getChatCompletion({
    required String prompt,
    String? systemPrompt,
    int maxTokens = 256,
    double temperature = 0.7,
  }) async {
    final url = Uri.parse(
      '$endpoint/openai/deployments/$deploymentName/chat/completions?api-version=$apiVersion',
    );

    final headers = {
      'Content-Type': 'application/json',
      'api-key': apiKey,
    };

    final body = jsonEncode({
      'messages': [
        if (systemPrompt != null)
          {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': prompt},
      ],
      'max_tokens': maxTokens,
      'temperature': temperature,
    });

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final choices = data['choices'];
      final usage = data['usage'];
      final totalTokens = usage?['total_tokens'] ?? 0;
      final promptTokens = usage?['prompt_tokens'] ?? 0;
      final completionTokens = usage?['completion_tokens'] ?? 0;
      // GPT-4 Turbo pricing (as of July 2024)
      const double inputPricePer1k = 0.01; // $0.01 per 1,000 input tokens
      const double outputPricePer1k = 0.03; // $0.03 per 1,000 output tokens
      final double cost = (promptTokens / 1000.0) * inputPricePer1k + (completionTokens / 1000.0) * outputPricePer1k;
      if (choices != null && choices.isNotEmpty) {
        // --- API USAGE TRACKING LOGIC ---
        try {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            final usageRef = FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('api_usage');
            await usageRef.add({
              'timestamp': FieldValue.serverTimestamp(),
              'prompt': prompt,
              'systemPrompt': systemPrompt,
              'maxTokens': maxTokens,
              'temperature': temperature,
              'type': 'azure_openai_chat_completion',
              'responseLength': (choices[0]['message']['content'] as String?)?.length ?? 0,
              'totalTokens': totalTokens,
              'promptTokens': promptTokens,
              'completionTokens': completionTokens,
              'cost': cost,
              'model': deploymentName,
              'inputPricePer1k': inputPricePer1k,
              'outputPricePer1k': outputPricePer1k,
            });
          }
        } catch (e) {
          print('Failed to log API usage: $e');
        }
        // --- END API USAGE TRACKING LOGIC ---
        return choices[0]['message']['content'] as String?;
      }
    } else {
      print('Azure OpenAI error: \\${response.statusCode} \\${response.body}');
    }
    return null;
  }
}

// Only one definition and call for the defaults initializer should exist:
void initializeAzureOpenAIDefaults() {
  AzureOpenAIService.initialize(
    endpoint: 'https://cord-ai.openai.azure.com',
    apiKey: 'AlmojE8mLbeHBFjiNBkT0VsuRc8CL0C7Dsq0lhqHL7sKJu3rV8XoJQQJ99BGACYeBjFXJ3w3AAABACOGChqX',
    deploymentName: 'gpt-4.1',
  );
}

// Test function to verify Azure OpenAI setup
Future<void> testAzureOpenAI() async {
  try {
    // Check initialization
    final service = AzureOpenAIService.instance;
    print('AzureOpenAIService initialized with:');
    print('  endpoint: \\${service.endpoint}');
    print('  deploymentName: \\${service.deploymentName}');
    print('  apiKey: \\${service.apiKey.substring(0, 4)}...'); // Only show part of key for security

    // Test API call
    final response = await service.getChatCompletion(
      prompt: 'Say hello from Azure OpenAI!',
    );
    print('Azure OpenAI response:');
    print(response);
  } catch (e) {
    print('Azure OpenAI test error: $e');
  }
}
// To run the test, call testAzureOpenAI() from your app or main.

