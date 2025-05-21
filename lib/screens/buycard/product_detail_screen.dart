import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ProductDetailScreen extends StatefulWidget {
  @override
  _ProductDetailScreenState createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  Map<dynamic, dynamic>? product;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    // Trì hoãn load dữ liệu đến khi context sẵn sàng
    Future.microtask(() => _loadProductData());
  }

  // Hàm lấy dữ liệu sản phẩm
  Future<void> _loadProductData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    // Thử lấy từ arguments
    final dynamic arguments = ModalRoute.of(context)?.settings.arguments;
    print('📡 ProductDetailScreen arguments: $arguments');

    if (arguments != null && arguments is Map<dynamic, dynamic> && arguments['_id'] != null) {
      setState(() {
        product = arguments;
        isLoading = false;
      });
      print('📡 Product set from arguments: $product');
      return;
    }

    // Nếu arguments không hợp lệ, thử lấy từ API (dự phòng)
    String? productId;
    if (arguments is Map<dynamic, dynamic> && arguments['_id'] is String) {
      productId = arguments['_id'];
    }

    if (productId != null) {
      const maxRetries = 2;
      int attempt = 0;

      while (attempt <= maxRetries) {
        try {
          final client = http.Client();
          final response = await client
              .get(
                Uri.parse('https://shop-backend-nodejs.onrender.com/api/products/$productId'),
                headers: {'Connection': 'keep-alive'},
              )
              .timeout(Duration(seconds: 10));
          client.close();

          print('📡 Fetch product detail ($productId, attempt ${attempt + 1}): ${response.statusCode} - ${response.body}');

          if (response.statusCode == 200) {
            final data = json.decode(response.body) as Map<dynamic, dynamic>;
            if (data['_id'] != null) {
              setState(() {
                product = data;
                isLoading = false;
              });
              print('📡 Product set from API: $product');
              return;
            }
            setState(() {
              isLoading = false;
              errorMessage = 'Dữ liệu sản phẩm không hợp lệ: Thiếu ID';
            });
            return;
          } else {
            setState(() {
              isLoading = false;
              errorMessage = 'Không tìm thấy sản phẩm (Status: ${response.statusCode})';
            });
            return;
          }
        } catch (e) {
          print('🔥 Lỗi khi lấy chi tiết sản phẩm (attempt ${attempt + 1}): $e');
          attempt++;
          if (attempt > maxRetries) {
            setState(() {
              isLoading = false;
              errorMessage = 'Lỗi kết nối khi lấy chi tiết sản phẩm: $e';
            });
            return;
          }
          await Future.delayed(Duration(seconds: 1));
        }
      }
    } else {
      setState(() {
        isLoading = false;
        errorMessage = 'Không có ID sản phẩm hợp lệ. Arguments: $arguments';
      });
      print('📡 Error: No valid product ID. Arguments: $arguments');
    }
  }

  // Gửi yêu cầu thêm vào giỏ hàng
  Future<void> addToCart(BuildContext context, String? productId) async {
    final String apiUrl = "https://shop-backend-nodejs.onrender.com/api/cart/add";

    if (productId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Lỗi: Không có ID sản phẩm")),
      );
      return;
    }

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
          SnackBar(content: Text("❌ Lỗi khi thêm vào giỏ hàng: ${response.statusCode}")),
        );
      }
    } catch (error) {
      print("🔥 Lỗi khi thêm vào giỏ hàng: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ Không thể thêm vào giỏ hàng")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    print('📡 Building ProductDetailScreen, product: $product');

    if (isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null || product == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Lỗi')),
        body: Center(child: Text(errorMessage ?? 'Không có dữ liệu sản phẩm')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(product!['name'] ?? 'Chi tiết sản phẩm'),
        backgroundColor: Colors.orange,
        leading: IconButton(
          key: Key('backButton'),
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
                    product!['image'] ?? 'https://via.placeholder.com/150',
                    height: isTablet ? 300 : 250,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Icon(Icons.error, size: 100),
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  product!['name'] ?? 'Không có tên',
                  style: TextStyle(fontSize: isTablet ? 28 : 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),
                Text(
                  "Giá: ${product!['price'] ?? 'N/A'} đ",
                  style: TextStyle(color: Colors.red, fontSize: isTablet ? 22 : 20),
                ),
                SizedBox(height: 12),
                Text(
                  "Mô tả: ${product!['description'] ?? 'Không có mô tả'}",
                  style: TextStyle(fontSize: isTablet ? 18 : 16),
                ),
                SizedBox(height: 12),
                Text(
                  "Danh mục: ${product!['category'] ?? 'Không có danh mục'}",
                  style: TextStyle(fontSize: isTablet ? 18 : 16),
                ),
                SizedBox(height: 12),
                Text(
                  "Số lượng còn lại: ${product!['stock'] ?? 'Không xác định'}",
                  style: TextStyle(fontSize: isTablet ? 18 : 16),
                ),
                SizedBox(height: 32),
                Center(
                  child: ElevatedButton(
                    onPressed: () => addToCart(context, product!['_id']),
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