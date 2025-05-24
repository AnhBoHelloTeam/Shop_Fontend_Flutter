import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:another_flushbar/flushbar.dart';

class HotBuyProducts extends StatefulWidget {
  const HotBuyProducts({super.key});

  @override
  _HotBuyProductsState createState() => _HotBuyProductsState();
}

class _HotBuyProductsState extends State<HotBuyProducts> {
  List<dynamic> hotProducts = [];
  bool isLoading = true;
  String? errorMessage;
  bool isFetchingDetail = false;

  @override
  void initState() {
    super.initState();
    _fetchHotProducts();
  }

  Future<void> _fetchHotProducts({bool isRetry = false}) async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      if (!isRetry) errorMessage = null;
    });

    const maxRetries = 3;
    int attempt = 0;
    const timeoutSeconds = 5;

    // Load cached data first
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString('hot_products');
    if (cachedData != null && !isRetry) {
      try {
        final cachedProducts = jsonDecode(cachedData) as List<dynamic>;
        if (mounted) {
          setState(() {
            hotProducts = cachedProducts.where((item) {
              return item != null &&
                  item is Map &&
                  item['_id'] != null &&
                  item['name'] != null &&
                  item['price'] != null;
            }).toList();
            isLoading = false;
          });
          if (kDebugMode) debugPrint('📡 Loaded ${hotProducts.length} hot products from cache');
        }
      } catch (e) {
        if (kDebugMode) debugPrint('🔥 Error decoding cached data: $e');
      }
    }

    while (attempt <= maxRetries) {
      try {
        final client = http.Client();
        final response = await client
            .get(
              Uri.parse('https://shop-backend-nodejs.onrender.com/api/products/hot'),
              headers: {'Connection': 'keep-alive'},
            )
            .timeout(const Duration(seconds: timeoutSeconds));
        client.close();

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as List<dynamic>;
          final validProducts = data.where((item) {
            return item != null &&
                item is Map &&
                item['_id'] != null &&
                item['name'] != null &&
                item['price'] != null;
          }).toList();

          await prefs.setString('hot_products', jsonEncode(data));
          if (kDebugMode) debugPrint('📡 Saved ${validProducts.length} hot products to cache');

          if (mounted) {
            setState(() {
              hotProducts = validProducts;
              isLoading = false;
              errorMessage = null;
            });
          }
          return;
        } else {
          if (kDebugMode) debugPrint('⚠️ Failed to fetch hot products: ${response.statusCode}');
          attempt++;
          if (attempt > maxRetries) {
            if (mounted) {
              setState(() {
                isLoading = false;
                errorMessage = 'Lỗi khi lấy sản phẩm hot';
              });
            }
            return;
          }
          await Future.delayed(const Duration(seconds: 2));
        }
      } catch (e) {
        if (kDebugMode) debugPrint('🔥 Error fetching hot products (attempt ${attempt + 1}): $e');
        attempt++;
        if (attempt > maxRetries) {
          if (mounted) {
            setState(() {
              isLoading = false;
              errorMessage = 'Không thể kết nối đến server';
            });
          }
          return;
        }
        await Future.delayed(const Duration(seconds: 2));
      }
    }
  }

  Future<Map<String, dynamic>?> _fetchProductDetail(String productId) async {
    const maxRetries = 2;
    int attempt = 0;
    const timeoutSeconds = 5;

    while (attempt <= maxRetries) {
      try {
        final client = http.Client();
        final response = await client
            .get(
              Uri.parse('https://shop-backend-nodejs.onrender.com/api/products/$productId'),
              headers: {'Connection': 'keep-alive'},
            )
            .timeout(const Duration(seconds: timeoutSeconds));
        client.close();

        if (kDebugMode) debugPrint('📡 Fetch product detail ($productId): ${response.statusCode}');

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          if (data['_id'] == null) {
            _showFlushbar('Dữ liệu sản phẩm không hợp lệ', Colors.red);
            return null;
          }
          return data;
        } else {
          if (kDebugMode) debugPrint('⚠️ Failed to fetch product detail: ${response.statusCode}');
          attempt++;
          if (attempt > maxRetries) {
            _showFlushbar('Lỗi khi lấy chi tiết sản phẩm', Colors.red);
            return null;
          }
          await Future.delayed(const Duration(seconds: 1));
        }
      } catch (e) {
        if (kDebugMode) debugPrint('🔥 Error fetching product detail (attempt ${attempt + 1}): $e');
        attempt++;
        if (attempt > maxRetries) {
          _showFlushbar('Không thể lấy chi tiết sản phẩm', Colors.red);
          return null;
        }
        await Future.delayed(const Duration(seconds: 1));
      }
    }
    return null;
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
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: 3,
      itemBuilder: (context, index) {
        return Container(
          width: 150.w,
          margin: EdgeInsets.symmetric(horizontal: 8.w),
          child: Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 90.h,
                    width: double.infinity,
                    color: Colors.white,
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(6.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(height: 13.h, width: 100.w, color: Colors.white),
                          Container(height: 11.h, width: 60.w, color: Colors.white),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(height: 11.h, width: 50.w, color: Colors.white),
                              Container(height: 11.h, width: 30.w, color: Colors.white),
                            ],
                          ),
                        ],
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
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: FadeIn(
            child: Text(
              '🔥 Sản phẩm hot',
              style: GoogleFonts.poppins(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
        ),
        SizedBox(
          height: 200.h,
          child: isLoading
              ? _buildSkeletonLoader()
              : errorMessage != null
                  ? Center(
                      child: FadeInUp(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              errorMessage!,
                              style: GoogleFonts.poppins(
                                color: Colors.red,
                                fontSize: 16.sp,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 8.h),
                            ZoomIn(
                              child: ElevatedButton(
                                onPressed: () => _fetchHotProducts(isRetry: true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                                ),
                                child: Text(
                                  'Thử lại',
                                  style: GoogleFonts.poppins(fontSize: 14.sp, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : hotProducts.isEmpty
                      ? Center(
                          child: Text(
                            'Chưa có sản phẩm hot',
                            style: GoogleFonts.poppins(fontSize: 16.sp, color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: hotProducts.length,
                          itemBuilder: (context, index) {
                            final product = hotProducts[index];
                            return FadeInRight(
                              delay: Duration(milliseconds: index * 100),
                              child: Container(
                                width: 150.w,
                                margin: EdgeInsets.symmetric(horizontal: 8.w),
                                child: Card(
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
                                        child: CachedNetworkImage(
                                          imageUrl: product['image'] ?? 'https://via.placeholder.com/150',
                                          height: 90.h,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) => Shimmer.fromColors(
                                            baseColor: Colors.grey[300]!,
                                            highlightColor: Colors.grey[100]!,
                                            child: Container(
                                              height: 90.h,
                                              color: Colors.white,
                                            ),
                                          ),
                                          errorWidget: (context, url, error) => Icon(Icons.error, size: 30.sp),
                                        ),
                                      ),
                                      Expanded(
                                        child: Padding(
                                          padding: EdgeInsets.all(6.w),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                product['name'] ?? 'Sản phẩm',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 13.sp,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                '${product['price'] ?? 0} đ',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 11.sp,
                                                  color: Colors.red,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    'Đã bán: ${product['soldCount'] ?? 0}',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 11.sp,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                  GestureDetector(
                                                    onTap: () async {
                                                      if (product['_id'] == null) {
                                                        _showFlushbar('ID sản phẩm không hợp lệ', Colors.red);
                                                        return;
                                                      }
                                                      setState(() => isFetchingDetail = true);
                                                      final productDetail = await _fetchProductDetail(product['_id']);
                                                      setState(() => isFetchingDetail = false);
                                                      if (productDetail != null && mounted) {
                                                        try {
                                                          await Navigator.pushNamed(
                                                            context,
                                                            '/product_detail',
                                                            arguments: productDetail,
                                                          );
                                                        } catch (e) {
                                                          if (kDebugMode) debugPrint('🔥 Error navigating: $e');
                                                          _showFlushbar('Lỗi khi mở chi tiết sản phẩm', Colors.red);
                                                        }
                                                      }
                                                    },
                                                    child: isFetchingDetail
                                                        ? SizedBox(
                                                            width: 16.w,
                                                            height: 16.h,
                                                            child: CircularProgressIndicator(strokeWidth: 2),
                                                          )
                                                        : Text(
                                                            'Chi tiết',
                                                            style: GoogleFonts.poppins(
                                                              fontSize: 11.sp,
                                                              color: Colors.blue,
                                                              fontWeight: FontWeight.w500,
                                                            ),
                                                          ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
        ),
      ],
    );
  }
}