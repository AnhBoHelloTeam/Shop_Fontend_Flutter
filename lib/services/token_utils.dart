
import 'package:jwt_decoder/jwt_decoder.dart';

class TokenUtils {
  // Giải mã token và lấy userId
  static String? getUserIdFromToken(String token) {
    try {
      final decodedToken = JwtDecoder.decode(token);
      return decodedToken["userId"];
    } catch (e) {
      print("Lỗi khi giải mã token: $e");
      return null;
    }
  }
}
