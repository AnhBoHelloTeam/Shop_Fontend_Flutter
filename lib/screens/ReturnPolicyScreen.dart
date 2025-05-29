import 'dart:convert';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

// Widget quản lý yêu cầu trả hàng (admin)
class ReturnPolicyScreen extends StatefulWidget {
  const ReturnPolicyScreen({super.key});

  @override
  _ReturnPolicyScreenState createState() => _ReturnPolicyScreenState();
}

class _ReturnPolicyScreenState extends State<ReturnPolicyScreen> {
  List<dynamic> returnRequests = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchReturnRequests();
  }

  // Lấy danh sách yêu cầu trả hàng
  Future<void> _fetchReturnRequests() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('authToken') ?? '';
      if (authToken.isEmpty) {
        if (mounted) {
          setState(() {
            errorMessage = 'Vui lòng đăng nhập với tài khoản admin';
            isLoading = false;
          });
        }
        return;
      }

      final response = await http.get(
        Uri.parse('https://shop-backend-nodejs.onrender.com/api/orders/return-requests'),
        headers: {'Authorization': 'Bearer $authToken'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            returnRequests = data;
            isLoading = false;
            errorMessage = '';
          });
        }
      } else {
        if (mounted) {
          setState(() {
            errorMessage = jsonDecode(response.body)['error'] ?? 'Không thể lấy danh sách yêu cầu';
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('🔥 Lỗi lấy yêu cầu trả hàng: $e');
      if (mounted) {
        setState(() {
          errorMessage = 'Lỗi kết nối server';
          isLoading = false;
        });
      }
    }
  }

  // Xử lý yêu cầu trả hàng
  Future<void> _processReturnRequest(String orderId, String action) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('authToken') ?? '';
      if (authToken.isEmpty) {
        _showFlushbar('Vui lòng đăng nhập lại', Colors.red);
        return;
      }

      final response = await http.put(
        Uri.parse('https://shop-backend-nodejs.onrender.com/api/orders/return/$orderId'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'action': action}),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        _showFlushbar('✅ Đã ${action == 'approve' ? 'xác nhận' : 'từ chối'} yêu cầu trả hàng', Colors.green);
        await _fetchReturnRequests();
      } else {
        _showFlushbar(jsonDecode(response.body)['error'] ?? 'Không thể xử lý yêu cầu', Colors.red);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('🔥 Lỗi xử lý yêu cầu trả hàng: $e');
      _showFlushbar('Lỗi server, vui lòng thử lại', Colors.red);
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
              colors: [Colors.blue, Colors.cyan],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: FadeIn(
          child: Text(
            '📋 Quản lý trả hàng',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 20.sp,
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchReturnRequests,
        color: Colors.blue,
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
                : returnRequests.isEmpty
                    ? Center(
                        child: Text(
                          'Chưa có yêu cầu trả hàng',
                          style: GoogleFonts.poppins(fontSize: 16.sp),
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.all(16.w),
                        itemCount: returnRequests.length,
                        itemBuilder: (context, index) {
                          final request = returnRequests[index];
                          final order = request['order'] ?? {};
                          final createdAt = DateTime.parse(
                            request['requestedAt'] ?? DateTime.now().toIso8601String(),
                          ).toLocal();
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
                                      'Người dùng: ${request['user']['username'] ?? 'N/A'} (${request['user']['email'] ?? 'N/A'})',
                                      style: GoogleFonts.poppins(fontSize: 14.sp),
                                    ),
                                    Text(
                                      'Ngày yêu cầu: ${DateFormat('dd/MM/yyyy HH:mm').format(createdAt)}',
                                      style: GoogleFonts.poppins(fontSize: 14.sp),
                                    ),
                                    Text(
                                      'Lý do: ${request['reason'] ?? 'Không có'}',
                                      style: GoogleFonts.poppins(fontSize: 14.sp),
                                    ),
                                    if (request['image'] != null) ...[
                                      SizedBox(height: 8.h),
                                      GestureDetector(
                                        onTap: () {
                                          showDialog(
                                            context: context,
                                            builder: (context) => Dialog(
                                              child: Image.network(
                                                'https://shop-backend-nodejs.onrender.com${request['image']}',
                                                fit: BoxFit.contain,
                                              ),
                                            ),
                                          );
                                        },
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(8.r),
                                          child: Image.network(
                                            'https://shop-backend-nodejs.onrender.com${request['image']}',
                                            width: 100.w,
                                            height: 100.h,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => Icon(
                                              Icons.error,
                                              size: 30.sp,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                    SizedBox(height: 10.h),
                                    Text(
                                      'Sản phẩm:',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (order['items'] != null)
                                      ...order['items'].map<Widget>((item) {
                                        final product = item['product'] ?? {};
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
                                            'Số lượng: ${item['quantity'] ?? 0}',
                                            style: GoogleFonts.poppins(fontSize: 13.sp),
                                          ),
                                        );
                                      }).toList(),
                                    SizedBox(height: 10.h),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        ElevatedButton(
                                          onPressed: () => _processReturnRequest(order['_id'], 'approve'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8.r),
                                            ),
                                          ),
                                          child: Text(
                                            'Xác nhận',
                                            style: GoogleFonts.poppins(
                                              fontSize: 14.sp,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 8.w),
                                        ElevatedButton(
                                          onPressed: () => _processReturnRequest(order['_id'], 'reject'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8.r),
                                            ),
                                          ),
                                          child: Text(
                                            'Từ chối',
                                            style: GoogleFonts.poppins(
                                              fontSize: 14.sp,
                                              color: Colors.white,
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