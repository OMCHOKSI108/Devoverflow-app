import 'dart:convert';
import 'package:http/http.dart' as http;
import 'lib/logger.dart' as logger;

void main() async {
  // Use the user-provided backend URL
  final base = 'https://devoverflow-backend.onrender.com/api';
  final url = '$base/questions';

  try {
    logger.logInfo('Testing API connectivity to correct endpoint...');
    final response = await http.get(Uri.parse(url));
    logger.logInfo('Status Code: ${response.statusCode}');
    logger.logInfo('Response length: ${response.body.length}');
    logger.logInfo('Response: ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      logger.logInfo('API is working! Success: ${data['success']}');
      if (data['questions'] != null) {
        logger.logInfo(
          'Questions count: ${(data['questions'] as List).length}',
        );
      }
    } else {
      logger.logWarn('API returned error status');
    }
  } catch (e) {
    logger.logError('Error connecting to API: $e');
  }
}
