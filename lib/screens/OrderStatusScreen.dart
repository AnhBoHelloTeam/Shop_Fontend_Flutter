import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:intl/intl.dart';

class OrderStatusScreen extends StatefulWidget {
  final String authToken;

  const OrderStatusScreen({super.key, required this.authToken});

  @override
  _OrderStatusScreenState createState() => _OrderStatusScreenState();
}

class _OrderStatusScreenState extends State<OrderStatusScreen> {
  String selectedStatus = 'all';
  List<dynamic> orders = [];
  bool isLoading = true;
  String? errorMessage;

  final List<Map<String, String>> statusTabs = const [
    {'label': 'Tất cả', 'value': 'all'},
    {'label': 'Chờ thanh toán', 'value': 'pending'},
    {'label': 'Vận chuyển', 'value': 'confirmed'},
    {'label': 'Chờ giao', 'value': 'shipped'},
    {'label': 'Hoàn thành', 'value': 'delivered'},
    {'label': 'Đã hủy', 'value': 'cancelled'},
    {'label': 'Trả hàng/Hoàn tiền', 'value': 'returned'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    const maxRetries = 3;
    int attempt = 0;
    const timeoutSeconds = 5;

    // Load cached data
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'orders_$selectedStatus';
    final cachedOrders = prefs.getString(cacheKey);
    if (cachedOrders != null) {
      try {
        final cachedData = jsonDecode(cachedOrders) as List<dynamic>;
        if (mounted) {
          setState(() {
            orders = cachedData;
            isLoading = false;
          });
          if (kDebugMode) debugPrint('📡 Loaded ${orders.length} orders from cache ($selectedStatus)');
        }
      } catch (e) {
        if (kDebugMode) debugPrint('🔥 Error decoding cached orders: $e');
      }
    }

    while (attempt <= maxRetries) {
      try {
        final client = http.Client();
        final response = await client
            .get(
              Uri.parse("https://shop-backend-nodejs.onrender.com/api/orders/status/$selectedStatus"),
              headers: {"Authorization": "Bearer ${widget.authToken}"},
            )
            .timeout(const Duration(seconds: timeoutSeconds));
        client.close();

        if (kDebugMode) debugPrint('📡 Order status response ($selectedStatus): ${response.statusCode}, attempt ${attempt + 1}');

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final orderList = data is List ? data : [];
          await prefs.setString(cacheKey, jsonEncode(orderList));
          if (mounted) {
            setState(() {
              orders = orderList;
              isLoading = false;
              errorMessage = null;
            });
          }
          return;
        } else {
          if (kDebugMode) debugPrint('⚠️ Failed to fetch orders: ${response.statusCode}');
          attempt++;
          if (attempt > maxRetries) {
            if (mounted) {
              setState(() {
                isLoading = false;
                errorMessage = 'Lỗi khi lấy danh sách đơn hàng';
              });
            }
            return;
          }
          await Future.delayed(const Duration(seconds: 2));
        }
      } catch (e) {
        if (kDebugMode) debugPrint('🔥 Error fetching orders (attempt ${attempt + 1}): $e');
        attempt++;
        if (attempt > maxRetries) {
          if (mounted) {
            setState(() {
              isLoading = false;
              errorMessage = 'Lỗi kết nối đến server';
            });
          }
          return;
        }
        await Future.delayed(const Duration(seconds: 2));
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
      child: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: 3,
        itemBuilder: (context, index) {
          return Card(
            margin: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            child: Padding(
              padding: EdgeInsets.all(16.w),
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
            "📦 Trạng thái đơn hàng",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 20.sp,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            height: 50.h,
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: statusTabs.length,
              itemBuilder: (context, index) {
                final tab = statusTabs[index];
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: FadeIn(
                    delay: Duration(milliseconds: index * 100),
                    child: ChoiceChip(
                      label: Text(
                        tab['label']!,
                        style: GoogleFonts.poppins(
                          fontSize: 14.sp,
                          color: selectedStatus == tab['value'] ? Colors.white : Colors.black87,
                        ),
                      ),
                      selected: selectedStatus == tab['value'],
                      selectedColor: Colors.orange,
                      backgroundColor: Colors.grey[200],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            selectedStatus = tab['value']!;
                          });
                          _fetchOrders();
                        }
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchOrders,
              color: Colors.orange,
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
                                ),
                                SizedBox(height: 16.h),
                                ZoomIn(
                                  child: ElevatedButton(
                                    onPressed: _fetchOrders,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                                    ),
                                    child: Text(
                                      'Thử lại',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14.sp,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : orders.isEmpty
                          ? Center(
                              child: Text(
                                'Chưa có đơn hàng nào',
                                style: GoogleFonts.poppins(
                                  fontSize: 16.sp,
                                  color: Colors.grey,
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: EdgeInsets.all(16.w),
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: orders.length,
                              itemBuilder: (context, index) {
                                final order = orders[index];
                                final createdAt = DateTime.parse(order['createdAt'] ?? DateTime.now().toIso8601String()).toLocal();
                                return FadeInUp(
                                  delay: Duration(milliseconds: index * 100),
                                  child: Card(
                                    margin: EdgeInsets.symmetric(vertical: 8.h),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                                    elevation: 4,
                                    child: Padding(
                                      padding: EdgeInsets.all(16.w),
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
                                            'Khách hàng: ${order['user']?['name'] ?? 'Không rõ'}',
                                            style: GoogleFonts.poppins(fontSize: 14.sp),
                                          ),
                                          Text(
                                            'Email: ${order['user']?['email'] ?? 'Không rõ'}',
                                            style: GoogleFonts.poppins(fontSize: 14.sp),
                                          ),
                                          Text(
                                            'Ngày đặt: ${DateFormat('dd/MM/yyyy HH:mm').format(createdAt)}',
                                            style: GoogleFonts.poppins(fontSize: 14.sp),
                                          ),
                                          SizedBox(height: 8.h),
                                          Text(
                                            'Sản phẩm:',
                                            style: GoogleFonts.poppins(
                                              fontSize: 16.sp,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          ...order['items'].map<Widget>((item) {
                                            return Padding(
                                              padding: EdgeInsets.only(left: 8.w, top: 4.h),
                                              child: Text(
                                                '- ${item['product']?['name'] ?? 'Không rõ'} (x${item['quantity'] ?? 0})',
                                                style: GoogleFonts.poppins(fontSize: 14.sp),
                                              ),
                                            );
                                          }).toList(),
                                          SizedBox(height: 8.h),
                                          Text(
                                            'Tổng tiền: ${(order['totalPrice']?.toDouble() ?? 0.0).toStringAsFixed(2)} đ',
                                            style: GoogleFonts.poppins(
                                              fontSize: 14.sp,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          if (order['discount']?['code'] != null)
                                            Text(
                                              'Mã giảm giá: ${order['discount']['code']} (-${order['discount']['amount']?.toDouble().toStringAsFixed(2)} đ)',
                                              style: GoogleFonts.poppins(
                                                fontSize: 14.sp,
                                                color: Colors.green,
                                              ),
                                            ),
                                          SizedBox(height: 8.h),
                                          Text(
                                            'Trạng thái: ${order['status'] ?? 'Không rõ'}',
                                            style: GoogleFonts.poppins(
                                              fontSize: 14.sp,
                                              color: Colors.blue,
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
          ),
        ],
      ),
    );
  }
}