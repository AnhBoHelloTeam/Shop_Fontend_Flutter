import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shop_frontend/services/token_utils.dart';

class CheckoutPage extends StatefulWidget {
  @override
  _CheckoutPageState createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  List<dynamic> cartItems = [];
  List<dynamic> availableDiscounts = [];
  double totalPrice = 0.0;
  bool isLoading = true;
  String discountCode = '';
  double discountAmount = 0.0;
  String discountError = '';
  Map<String, dynamic> userInfo = {};
  String selectedPaymentMethod = 'COD';

  final TextEditingController _discountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await fetchCartItems();
    await fetchUserInfo();
    if (cartItems.isNotEmpty) {
      await fetchAvailableDiscounts();
    }
    setState(() => isLoading = false);
  }

  Future<void> fetchCartItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('authToken') ?? '';

      if (authToken.isEmpty) {
        setState(() => isLoading = false);
        return;
      }

      final url = "https://shop-backend-nodejs.onrender.com/api/cart";
      final response = await http.get(
        Uri.parse(url),
        headers: {"Authorization": "Bearer $authToken"},
      );

      print("📡 Response giỏ hàng: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          cartItems = data['items'] ?? [];
          totalPrice = cartItems.fold(0.0, (sum, item) {
            return sum + (item['product']['price'] * item['quantity']);
          });
        });
      } else {
        print("❌ Lỗi khi lấy giỏ hàng: ${response.body}");
      }
    } catch (error) {
      print("🔥 Lỗi khi lấy giỏ hàng: $error");
    }
  }

  Future<void> fetchUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('authToken') ?? '';

      if (authToken.isEmpty) return;

      final userId = TokenUtils.getUserIdFromToken(authToken);
      if (userId == null) return;

      final response = await http.get(
        Uri.parse("https://shop-backend-nodejs.onrender.com/api/users/$userId"),
        headers: {"Authorization": "Bearer $authToken"},
      );

      print("📡 Response thông tin người dùng: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 200) {
        setState(() {
          userInfo = json.decode(response.body);
        });
      } else {
        print("❌ Lỗi khi lấy thông tin người dùng: ${response.body}");
      }
    } catch (error) {
      print("🔥 Lỗi khi lấy thông tin người dùng: $error");
    }
  }

  Future<void> fetchAvailableDiscounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('authToken') ?? '';

      print("🔑 authToken: $authToken");
      if (authToken.isEmpty) {
        setState(() {
          discountError = 'Vui lòng đăng nhập để xem mã giảm giá';
        });
        return;
      }

      final payload = {
        "cartItems": cartItems,
        "totalPrice": totalPrice,
        "currentDate": DateTime.now().toIso8601String(),
      };
      print("📤 Payload mã giảm giá: ${json.encode(payload)}");

      final response = await http.post(
        Uri.parse("https://shop-backend-nodejs.onrender.com/api/discounts/available"),
        headers: {
          "Authorization": "Bearer $authToken",
          "Content-Type": "application/json",
        },
        body: json.encode(payload),
      ).timeout(Duration(seconds: 30));

      print("📡 Response lấy mã giảm giá: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          setState(() {
            availableDiscounts = data;
            discountError = '';
          });
        } else {
          setState(() {
            discountError = 'Dữ liệu mã giảm giá không đúng định dạng';
          });
        }
      } else if (response.statusCode == 404) {
        setState(() {
          discountError = 'Chức năng mã giảm giá chưa được triển khai';
        });
      } else {
        setState(() {
          discountError = json.decode(response.body)['message'] ?? 'Không thể lấy danh sách mã giảm giá';
        });
      }
    } catch (error) {
      print("🔥 Lỗi khi lấy mã giảm giá: $error");
      setState(() {
        discountError = 'Không thể kết nối đến server. Vui lòng thử lại sau.';
      });
    }
  }

  Future<void> applyDiscountCode(String code) async {
    if (code.trim().isEmpty) {
      setState(() {
        discountError = 'Vui lòng nhập mã giảm giá';
      });
      return;
    }

    setState(() {
      discountError = '';
      discountAmount = 0.0;
      discountCode = code;
      _discountController.text = code;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('authToken') ?? '';

      if (authToken.isEmpty) {
        setState(() {
          discountError = 'Vui lòng đăng nhập';
        });
        return;
      }

      final payload = {
        "code": code,
        "cartItems": cartItems,
        "totalPrice": totalPrice,
      };
      print("📤 Payload áp dụng mã: ${json.encode(payload)}");

      final response = await http.post(
        Uri.parse("https://shop-backend-nodejs.onrender.com/api/discounts/apply"),
        headers: {
          "Authorization": "Bearer $authToken",
          "Content-Type": "application/json",
        },
        body: json.encode(payload),
      ).timeout(Duration(seconds: 30));

      print("📡 Response áp dụng mã giảm giá: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          discountAmount = data['discountAmount']?.toDouble() ?? 0.0;
          totalPrice = data['newTotalPrice']?.toDouble() ?? totalPrice;
        });
      } else {
        setState(() {
          discountError = json.decode(response.body)['message'] ?? 'Mã giảm giá không hợp lệ';
        });
      }
    } catch (error) {
      print("🔥 Lỗi khi áp dụng mã giảm giá: $error");
      setState(() {
        discountError = 'Lỗi khi áp dụng mã giảm giá';
      });
    }
  }

  Future<void> checkout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('authToken') ?? '';

      if (authToken.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Vui lòng đăng nhập'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final payload = {
        "items": cartItems,
        "discountCode": discountCode.isNotEmpty ? discountCode : null,
        "paymentMethod": selectedPaymentMethod,
        "shippingAddress": userInfo['address'] ?? '',
      };
      print("📤 Payload checkout: ${json.encode(payload)}");

      final response = await http.post(
        Uri.parse("https://shop-backend-nodejs.onrender.com/api/orders/checkout"),
        headers: {
          "Authorization": "Bearer $authToken",
          "Content-Type": "application/json",
        },
        body: json.encode(payload),
      );

      print("📡 Response checkout: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Đặt hàng thành công!'),
            backgroundColor: Colors.green,
          ),
        );

        await Future.delayed(Duration(seconds: 2));
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/order-history');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Đặt hàng thất bại: ${json.decode(response.body)['message']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (error) {
      print("🔥 Lỗi khi đặt hàng: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ Lỗi server, vui lòng thử lại sau!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void showDiscountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Chọn mã giảm giá', style: TextStyle(fontSize: 18.sp)),
        content: Container(
          width: double.maxFinite,
          constraints: BoxConstraints(maxHeight: 300.h),
          child: availableDiscounts.isEmpty
              ? Text('Không có mã giảm giá hợp lệ', style: TextStyle(fontSize: 14.sp))
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: availableDiscounts.length,
                  itemBuilder: (context, index) {
                    final discount = availableDiscounts[index];
                    return ListTile(
                      title: Text(
                        '${discount['code']} (-${discount['percentage']}%)',
                        style: TextStyle(fontSize: 14.sp),
                      ),
                      subtitle: Text(
                        'Đơn tối thiểu: ${discount['minOrderValue']} đ\nHiệu lực: ${DateTime.parse(discount['startDate']).toLocal().toString().substring(0, 10)} - ${DateTime.parse(discount['endDate']).toLocal().toString().substring(0, 10)}',
                        style: TextStyle(fontSize: 12.sp),
                      ),
                      onTap: () {
                        setState(() {
                          discountCode = discount['code'];
                          _discountController.text = discount['code'];
                        });
                        Navigator.pop(context);
                        applyDiscountCode(discount['code']);
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Đóng', style: TextStyle(fontSize: 14.sp)),
          ),
        ],
      ),
    );
  }

  Widget buildCartItem(product, quantity) {
    return ListTile(
      leading: Image.network(
        product['image'] ?? 'https://via.placeholder.com/100',
        width: 60.w,
        height: 60.w,
        fit: BoxFit.cover,
      ),
      title: Text(product['name'] ?? 'Không rõ', style: TextStyle(fontSize: 16.sp)),
      subtitle: Text("Giá: ${product['price']} đ x $quantity", style: TextStyle(fontSize: 14.sp)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Thanh toán", style: TextStyle(fontSize: 20.sp)),
        backgroundColor: Colors.orange,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : cartItems.isEmpty
              ? Center(child: Text("Giỏ hàng của bạn đang trống!", style: TextStyle(fontSize: 16.sp)))
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final isTablet = constraints.maxWidth > 600;
                    return SingleChildScrollView(
                      padding: EdgeInsets.all(16.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Thông tin khách hàng",
                            style: TextStyle(
                              fontSize: isTablet ? 24.sp : 20.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                            child: Padding(
                              padding: EdgeInsets.all(12.w),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Tên: ${userInfo['name'] ?? 'Chưa cập nhật'}",
                                    style: TextStyle(fontSize: 16.sp),
                                  ),
                                  SizedBox(height: 8.h),
                                  Text(
                                    "Email: ${userInfo['email'] ?? 'Chưa cập nhật'}",
                                    style: TextStyle(fontSize: 16.sp),
                                  ),
                                  SizedBox(height: 8.h),
                                  Text(
                                    "Số điện thoại: ${userInfo['phone'] ?? 'Chưa cập nhật'}",
                                    style: TextStyle(fontSize: 16.sp),
                                  ),
                                  SizedBox(height: 8.h),
                                  Text(
                                    "Địa chỉ giao hàng: ${userInfo['address'] ?? 'Chưa cập nhật'}",
                                    style: TextStyle(fontSize: 16.sp),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 24.h),
                          Text(
                            "Thông tin đơn hàng",
                            style: TextStyle(
                              fontSize: isTablet ? 24.sp : 20.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 16.h),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: cartItems.length,
                            itemBuilder: (context, index) {
                              final product = cartItems[index]['product'];
                              final quantity = cartItems[index]['quantity'];
                              return buildCartItem(product, quantity);
                            },
                          ),
                          Divider(),
                          SizedBox(height: 16.h),
                          Text(
                            "Mã giảm giá",
                            style: TextStyle(
                              fontSize: isTablet ? 20.sp : 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _discountController,
                                  readOnly: availableDiscounts.isNotEmpty,
                                  onTap: availableDiscounts.isNotEmpty ? showDiscountDialog : null,
                                  decoration: InputDecoration(
                                    labelText: "Chọn hoặc nhập mã giảm giá",
                                    border: OutlineInputBorder(),
                                    suffixIcon: availableDiscounts.isNotEmpty ? Icon(Icons.arrow_drop_down) : null,
                                    errorText: discountError.isNotEmpty ? discountError : null,
                                  ),
                                  style: TextStyle(fontSize: 14.sp),
                                  onChanged: availableDiscounts.isEmpty
                                      ? (value) {
                                          setState(() {
                                            discountCode = value;
                                          });
                                        }
                                      : null,
                                ),
                              ),
                              SizedBox(width: 8.w),
                              ElevatedButton(
                                onPressed: () => applyDiscountCode(discountCode),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                                ),
                                child: Text("Áp dụng", style: TextStyle(fontSize: 14.sp)),
                              ),
                            ],
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            "Phương thức thanh toán",
                            style: TextStyle(
                              fontSize: isTablet ? 20.sp : 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          DropdownButtonFormField<String>(
                            value: selectedPaymentMethod,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                            ),
                            items: [
                              DropdownMenuItem(
                                value: 'COD',
                                child: Text('Thanh toán khi nhận hàng', style: TextStyle(fontSize: 14.sp)),
                              ),
                              DropdownMenuItem(
                                value: 'CARD',
                                child: Text('Thẻ tín dụng/Thẻ ghi nợ', style: TextStyle(fontSize: 14.sp)),
                              ),
                              DropdownMenuItem(
                                value: 'WALLET',
                                child: Text('Ví điện tử', style: TextStyle(fontSize: 14.sp)),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                selectedPaymentMethod = value!;
                              });
                            },
                          ),
                          SizedBox(height: 24.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Tổng cộng:",
                                style: TextStyle(
                                  fontSize: isTablet ? 20.sp : 16.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "${totalPrice.toStringAsFixed(2)} đ",
                                style: TextStyle(
                                  fontSize: isTablet ? 20.sp : 16.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                          if (discountAmount > 0)
                            Padding(
                              padding: EdgeInsets.only(top: 8.h),
                              child: Text(
                                "Đã giảm: ${discountAmount.toStringAsFixed(2)} đ (Mã: $discountCode)",
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: isTablet ? 18.sp : 16.sp,
                                ),
                              ),
                            ),
                          SizedBox(height: 20.h),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              key: Key('confirmCheckoutButton'),
                              onPressed: checkout,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: EdgeInsets.symmetric(vertical: isTablet ? 18.h : 14.h),
                                textStyle: TextStyle(fontSize: isTablet ? 20.sp : 16.sp),
                              ),
                              child: Text('Xác nhận đặt hàng'),
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