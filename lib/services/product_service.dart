import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ProductService {
  static const String baseUrl = "https://shop-backend-nodejs.onrender.com/api/products";
  static const int maxRetries = 3;
  static const Duration timeout = Duration(seconds: 5);

  // Lấy danh sách sản phẩm với phân trang và bộ lọc
  Future<Map<String, dynamic>> fetchProducts({
    int page = 1,
    int limit = 50,
    String? category,
    double? minPrice,
    double? maxPrice,
    String? name,
  }) async {
    int attempt = 0;
    final cacheKey = 'products_page${page}_limit${limit}_${category ?? ''}_${minPrice ?? ''}_${maxPrice ?? ''}_${name ?? ''}';

    // Load cached data
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString(cacheKey);
    if (cachedData != null) {
      try {
        final products = jsonDecode(cachedData) as List<dynamic>;
        if (kDebugMode) {
          debugPrint('📡 Loaded ${products.length} products from cache');
        }
        return {'success': true, 'data': products};
      } catch (e) {
        if (kDebugMode) {
          debugPrint('🔥 Error decoding cached products: $e');
        }
      }
    }

    while (attempt < maxRetries) {
      final client = http.Client();
      try {
        final Uri uri = Uri.parse('$baseUrl?page=$page&limit=$limit'
            '${category != null ? '&category=$category' : ''}'
            '${minPrice != null ? '&minPrice=$minPrice' : ''}'
            '${maxPrice != null ? '&maxPrice=$maxPrice' : ''}'
            '${name != null ? '&name=$name' : ''}');

        final response = await client.get(uri).timeout(timeout);

        if (kDebugMode) {
          debugPrint('📡 Fetch products response: ${response.statusCode}, attempt ${attempt + 1}');
        }

        if (response.statusCode == 200) {
          final products = jsonDecode(response.body) as List<dynamic>;
          await prefs.setString(cacheKey, jsonEncode(products));
          client.close();
          return {'success': true, 'data': products};
        } else {
          client.close();
          return {
            'success': false,
            'error': 'Lỗi khi lấy danh sách sản phẩm (${response.statusCode})'
          };
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('🔥 Fetch products error (attempt ${attempt + 1}): $e');
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

  // Lấy thông tin chi tiết sản phẩm theo ID
  Future<Map<String, dynamic>> fetchProductById(String id) async {
    int attempt = 0;
    final cacheKey = 'product_$id';

    // Load cached data
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString(cacheKey);
    if (cachedData != null) {
      try {
        final product = jsonDecode(cachedData) as Map<String, dynamic>;
        if (kDebugMode) {
          debugPrint('📡 Loaded product $id from cache');
        }
        return {'success': true, 'data': product};
      } catch (e) {
        if (kDebugMode) {
          debugPrint('🔥 Error decoding cached product: $e');
        }
      }
    }

    while (attempt < maxRetries) {
      final client = http.Client();
      try {
        final response = await client
            .get(Uri.parse('$baseUrl/$id'))
            .timeout(timeout);

        if (kDebugMode) {
          debugPrint('📡 Fetch product $id response: ${response.statusCode}, attempt ${attempt + 1}');
        }

        if (response.statusCode == 200) {
          final product = jsonDecode(response.body) as Map<String, dynamic>;
          await prefs.setString(cacheKey, jsonEncode(product));
          client.close();
          return {'success': true, 'data': product};
        } else if (response.statusCode == 404) {
          client.close();
          return {'success': false, 'error': 'Sản phẩm không tồn tại'};
        } else {
          client.close();
          return {
            'success': false,
            'error': 'Lỗi khi lấy thông tin sản phẩm (${response.statusCode})'
          };
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('🔥 Fetch product $id error (attempt ${attempt + 1}): $e');
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

  // Thêm sản phẩm mới (Chỉ dành cho admin)
  Future<Map<String, dynamic>> createProduct(Map<String, dynamic> productData, String token) async {
    int attempt = 0;

    while (attempt < maxRetries) {
      final client = http.Client();
      try {
        final response = await client
            .post(
              Uri.parse(baseUrl),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: jsonEncode(productData),
            )
            .timeout(timeout);

        if (kDebugMode) {
          debugPrint('📡 Create product response: ${response.statusCode}, attempt ${attempt + 1}');
        }

        if (response.statusCode == 201) {
          final product = jsonDecode(response.body) as Map<String, dynamic>;
          client.close();
          return {'success': true, 'data': product};
        } else {
          client.close();
          return {
            'success': false,
            'error': 'Lỗi khi thêm sản phẩm (${response.statusCode})'
          };
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('🔥 Create product error (attempt ${attempt + 1}): $e');
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

  // Cập nhật sản phẩm theo ID (Chỉ dành cho admin)
  Future<Map<String, dynamic>> updateProduct(String id, Map<String, dynamic> updateData, String token) async {
    int attempt = 0;

    while (attempt < maxRetries) {
      final client = http.Client();
      try {
        final response = await client
            .put(
              Uri.parse('$baseUrl/$id'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: jsonEncode(updateData),
            )
            .timeout(timeout);

        if (kDebugMode) {
          debugPrint('📡 Update product $id response: ${response.statusCode}, attempt ${attempt + 1}');
        }

        if (response.statusCode == 200) {
          final product = jsonDecode(response.body) as Map<String, dynamic>;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('product_$id', jsonEncode(product));
          client.close();
          return {'success': true, 'data': product};
        } else {
          client.close();
          return {
            'success': false,
            'error': 'Lỗi khi cập nhật sản phẩm (${response.statusCode})'
          };
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('🔥 Update product $id error (attempt ${attempt + 1}): $e');
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

  // Xóa sản phẩm theo ID (Chỉ dành cho admin)
  Future<Map<String, dynamic>> deleteProduct(String id, String token) async {
    int attempt = 0;

    while (attempt < maxRetries) {
      final client = http.Client();
      try {
        final response = await client
            .delete(
              Uri.parse('$baseUrl/$id'),
              headers: {'Authorization': 'Bearer $token'},
            )
            .timeout(timeout);

        if (kDebugMode) {
          debugPrint('📡 Delete product $id response: ${response.statusCode}, attempt ${attempt + 1}');
        }

        if (response.statusCode == 200) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('product_$id');
          client.close();
          return {'success': true};
        } else {
          client.close();
          return {
            'success': false,
            'error': 'Lỗi khi xóa sản phẩm (${response.statusCode})'
          };
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('🔥 Delete product $id error (attempt ${attempt + 1}): $e');
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
}