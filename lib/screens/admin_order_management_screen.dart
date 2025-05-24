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
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shop_frontend/screens/OrderStatusScreen.dart';

class AdminOrderManagementScreen extends StatefulWidget {
  final String authToken;

  const AdminOrderManagementScreen({required this.authToken, super.key});

  @override
  _AdminOrderManagementScreenState createState() => _AdminOrderManagementScreenState();
}

class _AdminOrderManagementScreenState extends State<AdminOrderManagementScreen> {
  List<dynamic> orders = [];
  bool isLoading = true;
  String? errorMessage;
  late IO.Socket socket;
  List<dynamic> notifications = [];

  @override
  void initState() {
    super.initState();
    _fetchOrders();
    _initSocket();
  }

  void _initSocket() {
    socket = IO.io('https://shop-backend-nodejs.onrender.com', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'reconnection': true,
      'reconnectionAttempts': 5,
      'reconnectionDelay': 2000,
    });

    socket.connect();
    socket.onConnect((_) {
      if (kDebugMode) debugPrint('📡 Connected to socket');
      socket.emit('join', 'admin');
    });

    socket.on('notification', (data) {
      if (mounted) {
        setState(() {
          notifications.add(data);
        });
        _showFlushbar('🔔 Thông báo mới: ${data['message']}', Colors.blue);
      }
    });

    socket.onConnectError((data) {
      if (kDebugMode) debugPrint('⚠️ Socket connection error: $data');
    });

    socket.onDisconnect((_) {
      if (kDebugMode) debugPrint('🔌 Disconnected from socket');
    });
  }

  Future<void> _fetchOrders() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      // Kiểm tra cache
      final cachedOrders = prefs.getString('orders_list');
      if (cachedOrders != null) {
        if (mounted) {
          setState(() {
            orders = jsonDecode(cachedOrders);
            isLoading = false;
          });
          if (kDebugMode) debugPrint('📡 Loaded orders from cache');
        }
      }

      // Gọi API với retry
      const maxRetries = 3;
      int attempt = 0;
      while (attempt <= maxRetries) {
        try {
          final response = await http.get(
            Uri.parse("https://shop-backend-nodejs.onrender.com/api/orders"),
            headers: {"Authorization": "Bearer ${widget.authToken}"},
          ).timeout(const Duration(seconds: 5));

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            await prefs.setString('orders_list', response.body);
            if (mounted) {
              setState(() {
                orders = data;
                isLoading = false;
                errorMessage = null;
              });
            }
            return;
          } else {
            if (kDebugMode) debugPrint('⚠️ Failed to fetch orders: ${response.statusCode}');
            if (mounted) {
              setState(() {
                isLoading = false;
                errorMessage = "Lỗi khi lấy danh sách đơn hàng: ${response.statusCode}";
              });
            }
            return;
          }
        } catch (e) {
          attempt++;
          if (attempt > maxRetries) {
            if (kDebugMode) debugPrint('🔥 Error fetching orders after $maxRetries attempts: $e');
            if (mounted) {
              setState(() {
                isLoading = false;
                errorMessage = "Lỗi kết nối đến server.";
              });
            }
            break;
          }
          await Future.delayed(const Duration(seconds: 2));
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('🔥 Error fetching orders: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = "Lỗi kết nối đến server.";
        });
      }
    }
  }

  Future<void> _updateOrderStatus(String orderId, String status) async {
    try {
      const maxRetries = 3;
      int attempt = 0;
      while (attempt <= maxRetries) {
        try {
          final response = await http.put(
            Uri.parse("https://shop-backend-nodejs.onrender.com/api/orders/$orderId/status"),
            headers: {
              "Authorization": "Bearer ${widget.authToken}",
              "Content-Type": "application/json",
            },
            body: jsonEncode({"status": status}),
          ).timeout(const Duration(seconds: 5));

          if (response.statusCode == 200) {
            _showFlushbar('✅ Cập nhật trạng thái thành công', Colors.green);
            _fetchOrders();
            return;
          } else {
            if (kDebugMode) debugPrint('⚠️ Failed to update order status: ${response.statusCode}');
            _showFlushbar('❌ Lỗi khi cập nhật trạng thái', Colors.red);
            return;
          }
        } catch (e) {
          attempt++;
          if (attempt > maxRetries) {
            if (kDebugMode) debugPrint('🔥 Error updating order status after $maxRetries attempts: $e');
            _showFlushbar('⚠️ Lỗi server', Colors.red);
            break;
          }
          await Future.delayed(const Duration(seconds: 2));
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('🔥 Error updating order status: $e');
      _showFlushbar('⚠️ Lỗi server', Colors.red);
    }
  }

  Future<void> _markNotificationAsRead(String notificationId, int index) async {
    try {
      const maxRetries = 3;
      int attempt = 0;
      while (attempt <= maxRetries) {
        try {
          final response = await http.put(
            Uri.parse("https://shop-backend-nodejs.onrender.com/api/notifications/$notificationId/read"),
            headers: {"Authorization": "Bearer ${widget.authToken}"},
          ).timeout(const Duration(seconds: 5));

          if (response.statusCode == 200) {
            if (mounted) {
              setState(() {
                notifications[index]['isRead'] = true;
              });
            }
            return;
          } else {
            if (kDebugMode) debugPrint('⚠️ Failed to mark notification: ${response.statusCode}');
            return;
          }
        } catch (e) {
          attempt++;
          if (attempt > maxRetries) {
            if (kDebugMode) debugPrint('🔥 Error marking notification after $maxRetries attempts: $e');
            break;
          }
          await Future.delayed(const Duration(seconds: 2));
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('🔥 Error marking notification: $e');
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
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 5,
          itemBuilder: (context, index) {
            return Card(
              margin: EdgeInsets.symmetric(vertical: 8.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 100.w, height: 16.h, color: Colors.white),
                    SizedBox(height: 8.h),
                    Container(width: 150.w, height: 14.h, color: Colors.white),
                    SizedBox(height: 8.h),
                    Container(width: 200.w, height: 14.h, color: Colors.white),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    socket.disconnect();
    super.dispose();
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
            "📋 Quản lý đơn hàng",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 20.sp,
            ),
          ),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.notifications, size: 24.sp, color: Colors.white),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                      title: Text(
                        "🔔 Thông báo",
                        style: GoogleFonts.poppins(fontSize: 18.sp, fontWeight: FontWeight.bold),
                      ),
                      content: notifications.isEmpty
                          ? Text(
                              "Chưa có thông báo",
                              style: GoogleFonts.poppins(fontSize: 16.sp),
                            )
                          : SizedBox(
                              width: double.maxFinite,
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: notifications.length,
                                itemBuilder: (context, index) {
                                  final notification = notifications[index];
                                  return FadeInUp(
                                    child: ListTile(
                                      title: Text(
                                        notification['message'] ?? 'Không có nội dung',
                                        style: GoogleFonts.poppins(fontSize: 14.sp),
                                      ),
                                      subtitle: Text(
                                        notification['createdAt']?.substring(0, 10) ?? '',
                                        style: GoogleFonts.poppins(fontSize: 12.sp, color: Colors.grey[700]),
                                      ),
                                      trailing: Icon(
                                        notification['isRead'] ? Icons.check_circle : Icons.circle,
                                        color: notification['isRead'] ? Colors.green : Colors.red,
                                        size: 20.sp,
                                      ),
                                      onTap: () async {
                                        if (!notification['isRead']) {
                                          await _markNotificationAsRead(notification['_id'], index);
                                        }
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
                            "Đóng",
                            style: GoogleFonts.poppins(fontSize: 14.sp, color: Colors.orange),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              if (notifications.any((n) => !n['isRead']))
                Positioned(
                  right: 8.w,
                  top: 8.h,
                  child: Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    constraints: BoxConstraints(minWidth: 16.w, minHeight: 16.h),
                    child: Text(
                      "${notifications.where((n) => !n['isRead']).length}",
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 12.sp),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.filter_list, size: 24.sp, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OrderStatusScreen(authToken: widget.authToken),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
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
                            style: GoogleFonts.poppins(color: Colors.red, fontSize: 16.sp),
                          ),
                          SizedBox(height: 16.h),
                          ZoomIn(
                            child: ElevatedButton(
                              onPressed: _fetchOrders,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                              ),
                              child: Text(
                                "Thử lại",
                                style: GoogleFonts.poppins(fontSize: 16.sp, color: Colors.white),
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
                          "Chưa có đơn hàng nào",
                          style: GoogleFonts.poppins(fontSize: 16.sp),
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                        itemCount: orders.length,
                        itemBuilder: (context, index) {
                          final order = orders[index];
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
                                      "Đơn hàng #${order['_id']?.substring(0, 8) ?? 'N/A'}",
                                      style: GoogleFonts.poppins(
                                        fontSize: 18.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 8.h),
                                    Text(
                                      "Khách hàng: ${order['user']?['name'] ?? 'N/A'}",
                                      style: GoogleFonts.poppins(fontSize: 14.sp),
                                    ),
                                    Text(
                                      "Email: ${order['user']?['email'] ?? 'N/A'}",
                                      style: GoogleFonts.poppins(fontSize: 14.sp),
                                    ),
                                    SizedBox(height: 8.h),
                                    Text(
                                      "Sản phẩm:",
                                      style: GoogleFonts.poppins(fontSize: 14.sp, fontWeight: FontWeight.w500),
                                    ),
                                    ...order['items'].map<Widget>((item) {
                                      return Text(
                                        "- ${item['product']?['name'] ?? 'N/A'} (x${item['quantity']})",
                                        style: GoogleFonts.poppins(fontSize: 14.sp),
                                      );
                                    }).toList(),
                                    SizedBox(height: 8.h),
                                    Text(
                                      "Tổng tiền: ${order['totalPrice'] ?? 0} đ",
                                      style: GoogleFonts.poppins(fontSize: 14.sp),
                                    ),
                                    if (order['discount']?['code'] != null)
                                      Text(
                                        "Mã giảm giá: ${order['discount']['code']} (-${order['discount']['amount']} đ)",
                                        style: GoogleFonts.poppins(fontSize: 14.sp),
                                      ),
                                    SizedBox(height: 8.h),
                                    Text(
                                      "Trạng thái: ${order['status'] ?? 'N/A'}",
                                      style: GoogleFonts.poppins(fontSize: 14.sp, color: Colors.blue),
                                    ),
                                    SizedBox(height: 12.h),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        if (order['status'] == 'pending')
                                          ZoomIn(
                                            child: ElevatedButton(
                                              onPressed: () => _updateOrderStatus(order['_id'], 'confirmed'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.green,
                                                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(8.r),
                                                ),
                                              ),
                                              child: Text(
                                                "Xác nhận",
                                                style: GoogleFonts.poppins(fontSize: 14.sp, color: Colors.white),
                                              ),
                                            ),
                                          ),
                                        SizedBox(width: 8.w),
                                        if (order['status'] == 'confirmed')
                                          ZoomIn(
                                            child: ElevatedButton(
                                              onPressed: () => _updateOrderStatus(order['_id'], 'shipped'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.blue,
                                                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(8.r),
                                                ),
                                              ),
                                              child: Text(
                                                "Giao hàng",
                                                style: GoogleFonts.poppins(fontSize: 14.sp, color: Colors.white),
                                              ),
                                            ),
                                          ),
                                        SizedBox(width: 8.w),
                                        if (order['status'] != 'cancelled' && order['status'] != 'delivered')
                                          ZoomIn(
                                            child: ElevatedButton(
                                              onPressed: () => _updateOrderStatus(order['_id'], 'cancelled'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red,
                                                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(8.r),
                                                ),
                                              ),
                                              child: Text(
                                                "Hủy",
                                                style: GoogleFonts.poppins(fontSize: 14.sp, color: Colors.white),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}