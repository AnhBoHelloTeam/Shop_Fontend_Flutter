import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key});

  @override
  _ProductDetailScreenState createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  Map<String, dynamic>? product;
  List<dynamic> reviews = [];
  bool isLoading = true;
  String? errorMessage;
  bool _isDataLoaded = false;
  Map<String, String> _userNameCache = {}; // Cache for user names by user ID

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _loadProductData());
  }

  Future<void> _loadProductData() async {
    if (_isDataLoaded || !mounted) return;
    _isDataLoaded = true;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final dynamic arguments = ModalRoute.of(context)?.settings.arguments;
    String? productId;

    if (arguments is Map && arguments['_id'] is String) {
      productId = arguments['_id'];
      if (arguments['name'] != null && mounted) {
        setState(() {
          product = arguments.cast<String, dynamic>();
        });
      }
    }

    if (productId == null) {
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = 'Không có ID sản phẩm hợp lệ';
        });
        if (kDebugMode) debugPrint('🔥 Error: No valid product ID');
      }
      return;
    }

    // Initialize SharedPreferences
    final prefs = await SharedPreferences.getInstance();

    // Check cache for product and reviews
    final cachedProduct = prefs.getString('product_$productId');
    final cachedReviews = prefs.getString('reviews_$productId');

    if (cachedProduct != null && cachedReviews != null && mounted) {
      setState(() {
        product = json.decode(cachedProduct);
        reviews = json.decode(cachedReviews);
        isLoading = false;
      });
      if (kDebugMode) debugPrint('📡 Loaded from cache: product_$productId');
    }

    // Fetch authToken for user API calls
    final authToken = prefs.getString('authToken') ?? '';

    // Fetch product and reviews with retry
    const maxRetries = 3;
    int attempt = 0;

    while (attempt < maxRetries) {
      try {
        final client = http.Client();
        final responses = await Future.wait([
          client.get(
            Uri.parse('https://shop-backend-nodejs.onrender.com/api/products/$productId'),
            headers: {'Connection': 'keep-alive'},
          ).timeout(const Duration(seconds: 5)),
          client.get(
            Uri.parse('https://shop-backend-nodejs.onrender.com/api/orders/review/$productId'),
            headers: {'Connection': 'keep-alive'},
          ).timeout(const Duration(seconds: 5)),
        ]);
        client.close();

        final productResponse = responses[0];
        final reviewsResponse = responses[1];

        if (productResponse.statusCode == 200) {
          final data = json.decode(productResponse.body);
          if (data['_id'] != null) {
            product = data;
            await prefs.setString('product_$productId', json.encode(data));
          } else {
            errorMessage = 'Dữ liệu sản phẩm không hợp lệ';
            break;
          }
        } else {
          errorMessage = 'Không tìm thấy sản phẩm (Status: ${productResponse.statusCode})';
          break;
        }

        if (reviewsResponse.statusCode == 200) {
          final data = json.decode(reviewsResponse.body);
          reviews = data is List ? data : [];
          await prefs.setString('reviews_$productId', json.encode(reviews));
        } else {
          reviews = [];
        }

        if (kDebugMode) debugPrint('📡 Fetched product: ${productResponse.statusCode}, reviews: ${reviewsResponse.statusCode}');
        break;
      } catch (e) {
        if (kDebugMode) debugPrint('🔥 Error fetching data (attempt ${attempt + 1}): $e');
        attempt++;
        if (attempt >= maxRetries) {
          errorMessage = 'Lỗi kết nối';
          reviews = [];
          break;
        }
        await Future.delayed(const Duration(seconds: 2));
      }
    }

    // Fetch user names for reviews
    if (reviews.isNotEmpty && authToken.isNotEmpty) {
      await _fetchUserNamesForReviews(prefs, authToken);
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchUserNamesForReviews(SharedPreferences prefs, String authToken) async {
    const maxRetries = 3;
    const timeoutSeconds = 5;

    for (var review in reviews) {
      String? userId = review['user']?['_id'] ?? review['userId'];
      if (userId == null) {
        if (kDebugMode) debugPrint('🔥 No userId found for review: ${review['_id']}');
        continue;
      }

      // Check cache first
      final cachedUserName = prefs.getString('user_name_$userId');
      if (cachedUserName != null) {
        _userNameCache[userId] = cachedUserName;
        if (kDebugMode) debugPrint('📡 Loaded user name from cache: $userId -> $cachedUserName');
        continue;
      }

      // Fetch user name from API
      int attempt = 0;
      while (attempt < maxRetries) {
        try {
          final client = http.Client();
          final response = await client
              .get(
                Uri.parse('https://shop-backend-nodejs.onrender.com/api/users/$userId'),
                headers: {
                  'Authorization': 'Bearer $authToken',
                  'Connection': 'keep-alive',
                },
              )
              .timeout(const Duration(seconds: timeoutSeconds));
          client.close();

          if (kDebugMode) debugPrint('📡 User fetch response for $userId: ${response.statusCode}, attempt ${attempt + 1}');

          if (response.statusCode == 200) {
            final userData = json.decode(response.body);
            final userName = userData['name'] ?? 'Người dùng';
            _userNameCache[userId] = userName;
            await prefs.setString('user_name_$userId', userName);
            if (kDebugMode) debugPrint('📡 Fetched user name: $userId -> $userName');
            break;
          } else {
            if (kDebugMode) debugPrint('⚠️ Failed to fetch user $userId: ${response.statusCode}');
            _userNameCache[userId] = 'Người dùng';
            break;
          }
        } catch (e) {
          if (kDebugMode) debugPrint('🔥 Error fetching user $userId (attempt ${attempt + 1}): $e');
          attempt++;
          if (attempt >= maxRetries) {
            _userNameCache[userId] = 'Người dùng';
            break;
          }
          await Future.delayed(const Duration(seconds: 2));
        }
      }
    }
  }

  Future<void> addToCart(BuildContext context, String? productId) async {
    const String apiUrl = "https://shop-backend-nodejs.onrender.com/api/cart/add";

    if (productId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Lỗi: Không có ID sản phẩm")),
      );
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('authToken') ?? '';

      if (authToken.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("🔐 Bạn cần đăng nhập để thêm vào giỏ hàng")),
        );
        return;
      }

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $authToken",
        },
        body: jsonEncode({
          "productId": productId,
          "quantity": 1,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Đã thêm vào giỏ hàng")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Lỗi khi thêm vào giỏ hàng: ${response.statusCode}")),
        );
      }
    } catch (e) {
      if (kDebugMode) debugPrint('🔥 Error adding to cart: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Không thể thêm vào giỏ hàng")),
      );
    }
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
            Center(
              child: Container(
                width: 250.w,
                height: 250.h,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 24.h),
            Container(width: 200.w, height: 24.h, color: Colors.white),
            SizedBox(height: 12.h),
            Container(width: 100.w, height: 20.h, color: Colors.white),
            SizedBox(height: 12.h),
            Container(width: 300.w, height: 16.h, color: Colors.white),
            SizedBox(height: 12.h),
            Container(width: 150.w, height: 16.h, color: Colors.white),
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
            product?['name'] ?? 'Chi tiết sản phẩm',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 20.sp,
            ),
          ),
        ),
        leading: ZoomIn(
          child: IconButton(
            key: const Key('backButton'),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: isLoading
          ? _buildSkeletonLoader()
          : errorMessage != null || product == null
              ? Center(
                  child: FadeInUp(
                    child: Text(
                      errorMessage ?? 'Không có dữ liệu sản phẩm',
                      style: GoogleFonts.poppins(fontSize: 16.sp),
                    ),
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final isTablet = constraints.maxWidth > 600;
                    return RefreshIndicator(
                      onRefresh: () {
                        _isDataLoaded = false; // Allow data reload
                        return _loadProductData();
                      },
                      color: Colors.orange,
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(16.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FadeIn(
                              child: Center(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(15.r),
                                  child: Image.network(
                                    product!['image'] ?? 'https://via.placeholder.com/150',
                                    height: isTablet ? 300.h : 250.h,
                                    width: isTablet ? 300.w : 250.w,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Icon(Icons.error, size: 100),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 24.h),
                            FadeInUp(
                              child: Text(
                                product!['name'] ?? 'Không có tên',
                                style: GoogleFonts.poppins(
                                  fontSize: isTablet ? 28.sp : 24.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(height: 12.h),
                            FadeInUp(
                              delay: const Duration(milliseconds: 100),
                              child: Text(
                                "Giá: ${product!['price'] ?? 'N/A'} đ",
                                style: GoogleFonts.poppins(
                                  color: Colors.red,
                                  fontSize: isTablet ? 22.sp : 20.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            SizedBox(height: 12.h),
                            FadeInUp(
                              delay: const Duration(milliseconds: 200),
                              child: Text(
                                "Mô tả: ${product!['description'] ?? 'Không có mô tả'}",
                                style: GoogleFonts.poppins(
                                  fontSize: isTablet ? 18.sp : 16.sp,
                                ),
                              ),
                            ),
                            SizedBox(height: 12.h),
                            FadeInUp(
                              delay: const Duration(milliseconds: 300),
                              child: Text(
                                "Danh mục: ${product!['category'] ?? 'Không có danh mục'}",
                                style: GoogleFonts.poppins(
                                  fontSize: isTablet ? 18.sp : 16.sp,
                                ),
                              ),
                            ),
                            SizedBox(height: 12.h),
                            FadeInUp(
                              delay: const Duration(milliseconds: 400),
                              child: Text(
                                "Số lượng còn lại: ${product!['stock'] ?? 'Không xác định'}",
                                style: GoogleFonts.poppins(
                                  fontSize: isTablet ? 18.sp : 16.sp,
                                ),
                              ),
                            ),
                            SizedBox(height: 24.h),
                            FadeInUp(
                              delay: const Duration(milliseconds: 500),
                              child: Center(
                                child: ZoomIn(
                                  child: ElevatedButton(
                                    onPressed: () => addToCart(context, product!['_id']),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      padding: EdgeInsets.symmetric(
                                        vertical: isTablet ? 18.h : 14.h,
                                        horizontal: isTablet ? 60.w : 40.w,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20.r),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [Colors.orange, Colors.amber],
                                        ),
                                        borderRadius: BorderRadius.all(Radius.circular(20)),
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        vertical: isTablet ? 18.h : 14.h,
                                        horizontal: isTablet ? 60.w : 40.w,
                                      ),
                                      child: Text(
                                        '🛒 Thêm vào giỏ hàng',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: isTablet ? 20.sp : 18.sp,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 24.h),
                            FadeInUp(
                              delay: const Duration(milliseconds: 600),
                              child: Text(
                                'Đánh giá sản phẩm',
                                style: GoogleFonts.poppins(
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(height: 12.h),
                            reviews.isEmpty
                                ? FadeInUp(
                                    delay: const Duration(milliseconds: 700),
                                    child: Text(
                                      'Chưa có đánh giá nào',
                                      style: GoogleFonts.poppins(
                                        fontSize: isTablet ? 18.sp : 16.sp,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: reviews.length,
                                    itemBuilder: (context, index) {
                                      final review = reviews[index];
                                      final userId = review['user']?['_id'] ?? review['userId'] ?? 'unknown';
                                      final userName = _userNameCache[userId] ?? 'Người dùng';
                                      return FadeInUp(
                                        delay: Duration(milliseconds: 800 + index * 100),
                                        child: Card(
                                          elevation: 3,
                                          margin: EdgeInsets.symmetric(vertical: 8.h),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12.r),
                                          ),
                                          child: Padding(
                                            padding: EdgeInsets.all(12.w),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Text(
                                                      userName,
                                                      style: GoogleFonts.poppins(
                                                        fontSize: 16.sp,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                    const Spacer(),
                                                    Row(
                                                      children: List.generate(5, (i) {
                                                        return Icon(
                                                          i < (review['rating'] ?? 0)
                                                              ? Icons.star
                                                              : Icons.star_border,
                                                          color: Colors.amber,
                                                          size: 18.sp,
                                                        );
                                                      }),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(height: 8.h),
                                                Text(
                                                  review['comment'] ?? 'Không có nhận xét',
                                                  style: GoogleFonts.poppins(fontSize: 14.sp),
                                                ),
                                                SizedBox(height: 8.h),
                                                Text(
                                                  _formatDate(review['createdAt']),
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 12.sp,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return 'Không xác định';
    try {
      final date = DateTime.parse(isoDate).toLocal();
      return "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}";
    } catch (e) {
      return 'Ngày không hợp lệ';
    }
  }
}