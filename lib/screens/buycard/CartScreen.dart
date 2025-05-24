import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shop_frontend/screens/buycard/checkout_screen.dart';
import 'package:shop_frontend/screens/login_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<dynamic> cartItems = [];
  bool isLoading = true;
  bool isLoggedIn = false;
  int totalQuantity = 0;
  double totalPrice = 0.0;
  static const String apiUrl = "https://shop-backend-nodejs.onrender.com/api/cart/";

  @override
  void initState() {
    super.initState();
    fetchCartItems();
  }

  Future<void> fetchCartItems() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('authToken') ?? '';

      if (authToken.isEmpty) {
        if (!mounted) return;
        setState(() {
          isLoading = false;
          isLoggedIn = false;
        });
        return;
      }

      // Kiểm tra cache
      final cachedCart = prefs.getString('cart_data');
      if (cachedCart != null) {
        final data = jsonDecode(cachedCart);
        if (!mounted) return;
        setState(() {
          isLoggedIn = true;
          cartItems = data['items'] ?? [];
          totalQuantity = data['totalQuantity'] ?? 0;
          totalPrice = (data['totalPrice'] ?? 0).toDouble();
          isLoading = false;
        });
        if (kDebugMode) debugPrint('📡 Loaded cart from cache');
      }

      // Gọi API với retry
      const maxRetries = 3;
      int attempt = 0;
      while (attempt <= maxRetries) {
        try {
          final response = await http.get(
            Uri.parse(apiUrl),
            headers: {"Authorization": "Bearer $authToken"},
          ).timeout(const Duration(seconds: 5));

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            await prefs.setString('cart_data', response.body);
            if (!mounted) return;
            setState(() {
              isLoggedIn = true;
              cartItems = data['items'] ?? [];
              totalQuantity = data['totalQuantity'] ?? 0;
              totalPrice = (data['totalPrice'] ?? 0).toDouble();
              isLoading = false;
            });
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

      if (!mounted) return;
      setState(() {
        isLoading = false;
        isLoggedIn = true;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('🔥 Error: $e');
      if (!mounted) return;
      setState(() {
        isLoading = false;
        isLoggedIn = false;
      });
    }
  }

  Future<void> increaseItemQuantity(String productId) async {
    if (productId.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('authToken') ?? '';
      if (authToken.isEmpty) return;

      final response = await http.put(
        Uri.parse("$apiUrl/increase/$productId"),
        headers: {"Authorization": "Bearer $authToken"},
      );

      if (response.statusCode == 200) {
        await fetchCartItems();
      } else if (kDebugMode) {
        debugPrint('⚠️ Failed to increase quantity: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('🔥 Error increasing quantity: $e');
    }
  }

  Future<void> decreaseItemQuantity(String productId) async {
    if (productId.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('authToken') ?? '';
      if (authToken.isEmpty) return;

      final response = await http.put(
        Uri.parse("$apiUrl/decrease/$productId"),
        headers: {"Authorization": "Bearer $authToken"},
      );

      if (response.statusCode == 200) {
        await fetchCartItems();
      } else if (kDebugMode) {
        debugPrint('⚠️ Failed to decrease quantity: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('🔥 Error decreasing quantity: $e');
    }
  }

  Future<void> removeItemFromCart(String productId) async {
    if (productId.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('authToken') ?? '';
      if (authToken.isEmpty) return;

      final response = await http.delete(
        Uri.parse("$apiUrl/remove/$productId"),
        headers: {"Authorization": "Bearer $authToken"},
      );

      if (response.statusCode == 200) {
        await fetchCartItems();
      } else if (kDebugMode) {
        debugPrint('⚠️ Failed to remove item: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('🔥 Error removing item: $e');
    }
  }

  Widget _buildSkeletonLoader() {
    return ListView.builder(
      itemCount: 3,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: Row(
              children: [
                Container(
                  width: 50.w,
                  height: 50.h,
                  color: Colors.white,
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 16.h, width: 100.w, color: Colors.white),
                      SizedBox(height: 8.h),
                      Container(height: 14.h, width: 60.w, color: Colors.white),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
            "Giỏ hàng",
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
          : !isLoggedIn
              ? Center(
                  child: FadeInUp(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Vui lòng đăng nhập để sử dụng giỏ hàng!",
                          style: GoogleFonts.poppins(fontSize: 16.sp),
                        ),
                        SizedBox(height: 20.h),
                        ZoomIn(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) =>  LoginScreen()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 24.w),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                            ),
                            child: Text(
                              "Đăng nhập",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 16.sp,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : cartItems.isEmpty
                  ? Center(
                      child: FadeInUp(
                        child: Text(
                          "Giỏ hàng của bạn đang trống!",
                          style: GoogleFonts.poppins(fontSize: 16.sp),
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: fetchCartItems,
                            color: Colors.orange,
                            child: ListView.builder(
                              padding: EdgeInsets.symmetric(vertical: 8.h),
                              itemCount: cartItems.length,
                              itemBuilder: (context, index) {
                                final item = cartItems[index];
                                final product = item['product'];

                                return FadeInUp(
                                  delay: Duration(milliseconds: index * 100),
                                  child: product == null
                                      ? Card(
                                          elevation: 3,
                                          margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(15.r),
                                          ),
                                          child: ListTile(
                                            leading: const Icon(Icons.error, color: Colors.red),
                                            title: Text(
                                              "Sản phẩm không tồn tại",
                                              style: GoogleFonts.poppins(),
                                            ),
                                            subtitle: Text(
                                              "Dữ liệu sản phẩm bị thiếu.",
                                              style: GoogleFonts.poppins(),
                                            ),
                                            trailing: IconButton(
                                              icon: const Icon(Icons.delete, color: Colors.red),
                                              onPressed: () {
                                                final fallbackId = item['product']?['_id'] ?? '';
                                                if (fallbackId.isNotEmpty) {
                                                  removeItemFromCart(fallbackId);
                                                }
                                              },
                                            ),
                                          ),
                                        )
                                      : Card(
                                          elevation: 3,
                                          margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(15.r),
                                          ),
                                          child: ListTile(
                                            leading: ClipRRect(
                                              borderRadius: BorderRadius.circular(8.r),
                                              child: Image.network(
                                                product['image'] ?? 'https://via.placeholder.com/100',
                                                width: 50.w,
                                                height: 50.h,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) =>
                                                    const Icon(Icons.error),
                                              ),
                                            ),
                                            title: Text(
                                              product['name'] ?? 'Không có tên',
                                              style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14.sp,
                                              ),
                                            ),
                                            subtitle: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "Giá: ${product['price'] ?? 0} đ",
                                                  style: GoogleFonts.poppins(
                                                    color: Colors.red,
                                                    fontSize: 12.sp,
                                                  ),
                                                ),
                                                Text(
                                                  "Số lượng: ${item['quantity'] ?? 0}",
                                                  style: GoogleFonts.poppins(fontSize: 12.sp),
                                                ),
                                                Text(
                                                  "Tổng giá: ${item['totalItemPrice'] ?? 0} đ",
                                                  style: GoogleFonts.poppins(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12.sp,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            trailing: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                ScaleTransitionButton(
                                                  onPressed: () => decreaseItemQuantity(product['_id'] ?? ''),
                                                  child: Icon(Icons.remove_circle, color: Colors.red, size: 24.sp),
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                                                  child: Text(
                                                    "${item['quantity'] ?? 0}",
                                                    style: GoogleFonts.poppins(fontSize: 14.sp),
                                                  ),
                                                ),
                                                ScaleTransitionButton(
                                                  onPressed: () => increaseItemQuantity(product['_id'] ?? ''),
                                                  child: Icon(Icons.add_circle, color: Colors.green, size: 24.sp),
                                                ),
                                                ScaleTransitionButton(
                                                  onPressed: () => removeItemFromCart(product['_id'] ?? ''),
                                                  child: Icon(Icons.delete, color: Colors.red, size: 24.sp),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                );
                              },
                            ),
                          ),
                        ),
                        Divider(height: 1.h, thickness: 1),
                        FadeInUp(
                          child: Padding(
                            padding: EdgeInsets.all(16.w),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Tổng số lượng: $totalQuantity",
                                  style: GoogleFonts.poppins(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 10.h),
                                Text(
                                  "Tổng giá: ${totalPrice.toStringAsFixed(2)} đ",
                                  style: GoogleFonts.poppins(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                                SizedBox(height: 20.h),
                                ZoomIn(
                                  child: ElevatedButton(
                                    key: const Key('checkoutButton'),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        PageRouteBuilder(
                                          pageBuilder: (context, animation, secondaryAnimation) =>
                                               CheckoutPage(),
                                          transitionsBuilder:
                                              (context, animation, secondaryAnimation, child) {
                                            const begin = Offset(1.0, 0.0);
                                            const end = Offset.zero;
                                            const curve = Curves.easeInOut;
                                            var tween = Tween(begin: begin, end: end)
                                                .chain(CurveTween(curve: curve));
                                            return SlideTransition(
                                              position: animation.drive(tween),
                                              child: child,
                                            );
                                          },
                                        ),
                                      ).then((_) => fetchCartItems());
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      padding: EdgeInsets.symmetric(vertical: 15.h, horizontal: 50.w),
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
                                      padding: EdgeInsets.symmetric(vertical: 15.h, horizontal: 50.w),
                                      child: Text(
                                        "Mua hàng",
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 16.sp,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
    );
  }
}

// Widget tùy chỉnh để thêm hiệu ứng scale khi nhấn
class ScaleTransitionButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;

  const ScaleTransitionButton({required this.onPressed, required this.child, super.key});

  @override
  _ScaleTransitionButtonState createState() => _ScaleTransitionButtonState();
}

class _ScaleTransitionButtonState extends State<ScaleTransitionButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}