import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class OrderHistoryPage extends StatefulWidget {
  @override
  _OrderHistoryPageState createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  List<dynamic> orders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    checkLoginAndFetchHistory();
  }

  Future<void> checkLoginAndFetchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('authToken') ?? '';

    if (authToken.isEmpty) {
      // Nếu chưa đăng nhập, hiển thị AlertDialog và chuyển sang màn hình đăng nhập
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text("Cần đăng nhập"),
            content: Text("Vui lòng đăng nhập để xem lịch sử đơn hàng."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // đóng dialog
                  Navigator.pushReplacementNamed(context, '/'); // chuyển sang trang login
                },
                child: Text("Đăng nhập", style: TextStyle(color: Colors.blue)),
              ),
            ],
          ),
        );
      });
      return;
    }

    fetchOrderHistory(authToken);
  }

  Future<void> fetchOrderHistory(String authToken) async {
    try {
      final url = "https://shop-backend-nodejs.onrender.com/api/orders/history";
      final response = await http.get(
        Uri.parse(url),
        headers: {"Authorization": "Bearer $authToken"},
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);

        for (var order in data) {
          for (var item in order['items']) {
            final productId = item['product'];
            final productDetails = await fetchProductDetails(productId);
            item['product'] = productDetails;
          }
        }

        setState(() {
          orders = data;
          isLoading = false;
        });
      } else {
        print("❌ Lỗi khi lấy lịch sử đơn hàng: ${response.body}");
      }
    } catch (error) {
      print("🔥 Lỗi khi lấy lịch sử đơn hàng: $error");
    }
  }

  Future<Map<String, dynamic>> fetchProductDetails(String productId) async {
    try {
      final url = "https://shop-backend-nodejs.onrender.com/api/products/$productId";
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {
          "name": "Không có thông tin",
          "image": "https://via.placeholder.com/50"
        };
      }
    } catch (error) {
      return {
        "name": "Không có thông tin",
        "image": "https://via.placeholder.com/50"
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lịch sử đơn hàng", style: TextStyle(fontSize: 18.sp)),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 12.w),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                final createdAt = order['createdAt'];
                final totalPrice = order['totalPrice'];
                final status = order['status'];
                final items = order['items'] as List<dynamic>;

                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  elevation: 3,
                  child: Padding(
                    padding: EdgeInsets.all(12.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("📅 Ngày đặt: $createdAt",
                            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
                        SizedBox(height: 4.h),
                        Text("💰 Tổng tiền: $totalPrice đ", style: TextStyle(fontSize: 14.sp)),
                        Text("📦 Trạng thái: ${status.toUpperCase()}",
                            style: TextStyle(fontSize: 14.sp)),
                        SizedBox(height: 10.h),
                        Column(
                          children: items.map((item) {
                            final product = item['product'];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8.r),
                                child: Image.network(
                                  product['image'] ?? 'https://via.placeholder.com/50',
                                  width: 50.w,
                                  height: 50.w,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              title: Text(product['name'] ?? "Không rõ",
                                  style: TextStyle(fontSize: 14.sp)),
                              subtitle: Text("Số lượng: ${item['quantity']}",
                                  style: TextStyle(fontSize: 13.sp)),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
