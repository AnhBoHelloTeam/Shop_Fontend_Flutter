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
import 'package:intl/intl.dart';
import 'package:shop_frontend/screens/return_request_screen.dart';

// Widget hiển thị lịch sử đơn hàng
class OrderHistoryScreen extends StatefulWidget {
  final VoidCallback? onDeliveryConfirmed;

  const OrderHistoryScreen({super.key, this.onDeliveryConfirmed});

  @override
  _OrderHistoryScreenState createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  List<dynamic> orders = [];
  List<dynamic> returnRequests = [];
  bool isLoading = true;
  String errorMessage = '';
  String? userId;
  String? membershipTier;

  @override
  void initState() {
    super.initState();
    _checkLoginAndFetchHistory();
  }

  // Kiểm tra đăng nhập và lấy lịch sử
  Future<void> _checkLoginAndFetchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('authToken') ?? '';

    if (authToken.isEmpty) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              title: Text(
                "Cần đăng nhập",
                style: GoogleFonts.poppins(fontSize: 16.sp, fontWeight: FontWeight.bold),
              ),
              content: Text(
                "Vui lòng đăng nhập để xem lịch sử đơn hàng.",
                style: GoogleFonts.poppins(fontSize: 14.sp),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.pushReplacementNamed(context, '/');
                  },
                  child: Text(
                    "Đăng nhập",
                    style: GoogleFonts.poppins(fontSize: 14.sp, color: Colors.blue),
                  ),
                ),
              ],
            ),
          );
        });
      }
      return;
    }

    try {
      final client = http.Client();
      final response = await client
          .get(
            Uri.parse('https://shop-backend-nodejs.onrender.com/api/users/me'),
            headers: {"Authorization": "Bearer $authToken"},
          )
          .timeout(const Duration(seconds: 5));
      client.close();

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        userId = userData['_id'];
        membershipTier = userData['membershipTier'] ?? 'Member';
        if (kDebugMode) debugPrint('📡 Lấy userId: $userId, membershipTier: $membershipTier');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('🔥 Lỗi lấy userId: $e');
    }

    await _fetchOrderHistory(authToken);
    await _fetchReturnRequests(authToken);
  }

  // Lấy lịch sử đơn hàng
  Future<void> _fetchOrderHistory(String authToken) async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedOrders = prefs.getString('order_history');
      if (cachedOrders != null) {
        try {
          final cachedData = jsonDecode(cachedOrders);
          if (mounted) {
            setState(() {
              orders = cachedData;
            });
            if (kDebugMode) debugPrint('📡 Load ${orders.length} đơn hàng từ cache');
          }
        } catch (e) {
          if (kDebugMode) debugPrint('🔥 Lỗi giải mã cache: $e');
        }
      }

      final client = http.Client();
      final response = await client
          .get(
            Uri.parse("https://shop-backend-nodejs.onrender.com/api/orders/history"),
            headers: {"Authorization": "Bearer $authToken"},
          )
          .timeout(const Duration(seconds: 5));
      client.close();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await prefs.setString('order_history', response.body);
        if (mounted) {
          setState(() {
            orders = data;
            isLoading = false;
            errorMessage = '';
          });
        }
      } else {
        if (mounted) {
          setState(() {
            errorMessage = 'Không thể lấy lịch sử đơn hàng';
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('🔥 Lỗi lấy lịch sử đơn: $e');
      if (mounted) {
        setState(() {
          errorMessage = 'Lỗi kết nối server';
          isLoading = false;
        });
      }
    }
  }

  // Lấy danh sách yêu cầu trả hàng
  Future<void> _fetchReturnRequests(String authToken) async {
    try {
      final client = http.Client();
      final response = await client
          .get(
            Uri.parse('https://shop-backend-nodejs.onrender.com/api/orders/return-requests'),
            headers: {'Authorization': 'Bearer $authToken'},
          )
          .timeout(const Duration(seconds: 5));
      client.close();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            returnRequests = data;
          });
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('🔥 Lỗi lấy yêu cầu trả hàng: $e');
    }
  }

  // Kiểm tra trạng thái trả hàng
  Map<String, dynamic>? _getReturnRequest(String orderId) {
    try {
      return returnRequests.firstWhere(
        (request) => request['order']['_id'] == orderId,
        orElse: () => null,
      );
    } catch (e) {
      return null;
    }
  }

  // Kiểm tra đánh giá sản phẩm
  Future<bool> _hasReviewed(String productId, String authToken) async {
    try {
      final client = http.Client();
      final response = await client
          .get(
            Uri.parse('https://shop-backend-nodejs.onrender.com/api/orders/review/$productId'),
            headers: {"Authorization": "Bearer $authToken"},
          )
          .timeout(const Duration(seconds: 5));
      client.close();

      if (response.statusCode == 200) {
        final reviews = jsonDecode(response.body);
        return reviews.any((review) => review['userId'] == userId);
      }
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('🔥 Lỗi kiểm tra đánh giá: $e');
      return false;
    }
  }

  // Xác nhận nhận hàng
  Future<void> _confirmDelivery(String orderId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('authToken') ?? '';
      final client = http.Client();
      final response = await client
          .put(
            Uri.parse("https://shop-backend-nodejs.onrender.com/api/orders/deliver/$orderId"),
            headers: {"Authorization": "Bearer $authToken"},
          )
          .timeout(const Duration(seconds: 5));
      client.close();

      if (response.statusCode == 200) {
        _showFlushbar('✅ Xác nhận nhận hàng thành công', Colors.green);
        await _fetchOrderHistory(authToken);
        if (widget.onDeliveryConfirmed != null) {
          widget.onDeliveryConfirmed!();
        }
      } else {
        _showFlushbar('Không thể xác nhận nhận hàng', Colors.red);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('🔥 Lỗi xác nhận giao hàng: $e');
      _showFlushbar('Lỗi server', Colors.red);
    }
  }

  // Chuyển đến màn hình yêu cầu trả hàng
  Future<void> _requestReturn(String orderId) async {
    final order = orders.firstWhere((o) => o['_id'] == orderId, orElse: () => null);
    if (order == null) {
      _showFlushbar('Không tìm thấy đơn hàng', Colors.red);
      return;
    }

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ReturnRequestScreen(
            orderId: orderId,
            items: List<Map<String, dynamic>>.from(order['items'] ?? []),
          ),
        ),
      );
    }
  }

  // Gửi đánh giá
  Future<void> _submitReview(String productId, int rating, String comment) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('authToken') ?? '';
      final client = http.Client();
      final response = await client
          .post(
            Uri.parse("https://shop-backend-nodejs.onrender.com/api/orders/review"),
            headers: {
              "Authorization": "Bearer $authToken",
              "Content-Type": "application/json",
            },
            body: jsonEncode({
              "productId": productId,
              "rating": rating,
              "comment": comment,
            }),
          )
          .timeout(const Duration(seconds: 5));
      client.close();

      if (response.statusCode == 201) {
        _showFlushbar('✅ Đánh giá thành công', Colors.green);
        await _fetchOrderHistory(authToken);
      } else {
        _showFlushbar('Không thể gửi đánh giá', Colors.red);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('🔥 Lỗi gửi đánh giá: $e');
      _showFlushbar('Lỗi server', Colors.red);
    }
  }

  // Hiển thị thông báo
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

  // Hiển thị dialog đánh giá
  void _showReviewDialog(String productId, String productName) {
    int? rating;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          title: Text(
            'Đánh giá: $productName',
            style: GoogleFonts.poppins(fontSize: 16.sp, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chọn số sao:',
                style: GoogleFonts.poppins(fontSize: 14.sp),
              ),
              Row(
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < (rating ?? 0) ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 24.sp,
                    ),
                    onPressed: () {
                      setDialogState(() {
                        rating = index + 1;
                      });
                    },
                  );
                }),
              ),
              TextField(
                controller: commentController,
                decoration: InputDecoration(
                  labelText: 'Nhận xét',
                  labelStyle: GoogleFonts.poppins(fontSize: 14.sp),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                ),
                style: GoogleFonts.poppins(fontSize: 14.sp),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Hủy',
                style: GoogleFonts.poppins(fontSize: 14.sp, color: Colors.red),
              ),
            ),
            ElevatedButton(
              onPressed: rating == null
                  ? null
                  : () {
                      _submitReview(productId, rating!, commentController.text);
                      Navigator.pop(context);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
              ),
              child: Text(
                'Gửi',
                style: GoogleFonts.poppins(fontSize: 14.sp, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Chuyển trạng thái sang tiếng Việt
  String _getStatusText(String status, Map<String, dynamic>? returnRequest) {
    if (status == 'delivered' && returnRequest != null) {
      switch (returnRequest['status']) {
        case 'pending':
          return 'Đang chờ duyệt trả hàng';
        case 'approved':
          return 'Trả hàng được chấp nhận';
        case 'rejected':
          return 'Trả hàng bị từ chối';
      }
    }
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

  // Skeleton loader
  Widget _buildSkeletonLoader() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: 3,
        itemBuilder: (context, index) {
          return Card(
            margin: EdgeInsets.symmetric(vertical: 8.h),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            child: Padding(
              padding: EdgeInsets.all(12.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 100.w, height: 18.h, color: Colors.white),
                  SizedBox(height: 8.h),
                  Container(width: 150.w, height: 14.h, color: Colors.white),
                  SizedBox(height: 8.h),
                  Container(width: 120.w, height: 14.h, color: Colors.white),
                ],
              ),
            ),
          );
        },
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
            "📜 Lịch sử đơn hàng",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 20.sp,
            ),
          ),
        ),
      ),
      body: FutureBuilder<String>(
        future: SharedPreferences.getInstance().then((prefs) => prefs.getString('authToken') ?? ''),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.orange));
          }
          final authToken = snapshot.data ?? '';
          if (authToken.isEmpty) {
            return Center(
              child: Text(
                'Vui lòng đăng nhập',
                style: GoogleFonts.poppins(fontSize: 16.sp),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              await _fetchOrderHistory(authToken);
              await _fetchReturnRequests(authToken);
            },
            color: Colors.orange,
            child: isLoading
                ? _buildSkeletonLoader()
                : errorMessage.isNotEmpty
                    ? Center(
                        child: FadeInUp(
                          child: Text(
                            errorMessage,
                            style: GoogleFonts.poppins(color: Colors.red, fontSize: 16.sp),
                          ),
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.all(16.w),
                            child: FadeIn(
                              child: Text(
                                'Thành viên: ${membershipTier ?? 'Đang tải...'}',
                                style: GoogleFonts.poppins(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: orders.isEmpty
                                ? Center(
                                    child: Text(
                                      'Chưa có đơn hàng nào',
                                      style: GoogleFonts.poppins(fontSize: 16.sp),
                                    ),
                                  )
                                : ListView.builder(
                                    padding: EdgeInsets.all(16.w),
                                    itemCount: orders.length,
                                    itemBuilder: (context, index) {
                                      final order = orders[index];
                                      final createdAt = DateTime.parse(
                                        order['createdAt'] ?? DateTime.now().toIso8601String(),
                                      ).toLocal();
                                      final returnRequest = _getReturnRequest(order['_id']);
                                      return FadeInUp(
                                        delay: Duration(milliseconds: index * 100),
                                        child: Card(
                                          margin: EdgeInsets.symmetric(vertical: 8.h),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                                          elevation: 4,
                                          child: Padding(
                                            padding: EdgeInsets.all(12.w),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Đơn hàng #${order['_id']?.substring(0, 8) ?? 'N/A'}',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 18.sp,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                SizedBox(height: 8.h),
                                                Text(
                                                  'Ngày đặt: ${DateFormat('dd/MM/yyyy HH:mm').format(createdAt)}',
                                                  style: GoogleFonts.poppins(fontSize: 14.sp),
                                                ),
                                                Text(
                                                  'Trạng thái: ${_getStatusText(order['status'], returnRequest)}',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 14.sp,
                                                    color: returnRequest != null && returnRequest['status'] == 'pending'
                                                        ? Colors.orange
                                                        : returnRequest != null && returnRequest['status'] == 'approved'
                                                            ? Colors.green
                                                            : Colors.blue,
                                                  ),
                                                ),
                                                Text(
                                                  'Tổng giá: ${(order['totalPrice']?.toDouble() ?? 0.0).toStringAsFixed(2)} đ',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 14.sp,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                if (order['discount'] != null && order['discount']['amount'] > 0)
                                                  Text(
                                                    'Giảm giá: ${(order['discount']['amount']?.toDouble() ?? 0.0).toStringAsFixed(2)} đ (Mã: ${order['discount']['code'] ?? 'N/A'})',
                                                    style: GoogleFonts.poppins(
                                                      color: Colors.green,
                                                      fontSize: 14.sp,
                                                    ),
                                                  ),
                                                SizedBox(height: 10.h),
                                                Text(
                                                  'Sản phẩm:',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 16.sp,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                if (order['items'] is List) ...[
                                                  ...order['items'].asMap().entries.map<Widget>((entry) {
                                                    final item = entry.value;
                                                    final product = item['product'] is Map ? item['product'] : {};
                                                    return FutureBuilder<bool>(
                                                      future: _hasReviewed(product['_id'] ?? '', authToken),
                                                      builder: (context, snapshot) {
                                                        final isReviewed = snapshot.data ?? false;
                                                        return ListTile(
                                                          contentPadding: EdgeInsets.zero,
                                                          leading: ClipRRect(
                                                            borderRadius: BorderRadius.circular(8.r),
                                                            child: Image.network(
                                                              product['image'] ?? 'https://via.placeholder.com/50',
                                                              width: 50.w,
                                                              height: 50.w,
                                                              fit: BoxFit.cover,
                                                              errorBuilder: (context, error, stackTrace) => Icon(
                                                                Icons.error,
                                                                size: 30.sp,
                                                              ),
                                                            ),
                                                          ),
                                                          title: Text(
                                                            product['name'] ?? 'Không rõ',
                                                            style: GoogleFonts.poppins(fontSize: 14.sp),
                                                          ),
                                                          subtitle: Text(
                                                            'Số lượng: ${item['quantity'] ?? 0}${isReviewed ? ' | Đã đánh giá' : ''}',
                                                            style: GoogleFonts.poppins(
                                                              fontSize: 13.sp,
                                                              color: isReviewed ? Colors.green : null,
                                                            ),
                                                          ),
                                                          trailing: order['status'] == 'delivered' && !isReviewed
                                                              ? IconButton(
                                                                  icon: Icon(Icons.rate_review, size: 20.sp, color: Colors.blue),
                                                                  onPressed: () => _showReviewDialog(
                                                                    product['_id'] ?? '',
                                                                    product['name'] ?? 'Không rõ',
                                                                  ),
                                                                )
                                                              : isReviewed
                                                                  ? Icon(
                                                                      Icons.check_circle,
                                                                      size: 20.sp,
                                                                      color: Colors.green,
                                                                    )
                                                                  : null,
                                                        );
                                                      },
                                                    );
                                                  }).toList(),
                                                ] else
                                                  Text(
                                                    'Không có sản phẩm',
                                                    style: GoogleFonts.poppins(fontSize: 14.sp),
                                                  ),
                                                if (order['status'] == 'shipped')
                                                  Padding(
                                                    padding: EdgeInsets.only(top: 8.h),
                                                    child: ZoomIn(
                                                      child: ElevatedButton(
                                                        onPressed: () => _confirmDelivery(order['_id'] ?? ''),
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor: Colors.green,
                                                          padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 16.w),
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(8.r),
                                                          ),
                                                        ),
                                                        child: Text(
                                                          'Xác nhận nhận hàng',
                                                          style: GoogleFonts.poppins(
                                                            fontSize: 14.sp,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                if (order['status'] == 'delivered' && returnRequest == null)
                                                  Padding(
                                                    padding: EdgeInsets.only(top: 8.h),
                                                    child: ZoomIn(
                                                      child: ElevatedButton(
                                                        onPressed: () => _requestReturn(order['_id'] ?? ''),
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor: Colors.red,
                                                          padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 16.w),
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(8.r),
                                                          ),
                                                        ),
                                                        child: Text(
                                                          'Yêu cầu trả hàng',
                                                          style: GoogleFonts.poppins(
                                                            fontSize: 14.sp,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                if (returnRequest != null)
                                                  Padding(
                                                    padding: EdgeInsets.only(top: 8.h),
                                                    child: Text(
                                                      returnRequest['status'] == 'pending'
                                                          ? 'Yêu cầu trả hàng đang chờ xử lý'
                                                          : returnRequest['status'] == 'approved'
                                                              ? 'Yêu cầu trả hàng đã được chấp nhận'
                                                              : 'Yêu cầu trả hàng bị từ chối',
                                                      style: GoogleFonts.poppins(
                                                        fontSize: 14.sp,
                                                        color: returnRequest['status'] == 'pending'
                                                            ? Colors.orange
                                                            : returnRequest['status'] == 'approved'
                                                                ? Colors.green
                                                                : Colors.red,
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
                      ),
          );
        },
      ),
    );
  }
}