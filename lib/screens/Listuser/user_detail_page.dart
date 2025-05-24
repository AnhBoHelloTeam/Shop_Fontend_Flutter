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

class UserDetailPage extends StatefulWidget {
  final String userId;

  const UserDetailPage({required this.userId, super.key});

  @override
  _UserDetailPageState createState() => _UserDetailPageState();
}

class _UserDetailPageState extends State<UserDetailPage> {
  Map<String, dynamic>? user;
  bool isLoading = true;
  String errorMessage = "";

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
  }

  Future<void> _fetchUserDetails() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('authToken') ?? '';
      if (authToken.isEmpty) {
        if (mounted) {
          setState(() {
            errorMessage = "Vui lòng đăng nhập để xem thông tin.";
            isLoading = false;
          });
        }
        _showFlushbar('🔐 Vui lòng đăng nhập', Colors.red);
        return;
      }

      // Kiểm tra cache
      final cachedUser = prefs.getString('user_${widget.userId}');
      if (cachedUser != null) {
        if (mounted) {
          setState(() {
            user = jsonDecode(cachedUser);
            isLoading = false;
          });
          if (kDebugMode) debugPrint('📡 Loaded user from cache: user_${widget.userId}');
        }
      }

      // Gọi API với retry
      const maxRetries = 3;
      int attempt = 0;
      while (attempt <= maxRetries) {
        try {
          final response = await http.get(
            Uri.parse("https://shop-backend-nodejs.onrender.com/api/users/${widget.userId}"),
            headers: {'Authorization': 'Bearer $authToken'},
          ).timeout(const Duration(seconds: 5));

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            await prefs.setString('user_${widget.userId}', response.body);
            if (mounted) {
              setState(() {
                user = data;
                isLoading = false;
                errorMessage = "";
              });
            }
            return;
          } else {
            if (kDebugMode) debugPrint('⚠️ Failed to fetch user: ${response.statusCode}');
            if (mounted) {
              setState(() {
                errorMessage = "Không thể lấy thông tin người dùng.";
                isLoading = false;
              });
            }
            return;
          }
        } catch (e) {
          attempt++;
          if (attempt > maxRetries) {
            if (kDebugMode) debugPrint('🔥 Error fetching user after $maxRetries attempts: $e');
            if (mounted) {
              setState(() {
                errorMessage = "Lỗi kết nối đến server.";
                isLoading = false;
              });
            }
            break;
          }
          await Future.delayed(const Duration(seconds: 2));
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('🔥 Error fetching user: $e');
      if (mounted) {
        setState(() {
          errorMessage = "Lỗi kết nối đến server.";
          isLoading = false;
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
        padding: EdgeInsets.all(20.w),
        child: Column(
          children: [
            CircleAvatar(radius: 60.r, backgroundColor: Colors.white),
            SizedBox(height: 20.h),
            Container(width: 200.w, height: 24.h, color: Colors.white),
            SizedBox(height: 10.h),
            Container(width: 150.w, height: 18.h, color: Colors.white),
            SizedBox(height: 25.h),
            ...List.generate(
              4,
              (index) => Padding(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                child: Row(
                  children: [
                    Container(width: 20.w, height: 20.h, color: Colors.white),
                    SizedBox(width: 10.w),
                    Container(width: 200.w, height: 16.h, color: Colors.white),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return FadeInUp(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, color: Colors.grey[700], size: 20.sp),
            SizedBox(width: 10.w),
            Expanded(
              child: RichText(
                text: TextSpan(
                  text: "$label: ",
                  style: GoogleFonts.poppins(
                    fontSize: 16.sp,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                  children: [
                    TextSpan(
                      text: value ?? "Không có dữ liệu",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.normal,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
            "👤 Thông tin người dùng",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 20.sp,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: isLoading
              ? _buildSkeletonLoader()
              : errorMessage.isNotEmpty
                  ? FadeInUp(
                      child: Padding(
                        padding: EdgeInsets.all(20.w),
                        child: Text(
                          errorMessage,
                          style: GoogleFonts.poppins(color: Colors.red, fontSize: 18.sp),
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 30.h),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final isTablet = constraints.maxWidth > 600;
                          return FadeInUp(
                            child: Container(
                              padding: EdgeInsets.all(20.w),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.shade300,
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  CircleAvatar(
                                    radius: isTablet ? 80.r : 60.r,
                                    child: ClipOval(
                                      child: CachedNetworkImage(
                                        imageUrl: user?['avatar'] ?? '',
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => Shimmer.fromColors(
                                          baseColor: Colors.grey[300]!,
                                          highlightColor: Colors.grey[100]!,
                                          child: Container(color: Colors.white),
                                        ),
                                        errorWidget: (context, url, error) => Image.asset(
                                          'assets/images/default_avatar.png',
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 20.h),
                                  Text(
                                    user?['name'] ?? 'Không có tên',
                                    style: GoogleFonts.poppins(
                                      fontSize: isTablet ? 26.sp : 22.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 10.h),
                                  Text(
                                    user?['email'] ?? 'Không có email',
                                    style: GoogleFonts.poppins(
                                      fontSize: isTablet ? 20.sp : 18.sp,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  SizedBox(height: 25.h),
                                  _buildInfoRow("📞 Số điện thoại", user?['phone']),
                                  _buildInfoRow("📍 Địa chỉ", user?['address']),
                                  _buildInfoRow("📅 Ngày tạo", user?['createdAt']),
                                  _buildInfoRow("🔄 Cập nhật", user?['updatedAt']),
                                  SizedBox(height: 20.h),
                                  Text(
                                    "👑 Vai trò: ${user?['role'] ?? 'Không xác định'}",
                                    style: GoogleFonts.poppins(
                                      fontSize: isTablet ? 20.sp : 18.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ),
    );
  }
}