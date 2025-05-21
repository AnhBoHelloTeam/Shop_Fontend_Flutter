import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class OrderHistoryScreen extends StatefulWidget {
  @override
  _OrderHistoryScreenState createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  List<dynamic> orders = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    checkLoginAndFetchHistory();
  }

  Future<void> checkLoginAndFetchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('authToken') ?? '';

    if (authToken.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text("Cần đăng nhập"),
            content: Text("Vui lòng đăng nhập để xem lịch sử đơn hàng."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pushReplacementNamed(context, '/');
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

      print("📡 Response lịch sử đơn hàng: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          setState(() {
            orders = data;
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = 'Dữ liệu đơn hàng không đúng định dạng';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = json.decode(response.body)['message'] ?? 'Không thể lấy lịch sử đơn hàng';
          isLoading = false;
        });
      }
    } catch (error) {
      print("🔥 Lỗi khi lấy lịch sử đơn hàng: $error");
      setState(() {
        errorMessage = 'Lỗi kết nối đến server';
        isLoading = false;
      });
    }
  }

  Future<void> confirmDelivery(String orderId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('authToken') ?? '';

      final response = await http.put(
        Uri.parse("https://shop-backend-nodejs.onrender.com/api/orders/deliver/$orderId"),
        headers: {"Authorization": "Bearer $authToken"},
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Xác nhận nhận hàng thành công'), backgroundColor: Colors.green),
        );
        fetchOrderHistory(authToken);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(json.decode(response.body)['message'] ?? 'Không thể xác nhận nhận hàng'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚠️ Lỗi server: $error'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> requestReturn(String orderId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('authToken') ?? '';

      final response = await http.put(
        Uri.parse("https://shop-backend-nodejs.onrender.com/api/orders/return/$orderId"),
        headers: {"Authorization": "Bearer $authToken"},
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Yêu cầu trả hàng thành công'), backgroundColor: Colors.green),
        );
        fetchOrderHistory(authToken);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(json.decode(response.body)['message'] ?? 'Không thể yêu cầu trả hàng'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚠️ Lỗi server: $error'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> submitReview(String productId, int rating, String comment) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('authToken') ?? '';

      final response = await http.post(
        Uri.parse("https://shop-backend-nodejs.onrender.com/api/orders/review"),
        headers: {
          "Authorization": "Bearer $authToken",
          "Content-Type": "application/json",
        },
        body: json.encode({
          "productId": productId,
          "rating": rating,
          "comment": comment,
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Đánh giá thành công'), backgroundColor: Colors.green),
        );
        fetchOrderHistory(authToken);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(json.decode(response.body)['message'] ?? 'Không thể gửi đánh giá'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚠️ Lỗi server: $error'), backgroundColor: Colors.red),
      );
    }
  }

  void showReviewDialog(String productId, String productName) {
    int rating = 1;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Đánh giá sản phẩm: $productName', style: TextStyle(fontSize: 16.sp)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButton<int>(
              value: rating,
              items: List.generate(5, (index) => DropdownMenuItem(
                value: index + 1,
                child: Text('${index + 1} sao', style: TextStyle(fontSize: 14.sp)),
              )),
              onChanged: (value) {
                setState(() {
                  rating = value!;
                });
              },
            ),
            TextField(
              controller: commentController,
              decoration: InputDecoration(labelText: 'Nhận xét'),
              style: TextStyle(fontSize: 14.sp),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy', style: TextStyle(fontSize: 14.sp)),
          ),
          ElevatedButton(
            onPressed: () {
              submitReview(productId, rating, commentController.text);
              Navigator.pop(context);
            },
            child: Text('Gửi', style: TextStyle(fontSize: 14.sp)),
          ),
        ],
      ),
    );
  }

  String getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Chờ xác nhận';
      case 'confirmed':
        return 'Đã xác nhận';
      case 'shipped':
        return 'Đang giao';
      case 'delivered':
        return 'Đã giao';
      case 'returned':
        return 'Đã trả hàng';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return 'Không xác định';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lịch sử đơn hàng', style: TextStyle(fontSize: 20.sp)),
        backgroundColor: Colors.orange,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage, style: TextStyle(fontSize: 16.sp)))
              : orders.isEmpty
                  ? Center(child: Text('Chưa có đơn hàng nào', style: TextStyle(fontSize: 16.sp)))
                  : ListView.builder(
                      padding: EdgeInsets.all(16.w),
                      itemCount: orders.length,
                      itemBuilder: (context, index) {
                        final order = orders[index];
                        final createdAt = DateTime.parse(order['createdAt'] ?? DateTime.now().toIso8601String()).toLocal();
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 8.h),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                          elevation: 3,
                          child: Padding(
                            padding: EdgeInsets.all(12.w),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Đơn hàng #${order['_id']?.substring(0, 8) ?? 'N/A'}',
                                  style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  'Ngày đặt: ${createdAt.day}/${createdAt.month}/${createdAt.year} ${createdAt.hour}:${createdAt.minute}',
                                  style: TextStyle(fontSize: 14.sp),
                                ),
                                Text(
                                  'Trạng thái: ${getStatusText(order['status'] ?? 'unknown')}',
                                  style: TextStyle(fontSize: 14.sp),
                                ),
                                Text(
                                  'Tổng giá: ${(order['totalPrice']?.toDouble() ?? 0.0).toStringAsFixed(2)} đ',
                                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
                                ),
                                if (order['discount'] != null && order['discount']['amount'] > 0)
                                  Text(
                                    'Giảm giá: ${(order['discount']['amount']?.toDouble() ?? 0.0).toStringAsFixed(2)} đ (Mã: ${order['discount']['code'] ?? 'N/A'})',
                                    style: TextStyle(color: Colors.green, fontSize: 14.sp),
                                  ),
                                SizedBox(height: 10.h),
                                Text('Sản phẩm:', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
                                if (order['items'] is List) ...[
                                  ...order['items'].asMap().entries.map<Widget>((entry) {
                                    final item = entry.value;
                                    final product = item['product'] is Map ? item['product'] : {};
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
                                      title: Text(product['name'] ?? 'Không rõ', style: TextStyle(fontSize: 14.sp)),
                                      subtitle: Text('Số lượng: ${item['quantity'] ?? 0}', style: TextStyle(fontSize: 13.sp)),
                                      trailing: order['status'] == 'delivered'
                                          ? IconButton(
                                              icon: Icon(Icons.rate_review, size: 20.sp),
                                              onPressed: () => showReviewDialog(product['_id'] ?? '', product['name'] ?? ''),
                                            )
                                          : null,
                                    );
                                  }).toList(),
                                ] else
                                  Text('Không có sản phẩm', style: TextStyle(fontSize: 14.sp)),
                                if (order['status'] == 'shipped')
                                  Padding(
                                    padding: EdgeInsets.only(top: 8.h),
                                    child: ElevatedButton(
                                      onPressed: () => confirmDelivery(order['_id'] ?? ''),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        padding: EdgeInsets.symmetric(vertical: 10.h),
                                      ),
                                      child: Text('Xác nhận nhận hàng', style: TextStyle(fontSize: 14.sp)),
                                    ),
                                  ),
                                if (order['status'] == 'delivered')
                                  Padding(
                                    padding: EdgeInsets.only(top: 8.h),
                                    child: ElevatedButton(
                                      onPressed: () => requestReturn(order['_id'] ?? ''),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        padding: EdgeInsets.symmetric(vertical: 10.h),
                                      ),
                                      child: Text('Yêu cầu trả hàng', style: TextStyle(fontSize: 14.sp)),
                                    ),
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