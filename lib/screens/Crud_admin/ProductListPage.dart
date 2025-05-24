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
import 'package:shop_frontend/screens/Crud_admin/EditProductPage.dart';

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  @override
  _ProductListPageState createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  List<dynamic> products = [];
  bool _isLoading = true;
  String _errorMessage = "";

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      // Kiểm tra cache
      final cachedProducts = prefs.getString('products_list');
      if (cachedProducts != null) {
        if (mounted) {
          setState(() {
            products = jsonDecode(cachedProducts);
            _isLoading = false;
          });
          if (kDebugMode) debugPrint('📡 Loaded products from cache');
        }
      }

      // Gọi API với retry
      const maxRetries = 3;
      int attempt = 0;
      while (attempt <= maxRetries) {
        try {
          final response = await http.get(
            Uri.parse('https://shop-backend-nodejs.onrender.com/api/products'),
          ).timeout(const Duration(seconds: 5));

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            await prefs.setString('products_list', response.body);
            if (mounted) {
              setState(() {
                products = data;
                _isLoading = false;
                _errorMessage = "";
              });
            }
            return;
          } else {
            if (kDebugMode) debugPrint('⚠️ Failed to fetch products: ${response.statusCode}');
            if (mounted) {
              setState(() {
                _errorMessage = "Không thể tải danh sách sản phẩm.";
                _isLoading = false;
              });
            }
            return;
          }
        } catch (e) {
          attempt++;
          if (attempt > maxRetries) {
            if (kDebugMode) debugPrint('🔥 Error fetching products after $maxRetries attempts: $e');
            if (mounted) {
              setState(() {
                _errorMessage = "Lỗi kết nối tới server.";
                _isLoading = false;
              });
            }
            break;
          }
          await Future.delayed(const Duration(seconds: 2));
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('🔥 Error fetching products: $e');
      if (mounted) {
        setState(() {
          _errorMessage = "Lỗi kết nối tới server.";
          _isLoading = false;
        });
      }
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

  Widget _buildSkeletonLoader() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 5,
          itemBuilder: (context, index) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                child: ListTile(
                  leading: Container(width: 60.w, height: 60.h, color: Colors.white),
                  title: Container(width: 100.w, height: 16.h, color: Colors.white),
                  subtitle: Container(width: 80.w, height: 14.h, color: Colors.white),
                ),
              ),
            );
          },
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
            "📦 Danh sách sản phẩm",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 20.sp,
            ),
          ),
        ),
      ),
      body: _isLoading
          ? _buildSkeletonLoader()
          : _errorMessage.isNotEmpty
              ? Center(
                  child: FadeInUp(
                    child: Text(
                      _errorMessage,
                      style: GoogleFonts.poppins(color: Colors.red, fontSize: 16.sp),
                    ),
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final isTablet = constraints.maxWidth > 600;
                    return RefreshIndicator(
                      onRefresh: _fetchProducts,
                      color: Colors.orange,
                      child: ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: isTablet ? 32.w : 16.w, vertical: 12.h),
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          final product = products[index];
                          return FadeInUp(
                            delay: Duration(milliseconds: index * 100),
                            child: Card(
                              elevation: 4,
                              margin: EdgeInsets.symmetric(vertical: 8.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: ListTile(
                                contentPadding: EdgeInsets.all(16.w),
                                leading: product['image'] != null && product['image'].isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8.r),
                                        child: CachedNetworkImage(
                                          imageUrl: product['image'],
                                          width: 60.w,
                                          height: 60.h,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) => Shimmer.fromColors(
                                            baseColor: Colors.grey[300]!,
                                            highlightColor: Colors.grey[100]!,
                                            child: Container(color: Colors.white),
                                          ),
                                          errorWidget: (context, url, error) => const Icon(Icons.error),
                                        ),
                                      )
                                    : Icon(Icons.image_not_supported, size: 40.sp, color: Colors.grey),
                                title: Text(
                                  product['name'] ?? "Không có tên",
                                  style: GoogleFonts.poppins(
                                    fontSize: isTablet ? 20.sp : 18.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  "Giá: ${product['price']} đ",
                                  style: GoogleFonts.poppins(
                                    fontSize: isTablet ? 18.sp : 16.sp,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                trailing: Icon(Icons.edit, color: Colors.teal, size: 24.sp),
                                onTap: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EditProductPage(productId: product['_id']),
                                    ),
                                  );
                                  if (result == true) {
                                    _showFlushbar('✅ Sản phẩm đã được cập nhật!', Colors.green);
                                    _fetchProducts();
                                  }
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}