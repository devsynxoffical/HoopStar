import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const baseUrl = 'http://localhost:5000';
  
  print('Testing backend connection...');
  
  // Test server status
  try {
    final response = await http.get(Uri.parse('$baseUrl/'));
    print('✅ Server status: ${response.statusCode}');
    print('   Response: ${response.body}');
  } catch (e) {
    print('❌ Server connection failed: $e');
    return;
  }
  
  // Test admin login
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/admin/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': 'admin@test.com',
        'password': 'password123',
      }),
    );
    print('✅ Admin login: ${response.statusCode}');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('   User: ${data['username']} (${data['role']})');
      print('   Token: ${data['token']}');
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
    print('✅ Coach login: ${response.statusCode}');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('   User: ${data['username']} (${data['role']})');
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
    print('✅ Player login: ${response.statusCode}');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('   User: ${data['username']} (${data['role']})');
    }
  } catch (e) {
    print('❌ Player login failed: $e');
  }
  
  // Test admin overview
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/api/auth/admin/overview'),
      headers: {'Authorization': 'Bearer mock_admin_token'},
    );
    print('✅ Admin overview: ${response.statusCode}');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('   Academy: ${data['admin']['academyName']}');
      print('   Staff count: ${data['staff'].length}');
      print('   Teams count: ${data['teams'].length}');
    }
  } catch (e) {
    print('❌ Admin overview failed: $e');
  }
  
  print('\n🎉 Backend connection test completed!');
}
