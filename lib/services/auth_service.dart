import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = "https://shop-backend-nodejs.onrender.com/api/auth";
  static const int maxRetries = 3;
  static const Duration timeout = Duration(seconds: 5);

  /// **Đăng nhập**
  Future<Map<String, dynamic>> login(String email, String password) async {
    int attempt = 0;

    while (attempt < maxRetries) {
      final client = http.Client();
      try {
        final response = await client
            .post(
              Uri.parse('$baseUrl/login'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'email': email, 'password': password}),
            )
            .timeout(timeout);

        if (kDebugMode) {
          debugPrint('📡 Login response: ${response.statusCode}, attempt ${attempt + 1}');
        }

        final result = _handleResponse(response, action: 'login');
        client.close();

        if (result['success'] == true) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('authToken', result['data']['token']);
          await prefs.setString('last_email', email);
        }

        return result;
      } catch (e) {
        if (kDebugMode) {
          debugPrint('🔥 Login error (attempt ${attempt + 1}): $e');
        }
        attempt++;
        client.close();
        if (attempt >= maxRetries) {
          return {
            'success': false,
            'error': '🚫 Không thể kết nối đến máy chủ! Hãy kiểm tra mạng.'
          };
        }
        await Future.delayed(const Duration(seconds: 2));
      }
    }
    return {
      'success': false,
      'error': '🚫 Không thể kết nối sau $maxRetries lần thử.'
    };
  }

  /// **Đăng ký**
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String address,
    required String avatar,
    required String role,
  }) async {
    int attempt = 0;

    while (attempt < maxRetries) {
      final client = http.Client();
      try {
        final response = await client
            .post(
              Uri.parse('$baseUrl/register'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'name': name,
                'email': email,
                'password': password,
                'phone': phone,
                'address': address,
                'avatar': avatar,
                'role': role,
              }),
            )
            .timeout(timeout);

        if (kDebugMode) {
          debugPrint('📡 Register response: ${response.statusCode}, attempt ${attempt + 1}');
        }

        final result = _handleResponse(response, action: 'register');
        client.close();
        return result;
      } catch (e) {
        if (kDebugMode) {
          debugPrint('🔥 Register error (attempt ${attempt + 1}): $e');
        }
        attempt++;
        client.close();
        if (attempt >= maxRetries) {
          return {'error': '🚫 Không thể kết nối đến máy chủ! Hãy thử lại.'};
        }
        await Future.delayed(const Duration(seconds: 2));
      }
    }
    return {'error': '🚫 Không thể kết nối sau $maxRetries lần thử.'};
  }

  /// **Xử lý phản hồi từ server**
  Map<String, dynamic> _handleResponse(http.Response response, {required String action}) {
    try {
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return action == 'login' ? {'success': true, 'data': data} : data;
      }

      // Xử lý lỗi khi đăng nhập
      if (action == 'login') {
        if (response.statusCode == 400) {
          return {'success': false, 'error': 'Sai email hoặc mật khẩu!'};
        } else if (response.statusCode == 401) {
          return {'success': false, 'error': 'Sai mật khẩu! Vui lòng kiểm tra lại.'};
        } else if (response.statusCode == 404) {
          return {'success': false, 'error': 'Tài khoản không tồn tại! Vui lòng đăng ký trước.'};
        }
      }

      // Xử lý lỗi khi đăng ký
      if (action == 'register') {
        if (response.statusCode == 400) {
          return {'error': data['message'] ?? 'Dữ liệu nhập vào không hợp lệ!'};
        } else if (response.statusCode == 409) {
          if (data['message'] == 'Email đã tồn tại') {
            return {'error': 'Email này đã được sử dụng! Vui lòng chọn email khác.'};
          } else if (data['message'] == 'Số điện thoại đã tồn tại') {
            return {'error': 'Số điện thoại này đã được đăng ký! Dùng số khác nhé.'};
          }
        }
      }

      // Xử lý lỗi chung
      if (response.statusCode == 500) {
        return action == 'login'
            ? {'success': false, 'error': 'Lỗi máy chủ! Vui lòng thử lại sau.'}
            : {'error': 'Lỗi máy chủ! Vui lòng thử lại sau.'};
      }

      return action == 'login'
          ? {'success': false, 'error': 'Lỗi không xác định (${response.statusCode})'}
          : {'error': 'Lỗi không xác định (${response.statusCode})'};
    } catch (e) {
      if (kDebugMode) {
        debugPrint('🔥 Error parsing response: $e');
      }
      return action == 'login'
          ? {'success': false, 'error': 'Lỗi xử lý dữ liệu từ server!'}
          : {'error': 'Lỗi xử lý dữ liệu từ server!'};
    }
  }
}