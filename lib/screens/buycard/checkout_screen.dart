import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CheckoutPage extends StatefulWidget {
  @override
  _CheckoutPageState createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  List<dynamic> cartItems = [];
  double totalPrice = 0.0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCartItems();
  }

  Future<void> fetchCartItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('authToken') ?? '';

      if (authToken.isEmpty) return;

      final url = "https://shop-backend-nodejs.onrender.com/api/cart";
      final response = await http.get(
        Uri.parse(url),
        headers: {"Authorization": "Bearer $authToken"},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          cartItems = data['items'];
          totalPrice = cartItems.fold(0.0, (sum, item) {
            return sum + (item['product']['price'] * item['quantity']);
          });
          isLoading = false;
        });
      } else {
        print("❌ Lỗi khi lấy giỏ hàng: ${response.body}");
        setState(() => isLoading = false);
      }
    } catch (error) {
      print("🔥 Lỗi khi lấy giỏ hàng: $error");
      setState(() => isLoading = false);
    }
  }

  Future<void> checkout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('authToken') ?? '';

      if (authToken.isEmpty) return;

      final url = "https://shop-backend-nodejs.onrender.com/api/orders/checkout";
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer $authToken",
          "Content-Type": "application/json"
        },
        body: json.encode({"items": cartItems}),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('✅ Đặt hàng thành công!'),
          backgroundColor: Colors.green,
        ));

        await Future.delayed(Duration(seconds: 2));

        if (mounted) {
          Navigator.pushReplacementNamed(context, '/order-history');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('❌ Đặt hàng thất bại: ${response.body}'),
          backgroundColor: Colors.red,
        ));
      }
    } catch (error) {
      print("🔥 Lỗi khi đặt hàng: $error");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('⚠️ Lỗi server, vui lòng thử lại sau!'),
        backgroundColor: Colors.red,
      ));
    }
  }

  Widget buildCartItem(product, quantity) {
    return ListTile(
      leading: Image.network(
        product['image'] ?? 'https://via.placeholder.com/100',
        width: 60,
        height: 60,
        fit: BoxFit.cover,
      ),
      title: Text(product['name']),
      subtitle: Text("Giá: ${product['price']} đ x $quantity"),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Thanh toán"),
        backgroundColor: Colors.orange,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : cartItems.isEmpty
              ? Center(child: Text("Giỏ hàng của bạn đang trống!"))
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final isTablet = constraints.maxWidth > 600;

                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Thông tin đơn hàng",
                            style: TextStyle(fontSize: isTablet ? 24 : 20, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 16),
                          Expanded(
                            child: ListView.builder(
                              itemCount: cartItems.length,
                              itemBuilder: (context, index) {
                                final product = cartItems[index]['product'];
                                final quantity = cartItems[index]['quantity'];
                                return buildCartItem(product, quantity);
                              },
                            ),
                          ),
                          Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Tổng cộng:",
                                  style: TextStyle(
                                    fontSize: isTablet ? 20 : 16,
                                    fontWeight: FontWeight.bold,
                                  )),
                              Text(
                                "${totalPrice.toStringAsFixed(2)} đ",
                                style: TextStyle(
                                  fontSize: isTablet ? 20 : 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                               key: Key('confirmCheckoutButton'), // key
                              onPressed: checkout,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: EdgeInsets.symmetric(vertical: isTablet ? 18 : 14),
                                textStyle: TextStyle(fontSize: isTablet ? 20 : 16),
                              ),
                              child: Text('Mua hàng'),
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
