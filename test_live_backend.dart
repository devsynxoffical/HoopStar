import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const baseUrl = 'https://ballchart-production.up.railway.app';
  
  print('🔗 Testing LIVE backend connection...');
  print('URL: $baseUrl');
  
  // Test server status
  try {
    final response = await http.get(Uri.parse('$baseUrl/'));
    print('✅ Server status: ${response.statusCode}');
    print('   Response: ${response.body}');
  } catch (e) {
    print('❌ Server connection failed: $e');
    print('   Trying alternative endpoints...');
    
    // Try API health check
    try {
      final healthResponse = await http.get(Uri.parse('$baseUrl/api'));
      print('✅ API endpoint: ${healthResponse.statusCode}');
    } catch (e) {
      print('❌ API endpoint failed: $e');
      return;
    }
  }
  
  // Test admin login with dummy data
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/admin/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': 'admin@test.com',
        'password': 'password123',
      }),
    );
    print('✅ Admin login test: ${response.statusCode}');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('   Response: ${data['username'] ?? 'Unknown'} (${data['role'] ?? 'Unknown'})');
    } else {
      print('   Error: ${response.body}');
    }
  } catch (e) {
    print('❌ Admin login failed: $e');
  }
  
  // Test coach login
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/coach/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': 'coach@test.com',
        'password': 'password123',
      }),
    );
    print('✅ Coach login test: ${response.statusCode}');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('   Response: ${data['username'] ?? 'Unknown'} (${data['role'] ?? 'Unknown'})');
    } else {
      print('   Error: ${response.body}');
    }
  } catch (e) {
    print('❌ Coach login failed: $e');
  }
  
  // Test player login
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/player/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': 'player@test.com',
        'password': 'password123',
      }),
    );
    print('✅ Player login test: ${response.statusCode}');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('   Response: ${data['username'] ?? 'Unknown'} (${data['role'] ?? 'Unknown'})');
    } else {
      print('   Error: ${response.body}');
    }
  } catch (e) {
    print('❌ Player login failed: $e');
  }
  
  print('\n🎯 Live backend test completed!');
  print('If tests failed, the live backend may need real user accounts.');
}
