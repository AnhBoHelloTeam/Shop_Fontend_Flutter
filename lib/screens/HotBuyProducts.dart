import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';

class HotBuyProducts extends StatefulWidget {
  const HotBuyProducts({Key? key}) : super(key: key);

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

  Future<void> _fetchHotProducts() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse('https://shop-backend-nodejs.onrender.com/api/products/hot'),
        headers: {'Connection': 'keep-alive'},
      ).timeout(Duration(seconds: 10));

      print('📡 Response hot products: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List<dynamic>;
        final validProducts = data.where((item) {
          return item != null &&
              item is Map &&
              item['_id'] != null &&
              item['name'] != null &&
              item['price'] != null;
        }).toList();
        print('📡 Valid hot products: ${validProducts.length}');
        setState(() {
          hotProducts = validProducts;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          errorMessage = 'Lỗi khi lấy danh sách sản phẩm hot: ${response.statusCode}';
        });
      }
    } catch (e) {
      print('🔥 Lỗi khi lấy danh sách sản phẩm hot: $e');
      setState(() {
        isLoading = false;
        errorMessage = 'Lỗi kết nối đến server: $e';
      });
    }
  }

  // Hàm gọi API /api/products/<id> với retry
  Future<Map<String, dynamic>?> _fetchProductDetail(String productId) async {
    const maxRetries = 2;
    int attempt = 0;

    while (attempt <= maxRetries) {
      try {
        final client = http.Client();
        final response = await client
            .get(
              Uri.parse('https://shop-backend-nodejs.onrender.com/api/products/$productId'),
              headers: {'Connection': 'keep-alive'},
            )
            .timeout(Duration(seconds: 10));
        client.close();

        print('📡 Fetch product detail ($productId, attempt ${attempt + 1}): ${response.statusCode} - ${response.body}');

        if (response.statusCode == 200) {
          final data = json.decode(response.body) as Map<String, dynamic>;
          if (data['_id'] == null) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Dữ liệu sản phẩm không hợp lệ: Thiếu ID')),
              );
            }
            return null;
          }
          return data;
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Lỗi khi lấy chi tiết sản phẩm: ${response.statusCode}')),
            );
          }
          return null;
        }
      } catch (e) {
        print('🔥 Lỗi khi lấy chi tiết sản phẩm (attempt ${attempt + 1}): $e');
        attempt++;
        if (attempt > maxRetries) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Không thể lấy chi tiết sản phẩm: $e')),
            );
          }
          return null;
        }
        await Future.delayed(Duration(seconds: 1));
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Text(
            'Sản phẩm hot',
            style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 200.h,
          child: isLoading
              ? Center(child: CircularProgressIndicator())
              : errorMessage != null
                  ? Center(child: Text(errorMessage!, style: TextStyle(color: Colors.red, fontSize: 16.sp)))
                  : hotProducts.isEmpty
                      ? Center(child: Text('Chưa có sản phẩm hot', style: TextStyle(fontSize: 16.sp, color: Colors.grey)))
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: hotProducts.length,
                          itemBuilder: (context, index) {
                            final product = hotProducts[index];
                            return Container(
                              width: 150.w,
                              margin: EdgeInsets.symmetric(horizontal: 8.w),
                              child: Card(
                                elevation: 3,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CachedNetworkImage(
                                      imageUrl: product['image'] ?? 'https://via.placeholder.com/150',
                                      height: 90.h,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Center(child: CircularProgressIndicator()),
                                      errorWidget: (context, url, error) => Icon(Icons.error),
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
                                              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              '${product['price'] ?? 0} đ',
                                              style: TextStyle(fontSize: 11.sp, color: Colors.red),
                                            ),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  'Đã bán: ${product['soldCount'] ?? 0}',
                                                  style: TextStyle(fontSize: 11.sp, color: Colors.grey),
                                                ),
                                                GestureDetector(
                                                  onTap: () async {
                                                    if (product['_id'] == null) {
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(content: Text('Không thể xem chi tiết: ID sản phẩm không hợp lệ')),
                                                      );
                                                      return;
                                                    }
                                                    setState(() {
                                                      isFetchingDetail = true;
                                                    });
                                                    final productDetail = await _fetchProductDetail(product['_id']);
                                                    setState(() {
                                                      isFetchingDetail = false;
                                                    });
                                                    if (productDetail != null) {
                                                      print('📡 Navigating to product detail: ${product['_id']}, data: $productDetail');
                                                      try {
                                                        await Navigator.pushNamed(context, '/product_detail', arguments: productDetail);
                                                      } catch (e) {
                                                        print('🔥 Lỗi khi điều hướng: $e');
                                                        if (mounted) {
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            SnackBar(content: Text('Lỗi khi mở chi tiết sản phẩm')),
                                                          );
                                                        }
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
                                                          style: TextStyle(fontSize: 11.sp, color: Colors.blue),
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
                            );
                          },
                        ),
        ),
      ],
    );
  }
}