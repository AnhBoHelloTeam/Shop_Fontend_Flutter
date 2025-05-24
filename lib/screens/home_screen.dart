import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:shop_frontend/screens/CategoriesScreen.dart';
import 'package:shop_frontend/screens/HotBuyProducts.dart';
import 'package:shop_frontend/screens/OrderHistory_screen.dart';
import 'package:shop_frontend/screens/user_sceen.dart';
import '../services/product_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> products = [];
  List<String> categories = [];
  int _currentIndex = 0;
  bool isLoading = true;
  final ProductService productService = ProductService();
  final TextEditingController _searchController = TextEditingController();
  String? authToken;
  String selectedCategory = '';
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadAuthToken();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is String && mounted) {
        setState(() {
          selectedCategory = args;
        });
        loadProducts();
      }
    });
    loadCategories();
    loadProducts();
  }

  Future<void> _loadAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken') ?? '';
    if (token.isEmpty && kDebugMode) {
      debugPrint('🔍 HomeScreen authToken is empty');
    }
    if (mounted) {
      setState(() {
        authToken = token;
      });
    }
  }

  Future<void> loadCategories() async {
    const maxRetries = 3;
    int attempt = 0;
    const timeoutSeconds = 5;
    final cacheKey = 'categories';

    // Load cached categories
    final prefs = await SharedPreferences.getInstance();
    final cachedCategories = prefs.getString(cacheKey);
    if (cachedCategories != null) {
      try {
        final categoryList = jsonDecode(cachedCategories) as List<dynamic>;
        if (mounted) {
          setState(() {
            categories = List<String>.from(categoryList)..insert(0, '');
          });
          if (kDebugMode) debugPrint('📡 Loaded ${categoryList.length} categories from cache');
        }
      } catch (e) {
        if (kDebugMode) debugPrint('🔥 Error decoding cached categories: $e');
      }
    }

    while (attempt < maxRetries) {
      final client = http.Client();
      try {
        final response = await client
            .get(Uri.parse("https://shop-backend-nodejs.onrender.com/api/products/categories"))
            .timeout(const Duration(seconds: timeoutSeconds));

        if (kDebugMode) {
          debugPrint('📡 Load categories response: ${response.statusCode}, attempt ${attempt + 1}');
        }

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final categoryList = List<String>.from(data);
          await prefs.setString(cacheKey, jsonEncode(categoryList));
          if (mounted) {
            setState(() {
              categories = List<String>.from(categoryList)..insert(0, '');
            });
          }
          client.close();
          return;
        } else {
          attempt++;
          if (attempt >= maxRetries) {
            if (mounted) {
              _showFlushbar('Không thể tải danh mục sản phẩm', Colors.red);
            }
          }
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('🔥 Error loading categories (attempt ${attempt + 1}): $e');
        }
        attempt++;
        if (attempt >= maxRetries) {
          if (mounted) {
            _showFlushbar('Lỗi kết nối khi tải danh mục', Colors.red);
          }
        }
      } finally {
        client.close();
      }
      await Future.delayed(const Duration(seconds: 2));
    }
  }

  Future<void> loadProducts() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final response = await productService.fetchProducts(
        category: selectedCategory.isEmpty ? null : selectedCategory,
        name: searchQuery.isEmpty ? null : searchQuery,
      );

      if (mounted) {
        setState(() {
          if (response['success'] == true) {
            products = response['data'] as List<dynamic>;
          } else {
            products = [];
            _showFlushbar(response['error'] ?? 'Lỗi khi tải sản phẩm', Colors.red);
          }
          isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('🔥 Error loading products: $e');
      }
      if (mounted) {
        setState(() => isLoading = false);
        _showFlushbar('Lỗi kết nối khi tải sản phẩm', Colors.red);
      }
    }
  }

  Future<void> addToCart(String productId) async {
    if (authToken == null || authToken!.isEmpty) {
      if (mounted) {
        _showFlushbar('Vui lòng đăng nhập để thêm vào giỏ hàng', Colors.red);
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/');
          }
        });
      }
      return;
    }

    const maxRetries = 3;
    int attempt = 0;
    const timeoutSeconds = 5;

    while (attempt < maxRetries) {
      final client = http.Client();
      try {
        final response = await client
            .post(
              Uri.parse("https://shop-backend-nodejs.onrender.com/api/cart/add"),
              headers: {
                "Content-Type": "application/json",
                "Authorization": "Bearer $authToken",
              },
              body: jsonEncode({"productId": productId, "quantity": 1}),
            )
            .timeout(const Duration(seconds: timeoutSeconds));

        if (kDebugMode) {
          debugPrint('📡 Add to cart response: ${response.statusCode}, attempt ${attempt + 1}');
        }

        if (response.statusCode == 200) {
          if (mounted) {
            _showFlushbar('Đã thêm sản phẩm vào giỏ hàng', Colors.green);
          }
          client.close();
          return;
        } else {
          attempt++;
          if (attempt >= maxRetries) {
            if (mounted) {
              _showFlushbar('Không thể thêm vào giỏ hàng', Colors.red);
            }
          }
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('🔥 Error adding to cart (attempt ${attempt + 1}): $e');
        }
        attempt++;
        if (attempt >= maxRetries) {
          if (mounted) {
            _showFlushbar('Lỗi kết nối khi thêm vào giỏ hàng', Colors.red);
          }
        }
      } finally {
        client.close();
      }
      await Future.delayed(const Duration(seconds: 2));
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

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        title: Text(
          "Đăng xuất",
          style: GoogleFonts.poppins(fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),
        content: Text(
          "Bạn có chắc chắn muốn đăng xuất không?",
          style: GoogleFonts.poppins(fontSize: 14.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Hủy",
              style: GoogleFonts.poppins(fontSize: 14.sp, color: Colors.blue),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('isLoggedIn');
              await prefs.remove('authToken');
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/');
              }
            },
            child: Text(
              "Đăng xuất",
              style: GoogleFonts.poppins(fontSize: 14.sp, color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        int columns = constraints.maxWidth < 600 ? 2 : constraints.maxWidth < 900 ? 3 : 4;
        return GridView.builder(
          padding: EdgeInsets.all(10.w),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 10.w,
            mainAxisSpacing: 10.h,
            childAspectRatio: 0.7,
          ),
          itemCount: 8,
          itemBuilder: (context, index) {
            return Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
                elevation: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 120.h,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(15.r)),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.w),
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
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8.r,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              key: const Key('searchTextField'),
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Tìm kiếm sản phẩm...",
                hintStyle: GoogleFonts.poppins(color: Colors.grey, fontSize: 14.sp),
                prefixIcon: const Icon(Icons.search, color: Colors.orange),
                suffixIcon: const Icon(Icons.mic, color: Colors.orange),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12.h),
              ),
              style: GoogleFonts.poppins(fontSize: 14.sp),
              onChanged: (value) {
                if (mounted) {
                  setState(() {
                    searchQuery = value;
                    loadProducts();
                  });
                }
              },
            ),
          ),
        ),
        actions: [
          ZoomIn(
            child: IconButton(
              key: const Key('cartIconButton'),
              icon: const Icon(Icons.shopping_cart, color: Colors.white),
              onPressed: () => Navigator.pushNamed(context, '/cart'),
            ),
          ),
          ZoomIn(
            child: IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: _showLogoutDialog,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: _currentIndex == 0
            ? RefreshIndicator(
                onRefresh: loadProducts,
                color: Colors.orange,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 16.h),
                      FadeInUp(
                        child: Container(
                          height: 40.h,
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: categories.length,
                            itemBuilder: (context, index) {
                              final category = categories[index];
                              final isSelected = selectedCategory == category;
                              return Padding(
                                padding: EdgeInsets.only(right: 8.w),
                                child: ZoomIn(
                                  delay: Duration(milliseconds: index * 100),
                                  child: GestureDetector(
                                    onTap: () {
                                      if (mounted) {
                                        setState(() {
                                          selectedCategory = category;
                                          loadProducts();
                                        });
                                      }
                                    },
                                    child: Chip(
                                      label: Text(
                                        category.isEmpty ? "Tất cả" : category,
                                        style: GoogleFonts.poppins(
                                          color: isSelected ? Colors.white : Colors.orange,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14.sp,
                                        ),
                                      ),
                                      backgroundColor: isSelected
                                          ? Colors.orange
                                          : Colors.grey[200],
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20.r),
                                      ),
                                      side: const BorderSide(color: Colors.orange),
                                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: 16.h),
                      const HotBuyProducts(),
                      SizedBox(height: 16.h),
                      isLoading
                          ? _buildSkeletonLoader()
                          : products.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16.w),
                                    child: Text(
                                      "Không tìm thấy sản phẩm",
                                      style: GoogleFonts.poppins(fontSize: 16.sp, color: Colors.grey),
                                    ),
                                  ),
                                )
                              : LayoutBuilder(
                                  builder: (context, constraints) {
                                    int columns = constraints.maxWidth < 600
                                        ? 2
                                        : constraints.maxWidth < 900
                                            ? 3
                                            : 4;
                                    return GridView.builder(
                                      padding: EdgeInsets.all(16.w),
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: columns,
                                        crossAxisSpacing: 10.w,
                                        mainAxisSpacing: 10.h,
                                        childAspectRatio: 0.7,
                                      ),
                                      itemCount: products.length,
                                      itemBuilder: (context, index) {
                                        final product = products[index];
                                        return FadeInUp(
                                          delay: Duration(milliseconds: index * 50),
                                          child: GestureDetector(
                                            onTap: () => Navigator.pushNamed(
                                              context,
                                              '/product_detail',
                                              arguments: product,
                                            ),
                                            child: Card(
                                              key: Key('productCard_$index'),
                                              elevation: 5,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(15.r),
                                              ),
                                              child: Stack(
                                                children: [
                                                  Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Expanded(
                                                        child: Container(
                                                          decoration: BoxDecoration(
                                                            borderRadius: BorderRadius.vertical(top: Radius.circular(15.r)),
                                                            image: DecorationImage(
                                                              image: product['image'] != null && product['image'].isNotEmpty
                                                                  ? NetworkImage(product['image'])
                                                                  : const AssetImage('assets/placeholder.png') as ImageProvider,
                                                              fit: BoxFit.cover,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      Padding(
                                                        padding: EdgeInsets.all(8.w),
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Text(
                                                              product['name'] ?? 'Không có tên',
                                                              maxLines: 2,
                                                              overflow: TextOverflow.ellipsis,
                                                              style: GoogleFonts.poppins(
                                                                fontWeight: FontWeight.bold,
                                                                fontSize: 14.sp,
                                                              ),
                                                            ),
                                                            SizedBox(height: 5.h),
                                                            Row(
                                                              children: [
                                                                Text(
                                                                  "${product['price']?.toStringAsFixed(0) ?? 'N/A'} đ",
                                                                  style: GoogleFonts.poppins(
                                                                    color: Colors.red,
                                                                    fontSize: 14.sp,
                                                                    fontWeight: FontWeight.w600,
                                                                  ),
                                                                ),
                                                                if (product['originalPrice'] != null &&
                                                                    product['originalPrice'] > product['price']) ...[
                                                                  SizedBox(width: 8.w),
                                                                  Text(
                                                                    "${product['originalPrice'].toStringAsFixed(0)} đ",
                                                                    style: GoogleFonts.poppins(
                                                                      color: Colors.grey,
                                                                      fontSize: 12.sp,
                                                                      decoration: TextDecoration.lineThrough,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ],
                                                            ),
                                                            SizedBox(height: 8.h),
                                                            Row(
                                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                              children: [
                                                                TextButton(
                                                                  key: Key('detailButton_$index'),
                                                                  onPressed: () => Navigator.pushNamed(
                                                                    context,
                                                                    '/product_detail',
                                                                    arguments: product,
                                                                  ),
                                                                  child: Text(
                                                                    "Chi tiết",
                                                                    style: GoogleFonts.poppins(
                                                                      color: Colors.blue,
                                                                      fontSize: 12.sp,
                                                                    ),
                                                                  ),
                                                                ),
                                                                ScaleTransitionButton(
                                                                  onPressed: () => addToCart(product['_id']),
                                                                  child: Container(
                                                                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                                                                    decoration: BoxDecoration(
                                                                      gradient: const LinearGradient(
                                                                        colors: [Colors.orange, Colors.amber],
                                                                      ),
                                                                      borderRadius: BorderRadius.circular(20.r),
                                                                    ),
                                                                    child: Text(
                                                                      "Thêm",
                                                                      style: GoogleFonts.poppins(
                                                                        color: Colors.white,
                                                                        fontSize: 12.sp,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  if (product['originalPrice'] != null &&
                                                      product['originalPrice'] > product['price'])
                                                    Positioned(
                                                      top: 8.h,
                                                      left: 8.w,
                                                      child: Container(
                                                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                                        decoration: BoxDecoration(
                                                          color: Colors.red,
                                                          borderRadius: BorderRadius.circular(12.r),
                                                        ),
                                                        child: Text(
                                                          "-${((1 - product['price'] / product['originalPrice']) * 100).toInt()}%",
                                                          style: GoogleFonts.poppins(
                                                            color: Colors.white,
                                                            fontSize: 10.sp,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                    ],
                  ),
                ),
              )
            : _currentIndex == 1
                ? const CategoriesScreen()
                : _currentIndex == 2
                    ? const OrderHistoryScreen()
                    : const AccountPage(),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.deepOrange, Colors.orange],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8.r,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.black54,
          backgroundColor: Colors.transparent,
          selectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12.sp),
          unselectedLabelStyle: GoogleFonts.poppins(fontSize: 12.sp),
          onTap: (index) {
            if (index == 3 || index == 1) {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      index == 3 ? const AccountPage() : const CategoriesScreen(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    const begin = Offset(1.0, 0.0);
                    const end = Offset.zero;
                    const curve = Curves.easeInOut;
                    var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                    return SlideTransition(
                      position: animation.drive(tween),
                      child: child,
                    );
                  },
                ),
              );
            } else if (mounted) {
              setState(() => _currentIndex = index);
            }
          },
          items: [
            BottomNavigationBarItem(
              icon: PulseIcon(
                isSelected: _currentIndex == 0,
                icon: Icons.home,
              ),
              label: "Trang chủ",
            ),
            BottomNavigationBarItem(
              icon: PulseIcon(
                isSelected: _currentIndex == 1,
                icon: Icons.category,
              ),
              label: "Danh mục",
            ),
            BottomNavigationBarItem(
              icon: PulseIcon(
                isSelected: _currentIndex == 2,
                icon: Icons.history,
              ),
              label: "Lịch sử",
            ),
            BottomNavigationBarItem(
              key: const Key('accountIconButton'),
              icon: PulseIcon(
                isSelected: _currentIndex == 3,
                icon: Icons.person,
              ),
              label: "Tài khoản",
            ),
          ],
        ),
      ),
    );
  }
}

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

class PulseIcon extends StatefulWidget {
  final bool isSelected;
  final IconData icon;

  const PulseIcon({required this.isSelected, required this.icon, super.key});

  @override
  _PulseIconState createState() => _PulseIconState();
}

class _PulseIconState extends State<PulseIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
    if (widget.isSelected) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(PulseIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      _controller.repeat(reverse: true);
    } else if (!widget.isSelected && oldWidget.isSelected) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: EdgeInsets.all(widget.isSelected ? 10.w : 8.w),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: widget.isSelected ? Colors.black.withOpacity(0.3) : Colors.transparent,
        boxShadow: widget.isSelected
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8.r,
                  spreadRadius: 2.r,
                ),
              ]
            : [],
      ),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Icon(
          widget.icon,
          size: widget.isSelected ? 28.sp : 24.sp,
        ),
      ),
    );
  }
}