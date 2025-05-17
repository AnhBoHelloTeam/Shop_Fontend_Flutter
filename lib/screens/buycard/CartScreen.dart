import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shop_frontend/screens/buycard/checkout_screen.dart';
import 'package:shop_frontend/screens/login_screen.dart';

class CartScreen extends StatefulWidget {
  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<dynamic> cartItems = [];
  bool isLoading = true;
  bool isLoggedIn = false;
  int totalQuantity = 0;
  double totalPrice = 0.0;
  final String apiUrl = "https://shop-backend-nodejs.onrender.com/api/cart/";

  @override
  void initState() {
    super.initState();
    fetchCartItems();
  }

  Future<void> fetchCartItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('authToken') ?? '';

      if (authToken.isEmpty) {
        setState(() {
          isLoading = false;
          isLoggedIn = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {"Authorization": "Bearer $authToken"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          isLoggedIn = true;
          cartItems = data['items'] ?? [];
          totalQuantity = data['totalQuantity'] ?? 0;
          totalPrice = (data['totalPrice'] ?? 0).toDouble();
          isLoading = false;
        });
      } else {
        print("❌ Lỗi khi lấy giỏ hàng: ${response.body}");
        setState(() {
          isLoading = false;
          isLoggedIn = true;
        });
      }
    } catch (error) {
      print("🔥 Lỗi: $error");
      setState(() {
        isLoading = false;
        isLoggedIn = false;
      });
    }
  }

  Future<void> increaseItemQuantity(String productId) async {
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('authToken') ?? '';
    if (authToken.isEmpty) return;

    final response = await http.put(
      Uri.parse("$apiUrl/increase/$productId"),
      headers: {"Authorization": "Bearer $authToken"},
    );

    if (response.statusCode == 200) {
      fetchCartItems();
    } else {
      print("❌ Lỗi khi tăng số lượng: ${response.body}");
    }
  }

  Future<void> decreaseItemQuantity(String productId) async {
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('authToken') ?? '';
    if (authToken.isEmpty) return;

    final response = await http.put(
      Uri.parse("$apiUrl/decrease/$productId"),
      headers: {"Authorization": "Bearer $authToken"},
    );

    if (response.statusCode == 200) {
      fetchCartItems();
    } else {
      print("❌ Lỗi khi giảm số lượng: ${response.body}");
    }
  }

  Future<void> removeItemFromCart(String productId) async {
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('authToken') ?? '';
    if (authToken.isEmpty) return;

    final response = await http.delete(
      Uri.parse("https://shop-backend-nodejs.onrender.com/api/cart/remove/$productId"),
      headers: {"Authorization": "Bearer $authToken"},
    );

    if (response.statusCode == 200) {
      fetchCartItems();
    } else {
      print("❌ Lỗi khi xóa sản phẩm: ${response.body}");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text("Giỏ hàng")),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: Text("Giỏ hàng")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Vui lòng đăng nhập để sử dụng giỏ hàng!"),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => LoginScreen()),
                  );
                },
                child: Text("Đăng nhập"),
              )
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Giỏ hàng"),
        backgroundColor: Colors.orange,
      ),
      body: cartItems.isEmpty
          ? Center(child: Text("Giỏ hàng của bạn đang trống!"))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      final product = item['product'];

                      if (product == null) {
                        return ListTile(
                          leading: Icon(Icons.error, color: Colors.red),
                          title: Text("Sản phẩm không tồn tại"),
                          subtitle: Text("Dữ liệu sản phẩm bị thiếu."),
                          trailing: IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () {
                              final fallbackId = item['product']?['_id'] ?? '';
                              if (fallbackId.isNotEmpty) {
                                removeItemFromCart(fallbackId);
                              }
                            },
                          ),
                        );
                      }

                      final quantity = item['quantity'] ?? 0;
                      final totalItemPrice = item['totalItemPrice'] ?? 0;
                      final productId = product['_id'] ?? '';

                      return ListTile(
                        leading: Image.network(
                          product['image'] ?? 'https://via.placeholder.com/100',
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        ),
                        title: Text(product['name'] ?? 'Không có tên'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Giá: ${product['price'] ?? 0} đ"),
                            Text("Số lượng: $quantity"),
                            Text("Tổng giá: $totalItemPrice đ",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.remove_circle, color: Colors.red),
                              onPressed: () => decreaseItemQuantity(productId),
                            ),
                            Text("$quantity"),
                            IconButton(
                              icon: Icon(Icons.add_circle, color: Colors.green),
                              onPressed: () => increaseItemQuantity(productId),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () => removeItemFromCart(productId),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Divider(),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Tổng số lượng: $totalQuantity",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 10),
                      Text("Tổng giá: ${totalPrice.toStringAsFixed(2)} đ",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
                      SizedBox(height: 20),
                      ElevatedButton(
                        key: Key('checkoutButton'),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => CheckoutPage()),
                          ).then((_) => fetchCartItems());
                        },
                        child: Text("Mua hàng"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: EdgeInsets.symmetric(vertical: 15, horizontal: 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
