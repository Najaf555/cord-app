import 'dart:convert';
import 'package:http/http.dart' as http;

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
      if (choices != null && choices.isNotEmpty) {
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

