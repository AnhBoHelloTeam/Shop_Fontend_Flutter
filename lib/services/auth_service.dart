import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  final String baseUrl = "https://shop-backend-nodejs.onrender.com/api/auth"; // Nếu dùng giả lập Android

  /// **Đăng nhập**
 Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      print("📤 Request: $email | $password"); // Debug dữ liệu gửi lên
      print("📥 Response (${response.statusCode}): ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data}; // Đăng nhập thành công
      } else {
        final errorData = jsonDecode(response.body);
        return {'success': false, 'error': errorData['message'] ?? '❌ Sai email hoặc mật khẩu!'};
      }
    } catch (e) {
      print("❌ Lỗi khi kết nối: $e"); // Log lỗi
      return {'success': false, 'error': '🚫 Không thể kết nối đến máy chủ! Hãy kiểm tra mạng.'};
    }
}

  /// **Đăng ký**
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String address,
    required String avatar,
    required String role, // admin/user
  }) async {
    try {
      final response = await http.post(
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
      );

      return _handleResponse(response, action: 'register');
    } catch (e) {
      return {'error': 'Lỗi không xác định! Vui lòng thử lại.'};
    }
  }

  /// **Xử lý phản hồi từ server**
  Map<String, dynamic> _handleResponse(http.Response response, {required String action}) {
    try {
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return data;
      }

      // ✅ Xử lý lỗi khi đăng nhập
      if (action == 'login') {
        if (response.statusCode == 400) {
          return {'error': 'Sai email hoặc mật khẩu!'};
        } else if (response.statusCode == 401) {
          return {'error': 'Sai mật khẩu! Vui lòng kiểm tra lại.'};
        } else if (response.statusCode == 404) {
          return {'error': 'Tài khoản không tồn tại! Vui lòng đăng ký trước.'};
        }
      }

      // ✅ Xử lý lỗi khi đăng ký
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

      // ✅ Xử lý lỗi chung
      if (response.statusCode == 500) {
        return {'error': 'Lỗi máy chủ! Vui lòng thử lại sau.'};
      }

      return {'error': 'Lỗi không xác định (${response.statusCode})'};
    } catch (e) {
      return {'error': 'Lỗi xử lý dữ liệu từ server! Vui lòng thử lại.'};
    }
  }
}
