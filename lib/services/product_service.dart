import 'dart:convert';
import 'package:http/http.dart' as http;

class ProductService {
  final String baseUrl = "https://shop-backend-nodejs.onrender.com/api/products"; // URL mới trên Render

  // 📌 Lấy danh sách sản phẩm với phân trang và bộ lọc
  Future<List<dynamic>> fetchProducts({int page = 1, int limit = 50, String? category, double? minPrice, double? maxPrice, String? name}) async {
  try {
    final Uri uri = Uri.parse('$baseUrl?page=$page&limit=$limit'
        '${category != null ? '&category=$category' : ''}'
        '${minPrice != null ? '&minPrice=$minPrice' : ''}'
        '${maxPrice != null ? '&maxPrice=$maxPrice' : ''}'
        '${name != null ? '&name=$name' : ''}');

    print('🌐 Gửi request đến: $uri'); // In ra URL request để kiểm tra

    final response = await http.get(uri);

    print('🔍 Status Code: ${response.statusCode}'); // In ra status code của response
    print('📄 Dữ liệu phản hồi: ${response.body}'); // In ra nội dung response

    if (response.statusCode == 200) {
      List<dynamic> responseData = jsonDecode(response.body);
      if (responseData.isNotEmpty) {
        print('📦 Dữ liệu sản phẩm: $responseData');
      } else {
        print('🔍 Không có sản phẩm trong dữ liệu trả về.');
      }
      return responseData;
    } else {
      throw Exception('Lỗi khi lấy danh sách sản phẩm');
    }
  } catch (e) {
    print('❌ Lỗi fetchProducts: $e');
    return [];
  }
}


  // 📌 Lấy thông tin chi tiết sản phẩm theo ID
  Future<Map<String, dynamic>?> fetchProductById(String id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/$id'));

      print('🔍 Status Code: ${response.statusCode}');
      print('📄 Dữ liệu phản hồi: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Lỗi khi lấy thông tin sản phẩm');
      }
    } catch (e) {
      print('❌ Lỗi fetchProductById: $e');
      return null;
    }
  }

  // 📌 Thêm sản phẩm mới (Chỉ dành cho admin)
  Future<Map<String, dynamic>?> createProduct(Map<String, dynamic> productData, String token) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(productData),
      );

      print('🔍 Status Code: ${response.statusCode}');
      print('📄 Dữ liệu phản hồi: ${response.body}');

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Lỗi khi thêm sản phẩm');
      }
    } catch (e) {
      print('❌ Lỗi createProduct: $e');
      return null;
    }
  }

  // 📌 Cập nhật sản phẩm theo ID (Chỉ dành cho admin)
  Future<Map<String, dynamic>?> updateProduct(String id, Map<String, dynamic> updateData, String token) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(updateData),
      );

      print('🔍 Status Code: ${response.statusCode}');
      print('📄 Dữ liệu phản hồi: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Lỗi khi cập nhật sản phẩm');
      }
    } catch (e) {
      print('❌ Lỗi updateProduct: $e');
      return null;
    }
  }

  // 📌 Xóa sản phẩm theo ID (Chỉ dành cho admin)
  Future<bool> deleteProduct(String id, String token) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/$id'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print('🔍 Status Code: ${response.statusCode}');

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Lỗi deleteProduct: $e');
      return false;
    }
  }
}
