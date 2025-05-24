import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:another_flushbar/flushbar.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  _CheckoutPageState createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  List<dynamic> cartItems = [];
  List<dynamic> availableDiscounts = [];
  double totalPrice = 0.0;
  double membershipDiscount = 0.0;
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
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      await Future.wait([
        fetchCartItems(),
        fetchUserInfo(),
      ]);
      if (cartItems.isNotEmpty) {
        await fetchAvailableDiscounts();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('🔥 Error loading data: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> fetchCartItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('authToken') ?? '';
      if (authToken.isEmpty) return;

      // Kiểm tra cache
      final cachedCart = prefs.getString('cart_data');
      if (cachedCart != null) {
        final data = jsonDecode(cachedCart);
        if (mounted) {
          setState(() {
            cartItems = data['items'] ?? [];
            _calculateTotal();
          });
          if (kDebugMode) debugPrint('📡 Loaded cart from cache');
        }
      }

      // Gọi API với retry
      const maxRetries = 3;
      int attempt = 0;
      while (attempt <= maxRetries) {
        try {
          final response = await http.get(
            Uri.parse("https://shop-backend-nodejs.onrender.com/api/cart"),
            headers: {"Authorization": "Bearer $authToken"},
          ).timeout(const Duration(seconds: 5));

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            await prefs.setString('cart_data', response.body);
            if (mounted) {
              setState(() {
                cartItems = data['items'] ?? [];
                _calculateTotal();
              });
            }
            return;
          } else {
            if (kDebugMode) debugPrint('⚠️ Failed to fetch cart: ${response.statusCode}');
            break;
          }
        } catch (e) {
          attempt++;
          if (attempt > maxRetries) {
            if (kDebugMode) debugPrint('🔥 Error fetching cart after $maxRetries attempts: $e');
            break;
          }
          await Future.delayed(const Duration(seconds: 2));
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('🔥 Error fetching cart: $e');
    }
  }

  Future<void> fetchUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('authToken') ?? '';
      if (authToken.isEmpty) return;

      // Kiểm tra cache
      final cachedUser = prefs.getString('user_info');
      if (cachedUser != null) {
        if (mounted) {
          setState(() {
            userInfo = jsonDecode(cachedUser);
            _calculateTotal();
          });
          if (kDebugMode) debugPrint('📡 Loaded user info from cache');
        }
      }

      // Gọi API với retry
      const maxRetries = 3;
      int attempt = 0;
      while (attempt <= maxRetries) {
        try {
          final response = await http.get(
            Uri.parse("https://shop-backend-nodejs.onrender.com/api/users/me"),
            headers: {"Authorization": "Bearer $authToken"},
          ).timeout(const Duration(seconds: 5));

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            await prefs.setString('user_info', response.body);
            if (mounted) {
              setState(() {
                userInfo = data;
                _calculateTotal();
              });
            }
            return;
          } else {
            if (kDebugMode) debugPrint('⚠️ Failed to fetch user info: ${response.statusCode}');
            break;
          }
        } catch (e) {
          attempt++;
          if (attempt > maxRetries) {
            if (kDebugMode) debugPrint('🔥 Error fetching user info after $maxRetries attempts: $e');
            break;
          }
          await Future.delayed(const Duration(seconds: 2));
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('🔥 Error fetching user info: $e');
    }
  }

  Future<void> fetchAvailableDiscounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('authToken') ?? '';
      if (authToken.isEmpty) {
        if (mounted) {
          setState(() {
            discountError = 'Vui lòng đăng nhập để xem mã giảm giá';
          });
        }
        return;
      }

      final payload = {
        "cartItems": cartItems,
        "totalPrice": totalPrice,
        "currentDate": DateTime.now().toIso8601String(),
      };

      // Gọi API với retry
      const maxRetries = 3;
      int attempt = 0;
      while (attempt <= maxRetries) {
        try {
          final response = await http.post(
            Uri.parse("https://shop-backend-nodejs.onrender.com/api/discounts/available"),
            headers: {
              "Authorization": "Bearer $authToken",
              "Content-Type": "application/json",
            },
            body: json.encode(payload),
          ).timeout(const Duration(seconds: 5));

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            if (data is List) {
              if (mounted) {
                setState(() {
                  availableDiscounts = data;
                  discountError = '';
                });
              }
            } else {
              if (mounted) {
                setState(() {
                  discountError = 'Dữ liệu mã giảm giá không đúng định dạng';
                });
              }
            }
            return;
          } else if (response.statusCode == 404) {
            if (mounted) {
              setState(() {
                discountError = 'Chức năng mã giảm giá chưa được triển khai';
              });
            }
            return;
          } else {
            if (mounted) {
              setState(() {
                discountError = jsonDecode(response.body)['message'] ?? 'Không thể lấy danh sách mã giảm giá';
              });
            }
            return;
          }
        } catch (e) {
          attempt++;
          if (attempt > maxRetries) {
            if (kDebugMode) debugPrint('🔥 Error fetching discounts after $maxRetries attempts: $e');
            if (mounted) {
              setState(() {
                discountError = 'Không thể kết nối đến server';
              });
            }
            break;
          }
          await Future.delayed(const Duration(seconds: 2));
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('🔥 Error fetching discounts: $e');
      if (mounted) {
        setState(() {
          discountError = 'Không thể kết nối đến server';
        });
      }
    }
  }

  Future<void> applyDiscountCode(String code) async {
    if (code.trim().isEmpty) {
      if (mounted) {
        setState(() {
          discountError = 'Vui lòng nhập mã giảm giá';
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        discountError = '';
        discountAmount = 0.0;
        discountCode = code;
        _discountController.text = code;
      });
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('authToken') ?? '';
      if (authToken.isEmpty) {
        if (mounted) {
          setState(() {
            discountError = 'Vui lòng đăng nhập';
          });
        }
        return;
      }

      final payload = {
        "code": code,
        "cartItems": cartItems,
        "totalPrice": totalPrice,
      };

      // Gọi API với retry
      const maxRetries = 3;
      int attempt = 0;
      while (attempt <= maxRetries) {
        try {
          final response = await http.post(
            Uri.parse("https://shop-backend-nodejs.onrender.com/api/discounts/apply"),
            headers: {
              "Authorization": "Bearer $authToken",
              "Content-Type": "application/json",
            },
            body: json.encode(payload),
          ).timeout(const Duration(seconds: 5));

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            if (mounted) {
              setState(() {
                discountAmount = data['discountAmount']?.toDouble() ?? 0.0;
                _calculateTotal();
              });
            }
            return;
          } else {
            if (mounted) {
              setState(() {
                discountError = jsonDecode(response.body)['message'] ?? 'Mã giảm giá không hợp lệ';
              });
            }
            return;
          }
        } catch (e) {
          attempt++;
          if (attempt > maxRetries) {
            if (kDebugMode) debugPrint('🔥 Error applying discount after $maxRetries attempts: $e');
            if (mounted) {
              setState(() {
                discountError = 'Lỗi khi áp dụng mã giảm giá';
              });
            }
            break;
          }
          await Future.delayed(const Duration(seconds: 2));
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('🔥 Error applying discount: $e');
      if (mounted) {
        setState(() {
          discountError = 'Lỗi khi áp dụng mã giảm giá';
        });
      }
    }
  }

  void _calculateTotal() {
    final basePrice = cartItems.fold<double>(0.0, (sum, item) {
      return sum + (item['product']['price'] * item['quantity']);
    });

    // Tính ưu đãi thành viên
    membershipDiscount = 0.0;
    switch (userInfo['membershipTier']) {
      case 'Silver':
        membershipDiscount = basePrice * 0.05; // 5% cho Silver
        break;
      case 'Gold':
        membershipDiscount = basePrice * 0.10; // 10% cho Gold
        break;
      case 'Diamond':
        membershipDiscount = basePrice * 0.15; // 15% cho Diamond
        break;
    }

    // Tổng giá = giá gốc - mã giảm giá - ưu đãi thành viên
    totalPrice = basePrice - discountAmount - membershipDiscount;
    if (totalPrice < 0) totalPrice = 0;
  }

  Future<void> checkout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('authToken') ?? '';
      if (authToken.isEmpty) {
        _showFlushbar('Vui lòng đăng nhập', Colors.red);
        return;
      }

      final payload = {
        "items": cartItems,
        "discountCode": discountCode.isNotEmpty ? discountCode : null,
        "paymentMethod": selectedPaymentMethod,
        "shippingAddress": userInfo['address'] ?? '',
        "totalPrice": totalPrice,
      };

      // Gọi API với retry
      const maxRetries = 3;
      int attempt = 0;
      while (attempt <= maxRetries) {
        try {
          final response = await http.post(
            Uri.parse("https://shop-backend-nodejs.onrender.com/api/orders/checkout"),
            headers: {
              "Authorization": "Bearer $authToken",
              "Content-Type": "application/json",
            },
            body: json.encode(payload),
          ).timeout(const Duration(seconds: 5));

          if (response.statusCode == 201) {
            _showFlushbar('✅ Đặt hàng thành công!', Colors.green);
            await Future.delayed(const Duration(seconds: 2));
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/order-history');
            }
            return;
          } else {
            _showFlushbar(
              '❌ Đặt hàng thất bại: ${jsonDecode(response.body)['message']}',
              Colors.red,
            );
            return;
          }
        } catch (e) {
          attempt++;
          if (attempt > maxRetries) {
            if (kDebugMode) debugPrint('🔥 Error checking out after $maxRetries attempts: $e');
            _showFlushbar('⚠️ Lỗi server, vui lòng thử lại!', Colors.red);
            break;
          }
          await Future.delayed(const Duration(seconds: 2));
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('🔥 Error checking out: $e');
      _showFlushbar('⚠️ Lỗi server, vui lòng thử lại!', Colors.red);
    }
  }

  void _showFlushbar(String message, Color backgroundColor) {
    Flushbar(
      message: message,
      duration: const Duration(seconds: 3),
      backgroundGradient: LinearGradient(
        colors: [backgroundColor, backgroundColor.withOpacity(0.8)],
      ),
      borderRadius: BorderRadius.circular(10.r),
      margin: EdgeInsets.all(8.w),
      padding: EdgeInsets.all(16.w),
    ).show(context);
  }

  void showDiscountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Chọn mã giảm giá',
          style: GoogleFonts.poppins(fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),
        content: Container(
          width: double.maxFinite,
          constraints: BoxConstraints(maxHeight: 300.h),
          child: availableDiscounts.isEmpty
              ? Text(
                  'Không có mã giảm giá hợp lệ',
                  style: GoogleFonts.poppins(fontSize: 14.sp),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: availableDiscounts.length,
                  itemBuilder: (context, index) {
                    final discount = availableDiscounts[index];
                    return FadeInUp(
                      delay: Duration(milliseconds: index * 100),
                      child: ListTile(
                        title: Text(
                          '${discount['code']} (-${discount['percentage']}%)',
                          style: GoogleFonts.poppins(fontSize: 14.sp, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          'Đơn tối thiểu: ${discount['minOrderValue']} đ\nHiệu lực: ${DateTime.parse(discount['startDate']).toLocal().toString().substring(0, 10)} - ${DateTime.parse(discount['endDate']).toLocal().toString().substring(0, 10)}',
                          style: GoogleFonts.poppins(fontSize: 12.sp),
                        ),
                        onTap: () {
                          if (mounted) {
                            setState(() {
                              discountCode = discount['code'];
                              _discountController.text = discount['code'];
                            });
                          }
                          Navigator.pop(context);
                          applyDiscountCode(discount['code']);
                        },
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Đóng',
              style: GoogleFonts.poppins(fontSize: 14.sp, color: Colors.orange),
            ),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
        backgroundColor: Colors.white,
      ),
    );
  }

  Widget buildCartItem(Map<String, dynamic> product, int quantity) {
    return FadeInUp(
      child: Card(
        elevation: 3,
        margin: EdgeInsets.symmetric(vertical: 8.h),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
        child: ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: CachedNetworkImage(
              imageUrl: product['image'] ?? 'https://via.placeholder.com/100',
              width: 60.w,
              height: 60.w,
              fit: BoxFit.cover,
              placeholder: (context, url) => Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(color: Colors.white),
              ),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            ),
          ),
          title: Text(
            product['name'] ?? 'Không rõ',
            style: GoogleFonts.poppins(fontSize: 16.sp, fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            "Giá: ${product['price']} đ x $quantity",
            style: GoogleFonts.poppins(fontSize: 14.sp),
          ),
        ),
      ),
    );
  }

  Widget _buildMembershipBadge() {
    final tier = userInfo['membershipTier'] ?? 'Member';
    final tierStyles = {
      'Member': {'color': Colors.grey, 'icon': Icons.person},
      'Silver': {'color': Colors.blueGrey, 'icon': Icons.star_border},
      'Gold': {'color': Colors.amber, 'icon': Icons.star},
      'Diamond': {'color': Colors.blue, 'icon': Icons.diamond},
    };

    final style = tierStyles[tier]!;
    return FadeInUp(
      child: Row(
        children: [
          Icon(style['icon'] as IconData, color: style['color'] as Color, size: 20.sp),
          SizedBox(width: 8.w),
          Text(
            'Thứ hạng: $tier',
            style: GoogleFonts.poppins(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: style['color'] as Color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 200.w, height: 24.h, color: Colors.white),
            SizedBox(height: 12.h),
            Container(width: double.infinity, height: 150.h, color: Colors.white),
            SizedBox(height: 24.h),
            Container(width: 200.w, height: 24.h, color: Colors.white),
            SizedBox(height: 12.h),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 2,
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  child: Row(
                    children: [
                      Container(width: 60.w, height: 60.h, color: Colors.white),
                      SizedBox(width: 16.w),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(width: 100.w, height: 16.h, color: Colors.white),
                          SizedBox(height: 8.h),
                          Container(width: 80.w, height: 14.h, color: Colors.white),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orange, Colors.amber],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: FadeIn(
          child: Text(
            "Thanh toán",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 20.sp,
            ),
          ),
        ),
      ),
      body: isLoading
          ? _buildSkeletonLoader()
          : cartItems.isEmpty
              ? Center(
                  child: FadeInUp(
                    child: Text(
                      "Giỏ hàng của bạn đang trống!",
                      style: GoogleFonts.poppins(fontSize: 16.sp),
                    ),
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final isTablet = constraints.maxWidth > 600;
                    return RefreshIndicator(
                      onRefresh: _loadData,
                      color: Colors.orange,
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(16.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FadeInUp(
                              child: Text(
                                "Thông tin khách hàng",
                                style: GoogleFonts.poppins(
                                  fontSize: isTablet ? 24.sp : 20.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(height: 12.h),
                            FadeInUp(
                              delay: const Duration(milliseconds: 100),
                              child: Card(
                                elevation: 3,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
                                child: Padding(
                                  padding: EdgeInsets.all(12.w),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Tên: ${userInfo['name'] ?? 'Chưa cập nhật'}",
                                        style: GoogleFonts.poppins(fontSize: 16.sp),
                                      ),
                                      SizedBox(height: 8.h),
                                      Text(
                                        "Email: ${userInfo['email'] ?? 'Chưa cập nhật'}",
                                        style: GoogleFonts.poppins(fontSize: 16.sp),
                                      ),
                                      SizedBox(height: 8.h),
                                      Text(
                                        "Số điện thoại: ${userInfo['phone'] ?? 'Chưa cập nhật'}",
                                        style: GoogleFonts.poppins(fontSize: 16.sp),
                                      ),
                                      SizedBox(height: 8.h),
                                      Text(
                                        "Địa chỉ giao hàng: ${userInfo['address'] ?? 'Chưa cập nhật'}",
                                        style: GoogleFonts.poppins(fontSize: 16.sp),
                                      ),
                                      SizedBox(height: 8.h),
                                      _buildMembershipBadge(),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 24.h),
                            FadeInUp(
                              delay: const Duration(milliseconds: 200),
                              child: Text(
                                "Thông tin đơn hàng",
                                style: GoogleFonts.poppins(
                                  fontSize: isTablet ? 24.sp : 20.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(height: 16.h),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: cartItems.length,
                              itemBuilder: (context, index) {
                                final product = cartItems[index]['product'];
                                final quantity = cartItems[index]['quantity'];
                                return buildCartItem(product, quantity);
                              },
                            ),
                            Divider(height: 1.h),
                            SizedBox(height: 16.h),
                            FadeInUp(
                              delay: const Duration(milliseconds: 300),
                              child: Text(
                                "Mã giảm giá",
                                style: GoogleFonts.poppins(
                                  fontSize: isTablet ? 20.sp : 16.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(height: 8.h),
                            FadeInUp(
                              delay: const Duration(milliseconds: 400),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _discountController,
                                      readOnly: availableDiscounts.isNotEmpty,
                                      onTap: availableDiscounts.isNotEmpty ? showDiscountDialog : null,
                                      decoration: InputDecoration(
                                        labelText: "Chọn hoặc nhập mã giảm giá",
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10.r),
                                        ),
                                        suffixIcon: availableDiscounts.isNotEmpty
                                            ? Icon(Icons.arrow_drop_down, color: Colors.orange)
                                            : null,
                                        errorText: discountError.isNotEmpty ? discountError : null,
                                        labelStyle: GoogleFonts.poppins(fontSize: 14.sp),
                                      ),
                                      style: GoogleFonts.poppins(fontSize: 14.sp),
                                      onChanged: availableDiscounts.isEmpty
                                          ? (value) {
                                              if (mounted) {
                                                setState(() {
                                                  discountCode = value;
                                                });
                                              }
                                            }
                                          : null,
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  ZoomIn(
                                    child: ElevatedButton(
                                      onPressed: () => applyDiscountCode(discountCode),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10.r),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [Colors.blue, Colors.blueAccent],
                                          ),
                                          borderRadius: BorderRadius.all(Radius.circular(10)),
                                        ),
                                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                                        child: Text(
                                          "Áp dụng",
                                          style: GoogleFonts.poppins(
                                            fontSize: 14.sp,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 16.h),
                            FadeInUp(
                              delay: const Duration(milliseconds: 500),
                              child: Text(
                                "Phương thức thanh toán",
                                style: GoogleFonts.poppins(
                                  fontSize: isTablet ? 20.sp : 16.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(height: 8.h),
                            FadeInUp(
                              delay: const Duration(milliseconds: 600),
                              child: DropdownButtonFormField<String>(
                                value: selectedPaymentMethod,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.r),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                                  labelText: "Chọn phương thức",
                                  labelStyle: GoogleFonts.poppins(fontSize: 14.sp),
                                ),
                                items: [
                                  DropdownMenuItem(
                                    value: 'COD',
                                    child: Text(
                                      'Thanh toán khi nhận hàng',
                                      style: GoogleFonts.poppins(fontSize: 14.sp),
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'CARD',
                                    child: Text(
                                      'Thẻ tín dụng/Thẻ ghi nợ',
                                      style: GoogleFonts.poppins(fontSize: 14.sp),
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'WALLET',
                                    child: Text(
                                      'Ví điện tử',
                                      style: GoogleFonts.poppins(fontSize: 14.sp),
                                    ),
                                  ),
                                ],
                                onChanged: (value) {
                                  if (mounted) {
                                    setState(() {
                                      selectedPaymentMethod = value!;
                                    });
                                  }
                                },
                              ),
                            ),
                            SizedBox(height: 24.h),
                            FadeInUp(
                              delay: const Duration(milliseconds: 700),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Tổng cộng:",
                                    style: GoogleFonts.poppins(
                                      fontSize: isTablet ? 20.sp : 16.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    "${totalPrice.toStringAsFixed(2)} đ",
                                    style: GoogleFonts.poppins(
                                      fontSize: isTablet ? 20.sp : 16.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (discountAmount > 0)
                              FadeInUp(
                                delay: const Duration(milliseconds: 800),
                                child: Padding(
                                  padding: EdgeInsets.only(top: 8.h),
                                  child: Text(
                                    "Đã giảm (mã): ${discountAmount.toStringAsFixed(2)} đ (Mã: $discountCode)",
                                    style: GoogleFonts.poppins(
                                      color: Colors.green,
                                      fontSize: isTablet ? 18.sp : 16.sp,
                                    ),
                                  ),
                                ),
                              ),
                            if (membershipDiscount > 0)
                              FadeInUp(
                                delay: const Duration(milliseconds: 900),
                                child: Padding(
                                  padding: EdgeInsets.only(top: 8.h),
                                  child: Row(
                                    children: [
                                      Icon(
                                        {
                                          'Silver': Icons.star_border,
                                          'Gold': Icons.star,
                                          'Diamond': Icons.diamond,
                                        }[userInfo['membershipTier']] ?? Icons.person,
                                        color: {
                                          'Silver': Colors.blueGrey,
                                          'Gold': Colors.amber,
                                          'Diamond': Colors.blue,
                                        }[userInfo['membershipTier']] ?? Colors.grey,
                                        size: 18.sp,
                                      ),
                                      SizedBox(width: 8.w),
                                      Text(
                                        "Ưu đãi thành viên (${userInfo['membershipTier']}): ${membershipDiscount.toStringAsFixed(2)} đ",
                                        style: GoogleFonts.poppins(
                                          color: Colors.green,
                                          fontSize: isTablet ? 18.sp : 16.sp,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            SizedBox(height: 20.h),
                            FadeInUp(
                              delay: const Duration(milliseconds: 1000),
                              child: SizedBox(
                                width: double.infinity,
                                child: ZoomIn(
                                  child: ElevatedButton(
                                    key: const Key('confirmCheckoutButton'),
                                    onPressed: checkout,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      padding: EdgeInsets.symmetric(vertical: isTablet ? 18.h : 14.h),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20.r),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [Colors.green, Colors.greenAccent],
                                        ),
                                        borderRadius: BorderRadius.all(Radius.circular(20)),
                                      ),
                                      padding: EdgeInsets.symmetric(vertical: isTablet ? 18.h : 14.h),
                                      child: Text(
                                        'Xác nhận đặt hàng',
                                        style: GoogleFonts.poppins(
                                          fontSize: isTablet ? 20.sp : 16.sp,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
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