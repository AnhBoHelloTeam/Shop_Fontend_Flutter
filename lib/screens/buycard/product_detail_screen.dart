import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ProductDetailScreen extends StatelessWidget {
  // Gửi yêu cầu thêm vào giỏ hàng
  Future<void> addToCart(BuildContext context, String productId) async {
    final String apiUrl = "https://shop-backend-nodejs.onrender.com/api/cart/add";

    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('authToken') ?? '';

      if (authToken.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("🔐 Bạn cần đăng nhập để thêm vào giỏ hàng")),
        );
        return;
      }

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $authToken"
        },
        body: jsonEncode({
          "productId": productId,
          "quantity": 1,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ Đã thêm vào giỏ hàng")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Lỗi khi thêm vào giỏ hàng")),
        );
      }
    } catch (error) {
      print("🔥 Lỗi: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ Không thể thêm vào giỏ hàng")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = ModalRoute.of(context)?.settings.arguments as Map;

    return Scaffold(
      appBar: AppBar(
        title: Text(product['name'] ?? 'Chi tiết sản phẩm'),
        backgroundColor: Colors.orange,
        leading: IconButton(
          key: Key('backButton'),  // ← Thêm Key cho nút quay lại
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth > 600;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Image.network(
                    product['image'] ?? 'https://via.placeholder.com/150',
                    height: isTablet ? 300 : 250,
                    fit: BoxFit.cover,
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  product['name'] ?? 'Không có tên',
                  style: TextStyle(fontSize: isTablet ? 28 : 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),
                Text(
                  "Giá: ${product['price'] ?? 'N/A'} đ",
                  style: TextStyle(color: Colors.red, fontSize: isTablet ? 22 : 20),
                ),
                SizedBox(height: 12),
                Text(
                  "Mô tả: ${product['description'] ?? 'Không có mô tả'}",
                  style: TextStyle(fontSize: isTablet ? 18 : 16),
                ),
                SizedBox(height: 12),
                Text(
                  "Danh mục: ${product['category'] ?? 'Không có danh mục'}",
                  style: TextStyle(fontSize: isTablet ? 18 : 16),
                ),
                SizedBox(height: 12),
                Text(
                  "Số lượng còn lại: ${product['stock'] ?? 'Không xác định'}",
                  style: TextStyle(fontSize: isTablet ? 18 : 16),
                ),
                SizedBox(height: 32),
                Center(
                  child: ElevatedButton(
                    onPressed: () => addToCart(context, product['_id']),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: EdgeInsets.symmetric(
                        vertical: isTablet ? 18 : 14,
                        horizontal: isTablet ? 60 : 40,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      textStyle: TextStyle(fontSize: isTablet ? 20 : 18),
                    ),
                    child: Text('🛒 Thêm vào giỏ hàng'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
